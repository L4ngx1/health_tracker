import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'firebase_options.dart';

const r2WorkerUploadEndpoint = 'https://healthtracker-r2-upload.healthtracker.workers.dev';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthTracker R2 + Firebase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'HealthTracker Cloud Upload'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  String _status = 'Ready';
  String? _lastUploadedUrl;

  User? get user => FirebaseAuth.instance.currentUser;

  Future<void> _signInAnonymously() async {
    setState(() {
      _busy = true;
      _status = 'Signing in...';
    });
    try {
      await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        _status = 'Signed in as ${FirebaseAuth.instance.currentUser?.uid}';
      });
    } catch (e) {
      setState(() {
        _status = 'Sign-in failed: $e';
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUpload() async {
    if (user == null) {
      setState(() => _status = 'Please sign in first');
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _busy = true;
      _status = 'Uploading ${image.name} ...';
    });

    final Uint8List bytes = await image.readAsBytes();
    final mimeType = lookupMimeType(kIsWeb ? image.name : image.path) ?? 'application/octet-stream';
    final key = '${user!.uid}/${DateTime.now().toIso8601String()}_${image.name}';

    try {
      final uploadUri = Uri.parse('$r2WorkerUploadEndpoint/upload?key=${Uri.encodeComponent(key)}');
      debugPrint('start upload to $uploadUri mime=$mimeType size=${bytes.length}');
      final resp = await http
          .post(
            uploadUri,
            headers: {
              'Content-Type': mimeType,
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 45));
      debugPrint('got response status=${resp.statusCode} body=${resp.body}');

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = body['url'] as String? ?? '';

        await FirebaseFirestore.instance.collection('r2_uploads').add({
          'uid': user!.uid,
          'key': key,
          'url': url,
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _status = 'Uploaded successfully: $key';
          _lastUploadedUrl = url;
        });
      } else {
        setState(() {
          _status = 'Upload failed: ${resp.statusCode} ${resp.body}';
        });
      }
    } catch (e) {
      debugPrint('upload error: $e');
      setState(() {
        _status = 'Upload failed: $e';
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auth: ${user?.uid ?? 'not signed in'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _signInAnonymously,
              child: const Text('Sign in anonymously'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _pickAndUpload,
              child: const Text('Pick image and upload to R2'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 8),
                Expanded(child: Text(_status)),
              ],
            ),
            if (_lastUploadedUrl != null) ...[
              const SizedBox(height: 16),
              const Text('Last uploaded preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _lastUploadedUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Uploaded items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('r2_uploads').orderBy('uploadedAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No uploads yet'));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final url = data['url'] as String? ?? '';
                      final key = data['key'] as String? ?? 'unknown';
                      final uid = data['uid'] as String? ?? 'unknown';
                      return ListTile(
                        leading: url.isNotEmpty
                            ? SizedBox(
                                width: 64,
                                height: 64,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                        title: Text(key),
                        subtitle: Text('user: $uid'),
                        trailing: url.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () {
                                  // Optionally open url in browser or separate view
                                },
                              )
                            : null,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

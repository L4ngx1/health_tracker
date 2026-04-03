<<<<<<< HEAD
﻿import 'dart:convert';
=======
import 'dart:convert';
>>>>>>> origin/main
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudflareUploadResponse {
  const CloudflareUploadResponse({
    required this.ok,
    required this.key,
    required this.url,
  });

  final bool ok;
  final String key;
  final String url;

  factory CloudflareUploadResponse.fromMap(Map<String, dynamic> map) {
    return CloudflareUploadResponse(
      ok: map['ok'] == true,
      key: (map['key'] as String?) ?? '',
      url: (map['url'] as String?) ?? '',
    );
  }
}

class CloudflareR2UploadService {
  const CloudflareR2UploadService({required this.workerBaseUrl});

  final String workerBaseUrl;

  Future<CloudflareUploadResponse> uploadBytes({
    required Uint8List bytes,
    required String key,
    String contentType = 'application/octet-stream',
  }) async {
    final uri = Uri.parse('$workerBaseUrl?key=${Uri.encodeComponent(key)}');

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Cloudflare upload failed: ${response.statusCode} ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid upload response format.');
    }

    return CloudflareUploadResponse.fromMap(decoded);
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import '../../controllers/auth_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_palette.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = const AuthController();
  bool _loading = false;

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.displayName ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Lưu')),
        ],
      ),
    );

    if (saved != true) return;

    setState(() => _loading = true);
    final error = await _controller.updateProfile(
      displayName: nameCtrl.text.trim(),
      photoUrl: null,
    );
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() => _loading = false);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công.')));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ người dùng'),
        backgroundColor: AppPalette.primary,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings), icon: const Icon(Icons.settings)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Make top content scrollable to avoid RenderFlex overflow on small screens
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Top card with avatar and basic info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0,4))],
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _editProfile,
                              child: user?.photoURL != null
                                  ? (user!.photoURL!.startsWith('data:image')
                                      ? CircleAvatar(radius: 50, backgroundImage: MemoryImage(base64Decode(user.photoURL!.split(',').last)))
                                      : CircleAvatar(radius: 50, backgroundImage: NetworkImage(user.photoURL!)))
                                  : const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(user?.displayName ?? 'Người dùng', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                const SizedBox(width: 8),
                                InkWell(onTap: _editProfile, child: const Icon(Icons.edit, size: 18))
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(user?.email ?? '', style: const TextStyle(color: AppPalette.textMuted)),
                            const SizedBox(height: 8),
                            Chip(
                              backgroundColor: user?.emailVerified == true ? const Color(0xFFE8F8F0) : const Color(0xFFFFF3E6),
                              label: Text(user?.isAnonymous == true ? 'Ẩn danh' : (user?.emailVerified == true ? 'Đã xác minh' : 'Chưa xác minh')),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Info card
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thông tin chi tiết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              Row(children: [const Icon(Icons.fingerprint, size: 18), const SizedBox(width: 8), Expanded(child: Text('UID: ${user?.uid ?? '-'}'))]),
                              const SizedBox(height: 8),
                              Row(children: [const Icon(Icons.email_outlined, size: 18), const SizedBox(width: 8), Expanded(child: Text('Email: ${user?.email ?? '-'}'))]),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _loading
            ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()))
            : SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text('Bạn có chắc muốn đăng xuất không?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Hủy')),
                          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Đăng xuất')),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    setState(() => _loading = true);
                    await _controller.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
      ),
    );
  }
}

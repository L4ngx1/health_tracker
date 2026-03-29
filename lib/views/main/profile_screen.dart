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

  Widget _buildAvatar(User? user) {
    final photo = user?.photoURL;
    if (photo == null || photo.isEmpty) {
      return const CircleAvatar(
        radius: 46,
        backgroundColor: Color(0xFFD5E6DE),
        child: Icon(Icons.person, size: 42, color: AppPalette.primaryDark),
      );
    }
    if (photo.startsWith('data:image')) {
      return CircleAvatar(
        radius: 46,
        backgroundImage: MemoryImage(base64Decode(photo.split(',').last)),
      );
    }
    return CircleAvatar(radius: 46, backgroundImage: NetworkImage(photo));
  }

  Widget _statusChip(User? user) {
    final isAnonymous = user?.isAnonymous == true;
    final verified = user?.emailVerified == true;
    final label = isAnonymous
        ? 'Tài khoản ẩn danh'
        : (verified ? 'Email đã xác minh' : 'Email chưa xác minh');
    final bg = isAnonymous
        ? const Color(0xFFFFF3E6)
        : (verified ? const Color(0xFFE8F8F0) : const Color(0xFFFFF3E6));
    final fg = isAnonymous
        ? const Color(0xFF8A5A2B)
        : (verified ? AppPalette.primaryDark : const Color(0xFF8A5A2B));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE7E1)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.displayName ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Tên'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu'),
          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công.')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F3EC), Color(0xFFF2F8F4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Hồ sơ người dùng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.textMain,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.settings),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A1B7D5B),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFCFE3DA),
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: _editProfile,
                                borderRadius: BorderRadius.circular(50),
                                child: _buildAvatar(user),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?.displayName?.trim().isNotEmpty == true
                                  ? user!.displayName!.trim()
                                  : 'Người dùng',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppPalette.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'Không có email',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppPalette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _statusChip(user),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: _editProfile,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppPalette.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text(
                                  'Chỉnh sửa hồ sơ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2ECE7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin tài khoản',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppPalette.textMain,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.fingerprint,
                                  size: 18,
                                  color: AppPalette.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'UID: ${user?.uid ?? '-'}',
                                    style: const TextStyle(
                                      color: AppPalette.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                  color: AppPalette.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user?.email ?? '-',
                                    style: const TextStyle(
                                      color: AppPalette.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
            ? const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              )
            : SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text(
                          'Bạn có chắc muốn đăng xuất không?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text('Đăng xuất'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    setState(() => _loading = true);
                    await _controller.signOut();
                    if (!context.mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB4A4A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
      ),
    );
  }
}

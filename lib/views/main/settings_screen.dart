import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../controllers/auth_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authController = const AuthController();
  bool _loading = false;
  bool _notifications = true;
  String _language = 'vi';
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.getBool('notifications_enabled') ?? true;
      _language = prefs.getString('language') ?? 'vi';
      _darkMode = ThemeService.instance.mode.value == ThemeMode.dark;
    });
  }

  Future<void> _setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    setState(() => _notifications = enabled);
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _language = lang);
  }

  Future<void> _setDarkMode(bool enabled) async {
    await ThemeService.instance.setDarkMode(enabled);
    setState(() => _darkMode = enabled);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(
          'Bạn chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    final error = await _authController.deleteAccount();
    setState(() => _loading = false);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: AppPalette.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cài đặt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _darkMode,
              title: const Text('Chế độ tối'),
              subtitle: const Text(
                'Kích hoạt giao diện tối để tiết kiệm pin và dễ nhìn vào ban đêm.',
              ),
              onChanged: (v) => _setDarkMode(v),
            ),
            SwitchListTile(
              value: _notifications,
              title: const Text('Nhận thông báo'),
              subtitle: const Text('Cho phép ứng dụng gửi thông báo.'),
              onChanged: (v) => _setNotifications(v),
            ),
            ListTile(
              title: const Text('Ngôn ngữ'),
              subtitle: Text(_language == 'vi' ? 'Tiếng Việt' : 'English'),
              trailing: DropdownButton<String>(
                value: _language,
                items: const [
                  DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) {
                  if (v != null) _setLanguage(v);
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Xóa tài khoản'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  inherit: true,
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

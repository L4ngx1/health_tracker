import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_service.dart';
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
    });
  }

  Future<void> _setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    setState(() => _notifications = enabled);
  }

  Future<void> _setLanguage(String lang) async {
    await LocaleService.instance.setLanguage(lang);
  }

  Future<void> _setDarkMode(bool enabled) async {
    await ThemeService.instance.setDarkMode(enabled);
  }

  Future<void> _deleteAccount() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(AppStrings.settingsDeleteTitle(context)),
        content: Text(AppStrings.settingsDeleteConfirm(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(AppStrings.cancel(context)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(AppStrings.deleteAction(context)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest,
              ],
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
                    Expanded(
                      child: Text(
                        AppStrings.settingsTitle(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.optionsTitle(context),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.optionsSubtitle(context),
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: ThemeService.instance.mode,
                              builder: (context, mode, _) {
                                return SwitchListTile(
                                  value: mode == ThemeMode.dark,
                                  activeThumbColor: colorScheme.primary,
                                  title: Text(
                                    AppStrings.darkModeTitle(context),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppStrings.darkModeSubtitle(context),
                                  ),
                                  onChanged: (v) => _setDarkMode(v),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              value: _notifications,
                              activeThumbColor: colorScheme.primary,
                              title: Text(
                                AppStrings.notificationsTitle(context),
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                AppStrings.notificationsSubtitle(context),
                              ),
                              onChanged: (v) => _setNotifications(v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.languageTitle(context),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppStrings.languageSubtitle(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<Locale>(
                              valueListenable: LocaleService.instance.locale,
                              builder: (context, locale, _) {
                                return DropdownButton<String>(
                                  value: locale.languageCode,
                                  underline: const SizedBox.shrink(),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'vi',
                                      child: Text(
                                        AppStrings.languageVietnamese(context),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'en',
                                      child: Text(
                                        AppStrings.languageEnglish(context),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) _setLanguage(v);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _deleteAccount,
                          icon: _loading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onError,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.delete_forever_outlined),
                          label: Text(
                            _loading
                                ? AppStrings.processing(context)
                                : AppStrings.deleteAccount(context),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
    );
  }
}

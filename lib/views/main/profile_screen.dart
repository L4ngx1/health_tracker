import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import '../../controllers/auth_controller.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = const AuthController();
  bool _loading = false;

  Widget _buildAvatar(User? user, ColorScheme colorScheme) {
    final photo = user?.photoURL;
    if (photo == null || photo.isEmpty) {
      return CircleAvatar(
        radius: 46,
        backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
        child: Icon(Icons.person, size: 42, color: colorScheme.primary),
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

  Widget _statusChip(User? user, ColorScheme colorScheme) {
    final isAnonymous = user?.isAnonymous == true;
    final verified = user?.emailVerified == true;
    final label = isAnonymous
        ? AppStrings.anonymousAccount(context)
        : (verified
            ? AppStrings.emailVerified(context)
            : AppStrings.emailUnverified(context));
    final bg = isAnonymous
        ? colorScheme.tertiaryContainer
        : (verified
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer);
    final fg = isAnonymous
        ? colorScheme.onTertiaryContainer
        : (verified
            ? colorScheme.onPrimaryContainer
            : colorScheme.onErrorContainer);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
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
        title: Text(AppStrings.editProfileDialogTitle(context)),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: AppStrings.nameLabel(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel(context)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.save(context)),
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
        SnackBar(content: Text(AppStrings.profileUpdateSuccess(context))),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
                        AppStrings.profileScreenTitle(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
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
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.16),
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
                                  color: colorScheme.outlineVariant,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: _editProfile,
                                borderRadius: BorderRadius.circular(50),
                                child: _buildAvatar(user, colorScheme),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?.displayName?.trim().isNotEmpty == true
                                  ? user!.displayName!.trim()
                                  : AppStrings.userFallback(context),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? AppStrings.noEmail(context),
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _statusChip(user, colorScheme),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: _editProfile,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: colorScheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: Text(
                                  AppStrings.editProfile(context),
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
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.accountInfo(context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.fingerprint,
                                  size: 18,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.uidPrefix(
                                        context, user?.uid ?? '-'),
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user?.email ?? '-',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
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
                        title: Text(AppStrings.logoutConfirmTitle(context)),
                        content: Text(AppStrings.logoutConfirmContent(context)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: Text(AppStrings.cancel(context)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(c).pop(true),
                            child: Text(AppStrings.logout(context)),
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
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppStrings.logout(context),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
      ),
    );
  }
}

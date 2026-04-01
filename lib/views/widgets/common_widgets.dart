import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/localization/app_strings.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.onUserTap});

  final String title;
  final VoidCallback? onUserTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final hasGoogleProvider =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    final photoUrl = user?.photoURL?.trim();
    final showGoogleAvatar =
        hasGoogleProvider && photoUrl != null && photoUrl.isNotEmpty;

    return Row(
      children: [
        InkWell(
          onTap: onUserTap,
          borderRadius: BorderRadius.circular(18),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.16),
            foregroundImage: showGoogleAvatar ? NetworkImage(photoUrl) : null,
            child: showGoogleAvatar
                ? null
                : Icon(Icons.person, color: colorScheme.primary, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Icon(Icons.notifications_none_rounded, color: colorScheme.onSurface),
      ],
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.subTitle});

  final String subTitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const BrandIconOnly(),
        const SizedBox(height: 12),
        Text(
          AppStrings.appTitle(context),
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            height: 0.95,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subTitle,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class BrandIconOnly extends StatelessWidget {
  const BrandIconOnly({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondary.withValues(alpha: 0.28),
            colorScheme.primary.withValues(alpha: 0.34),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.eco_outlined, size: 38, color: colorScheme.primary),
    );
  }
}

class InputLabel extends StatelessWidget {
  const InputLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class RoundedInput extends StatelessWidget {
  const RoundedInput({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.validator,
    this.enabled = true,
  });

  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        focusNode: focusNode,
        textInputAction: textInputAction,
        autofocus: autofocus,
        obscureText: obscureText,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          suffixIcon: Icon(icon, color: colorScheme.primary),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    this.icon,
    this.isLoading = false,
    required this.onPressed,
  });

  final String text;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 3,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              )
            : (icon == null ? const SizedBox.shrink() : Icon(icon)),
        label: Text(
          isLoading ? AppStrings.processing(context) : text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  const SocialButton({super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 22,
              height: 22,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  const DividerWithText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
    );
  }
}

class ChipLabel extends StatelessWidget {
  const ChipLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFFD5E6DE),
          child: Icon(Icons.person, color: AppPalette.primaryDark, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: AppPalette.textMain,
            ),
          ),
        ),
        const Icon(
          Icons.notifications_none_rounded,
          color: AppPalette.textMain,
        ),
      ],
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.subTitle});

  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandIconOnly(),
        const SizedBox(height: 12),
        const Text(
          'Sống Khỏe',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: AppPalette.textMain,
            height: 0.95,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(subTitle, style: const TextStyle(color: AppPalette.textMuted)),
      ],
    );
  }
}

class BrandIconOnly extends StatelessWidget {
  const BrandIconOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCEBD9), Color(0xFFAEE7D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1B7D5B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.eco_outlined,
        size: 38,
        color: AppPalette.primaryDark,
      ),
    );
  }
}

class InputLabel extends StatelessWidget {
  const InputLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
          color: AppPalette.textMain,
        ),
      ),
    );
  }
}

class RoundedInput extends StatelessWidget {
  const RoundedInput({super.key, required this.hint, required this.icon});

  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                color: Color(0xFF91A39A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(icon, color: AppPalette.primaryDark),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
  });

  final String text;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 3,
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(
          text,
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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(color: Color(0xFFDADCE0)),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Color(0xFF202124),
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
    return Row(
      children: [
        const Expanded(child: Divider(color: AppPalette.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              color: AppPalette.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppPalette.divider)),
      ],
    );
  }
}

class ChipLabel extends StatelessWidget {
  const ChipLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFC8F0DC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppPalette.primaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

const double _kInputRadius = 14.0;
const double _kButtonRadius = 14.0;
const double _kControlHeight = 52.0;
const Color _kInputFill = Color(0xFFF1F6F2);

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.onProfileTap});

  final String title;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFD5E6DE),
            child: Icon(Icons.person, color: AppPalette.primaryDark, size: 18),
          ),
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
        const Hero(tag: 'brandIcon', child: BrandIconOnly()),
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
    const double brandSize = 72.0;
    return Container(
      width: brandSize,
      height: brandSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFCEBD9), Color(0xFFAEE7D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(brandSize / 2),
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
        size: 34,
        color: AppPalette.primaryDark,
      ),
    );
  }
}

class AuthSectionHeader extends StatelessWidget {
  const AuthSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppPalette.textMain,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: AppPalette.textMuted,
            height: 1.35,
          ),
        ),
      ],
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

class RoundedInput extends StatefulWidget {
  const RoundedInput({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofocus = false,
  });

  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;

  @override
  State<RoundedInput> createState() => _RoundedInputState();
}

class _RoundedInputState extends State<RoundedInput> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: _kInputFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        prefixIcon: Icon(widget.icon, color: AppPalette.primaryDark),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppPalette.primaryDark,
                ),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kInputRadius),
          borderSide: BorderSide.none,
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
    return SizedBox(
      width: double.infinity,
      height: _kControlHeight,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 4,
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kButtonRadius),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : icon == null
            ? const SizedBox.shrink()
            : Icon(icon),
        label: Text(
          isLoading ? 'Đang xử lý...' : text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
      height: _kControlHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppPalette.primary),
          backgroundColor: Colors.white,
          foregroundColor: AppPalette.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kButtonRadius),
          ),
        ),
        icon: const CircleAvatar(
          radius: 11,
          backgroundColor: Colors.white,
          child: Text(
            'G',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
          ),
        ),
        label: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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

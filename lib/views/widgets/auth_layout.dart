import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

class AuthStyles {
  static const Gradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7FBF9), Color(0xFFEAF6F0)],
  );

  static const double maxWidth = 520;
  static const double cardRadius = 26;
  static const EdgeInsets outerPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 22,
  );
  static const EdgeInsets innerPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 22,
  );
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.maxWidth = AuthStyles.maxWidth,
    this.showBack = false,
    this.onBack,
  });

  final Widget child;
  final double maxWidth;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    // make the card responsive: use smaller width on narrow screens
    final effectiveMax = screenWidth <= AuthStyles.maxWidth
        ? (screenWidth - 32).clamp(0.0, AuthStyles.maxWidth)
        : AuthStyles.maxWidth;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEBFFF6), Color(0xFFDEFAF0), Color(0xFFF7FBF9)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMax),
            child: Padding(
              padding: AuthStyles.outerPadding,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AuthStyles.cardRadius),
                ),
                shadowColor: const Color.fromRGBO(130, 207, 164, 0.16),
                child: Padding(
                  padding: AuthStyles.innerPadding,
                  child: Stack(
                    children: [
                      // main content
                      child,
                      // optional back button at top-left inside the card
                      if (showBack)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                            child: IconButton(
                              onPressed: onBack ?? () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back),
                              color: AppPalette.textMain,
                              tooltip: 'Quay lại',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

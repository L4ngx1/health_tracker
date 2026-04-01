import 'package:flutter/material.dart';

PageRouteBuilder<T> slidePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final primary = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInQuart,
      );
      final secondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.045, 0),
          end: Offset.zero,
        ).animate(primary),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(primary),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(primary),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-0.018, 0),
              ).animate(secondary),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

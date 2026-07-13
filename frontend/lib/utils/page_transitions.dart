import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scaleTween, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        );
}

class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  SlideUpPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetTween = Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            );
            return SlideTransition(
              position: offsetTween,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        );
}

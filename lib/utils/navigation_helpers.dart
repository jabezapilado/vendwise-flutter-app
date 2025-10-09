import 'package:flutter/material.dart';

/// A shared page route that slides the next page from right to left on push
/// and back to the right on pop, matching the desired horizontal motion.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          final offsetTween = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          );

          return SlideTransition(
            position: offsetTween.animate(curved),
            child: child,
          );
        },
      );

  final Widget page;
}

Future<T?> pushWithSlide<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(SlidePageRoute<T>(page: page));
}

Future<T?> pushReplacementWithSlide<T, TO>(BuildContext context, Widget page) {
  return Navigator.of(
    context,
  ).pushReplacement<T, TO>(SlidePageRoute<T>(page: page));
}

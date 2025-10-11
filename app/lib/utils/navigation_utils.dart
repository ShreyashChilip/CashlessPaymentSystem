import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class NavigationUtils {
  static Future<T?> pushScreen<T>(BuildContext context, Widget screen) {
    return Navigator.push<T>(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: screen,
      ),
    );
  }

  static Future<void> pushReplacementScreen(BuildContext context, Widget screen) {
    return Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: screen,
      ),
    );
  }

  static Future<void> pushAndRemoveUntil(BuildContext context, Widget screen) {
    return Navigator.pushAndRemoveUntil(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: screen,
      ),
      (route) => false,
    );
  }
}
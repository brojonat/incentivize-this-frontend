import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import 'app_router.dart';

class NotificationService {
  static void showSuccess(String message) {
    _showFlushbar(
      message,
      backgroundColor: Colors.green.shade200,
      textColor: Colors.black,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    );
  }

  static void showError(String message) {
    _showFlushbar(
      message,
      backgroundColor: Colors.red.shade200,
      textColor: Colors.black,
      icon: Icons.error_outline,
      iconColor: Colors.red,
    );
  }

  static void showPageSuccess(String message) {
    _showFlushbar(
      message,
      backgroundColor: Colors.green.shade200,
      textColor: Colors.black,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    );
  }

  static void showPageError(String message) {
    _showFlushbar(
      message,
      backgroundColor: Colors.red.shade200,
      textColor: Colors.black,
      icon: Icons.error_outline,
      iconColor: Colors.red,
    );
  }

  static void _showFlushbar(
    String message, {
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    Flushbar(
      messageText: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      icon: Icon(
        icon,
        color: iconColor,
      ),
    ).show(context);
  }
}

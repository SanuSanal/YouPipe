import 'package:flutter/material.dart';

/// The app's ScaffoldMessenger, for toasts raised outside any widget (SponsorBlock skips, downloads finishing).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showGlobalSnack(String message, {String? action, VoidCallback? onAction}) {
  final m = scaffoldMessengerKey.currentState;
  m?.hideCurrentSnackBar();
  m?.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      // Close after [duration] even with an action (Flutter keeps a toast with an action up until it's tapped).
      persist: false,
      action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {}),
    ),
  );
}

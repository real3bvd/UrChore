import 'package:flutter/material.dart';

void showAppNotification(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      duration: duration,
      persist: false,
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      actionOverflowThreshold: 0.35,
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
            ),
    ),
  );
}

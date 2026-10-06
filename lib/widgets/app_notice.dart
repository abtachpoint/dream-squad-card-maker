import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showAppNotice(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.info_outline_rounded,
  Color? accent,
  String? actionLabel,
  VoidCallback? onAction,
}) async {
  final theme = Theme.of(context);
  final tone = accent ?? theme.colorScheme.primary;
  HapticFeedback.selectionClick();

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.fromLTRB(16, 15, 12, 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF171920),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: tone.withValues(alpha: .46)),
                  boxShadow: [
                    BoxShadow(
                      color: tone.withValues(alpha: .12),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: tone),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(message, style: const TextStyle(color: Colors.white70, height: 1.3)),
                          if (actionLabel != null) ...[
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onAction?.call();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: tone,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      final slide = Tween<Offset>(begin: const Offset(0, .26), end: Offset.zero).animate(curved);
      final scale = Tween<double>(begin: .94, end: 1).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(scale: scale, alignment: Alignment.bottomCenter, child: child),
        ),
      );
    },
  );
}

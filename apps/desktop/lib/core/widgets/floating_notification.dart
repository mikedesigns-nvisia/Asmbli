import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

/// Floating notification overlay that doesn't affect page layout
class FloatingNotification {
  static OverlayEntry? _currentOverlay;

  /// Show a floating notification that overlays the screen without affecting layout
  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Remove existing notification if any
    _currentOverlay?.remove();
    _currentOverlay = null;

    final colors = ThemeColors(context);
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _FloatingNotificationWidget(
        message: message,
        type: type,
        colors: colors,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          overlayEntry.remove();
          if (_currentOverlay == overlayEntry) {
            _currentOverlay = null;
          }
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (_currentOverlay == overlayEntry) {
        overlayEntry.remove();
        _currentOverlay = null;
      }
    });
  }

  /// Show success notification
  static void success(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.success);
  }

  /// Show error notification
  static void error(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction, Duration? duration}) {
    show(
      context,
      message: message,
      type: NotificationType.error,
      duration: duration ?? const Duration(seconds: 5),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show warning notification
  static void warning(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    show(
      context,
      message: message,
      type: NotificationType.warning,
      duration: const Duration(seconds: 4),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show info notification
  static void info(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: NotificationType.info, duration: duration ?? const Duration(seconds: 3));
  }
}

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class _FloatingNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final ThemeColors colors;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _FloatingNotificationWidget({
    required this.message,
    required this.type,
    required this.colors,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_FloatingNotificationWidget> createState() => _FloatingNotificationWidgetState();
}

class _FloatingNotificationWidgetState extends State<_FloatingNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return widget.colors.success;
      case NotificationType.error:
        return widget.colors.error;
      case NotificationType.warning:
        return widget.colors.warning;
      case NotificationType.info:
        return widget.colors.primary;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80, // Below the header
      left: SpacingTokens.lg,
      right: SpacingTokens.lg,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null && widget.onAction != null) ...[
                    const SizedBox(width: SpacingTokens.sm),
                    TextButton(
                      onPressed: () {
                        widget.onAction?.call();
                        widget.onDismiss();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                          vertical: SpacingTokens.xs,
                        ),
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: TextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    iconSize: 18,
                    padding: const EdgeInsets.all(SpacingTokens.xs),
                    constraints: const BoxConstraints(),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../services/human_verification_service.dart';
import '../../models/verification_request.dart';

/// A popover button that shows pending verification requests
/// Can be placed in the app navigation bar for global access
/// Responsive: adapts to screen size (dropdown on large screens, bottom sheet on small)
class VerificationInboxPopover extends ConsumerStatefulWidget {
  const VerificationInboxPopover({super.key});

  @override
  ConsumerState<VerificationInboxPopover> createState() => _VerificationInboxPopoverState();
}

class _VerificationInboxPopoverState extends ConsumerState<VerificationInboxPopover> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  // Breakpoints
  static const double _smallScreenBreakpoint = 600;
  static const double _mediumScreenBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(humanVerificationServiceProvider);
    final colors = ThemeColors(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < _smallScreenBreakpoint;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => isSmallScreen
            ? _buildBottomSheetOverlay(context, colors, service)
            : _buildDropdownOverlay(context, colors, service),
        child: StreamBuilder<List<VerificationRequest>>(
          stream: service.requestsStream,
          initialData: const [],
          builder: (context, snapshot) {
            final pending = (snapshot.data ?? [])
                .where((r) => r.status == VerificationStatus.pending)
                .toList();
            final count = pending.length;

            return _buildButton(colors, count, isSmallScreen);
          },
        ),
      ),
    );
  }

  Widget _buildButton(ThemeColors colors, int count, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_overlayController.isShowing) {
            _overlayController.hide();
          } else {
            _overlayController.show();
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: count > 0 ? colors.primary : colors.onSurfaceVariant,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(minWidth: 14),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Hide label on very small screens
              if (!isSmallScreen) ...[
                const SizedBox(width: 8),
                Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet style overlay for small screens
  Widget _buildBottomSheetOverlay(BuildContext context, ThemeColors colors, HumanVerificationService service) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _overlayController.hide(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent tap from closing
            child: StreamBuilder<List<VerificationRequest>>(
              stream: service.requestsStream,
              initialData: const [],
              builder: (context, snapshot) {
                final pending = (snapshot.data ?? [])
                    .where((r) => r.status == VerificationStatus.pending)
                    .toList();

                return _buildBottomSheetContent(context, colors, service, pending);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Dropdown style overlay for larger screens
  Widget _buildDropdownOverlay(BuildContext context, ThemeColors colors, HumanVerificationService service) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _overlayController.hide(),
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: GestureDetector(
              onTap: () {}, // Prevent tap from closing
              child: StreamBuilder<List<VerificationRequest>>(
                stream: service.requestsStream,
                initialData: const [],
                builder: (context, snapshot) {
                  final pending = (snapshot.data ?? [])
                      .where((r) => r.status == VerificationStatus.pending)
                      .toList();

                  return _buildDropdownContent(context, colors, service, pending, screenWidth);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetContent(
    BuildContext context,
    ThemeColors colors,
    HumanVerificationService service,
    List<VerificationRequest> pending,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.7;

    return Material(
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      color: colors.surface,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildHeader(colors, pending, isCompact: false),
            if (pending.isEmpty)
              _buildEmptyState(colors, isCompact: false)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colors.border.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) => _buildRequestItem(
                    context,
                    colors,
                    service,
                    pending[index],
                    isCompact: false,
                  ),
                ),
              ),
            // Safe area padding for bottom
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContent(
    BuildContext context,
    ThemeColors colors,
    HumanVerificationService service,
    List<VerificationRequest> pending,
    double screenWidth,
  ) {
    // Responsive width based on screen size
    final double popoverWidth;
    final double maxHeight;
    final bool isCompact;

    if (screenWidth < _mediumScreenBreakpoint) {
      popoverWidth = 320;
      maxHeight = 360;
      isCompact = true;
    } else {
      popoverWidth = 400;
      maxHeight = 440;
      isCompact = false;
    }

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      color: colors.surface,
      child: Container(
        width: popoverWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(colors, pending, isCompact: isCompact),
            if (pending.isEmpty)
              _buildEmptyState(colors, isCompact: isCompact)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colors.border.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) => _buildRequestItem(
                    context,
                    colors,
                    service,
                    pending[index],
                    isCompact: isCompact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, List<VerificationRequest> pending, {required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 16,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Text(
            'Pending Verification',
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          if (pending.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                pending.length.toString(),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
          const Spacer(),
          InkWell(
            onTap: () {
              _overlayController.hide();
              context.go('/human-verification');
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors, {required bool isCompact}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 32 : 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 10 : 12),
            decoration: BoxDecoration(
              color: colors.background,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: isCompact ? 20 : 24,
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            'No pending requests',
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(
    BuildContext context,
    ThemeColors colors,
    HumanVerificationService service,
    VerificationRequest request, {
    required bool isCompact,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 8 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 5 : 6,
                  vertical: isCompact ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: isCompact ? 9 : 10, color: colors.warning),
                    SizedBox(width: isCompact ? 2 : 3),
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: isCompact ? 9 : 10,
                        fontWeight: FontWeight.w500,
                        color: colors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.source,
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 11,
                    color: colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(request.createdAt),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            request.title,
            style: TextStyle(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            request.description,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: colors.onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildCompactButton(
                colors,
                'Reject',
                onPressed: () => _showRejectDialog(context, colors, request, service),
                isDestructive: true,
                isCompact: isCompact,
              ),
              SizedBox(width: isCompact ? 6 : 8),
              _buildCompactButton(
                colors,
                'Approve',
                onPressed: () => service.approveRequest(request.id),
                isPrimary: true,
                isCompact: isCompact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton(
    ThemeColors colors,
    String label, {
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isDestructive = false,
    bool isCompact = false,
  }) {
    final bgColor = isPrimary
        ? colors.primary
        : isDestructive
            ? Colors.transparent
            : Colors.transparent;
    final textColor = isPrimary
        ? Colors.white
        : isDestructive
            ? colors.error
            : colors.onSurface;
    final borderColor = isPrimary
        ? colors.primary
        : isDestructive
            ? colors.error.withValues(alpha: 0.5)
            : colors.border;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            border: isPrimary ? null : Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    ThemeColors colors,
    VerificationRequest request,
    HumanVerificationService service,
  ) {
    final controller = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < _smallScreenBreakpoint;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          'Reject Request',
          style: TextStyle(
            fontSize: isSmall ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: SizedBox(
          width: isSmall ? double.infinity : 320,
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: isSmall ? 12 : 13, color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Reason (optional)',
              hintStyle: TextStyle(
                fontSize: isSmall ? 12 : 13,
                color: colors.onSurfaceVariant,
              ),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.primary),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmall ? 10 : 12,
                vertical: isSmall ? 8 : 10,
              ),
            ),
            maxLines: 2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              service.rejectRequest(
                request.id,
                feedback: controller.text.isEmpty ? null : controller.text,
              );
            },
            child: Text(
              'Reject',
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}

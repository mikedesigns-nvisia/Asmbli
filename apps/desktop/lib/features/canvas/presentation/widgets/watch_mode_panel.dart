import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/canvas_update_event.dart';

/// Watch Mode panel that displays real-time canvas updates
/// Shows agent operations as they happen with visual feedback
class WatchModePanel extends StatefulWidget {
  final Stream<CanvasUpdateEvent> updateStream;
  final bool isWatchMode;
  final VoidCallback onToggleWatchMode;

  const WatchModePanel({
    super.key,
    required this.updateStream,
    required this.isWatchMode,
    required this.onToggleWatchMode,
  });

  @override
  State<WatchModePanel> createState() => _WatchModePanelState();
}

class _WatchModePanelState extends State<WatchModePanel> {
  final List<CanvasUpdateEvent> _events = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<CanvasUpdateEvent>? _subscription;
  bool _autoscroll = true;

  @override
  void initState() {
    super.initState();
    _subscription = widget.updateStream.listen(_onUpdateEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUpdateEvent(CanvasUpdateEvent event) {
    setState(() {
      _events.insert(0, event); // Add to beginning for chronological order
      if (_events.length > 100) {
        _events.removeLast(); // Keep last 100 events
      }
    });

    // Autoscroll to top on new event
    if (_autoscroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearEvents() {
    setState(() {
      _events.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Row(
              children: [
                Icon(
                  widget.isWatchMode ? Icons.visibility : Icons.visibility_off,
                  color: widget.isWatchMode ? colors.success : colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Watch Mode',
                  style: TextStyles.cardTitle.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                // Clear button
                if (_events.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear_all, size: 18, color: colors.onSurfaceVariant),
                    onPressed: _clearEvents,
                    tooltip: 'Clear events',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                const SizedBox(width: SpacingTokens.xs),
                // Toggle button
                Switch(
                  value: widget.isWatchMode,
                  onChanged: (_) => widget.onToggleWatchMode(),
                  activeColor: colors.success,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Events list
          Expanded(
            child: _events.isEmpty
                ? _buildEmptyState(colors)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(SpacingTokens.sm),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return _buildEventTile(event, colors, index == 0);
                    },
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: colors.background.withOpacity(0.5),
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Text(
                  '${_events.length} events',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Autoscroll',
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _autoscroll,
                        onChanged: (value) => setState(() => _autoscroll = value),
                        activeColor: colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isWatchMode ? Icons.hourglass_empty : Icons.visibility_off,
              size: 48,
              color: colors.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              widget.isWatchMode
                  ? 'Waiting for agent activity...'
                  : 'Watch Mode is off',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              widget.isWatchMode
                  ? 'Agent operations will appear here in real-time'
                  : 'Enable Watch Mode to see real-time updates',
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(CanvasUpdateEvent event, ThemeColors colors, bool isLatest) {
    final timeSince = DateTime.now().difference(event.timestamp);
    final timeText = timeSince.inSeconds < 60
        ? '${timeSince.inSeconds}s ago'
        : '${timeSince.inMinutes}m ago';

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: isLatest
            ? colors.primary.withOpacity(0.1)
            : colors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: isLatest ? colors.primary.withOpacity(0.3) : colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getEventColor(event.type, colors).withOpacity(0.2),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Center(
              child: Text(
                event.type.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.type.displayName,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeText,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (event.description != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    event.description!,
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (event.toolName != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      event.toolName!,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(CanvasUpdateType type, ThemeColors colors) {
    switch (type) {
      case CanvasUpdateType.elementCreated:
        return colors.success;
      case CanvasUpdateType.elementUpdated:
        return colors.primary;
      case CanvasUpdateType.elementDeleted:
        return colors.error;
      case CanvasUpdateType.elementTransformed:
      case CanvasUpdateType.elementDuplicated:
        return colors.accent;
      default:
        return colors.onSurfaceVariant;
    }
  }
}

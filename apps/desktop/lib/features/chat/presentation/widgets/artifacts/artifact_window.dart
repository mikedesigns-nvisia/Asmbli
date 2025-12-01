import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../../../../../core/design_system/design_system.dart';
import '../../../../../core/models/artifact.dart';
import '../../../../../providers/artifact_provider.dart';

/// Draggable, resizable window for displaying artifacts
class ArtifactWindow extends ConsumerStatefulWidget {
  final Artifact artifact;
  final Widget child;

  const ArtifactWindow({
    super.key,
    required this.artifact,
    required this.child,
  });

  @override
  ConsumerState<ArtifactWindow> createState() => _ArtifactWindowState();
}

class _ArtifactWindowState extends ConsumerState<ArtifactWindow> {
  late Offset _position;
  late Size _size;
  Size? _resizeStartSize;
  Offset? _resizeDragStart;

  @override
  void initState() {
    super.initState();
    _position = Offset(
      widget.artifact.geometry.x,
      widget.artifact.geometry.y,
    );
    _size = Size(
      widget.artifact.geometry.width,
      widget.artifact.geometry.height,
    );
  }

  void _onDragStart(DragStartDetails details) {
    // Drag start - no state needed since we use delta
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Use delta for smooth, incremental movement
    setState(() {
      _position = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
    });
  }

  void _onDragEnd(DragEndDetails details) {
    // Save position to state
    final newGeometry = widget.artifact.geometry.copyWith(
      x: _position.dx,
      y: _position.dy,
    );
    ref.read(artifactProvider.notifier).updateArtifactGeometry(
          widget.artifact.id,
          newGeometry,
        );
  }

  void _onResizeStart(DragStartDetails details) {
    _resizeStartSize = _size;
    _resizeDragStart = details.globalPosition;
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (_resizeStartSize == null || _resizeDragStart == null) return;

    final delta = details.globalPosition - _resizeDragStart!;
    setState(() {
      _size = Size(
        (_resizeStartSize!.width + delta.dx).clamp(300, double.infinity),
        (_resizeStartSize!.height + delta.dy).clamp(200, double.infinity),
      );
    });
  }

  void _onResizeEnd(DragEndDetails details) {
    // Save size to state
    final newGeometry = widget.artifact.geometry.copyWith(
      width: _size.width,
      height: _size.height,
    );
    ref.read(artifactProvider.notifier).updateArtifactGeometry(
          widget.artifact.id,
          newGeometry,
        );
    _resizeStartSize = null;
    _resizeDragStart = null;
  }

  void _minimize() {
    ref.read(artifactProvider.notifier).minimizeArtifact(widget.artifact.id);
  }

  void _maximize() {
    if (widget.artifact.geometry.isMaximized) {
      ref.read(artifactProvider.notifier).restoreArtifact(widget.artifact.id);
    } else {
      ref.read(artifactProvider.notifier).maximizeArtifact(widget.artifact.id);
    }
  }

  void _close() {
    ref.read(artifactProvider.notifier).hideArtifact(widget.artifact.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final geometry = ref.watch(artifactByIdProvider(widget.artifact.id))?.geometry ??
        widget.artifact.geometry;

    // Update local state if maximized
    if (geometry.isMaximized) {
      final screenSize = MediaQuery.of(context).size;
      _position = const Offset(20, 20);
      _size = Size(screenSize.width - 40, screenSize.height - 40);
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Container(
        width: _size.width,
        height: _size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title bar with window controls
                  _buildTitleBar(colors),

                  // Content
                  Expanded(
                    child: widget.child,
                  ),

                  // Resize handle
                  _buildResizeHandle(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(ThemeColors colors) {
    return GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(
              color: colors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Artifact type icon
            Text(
              widget.artifact.type.icon,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(width: SpacingTokens.sm),

            // Title
            Expanded(
              child: Text(
                widget.artifact.title,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Firefox-style window controls (right side)
            _buildWindowControls(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowControls(ThemeColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimize button
        _WindowControlButton(
          icon: Icons.remove,
          tooltip: 'Minimize',
          onPressed: _minimize,
          colors: colors,
        ),

        const SizedBox(width: 4),

        // Maximize/Restore button
        _WindowControlButton(
          icon: widget.artifact.geometry.isMaximized
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
          tooltip: widget.artifact.geometry.isMaximized ? 'Restore' : 'Maximize',
          onPressed: _maximize,
          colors: colors,
        ),

        const SizedBox(width: 4),

        // Close button
        _WindowControlButton(
          icon: Icons.close,
          tooltip: 'Close',
          onPressed: _close,
          colors: colors,
          isCloseButton: true,
        ),
      ],
    );
  }

  Widget _buildResizeHandle(ThemeColors colors) {
    return GestureDetector(
      onPanStart: _onResizeStart,
      onPanUpdate: _onResizeUpdate,
      onPanEnd: _onResizeEnd,
      child: Container(
        height: 16,
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.only(right: 4, bottom: 2),
        child: Icon(
          Icons.drag_handle,
          size: 16,
          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Firefox-style window control button
class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ThemeColors colors;
  final bool isCloseButton;

  const _WindowControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.colors,
    this.isCloseButton = false,
  });

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.isCloseButton
                      ? widget.colors.error.withValues(alpha: 0.2)
                      : widget.colors.onSurfaceVariant.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _isHovered && widget.isCloseButton
                  ? widget.colors.error
                  : widget.colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

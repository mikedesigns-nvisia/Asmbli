import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';

/// A dropdown header button for navigation with sub-items
class DropdownHeaderButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final List<DropdownItem> items;
  final bool isActive;

  const DropdownHeaderButton({
    super.key,
    required this.text,
    required this.icon,
    required this.items,
    this.isActive = false,
  });

  @override
  State<DropdownHeaderButton> createState() => _DropdownHeaderButtonState();
}

class _DropdownHeaderButtonState extends State<DropdownHeaderButton> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _toggleDropdown() {
    print('Dropdown toggle clicked, _isOpen: $_isOpen');
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    final renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible barrier to close dropdown when clicking outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown content
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeColors(context).surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ThemeColors(context).border),
                ),
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((item) => _buildDropdownItem(item)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  Widget _buildDropdownItem(DropdownItem item) {
    final colors = ThemeColors(context);
    
    return InkWell(
      onTap: () {
        _removeOverlay();
        item.onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
          vertical: SpacingTokens.md,
        ),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Flexible(
                child: Text(
                  item.text,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (item.isActive) ...[
                const SizedBox(width: SpacingTokens.sm),
                Icon(
                  Icons.check,
                  size: 16,
                  color: colors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: _buttonKey,
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isActive || _isOpen
                ? colors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: _isOpen 
                ? Border.all(color: colors.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isActive || _isOpen ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                widget.text,
                style: TextStyles.bodyMedium.copyWith(
                  color: widget.isActive || _isOpen ? colors.primary : colors.onSurface,
                  fontWeight: widget.isActive || _isOpen ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: widget.isActive || _isOpen ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DropdownItem {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const DropdownItem({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });
}
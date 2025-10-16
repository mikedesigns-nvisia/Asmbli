import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../tokens/theme_colors.dart';

/// Modern button component with variants, animations, and professional styling
class AsmblButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AsmblButtonVariant variant;
  final AsmblButtonSize size;
  final bool isLoading;
  final bool hasBorder;
  final Widget? suffix;

  const AsmblButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = AsmblButtonVariant.primary,
    this.size = AsmblButtonSize.medium,
    this.isLoading = false,
    this.hasBorder = false,
    this.suffix,
  });

  // Factory constructors for common variants - maintains backward compatibility
  factory AsmblButton.primary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      suffix: suffix,
    );
  }

  factory AsmblButton.accent({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.accent,
      size: size,
      isLoading: isLoading,
      suffix: suffix,
    );
  }

  factory AsmblButton.secondary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      suffix: suffix,
    );
  }

  factory AsmblButton.outline({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.outline,
      size: size,
      isLoading: isLoading,
      hasBorder: true,
      suffix: suffix,
    );
  }

  factory AsmblButton.destructive({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    AsmblButtonSize size = AsmblButtonSize.medium,
    bool isLoading = false,
    Widget? suffix,
  }) {
    return AsmblButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AsmblButtonVariant.destructive,
      size: size,
      isLoading: isLoading,
      suffix: suffix,
    );
  }

  @override
  State<AsmblButton> createState() => _AsmblButtonState();
}

class _AsmblButtonState extends State<AsmblButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      onEnter: (_) {
        if (isEnabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        } : null,
        onTapUp: isEnabled ? (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        } : null,
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: Container(
                height: _getHeight(),
                padding: _getPadding(),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(colors),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  border: _shouldShowBorder() 
                      ? Border.all(color: _getBorderColor(colors))
                      : null,
                  boxShadow: _getShadow(colors),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null && !widget.isLoading) ...[
                      Icon(
                        widget.icon!,
                        size: _getIconSize(),
                        color: _getTextColor(colors),
                      ),
                      SizedBox(width: _getIconSpacing()),
                    ],
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: _getIconSize(),
                        height: _getIconSize(),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: _getTextColor(colors),
                        ),
                      ),
                      SizedBox(width: _getIconSpacing()),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        style: _getTextStyle(colors),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.suffix != null) ...[
                      SizedBox(width: _getIconSpacing()),
                      widget.suffix!,
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _getHeight() {
    switch (widget.size) {
      case AsmblButtonSize.small:
        return 32.0;
      case AsmblButtonSize.medium:
        return 40.0;
      case AsmblButtonSize.large:
        return 48.0;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (widget.size) {
      case AsmblButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: SpacingTokens.md_precise);
      case AsmblButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: SpacingTokens.lg_precise);
      case AsmblButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: SpacingTokens.xl_precise);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AsmblButtonSize.small:
        return 14.0;
      case AsmblButtonSize.medium:
        return 16.0;
      case AsmblButtonSize.large:
        return 18.0;
    }
  }

  double _getIconSpacing() {
    return widget.size == AsmblButtonSize.small 
        ? SpacingTokens.xs_precise 
        : SpacingTokens.sm_precise;
  }

  TextStyle _getTextStyle(ThemeColors colors) {
    final baseStyle = widget.size == AsmblButtonSize.small
        ? TextStyles.labelMedium
        : TextStyles.button;

    return baseStyle.copyWith(
      color: _getTextColor(colors),
      fontWeight: widget.variant == AsmblButtonVariant.primary
          ? TypographyTokens.medium
          : TypographyTokens.regular,
    );
  }

  bool _shouldShowBorder() {
    return widget.hasBorder || 
           widget.variant == AsmblButtonVariant.outline ||
           widget.variant == AsmblButtonVariant.secondary;
  }

  Color _getTextColor(ThemeColors colors) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled) {
      return colors.onSurfaceVariant.withValues(alpha: 0.6);
    }

    switch (widget.variant) {
      case AsmblButtonVariant.primary:
        return colors.onPrimary;
      case AsmblButtonVariant.accent:
        return colors.onAccent;
      case AsmblButtonVariant.secondary:
      case AsmblButtonVariant.outline:
        return colors.onSurface;
      case AsmblButtonVariant.destructive:
        return Colors.white;
    }
  }

  Color _getBackgroundColor(ThemeColors colors) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled) {
      return colors.surfaceVariant.withValues(alpha: 0.5);
    }

    switch (widget.variant) {
      case AsmblButtonVariant.primary:
        if (_isPressed) return colors.primary.withValues(alpha: 0.9);
        if (_isHovered) return colors.primary.withValues(alpha: 0.95);
        return colors.primary;
      
      case AsmblButtonVariant.accent:
        if (_isPressed) return colors.accent.withValues(alpha: 0.9);
        if (_isHovered) return colors.accent.withValues(alpha: 0.95);
        return colors.accent;
      
      case AsmblButtonVariant.secondary:
        if (_isPressed) return colors.surfaceVariant.withValues(alpha: 0.8);
        if (_isHovered) return colors.surfaceVariant.withValues(alpha: 0.6);
        return colors.surfaceVariant.withValues(alpha: 0.4);
      
      case AsmblButtonVariant.outline:
        if (_isPressed) return colors.accent.withValues(alpha: 0.1);
        if (_isHovered) return colors.accent.withValues(alpha: 0.05);
        return Colors.transparent;
      
      case AsmblButtonVariant.destructive:
        if (_isPressed) return Colors.red.withValues(alpha: 0.9);
        if (_isHovered) return Colors.red.withValues(alpha: 0.95);
        return Colors.red;
    }
  }

  Color _getBorderColor(ThemeColors colors) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    if (!isEnabled) {
      return colors.border.withValues(alpha: 0.5);
    }

    switch (widget.variant) {
      case AsmblButtonVariant.outline:
        if (_isHovered) return colors.accent;
        return colors.border;
      
      case AsmblButtonVariant.secondary:
        if (_isHovered) return colors.accent.withValues(alpha: 0.6);
        return colors.border;
      
      default:
        return colors.border;
    }
  }

  List<BoxShadow>? _getShadow(ThemeColors colors) {
    if (!_isHovered || widget.variant == AsmblButtonVariant.outline) {
      return null;
    }

    return [
      BoxShadow(
        color: colors.primary.withValues(alpha: 0.15),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

enum AsmblButtonVariant {
  primary,
  accent,
  secondary,
  outline,
  destructive,
}

enum AsmblButtonSize {
  small,
  medium,
  large,
}
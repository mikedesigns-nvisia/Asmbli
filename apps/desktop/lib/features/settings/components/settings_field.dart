import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/design_system.dart';

/// Reusable settings field component following design system patterns
class SettingsField extends StatelessWidget {
  final String label;
  final String? description;
  final String? value;
  final String? hint;
  final bool obscureText;
  final bool enabled;
  final bool required;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? suffix;
  final Widget? prefix;
  final int? maxLines;
  final int? maxLength;

  const SettingsField({
    super.key,
    required this.label,
    this.description,
    this.value,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.required = false,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.onChanged,
    this.onClear,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Row(
          children: [
            Text(
              label,
              style: TextStyles.labelMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            if (required) ...[
              const SizedBox(width: SpacingTokens.xs),
              Text(
                '*',
                style: TextStyles.labelMedium.copyWith(
                  color: colors.error,
                ),
              ),
            ],
          ],
        ),
        
        // Description
        if (description != null) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            description!,
            style: TextStyles.captionMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        
        const SizedBox(height: SpacingTokens.sm),
        
        // Input field
        _buildInputField(colors),
        
        // Error text
        if (errorText != null) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            errorText!,
            style: TextStyles.captionMedium.copyWith(
              color: colors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: errorText != null 
              ? colors.error
              : colors.border,
          width: errorText != null ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: value != null ? TextEditingController(text: value) : null,
        onChanged: onChanged,
        obscureText: obscureText,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyles.bodyMedium.copyWith(
          color: enabled ? colors.onSurface : colors.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(SpacingTokens.md),
          prefixIcon: prefix,
          suffixIcon: _buildSuffixWidget(colors),
          counterText: maxLength != null ? null : '',
        ),
      ),
    );
  }

  Widget? _buildSuffixWidget(ThemeColors colors) {
    final widgets = <Widget>[];
    
    // Clear button
    if (onClear != null && value != null && value!.isNotEmpty) {
      widgets.add(
        IconButton(
          onPressed: onClear,
          icon: Icon(
            Icons.clear,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    
    // Custom suffix
    if (suffix != null) {
      widgets.add(suffix!);
    }
    
    if (widgets.isEmpty) return null;
    if (widgets.length == 1) return widgets.first;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

/// Settings toggle component
class SettingsToggle extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const SettingsToggle({
    super.key,
    required this.label,
    this.description,
    required this.value,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyles.labelMedium.copyWith(
                      color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      description!,
                      style: TextStyles.captionMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.md),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings section header
class SettingsSection extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.headingSmall.copyWith(
            color: colors.onSurface,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            description!,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: SpacingTokens.lg),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.md),
          child: child,
        )),
      ],
    );
  }
}

/// Settings button for actions
class SettingsButton extends StatelessWidget {
  final String text;
  final String? description;
  final IconData? icon;
  final VoidCallback? onPressed;
  final SettingsButtonType type;
  final bool isLoading;

  const SettingsButton({
    super.key,
    required this.text,
    this.description,
    this.icon,
    this.onPressed,
    this.type = SettingsButtonType.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SettingsButtonType.primary:
        return AsmblButton.primary(
          text: text,
          icon: icon,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
        );
      case SettingsButtonType.secondary:
        return AsmblButton.secondary(
          text: text,
          icon: icon,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
        );
      case SettingsButtonType.outline:
        return AsmblButton.outline(
          text: text,
          icon: icon,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
        );
      case SettingsButtonType.danger:
        return AsmblButton.danger(
          text: text,
          icon: icon,
          onPressed: isLoading ? null : onPressed,
          isLoading: isLoading,
        );
    }
  }
}

enum SettingsButtonType {
  primary,
  secondary,
  outline,
  danger,
}
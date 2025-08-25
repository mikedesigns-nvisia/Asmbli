import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system.dart';
import '../../../features/settings/presentation/widgets/auto_detection_wizard.dart';

class AutoDetectButton extends ConsumerWidget {
  final String? specificIntegration;
  final VoidCallback? onDetectionComplete;
  final bool compact;

  const AutoDetectButton({
    super.key,
    this.specificIntegration,
    this.onDetectionComplete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      return _buildCompactButton(context);
    } else {
      return _buildFullButton(context);
    }
  }

  Widget _buildCompactButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SemanticColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SemanticColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAutoDetection(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_fix_high,
                  size: 18,
                  color: SemanticColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Auto-Detect',
                  style: TextStyles.labelMedium.copyWith(
                    color: SemanticColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SemanticColors.primary.withValues(alpha: 0.1),
            SemanticColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SemanticColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SemanticColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.auto_fix_high,
                  color: SemanticColors.surface,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specificIntegration != null
                          ? 'Auto-Detect ${specificIntegration}'
                          : 'Auto-Detect Configuration',
                      style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                        color: SemanticColors.primary,
                      ).copyWith(color: SemanticColors.primary),
                    ),
                    Text(
                      'Automatically find and configure installed tools',
                      style: TextStyles.bodySmall.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          AsmblButton.primary(
            text: 'Start Detection',
            onPressed: () => _showAutoDetection(context),
          ),
        ],
      ),
    );
  }

  void _showAutoDetection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AutoDetectionWizard(
        specificIntegration: specificIntegration,
        onComplete: onDetectionComplete,
      ),
    );
  }
}

/// Helper widget for adding auto-detect functionality to existing forms
class AutoDetectFormField extends ConsumerWidget {
  final String label;
  final String? value;
  final String integrationName;
  final ValueChanged<String?>? onChanged;

  const AutoDetectFormField({
    super.key,
    required this.label,
    this.value,
    required this.integrationName,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyles.labelMedium,
              ),
            ),
            AutoDetectButton(
              specificIntegration: integrationName,
              compact: true,
              onDetectionComplete: () => _handleDetectionComplete(context),
            ),
          ],
        ),
        SizedBox(height: SpacingTokens.sm),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Path will be auto-detected',
            filled: true,
            fillColor: SemanticColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: SemanticColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: SemanticColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: SemanticColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDetectionComplete(BuildContext context) {
    // This would be expanded to actually update the field value
    // with the detected path
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detection complete - configuration updated'),
      ),
    );
  }
}
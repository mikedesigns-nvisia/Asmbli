import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

/// Visual indicator showing wizard progress and step names
class WizardStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;
  final VoidCallback? onStepTapped;

  const WizardStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.md,
      ),
      child: Column(
        children: [
          // Progress bar
          _buildProgressBar(context),
          
          const SizedBox(height: SpacingTokens.md),
          
          // Step indicators with titles
          _buildStepIndicators(context),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: ThemeColors(context).surfaceVariant,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: ThemeColors(context).primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicators(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        final isAccessible = index <= currentStep;

        return Expanded(
          child: GestureDetector(
            onTap: isAccessible && onStepTapped != null ? onStepTapped : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: SpacingTokens.sm,
              ),
              child: Column(
                children: [
                  // Step circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getStepBackgroundColor(context, isActive, isCompleted),
                      border: Border.all(
                        color: _getStepBorderColor(context, isActive, isCompleted),
                        width: isActive ? 2 : 1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _buildStepIcon(context, index, isActive, isCompleted),
                    ),
                  ),
                  
                  const SizedBox(height: SpacingTokens.xs),
                  
                  // Step title
                  Text(
                    stepTitles[index],
                    style: TextStyles.bodySmall.copyWith(
                      color: _getStepTextColor(context, isActive, isCompleted, isAccessible),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepIcon(BuildContext context, int index, bool isActive, bool isCompleted) {
    if (isCompleted) {
      return Icon(
        Icons.check,
        size: 16,
        color: ThemeColors(context).success,
      );
    } else {
      return Text(
        '${index + 1}',
        style: TextStyles.bodySmall.copyWith(
          color: _getStepIconColor(context, isActive, isCompleted),
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }

  Color _getStepBackgroundColor(BuildContext context, bool isActive, bool isCompleted) {
    if (isCompleted) {
      return ThemeColors(context).success.withOpacity(0.1);
    } else if (isActive) {
      return ThemeColors(context).primary.withOpacity(0.1);
    } else {
      return ThemeColors(context).surface;
    }
  }

  Color _getStepBorderColor(BuildContext context, bool isActive, bool isCompleted) {
    if (isCompleted) {
      return ThemeColors(context).success;
    } else if (isActive) {
      return ThemeColors(context).primary;
    } else {
      return ThemeColors(context).border;
    }
  }

  Color _getStepIconColor(BuildContext context, bool isActive, bool isCompleted) {
    if (isCompleted) {
      return ThemeColors(context).success;
    } else if (isActive) {
      return ThemeColors(context).primary;
    } else {
      return ThemeColors(context).onSurfaceVariant;
    }
  }

  Color _getStepTextColor(BuildContext context, bool isActive, bool isCompleted, bool isAccessible) {
    if (isCompleted || isActive) {
      return ThemeColors(context).onSurface;
    } else if (isAccessible) {
      return ThemeColors(context).onSurfaceVariant;
    } else {
      return ThemeColors(context).onSurfaceVariant.withOpacity(0.5);
    }
  }
}
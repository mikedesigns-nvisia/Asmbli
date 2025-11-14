import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/model_warmup_service.dart';

/// Model warmup status indicator - shows when models are being prepared
class ModelWarmupStatusIndicator extends ConsumerStatefulWidget {
  const ModelWarmupStatusIndicator({super.key});

  @override
  ConsumerState<ModelWarmupStatusIndicator> createState() => _ModelWarmupStatusIndicatorState();
}

class _ModelWarmupStatusIndicatorState extends ConsumerState<ModelWarmupStatusIndicator> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    final warmupStatusAsync = ref.watch(modelWarmUpStatusProvider);
    
    return warmupStatusAsync.when(
      data: (statusMap) {
        final warmingModels = statusMap.values.where((s) => s.isWarming).toList();
        // final readyModels = statusMap.values.where((s) => s.isReady).toList();
        final hasError = statusMap.values.any((s) => s.hasError);
        
        // Reset dismissed state if models start warming up again
        if (warmingModels.isNotEmpty && _isDismissed) {
          _isDismissed = false;
        }
        
        // Don't show anything if dismissed, no warmup is happening, and all models are ready
        if (_isDismissed || (warmingModels.isEmpty && !hasError)) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          decoration: BoxDecoration(
            color: hasError 
                ? ThemeColors(context).error.withValues(alpha: 0.1)
                : ThemeColors(context).primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            border: Border.all(
              color: hasError 
                  ? ThemeColors(context).error.withValues(alpha: 0.3)
                  : ThemeColors(context).primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and loading indicator
              if (warmingModels.isNotEmpty) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      ThemeColors(context).primary,
                    ),
                  ),
                ),
              ] else if (hasError) ...[
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: ThemeColors(context).error,
                ),
              ],
              
              const SizedBox(width: SpacingTokens.xs),
              
              // Status text
              Text(
                _getStatusText(warmingModels.length, hasError, statusMap),
                style: TextStyles.bodySmall.copyWith(
                  color: hasError 
                      ? ThemeColors(context).error
                      : ThemeColors(context).primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              // Close button for errors or expandable details for other states
              if (hasError) ...[
                const SizedBox(width: SpacingTokens.sm),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isDismissed = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: ThemeColors(context).error,
                    ),
                  ),
                ),
              ] else if (statusMap.isNotEmpty) ...[
                const SizedBox(width: SpacingTokens.xs),
                
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: ThemeColors(context).primary,
                  ),
                  offset: const Offset(0, 30),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          'AI Models (${statusMap.length})',
                          style: TextStyles.bodySmall.copyWith(
                            color: ThemeColors(context).onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      ...statusMap.values.map((status) {
                        return PopupMenuItem<String>(
                          value: status.modelId,
                          child: Row(
                            children: [
                              // Status indicator
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(context, status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              
                              const SizedBox(width: SpacingTokens.sm),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      status.modelName,
                                      style: TextStyles.bodyMedium,
                                    ),
                                    Text(
                                      _getModelStatusText(status),
                                      style: TextStyles.bodySmall.copyWith(
                                        color: _getStatusColor(context, status),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Status icon
                              Icon(
                                _getStatusIcon(status),
                                size: 16,
                                color: _getStatusColor(context, status),
                              ),
                            ],
                          ),
                        );
                      }),
                    ];
                  },
                  onSelected: (modelId) {
                    // Could add model-specific actions here
                  },
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }
  
  String _getStatusText(int warmingCount, bool hasError, Map<String, ModelWarmUpStatus> statusMap) {
    if (hasError) {
      // Check if some models are ready while others failed
      final hasReady = statusMap.values.any((s) => s.isReady);
      if (hasReady) {
        return 'Not all models loaded';
      }
      return 'Model setup failed';
    }
    if (warmingCount > 0) {
      return 'Preparing AI models...';
    }
    return 'Models ready';
  }
  
  Color _getStatusColor(BuildContext context, ModelWarmUpStatus status) {
    if (status.hasError) {
      return ThemeColors(context).error;
    } else if (status.isReady) {
      return Colors.green;
    } else if (status.isWarming) {
      return Colors.orange;
    } else {
      return ThemeColors(context).onSurfaceVariant;
    }
  }
  
  IconData _getStatusIcon(ModelWarmUpStatus status) {
    if (status.hasError) {
      return Icons.error;
    } else if (status.isReady) {
      return Icons.check_circle;
    } else if (status.isWarming) {
      return Icons.hourglass_empty;
    } else {
      return Icons.circle;
    }
  }
  
  String _getModelStatusText(ModelWarmUpStatus status) {
    if (status.hasError) {
      return 'Setup failed';
    } else if (status.isReady) {
      return 'Ready';
    } else if (status.isWarming) {
      return 'Preparing...';
    } else {
      return 'Waiting';
    }
  }
}
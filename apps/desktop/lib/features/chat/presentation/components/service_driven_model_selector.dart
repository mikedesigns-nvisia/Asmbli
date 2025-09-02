import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/model_config_service.dart';

/// Service-driven model selector - connects to real ModelConfigService
class ServiceDrivenModelSelector extends ConsumerWidget {
  const ServiceDrivenModelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch real services - no hardcoding
    final selectedModel = ref.watch(selectedModelProvider);
    final allModels = ref.watch(allModelConfigsProvider);
    final readyModels = ref.watch(readyModelConfigsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.md,
      ),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: ThemeColors(context).border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Model type icon (local vs API)
          Icon(
            selectedModel?.isLocal == true ? Icons.computer : Icons.cloud,
            color: selectedModel?.isLocal == true 
                ? ThemeColors(context).primary
                : ThemeColors(context).accent,
            size: 18,
          ),
          
          const SizedBox(width: SpacingTokens.sm),
          
          // Model name and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedModel?.name ?? 'No model selected',
                style: TextStyles.bodyMedium.copyWith(
                  color: ThemeColors(context).onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getStatusText(selectedModel),
                style: TextStyles.bodySmall.copyWith(
                  color: _getStatusColor(context, selectedModel),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: SpacingTokens.sm),
          
          // Dropdown for model selection
          PopupMenuButton<String>(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: ThemeColors(context).onSurface,
            ),
            offset: const Offset(0, 40),
            itemBuilder: (context) {
              return [
                // Local models section
                if (readyModels.any((m) => m.isLocal)) ...[
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'Local Models',
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...readyModels
                      .where((model) => model.isLocal)
                      .map((model) => PopupMenuItem<String>(
                            value: model.id,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.computer,
                                  color: ThemeColors(context).primary,
                                  size: 16,
                                ),
                                const SizedBox(width: SpacingTokens.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        model.name,
                                        style: TextStyles.bodyMedium,
                                      ),
                                      Text(
                                        _getModelDescription(model),
                                        style: TextStyles.bodySmall.copyWith(
                                          color: ThemeColors(context).onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedModel?.id == model.id)
                                  Icon(
                                    Icons.check,
                                    color: ThemeColors(context).primary,
                                    size: 16,
                                  ),
                              ],
                            ),
                          )),
                ],
                
                // API models section
                if (readyModels.any((m) => !m.isLocal)) ...[
                  if (readyModels.any((m) => m.isLocal))
                    const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'API Models',
                      style: TextStyles.bodySmall.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...readyModels
                      .where((model) => !model.isLocal)
                      .map((model) => PopupMenuItem<String>(
                            value: model.id,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud,
                                  color: ThemeColors(context).accent,
                                  size: 16,
                                ),
                                const SizedBox(width: SpacingTokens.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        model.name,
                                        style: TextStyles.bodyMedium,
                                      ),
                                      Text(
                                        _getModelDescription(model),
                                        style: TextStyles.bodySmall.copyWith(
                                          color: ThemeColors(context).onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedModel?.id == model.id)
                                  Icon(
                                    Icons.check,
                                    color: ThemeColors(context).primary,
                                    size: 16,
                                  ),
                              ],
                            ),
                          )),
                ],
                
                // No models available
                if (readyModels.isEmpty)
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'No models available',
                      style: TextStyles.bodyMedium.copyWith(
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                    ),
                  ),
              ];
            },
            onSelected: (modelId) {
              // Update selected model through service
              ref.read(selectedModelProvider.notifier).state = 
                  allModels[modelId];
            },
          ),
        ],
      ),
    );
  }

  String _getStatusText(dynamic model) {
    if (model == null) return 'Select a model';
    
    if (model.isLocal) {
      switch (model.status?.name) {
        case 'ready': return 'Ready';
        case 'downloading': return 'Downloading...';
        case 'error': return 'Error';
        default: return 'Not ready';
      }
    } else {
      return model.isConfigured ? 'Ready' : 'Needs API key';
    }
  }

  Color _getStatusColor(BuildContext context, dynamic model) {
    if (model == null) return ThemeColors(context).onSurfaceVariant;
    
    if (model.isLocal) {
      switch (model.status?.name) {
        case 'ready': return ThemeColors(context).primary;
        case 'downloading': return ThemeColors(context).accent;
        case 'error': return Colors.red;
        default: return ThemeColors(context).onSurfaceVariant;
      }
    } else {
      return model.isConfigured 
          ? ThemeColors(context).primary 
          : ThemeColors(context).onSurfaceVariant;
    }
  }

  String _getModelDescription(dynamic model) {
    if (model.isLocal) {
      return '${model.ollamaModelId ?? 'Local'} • ${_getStatusText(model)}';
    } else {
      return '${model.provider} • ${model.isConfigured ? 'Ready' : 'Configure API key'}';
    }
  }
}
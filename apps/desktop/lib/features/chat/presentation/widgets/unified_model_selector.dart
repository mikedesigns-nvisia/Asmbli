import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/models/model_config.dart';
import '../../../../core/services/model_config_service.dart';

/// Unified model selector supporting both local and API models
class UnifiedModelSelector extends ConsumerStatefulWidget {
  const UnifiedModelSelector({super.key});

  @override
  ConsumerState<UnifiedModelSelector> createState() => _UnifiedModelSelectorState();
}

class _UnifiedModelSelectorState extends ConsumerState<UnifiedModelSelector> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allModels = ref.watch(allModelConfigsProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    
    // Separate models by type
    final localModels = allModels.values.where((m) => m.isLocal).toList();
    final apiModels = allModels.values.where((m) => m.isApi).toList();
    
    // Get selected model ID
    final selectedModelId = allModels.isEmpty ? '__loading__' : selectedModel?.id;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModelDropdown(theme, localModels, apiModels, selectedModelId),
        if (selectedModelId != null && selectedModelId != '__loading__')
          _buildModelInfoPanel(_getSelectedModel(allModels)),
      ],
    );
  }

  Widget _buildModelDropdown(ThemeData theme, List<ModelConfig> localModels, List<ModelConfig> apiModels, String? selectedModelId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.surface.withOpacity(0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedModelId,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          items: [
            // Loading state
            if (localModels.isEmpty && apiModels.isEmpty)
              DropdownMenuItem<String>(
                value: '__loading__',
                child: SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading models...',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Local models section
            if (localModels.isNotEmpty) ...[
              _buildSectionHeader('LOCAL MODELS', Icons.computer, ThemeColors(context).primary),
              ..._buildLocalModelItems(localModels),
            ],

            // API models section  
            if (apiModels.isNotEmpty) ...[
              if (localModels.isNotEmpty) _buildDivider(),
              _buildSectionHeader('API MODELS', Icons.cloud, ThemeColors(context).accent),
              ..._buildApiModelItems(apiModels),
            ],

            // Action items
            if (localModels.isNotEmpty || apiModels.isNotEmpty) ...[
              _buildDivider(),
              _buildActionItem('Download Local Model', Icons.download, '__download_model__'),
              _buildActionItem('Add API Key', Icons.add_circle_outline, '__add_api_key__'),
              _buildActionItem('Model Settings', Icons.settings, '__model_settings__'),
            ],
          ],
          onChanged: _onModelChanged,
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildSectionHeader(String title, IconData icon, Color color) {
    return DropdownMenuItem<String>(
      enabled: false,
      value: '__${title.toLowerCase().replaceAll(' ', '_')}__',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildLocalModelItems(List<ModelConfig> localModels) {
    return localModels.map((model) => DropdownMenuItem<String>(
      value: model.id,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            _buildStatusIndicator(model.status),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    model.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (model.status == ModelStatus.downloading && model.downloadProgress != null)
                    Text(
                      '${(model.downloadProgress! * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
            if (model.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors(context).primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    )).toList();
  }

  List<DropdownMenuItem<String>> _buildApiModelItems(List<ModelConfig> apiModels) {
    return apiModels.map((model) => DropdownMenuItem<String>(
      value: model.id,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            _buildStatusIndicator(model.status),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                model.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (model.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors(context).primary,
                  ),
                ),
              ),
            if (!model.isConfigured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ThemeColors(context).error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'NO KEY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors(context).error,
                  ),
                ),
              ),
          ],
        ),
      ),
    )).toList();
  }

  Widget _buildStatusIndicator(ModelStatus status) {
    Color color;
    IconData? icon;
    
    switch (status) {
      case ModelStatus.ready:
        color = ThemeColors(context).success;
        break;
      case ModelStatus.downloading:
      case ModelStatus.loading:
        color = Colors.blue;
        icon = Icons.downloading;
        break;
      case ModelStatus.needsSetup:
        color = Colors.orange;
        icon = Icons.download_outlined;
        break;
      case ModelStatus.error:
        color = ThemeColors(context).error;
        icon = Icons.error_outline;
        break;
    }
    
    if (icon != null) {
      return Icon(icon, size: 12, color: color);
    } else {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }
  }

  DropdownMenuItem<String> _buildDivider() {
    return const DropdownMenuItem<String>(
      enabled: false,
      value: '__divider__',
      child: Divider(height: 1),
    );
  }

  DropdownMenuItem<String> _buildActionItem(String title, IconData icon, String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: ThemeColors(context).primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ThemeColors(context).primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelInfoPanel(ModelConfig? model) {
    if (model == null) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: model.isLocal 
            ? ThemeColors(context).primary.withOpacity(0.3)
            : ThemeColors(context).accent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                model.isLocal ? Icons.computer : Icons.cloud,
                size: 16,
                color: model.isLocal 
                  ? ThemeColors(context).primary 
                  : ThemeColors(context).accent,
              ),
              const SizedBox(width: 6),
              Text(
                model.isLocal ? 'Running Locally' : 'Using API',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildPerformanceIndicator(model),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getModelDescription(model),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_shouldShowActionButton(model))
            _buildActionButton(model),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(ModelConfig model) {
    if (model.isLocal) {
      switch (model.status) {
        case ModelStatus.ready:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ThemeColors(context).success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'READY',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: ThemeColors(context).success,
              ),
            ),
          );
        case ModelStatus.downloading:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'DOWNLOADING',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          );
        default:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'SETUP NEEDED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          );
      }
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: model.isConfigured 
            ? ThemeColors(context).accent.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          model.isConfigured ? 'CONFIGURED' : 'NEEDS KEY',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: model.isConfigured 
              ? ThemeColors(context).accent 
              : Colors.grey,
          ),
        ),
      );
    }
  }

  String _getModelDescription(ModelConfig model) {
    if (model.isLocal) {
      switch (model.status) {
        case ModelStatus.ready:
          return 'Private, runs on your device. Fast responses.';
        case ModelStatus.downloading:
          return 'Downloading model to your device...';
        case ModelStatus.needsSetup:
          return 'Download this model to use it locally (${model.displaySize}).';
        default:
          return 'Local model not available.';
      }
    } else {
      if (model.isConfigured) {
        return 'Most capable. Uses your API key (~\$0.01 per message).';
      } else {
        return 'Configure your API key to use this model.';
      }
    }
  }

  bool _shouldShowActionButton(ModelConfig model) {
    if (model.isLocal) {
      return model.status == ModelStatus.needsSetup || model.status == ModelStatus.downloading;
    } else {
      return !model.isConfigured;
    }
  }

  Widget _buildActionButton(ModelConfig model) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (model.isLocal && model.status == ModelStatus.needsSetup)
            Expanded(
              child: AsmblButton.secondary(
                text: 'Download (${model.displaySize})',
                onPressed: () => _downloadModel(model),
              ),
            ),
          if (model.isLocal && model.status == ModelStatus.downloading) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              model.downloadProgress != null 
                ? 'Downloading... ${(model.downloadProgress! * 100).toInt()}%'
                : 'Downloading...',
              style: const TextStyle(fontSize: 11),
            ),
          ],
          if (model.isApi && !model.isConfigured)
            Expanded(
              child: AsmblButton.secondary(
                text: 'Configure API Key',
                onPressed: () => _configureApiKey(),
              ),
            ),
        ],
      ),
    );
  }

  ModelConfig? _getSelectedModel(Map<String, ModelConfig> allModels) {
    final selectedModel = ref.read(selectedModelProvider);
    return selectedModel;
  }

  void _onModelChanged(String? value) async {
    if (value == null) return;
    
    switch (value) {
      case '__download_model__':
        _showDownloadModelDialog();
        break;
      case '__add_api_key__':
        _configureApiKey();
        break;
      case '__model_settings__':
        context.go(AppRoutes.settings);
        break;
      default:
        if (!value.startsWith('__')) {
          // Find the model and update the provider
          final allModels = ref.read(allModelConfigsProvider);
          final model = allModels[value];
          if (model != null) {
            ref.read(selectedModelProvider.notifier).state = model;
          }
          _showModelSwitchedSnackbar(value);
          
          // Set as default model
          try {
            await ref.read(modelConfigsProvider.notifier).setDefault(value);
          } catch (e) {
            print('Failed to set default model: $e');
          }
        }
        break;
    }
  }

  void _downloadModel(ModelConfig model) async {
    try {
      await ref.read(modelConfigsProvider.notifier).downloadModel(
        model.id,
        onProgress: (progress) {
          // Progress is automatically handled by the state notifier
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} download started'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${model.name}: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  void _configureApiKey() {
    context.go(AppRoutes.settings);
  }

  void _showDownloadModelDialog() {
    // TODO: Implement download model dialog showing available models
    context.go(AppRoutes.settings);
  }

  void _showModelSwitchedSnackbar(String modelId) {
    final allModels = ref.read(allModelConfigsProvider);
    final model = allModels[modelId];
    
    if (model != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Switched to ${model.name}'),
            ],
          ),
          backgroundColor: ThemeColors(context).success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
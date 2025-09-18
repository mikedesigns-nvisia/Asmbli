import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/model_config.dart';
import '../../../../core/services/model_config_service.dart';
import 'ollama_setup_dialog.dart';

/// Widget for managing local model downloads
class ModelDownloadManager extends ConsumerWidget {
  const ModelDownloadManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = ThemeColors(context);
    
    final availableModels = ref.watch(availableModelConfigsProvider);
    final localModels = ref.watch(localModelConfigsProvider);
    final modelConfigService = ref.read(modelConfigServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.elementSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local Models',
                style: GoogleFonts.fustat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: SpacingTokens.iconSpacing),
              Text(
                'Download and manage local LLM models for offline AI capabilities',
                style: GoogleFonts.fustat(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: SpacingTokens.sectionSpacing),

        // Available models for download
        if (availableModels.isNotEmpty) ...[
          _buildSectionHeader('Available for Download', icon: Icons.download, theme: theme),
          const SizedBox(height: SpacingTokens.componentSpacing),
          ...availableModels.entries.map((entry) => 
            _buildAvailableModelCard(entry.value, modelConfigService, theme, colors, ref)
          ),
          const SizedBox(height: SpacingTokens.sectionSpacing),
        ],

        // Downloaded/installed models
        if (localModels.isNotEmpty) ...[
          _buildSectionHeader('Downloaded Models', icon: Icons.check_circle, theme: theme),
          const SizedBox(height: SpacingTokens.componentSpacing),
          ...localModels.entries.map((entry) => 
            _buildInstalledModelCard(entry.value, modelConfigService, theme, colors, ref)
          ),
        ],

        // Empty state if no models
        if (availableModels.isEmpty && localModels.isEmpty) ...[
          _buildEmptyState(context, theme, colors),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, {required IconData icon, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.elementSpacing),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: SpacingTokens.iconSpacing),
          Text(
            title,
            style: GoogleFonts.fustat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableModelCard(
    ModelConfig model, 
    ModelConfigService service, 
    ThemeData theme, 
    ThemeColors colors, 
    WidgetRef ref
  ) {
    final isDownloading = service.isModelDownloading(model.id);
    final downloadProgress = service.getDownloadProgress(model.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.elementSpacing,
        vertical: SpacingTokens.componentSpacing,
      ),
      padding: const EdgeInsets.all(SpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity( 0.7),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity( 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.memory,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: GoogleFonts.fustat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${model.provider} ${model.model}',
                      style: GoogleFonts.fustat(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.componentSpacing),

          // Model details
          Wrap(
            spacing: SpacingTokens.componentSpacing,
            runSpacing: SpacingTokens.iconSpacing,
            children: [
              _buildModelChip('Size: ${_formatModelSize(model.modelSize)}', Icons.storage, theme),
              ...model.capabilities.take(3).map((cap) => 
                _buildModelChip(cap.toUpperCase(), Icons.star, theme)
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.componentSpacing),

          // Download progress or button
          if (isDownloading && downloadProgress != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Downloading... ${(downloadProgress * 100).toInt()}%',
                  style: GoogleFonts.fustat(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: downloadProgress,
                  backgroundColor: theme.colorScheme.outline.withOpacity( 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: AsmblButton.primary(
                text: 'Download Model',
                onPressed: () => _downloadModel(model, service, ref),
                icon: Icons.download,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstalledModelCard(
    ModelConfig model, 
    ModelConfigService service, 
    ThemeData theme, 
    ThemeColors colors, 
    WidgetRef ref
  ) {
    final isReady = model.status == ModelStatus.ready;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.elementSpacing,
        vertical: SpacingTokens.componentSpacing,
      ),
      padding: const EdgeInsets.all(SpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: isReady 
          ? colors.success.withOpacity( 0.05)
          : theme.colorScheme.surface.withOpacity( 0.7),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: isReady 
            ? colors.success.withOpacity( 0.3)
            : theme.colorScheme.outline.withOpacity( 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isReady 
                    ? colors.success.withOpacity( 0.1)
                    : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isReady ? Icons.check_circle : Icons.memory,
                  size: 20,
                  color: isReady ? colors.success : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: GoogleFonts.fustat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getStatusColor(model.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(model.status),
                          style: GoogleFonts.fustat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(model.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleModelAction(value, model, service, ref),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: colors.error),
                        const SizedBox(width: 8),
                        const Text('Remove Model'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.componentSpacing),

          // Model details
          Wrap(
            spacing: SpacingTokens.componentSpacing,
            runSpacing: SpacingTokens.iconSpacing,
            children: [
              if (model.modelSize != null)
                _buildModelChip('Size: ${_formatModelSize(model.modelSize)}', Icons.storage, theme),
              ...model.capabilities.take(3).map((cap) => 
                _buildModelChip(cap.toUpperCase(), Icons.star, theme)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelChip(String text, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.fustat(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, ThemeColors colors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(SpacingTokens.sectionSpacing),
        padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity( 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.download,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            Text(
              'No Local Models Available',
              style: GoogleFonts.fustat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Local model downloads will be available once the\nOllama service is properly configured.',
              style: GoogleFonts.fustat(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            AsmblButton.primary(
              text: 'Set Up Ollama',
              onPressed: () => OllamaSetupDialog.show(context),
              icon: Icons.download,
            ),
          ],
        ),
      ),
    );
  }

  String _formatModelSize(int? sizeInBytes) {
    if (sizeInBytes == null) return 'Unknown';
    
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = sizeInBytes.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  Color _getStatusColor(ModelStatus status) {
    switch (status) {
      case ModelStatus.ready:
        return Colors.green;
      case ModelStatus.downloading:
        return Colors.blue;
      case ModelStatus.error:
        return Colors.red;
      case ModelStatus.loading:
        return Colors.orange;
      case ModelStatus.needsSetup:
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(ModelStatus status) {
    switch (status) {
      case ModelStatus.ready:
        return 'READY';
      case ModelStatus.downloading:
        return 'DOWNLOADING';
      case ModelStatus.error:
        return 'ERROR';
      case ModelStatus.loading:
        return 'LOADING';
      case ModelStatus.needsSetup:
        return 'NEEDS SETUP';
    }
  }

  void _downloadModel(ModelConfig model, ModelConfigService service, WidgetRef ref) async {
    try {
      await service.downloadModel(
        model.id,
        onProgress: (progress) {
          // Progress updates are handled by the provider watching
          ref.invalidate(localModelConfigsProvider);
        },
      );
    } catch (e) {
      print('Failed to download model ${model.name}: $e');
      // TODO: Show error dialog
    }
  }

  void _handleModelAction(String action, ModelConfig model, ModelConfigService service, WidgetRef ref) async {
    switch (action) {
      case 'remove':
        try {
          await service.removeLocalModel(model.id);
          ref.invalidate(localModelConfigsProvider);
        } catch (e) {
          print('Failed to remove model ${model.name}: $e');
          // TODO: Show error dialog
        }
        break;
    }
  }
}
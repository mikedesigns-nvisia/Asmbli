import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/model_config.dart';
import '../../../../core/services/model_config_service.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/model_download_manager.dart';
import '../widgets/ollama_setup_dialog.dart';

/// Clean, unified LLM Configuration screen
/// Directly controls what models appear in chat - no dummy data
class LLMConfigurationScreen extends ConsumerStatefulWidget {
  const LLMConfigurationScreen({super.key});

  @override
  ConsumerState<LLMConfigurationScreen> createState() => _LLMConfigurationScreenState();
}

class _LLMConfigurationScreenState extends ConsumerState<LLMConfigurationScreen> {
  String _selectedFilter = 'all'; // 'all', 'cloud', 'local'
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ThemeColors(context);
    final allModels = ref.watch(allModelConfigsProvider);
    final configuredModels = allModels.values.where((m) => m.isConfigured).toList();
    
    // Apply filtering
    final filteredModels = configuredModels.where((model) {
      switch (_selectedFilter) {
        case 'cloud':
          return model.isApi;
        case 'local':
          return model.isLocal;
        case 'all':
        default:
          return true;
      }
    }).toList();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(SpacingTokens.headerPadding),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity( 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: colors.border.withOpacity( 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: colors.onSurface),
                  ),
                  const SizedBox(width: SpacingTokens.componentSpacing),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Models',
                        style: GoogleFonts.fustat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        'Add AI assistants to chat with',
                        style: GoogleFonts.fustat(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Filter buttons
                  if (configuredModels.isNotEmpty) ...[
                    _buildFilterChips(colors),
                    const SizedBox(width: SpacingTokens.componentSpacing),
                  ],
                  AsmblButton.primary(
                    text: 'Add AI',
                    icon: Icons.add,
                    onPressed: _showAddModelOptions,
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (configuredModels.isEmpty) ...[
                          _buildEmptyState(colors, theme),
                        ] else ...[
                          _buildConfiguredModels(filteredModels, colors, theme, configuredModels),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors, ThemeData theme) {
    return Center(
      child: AsmblCard(
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.psychology,
                  size: 48,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: SpacingTokens.sectionSpacing),
              Text(
                'Ready to Get Started?',
                style: GoogleFonts.fustat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: SpacingTokens.componentSpacing),
              Text(
                'Add your first AI assistant to start chatting.\nConnect to services like ChatGPT or Claude, or install a local AI.',
                style: GoogleFonts.fustat(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacingTokens.sectionSpacing),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: SpacingTokens.componentSpacing,
                runSpacing: SpacingTokens.componentSpacing,
                children: [
                  AsmblButton.primary(
                    text: 'Connect Cloud AI',
                    icon: Icons.cloud,
                    onPressed: _showAddApiKeyDialog,
                  ),
                  AsmblButton.secondary(
                    text: 'Install Ollama',
                    icon: Icons.download,
                    onPressed: () => OllamaSetupDialog.show(context),
                  ),
                  AsmblButton.secondary(
                    text: 'Download Models',
                    icon: Icons.computer,
                    onPressed: _showLocalModelOptions,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeColors colors) {
    return Row(
      children: [
        _buildFilterChip('All', 'all', colors),
        const SizedBox(width: SpacingTokens.iconSpacing),
        _buildFilterChip('Cloud', 'cloud', colors),
        const SizedBox(width: SpacingTokens.iconSpacing),
        _buildFilterChip('Local', 'local', colors),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeColors colors) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface.withOpacity( 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border.withOpacity( 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.fustat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : colors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguredModels(List<ModelConfig> filteredModels, ThemeColors colors, ThemeData theme, List<ModelConfig> allModels) {
    final defaultModel = ref.watch(defaultModelConfigProvider);
    
    // Show filtered results or show nothing when filter doesn't match
    if (filteredModels.isEmpty) {
      return _buildNoResultsState(colors, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtered models - show based on current filter
        if (_selectedFilter == 'all' || _selectedFilter == 'cloud') ...[
          // Cloud AI Services Section
          ...filteredModels.where((m) => m.isApi).map((model) => _buildModelCard(
            model, 
            isDefault: defaultModel?.id == model.id,
            colors: colors,
            theme: theme,
          )),
        ],

        if (_selectedFilter == 'all' || _selectedFilter == 'local') ...[
          // Local AI Models Section  
          ...filteredModels.where((m) => m.isLocal).map((model) => _buildModelCard(
            model,
            isDefault: defaultModel?.id == model.id,
            colors: colors, 
            theme: theme,
          )),
        ],

        // Add more models
        AsmblCard(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: colors.primary),
            ),
            title: Text(
              'Add Another AI',
              style: GoogleFonts.fustat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            subtitle: Text(
              'Connect more AI services or install additional models',
              style: GoogleFonts.fustat(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: colors.onSurfaceVariant),
            onTap: _showAddModelOptions,
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState(ThemeColors colors, ThemeData theme) {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'cloud':
        message = 'No cloud AI services configured.\nTap "Add AI" to connect ChatGPT, Claude, or other services.';
        icon = Icons.cloud_off;
        break;
      case 'local':
        message = 'No local AI models installed.\nTap "Add AI" to download and run models locally.';
        icon = Icons.laptop_chromebook;
        break;
      default:
        message = 'No AI assistants found.';
        icon = Icons.search_off;
    }
    
    return Center(
      child: AsmblCard(
        child: Container(
          padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: SpacingTokens.sectionSpacing),
              Text(
                'No Results',
                style: GoogleFonts.fustat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: SpacingTokens.componentSpacing),
              Text(
                message,
                style: GoogleFonts.fustat(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SpacingTokens.sectionSpacing),
              if (_selectedFilter == 'local') ...[
                // For local filter, show Install Ollama + Download Models buttons
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: SpacingTokens.componentSpacing,
                  runSpacing: SpacingTokens.componentSpacing,
                  children: [
                    AsmblButton.primary(
                      text: 'Install Ollama',
                      icon: Icons.download,
                      onPressed: () => OllamaSetupDialog.show(context),
                    ),
                    AsmblButton.secondary(
                      text: 'Download Models',
                      icon: Icons.computer,
                      onPressed: _showLocalModelOptions,
                    ),
                  ],
                ),
              ] else ...[
                // For other filters, show generic Add AI button
                AsmblButton.primary(
                  text: 'Add AI',
                  icon: Icons.add,
                  onPressed: _showAddModelOptions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeColors colors) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: SpacingTokens.iconSpacing),
        Text(
          title,
          style: GoogleFonts.fustat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildModelCard(ModelConfig model, {required bool isDefault, required ThemeColors colors, required ThemeData theme}) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.componentSpacing),
      child: AsmblCard(
        child: Container(
          decoration: BoxDecoration(
            border: isDefault ? Border.all(color: colors.primary, width: 2) : null,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.cardPadding),
            child: Row(
              children: [
                // Model Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: model.isApi 
                      ? colors.primary.withOpacity( 0.1)
                      : colors.accent.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    model.isApi ? Icons.cloud : Icons.computer,
                    color: model.isApi ? colors.primary : colors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: SpacingTokens.componentSpacing),

                // Model Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            model.name,
                            style: GoogleFonts.fustat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: SpacingTokens.iconSpacing),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: GoogleFonts.fustat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${model.provider} • ${model.model}',
                        style: GoogleFonts.fustat(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) => _handleModelAction(value, model),
                  itemBuilder: (context) => [
                    if (!isDefault)
                      PopupMenuItem(
                        value: 'set_default',
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 16, color: colors.primary),
                            const SizedBox(width: 8),
                            const Text('Set as Default'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'test',
                      child: Row(
                        children: [
                          Icon(Icons.speed, size: 16, color: colors.onSurface),
                          const SizedBox(width: 8),
                          const Text('Test Connection'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: colors.onSurface),
                          const SizedBox(width: 8),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: colors.error),
                          const SizedBox(width: 8),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity( 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddModelOptions() {
    final colors = ThemeColors(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add AI Assistant',
          style: GoogleFonts.fustat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.border.withOpacity( 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud, color: Colors.blue),
                ),
                title: Text(
                  'Cloud AI Service',
                  style: GoogleFonts.fustat(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'ChatGPT, Claude, Gemini, and more\nRequires API key from provider',
                  style: GoogleFonts.fustat(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddApiKeyDialog();
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.border.withOpacity( 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download, color: Colors.orange),
                ),
                title: Text(
                  'Install Ollama',
                  style: GoogleFonts.fustat(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Set up Ollama to run local AI models\nPrivate, secure, and fast',
                  style: GoogleFonts.fustat(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  OllamaSetupDialog.show(context);
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.border.withOpacity( 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.computer, color: Colors.green),
                ),
                title: Text(
                  'Download Local Models',
                  style: GoogleFonts.fustat(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Download AI models to run locally\nRequires Ollama to be installed',
                  style: GoogleFonts.fustat(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLocalModelOptions();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => const ApiKeyDialog(),
    );
  }

  void _showLocalModelOptions() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Local Models'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: ModelDownloadManager(),
        ),
      ),
    );
  }

  void _handleModelAction(String action, ModelConfig model) async {
    final modelConfigService = ref.read(modelConfigServiceProvider);
    
    switch (action) {
      case 'set_default':
        await modelConfigService.setDefaultModel(model.id);
        break;
      case 'test':
        _testModel(model);
        break;
      case 'edit':
        if (model.isApi) {
          showDialog(
            context: context,
            builder: (context) => ApiKeyDialog(
              existingModelConfig: model,
            ),
          );
        }
        break;
      case 'delete':
        _deleteModel(model);
        break;
    }
  }

  void _testModel(ModelConfig model) {
    // TODO: Implement model connection testing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Testing ${model.name}...')),
    );
  }

  void _deleteModel(ModelConfig model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${model.name}?'),
        content: const Text('This will remove the model from your configuration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final modelConfigs = ref.read(modelConfigsProvider.notifier);
              await modelConfigs.removeModel(model.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
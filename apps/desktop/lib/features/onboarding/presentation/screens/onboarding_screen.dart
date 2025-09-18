import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/services/desktop/desktop_storage_service.dart';
import '../../../../core/services/ollama_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../settings/presentation/widgets/ollama_setup_dialog.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _apiKeyController = TextEditingController();
  String _selectedProvider = 'anthropic';
  bool _isValidating = false;
  String? _errorMessage;
  bool _isCheckingOllama = false;
  bool _ollamaAvailable = false;

  final Map<String, ProviderInfo> _providers = {
    'anthropic': const ProviderInfo(
      name: 'Claude (Anthropic)',
      icon: Icons.psychology,
      apiUrl: 'https://console.anthropic.com/account/keys',
      description: 'Most capable for complex tasks',
      models: ['claude-3-5-sonnet-20241022', 'claude-3-opus-20240229'],
      baseUrl: 'https://api.anthropic.com',
      requiresApiKey: true,
    ),
    'openai': const ProviderInfo(
      name: 'OpenAI',
      icon: Icons.auto_awesome,
      apiUrl: 'https://platform.openai.com/api-keys',
      description: 'GPT-4 and GPT-3.5 models',
      models: ['gpt-4-turbo-preview', 'gpt-3.5-turbo'],
      baseUrl: 'https://api.openai.com/v1',
      requiresApiKey: true,
    ),
    'google': const ProviderInfo(
      name: 'Google Gemini',
      icon: Icons.star,
      apiUrl: 'https://makersuite.google.com/app/apikey',
      description: 'Gemini Pro models',
      models: ['gemini-pro', 'gemini-pro-vision'],
      baseUrl: 'https://generativelanguage.googleapis.com',
      requiresApiKey: true,
    ),
    'ollama': const ProviderInfo(
      name: 'Ollama (Local)',
      icon: Icons.computer,
      apiUrl: 'https://ollama.ai/download',
      description: 'Run models locally on your device',
      models: ['llama2', 'mistral', 'codellama'],
      baseUrl: 'http://127.0.0.1:11434',
      requiresApiKey: false,
    ),
  };

  @override
  void initState() {
    super.initState();
    _checkOllamaAvailability();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkOllamaAvailability() async {
    setState(() => _isCheckingOllama = true);
    try {
      final ollamaService = ServiceLocator.instance.get<OllamaService>();
      final available = await ollamaService.isAvailable;
      setState(() => _ollamaAvailable = available);
    } catch (e) {
      setState(() => _ollamaAvailable = false);
    } finally {
      setState(() => _isCheckingOllama = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _saveAndContinue() async {
    final provider = _providers[_selectedProvider]!;
    
    // Handle Ollama differently - no API key required
    if (_selectedProvider == 'ollama') {
      if (!_ollamaAvailable) {
        // Show Ollama setup dialog
        if (mounted) {
          OllamaSetupDialog.show(context);
        }
        return;
      }
      // Ollama is available, proceed without API key
    } else {
      // For API providers, validate API key
      if (_apiKeyController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter an API key';
        });
        return;
      }
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      if (_selectedProvider == 'ollama') {
        // For Ollama, just mark as using local models
        final storage = DesktopStorageService.instance;
        await storage.setPreference('uses_ollama', true);
        await storage.setPreference('default_provider', 'ollama');
      } else {
        // Save API configuration for cloud providers
        final config = ApiConfig(
          id: '$_selectedProvider-primary',
          name: provider.name,
          provider: _selectedProvider,
          model: provider.models.first,
          apiKey: _apiKeyController.text.trim(),
          baseUrl: provider.baseUrl,
          isDefault: true,
          enabled: true,
        );

        final apiService = ref.read(apiConfigServiceProvider);
        await apiService.setApiConfig(config.id, config);
        await apiService.setDefaultApiConfig(config.id);
      }

      // Mark onboarding as complete
      final storage = DesktopStorageService.instance;
      await storage.setPreference('onboarding_completed', true);
      await storage.setPreference('onboarding_date', DateTime.now().toIso8601String());

      // Navigate to home
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save configuration: ${e.toString()}';
        _isValidating = false;
      });
    }
  }

  Future<void> _skipForNow() async {
    try {
      // Mark as skipped but not completed - user can still set up providers later
      final storage = DesktopStorageService.instance;
      await storage.setPreference('onboarding_skipped', true);
      await storage.setPreference('onboarding_completed', true); // Still mark as completed to not show again
      await storage.setPreference('onboarding_date', DateTime.now().toIso8601String());
      await storage.setPreference('providers_skipped', true); // Flag to show setup reminder later
      
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      print('Error skipping onboarding: $e');
      // Still navigate even if preferences fail
      if (mounted) {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final provider = _providers[_selectedProvider]!;

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
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingTokens.pageHorizontal),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome Header
                    Icon(
                      Icons.rocket_launch,
                      size: 64,
                      color: colors.primary,
                    ),
                    const SizedBox(height: SpacingTokens.xl),
                    Text(
                      'Welcome to Asmbli',
                      style: TextStyles.pageTitle.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    Text(
                      'Let\'s get you started with your AI assistant',
                      style: TextStyles.bodyLarge.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: SpacingTokens.sectionSpacing),

                    // Main Card
                    AsmblCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step indicator
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: SpacingTokens.sm,
                                    vertical: SpacingTokens.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity( 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Step 1 of 1',
                                    style: TextStyles.caption.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: SpacingTokens.lg),
                            
                            Text(
                              'Connect Your AI Provider',
                              style: TextStyles.sectionTitle.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: SpacingTokens.md),
                            
                            // Privacy message
                            Container(
                              padding: const EdgeInsets.all(SpacingTokens.md),
                              decoration: BoxDecoration(
                                color: colors.success.withOpacity( 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.success.withOpacity( 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 20,
                                    color: colors.success,
                                  ),
                                  const SizedBox(width: SpacingTokens.sm),
                                  Expanded(
                                    child: Text(
                                      'Your API key stays on your device. We never store or transmit it to our servers.',
                                      style: TextStyles.bodySmall.copyWith(
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: SpacingTokens.lg),
                            
                            // Provider Selection
                            Text(
                              'Select Provider',
                              style: TextStyles.labelLarge.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.sm),
                            
                            Wrap(
                              children: _providers.entries.map((entry) {
                                final isSelected = _selectedProvider == entry.key;
                                final isOllama = entry.key == 'ollama';
                                
                                return SizedBox(
                                  width: (MediaQuery.of(context).size.width - 120) / 2 - 8, // 2 columns
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedProvider = entry.key;
                                          _errorMessage = null;
                                          _apiKeyController.clear();
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(SpacingTokens.md),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                            ? colors.primary.withOpacity( 0.1)
                                            : colors.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected 
                                              ? colors.primary 
                                              : colors.border,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                Icon(
                                                  entry.value.icon,
                                                  size: 24,
                                                  color: isSelected 
                                                    ? colors.primary 
                                                    : colors.onSurfaceVariant,
                                                ),
                                                if (isOllama && _ollamaAvailable)
                                                  Positioned(
                                                    right: -2,
                                                    top: -2,
                                                    child: Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: colors.success,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: SpacingTokens.xs),
                                            Text(
                                              isOllama ? 'Ollama' : entry.value.name.split(' ').first,
                                              style: TextStyles.caption.copyWith(
                                                color: isSelected 
                                                  ? colors.primary 
                                                  : colors.onSurfaceVariant,
                                                fontWeight: isSelected 
                                                  ? FontWeight.bold 
                                                  : FontWeight.normal,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            if (isOllama)
                                              Text(
                                                _ollamaAvailable ? 'Available' : 'Not installed',
                                                style: TextStyles.caption.copyWith(
                                                  color: _ollamaAvailable 
                                                    ? colors.success 
                                                    : colors.onSurfaceVariant.withOpacity( 0.7),
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            const SizedBox(height: SpacingTokens.lg),
                            
                            // API Key Input (only show for non-Ollama providers)
                            if (_selectedProvider != 'ollama') ...[
                              Text(
                                'API Key',
                                style: TextStyles.labelLarge.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: SpacingTokens.sm),
                              
                              TextField(
                                controller: _apiKeyController,
                                obscureText: true,
                                style: TextStyles.bodyMedium.copyWith(
                                  color: colors.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'sk-...',
                                  hintStyle: TextStyles.bodyMedium.copyWith(
                                    color: colors.onSurfaceVariant.withOpacity( 0.5),
                                  ),
                                  filled: true,
                                  fillColor: colors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorText: _errorMessage,
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.paste, size: 20),
                                    onPressed: () async {
                                      final data = await Clipboard.getData('text/plain');
                                      if (data?.text != null) {
                                        _apiKeyController.text = data!.text!;
                                      }
                                    },
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: SpacingTokens.sm),
                              
                              // Get API Key Link
                              TextButton.icon(
                                onPressed: () => _launchUrl(provider.apiUrl),
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: Text('Get your ${provider.name} API key'),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.primary,
                                ),
                              ),
                            ] else ...[
                              // Ollama status message
                              Container(
                                padding: const EdgeInsets.all(SpacingTokens.md),
                                decoration: BoxDecoration(
                                  color: _ollamaAvailable 
                                    ? colors.success.withOpacity( 0.1)
                                    : colors.warning.withOpacity( 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _ollamaAvailable 
                                      ? colors.success.withOpacity( 0.3)
                                      : colors.warning.withOpacity( 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _ollamaAvailable ? Icons.check_circle : Icons.download,
                                      size: 20,
                                      color: _ollamaAvailable ? colors.success : colors.warning,
                                    ),
                                    const SizedBox(width: SpacingTokens.sm),
                                    Expanded(
                                      child: Text(
                                        _ollamaAvailable 
                                          ? 'Ollama is installed and running. You can use local models without an API key.'
                                          : 'Ollama is not installed. Click "Continue" to set up Ollama for local models.',
                                        style: TextStyles.bodySmall.copyWith(
                                          color: colors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: SpacingTokens.sm),
                              
                              // Download Ollama Link (if not available)
                              if (!_ollamaAvailable)
                                TextButton.icon(
                                  onPressed: () => _launchUrl(provider.apiUrl),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Download Ollama'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colors.primary,
                                  ),
                                ),
                            ],
                            
                            const SizedBox(height: SpacingTokens.xl),
                            
                            // Action Buttons
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _isValidating ? null : _skipForNow,
                                  style: TextButton.styleFrom(
                                    foregroundColor: colors.onSurfaceVariant,
                                  ),
                                  child: const Text('Skip for now'),
                                ),
                                const SizedBox(width: SpacingTokens.md),
                                Expanded(
                                  child: AsmblButton.primary(
                                    text: _isValidating 
                                      ? 'Saving...' 
                                      : (_selectedProvider == 'ollama' && !_ollamaAvailable)
                                        ? 'Set up Ollama'
                                        : 'Continue',
                                    onPressed: _isValidating ? null : _saveAndContinue,
                                    isLoading: _isValidating,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProviderInfo {
  final String name;
  final IconData icon;
  final String apiUrl;
  final String description;
  final List<String> models;
  final String baseUrl;
  final bool requiresApiKey;

  const ProviderInfo({
    required this.name,
    required this.icon,
    required this.apiUrl,
    required this.description,
    required this.models,
    required this.baseUrl,
    required this.requiresApiKey,
  });
}
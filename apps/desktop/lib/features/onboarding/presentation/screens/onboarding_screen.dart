import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/services/desktop/desktop_storage_service.dart';
import '../../../../core/services/desktop/desktop_service_provider.dart';

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

  final Map<String, ProviderInfo> _providers = {
    'anthropic': ProviderInfo(
      name: 'Claude (Anthropic)',
      icon: Icons.psychology,
      apiUrl: 'https://console.anthropic.com/account/keys',
      description: 'Most capable for complex tasks',
      models: ['claude-3-5-sonnet-20241022', 'claude-3-opus-20240229'],
      baseUrl: 'https://api.anthropic.com',
    ),
    'openai': ProviderInfo(
      name: 'OpenAI',
      icon: Icons.auto_awesome,
      apiUrl: 'https://platform.openai.com/api-keys',
      description: 'GPT-4 and GPT-3.5 models',
      models: ['gpt-4-turbo-preview', 'gpt-3.5-turbo'],
      baseUrl: 'https://api.openai.com/v1',
    ),
    'google': ProviderInfo(
      name: 'Google Gemini',
      icon: Icons.star,
      apiUrl: 'https://makersuite.google.com/app/apikey',
      description: 'Gemini Pro models',
      models: ['gemini-pro', 'gemini-pro-vision'],
      baseUrl: 'https://generativelanguage.googleapis.com',
    ),
  };

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _saveAndContinue() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an API key';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      // Save API configuration
      final provider = _providers[_selectedProvider]!;
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
    // Mark as skipped but not completed
    final storage = DesktopStorageService.instance;
    await storage.setPreference('onboarding_skipped', true);
    
    if (mounted) {
      context.go(AppRoutes.home);
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
              padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
              child: Container(
                constraints: BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome Header
                    Icon(
                      Icons.rocket_launch,
                      size: 64,
                      color: colors.primary,
                    ),
                    SizedBox(height: SpacingTokens.xl),
                    Text(
                      'Welcome to Asmbli',
                      style: TextStyles.pageTitle.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    SizedBox(height: SpacingTokens.md),
                    Text(
                      'Let\'s get you started with your AI assistant',
                      style: TextStyles.bodyLarge.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: SpacingTokens.sectionSpacing),

                    // Main Card
                    AsmblCard(
                      child: Padding(
                        padding: EdgeInsets.all(SpacingTokens.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step indicator
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: SpacingTokens.sm,
                                    vertical: SpacingTokens.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.1),
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
                            
                            SizedBox(height: SpacingTokens.lg),
                            
                            Text(
                              'Connect Your AI Provider',
                              style: TextStyles.sectionTitle.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            SizedBox(height: SpacingTokens.md),
                            
                            // Privacy message
                            Container(
                              padding: EdgeInsets.all(SpacingTokens.md),
                              decoration: BoxDecoration(
                                color: colors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.success.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 20,
                                    color: colors.success,
                                  ),
                                  SizedBox(width: SpacingTokens.sm),
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
                            
                            SizedBox(height: SpacingTokens.lg),
                            
                            // Provider Selection
                            Text(
                              'Select Provider',
                              style: TextStyles.labelLarge.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            SizedBox(height: SpacingTokens.sm),
                            
                            Row(
                              children: _providers.entries.map((entry) {
                                final isSelected = _selectedProvider == entry.key;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: entry.key != _providers.keys.last 
                                        ? SpacingTokens.sm : 0,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedProvider = entry.key;
                                          _errorMessage = null;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.all(SpacingTokens.md),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                            ? colors.primary.withValues(alpha: 0.1)
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
                                            Icon(
                                              entry.value.icon,
                                              size: 24,
                                              color: isSelected 
                                                ? colors.primary 
                                                : colors.onSurfaceVariant,
                                            ),
                                            SizedBox(height: SpacingTokens.xs),
                                            Text(
                                              entry.value.name.split(' ').first,
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
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            SizedBox(height: SpacingTokens.lg),
                            
                            // API Key Input
                            Text(
                              'API Key',
                              style: TextStyles.labelLarge.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            SizedBox(height: SpacingTokens.sm),
                            
                            TextField(
                              controller: _apiKeyController,
                              obscureText: true,
                              style: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'sk-...',
                                hintStyle: TextStyles.bodyMedium.copyWith(
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
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
                                  icon: Icon(Icons.paste, size: 20),
                                  onPressed: () async {
                                    final data = await Clipboard.getData('text/plain');
                                    if (data?.text != null) {
                                      _apiKeyController.text = data!.text!;
                                    }
                                  },
                                ),
                              ),
                            ),
                            
                            SizedBox(height: SpacingTokens.sm),
                            
                            // Get API Key Link
                            TextButton.icon(
                              onPressed: () => _launchUrl(provider.apiUrl),
                              icon: Icon(Icons.open_in_new, size: 16),
                              label: Text('Get your ${provider.name} API key'),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.primary,
                              ),
                            ),
                            
                            SizedBox(height: SpacingTokens.xl),
                            
                            // Action Buttons
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _isValidating ? null : _skipForNow,
                                  child: Text('Skip for now'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colors.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(width: SpacingTokens.md),
                                Expanded(
                                  child: AsmblButton.primary(
                                    text: _isValidating ? 'Saving...' : 'Continue',
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

  const ProviderInfo({
    required this.name,
    required this.icon,
    required this.apiUrl,
    required this.description,
    required this.models,
    required this.baseUrl,
  });
}
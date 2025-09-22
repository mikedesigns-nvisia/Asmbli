import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/feature_flag_service.dart';
import '../../../../core/constants/routes.dart';
import '../screens/settings_screen.dart';
import '../../../tools/presentation/screens/tools_screen.dart';

/// Adaptive Integration Router
/// Routes users to either legacy integration tabs or new Integration Hub
/// based on feature flag configuration and user preferences
class AdaptiveIntegrationRouter extends ConsumerWidget {
  final String? initialTab;
  
  const AdaptiveIntegrationRouter({
    super.key,
    this.initialTab,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHubEnabled = ref.watch(integrationHubEnabledProvider);
    
    if (isHubEnabled) {
      // Default: New Integration Hub (unified experience)
      return const ToolsScreen();
    } else {
      // Fallback: Legacy settings screen (for users who explicitly opt out)
      return SettingsScreen(initialTab: initialTab ?? 'integrations');
    }
  }
}

/// Legacy Interface Deprecation Banner
/// Shows at top of legacy screens to inform users about the new default
class IntegrationHubMigrationBanner extends ConsumerWidget {
  final VoidCallback? onDismiss;
  
  const IntegrationHubMigrationBanner({
    super.key,
    this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHubEnabled = ref.watch(integrationHubEnabledProvider);
    
    // Show deprecation notice if using legacy interface
    if (isHubEnabled) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legacy Interface - Deprecated',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'re using the old integration interface. Switch to the new Integration Hub for a better experience.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => _enableIntegrationHub(ref, context),
            child: const Text('Switch to Hub'),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
  
  void _enableIntegrationHub(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(featureFlagProvider.notifier).toggleIntegrationHub();
      
      // Navigate to Integration Hub
      if (context.mounted) {
        context.go(AppRoutes.integrationHub);
        
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Integration Hub enabled! You can switch back in Settings > Advanced.'),
            action: SnackBarAction(
              label: 'Got it',
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

/// Feature Flag Toggle Widget
/// For settings screen to allow users to switch between experiences
class IntegrationExperienceToggle extends ConsumerWidget {
  const IntegrationExperienceToggle({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHubEnabled = ref.watch(integrationHubEnabledProvider);
    final isExpertDefault = ref.watch(expertModeDefaultProvider);
    final isAdvancedEnabled = ref.watch(advancedPanelEnabledProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Integration Experience',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        
        // Hub toggle
        SwitchListTile(
          title: const Text('Use Integration Hub'),
          subtitle: const Text('Modern unified interface (recommended - now default)'),
          value: isHubEnabled,
          onChanged: (_) => ref.read(featureFlagProvider.notifier).toggleIntegrationHub(),
        ),
        
        if (isHubEnabled) ...[
          // Expert mode default
          SwitchListTile(
            title: const Text('Expert Mode by Default'),
            subtitle: const Text('Show advanced controls and technical details'),
            value: isExpertDefault,
            onChanged: (_) => ref.read(featureFlagProvider.notifier).toggleExpertMode(),
          ),
          
          // Advanced panel
          SwitchListTile(
            title: const Text('Enable Advanced Tools'),
            subtitle: const Text('Health monitoring, analytics, and system controls'),
            value: isAdvancedEnabled,
            onChanged: (_) => ref.read(featureFlagProvider.notifier).toggleAdvancedPanel(),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Reset button
        OutlinedButton.icon(
          onPressed: () => _resetToDefaults(ref, context),
          icon: const Icon(Icons.refresh),
          label: const Text('Reset to Defaults'),
        ),
      ],
    );
  }
  
  void _resetToDefaults(WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Integration Experience?'),
        content: const Text('This will restore the default integration interface and clear your preferences.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(featureFlagProvider.notifier).resetFlags();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Integration experience reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
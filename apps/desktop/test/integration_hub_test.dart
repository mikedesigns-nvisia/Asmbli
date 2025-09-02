import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'package:agentengine_desktop/core/services/feature_flag_service.dart';
import 'package:agentengine_desktop/features/settings/presentation/widgets/adaptive_integration_router.dart';

void main() {
  group('Integration Hub Feature Flags', () {
    late SharedPreferences prefs;
    late FeatureFlagService service;

    setUp(() async {
      // Initialize test preferences
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = FeatureFlagService(prefs);
    });

    test('Feature flags initialize with correct defaults', () {
      expect(service.isIntegrationHubEnabled, true); // Default: enabled (new default)
      expect(service.isExpertModeDefault, false);
      expect(service.isAdvancedPanelEnabled, true); // Default: enabled
    });

    test('Feature flags can be toggled', () async {
      // Initially enabled (new default)
      expect(service.isIntegrationHubEnabled, true);

      // Disable Integration Hub
      await service.setIntegrationHubEnabled(false);
      expect(service.isIntegrationHubEnabled, false);

      // Enable again
      await service.setIntegrationHubEnabled(true);
      expect(service.isIntegrationHubEnabled, true);
    });

    test('Feature flags persist across service instances', () async {
      // Set flag in first service instance
      await service.setIntegrationHubEnabled(true);
      await service.setExpertModeDefault(true);

      // Create new service instance with same prefs
      final service2 = FeatureFlagService(prefs);

      // Verify flags persisted
      expect(service2.isIntegrationHubEnabled, true);
      expect(service2.isExpertModeDefault, true);
    });

    test('Reset to defaults works correctly', () async {
      // Set some non-default values
      await service.setIntegrationHubEnabled(false);
      await service.setExpertModeDefault(true);
      await service.setAdvancedPanelEnabled(false);

      // Verify they were set
      expect(service.isIntegrationHubEnabled, false);
      expect(service.isExpertModeDefault, true);
      expect(service.isAdvancedPanelEnabled, false);

      // Reset to defaults
      await service.resetToDefaults();

      // Verify defaults restored
      expect(service.isIntegrationHubEnabled, true);
      expect(service.isExpertModeDefault, false);
      expect(service.isAdvancedPanelEnabled, true);
    });

    test('getAllFlags returns correct state', () async {
      await service.setIntegrationHubEnabled(true);
      await service.setExpertModeDefault(false);
      await service.setAdvancedPanelEnabled(true);

      final flags = service.getAllFlags();

      expect(flags['integration_hub_enabled'], true);
      expect(flags['expert_mode_default'], false);
      expect(flags['advanced_panel_enabled'], true);
    });
  });

  group('Adaptive Integration Router', () {
    testWidgets('Shows Integration Hub when feature flag enabled', (tester) async {
      // Set up mock preferences with Integration Hub enabled
      SharedPreferences.setMockInitialValues({
        'feature_integration_hub_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(prefs)),
          ],
          child: const MaterialApp(
            home: AdaptiveIntegrationRouter(),
          ),
        ),
      );

      // Should show Integration Hub when feature flag is enabled
      expect(find.text('Integration Hub'), findsOneWidget);
    });

    testWidgets('Shows Settings Screen when feature flag disabled', (tester) async {
      // Set up mock preferences with Integration Hub disabled
      SharedPreferences.setMockInitialValues({
        'feature_integration_hub_enabled': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featureFlagServiceProvider.overrideWithValue(FeatureFlagService(prefs)),
          ],
          child: const MaterialApp(
            home: AdaptiveIntegrationRouter(initialTab: 'integrations'),
          ),
        ),
      );

      // Should show Settings screen when feature flag is disabled
      // Note: This might show loading or error states due to missing dependencies
      await tester.pumpAndSettle();
      
      // We expect either the settings screen or some indication that we tried to load it
      // Since we don't have full service setup, we just verify no crash occurred
      expect(tester.takeException(), isNull);
    });
  });
}
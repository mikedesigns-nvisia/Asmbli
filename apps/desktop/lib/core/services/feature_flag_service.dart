import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature Flag Service for managing experimental features
/// Allows gradual rollout and A/B testing of new UI components
class FeatureFlagService {
  static const String _keyIntegrationHub = 'feature_integration_hub_enabled';
  static const String _keyExpertMode = 'feature_expert_mode_default';
  static const String _keyAdvancedPanel = 'feature_advanced_panel_enabled';
  
  final SharedPreferences _prefs;
  
  FeatureFlagService(this._prefs);
  
  /// Check if Integration Hub is enabled (vs legacy tabs)
  bool get isIntegrationHubEnabled {
    return _prefs.getBool(_keyIntegrationHub) ?? true; // Default: enabled (new default experience)
  }
  
  /// Check if expert mode should be enabled by default
  bool get isExpertModeDefault {
    return _prefs.getBool(_keyExpertMode) ?? false;
  }
  
  /// Check if advanced management panel is enabled
  bool get isAdvancedPanelEnabled {
    return _prefs.getBool(_keyAdvancedPanel) ?? true; // Default: enabled
  }
  
  /// Toggle Integration Hub feature
  Future<void> setIntegrationHubEnabled(bool enabled) async {
    await _prefs.setBool(_keyIntegrationHub, enabled);
  }
  
  /// Set expert mode default preference
  Future<void> setExpertModeDefault(bool enabled) async {
    await _prefs.setBool(_keyExpertMode, enabled);
  }
  
  /// Toggle advanced panel feature
  Future<void> setAdvancedPanelEnabled(bool enabled) async {
    await _prefs.setBool(_keyAdvancedPanel, enabled);
  }
  
  /// Get all feature flags for debugging
  Map<String, bool> getAllFlags() {
    return {
      'integration_hub_enabled': isIntegrationHubEnabled,
      'expert_mode_default': isExpertModeDefault,
      'advanced_panel_enabled': isAdvancedPanelEnabled,
    };
  }
  
  /// Reset all feature flags to defaults
  Future<void> resetToDefaults() async {
    await _prefs.remove(_keyIntegrationHub);
    await _prefs.remove(_keyExpertMode);
    await _prefs.remove(_keyAdvancedPanel);
  }
}

/// Provider for Feature Flag Service
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  throw UnimplementedError('FeatureFlagService provider must be overridden');
});

/// Feature Flag Notifier for reactive updates
class FeatureFlagNotifier extends StateNotifier<Map<String, bool>> {
  final FeatureFlagService _service;
  
  FeatureFlagNotifier(this._service) : super({}) {
    _loadFlags();
  }
  
  void _loadFlags() {
    state = _service.getAllFlags();
  }
  
  Future<void> toggleIntegrationHub() async {
    await _service.setIntegrationHubEnabled(!_service.isIntegrationHubEnabled);
    _loadFlags();
  }
  
  Future<void> toggleExpertMode() async {
    await _service.setExpertModeDefault(!_service.isExpertModeDefault);
    _loadFlags();
  }
  
  Future<void> toggleAdvancedPanel() async {
    await _service.setAdvancedPanelEnabled(!_service.isAdvancedPanelEnabled);
    _loadFlags();
  }
  
  Future<void> resetFlags() async {
    await _service.resetToDefaults();
    _loadFlags();
  }
}

/// Provider for reactive feature flags
final featureFlagProvider = StateNotifierProvider<FeatureFlagNotifier, Map<String, bool>>((ref) {
  final service = ref.read(featureFlagServiceProvider);
  return FeatureFlagNotifier(service);
});

/// Convenience providers for specific flags
final integrationHubEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagProvider)['integration_hub_enabled'] ?? false;
});

final expertModeDefaultProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagProvider)['expert_mode_default'] ?? false;
});

final advancedPanelEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagProvider)['advanced_panel_enabled'] ?? true;
});
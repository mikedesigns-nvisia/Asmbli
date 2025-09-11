import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'oauth_token_refresh_service.dart';

/// Service that automatically initializes OAuth token refresh when app starts
class OAuthAutoRefreshInitializer {
  static bool _isInitialized = false;

  /// Initialize automatic token refresh
  static void initialize(WidgetRef ref) {
    if (_isInitialized) return;
    
    // Start the automatic refresh service
    ref.read(autoTokenRefreshProvider);
    
    _isInitialized = true;
  }

  /// Check if auto refresh has been initialized
  static bool get isInitialized => _isInitialized;
}
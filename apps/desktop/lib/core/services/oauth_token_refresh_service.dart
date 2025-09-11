import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../models/oauth_provider.dart';
import 'oauth_integration_service.dart';
import 'oauth_extensions.dart';
import 'secure_auth_service.dart';

/// Service that automatically refreshes OAuth tokens before they expire
class OAuthTokenRefreshService {
  final OAuthIntegrationService _oauthService;
  final SecureAuthService _authService;
  final Logger _logger = Logger('OAuthTokenRefreshService');
  
  Timer? _refreshTimer;
  final Map<OAuthProvider, Timer?> _providerTimers = {};
  bool _isRunning = false;
  
  /// How long before expiration to refresh tokens (default: 15 minutes)
  static const Duration refreshBuffer = Duration(minutes: 15);
  
  /// How often to check for tokens needing refresh (default: 5 minutes)
  static const Duration checkInterval = Duration(minutes: 5);

  OAuthTokenRefreshService(this._oauthService, this._authService);

  /// Start the automatic token refresh service
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _logger.info('Starting OAuth token refresh service');
    
    // Run initial check immediately
    _checkAndRefreshTokens();
    
    // Schedule periodic checks
    _refreshTimer = Timer.periodic(checkInterval, (_) {
      _checkAndRefreshTokens();
    });
  }

  /// Stop the automatic token refresh service
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _logger.info('Stopping OAuth token refresh service');
    
    _refreshTimer?.cancel();
    _refreshTimer = null;
    
    // Cancel all provider-specific timers
    for (final timer in _providerTimers.values) {
      timer?.cancel();
    }
    _providerTimers.clear();
  }

  /// Check all connected providers and refresh tokens if needed
  Future<void> _checkAndRefreshTokens() async {
    if (!_isRunning) return;
    
    _logger.fine('Checking tokens for refresh');
    
    for (final provider in OAuthProvider.values) {
      await _checkProviderToken(provider);
    }
  }

  /// Check and refresh a specific provider's token if needed
  Future<void> _checkProviderToken(OAuthProvider provider) async {
    try {
      final tokenInfo = await _oauthService.getTokenInfo(provider);
      if (tokenInfo == null) return; // No token stored
      
      final now = DateTime.now();
      final expiresAt = tokenInfo.expiresAt;
      
      if (expiresAt == null) {
        _logger.fine('Token for ${provider.name} has no expiration');
        return;
      }
      
      final timeUntilExpiry = expiresAt.difference(now);
      
      if (timeUntilExpiry <= refreshBuffer) {
        _logger.info('Token for ${provider.name} expires in ${timeUntilExpiry.inMinutes} minutes, refreshing now');
        await _refreshProviderToken(provider);
      } else {
        // Schedule refresh for this specific provider
        _scheduleProviderRefresh(provider, timeUntilExpiry - refreshBuffer);
      }
    } catch (e) {
      _logger.warning('Error checking token for ${provider.name}: $e');
    }
  }

  /// Refresh a specific provider's token
  Future<void> _refreshProviderToken(OAuthProvider provider) async {
    try {
      _logger.info('Refreshing token for ${provider.name}');
      
      final result = await _oauthService.refreshToken(provider);
      
      if (result.isSuccess) {
        _logger.info('Successfully refreshed token for ${provider.name}');
        
        // Schedule next refresh based on new expiration
        final tokenInfo = await _oauthService.getTokenInfo(provider);
        if (tokenInfo?.expiresAt != null) {
          final timeUntilExpiry = tokenInfo!.expiresAt!.difference(DateTime.now());
          if (timeUntilExpiry > refreshBuffer) {
            _scheduleProviderRefresh(provider, timeUntilExpiry - refreshBuffer);
          }
        }
      } else {
        _logger.severe('Failed to refresh token for ${provider.name}: ${result.error}');
        // Could emit an event here for UI notification
        _handleRefreshFailure(provider, result.error ?? 'Unknown error');
      }
    } catch (e) {
      _logger.severe('Error refreshing token for ${provider.name}: $e');
      _handleRefreshFailure(provider, e.toString());
    }
  }

  /// Schedule a refresh for a specific provider
  void _scheduleProviderRefresh(OAuthProvider provider, Duration delay) {
    // Cancel existing timer for this provider
    _providerTimers[provider]?.cancel();
    
    if (delay.isNegative || delay.inSeconds < 1) {
      // Refresh immediately if delay is too short
      _refreshProviderToken(provider);
      return;
    }
    
    _logger.fine('Scheduling refresh for ${provider.name} in ${delay.inMinutes} minutes');
    
    _providerTimers[provider] = Timer(delay, () {
      _refreshProviderToken(provider);
    });
  }

  /// Handle refresh failure (could trigger notifications, etc.)
  void _handleRefreshFailure(OAuthProvider provider, String error) {
    _logger.severe('Token refresh failed for ${provider.name}: $error');
    
    // Could implement:
    // - User notifications
    // - Retry with exponential backoff
    // - Mark provider as requiring re-authentication
    // - Emit events for UI updates
  }

  /// Manually trigger refresh for a specific provider
  Future<bool> refreshProviderNow(OAuthProvider provider) async {
    try {
      final result = await _oauthService.refreshToken(provider);
      if (result.isSuccess) {
        _logger.info('Manual refresh successful for ${provider.name}');
        
        // Update scheduled refresh
        final tokenInfo = await _oauthService.getTokenInfo(provider);
        if (tokenInfo?.expiresAt != null) {
          final timeUntilExpiry = tokenInfo!.expiresAt!.difference(DateTime.now());
          if (timeUntilExpiry > refreshBuffer) {
            _scheduleProviderRefresh(provider, timeUntilExpiry - refreshBuffer);
          }
        }
        return true;
      } else {
        _logger.warning('Manual refresh failed for ${provider.name}: ${result.error}');
        return false;
      }
    } catch (e) {
      _logger.severe('Manual refresh error for ${provider.name}: $e');
      return false;
    }
  }

  /// Check if a provider's token needs immediate refresh
  Future<bool> needsRefresh(OAuthProvider provider) async {
    try {
      final tokenInfo = await _oauthService.getTokenInfo(provider);
      if (tokenInfo?.expiresAt == null) return false;
      
      final timeUntilExpiry = tokenInfo!.expiresAt!.difference(DateTime.now());
      return timeUntilExpiry <= refreshBuffer;
    } catch (e) {
      return false;
    }
  }

  /// Get time until next refresh for a provider
  Future<Duration?> timeUntilRefresh(OAuthProvider provider) async {
    try {
      final tokenInfo = await _oauthService.getTokenInfo(provider);
      if (tokenInfo?.expiresAt == null) return null;
      
      final timeUntilExpiry = tokenInfo!.expiresAt!.difference(DateTime.now());
      final refreshTime = timeUntilExpiry - refreshBuffer;
      
      return refreshTime.isNegative ? Duration.zero : refreshTime;
    } catch (e) {
      return null;
    }
  }

  /// Get status of all provider tokens
  Future<Map<OAuthProvider, TokenRefreshStatus>> getRefreshStatus() async {
    final status = <OAuthProvider, TokenRefreshStatus>{};
    
    for (final provider in OAuthProvider.values) {
      try {
        final tokenInfo = await _oauthService.getTokenInfo(provider);
        if (tokenInfo == null) {
          status[provider] = TokenRefreshStatus.notConnected;
          continue;
        }
        
        if (tokenInfo.expiresAt == null) {
          status[provider] = TokenRefreshStatus.noExpiration;
          continue;
        }
        
        final timeUntilExpiry = tokenInfo.expiresAt!.difference(DateTime.now());
        
        if (timeUntilExpiry.isNegative) {
          status[provider] = TokenRefreshStatus.expired;
        } else if (timeUntilExpiry <= refreshBuffer) {
          status[provider] = TokenRefreshStatus.needsRefresh;
        } else {
          status[provider] = TokenRefreshStatus.healthy;
        }
      } catch (e) {
        status[provider] = TokenRefreshStatus.error;
      }
    }
    
    return status;
  }

  /// Clean up resources
  void dispose() {
    stop();
  }
}

/// Status of token refresh for a provider
enum TokenRefreshStatus {
  /// Provider is not connected/authenticated
  notConnected,
  
  /// Token has no expiration (permanent token)
  noExpiration,
  
  /// Token is healthy and doesn't need refresh yet
  healthy,
  
  /// Token needs refresh soon
  needsRefresh,
  
  /// Token has already expired
  expired,
  
  /// Error checking token status
  error,
}

/// Extension methods for TokenRefreshStatus
extension TokenRefreshStatusExtensions on TokenRefreshStatus {
  bool get isHealthy => this == TokenRefreshStatus.healthy || this == TokenRefreshStatus.noExpiration;
  bool get needsAttention => this == TokenRefreshStatus.needsRefresh || this == TokenRefreshStatus.expired;
  bool get hasError => this == TokenRefreshStatus.error;
}

// ==================== Riverpod Providers ====================

final oauthTokenRefreshServiceProvider = Provider<OAuthTokenRefreshService>((ref) {
  final oauthService = ref.read(oauthIntegrationServiceProvider);
  final authService = ref.read(secureAuthServiceProvider);
  return OAuthTokenRefreshService(oauthService, authService);
});

/// Provider that automatically starts the refresh service
final autoTokenRefreshProvider = Provider<OAuthTokenRefreshService>((ref) {
  final service = ref.read(oauthTokenRefreshServiceProvider);
  
  // Start the service when first accessed
  service.start();
  
  // Clean up when provider is disposed
  ref.onDispose(() {
    service.stop();
  });
  
  return service;
});
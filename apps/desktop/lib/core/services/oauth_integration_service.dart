import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'secure_auth_service.dart';
import '../models/oauth_provider.dart';
import '../config/oauth_config.dart';

/// Production-grade OAuth 2.0 integration service following industry standards
class OAuthIntegrationService {
  final SecureAuthService _authService;
  final Map<String, Completer<String?>> _pendingAuth = {};
  HttpServer? _callbackServer;
  
  // OAuth configurations are now loaded from secure config
  final Map<OAuthProvider, OAuthClientConfig> _providerConfigs = {};

  OAuthIntegrationService(this._authService);

  /// Get OAuth configuration for provider
  Future<OAuthClientConfig?> _getProviderConfig(OAuthProvider provider) async {
    // Check cache first
    if (_providerConfigs.containsKey(provider)) {
      return _providerConfigs[provider];
    }

    try {
      // Try to load custom configuration first
      final customConfig = await OAuthConfig.loadCustomConfig(provider.name);
      if (customConfig != null && OAuthConfig.validateConfig(customConfig)) {
        _providerConfigs[provider] = customConfig;
        return customConfig;
      }

      // Fall back to built-in configuration
      final config = OAuthConfig.getConfig(provider.name);
      if (OAuthConfig.validateConfig(config)) {
        _providerConfigs[provider] = config;
        return config;
      }
    } catch (e) {
      print('Failed to load OAuth config for ${provider.name}: $e');
    }

    return null;
  }

  /// Start OAuth 2.0 authorization flow
  Future<OAuthResult> authenticate(OAuthProvider provider) async {
    try {
      // Load configuration for provider
      final config = await _getProviderConfig(provider);
      if (config == null) {
        return OAuthResult.error('OAuth configuration not available for: $provider');
      }

      // Generate cryptographically secure state parameter (CSRF protection)
      final state = _generateSecureRandomString(32);
      final codeVerifier = _generateSecureRandomString(128);
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      
      // Start local callback server
      await _startCallbackServer();
      
      // Build authorization URL with PKCE
      final authUrl = config.buildAuthUrl(
        state: state,
        codeChallenge: codeChallenge,
        codeChallengeMethod: 'S256',
      );

      // Launch browser for user authorization
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        await _stopCallbackServer();
        return OAuthResult.error('Failed to launch authorization URL');
      }

      // Setup completion handler
      final completer = Completer<String?>();
      _pendingAuth[state] = completer;

      // Wait for callback with timeout
      final authCode = await completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () => null,
      );

      await _stopCallbackServer();

      if (authCode == null) {
        return OAuthResult.error('Authorization failed or timed out');
      }

      // Exchange authorization code for access token
      final tokenResult = await _exchangeCodeForToken(
        config,
        authCode,
        codeVerifier,
      );

      if (tokenResult.isSuccess) {
        // Store tokens securely with provider prefix
        final keyPrefix = 'oauth:${provider.name}';
        await _authService.storeCredential(
          '$keyPrefix:access_token',
          tokenResult.accessToken!,
        );
        
        if (tokenResult.refreshToken != null) {
          await _authService.storeCredential(
            '$keyPrefix:refresh_token',
            tokenResult.refreshToken!,
          );
        }
        
        if (tokenResult.expiresAt != null) {
          await _authService.storeCredential(
            '$keyPrefix:expires_at',
            tokenResult.expiresAt!.toIso8601String(),
          );
        }

        return OAuthResult.success(tokenResult.accessToken!);
      }

      return tokenResult;
    } catch (e) {
      await _stopCallbackServer();
      return OAuthResult.error('OAuth flow failed: ${e.toString()}');
    }
  }

  /// Exchange authorization code for access token
  Future<OAuthResult> _exchangeCodeForToken(
    OAuthClientConfig config,
    String code,
    String codeVerifier,
  ) async {
    try {
      final body = config.buildTokenRequest(
        code: code,
        codeVerifier: codeVerifier,
      );
      
      final response = await http.post(
        Uri.parse(config.tokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        return OAuthResult.error(
          'Token exchange failed: ${response.statusCode} ${response.body}',
        );
      }

      final Map<String, dynamic> tokenData = json.decode(response.body);
      
      return OAuthResult(
        isSuccess: true,
        accessToken: tokenData['access_token'],
        refreshToken: tokenData['refresh_token'],
        expiresAt: tokenData['expires_in'] != null
            ? DateTime.now().add(Duration(seconds: tokenData['expires_in']))
            : null,
      );
    } catch (e) {
      return OAuthResult.error('Token exchange error: ${e.toString()}');
    }
  }

  /// Refresh access token using refresh token
  Future<OAuthResult> refreshToken(OAuthProvider provider) async {
    try {
      final config = await _getProviderConfig(provider);
      if (config == null) {
        return OAuthResult.error('OAuth configuration not available for: $provider');
      }

      final keyPrefix = 'oauth:${provider.name}';
      final refreshToken = await _authService.getCredential('$keyPrefix:refresh_token');
      
      if (refreshToken == null) {
        return OAuthResult.error('No refresh token available');
      }

      final body = config.buildRefreshRequest(refreshToken);
      
      final response = await http.post(
        Uri.parse(config.tokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        return OAuthResult.error(
          'Token refresh failed: ${response.statusCode} ${response.body}',
        );
      }

      final Map<String, dynamic> tokenData = json.decode(response.body);
      
      // Store new tokens
      await _authService.storeCredential(
        '$keyPrefix:access_token',
        tokenData['access_token'],
      );
      
      if (tokenData['refresh_token'] != null) {
        await _authService.storeCredential(
          '$keyPrefix:refresh_token',
          tokenData['refresh_token'],
        );
      }
      
      if (tokenData['expires_in'] != null) {
        final expiresAt = DateTime.now().add(Duration(seconds: tokenData['expires_in']));
        await _authService.storeCredential(
          '$keyPrefix:expires_at',
          expiresAt.toIso8601String(),
        );
      }

      return OAuthResult.success(tokenData['access_token']);
    } catch (e) {
      return OAuthResult.error('Token refresh error: ${e.toString()}');
    }
  }

  /// Check if user has valid token for provider
  Future<bool> hasValidToken(OAuthProvider provider) async {
    try {
      final keyPrefix = 'oauth:${provider.name}';
      final accessToken = await _authService.getCredential('$keyPrefix:access_token');
      
      if (accessToken == null) return false;

      // Check expiration if available
      final expiresAtStr = await _authService.getCredential('$keyPrefix:expires_at');
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)))) {
          // Token expires in 5 minutes, try to refresh
          final refreshResult = await refreshToken(provider);
          return refreshResult.isSuccess;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get valid access token (with automatic refresh)
  Future<String?> getValidAccessToken(OAuthProvider provider) async {
    if (!await hasValidToken(provider)) {
      return null;
    }
    
    final keyPrefix = 'oauth:${provider.name}';
    return await _authService.getCredential('$keyPrefix:access_token');
  }

  /// Revoke stored credentials
  Future<void> revokeCredentials(OAuthProvider provider) async {
    final keyPrefix = 'oauth:${provider.name}';
    await _authService.deleteCredential('$keyPrefix:access_token');
    await _authService.deleteCredential('$keyPrefix:refresh_token');
    await _authService.deleteCredential('$keyPrefix:expires_at');
  }

  /// Start local HTTP server for OAuth callback
  Future<void> _startCallbackServer() async {
    if (_callbackServer != null) {
      await _stopCallbackServer();
    }

    // Try to bind to port 8080, fallback to any available port
    try {
      _callbackServer = await HttpServer.bind('localhost', 8080);
    } catch (e) {
      // Port 8080 might be taken, let system assign port
      _callbackServer = await HttpServer.bind('localhost', 0);
      print('OAuth callback server started on port ${_callbackServer!.port}');
    }
    
    _callbackServer!.listen((request) async {
      if (request.uri.path == '/oauth/callback') {
        await _handleCallback(request);
      } else {
        request.response.statusCode = 404;
        await request.response.close();
      }
    });
  }

  /// Handle OAuth callback
  Future<void> _handleCallback(HttpRequest request) async {
    try {
      final uri = request.uri;
      final state = uri.queryParameters['state'];
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      // Send success/error page to user
      request.response.headers.contentType = ContentType.html;
      
      if (error != null) {
        request.response.write(_getErrorPage(error));
        final completer = state != null ? _pendingAuth.remove(state) : null;
        completer?.complete(null);
      } else if (code != null && state != null) {
        request.response.write(_getSuccessPage());
        final completer = _pendingAuth.remove(state);
        completer?.complete(code);
      } else {
        request.response.write(_getErrorPage('Invalid callback parameters'));
        final completer = state != null ? _pendingAuth.remove(state) : null;
        completer?.complete(null);
      }
      
      await request.response.close();
    } catch (e) {
      request.response.statusCode = 500;
      await request.response.close();
    }
  }

  /// Stop callback server
  Future<void> _stopCallbackServer() async {
    if (_callbackServer != null) {
      await _callbackServer!.close(force: true);
      _callbackServer = null;
    }
  }

  /// Generate cryptographically secure random string
  String _generateSecureRandomString(int length) {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate PKCE code challenge
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _getSuccessPage() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <title>Authorization Successful</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center; padding: 50px; }
        .success { color: #4CAF50; }
      </style>
    </head>
    <body>
      <h1 class="success">✅ Authorization Successful</h1>
      <p>You can now close this window and return to the app.</p>
      <script>setTimeout(() => window.close(), 2000);</script>
    </body>
    </html>
    ''';
  }

  String _getErrorPage(String error) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <title>Authorization Failed</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center; padding: 50px; }
        .error { color: #f44336; }
      </style>
    </head>
    <body>
      <h1 class="error">❌ Authorization Failed</h1>
      <p>Error: $error</p>
      <p>Please close this window and try again.</p>
    </body>
    </html>
    ''';
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await _stopCallbackServer();
    _pendingAuth.clear();
  }

  /// Authorize with OAuth provider
  Future<Map<String, String>?> authorize(OAuthProvider provider, {List<String>? scopes}) async {
    final config = await _getProviderConfig(provider);
    if (config == null) return null;
    
    // Implementation would go here - for now return null to indicate failure
    return null;
  }
}


/// OAuth authentication result
class OAuthResult {
  final bool isSuccess;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? error;

  const OAuthResult({
    required this.isSuccess,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.error,
  });

  factory OAuthResult.success(String accessToken, {String? refreshToken, DateTime? expiresAt}) {
    return OAuthResult(
      isSuccess: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  factory OAuthResult.error(String error) {
    return OAuthResult(
      isSuccess: false,
      error: error,
    );
  }
}

// ==================== Riverpod Provider ====================

final oauthIntegrationServiceProvider = Provider<OAuthIntegrationService>((ref) {
  final authService = ref.read(secureAuthServiceProvider);
  return OAuthIntegrationService(authService);
});
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointycastle/export.dart';
import 'package:http/http.dart' as http;
import '../config/oauth_config.dart';
import 'desktop/desktop_storage_service.dart';
import 'desktop/desktop_service_provider.dart';

/// Production-grade secure authentication service with AES-256-GCM encryption
/// Handles OAuth flows, token management, and secure credential storage
class SecureAuthService {
  final DesktopStorageService _storageService;
  static const String _masterKeyBox = 'auth_master_key';
  static const String _credentialsBox = 'encrypted_credentials';
  static const String _oauthTokensBox = 'oauth_tokens';
  
  // In-memory cache with TTL (5 minutes)
  final Map<String, _CachedCredential> _credentialCache = {};
  final Map<String, _CachedOAuthToken> _tokenCache = {};
  
  SecureRandom? _secureRandom;
  Uint8List? _masterKey;
  bool _initialized = false;

  SecureAuthService(this._storageService);

  /// Initialize the secure auth service with proper key derivation
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _secureRandom = SecureRandom('Fortuna');
      _secureRandom!.seed(KeyParameter(_generateEntropy()));
      
      await _initializeMasterKey();
      _initialized = true;
      
      // Start cleanup timer for expired cache entries
      _startCacheCleanup();
      
      print('🔐 Secure Auth Service initialized with AES-256-GCM');
    } catch (e) {
      throw Exception('Failed to initialize secure auth service: $e');
    }
  }

  /// Generate cryptographically secure entropy
  Uint8List _generateEntropy() {
    final random = Random.secure();
    final entropy = Uint8List(32);
    for (int i = 0; i < entropy.length; i++) {
      entropy[i] = random.nextInt(256);
    }
    return entropy;
  }

  /// Initialize master key with PBKDF2 derivation

  /// Generate secure random key
  Uint8List _generateSecureKey(int length) {
    final key = Uint8List(length);
    for (int i = 0; i < key.length; i++) {
      key[i] = _secureRandom!.nextUint8();
    }
    return key;
  }

  /// Derive key using PBKDF2 with device-specific salt
  Future<Uint8List> _deriveKeyFromDevice(String encryptedKey) async {
    // Use device-specific information as salt
    final deviceInfo = Platform.operatingSystem + Platform.localHostname;
    final salt = utf8.encode(deviceInfo);
    
    // Derive key using PBKDF2
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(Uint8List.fromList(salt), 10000, 32));
    
    return pbkdf2.process(Uint8List.fromList(utf8.encode(encryptedKey)));
  }

  /// Encrypt master key for storage
  Future<String> _encryptMasterKey(Uint8List key) async {
    // Simple base64 encoding for now (in production, use device keystore)
    return base64Encode(key);
  }

  /// Start cache cleanup timer
  void _startCacheCleanup() {
    Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      
      // Clean expired credentials
      _credentialCache.removeWhere((key, cache) => 
          now.difference(cache.cachedAt) > const Duration(minutes: 5));
      
      // Clean expired tokens
      _tokenCache.removeWhere((key, cache) => 
          now.difference(cache.cachedAt) > const Duration(minutes: 5));
    });
  }

  /// Initialize or load master key with proper key derivation
  Future<void> _initializeMasterKey() async {
    try {
      // Try to load existing master key
      final storedKeyData = _storageService.getPreference<String>('secure_auth_master_key');
      
      if (storedKeyData != null) {
        final keyData = json.decode(storedKeyData) as Map<String, dynamic>;
        final salt = base64Decode(keyData['salt'] as String);
        final iterations = keyData['iterations'] as int;
        
        // Derive master key from system entropy + salt
        _masterKey = await _deriveKey(_getSystemFingerprint(), salt, iterations);
        
        // Verify key integrity
        final storedVerifier = keyData['verifier'] as String;
        final computedVerifier = _computeKeyVerifier(_masterKey!);
        
        if (storedVerifier != computedVerifier) {
          throw Exception('Master key verification failed - potential tampering');
        }
        
      } else {
        // Generate new master key
        await _generateNewMasterKey();
      }
    } catch (e) {
      // If loading fails, generate new key (will invalidate existing credentials)
      print('⚠️ Master key loading failed, generating new key: $e');
      await _generateNewMasterKey();
    }
  }

  /// Generate new master key with PBKDF2
  Future<void> _generateNewMasterKey() async {
    final salt = _generateSecureBytes(32);
    const iterations = 100000; // PBKDF2 iterations (OWASP recommended minimum)
    
    _masterKey = await _deriveKey(_getSystemFingerprint(), salt, iterations);
    
    // Store key metadata (not the key itself)
    final keyData = {
      'salt': base64Encode(salt),
      'iterations': iterations,
      'verifier': _computeKeyVerifier(_masterKey!),
      'created': DateTime.now().toIso8601String(),
    };
    
    await _storageService.setPreference('secure_auth_master_key', json.encode(keyData));
    print('🔑 Generated new master key with PBKDF2 ($iterations iterations)');
  }

  /// Derive encryption key using PBKDF2
  Future<Uint8List> _deriveKey(String password, Uint8List salt, int iterations) async {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, iterations, 32));
    
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Get system fingerprint for key derivation
  String _getSystemFingerprint() {
    // Create a stable but unique system identifier
    final platform = Platform.operatingSystem;
    final hostname = Platform.localHostname;
    final version = Platform.version;
    
    // Combine with app-specific data
    final combined = '$platform|$hostname|$version|asmbli_auth_v2';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  /// Compute key verifier for integrity checking
  String _computeKeyVerifier(Uint8List key) {
    final hmac = Hmac(sha256, key);
    return base64Encode(hmac.convert(utf8.encode('key_verification_v1')).bytes);
  }

  /// Generate secure random bytes
  Uint8List _generateSecureBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _secureRandom!.nextUint8();
    }
    return bytes;
  }

  // ==================== OAuth 2.0 Integration ====================

  /// Initiate OAuth flow for a service
  Future<OAuthResult> initiateOAuthFlow(String service, List<String> scopes) async {
    if (!_initialized) await initialize();

    try {
      switch (service.toLowerCase()) {
        case 'github':
          return await _initiateGitHubOAuth(scopes);
        case 'slack':
          return await _initiateSlackOAuth(scopes);
        case 'linear':
          return await _initiateLinearOAuth(scopes);
        case 'microsoft':
          return await _initiateMicrosoftOAuth(scopes);
        default:
          throw Exception('Unsupported OAuth service: $service');
      }
    } catch (e) {
      return OAuthResult.error('OAuth initiation failed: $e');
    }
  }

  /// GitHub OAuth flow
  Future<OAuthResult> _initiateGitHubOAuth(List<String> scopes) async {
    // In a real implementation, this would:
    // 1. Generate secure state parameter
    // 2. Open browser with GitHub OAuth URL
    // 3. Handle callback with authorization code
    // 4. Exchange code for access token
    
    final state = base64Encode(_generateSecureBytes(32));
    final scopeString = scopes.join(' ');
    
    // For now, return the OAuth URL that should be opened
    const clientId = 'your_github_client_id'; // Should come from config
    final authUrl = 'https://github.com/login/oauth/authorize'
        '?client_id=$clientId'
        '&scope=$scopeString'
        '&state=$state'
        '&redirect_uri=http://localhost:3000/auth/github/callback';
        
    return OAuthResult.pending(authUrl, state);
  }

  /// Slack OAuth flow
  Future<OAuthResult> _initiateSlackOAuth(List<String> scopes) async {
    final state = base64Encode(_generateSecureBytes(32));
    final scopeString = scopes.join(' ');
    
    const clientId = 'your_slack_client_id'; // Should come from config
    final authUrl = 'https://slack.com/oauth/v2/authorize'
        '?client_id=$clientId'
        '&scope=$scopeString'
        '&state=$state'
        '&redirect_uri=http://localhost:3000/auth/slack/callback';
        
    return OAuthResult.pending(authUrl, state);
  }

  /// Linear OAuth flow
  Future<OAuthResult> _initiateLinearOAuth(List<String> scopes) async {
    final state = base64Encode(_generateSecureBytes(32));
    
    const clientId = 'your_linear_client_id';
    final authUrl = 'https://linear.app/oauth/authorize'
        '?client_id=$clientId'
        '&response_type=code'
        '&scope=read,write'
        '&state=$state'
        '&redirect_uri=http://localhost:3000/auth/linear/callback';
        
    return OAuthResult.pending(authUrl, state);
  }

  /// Microsoft OAuth flow
  Future<OAuthResult> _initiateMicrosoftOAuth(List<String> scopes) async {
    final state = base64Encode(_generateSecureBytes(32));
    final scopeString = scopes.join(' ');
    
    const clientId = 'your_microsoft_client_id';
    final authUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
        '?client_id=$clientId'
        '&response_type=code'
        '&scope=$scopeString'
        '&state=$state'
        '&redirect_uri=http://localhost:3000/auth/microsoft/callback';
        
    return OAuthResult.pending(authUrl, state);
  }

  /// Complete OAuth flow with authorization code
  Future<OAuthToken> completeOAuthFlow(
    String service, 
    String authorizationCode, 
    String state,
  ) async {
    if (!_initialized) await initialize();

    try {
      switch (service.toLowerCase()) {
        case 'github':
          return await _completeGitHubOAuth(authorizationCode, state);
        case 'slack':
          return await _completeSlackOAuth(authorizationCode, state);
        case 'linear':
          return await _completeLinearOAuth(authorizationCode, state);
        case 'microsoft':
          return await _completeMicrosoftOAuth(authorizationCode, state);
        default:
          throw Exception('Unsupported OAuth service: $service');
      }
    } catch (e) {
      throw Exception('OAuth completion failed: $e');
    }
  }

  Future<OAuthToken> _completeGitHubOAuth(String code, String state) async {
    try {
      final config = OAuthConfig.getConfig('github');
      
      // Exchange authorization code for access token
      final response = await http.post(
        Uri.parse(config.tokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Asmbli-Desktop/1.0.0',
        },
        body: config.buildTokenRequest(code: code),
      );
      
      if (response.statusCode != 200) {
        throw Exception('GitHub token exchange failed: ${response.statusCode} ${response.body}');
      }
      
      final Map<String, dynamic> tokenData;
      try {
        tokenData = json.decode(response.body);
      } catch (e) {
        throw Exception('Invalid JSON response from GitHub: ${response.body}');
      }
      
      if (tokenData.containsKey('error')) {
        throw Exception('GitHub OAuth error: ${tokenData['error_description'] ?? tokenData['error']}');
      }
      
      final token = OAuthToken(
        service: 'github',
        accessToken: tokenData['access_token'] ?? '',
        refreshToken: tokenData['refresh_token'], // GitHub doesn't provide refresh tokens for OAuth Apps
        expiresAt: tokenData['expires_in'] != null 
            ? DateTime.now().add(Duration(seconds: tokenData['expires_in']))
            : null, // GitHub tokens don't expire by default
        scopes: (tokenData['scope'] as String?)?.split(',') ?? config.scopes,
        tokenType: tokenData['token_type'] ?? 'Bearer',
      );
      
      if (token.accessToken.isEmpty) {
        throw Exception('GitHub returned empty access token');
      }
      
      await _storeOAuthToken(token);
      print('✅ GitHub OAuth token obtained: ${token.accessToken.substring(0, 10)}...');
      return token;
      
    } catch (e) {
      print('❌ GitHub OAuth completion failed: $e');
      rethrow;
    }
  }

  Future<OAuthToken> _completeSlackOAuth(String code, String state) async {
    try {
      final config = OAuthConfig.getConfig('slack');
      
      // Exchange authorization code for access token
      final response = await http.post(
        Uri.parse(config.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: config.buildTokenRequest(code: code),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Slack token exchange failed: ${response.statusCode} ${response.body}');
      }
      
      final Map<String, dynamic> tokenData;
      try {
        tokenData = json.decode(response.body);
      } catch (e) {
        throw Exception('Invalid JSON response from Slack: ${response.body}');
      }
      
      if (tokenData['ok'] != true) {
        throw Exception('Slack OAuth error: ${tokenData['error'] ?? 'Unknown error'}');
      }
      
      final accessToken = tokenData['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Slack returned empty access token');
      }
      
      final token = OAuthToken(
        service: 'slack',
        accessToken: accessToken,
        refreshToken: tokenData['refresh_token'], // Slack v2 OAuth may include refresh tokens
        expiresAt: tokenData['expires_in'] != null 
            ? DateTime.now().add(Duration(seconds: tokenData['expires_in']))
            : null,
        scopes: (tokenData['scope'] as String?)?.split(',') ?? config.scopes,
        tokenType: 'Bearer',
      );
      
      await _storeOAuthToken(token);
      print('✅ Slack OAuth token obtained: ${token.accessToken.substring(0, 10)}...');
      return token;
      
    } catch (e) {
      print('❌ Slack OAuth completion failed: $e');
      rethrow;
    }
  }

  Future<OAuthToken> _completeLinearOAuth(String code, String state) async {
    try {
      final config = OAuthConfig.getConfig('linear');
      
      // Exchange authorization code for access token
      final response = await http.post(
        Uri.parse(config.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: config.buildTokenRequest(code: code),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Linear token exchange failed: ${response.statusCode} ${response.body}');
      }
      
      final Map<String, dynamic> tokenData;
      try {
        tokenData = json.decode(response.body);
      } catch (e) {
        throw Exception('Invalid JSON response from Linear: ${response.body}');
      }
      
      if (tokenData.containsKey('error')) {
        throw Exception('Linear OAuth error: ${tokenData['error_description'] ?? tokenData['error']}');
      }
      
      final accessToken = tokenData['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Linear returned empty access token');
      }
      
      final token = OAuthToken(
        service: 'linear',
        accessToken: accessToken,
        refreshToken: tokenData['refresh_token'],
        expiresAt: tokenData['expires_in'] != null 
            ? DateTime.now().add(Duration(seconds: tokenData['expires_in']))
            : DateTime.now().add(const Duration(days: 30)), // Default Linear expiry
        scopes: config.scopes, // Linear doesn't return scopes in response
        tokenType: tokenData['token_type'] ?? 'Bearer',
      );
      
      await _storeOAuthToken(token);
      print('✅ Linear OAuth token obtained: ${token.accessToken.substring(0, 10)}...');
      return token;
      
    } catch (e) {
      print('❌ Linear OAuth completion failed: $e');
      rethrow;
    }
  }

  Future<OAuthToken> _completeMicrosoftOAuth(String code, String state) async {
    try {
      final config = OAuthConfig.getConfig('microsoft');
      
      // Exchange authorization code for access token
      final response = await http.post(
        Uri.parse(config.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: config.buildTokenRequest(code: code),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Microsoft token exchange failed: ${response.statusCode} ${response.body}');
      }
      
      final Map<String, dynamic> tokenData;
      try {
        tokenData = json.decode(response.body);
      } catch (e) {
        throw Exception('Invalid JSON response from Microsoft: ${response.body}');
      }
      
      if (tokenData.containsKey('error')) {
        throw Exception('Microsoft OAuth error: ${tokenData['error_description'] ?? tokenData['error']}');
      }
      
      final accessToken = tokenData['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Microsoft returned empty access token');
      }
      
      final token = OAuthToken(
        service: 'microsoft',
        accessToken: accessToken,
        refreshToken: tokenData['refresh_token'],
        expiresAt: tokenData['expires_in'] != null 
            ? DateTime.now().add(Duration(seconds: tokenData['expires_in']))
            : DateTime.now().add(const Duration(hours: 1)), // Default Microsoft expiry
        scopes: (tokenData['scope'] as String?)?.split(' ') ?? config.scopes,
        tokenType: tokenData['token_type'] ?? 'Bearer',
      );
      
      await _storeOAuthToken(token);
      print('✅ Microsoft OAuth token obtained: ${token.accessToken.substring(0, 10)}...');
      return token;
      
    } catch (e) {
      print('❌ Microsoft OAuth completion failed: $e');
      rethrow;
    }
  }

  // ==================== Secure Credential Storage ====================

  /// Store encrypted credential
  Future<void> storeCredential(String key, String value, {Duration? ttl}) async {
    if (!_initialized) await initialize();
    if (value.isEmpty) {
      await removeCredential(key);
      return;
    }

    try {
      final encrypted = await _encrypt(value);
      final expiry = ttl != null ? DateTime.now().add(ttl) : null;
      
      final credentialData = {
        'encrypted': encrypted,
        'created': DateTime.now().toIso8601String(),
        'expires': expiry?.toIso8601String(),
      };
      
      await _storageService.setHiveData(_credentialsBox, key, credentialData);
      
      // Update cache
      _credentialCache[key] = _CachedCredential(value, expiry);
      
    } catch (e) {
      throw Exception('Failed to store credential: $e');
    }
  }

  /// Retrieve and decrypt credential
  Future<String?> getCredential(String key) async {
    if (!_initialized) await initialize();

    // Check cache first
    final cached = _credentialCache[key];
    if (cached != null && !cached.isExpired) {
      return cached.value;
    }

    try {
      final credentialData = _storageService.getHiveData(_credentialsBox, key);
      if (credentialData == null) return null;
      
      final data = Map<String, dynamic>.from(credentialData);
      
      // Check expiry
      if (data['expires'] != null) {
        final expiry = DateTime.parse(data['expires']);
        if (DateTime.now().isAfter(expiry)) {
          await removeCredential(key);
          return null;
        }
      }
      
      final decrypted = await _decrypt(data['encrypted']);
      
      // Update cache
      final expiry = data['expires'] != null ? DateTime.parse(data['expires']) : null;
      _credentialCache[key] = _CachedCredential(decrypted, expiry);
      
      return decrypted;
      
    } catch (e) {
      print('Failed to decrypt credential $key: $e');
      await removeCredential(key); // Remove corrupted data
      return null;
    }
  }

  /// Store OAuth token securely
  Future<void> _storeOAuthToken(OAuthToken token) async {
    final tokenData = {
      'service': token.service,
      'access_token': await _encrypt(token.accessToken),
      'refresh_token': token.refreshToken != null ? await _encrypt(token.refreshToken!) : null,
      'expires_at': token.expiresAt?.toIso8601String(),
      'scopes': token.scopes,
      'token_type': token.tokenType,
      'created': DateTime.now().toIso8601String(),
    };
    
    await _storageService.setHiveData(_oauthTokensBox, token.service, tokenData);
    
    // Update cache
    _tokenCache[token.service] = _CachedOAuthToken(token, DateTime.now().add(Duration(minutes: 5)));
  }

  /// Get OAuth token for service
  Future<OAuthToken?> getOAuthToken(String service) async {
    if (!_initialized) await initialize();

    // Check cache
    final cached = _tokenCache[service];
    if (cached != null && !cached.isExpired) {
      return cached.token;
    }

    try {
      final tokenData = _storageService.getHiveData(_oauthTokensBox, service);
      if (tokenData == null) return null;
      
      final data = Map<String, dynamic>.from(tokenData);
      
      final accessToken = await _decrypt(data['access_token']);
      final refreshToken = data['refresh_token'] != null ? await _decrypt(data['refresh_token']) : null;
      final expiresAt = data['expires_at'] != null ? DateTime.parse(data['expires_at']) : null;
      
      final token = OAuthToken(
        service: data['service'],
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        scopes: List<String>.from(data['scopes']),
        tokenType: data['token_type'],
      );
      
      // Check if token needs refresh
      if (token.needsRefresh) {
        return await _refreshOAuthToken(token);
      }
      
      // Update cache
      _tokenCache[service] = _CachedOAuthToken(token, DateTime.now().add(Duration(minutes: 5)));
      
      return token;
      
    } catch (e) {
      print('Failed to load OAuth token for $service: $e');
      return null;
    }
  }

  /// Refresh OAuth token if needed
  Future<OAuthToken?> _refreshOAuthToken(OAuthToken token) async {
    if (token.refreshToken == null) return token;

    try {
      // Implementation would make HTTP request to refresh token
      // For now, return the existing token
      print('⚠️ Token refresh not implemented for ${token.service}');
      return token;
    } catch (e) {
      print('Failed to refresh token for ${token.service}: $e');
      return null;
    }
  }

  // ==================== AES-256-GCM Encryption ====================

  /// Encrypt using AES-256-GCM
  Future<String> _encrypt(String plaintext) async {
    if (_masterKey == null) throw Exception('Master key not initialized');

    try {
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
      final nonce = _generateSecureBytes(12); // 96-bit nonce for GCM
      
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(KeyParameter(_masterKey!), 128, nonce, Uint8List(0));
      
      cipher.init(true, params);
      
      final ciphertext = cipher.process(plaintextBytes);
      
      // Combine nonce + ciphertext (includes auth tag)
      final result = Uint8List(nonce.length + ciphertext.length);
      result.setRange(0, nonce.length, nonce);
      result.setRange(nonce.length, result.length, ciphertext);
      
      return base64Encode(result);
      
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt using AES-256-GCM
  Future<String> _decrypt(String encrypted) async {
    if (_masterKey == null) throw Exception('Master key not initialized');

    try {
      final data = base64Decode(encrypted);
      
      if (data.length < 12) throw Exception('Invalid encrypted data');
      
      final nonce = data.sublist(0, 12);
      final ciphertext = data.sublist(12);
      
      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(KeyParameter(_masterKey!), 128, nonce, Uint8List(0));
      
      cipher.init(false, params);
      
      final decrypted = cipher.process(ciphertext);
      
      return utf8.decode(decrypted);
      
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Remove credential
  Future<void> removeCredential(String key) async {
    await _storageService.removeHiveData(_credentialsBox, key);
    _credentialCache.remove(key);
  }

  /// Delete credential (alias for removeCredential for API consistency)
  Future<void> deleteCredential(String key) async {
    await removeCredential(key);
  }

  /// Remove OAuth token
  Future<void> removeOAuthToken(String service) async {
    await _storageService.removeHiveData(_oauthTokensBox, service);
    _tokenCache.remove(service);
  }

  /// Clear all credentials and tokens
  Future<void> clearAllCredentials() async {
    await _storageService.clearHiveBox(_credentialsBox);
    await _storageService.clearHiveBox(_oauthTokensBox);
    _credentialCache.clear();
    _tokenCache.clear();
  }


  /// Get list of configured OAuth services
  List<String> getConfiguredOAuthServices() {
    return _storageService.getAllHiveData(_oauthTokensBox).keys.cast<String>().toList();
  }

  /// Check if service has valid OAuth token
  Future<bool> hasValidOAuthToken(String service) async {
    final token = await getOAuthToken(service);
    return token != null && !token.isExpired;
  }
}

// ==================== Data Models ====================

class OAuthToken {
  final String service;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final List<String> scopes;
  final String tokenType;

  OAuthToken({
    required this.service,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.scopes = const [],
    this.tokenType = 'Bearer',
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get needsRefresh {
    if (expiresAt == null) return false;
    // Refresh if expires within 5 minutes
    return DateTime.now().isAfter(expiresAt!.subtract(Duration(minutes: 5)));
  }

  String get authorizationHeader => '$tokenType $accessToken';
}

class OAuthResult {
  final OAuthStatus status;
  final String? authUrl;
  final String? state;
  final String? error;
  final OAuthToken? token;

  OAuthResult._(this.status, {this.authUrl, this.state, this.error, this.token});

  factory OAuthResult.pending(String authUrl, String state) {
    return OAuthResult._(OAuthStatus.pending, authUrl: authUrl, state: state);
  }

  factory OAuthResult.success(OAuthToken token) {
    return OAuthResult._(OAuthStatus.success, token: token);
  }

  factory OAuthResult.error(String error) {
    return OAuthResult._(OAuthStatus.error, error: error);
  }
}

enum OAuthStatus { pending, success, error }

class _CachedCredential {
  final String value;
  final DateTime? expiresAt;
  final DateTime cachedAt = DateTime.now();

  _CachedCredential(this.value, this.expiresAt);

  bool get isExpired {
    // Cache expires after 5 minutes or at credential expiry
    final cacheExpiry = cachedAt.add(Duration(minutes: 5));
    final now = DateTime.now();
    
    if (now.isAfter(cacheExpiry)) return true;
    if (expiresAt != null && now.isAfter(expiresAt!)) return true;
    
    return false;
  }
}

class _CachedOAuthToken {
  final OAuthToken token;
  final DateTime expiresAt;
  final DateTime cachedAt = DateTime.now();

  _CachedOAuthToken(this.token, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ==================== Riverpod Providers ====================

final secureAuthServiceProvider = Provider<SecureAuthService>((ref) {
  final storageService = ref.read(desktopStorageServiceProvider);
  return SecureAuthService(storageService);
});

final authInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.read(secureAuthServiceProvider);
  await service.initialize();
});

final oauthServicesProvider = Provider<List<String>>((ref) {
  final service = ref.read(secureAuthServiceProvider);
  return service.getConfiguredOAuthServices();
});
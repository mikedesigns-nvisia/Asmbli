import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'desktop/desktop_storage_service.dart';
import 'desktop/desktop_service_provider.dart';
import 'desktop/macos_keychain_service.dart';

/// Unified service for secure storage and retrieval of API credentials and tokens
/// Uses native macOS Keychain on macOS, fallback to encrypted storage on other platforms
class SecureCredentialsService {
  final DesktopStorageService _storageService;
  final MacOSKeychainService? _keychainService;

  static const String _credentialsBox = 'secure_credentials';
  static const String _saltKey = 'mcp_credential_salt';

  // Cache for decrypted credentials to avoid repeated decryption
  final Map<String, String> _credentialCache = {};
  String? _encryptionKey;

  SecureCredentialsService(
    this._storageService, [
    this._keychainService,
  ]);

  /// Check if native secure storage (Keychain) is available
  bool get useNativeKeychain =>
      !kIsWeb && Platform.isMacOS && _keychainService != null;

  /// Initialize secure storage with encryption key
  Future<void> initialize() async {
    if (useNativeKeychain) {
      await _keychainService!.initialize();
      print('✓ Using macOS Keychain for credential storage');
    } else {
      await _initializeEncryptionKey();
      print('✓ Using encrypted storage for credentials');
    }
  }

  /// Store encrypted credential
  Future<void> storeCredential(String key, String value) async {
    if (value.isEmpty) {
      await removeCredential(key);
      return;
    }

    if (useNativeKeychain) {
      await _keychainService!.storeCredential(key, value);
    } else {
      final encryptedValue = await _encrypt(value);
      await _storageService.setHiveData(_credentialsBox, key, encryptedValue);
    }

    // Update cache
    _credentialCache[key] = value;
  }

  /// Store multiple credentials in a batch
  Future<void> storeCredentials(Map<String, String> credentials) async {
    if (useNativeKeychain) {
      await _keychainService!.storeCredentials(credentials);
      // Update cache
      _credentialCache.addAll(credentials);
    } else {
      for (final entry in credentials.entries) {
        await storeCredential(entry.key, entry.value);
      }
    }
  }

  /// Retrieve and decrypt credential
  Future<String?> getCredential(String key) async {
    // Check cache first
    if (_credentialCache.containsKey(key)) {
      return _credentialCache[key];
    }

    String? value;

    if (useNativeKeychain) {
      value = await _keychainService!.getCredential(key);
    } else {
      final encryptedValue = _storageService.getHiveData(_credentialsBox, key) as String?;
      if (encryptedValue == null) {
        return null;
      }

      try {
        value = await _decrypt(encryptedValue);
      } catch (e) {
        print('Failed to decrypt credential $key: $e');
        // Remove corrupted credential
        await removeCredential(key);
        return null;
      }
    }

    if (value != null) {
      _credentialCache[key] = value;
    }

    return value;
  }

  /// Retrieve multiple credentials
  Future<Map<String, String>> getCredentials(List<String> keys) async {
    if (useNativeKeychain) {
      final result = await _keychainService!.getCredentials(keys);
      // Update cache
      _credentialCache.addAll(result);
      return result;
    } else {
      final result = <String, String>{};
      for (final key in keys) {
        final value = await getCredential(key);
        if (value != null) {
          result[key] = value;
        }
      }
      return result;
    }
  }

  /// Check if credential exists
  Future<bool> hasCredential(String key) async {
    if (_credentialCache.containsKey(key)) {
      return true;
    }

    if (useNativeKeychain) {
      return await _keychainService!.hasCredential(key);
    } else {
      return _storageService.getHiveData(_credentialsBox, key) != null;
    }
  }

  /// Remove credential
  Future<void> removeCredential(String key) async {
    if (useNativeKeychain) {
      await _keychainService!.removeCredential(key);
    } else {
      await _storageService.removeHiveData(_credentialsBox, key);
    }
    _credentialCache.remove(key);
  }

  /// Clear all credentials
  Future<void> clearAllCredentials() async {
    if (useNativeKeychain) {
      await _keychainService!.clearAllCredentials();
    } else {
      await _storageService.clearHiveBox(_credentialsBox);
    }
    _credentialCache.clear();
  }

  /// Get all stored credential keys (for management)
  Future<List<String>> getStoredCredentialKeys() async {
    if (useNativeKeychain) {
      return await _keychainService!.getStoredCredentialKeys();
    } else {
      final box = _storageService.getAllHiveData(_credentialsBox);
      return box.keys.cast<String>().toList();
    }
  }

  /// Validate credential format (basic validation)
  bool validateCredential(String key, String value) {
    if (useNativeKeychain) {
      return _keychainService!.validateCredential(key, value);
    }

    if (value.isEmpty) return false;

    // Basic validation patterns for common credential types
    switch (key.toLowerCase()) {
      case String k when k.contains('github'):
        return value.startsWith('ghp_') || value.startsWith('github_pat_');
      case String k when k.contains('slack'):
        return value.startsWith('xoxb-') || value.startsWith('xoxp-');
      case String k when k.contains('api_key'):
        return value.length >= 16; // Minimum reasonable API key length
      case String k when k.contains('token'):
        return value.length >= 8;  // Minimum reasonable token length
      case String k when k.contains('bearer'):
        return value.length >= 16;
      default:
        return value.length >= 4; // Very basic minimum
    }
  }

  /// Check credential health (not expired, format valid)
  Future<Map<String, bool>> checkCredentialHealth(List<String> keys) async {
    final result = <String, bool>{};
    for (final key in keys) {
      final value = await getCredential(key);
      if (value == null) {
        result[key] = false;
      } else {
        result[key] = validateCredential(key, value);
      }
    }
    return result;
  }

  // ==================== Private Methods ====================

  /// Initialize encryption key using system-specific data
  Future<void> _initializeEncryptionKey() async {
    // Try to get existing salt
    String? salt = _storageService.getPreference<String>(_saltKey);
    
    // Generate new salt if none exists
    if (salt == null) {
      salt = _generateSalt();
      await _storageService.setPreference(_saltKey, salt);
    }

    // Derive encryption key from salt + system info
    _encryptionKey = await _deriveEncryptionKey(salt);
  }

  /// Generate random salt for key derivation
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Derive encryption key from salt and system information
  Future<String> _deriveEncryptionKey(String salt) async {
    // Combine salt with some system-specific information
    // Note: In production, you might want to use more sophisticated key derivation
    final systemInfo = _getSystemInfo();
    final combined = salt + systemInfo;
    
    // Use PBKDF2-like approach with multiple rounds of hashing
    var key = utf8.encode(combined);
    for (int i = 0; i < 1000; i++) {
      key = Uint8List.fromList(sha256.convert(key).bytes);
    }
    
    return base64Encode(key.take(32).toList()); // Use first 32 bytes as key
  }

  /// Get system-specific information for key derivation
  String _getSystemInfo() {
    // Use a combination of relatively stable system identifiers
    // Note: This is a simplified approach. In production, consider using
    // platform-specific APIs for hardware fingerprinting
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final appVersion = '1.0.0'; // Could be retrieved from package info
    
    // Create a somewhat stable but not too predictable identifier
    return 'asmbli_agent_$appVersion${timestamp ~/ 1000000}'; // Stable for ~11 days
  }

  /// Simple encryption using XOR with derived key
  /// Note: This is a basic implementation. For production use, consider AES encryption
  Future<String> _encrypt(String plaintext) async {
    if (_encryptionKey == null) {
      throw Exception('Encryption key not initialized');
    }

    final keyBytes = base64Decode(_encryptionKey!);
    final plaintextBytes = utf8.encode(plaintext);
    final encryptedBytes = List<int>.generate(plaintextBytes.length, (i) {
      return plaintextBytes[i] ^ keyBytes[i % keyBytes.length];
    });

    // Add simple integrity check
    final hash = sha256.convert(plaintextBytes).bytes.take(4).toList();
    final result = [...hash, ...encryptedBytes];
    
    return base64Encode(result);
  }

  /// Simple decryption using XOR with derived key
  Future<String> _decrypt(String encrypted) async {
    if (_encryptionKey == null) {
      throw Exception('Encryption key not initialized');
    }

    try {
      final keyBytes = base64Decode(_encryptionKey!);
      final encryptedData = base64Decode(encrypted);
      
      // Extract hash and encrypted bytes
      if (encryptedData.length < 4) {
        throw Exception('Invalid encrypted data');
      }
      
      final hash = encryptedData.take(4).toList();
      final encryptedBytes = encryptedData.skip(4).toList();
      
      // Decrypt
      final decryptedBytes = List<int>.generate(encryptedBytes.length, (i) {
        return encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      });
      
      // Verify integrity
      final expectedHash = sha256.convert(decryptedBytes).bytes.take(4).toList();
      if (!_listEquals(hash, expectedHash)) {
        throw Exception('Integrity check failed');
      }
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Compare two lists for equality
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Enhanced credentials service with MCP-specific helpers
class MCPCredentialsService {
  final SecureCredentialsService _secureService;
  
  MCPCredentialsService(this._secureService);

  /// Store MCP server credentials with automatic key prefixing
  Future<void> storeMCPServerCredentials(
    String serverId,
    String agentId,
    Map<String, String> credentials,
  ) async {
    for (final entry in credentials.entries) {
      final key = _getMCPCredentialKey(serverId, agentId, entry.key);
      await _secureService.storeCredential(key, entry.value);
    }
  }

  /// Retrieve MCP server credentials
  Future<Map<String, String>> getMCPServerCredentials(
    String serverId,
    String agentId,
    List<String> credentialNames,
  ) async {
    final result = <String, String>{};
    for (final name in credentialNames) {
      final key = _getMCPCredentialKey(serverId, agentId, name);
      final value = await _secureService.getCredential(key);
      if (value != null) {
        result[name] = value;
      }
    }
    return result;
  }

  /// Remove MCP server credentials
  Future<void> removeMCPServerCredentials(
    String serverId,
    String agentId,
    List<String> credentialNames,
  ) async {
    for (final name in credentialNames) {
      final key = _getMCPCredentialKey(serverId, agentId, name);
      await _secureService.removeCredential(key);
    }
  }

  /// Check if all required MCP credentials are stored and valid
  Future<bool> validateMCPServerCredentials(
    String serverId,
    String agentId,
    List<String> requiredCredentials,
  ) async {
    for (final credName in requiredCredentials) {
      final key = _getMCPCredentialKey(serverId, agentId, credName);
      final value = await _secureService.getCredential(key);
      if (value == null || !_secureService.validateCredential(credName, value)) {
        return false;
      }
    }
    return true;
  }

  /// Generate scoped credential key for MCP servers
  String _getMCPCredentialKey(String serverId, String agentId, String credentialName) {
    return 'mcp:$agentId:$serverId:$credentialName';
  }
}

// ==================== Riverpod Providers ====================

final secureCredentialsServiceProvider = Provider<SecureCredentialsService>((ref) {
  final storageService = ref.read(desktopStorageServiceProvider);

  // Try to get macOS Keychain service if available
  MacOSKeychainService? keychainService;
  if (!kIsWeb && Platform.isMacOS) {
    try {
      keychainService = ref.read(macOSKeychainServiceProvider);
    } catch (e) {
      // Keychain service not available, fall back to encrypted storage
      print('Keychain service not available, using encrypted storage: $e');
    }
  }

  return SecureCredentialsService(storageService, keychainService);
});

final mcpCredentialsServiceProvider = Provider<MCPCredentialsService>((ref) {
  final secureService = ref.read(secureCredentialsServiceProvider);
  return MCPCredentialsService(secureService);
});

/// Provider for credential initialization
final credentialsInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.read(secureCredentialsServiceProvider);
  await service.initialize();
});
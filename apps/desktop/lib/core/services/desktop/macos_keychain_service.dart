import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// macOS-native Keychain service for secure credential storage
/// Uses the system Keychain for proper security integration
class MacOSKeychainService {
  static MacOSKeychainService? _instance;
  late final FlutterSecureStorage _secureStorage;

  MacOSKeychainService._() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        groupId: 'group.com.asmbli.agentengine',
        accountName: 'AgentEngine',
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(
        groupId: 'group.com.asmbli.agentengine',
        accountName: 'AgentEngine',
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  static MacOSKeychainService get instance {
    _instance ??= MacOSKeychainService._();
    return _instance!;
  }

  bool get isSupported => !kIsWeb && Platform.isMacOS;

  /// Initialize the Keychain service
  Future<void> initialize() async {
    if (!isSupported) {
      print('Keychain service not supported on this platform');
      return;
    }

    try {
      // Test keychain access
      await _secureStorage.containsKey(key: '_keychain_test');
      print('✓ macOS Keychain service initialized');
    } catch (e) {
      print('✗ Keychain initialization failed: $e');
      rethrow;
    }
  }

  /// Store a credential in the macOS Keychain
  Future<void> storeCredential(String key, String value) async {
    if (!isSupported) {
      throw UnsupportedError('Keychain not available on this platform');
    }

    if (value.isEmpty) {
      await removeCredential(key);
      return;
    }

    try {
      await _secureStorage.write(
        key: _sanitizeKey(key),
        value: value,
      );
    } catch (e) {
      throw Exception('Failed to store credential in Keychain: $e');
    }
  }

  /// Store multiple credentials in batch
  Future<void> storeCredentials(Map<String, String> credentials) async {
    if (!isSupported) {
      throw UnsupportedError('Keychain not available on this platform');
    }

    for (final entry in credentials.entries) {
      await storeCredential(entry.key, entry.value);
    }
  }

  /// Retrieve a credential from the macOS Keychain
  Future<String?> getCredential(String key) async {
    if (!isSupported) {
      return null;
    }

    try {
      return await _secureStorage.read(key: _sanitizeKey(key));
    } catch (e) {
      print('Failed to read credential from Keychain: $e');
      return null;
    }
  }

  /// Retrieve multiple credentials
  Future<Map<String, String>> getCredentials(List<String> keys) async {
    if (!isSupported) {
      return {};
    }

    final result = <String, String>{};
    for (final key in keys) {
      final value = await getCredential(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  /// Check if a credential exists in the Keychain
  Future<bool> hasCredential(String key) async {
    if (!isSupported) {
      return false;
    }

    try {
      return await _secureStorage.containsKey(key: _sanitizeKey(key));
    } catch (e) {
      print('Failed to check credential existence: $e');
      return false;
    }
  }

  /// Remove a credential from the Keychain
  Future<void> removeCredential(String key) async {
    if (!isSupported) {
      return;
    }

    try {
      await _secureStorage.delete(key: _sanitizeKey(key));
    } catch (e) {
      print('Failed to remove credential from Keychain: $e');
    }
  }

  /// Clear all stored credentials
  Future<void> clearAllCredentials() async {
    if (!isSupported) {
      return;
    }

    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print('Failed to clear all credentials: $e');
    }
  }

  /// Get all stored credential keys
  Future<List<String>> getStoredCredentialKeys() async {
    if (!isSupported) {
      return [];
    }

    try {
      final allData = await _secureStorage.readAll();
      return allData.keys.map((key) => _desanitizeKey(key)).toList();
    } catch (e) {
      print('Failed to get credential keys: $e');
      return [];
    }
  }

  /// Validate credential format based on common patterns
  bool validateCredential(String key, String value) {
    if (value.isEmpty) return false;

    // Common credential validation patterns
    switch (key.toLowerCase()) {
      case String k when k.contains('github'):
        return value.startsWith('ghp_') ||
               value.startsWith('github_pat_') ||
               value.startsWith('gho_') ||
               value.startsWith('ghu_');
      case String k when k.contains('slack'):
        return value.startsWith('xoxb-') ||
               value.startsWith('xoxp-') ||
               value.startsWith('xapp-');
      case String k when k.contains('openai'):
        return value.startsWith('sk-') && value.length > 20;
      case String k when k.contains('anthropic'):
        return value.startsWith('sk-ant-') && value.length > 20;
      case String k when k.contains('api_key'):
        return value.length >= 16;
      case String k when k.contains('token'):
        return value.length >= 8;
      case String k when k.contains('bearer'):
        return value.length >= 16;
      case String k when k.contains('secret'):
        return value.length >= 12;
      default:
        return value.length >= 4;
    }
  }

  /// Check health of stored credentials
  Future<Map<String, CredentialHealth>> checkCredentialHealth(List<String> keys) async {
    final result = <String, CredentialHealth>{};

    for (final key in keys) {
      final value = await getCredential(key);
      if (value == null) {
        result[key] = CredentialHealth.missing;
      } else if (!validateCredential(key, value)) {
        result[key] = CredentialHealth.invalid;
      } else {
        result[key] = CredentialHealth.valid;
      }
    }

    return result;
  }

  /// Test Keychain connectivity
  Future<bool> testKeychainAccess() async {
    if (!isSupported) {
      return false;
    }

    try {
      const testKey = '_keychain_connectivity_test';
      const testValue = 'test_value';

      await storeCredential(testKey, testValue);
      final retrieved = await getCredential(testKey);
      await removeCredential(testKey);

      return retrieved == testValue;
    } catch (e) {
      print('Keychain connectivity test failed: $e');
      return false;
    }
  }

  /// Get Keychain service information
  Map<String, dynamic> getServiceInfo() {
    return {
      'platform': 'macOS',
      'supported': isSupported,
      'provider': 'FlutterSecureStorage',
      'backend': 'macOS Keychain',
      'encryption': 'Hardware-backed encryption',
      'groupId': 'group.com.asmbli.agentengine',
      'accessibility': 'first_unlock_this_device',
    };
  }

  // ==================== Private Methods ====================

  /// Sanitize key for Keychain storage (remove special characters)
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Desanitize key for display
  String _desanitizeKey(String sanitizedKey) {
    // In practice, you might want to store a mapping
    // For now, just return as-is
    return sanitizedKey;
  }
}

/// Enhanced MCP credentials service using macOS Keychain
class MacOSMCPCredentialsService {
  final MacOSKeychainService _keychainService;

  MacOSMCPCredentialsService(this._keychainService);

  /// Store MCP server credentials with proper namespacing
  Future<void> storeMCPServerCredentials(
    String serverId,
    String agentId,
    Map<String, String> credentials,
  ) async {
    for (final entry in credentials.entries) {
      final key = _getMCPCredentialKey(serverId, agentId, entry.key);
      await _keychainService.storeCredential(key, entry.value);
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
      final value = await _keychainService.getCredential(key);
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
      await _keychainService.removeCredential(key);
    }
  }

  /// Validate all required MCP credentials exist and are valid
  Future<bool> validateMCPServerCredentials(
    String serverId,
    String agentId,
    List<String> requiredCredentials,
  ) async {
    for (final credName in requiredCredentials) {
      final key = _getMCPCredentialKey(serverId, agentId, credName);
      final value = await _keychainService.getCredential(key);
      if (value == null || !_keychainService.validateCredential(credName, value)) {
        return false;
      }
    }
    return true;
  }

  /// Get health status of MCP credentials
  Future<Map<String, CredentialHealth>> getMCPCredentialHealth(
    String serverId,
    String agentId,
    List<String> credentialNames,
  ) async {
    final keys = credentialNames
        .map((name) => _getMCPCredentialKey(serverId, agentId, name))
        .toList();

    return await _keychainService.checkCredentialHealth(keys);
  }

  /// Generate namespaced credential key for MCP servers
  String _getMCPCredentialKey(String serverId, String agentId, String credentialName) {
    return 'mcp.$agentId.$serverId.$credentialName';
  }
}

/// Credential health status
enum CredentialHealth {
  valid,
  invalid,
  missing,
  expired,
}

// ==================== Riverpod Providers ====================

final macOSKeychainServiceProvider = Provider<MacOSKeychainService>((ref) {
  return MacOSKeychainService.instance;
});

final macOSMCPCredentialsServiceProvider = Provider<MacOSMCPCredentialsService>((ref) {
  final keychainService = ref.read(macOSKeychainServiceProvider);
  return MacOSMCPCredentialsService(keychainService);
});

/// Provider for Keychain initialization
final keychainInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.read(macOSKeychainServiceProvider);
  await service.initialize();
});

/// Provider for Keychain connectivity test
final keychainConnectivityProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(macOSKeychainServiceProvider);
  return await service.testKeychainAccess();
});
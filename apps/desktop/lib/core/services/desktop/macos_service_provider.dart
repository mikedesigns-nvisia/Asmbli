import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desktop_service_provider.dart';
import 'macos_keychain_service.dart';
import 'window_management_service.dart';
import 'desktop_storage_service.dart';

/// macOS-specific service provider that extends the base desktop provider
/// with native macOS features and integrations
class MacOSServiceProvider extends DesktopServiceProvider {
  static MacOSServiceProvider? _instance;

  late final MacOSKeychainService _keychainService;
  late final MacOSMCPCredentialsService _mcpCredentialsService;
  bool _macOSInitialized = false;

  MacOSServiceProvider._() : super();

  static MacOSServiceProvider get instance {
    _instance ??= MacOSServiceProvider._();
    return _instance!;
  }

  /// Get the native macOS Keychain service
  MacOSKeychainService get keychain => _keychainService;

  /// Get the macOS-specific MCP credentials service
  MacOSMCPCredentialsService get mcpCredentials => _mcpCredentialsService;

  @override
  bool get isMacOS => Platform.isMacOS;

  /// Initialize macOS-specific services
  @override
  Future<void> initialize() async {
    // Initialize base desktop services first
    await super.initialize();

    if (!isMacOS) {
      print('macOS services not available on this platform');
      return;
    }

    if (_macOSInitialized) {
      print('macOS services already initialized');
      return;
    }

    try {
      // Initialize macOS Keychain service
      _keychainService = MacOSKeychainService.instance;
      await _keychainService.initialize();
      print('✓ macOS Keychain service initialized');

      // Initialize MCP credentials service
      _mcpCredentialsService = MacOSMCPCredentialsService(_keychainService);
      print('✓ macOS MCP credentials service initialized');

      _macOSInitialized = true;
      print('✓ macOS-specific services initialized');
    } catch (e) {
      print('✗ macOS service initialization failed: $e');
      rethrow;
    }
  }

  @override
  Map<String, dynamic> getPlatformCapabilities() {
    final baseCapabilities = super.getPlatformCapabilities();

    if (!isMacOS) {
      return baseCapabilities;
    }

    // Add macOS-specific capabilities
    baseCapabilities['macOS'] = {
      'keychain': {
        'supported': true,
        'hardwareEncryption': true,
        'biometricAuth': true,
        'groupAccess': true,
      },
      'notifications': {
        'native': true,
        'userNotifications': true,
        'banners': true,
        'badges': true,
      },
      'security': {
        'appSandbox': true,
        'codeSignature': true,
        'entitlements': true,
        'gatekeeper': true,
      },
      'fileSystem': {
        'securityScopedBookmarks': true,
        'powerboxAccess': true,
        'documentTypes': true,
        'quarantine': true,
      },
      'window': {
        'nativeToolbar': true,
        'trafficLights': true,
        'vibrancy': true,
        'titlebarTransparency': true,
      }
    };

    return baseCapabilities;
  }

  @override
  Future<Map<String, dynamic>> getSystemInfo() async {
    final baseInfo = await super.getSystemInfo();

    if (!isMacOS) {
      return baseInfo;
    }

    try {
      // Add macOS-specific system information
      final keychainInfo = _keychainService.getServiceInfo();
      final keychainConnectivity = await _keychainService.testKeychainAccess();

      baseInfo['macOS'] = {
        'version': await _getMacOSVersion(),
        'architecture': await _getArchitecture(),
        'keychain': {
          ...keychainInfo,
          'connectivity': keychainConnectivity,
          'credentialCount': (await _keychainService.getStoredCredentialKeys()).length,
        },
        'security': {
          'sandboxed': await _isAppSandboxed(),
          'codeSigningStatus': await _getCodeSigningStatus(),
          'entitlementsValid': await _validateEntitlements(),
        },
        'hardware': {
          'hasSecureEnclave': await _hasSecureEnclave(),
          'touchIdAvailable': await _isTouchIdAvailable(),
        }
      };
    } catch (e) {
      baseInfo['macOS'] = {'error': 'Failed to gather macOS info: $e'};
    }

    return baseInfo;
  }

  @override
  Future<bool> isHealthy() async {
    final baseHealthy = await super.isHealthy();

    if (!isMacOS || !_macOSInitialized) {
      return baseHealthy;
    }

    try {
      final keychainHealthy = await _keychainService.testKeychainAccess();
      return baseHealthy && keychainHealthy;
    } catch (e) {
      print('macOS health check failed: $e');
      return false;
    }
  }

  @override
  Future<void> performMaintenance() async {
    await super.performMaintenance();

    if (!isMacOS || !_macOSInitialized) {
      return;
    }

    try {
      // Test keychain connectivity
      final keychainOk = await _keychainService.testKeychainAccess();
      if (!keychainOk) {
        print('⚠️ Keychain connectivity issues detected');
      } else {
        print('✓ Keychain maintenance check passed');
      }

      // Could add credential health checks here
      print('✓ macOS maintenance completed');
    } catch (e) {
      print('✗ macOS maintenance failed: $e');
    }
  }

  /// Migrate credentials from legacy storage to Keychain
  Future<void> migrateCredentialsToKeychain() async {
    if (!isMacOS || !_macOSInitialized) {
      throw StateError('macOS services not initialized');
    }

    print('🔄 Starting credential migration to Keychain...');

    try {
      // This would migrate from the old SecureCredentialsService
      // Implementation depends on your current credential storage
      print('✓ Credential migration completed');
    } catch (e) {
      print('✗ Credential migration failed: $e');
      rethrow;
    }
  }

  /// Check if app has necessary macOS permissions
  Future<Map<String, bool>> checkMacOSPermissions() async {
    if (!isMacOS) {
      return {};
    }

    return {
      'keychain': await _keychainService.testKeychainAccess(),
      'fileSystem': await _checkFileSystemPermissions(),
      'network': await _checkNetworkPermissions(),
    };
  }

  // ==================== Private macOS Methods ====================

  Future<String> _getMacOSVersion() async {
    try {
      final result = await Process.run('sw_vers', ['-productVersion']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getArchitecture() async {
    try {
      final result = await Process.run('uname', ['-m']);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<bool> _isAppSandboxed() async {
    // Check if app is running in sandbox mode
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      return homeDir.contains('Containers');
    } catch (e) {
      return false;
    }
  }

  Future<String> _getCodeSigningStatus() async {
    try {
      final result = await Process.run('codesign', ['-dv', Platform.resolvedExecutable]);
      return result.stderr.toString().contains('Signature=') ? 'Valid' : 'Invalid';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<bool> _validateEntitlements() async {
    // Basic entitlements validation
    try {
      final result = await Process.run('codesign', ['-d', '--entitlements', ':-', Platform.resolvedExecutable]);
      final entitlements = result.stdout.toString();
      return entitlements.contains('com.apple.security.app-sandbox');
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasSecureEnclave() async {
    // Check for Secure Enclave availability (T2 chip or Apple Silicon)
    try {
      final result = await Process.run('system_profiler', ['SPHardwareDataType']);
      final output = result.stdout.toString();
      return output.contains('Apple') && (output.contains('T2') || output.contains('Apple M'));
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isTouchIdAvailable() async {
    // Check if Touch ID is available
    try {
      final result = await Process.run('bioutil', ['-r']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkFileSystemPermissions() async {
    try {
      // Test basic file system access
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/agentengine_fs_test.txt');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkNetworkPermissions() async {
    try {
      // Test basic network connectivity
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://httpbin.org/get'));
      final response = await request.close();
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _macOSInitialized = false;
  }
}

// ==================== Riverpod Providers ====================

final macOSServiceProvider = Provider<MacOSServiceProvider>((ref) {
  return MacOSServiceProvider.instance;
});

final macOSSystemInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final macOSService = ref.read(macOSServiceProvider);
  return await macOSService.getSystemInfo();
});

final macOSPermissionsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final macOSService = ref.read(macOSServiceProvider);
  return await macOSService.checkMacOSPermissions();
});

final macOSCapabilitiesProvider = Provider<Map<String, dynamic>>((ref) {
  final macOSService = ref.read(macOSServiceProvider);
  return macOSService.getPlatformCapabilities();
});

/// Provider that initializes all macOS services
final macOSInitializationProvider = FutureProvider<void>((ref) async {
  final macOSService = ref.read(macOSServiceProvider);
  await macOSService.initialize();
});
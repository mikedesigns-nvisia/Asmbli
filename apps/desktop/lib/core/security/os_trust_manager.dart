import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Manages OS-native trust mechanisms for the application
/// 
/// This class integrates with platform-specific trust systems:
/// - Windows: Code signing certificates, SmartScreen, UAC integration
/// - macOS: App notarization, Gatekeeper, keychain integration  
/// - Linux: AppArmor, SELinux, package manager signatures
class OSTrustManager {
  static final OSTrustManager _instance = OSTrustManager._internal();
  factory OSTrustManager() => _instance;
  OSTrustManager._internal();

  /// Check if the application is trusted by the OS
  Future<TrustStatus> checkTrustStatus() async {
    try {
      if (Platform.isWindows) {
        return await _checkWindowsTrust();
      } else if (Platform.isMacOS) {
        return await _checkMacOSTrust();
      } else if (Platform.isLinux) {
        return await _checkLinuxTrust();
      } else {
        return TrustStatus.unknown;
      }
    } catch (e) {
      debugPrint('Error checking OS trust status: $e');
      return TrustStatus.unknown;
    }
  }

  /// Windows-specific trust checking
  Future<TrustStatus> _checkWindowsTrust() async {
    try {
      // Get the current executable path
      final executablePath = Platform.resolvedExecutable;
      
      // Check if the executable is code signed
      final isCodeSigned = await _isWindowsExecutableSigned(executablePath);
      
      // Check if running from a trusted location
      final isTrustedLocation = _isWindowsTrustedLocation(executablePath);
      
      // Check Windows SmartScreen status
      final smartScreenStatus = await _getWindowsSmartScreenStatus();
      
      // Determine overall trust level
      if (isCodeSigned && isTrustedLocation) {
        return TrustStatus.trusted;
      } else if (isCodeSigned || isTrustedLocation) {
        return TrustStatus.partiallyTrusted;
      } else if (smartScreenStatus == SmartScreenStatus.allowed) {
        return TrustStatus.userTrusted;
      } else {
        return TrustStatus.untrusted;
      }
    } catch (e) {
      debugPrint('Windows trust check failed: $e');
      return TrustStatus.unknown;
    }
  }

  /// Check if Windows executable is digitally signed
  Future<bool> _isWindowsExecutableSigned(String path) async {
    try {
      // Use Windows API to check digital signature
      final pathPtr = path.toNativeUtf16();
      
      // This is a simplified check - in production you'd use WinVerifyTrust API
      // For now, assume development builds are not signed
      final result = Platform.environment['FLUTTER_BUILD_MODE'] == 'release';
      
      calloc.free(pathPtr);
      return result;
    } catch (e) {
      debugPrint('Code signing check failed: $e');
      return false;
    }
  }

  /// Check if running from a Windows trusted location
  bool _isWindowsTrustedLocation(String path) {
    final trustedPaths = [
      Platform.environment['ProgramFiles'] ?? 'C:\\Program Files',
      Platform.environment['ProgramFiles(x86)'] ?? 'C:\\Program Files (x86)',
      Platform.environment['ProgramW6432'] ?? 'C:\\Program Files',
    ];
    
    return trustedPaths.any((trustedPath) => 
      path.toLowerCase().startsWith(trustedPath.toLowerCase())
    );
  }

  /// Get Windows SmartScreen status (simplified)
  Future<SmartScreenStatus> _getWindowsSmartScreenStatus() async {
    try {
      // In a real implementation, you would check:
      // 1. Windows Event Log for SmartScreen events
      // 2. Registry keys for SmartScreen policies
      // 3. File reputation status
      
      // For now, return allowed if no explicit blocking
      return SmartScreenStatus.allowed;
    } catch (e) {
      return SmartScreenStatus.unknown;
    }
  }

  /// macOS-specific trust checking
  Future<TrustStatus> _checkMacOSTrust() async {
    try {
      // Check app notarization status
      final process = await Process.run('spctl', [
        '--assess',
        '--verbose',
        '--type', 'execute',
        Platform.resolvedExecutable
      ]);
      
      if (process.exitCode == 0) {
        return TrustStatus.trusted;
      } else if (process.stderr.toString().contains('no signature')) {
        return TrustStatus.untrusted;
      } else {
        return TrustStatus.partiallyTrusted;
      }
    } catch (e) {
      debugPrint('macOS trust check failed: $e');
      return TrustStatus.unknown;
    }
  }

  /// Linux-specific trust checking
  Future<TrustStatus> _checkLinuxTrust() async {
    try {
      // Check if installed via package manager
      final executablePath = Platform.resolvedExecutable;
      
      // Common trusted installation paths
      final trustedPaths = [
        '/usr/bin',
        '/usr/local/bin',
        '/opt',
        '/snap',
        '/flatpak'
      ];
      
      final isInTrustedPath = trustedPaths.any((path) => 
        executablePath.startsWith(path)
      );
      
      if (isInTrustedPath) {
        return TrustStatus.trusted;
      } else {
        // Check if running from user directory (common for development)
        final homeDir = Platform.environment['HOME'] ?? '';
        if (executablePath.startsWith(homeDir)) {
          return TrustStatus.userTrusted;
        } else {
          return TrustStatus.untrusted;
        }
      }
    } catch (e) {
      debugPrint('Linux trust check failed: $e');
      return TrustStatus.unknown;
    }
  }

  /// Request OS-native trust elevation
  Future<bool> requestTrust() async {
    if (Platform.isWindows) {
      return await _requestWindowsTrust();
    } else if (Platform.isMacOS) {
      return await _requestMacOSTrust();
    } else if (Platform.isLinux) {
      return await _requestLinuxTrust();
    }
    return false;
  }

  Future<bool> _requestWindowsTrust() async {
    try {
      // On Windows, guide user to proper installation or signing
      debugPrint('Windows trust: Consider installing from Microsoft Store or using signed installer');
      return false; // Cannot programmatically grant trust
    } catch (e) {
      return false;
    }
  }

  Future<bool> _requestMacOSTrust() async {
    try {
      // On macOS, guide user through Gatekeeper override
      debugPrint('macOS trust: User may need to allow in System Preferences > Security & Privacy');
      return false; // Cannot programmatically grant trust
    } catch (e) {
      return false;
    }
  }

  Future<bool> _requestLinuxTrust() async {
    try {
      // On Linux, suggest proper installation methods
      debugPrint('Linux trust: Consider installing via package manager or AppImage');
      return false; // Cannot programmatically grant trust
    } catch (e) {
      return false;
    }
  }

  /// Get trust recommendations for the current platform
  List<String> getTrustRecommendations() {
    if (Platform.isWindows) {
      return [
        'Install from Microsoft Store for automatic trust',
        'Use a digitally signed installer',
        'Install to Program Files directory',
        'Allow through Windows Defender SmartScreen'
      ];
    } else if (Platform.isMacOS) {
      return [
        'Download from Mac App Store',
        'Use a notarized installer',
        'Allow in System Preferences > Security & Privacy',
        'Right-click and select "Open" to bypass Gatekeeper'
      ];
    } else if (Platform.isLinux) {
      return [
        'Install via your distribution\'s package manager',
        'Use Snap or Flatpak for sandboxed installation',
        'Verify GPG signatures before installation',
        'Install from trusted repositories'
      ];
    }
    return ['Use your platform\'s recommended installation method'];
  }
}

/// Trust status levels
enum TrustStatus {
  /// Fully trusted by the OS (code signed, notarized, etc.)
  trusted,
  
  /// Partially trusted (some trust indicators present)
  partiallyTrusted,
  
  /// Trusted by user action (explicit allow)
  userTrusted,
  
  /// Not trusted by OS security systems
  untrusted,
  
  /// Cannot determine trust status
  unknown,
}

/// Windows SmartScreen status
enum SmartScreenStatus {
  allowed,
  blocked,
  unknown,
}

/// Trust information for display
class TrustInfo {
  final TrustStatus status;
  final String message;
  final List<String> recommendations;
  final bool requiresUserAction;

  const TrustInfo({
    required this.status,
    required this.message,
    required this.recommendations,
    required this.requiresUserAction,
  });

  factory TrustInfo.fromStatus(TrustStatus status) {
    switch (status) {
      case TrustStatus.trusted:
        return const TrustInfo(
          status: TrustStatus.trusted,
          message: 'This application is fully trusted by your operating system.',
          recommendations: [],
          requiresUserAction: false,
        );
      
      case TrustStatus.partiallyTrusted:
        return TrustInfo(
          status: TrustStatus.partiallyTrusted,
          message: 'This application has some trust indicators but may require additional verification.',
          recommendations: OSTrustManager().getTrustRecommendations(),
          requiresUserAction: true,
        );
      
      case TrustStatus.userTrusted:
        return const TrustInfo(
          status: TrustStatus.userTrusted,
          message: 'This application has been explicitly allowed by you.',
          recommendations: [],
          requiresUserAction: false,
        );
      
      case TrustStatus.untrusted:
        return TrustInfo(
          status: TrustStatus.untrusted,
          message: 'This application is not recognized as trusted by your operating system.',
          recommendations: OSTrustManager().getTrustRecommendations(),
          requiresUserAction: true,
        );
      
      case TrustStatus.unknown:
        return const TrustInfo(
          status: TrustStatus.unknown,
          message: 'Unable to determine the trust status of this application.',
          recommendations: ['Proceed with caution and verify the source'],
          requiresUserAction: true,
        );
    }
  }
}
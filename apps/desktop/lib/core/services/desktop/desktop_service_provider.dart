import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_system_service.dart';
import 'window_management_service.dart';
import 'desktop_storage_service.dart';

class DesktopServiceProvider {
  static DesktopServiceProvider? _instance;
  
  DesktopServiceProvider._();
  
  static DesktopServiceProvider get instance {
    _instance ??= DesktopServiceProvider._();
    return _instance!;
  }

  DesktopFileSystemService get fileSystem => DesktopFileSystemService.instance;
  DesktopWindowManagementService get windowManager => DesktopWindowManagementService.instance;
  DesktopStorageService get storage => DesktopStorageService.instance;

  bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  bool get isWindows => Platform.isWindows;
  bool get isMacOS => Platform.isMacOS;
  bool get isLinux => Platform.isLinux;

  Future<void> initialize() async {
    if (!isDesktop) {
      print('Desktop services not available on this platform');
      return;
    }

    try {
      await storage.initialize();
      print('✓ Storage service initialized');
    } catch (e) {
      print('✗ Storage service initialization failed: $e');
    }

    try {
      await windowManager.initialize();
      print('✓ Window management service initialized');
    } catch (e) {
      print('✗ Window management service initialization failed: $e');
    }

    print('✓ File system service ready');
    print('Desktop services initialized for ${getPlatformName()}');
  }

  String getPlatformName() {
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }

  Map<String, dynamic> getPlatformCapabilities() {
    return {
      'platform': getPlatformName(),
      'isDesktop': isDesktop,
      'fileSystem': {
        'nativeDialogs': isDesktop,
        'systemIntegration': isDesktop,
        'dragDrop': isDesktop,
      },
      'windowManagement': {
        'alwaysOnTop': isDesktop,
        'minimizeToTray': isWindows || isLinux,
        'transparency': isWindows || isLinux,
        'globalHotkeys': isDesktop,
        'systemTray': isWindows || isLinux,
      },
      'storage': {
        'preferences': isDesktop,
        'localDatabase': isDesktop,
        'fileSystem': isDesktop,
        'backup': isDesktop,
      },
    };
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    final Map<String, dynamic> info = {
      'platform': getPlatformName(),
      'isDesktop': isDesktop,
      'capabilities': getPlatformCapabilities(),
    };

    if (isDesktop) {
      try {
        final appDir = await fileSystem.getAgentEngineDirectory();
        info['paths'] = {
          'appData': appDir.path,
          'agents': (await fileSystem.getAgentsDirectory()).path,
          'templates': (await fileSystem.getTemplatesDirectory()).path,
          'logs': (await fileSystem.getLogsDirectory()).path,
          'mcpServers': (await fileSystem.getMCPServersDirectory()).path,
        };

        final storageSize = await storage.getStorageSize();
        final storageBreakdown = await storage.getStorageBreakdown();
        
        info['storage'] = {
          'totalSize': storageSize,
          'formattedSize': storage.formatStorageSize(storageSize),
          'breakdown': storageBreakdown,
          'isHealthy': await storage.isHealthy(),
        };

        if (windowManager.isDesktop) {
          final windowState = await windowManager.getWindowState();
          final windowSize = await windowManager.getSize();
          final windowPosition = await windowManager.getPosition();
          
          info['window'] = {
            'state': windowState.name,
            'size': {'width': windowSize.width, 'height': windowSize.height},
            'position': {'x': windowPosition.dx, 'y': windowPosition.dy},
            'isVisible': await windowManager.isVisible(),
            'isFocused': await windowManager.isFocused(),
            'isMaximized': await windowManager.isMaximized(),
            'isMinimized': await windowManager.isMinimized(),
          };
        }
      } catch (e) {
        info['error'] = 'Failed to gather system info: $e';
      }
    }

    return info;
  }

  Future<bool> isHealthy() async {
    if (!isDesktop) return true;

    try {
      final storageHealthy = await storage.isHealthy();
      return storageHealthy;
    } catch (e) {
      return false;
    }
  }

  Future<void> performMaintenance() async {
    if (!isDesktop) return;

    try {
      await storage.cleanupOldData();
      await storage.compactStorage();
      print('✓ Storage maintenance completed');
    } catch (e) {
      print('✗ Storage maintenance failed: $e');
    }

    if (windowManager.isDesktop) {
      try {
        await windowManager.saveWindowState();
        print('✓ Window state saved');
      } catch (e) {
        print('✗ Window state save failed: $e');
      }
    }
  }

  Future<void> createBackup([String? backupPath]) async {
    if (!isDesktop) return;
    
    await storage.backupData(backupPath);
  }

  Future<List<String>> getAvailableBackups() async {
    if (!isDesktop) return [];
    
    return await storage.getBackupFiles();
  }

  Future<void> restoreFromBackup(String backupPath) async {
    if (!isDesktop) return;
    
    await storage.restoreFromBackup(backupPath);
  }

  void dispose() {
    if (isDesktop) {
      storage.dispose();
    }
  }
}

final desktopServiceProvider = Provider<DesktopServiceProvider>((ref) {
  return DesktopServiceProvider.instance;
});

final fileSystemServiceProvider = Provider<DesktopFileSystemService>((ref) {
  return DesktopFileSystemService.instance;
});

final windowManagementServiceProvider = Provider<DesktopWindowManagementService>((ref) {
  return DesktopWindowManagementService.instance;
});

final desktopStorageServiceProvider = Provider<DesktopStorageService>((ref) {
  return DesktopStorageService.instance;
});

final systemInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final desktopService = ref.read(desktopServiceProvider);
  return await desktopService.getSystemInfo();
});

final platformCapabilitiesProvider = Provider<Map<String, dynamic>>((ref) {
  final desktopService = ref.read(desktopServiceProvider);
  return desktopService.getPlatformCapabilities();
});

final isDesktopProvider = Provider<bool>((ref) {
  final desktopService = ref.read(desktopServiceProvider);
  return desktopService.isDesktop;
});

final platformNameProvider = Provider<String>((ref) {
  final desktopService = ref.read(desktopServiceProvider);
  return desktopService.getPlatformName();
});
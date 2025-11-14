import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../di/service_locator.dart';
import './desktop/desktop_storage_service.dart';

/// Service for persisting canvas state and design data
/// Handles local storage, auto-save, and state recovery
class CanvasStorageService {
  static const String _canvasStateKey = 'canvas_state';
  static const String _autosavePrefix = 'canvas_autosave_';
  static const Duration _autosaveInterval = Duration(seconds: 30);
  
  Timer? _autosaveTimer;
  String? _currentCanvasId;
  Map<String, dynamic>? _currentState;
  
  late final DesktopStorageService _storage;
  late final Directory _canvasDirectory;

  /// Initialize the canvas storage service
  Future<void> initialize() async {
    _storage = ServiceLocator.instance.get<DesktopStorageService>();
    
    // Create canvas storage directory
    final appDir = await getApplicationDocumentsDirectory();
    _canvasDirectory = Directory(path.join(appDir.path, 'Asmbli', 'Canvas'));
    
    if (!await _canvasDirectory.exists()) {
      await _canvasDirectory.create(recursive: true);
      print('📁 Created canvas storage directory: ${_canvasDirectory.path}');
    }
    
    print('✅ Canvas Storage Service initialized');
  }

  /// Start auto-save for the current canvas
  void startAutoSave(String canvasId) {
    _currentCanvasId = canvasId;
    _stopAutoSave();
    
    _autosaveTimer = Timer.periodic(_autosaveInterval, (_) {
      if (_currentState != null && _currentCanvasId != null) {
        _autoSaveState(_currentCanvasId!, _currentState!);
      }
    });
    
    print('💾 Auto-save started for canvas: $canvasId');
  }

  /// Stop auto-save
  void stopAutoSave() {
    _stopAutoSave();
    _currentCanvasId = null;
    _currentState = null;
  }

  void _stopAutoSave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
  }

  /// Save canvas state
  Future<void> saveCanvasState(String canvasId, Map<String, dynamic> state) async {
    try {
      _currentState = state;
      
      // Save to primary storage
      await _storage.setPreference('${_canvasStateKey}_$canvasId', state);
      
      // Save to file system as backup
      final file = File(path.join(_canvasDirectory.path, '$canvasId.json'));
      await file.writeAsString(jsonEncode({
        'id': canvasId,
        'state': state,
        'savedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      }));
      
      print('💾 Canvas state saved: $canvasId');
      
    } catch (e) {
      print('❌ Failed to save canvas state: $e');
      rethrow;
    }
  }

  /// Load canvas state
  Future<Map<String, dynamic>?> loadCanvasState(String canvasId) async {
    try {
      // Try primary storage first
      final state = _storage.getPreference<Map<String, dynamic>>('${_canvasStateKey}_$canvasId');
      if (state != null) {
        _currentCanvasId = canvasId;
        _currentState = state;
        return state;
      }
      
      // Try file system backup
      final file = File(path.join(_canvasDirectory.path, '$canvasId.json'));
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final state = data['state'] as Map<String, dynamic>;
        
        _currentCanvasId = canvasId;
        _currentState = state;
        return state;
      }
      
      print('📭 No saved state found for canvas: $canvasId');
      return null;
      
    } catch (e) {
      print('❌ Failed to load canvas state: $e');
      return null;
    }
  }

  /// Auto-save current state
  Future<void> _autoSaveState(String canvasId, Map<String, dynamic> state) async {
    try {
      // Save autosave copy
      await _storage.setPreference('${_autosavePrefix}$canvasId', {
        'state': state,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (kDebugMode) {
        print('💾 Auto-saved canvas: $canvasId');
      }
      
    } catch (e) {
      print('❌ Auto-save failed: $e');
    }
  }

  /// Get auto-save data
  Future<Map<String, dynamic>?> getAutoSave(String canvasId) async {
    try {
      final autoSave = _storage.getPreference<Map<String, dynamic>>('${_autosavePrefix}$canvasId');
      return autoSave;
    } catch (e) {
      print('❌ Failed to get auto-save: $e');
      return null;
    }
  }

  /// Clear auto-save data
  Future<void> clearAutoSave(String canvasId) async {
    try {
      await _storage.removePreference('${_autosavePrefix}$canvasId');
      print('🗑️ Auto-save cleared for canvas: $canvasId');
    } catch (e) {
      print('❌ Failed to clear auto-save: $e');
    }
  }

  /// List all saved canvases
  Future<List<Map<String, dynamic>>> listSavedCanvases() async {
    try {
      final canvases = <Map<String, dynamic>>[];
      
      // Get from file system
      if (await _canvasDirectory.exists()) {
        await for (final entity in _canvasDirectory.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            try {
              final content = await entity.readAsString();
              final data = jsonDecode(content) as Map<String, dynamic>;
              
              canvases.add({
                'id': data['id'],
                'name': data['state']['name'] ?? 'Untitled Canvas',
                'savedAt': data['savedAt'],
                'version': data['version'],
                'filePath': entity.path,
              });
            } catch (e) {
              print('❌ Failed to read canvas file: ${entity.path}');
            }
          }
        }
      }
      
      // Sort by save date (newest first)
      canvases.sort((a, b) {
        final aDate = DateTime.parse(a['savedAt'] as String);
        final bDate = DateTime.parse(b['savedAt'] as String);
        return bDate.compareTo(aDate);
      });
      
      return canvases;
      
    } catch (e) {
      print('❌ Failed to list saved canvases: $e');
      return [];
    }
  }

  /// Delete saved canvas
  Future<void> deleteCanvas(String canvasId) async {
    try {
      // Remove from primary storage
      await _storage.removePreference('${_canvasStateKey}_$canvasId');
      
      // Remove autosave
      await clearAutoSave(canvasId);
      
      // Remove file
      final file = File(path.join(_canvasDirectory.path, '$canvasId.json'));
      if (await file.exists()) {
        await file.delete();
      }
      
      print('🗑️ Canvas deleted: $canvasId');
      
    } catch (e) {
      print('❌ Failed to delete canvas: $e');
      rethrow;
    }
  }

  /// Export canvas to file
  Future<String> exportCanvas(String canvasId, Map<String, dynamic> state) async {
    try {
      final exportData = {
        'id': canvasId,
        'state': state,
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'application': 'Asmbli Canvas',
      };
      
      // Create export file name with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'canvas_export_${canvasId}_$timestamp.asmbli';
      final exportPath = path.join(_canvasDirectory.path, 'exports', fileName);
      
      // Create exports directory if needed
      final exportsDir = Directory(path.dirname(exportPath));
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }
      
      // Write export file
      final file = File(exportPath);
      await file.writeAsString(jsonEncode(exportData));
      
      print('📤 Canvas exported to: $exportPath');
      return exportPath;
      
    } catch (e) {
      print('❌ Failed to export canvas: $e');
      rethrow;
    }
  }

  /// Import canvas from file
  Future<Map<String, dynamic>> importCanvas(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('Import file not found', filePath);
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      // Validate import data
      if (!data.containsKey('state') || !data.containsKey('id')) {
        throw FormatException('Invalid canvas export file format');
      }
      
      final canvasId = data['id'] as String;
      final state = data['state'] as Map<String, dynamic>;
      
      // Save imported canvas
      await saveCanvasState(canvasId, state);
      
      print('📥 Canvas imported: $canvasId from $filePath');
      return {'id': canvasId, 'state': state};
      
    } catch (e) {
      print('❌ Failed to import canvas: $e');
      rethrow;
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final stats = {
        'canvasCount': 0,
        'totalSize': 0,
        'directory': _canvasDirectory.path,
        'autosaveEnabled': _autosaveTimer?.isActive ?? false,
        'currentCanvas': _currentCanvasId,
      };
      
      if (await _canvasDirectory.exists()) {
        await for (final entity in _canvasDirectory.list(recursive: true)) {
          if (entity is File) {
            stats['canvasCount'] = (stats['canvasCount'] as int) + 1;
            final fileStat = await entity.stat();
            stats['totalSize'] = (stats['totalSize'] as int) + fileStat.size;
          }
        }
      }
      
      return stats;
      
    } catch (e) {
      print('❌ Failed to get storage stats: $e');
      return {};
    }
  }

  /// Update current state (for auto-save)
  void updateCurrentState(Map<String, dynamic> state) {
    _currentState = state;
  }

  /// Cleanup old auto-saves
  Future<void> cleanupOldAutoSaves() async {
    try {
      // Get all canvas-related keys from user_data box (where preferences are typically stored)
      final userDataKeys = _storage.getHiveKeys('user_data');
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      
      for (final key in userDataKeys) {
        if (key.startsWith(_autosavePrefix)) {
          final autoSave = _storage.getPreference<Map<String, dynamic>>(key);
          if (autoSave != null && autoSave['timestamp'] != null) {
            final timestamp = DateTime.parse(autoSave['timestamp'] as String);
            if (timestamp.isBefore(cutoff)) {
              await _storage.removePreference(key);
              print('🗑️ Cleaned up old auto-save: $key');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Failed to cleanup old auto-saves: $e');
    }
  }

  /// Save canvas agent activity for library
  Future<void> saveCanvasActivity(Map<String, dynamic> activity) async {
    try {
      const activitiesKey = 'canvas_agent_activities';
      final existingActivities = _storage.getPreference<List<dynamic>>(activitiesKey) ?? [];
      
      // Add new activity at the beginning (most recent first)
      existingActivities.insert(0, activity);
      
      // Keep only last 100 activities to prevent storage bloat
      if (existingActivities.length > 100) {
        existingActivities.removeRange(100, existingActivities.length);
      }
      
      await _storage.setPreference(activitiesKey, existingActivities);
      print('📚 Canvas activity saved: ${activity['description']}');
    } catch (e) {
      print('❌ Failed to save canvas activity: $e');
    }
  }
  
  /// Get recent canvas agent activities for library
  List<Map<String, dynamic>> getCanvasActivities() {
    try {
      const activitiesKey = 'canvas_agent_activities';
      final activities = _storage.getPreference<List<dynamic>>(activitiesKey) ?? [];
      return activities.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Failed to load canvas activities: $e');
      return [];
    }
  }
  
  /// Save canvas agent chat message
  Future<void> saveCanvasChat(Map<String, dynamic> message) async {
    try {
      const chatKey = 'canvas_agent_chat';
      final existingChat = _storage.getPreference<List<dynamic>>(chatKey) ?? [];
      
      // Add new message
      existingChat.add(message);
      
      // Keep only last 100 messages to prevent storage bloat
      if (existingChat.length > 100) {
        existingChat.removeRange(0, existingChat.length - 100);
      }
      
      await _storage.setPreference(chatKey, existingChat);
      print('💬 Canvas chat message saved');
    } catch (e) {
      print('❌ Failed to save canvas chat: $e');
    }
  }
  
  /// Get canvas agent chat history
  List<Map<String, dynamic>> getCanvasChat() {
    try {
      const chatKey = 'canvas_agent_chat';
      final chat = _storage.getPreference<List<dynamic>>(chatKey) ?? [];
      return chat.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Failed to load canvas chat: $e');
      return [];
    }
  }

  /// Dispose service
  void dispose() {
    stopAutoSave();
    print('🛑 Canvas Storage Service disposed');
  }
}
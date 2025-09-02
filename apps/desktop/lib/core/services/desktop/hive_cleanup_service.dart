import 'package:hive/hive.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'dart:convert';

/// Service to clean up corrupted Hive database entries
class HiveCleanupService {
  static const String _conversationsBoxName = 'conversations';
  
  /// Clean up corrupted conversations box
  static Future<bool> cleanupConversationsBox() async {
    try {
      print('🧹 Starting Hive conversations cleanup...');
      
      // Try to open the box
      final Box<dynamic> box;
      try {
        box = await Hive.openBox(_conversationsBoxName);
      } catch (e) {
        print('❌ Failed to open conversations box: $e');
        return false;
      }
      
      final keysToRemove = <String>[];
      final repairedConversations = <String, Map<String, dynamic>>{};
      int totalEntries = box.keys.length;
      int corruptedEntries = 0;
      int repairedEntries = 0;
      
      print('📊 Found $totalEntries entries in conversations box');
      
      // Check each entry
      for (final key in box.keys) {
        try {
          final value = box.get(key);
          
          if (value == null) {
            keysToRemove.add(key.toString());
            continue;
          }
          
          // Try to parse as Conversation
          Map<String, dynamic> conversationJson;
          
          if (value is Map<String, dynamic>) {
            conversationJson = value;
          } else if (value is Map<dynamic, dynamic>) {
            // Convert dynamic map to typed map
            conversationJson = _convertDynamicMap(value);
            repairedConversations[key.toString()] = conversationJson;
            repairedEntries++;
          } else if (value is String) {
            // Parse JSON string
            try {
              conversationJson = json.decode(value) as Map<String, dynamic>;
            } catch (e) {
              print('⚠️ Failed to parse JSON for key $key: $e');
              keysToRemove.add(key.toString());
              corruptedEntries++;
              continue;
            }
          } else {
            print('⚠️ Unknown data type for key $key: ${value.runtimeType}');
            keysToRemove.add(key.toString());
            corruptedEntries++;
            continue;
          }
          
          // Try to create Conversation object to validate structure
          try {
            Conversation.fromJson(conversationJson);
          } catch (e) {
            print('⚠️ Failed to validate conversation structure for key $key: $e');
            keysToRemove.add(key.toString());
            corruptedEntries++;
          }
          
        } catch (e) {
          print('⚠️ Error processing key $key: $e');
          keysToRemove.add(key.toString());
          corruptedEntries++;
        }
      }
      
      print('📈 Analysis complete:');
      print('  - Total entries: $totalEntries');
      print('  - Corrupted entries: $corruptedEntries');
      print('  - Repairable entries: $repairedEntries');
      print('  - Entries to remove: ${keysToRemove.length}');
      
      // Remove corrupted entries
      for (final key in keysToRemove) {
        try {
          await box.delete(key);
          print('🗑️ Removed corrupted entry: $key');
        } catch (e) {
          print('❌ Failed to remove key $key: $e');
        }
      }
      
      // Repair entries with type issues
      for (final entry in repairedConversations.entries) {
        try {
          await box.put(entry.key, entry.value);
          print('🔧 Repaired entry: ${entry.key}');
        } catch (e) {
          print('❌ Failed to repair key ${entry.key}: $e');
        }
      }
      
      // Compact the box
      await box.compact();
      
      print('✅ Hive cleanup complete!');
      print('   Removed $corruptedEntries corrupted entries');
      print('   Repaired $repairedEntries entries');
      
      return true;
      
    } catch (e) {
      print('❌ Hive cleanup failed: $e');
      return false;
    }
  }
  
  /// Convert Map<dynamic, dynamic> to Map<String, dynamic> recursively
  static Map<String, dynamic> _convertDynamicMap(Map<dynamic, dynamic> source) {
    final Map<String, dynamic> result = {};
    
    for (final entry in source.entries) {
      final String key = entry.key.toString();
      final dynamic value = entry.value;
      
      if (value is Map<dynamic, dynamic>) {
        result[key] = _convertDynamicMap(value);
      } else if (value is List<dynamic>) {
        result[key] = _convertDynamicList(value);
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }
  
  /// Convert List<dynamic> to proper types recursively
  static List<dynamic> _convertDynamicList(List<dynamic> source) {
    return source.map((item) {
      if (item is Map<dynamic, dynamic>) {
        return _convertDynamicMap(item);
      } else if (item is List<dynamic>) {
        return _convertDynamicList(item);
      } else {
        return item;
      }
    }).toList();
  }
  
  /// Reset conversations box completely (nuclear option)
  static Future<bool> resetConversationsBox() async {
    try {
      print('💥 Resetting conversations box (all data will be lost)...');
      
      await Hive.deleteBoxFromDisk(_conversationsBoxName);
      print('✅ Conversations box reset complete');
      
      return true;
    } catch (e) {
      print('❌ Failed to reset conversations box: $e');
      return false;
    }
  }
  
  /// Check conversations box health
  static Future<Map<String, dynamic>> checkBoxHealth() async {
    final Map<String, dynamic> health = {
      'totalEntries': 0,
      'corruptedEntries': 0,
      'validEntries': 0,
      'typeIssues': 0,
      'isHealthy': true,
    };
    
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      health['totalEntries'] = box.keys.length;
      
      for (final key in box.keys) {
        try {
          final value = box.get(key);
          
          if (value == null) {
            health['corruptedEntries'] = (health['corruptedEntries'] as int) + 1;
            continue;
          }
          
          Map<String, dynamic> conversationJson;
          
          if (value is Map<String, dynamic>) {
            conversationJson = value;
          } else if (value is Map<dynamic, dynamic>) {
            conversationJson = _convertDynamicMap(value);
            health['typeIssues'] = (health['typeIssues'] as int) + 1;
          } else {
            health['corruptedEntries'] = (health['corruptedEntries'] as int) + 1;
            continue;
          }
          
          // Validate structure
          Conversation.fromJson(conversationJson);
          health['validEntries'] = (health['validEntries'] as int) + 1;
          
        } catch (e) {
          health['corruptedEntries'] = (health['corruptedEntries'] as int) + 1;
        }
      }
      
      health['isHealthy'] = health['corruptedEntries'] == 0 && health['typeIssues'] == 0;
      
    } catch (e) {
      health['isHealthy'] = false;
      health['error'] = e.toString();
    }
    
    return health;
  }
}
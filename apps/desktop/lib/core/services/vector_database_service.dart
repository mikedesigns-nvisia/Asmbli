import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../vector/database/vector_database.dart';
import '../vector/models/vector_models.dart';
import '../di/service_locator.dart';
import 'storage_service.dart';

/// Production vector database service with proper lifecycle management
class VectorDatabaseService {
  VectorDatabase? _database;
  
  VectorDatabaseService(); // Remove singleton pattern to prevent memory leaks

  /// Initialize the vector database
  Future<VectorDatabase> initialize() async {
    if (_database != null) {
      return _database!;
    }

    try {
      // Get database path with fallbacks for OneDrive issues
      final databasePath = await _getDatabasePath();
      
      // Ensure database directory exists
      final dbDir = Directory(databasePath);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      _database = await VectorDatabaseFactory.create(
        databasePath: databasePath,
        chunkingConfig: const ChunkingConfig(
          chunkSize: 1024, // Larger chunks for better context
          chunkOverlap: 100,
          separators: ['\n\n', '\n', '. ', '! ', '? ', ' '],
          preserveCodeBlocks: true,
          preserveTables: true,
          minChunkSize: 100,
        ),
      );

      await _database!.initialize();
      
      print('🗄️ Vector database initialized at: $databasePath');
      return _database!;
      
    } catch (e) {
      print('❌ Failed to initialize vector database: $e');
      rethrow;
    }
  }

  /// Get the initialized database instance
  VectorDatabase get database {
    if (_database == null) {
      throw StateError('Vector database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Check if database is initialized
  bool get isInitialized => _database != null;

  /// Dispose the database
  Future<void> dispose() async {
    if (_database != null) {
      await _database!.dispose();
      _database = null;
    }
  }

  /// Get database statistics
  Future<VectorDatabaseStats> getStats() async {
    if (!isInitialized) {
      return VectorDatabaseStats(
        totalDocuments: 0,
        totalChunks: 0,
        totalEmbeddings: 0,
        lastUpdated: DateTime.now(),
        databaseVersion: '1.0.0',
      );
    }
    
    return await database.getStats();
  }

  /// Optimize database performance
  Future<void> optimize() async {
    if (isInitialized) {
      await database.optimize();
    }
  }

  /// Get database path with fallbacks for OneDrive/sync issues
  Future<String> _getDatabasePath() async {
    try {
      // First try: Application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final primaryPath = path.join(appDocDir.path, 'AgentEngine', 'vector_db');
      
      // Test if we can create the directory
      final testDir = Directory(primaryPath);
      await testDir.create(recursive: true);
      
      // If successful, use this path
      print('🗄️ Using primary path: $primaryPath');
      return primaryPath;
      
    } catch (primaryError) {
      print('⚠️ Primary path failed: $primaryError');
      
      try {
        // Second try: Application support directory
        final appSupportDir = await getApplicationSupportDirectory();
        final secondaryPath = path.join(appSupportDir.path, 'AgentEngine', 'vector_db');
        
        final testDir = Directory(secondaryPath);
        await testDir.create(recursive: true);
        
        print('🗄️ Using secondary path: $secondaryPath');
        return secondaryPath;
        
      } catch (secondaryError) {
        print('⚠️ Secondary path failed: $secondaryError');
        
        // Third try: Temporary directory (not ideal but works)
        final tempDir = await getTemporaryDirectory();
        final fallbackPath = path.join(tempDir.path, 'AgentEngine', 'vector_db');
        
        final testDir = Directory(fallbackPath);
        await testDir.create(recursive: true);
        
        print('🗄️ Using fallback path (temporary): $fallbackPath');
        return fallbackPath;
      }
    }
  }
}

/// Riverpod providers for vector database  
final vectorDatabaseServiceProvider = Provider<VectorDatabaseService>((ref) {
  final service = VectorDatabaseService();
  
  // Ensure proper disposal when provider is disposed
  ref.onDispose(() async {
    await service.dispose();
  });
  
  return service;
});

final vectorDatabaseProvider = FutureProvider<VectorDatabase>((ref) async {
  final service = ref.read(vectorDatabaseServiceProvider);
  return await service.initialize();
});

final vectorDatabaseStatsProvider = FutureProvider<VectorDatabaseStats>((ref) async {
  final service = ref.read(vectorDatabaseServiceProvider);
  return await service.getStats();
});
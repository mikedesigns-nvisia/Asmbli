import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vector_database_service.dart';
import 'context_vector_ingestion_service.dart';
import 'vector_context_retrieval_service.dart';
import '../di/service_locator.dart';
import '../../features/context/presentation/providers/context_provider.dart';

/// Generic ref interface
abstract class RefInterface {
  T read<T>(ProviderListenable<T> provider);
  void invalidate(ProviderBase provider);
}

/// Wrapper for different ref types
class RefWrapper implements RefInterface {
  final dynamic _ref;
  RefWrapper(this._ref);
  
  @override
  T read<T>(ProviderListenable<T> provider) => _ref.read(provider);
  
  @override
  void invalidate(ProviderBase provider) => _ref.invalidate(provider);
}

/// Production service that initializes and manages the complete vector integration system
class VectorIntegrationService {
  static VectorIntegrationService? _instance;
  
  VectorIntegrationService._internal();
  
  factory VectorIntegrationService() {
    _instance ??= VectorIntegrationService._internal();
    return _instance!;
  }

  bool _isInitialized = false;
  VectorDatabaseService? _databaseService;
  Timer? _syncTimer;
  
  /// Initialize the complete vector integration system  
  Future<void> initialize(RefInterface ref) async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing Vector Integration System...');
      
      // Step 1: Initialize vector database
      print('📝 Step 1/6: Creating vector database service...');
      _databaseService = ref.read(vectorDatabaseServiceProvider);
      
      print('📝 Step 2/6: Initializing vector database...');
      await _databaseService!.initialize();
      
      // Step 2: Wait for database to be available
      print('📝 Step 3/6: Waiting for database provider...');
      final vectorDB = await ref.read(vectorDatabaseProvider.future);
      
      // Step 3: Initialize ingestion service
      print('📝 Step 4/6: Initializing ingestion service...');
      final ingestionService = ref.read(contextVectorIngestionServiceProvider);
      
      // Step 4: Perform initial sync of all active context documents (with timeout)
      print('📝 Step 5/6: Performing initial context document sync...');
      if (ingestionService != null) {
        try {
          await ingestionService.ingestAllActiveDocuments().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏰ Initial document sync timed out after 30s - continuing without sync');
            },
          );
          print('✅ Initial document sync completed successfully');
        } catch (e) {
          print('⚠️ Initial document sync failed: $e - continuing anyway');
        }
      } else {
        print('⚠️ Ingestion service not available, skipping initial sync');
      }
      
      // Step 5: Initialize retrieval service (lazy initialization via provider)
      print('📝 Step 6/6: Initializing retrieval service...');
      final retrievalService = ref.read(vectorContextRetrievalServiceProvider);
      
      // Step 6: Setup periodic sync
      _setupPeriodicSync(ref);
      
      _isInitialized = true;
      print('✅ Vector Integration System initialized successfully');
      
      // Log initialization stats
      final stats = await _databaseService!.getStats();
      print('📊 Vector DB Stats: ${stats.totalDocuments} docs, ${stats.totalChunks} chunks');
      
    } catch (e) {
      print('❌ Vector Integration System initialization failed: $e');
      rethrow;
    }
  }

  /// Setup periodic synchronization of context documents
  void _setupPeriodicSync(RefInterface ref) {
    // Sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        await _performPeriodicSync(ref);
      } catch (e) {
        print('⚠️ Periodic sync failed: $e');
      }
    });
  }

  /// Perform periodic synchronization
  Future<void> _performPeriodicSync(RefInterface ref) async {
    try {
      print('🔄 Performing periodic vector sync...');
      
      final ingestionService = ref.read(contextVectorIngestionServiceProvider);
      if (ingestionService != null) {
        await ingestionService.syncAllDocuments();
      }
      
      // Optimize database performance
      if (_databaseService != null) {
        await _databaseService!.optimize();
      }
      
      print('✅ Periodic sync completed');
      
    } catch (e) {
      print('❌ Periodic sync failed: $e');
    }
  }

  /// Force full synchronization of all context documents
  Future<void> forceSyncAll(RefInterface ref) async {
    try {
      print('🔄 Forcing full vector sync...');
      
      final ingestionService = ref.read(contextVectorIngestionServiceProvider);
      if (ingestionService != null) {
        await ingestionService.syncAllDocuments();
      }
      
      // Invalidate providers to refresh UI
      ref.invalidate(contextDocumentsWithVectorProvider);
      ref.invalidate(contextIngestionStatusProvider);
      
      print('✅ Full sync completed');
      
    } catch (e) {
      print('❌ Full sync failed: $e');
      rethrow;
    }
  }

  /// Get comprehensive system status
  Future<Map<String, dynamic>> getSystemStatus(RefInterface ref) async {
    try {
      final status = <String, dynamic>{
        'initialized': _isInitialized,
        'sync_active': _syncTimer?.isActive ?? false,
      };
      
      if (_isInitialized && _databaseService != null) {
        // Vector database stats
        final dbStats = await _databaseService!.getStats();
        status['vector_database'] = dbStats.toJson();
        
        // Ingestion stats
        final ingestionService = ref.read(contextVectorIngestionServiceProvider);
        if (ingestionService != null) {
          final ingestionStats = await ingestionService.getIngestionStats();
          status['ingestion'] = ingestionStats;
        }
        
        // Retrieval stats
        final retrievalService = ref.read(vectorContextRetrievalServiceProvider);
        if (retrievalService != null) {
          final retrievalStats = await retrievalService.getContextStats();
          status['retrieval'] = retrievalStats;
        }
      }
      
      return status;
      
    } catch (e) {
      return {
        'error': e.toString(),
        'initialized': _isInitialized,
      };
    }
  }

  /// Check if system is healthy and ready
  Future<bool> isHealthy(RefInterface ref) async {
    try {
      if (!_isInitialized) return false;
      
      // Check database connectivity
      if (_databaseService == null || !_databaseService!.isInitialized) {
        return false;
      }
      
      // Check if we have context documents
      final stats = await _databaseService!.getStats();
      
      // System is healthy if database is accessible
      return stats.totalDocuments >= 0; // Even 0 is valid
      
    } catch (e) {
      print('⚠️ Health check failed: $e');
      return false;
    }
  }

  /// Restart the system (useful for recovery from errors)
  Future<void> restart(RefInterface ref) async {
    try {
      print('🔄 Restarting Vector Integration System...');
      
      await dispose();
      await initialize(ref);
      
      print('✅ System restarted successfully');
      
    } catch (e) {
      print('❌ System restart failed: $e');
      rethrow;
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    try {
      print('🧹 Disposing Vector Integration System...');
      
      _syncTimer?.cancel();
      _syncTimer = null;
      
      if (_databaseService != null) {
        await _databaseService!.dispose();
        _databaseService = null;
      }
      
      _isInitialized = false;
      
      print('✅ Vector Integration System disposed');
      
    } catch (e) {
      print('⚠️ Error during disposal: $e');
    }
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Get database service (throws if not initialized)
  VectorDatabaseService get databaseService {
    if (_databaseService == null) {
      throw StateError('Vector Integration System not initialized');
    }
    return _databaseService!;
  }
}

/// Riverpod provider for vector integration service
final vectorIntegrationServiceProvider = Provider<VectorIntegrationService>((ref) {
  return VectorIntegrationService();
});

/// Provider for system initialization
final vectorSystemInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.read(vectorIntegrationServiceProvider);
  await service.initialize(RefWrapper(ref));
});

/// Provider for system status
final vectorSystemStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(vectorIntegrationServiceProvider);
  return await service.getSystemStatus(RefWrapper(ref));
});

/// Provider for system health check
final vectorSystemHealthProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(vectorIntegrationServiceProvider);
  return await service.isHealthy(RefWrapper(ref));
});
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'streamlined_vector_context_service.dart';
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
/// Now uses StreamlinedVectorContextService instead of separate services
class VectorIntegrationService {
  static VectorIntegrationService? _instance;
  
  VectorIntegrationService._internal();
  
  factory VectorIntegrationService() {
    _instance ??= VectorIntegrationService._internal();
    return _instance!;
  }

  bool _isInitialized = false;
  StreamlinedVectorContextService? _streamlinedService;
  Timer? _syncTimer;
  
  /// Initialize the complete vector integration system using streamlined service
  Future<void> initialize(RefInterface ref) async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing Streamlined Vector Integration System...');
      
      // Step 1: Get streamlined service
      print('📝 Step 1/3: Getting streamlined vector context service...');
      _streamlinedService = ref.read(streamlinedVectorContextServiceProvider);
      
      print('📝 Step 2/3: Initializing streamlined service...');
      await _streamlinedService!.initialize();
      
      // Step 2: Perform initial sync of all active context documents (with timeout)
      print('📝 Step 3/3: Performing initial context document sync...');
      try {
        await _streamlinedService!.ingestAllActiveDocuments().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('⏰ Initial document sync timed out after 30s - continuing without sync');
          },
        );
        print('✅ Initial document sync completed successfully');
      } catch (e) {
        print('⚠️ Initial document sync failed: $e - continuing anyway');
      }
      
      // Setup periodic sync
      _setupPeriodicSync(ref);
      
      _isInitialized = true;
      print('✅ Streamlined Vector Integration System initialized successfully');
      
      // Log initialization stats
      final stats = await _streamlinedService!.getStats();
      print('📊 Vector Stats: ${stats['total_vector_documents']} docs, ${stats['total_chunks']} chunks');
      
    } catch (e) {
      print('❌ Streamlined Vector Integration System initialization failed: $e');
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

  /// Perform periodic synchronization using streamlined service
  Future<void> _performPeriodicSync(RefInterface ref) async {
    try {
      print('🔄 Performing periodic vector sync...');
      
      if (_streamlinedService != null) {
        await _streamlinedService!.syncAllDocuments();
        await _streamlinedService!.optimize();
      }
      
      print('✅ Periodic sync completed');
      
    } catch (e) {
      print('❌ Periodic sync failed: $e');
    }
  }

  /// Force full synchronization of all context documents using streamlined service
  Future<void> forceSyncAll(RefInterface ref) async {
    try {
      print('🔄 Forcing full vector sync...');
      
      if (_streamlinedService != null) {
        await _streamlinedService!.syncAllDocuments();
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

  /// Get comprehensive system status using streamlined service
  Future<Map<String, dynamic>> getSystemStatus(RefInterface ref) async {
    try {
      final status = <String, dynamic>{
        'initialized': _isInitialized,
        'sync_active': _syncTimer?.isActive ?? false,
      };
      
      if (_isInitialized && _streamlinedService != null) {
        // Get all stats from streamlined service
        final streamlinedStats = await _streamlinedService!.getStats();
        status.addAll(streamlinedStats);
      }
      
      return status;
      
    } catch (e) {
      return {
        'error': e.toString(),
        'initialized': _isInitialized,
      };
    }
  }

  /// Check if system is healthy and ready using streamlined service
  Future<bool> isHealthy(RefInterface ref) async {
    try {
      if (!_isInitialized) return false;
      
      // Check streamlined service availability
      if (_streamlinedService == null || !_streamlinedService!.isInitialized) {
        return false;
      }
      
      // Get stats to verify system is working
      final stats = await _streamlinedService!.getStats();
      
      // System is healthy if we can get stats without error
      return stats.containsKey('initialized') && stats['initialized'] == true;
      
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

  /// Dispose and cleanup streamlined service
  Future<void> dispose() async {
    try {
      print('🧹 Disposing Streamlined Vector Integration System...');
      
      _syncTimer?.cancel();
      _syncTimer = null;
      
      if (_streamlinedService != null) {
        await _streamlinedService!.dispose();
        _streamlinedService = null;
      }
      
      _isInitialized = false;
      
      print('✅ Streamlined Vector Integration System disposed');
      
    } catch (e) {
      print('⚠️ Error during disposal: $e');
    }
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;

  /// Get streamlined service (throws if not initialized)
  StreamlinedVectorContextService get streamlinedService {
    if (_streamlinedService == null) {
      throw StateError('Streamlined Vector Integration System not initialized');
    }
    return _streamlinedService!;
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
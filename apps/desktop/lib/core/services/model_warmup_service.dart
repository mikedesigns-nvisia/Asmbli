import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/model_config.dart';
import './llm/unified_llm_service.dart';
import './llm/llm_provider.dart';
import './model_config_service.dart';

/// Service responsible for warming up all configured models at app startup
/// This eliminates the "cold start" problem where first requests fail
class ModelWarmUpService {
  final UnifiedLLMService _llmService;
  final ModelConfigService _modelConfigService;
  
  final Map<String, ModelWarmUpStatus> _warmUpStatus = {};
  final StreamController<Map<String, ModelWarmUpStatus>> _statusController = 
      StreamController<Map<String, ModelWarmUpStatus>>.broadcast();

  ModelWarmUpService({
    required UnifiedLLMService llmService,
    required ModelConfigService modelConfigService,
  }) : _llmService = llmService,
       _modelConfigService = modelConfigService;

  /// Stream of warm-up status updates for all models
  Stream<Map<String, ModelWarmUpStatus>> get statusStream => _statusController.stream;

  /// Get current warm-up status for all models
  Map<String, ModelWarmUpStatus> get currentStatus => Map.from(_warmUpStatus);

  /// Get warm-up status for a specific model
  ModelWarmUpStatus? getModelStatus(String modelId) => _warmUpStatus[modelId];

  /// Check if a specific model is warmed up and ready
  bool isModelReady(String modelId) {
    final status = _warmUpStatus[modelId];
    return status?.isReady ?? false;
  }

  /// Warm up all configured models
  Future<void> warmUpAllModels() async {
    debugPrint('🔥 Starting model warm-up process...');
    
    final allModels = _modelConfigService.allModelConfigs.values
        .where((model) => model.isConfigured)
        .toList();
    
    if (allModels.isEmpty) {
      debugPrint('⚠️ No configured models found to warm up');
      return;
    }

    debugPrint('🔥 Found ${allModels.length} configured models to warm up');

    // Initialize status for all models
    for (final model in allModels) {
      _warmUpStatus[model.id] = ModelWarmUpStatus(
        modelId: model.id,
        modelName: model.name,
        isLocal: model.isLocal,
        status: WarmUpState.starting,
        startedAt: DateTime.now(),
      );
    }
    _notifyStatusUpdate();

    // Warm up models in parallel with some delay to avoid overwhelming system
    final futures = <Future>[];
    for (int i = 0; i < allModels.length; i++) {
      final model = allModels[i];
      futures.add(
        Future.delayed(
          Duration(milliseconds: i * 500), // Stagger requests by 500ms
          () => _warmUpSingleModel(model),
        ),
      );
    }

    await Future.wait(futures);
    
    final readyCount = _warmUpStatus.values.where((s) => s.isReady).length;
    final errorCount = _warmUpStatus.values.where((s) => s.hasError).length;
    
    debugPrint('🔥 Model warm-up complete: $readyCount ready, $errorCount errors');
  }

  /// Warm up a specific model
  Future<void> warmUpModel(String modelId) async {
    final model = _modelConfigService.getModelConfig(modelId);
    if (model == null || !model.isConfigured) {
      debugPrint('⚠️ Model $modelId not found or not configured');
      return;
    }

    await _warmUpSingleModel(model);
  }

  /// Mark a model as ready after successful response (reactive warm-up)
  void markModelAsReady(String modelId) {
    final currentStatus = _warmUpStatus[modelId];
    if (currentStatus == null) {
      // Model wasn't in warm-up status, create a new ready status
      final model = _modelConfigService.getModelConfig(modelId);
      if (model != null) {
        _warmUpStatus[modelId] = ModelWarmUpStatus(
          modelId: modelId,
          modelName: model.name,
          isLocal: model.isLocal,
          status: WarmUpState.ready,
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
          lastPingAt: DateTime.now(),
        );
      }
    } else if (!currentStatus.isReady) {
      // Update existing status to ready
      _warmUpStatus[modelId] = currentStatus.copyWith(
        status: WarmUpState.ready,
        completedAt: DateTime.now(),
        lastPingAt: DateTime.now(),
        error: null, // Clear any previous error
      );
    }
    
    _notifyStatusUpdate();
    debugPrint('✅ Model $modelId marked as ready after successful response');
  }

  /// Internal method to warm up a single model
  Future<void> _warmUpSingleModel(ModelConfig model) async {
    final startTime = DateTime.now();
    
    try {
      debugPrint('🔥 Warming up ${model.name} (${model.isLocal ? "local" : "API"})...');
      
      // Update status to warming
      _warmUpStatus[model.id] = _warmUpStatus[model.id]!.copyWith(
        status: WarmUpState.warming,
      );
      _notifyStatusUpdate();

      // Different warm-up strategies for local vs API models
      if (model.isLocal) {
        await _warmUpLocalModel(model);
      } else {
        await _warmUpAPIModel(model);
      }

      final duration = DateTime.now().difference(startTime);
      
      // Update status to ready
      _warmUpStatus[model.id] = _warmUpStatus[model.id]!.copyWith(
        status: WarmUpState.ready,
        completedAt: DateTime.now(),
        warmUpDuration: duration,
        lastPingAt: DateTime.now(),
      );
      
      debugPrint('✅ ${model.name} warmed up successfully in ${duration.inMilliseconds}ms');
      
    } catch (e) {
      debugPrint('❌ Failed to warm up ${model.name}: $e');
      
      // Update status to error
      _warmUpStatus[model.id] = _warmUpStatus[model.id]!.copyWith(
        status: WarmUpState.error,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
    }
    
    _notifyStatusUpdate();
  }

  /// Warm up local model (Ollama/etc)
  Future<void> _warmUpLocalModel(ModelConfig model) async {
    // For local models, send a minimal generation request to wake up the model
    const warmUpPrompt = 'Hi'; // Minimal prompt to activate model
    
    final response = await _llmService.chat(
      message: warmUpPrompt,
      modelId: model.id,
      context: ChatContext(
        messages: [],
        systemPrompt: 'You are a helpful assistant. Respond briefly.',
        metadata: {
          'isWarmUpRequest': true,
          'maxTokens': 5, // Minimal response to speed up warm-up
        },
      ),
    );

    // Verify we got a response
    if (response.content.isEmpty) {
      throw Exception('Local model warm-up failed: empty response');
    }
  }

  /// Warm up API model (Claude, GPT, etc)
  Future<void> _warmUpAPIModel(ModelConfig model) async {
    // For API models, send a minimal request to validate credentials and warm connections
    const warmUpPrompt = 'Hello'; // Minimal prompt
    
    final response = await _llmService.chat(
      message: warmUpPrompt,
      modelId: model.id,
      context: ChatContext(
        messages: [],
        systemPrompt: 'Respond with just "Ready" to confirm connection.',
        metadata: {
          'isWarmUpRequest': true,
          'maxTokens': 3, // Very minimal response
        },
      ),
    );

    // Verify we got a response and API key is working
    if (response.content.isEmpty) {
      throw Exception('API model warm-up failed: empty response');
    }
  }

  /// Keep models warm with periodic ping requests
  void startPeriodicWarmUp({Duration interval = const Duration(minutes: 10)}) {
    Timer.periodic(interval, (timer) async {
      final readyModels = _warmUpStatus.values
          .where((status) => status.isReady)
          .toList();

      for (final status in readyModels) {
        try {
          // Send minimal ping to keep model active
          await _pingModel(status.modelId);
          
          // Update last ping time
          _warmUpStatus[status.modelId] = status.copyWith(
            lastPingAt: DateTime.now(),
          );
          
        } catch (e) {
          debugPrint('⚠️ Ping failed for ${status.modelName}: $e');
          
          // Mark as needs re-warming
          _warmUpStatus[status.modelId] = status.copyWith(
            status: WarmUpState.needsWarmUp,
            error: 'Ping failed: $e',
          );
        }
      }
      
      _notifyStatusUpdate();
    });
  }

  /// Send minimal ping to keep model active
  Future<void> _pingModel(String modelId) async {
    final model = _modelConfigService.getModelConfig(modelId);
    if (model == null) return;

    // Very lightweight ping request
    await _llmService.chat(
      message: 'ping',
      modelId: modelId,
      context: ChatContext(
        messages: [],
        systemPrompt: 'Respond with just "pong".',
        metadata: {
          'isPingRequest': true,
          'maxTokens': 1,
        },
      ),
    );
  }

  void _notifyStatusUpdate() {
    _statusController.add(Map.from(_warmUpStatus));
  }

  void dispose() {
    _statusController.close();
  }
}

/// Status information for model warm-up
class ModelWarmUpStatus {
  final String modelId;
  final String modelName;
  final bool isLocal;
  final WarmUpState status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Duration? warmUpDuration;
  final DateTime? lastPingAt;
  final String? error;

  const ModelWarmUpStatus({
    required this.modelId,
    required this.modelName,
    required this.isLocal,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.warmUpDuration,
    this.lastPingAt,
    this.error,
  });

  bool get isReady => status == WarmUpState.ready;
  bool get isWarming => status == WarmUpState.warming;
  bool get hasError => status == WarmUpState.error;
  bool get needsWarmUp => status == WarmUpState.needsWarmUp;

  ModelWarmUpStatus copyWith({
    WarmUpState? status,
    DateTime? completedAt,
    Duration? warmUpDuration,
    DateTime? lastPingAt,
    String? error,
  }) {
    return ModelWarmUpStatus(
      modelId: modelId,
      modelName: modelName,
      isLocal: isLocal,
      status: status ?? this.status,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      warmUpDuration: warmUpDuration ?? this.warmUpDuration,
      lastPingAt: lastPingAt ?? this.lastPingAt,
      error: error ?? this.error,
    );
  }
}

enum WarmUpState {
  starting,      // Warm-up process initiated
  warming,       // Currently warming up
  ready,         // Model is warm and ready
  error,         // Warm-up failed
  needsWarmUp,   // Model was ready but needs re-warming
}

/// Provider for model warm-up service
final modelWarmUpServiceProvider = Provider<ModelWarmUpService>((ref) {
  final service = ModelWarmUpService(
    llmService: ref.read(unifiedLLMServiceProvider),
    modelConfigService: ref.read(modelConfigServiceProvider),
  );
  
  // Auto-dispose cleanup
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for warm-up status stream
final modelWarmUpStatusProvider = StreamProvider<Map<String, ModelWarmUpStatus>>((ref) {
  final service = ref.read(modelWarmUpServiceProvider);
  return service.statusStream;
});

/// Provider to check if a specific model is ready
final isModelReadyProvider = Provider.family<bool, String>((ref, modelId) {
  final statusAsync = ref.watch(modelWarmUpStatusProvider);
  
  return statusAsync.maybeWhen(
    data: (statusMap) => statusMap[modelId]?.isReady ?? false,
    orElse: () => false,
  );
});
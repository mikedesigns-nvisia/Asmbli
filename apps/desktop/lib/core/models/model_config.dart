import '../services/api_config_service.dart';

/// Type of model provider
enum ModelType { 
  /// Local model running via Ollama
  local, 
  /// API-based model (Claude, GPT, etc.)
  api 
}

/// Current status of a model
enum ModelStatus { 
  /// Model is ready to use
  ready, 
  /// Model is currently being downloaded
  downloading, 
  /// Model needs to be downloaded/configured
  needsSetup, 
  /// Model is currently loading into memory
  loading, 
  /// Model has an error
  error 
}

/// Extended model configuration that supports both local and API models
class ModelConfig extends ApiConfig {
  /// Type of model (local or API)
  final ModelType type;
  
  /// Current status of the model
  final ModelStatus status;
  
  /// Local file path for downloaded models
  final String? localPath;
  
  /// Model size in bytes for download estimation
  final int? modelSize;
  
  /// Model capabilities (reasoning, code, chat, etc.)
  final List<String> capabilities;
  
  /// Download URL for local models
  final String? downloadUrl;
  
  /// Download progress (0.0 - 1.0)
  final double? downloadProgress;
  
  /// Ollama model identifier (e.g., "qwen:32b-q4_k_m")
  final String? ollamaModelId;

  const ModelConfig({
    required super.id,
    required super.name,
    required super.provider,
    required super.model,
    required super.apiKey,
    required super.baseUrl,
    this.type = ModelType.api,
    this.status = ModelStatus.needsSetup,
    this.localPath,
    this.modelSize,
    this.capabilities = const [],
    this.downloadUrl,
    this.downloadProgress,
    this.ollamaModelId,
    super.isDefault,
    super.enabled,
    super.settings,
  });

  /// Create ModelConfig from existing ApiConfig (for migration)
  factory ModelConfig.fromApiConfig(ApiConfig apiConfig) {
    return ModelConfig(
      id: apiConfig.id,
      name: apiConfig.name,
      provider: apiConfig.provider,
      model: apiConfig.model,
      apiKey: apiConfig.apiKey,
      baseUrl: apiConfig.baseUrl,
      type: ModelType.api,
      status: apiConfig.isConfigured ? ModelStatus.ready : ModelStatus.needsSetup,
      isDefault: apiConfig.isDefault,
      enabled: apiConfig.enabled,
      settings: apiConfig.settings,
    );
  }

  /// Create a local model configuration
  factory ModelConfig.localModel({
    required String id,
    required String name,
    required String ollamaModelId,
    required ModelStatus status,
    String? localPath,
    int? modelSize,
    List<String> capabilities = const [],
    String? downloadUrl,
    double? downloadProgress,
    bool isDefault = false,
    bool enabled = true,
  }) {
    return ModelConfig(
      id: id,
      name: name,
      provider: 'Local',
      model: ollamaModelId,
      apiKey: '', // Local models don't need API keys
      baseUrl: 'http://127.0.0.1:11434', // Default Ollama endpoint
      type: ModelType.local,
      status: status,
      localPath: localPath,
      modelSize: modelSize,
      capabilities: capabilities,
      downloadUrl: downloadUrl,
      downloadProgress: downloadProgress,
      ollamaModelId: ollamaModelId,
      isDefault: isDefault,
      enabled: enabled,
    );
  }

  @override
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String,
      model: json['model'] as String,
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String,
      type: ModelType.values.firstWhere(
        (e) => e.name == (json['type'] as String?), 
        orElse: () => ModelType.api,
      ),
      status: ModelStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => ModelStatus.needsSetup,
      ),
      localPath: json['localPath'] as String?,
      modelSize: json['modelSize'] as int?,
      capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
      downloadUrl: json['downloadUrl'] as String?,
      downloadProgress: (json['downloadProgress'] as num?)?.toDouble(),
      ollamaModelId: json['ollamaModelId'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'type': type.name,
      'status': status.name,
      if (localPath != null) 'localPath': localPath,
      if (modelSize != null) 'modelSize': modelSize,
      'capabilities': capabilities,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (downloadProgress != null) 'downloadProgress': downloadProgress,
      if (ollamaModelId != null) 'ollamaModelId': ollamaModelId,
    });
    return json;
  }

  @override
  ModelConfig copyWith({
    String? id,
    String? name,
    String? provider,
    String? model,
    String? apiKey,
    String? baseUrl,
    ModelType? type,
    ModelStatus? status,
    String? localPath,
    int? modelSize,
    List<String>? capabilities,
    String? downloadUrl,
    double? downloadProgress,
    String? ollamaModelId,
    bool? isDefault,
    bool? enabled,
    Map<String, dynamic>? settings,
  }) {
    return ModelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      modelSize: modelSize ?? this.modelSize,
      capabilities: capabilities ?? this.capabilities,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      ollamaModelId: ollamaModelId ?? this.ollamaModelId,
      isDefault: isDefault ?? this.isDefault,
      enabled: enabled ?? this.enabled,
      settings: settings ?? this.settings,
    );
  }

  @override
  bool get isConfigured {
    switch (type) {
      case ModelType.local:
        return status == ModelStatus.ready;
      case ModelType.api:
        return apiKey.isNotEmpty;
    }
  }

  /// Whether this model is a local model
  bool get isLocal => type == ModelType.local;

  /// Whether this model is an API model
  bool get isApi => type == ModelType.api;

  /// Get display status for UI
  String get displayStatus {
    switch (status) {
      case ModelStatus.ready:
        return 'Ready';
      case ModelStatus.downloading:
        return 'Downloading...';
      case ModelStatus.needsSetup:
        return isApi ? 'Configure API Key' : 'Download Model';
      case ModelStatus.loading:
        return 'Loading...';
      case ModelStatus.error:
        return 'Error';
    }
  }

  /// Get formatted model size for display
  String get displaySize {
    if (modelSize == null) return 'Unknown size';
    
    final sizeInGB = modelSize! / (1024 * 1024 * 1024);
    if (sizeInGB >= 1) {
      return '${sizeInGB.toStringAsFixed(1)} GB';
    } else {
      final sizeInMB = modelSize! / (1024 * 1024);
      return '${sizeInMB.toStringAsFixed(0)} MB';
    }
  }
}
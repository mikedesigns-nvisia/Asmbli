import 'dart:convert';

enum ExtensionComplexity { low, medium, high }

enum ConnectionType { mcp, api, extension, webhook }

enum PricingTier { free, freemium, paid }

class Extension {
  final String id;
  final String name;
  final String description;
  final String category;
  final String provider;
  final String? icon;
  final ExtensionComplexity complexity;
  final bool enabled;
  final ConnectionType connectionType;
  final String authMethod;
  final PricingTier pricing;
  final List<String> features;
  final List<String> capabilities;
  final List<String> requirements;
  final String documentation;
  final int setupComplexity;
  final Map<String, dynamic> configuration;

  const Extension({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.provider,
    this.icon,
    required this.complexity,
    required this.enabled,
    required this.connectionType,
    required this.authMethod,
    required this.pricing,
    required this.features,
    required this.capabilities,
    required this.requirements,
    required this.documentation,
    required this.setupComplexity,
    required this.configuration,
  });

  Extension copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? provider,
    String? icon,
    ExtensionComplexity? complexity,
    bool? enabled,
    ConnectionType? connectionType,
    String? authMethod,
    PricingTier? pricing,
    List<String>? features,
    List<String>? capabilities,
    List<String>? requirements,
    String? documentation,
    int? setupComplexity,
    Map<String, dynamic>? configuration,
  }) {
    return Extension(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      provider: provider ?? this.provider,
      icon: icon ?? this.icon,
      complexity: complexity ?? this.complexity,
      enabled: enabled ?? this.enabled,
      connectionType: connectionType ?? this.connectionType,
      authMethod: authMethod ?? this.authMethod,
      pricing: pricing ?? this.pricing,
      features: features ?? this.features,
      capabilities: capabilities ?? this.capabilities,
      requirements: requirements ?? this.requirements,
      documentation: documentation ?? this.documentation,
      setupComplexity: setupComplexity ?? this.setupComplexity,
      configuration: configuration ?? this.configuration,
    );
  }

  factory Extension.fromJson(Map<String, dynamic> json) {
    return Extension(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      provider: json['provider'] as String,
      icon: json['icon'] as String?,
      complexity: _parseComplexity(json['complexity'] as String),
      enabled: json['enabled'] as bool,
      connectionType: _parseConnectionType(json['connectionType'] as String),
      authMethod: json['authMethod'] as String,
      pricing: _parsePricing(json['pricing'] as String),
      features: List<String>.from(json['features'] as List),
      capabilities: List<String>.from(json['capabilities'] as List),
      requirements: List<String>.from(json['requirements'] as List),
      documentation: json['documentation'] as String,
      setupComplexity: json['setupComplexity'] as int,
      configuration: Map<String, dynamic>.from(json['configuration'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'provider': provider,
      'icon': icon,
      'complexity': complexity.name,
      'enabled': enabled,
      'connectionType': connectionType.name,
      'authMethod': authMethod,
      'pricing': pricing.name,
      'features': features,
      'capabilities': capabilities,
      'requirements': requirements,
      'documentation': documentation,
      'setupComplexity': setupComplexity,
      'configuration': configuration,
    };
  }

  String toJsonString() => json.encode(toJson());

  static Extension fromJsonString(String jsonString) =>
      Extension.fromJson(json.decode(jsonString));

  static ExtensionComplexity _parseComplexity(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'low':
        return ExtensionComplexity.low;
      case 'medium':
        return ExtensionComplexity.medium;
      case 'high':
        return ExtensionComplexity.high;
      default:
        return ExtensionComplexity.low;
    }
  }

  static ConnectionType _parseConnectionType(String connectionType) {
    switch (connectionType.toLowerCase()) {
      case 'mcp':
        return ConnectionType.mcp;
      case 'api':
        return ConnectionType.api;
      case 'extension':
        return ConnectionType.extension;
      case 'webhook':
        return ConnectionType.webhook;
      default:
        return ConnectionType.mcp;
    }
  }

  static PricingTier _parsePricing(String pricing) {
    switch (pricing.toLowerCase()) {
      case 'free':
        return PricingTier.free;
      case 'freemium':
        return PricingTier.freemium;
      case 'paid':
        return PricingTier.paid;
      default:
        return PricingTier.free;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Extension && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Extension(id: $id, name: $name, enabled: $enabled)';
}

// Extension categories helper
class ExtensionCategories {
  static const String developmentCode = 'Development & Code';
  static const String aiMachineLearning = 'AI & Machine Learning';
  static const String webBrowser = 'Web & Browser';
  static const String database = 'Database';
  static const String businessTools = 'Business Tools';
  static const String socialMedia = 'Social Media';
  static const String productivity = 'Productivity';
  static const String design = 'Design';
  static const String security = 'Security';
  static const String analytics = 'Analytics';

  static List<String> get all => [
        developmentCode,
        aiMachineLearning,
        webBrowser,
        database,
        businessTools,
        socialMedia,
        productivity,
        design,
        security,
        analytics,
      ];

  static String getIconForCategory(String category) {
    switch (category) {
      case developmentCode:
        return 'Code';
      case aiMachineLearning:
        return 'Brain';
      case webBrowser:
        return 'Globe';
      case database:
        return 'Database';
      case businessTools:
        return 'Briefcase';
      case socialMedia:
        return 'MessageSquare';
      case productivity:
        return 'CheckSquare';
      case design:
        return 'Palette';
      case security:
        return 'Shield';
      case analytics:
        return 'BarChart';
      default:
        return 'Package';
    }
  }
}
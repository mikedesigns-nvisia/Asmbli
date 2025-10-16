import 'package:json_annotation/json_annotation.dart';
import 'reasoning_workflow.dart';

part 'marketplace_workflow.g.dart';

/// Categories for marketplace workflows
enum WorkflowMarketplaceCategory {
  general,
  research,
  creative,
  development,
  dataScience,
  business,
  marketing,
  education,
  healthcare,
  finance;

  String get displayName {
    switch (this) {
      case WorkflowMarketplaceCategory.general:
        return 'General';
      case WorkflowMarketplaceCategory.research:
        return 'Research & Analysis';
      case WorkflowMarketplaceCategory.creative:
        return 'Creative & Design';
      case WorkflowMarketplaceCategory.development:
        return 'Development';
      case WorkflowMarketplaceCategory.dataScience:
        return 'Data Science';
      case WorkflowMarketplaceCategory.business:
        return 'Business';
      case WorkflowMarketplaceCategory.marketing:
        return 'Marketing';
      case WorkflowMarketplaceCategory.education:
        return 'Education';
      case WorkflowMarketplaceCategory.healthcare:
        return 'Healthcare';
      case WorkflowMarketplaceCategory.finance:
        return 'Finance';
    }
  }

  String get iconName {
    switch (this) {
      case WorkflowMarketplaceCategory.general:
        return 'apps';
      case WorkflowMarketplaceCategory.research:
        return 'search';
      case WorkflowMarketplaceCategory.creative:
        return 'palette';
      case WorkflowMarketplaceCategory.development:
        return 'code';
      case WorkflowMarketplaceCategory.dataScience:
        return 'analytics';
      case WorkflowMarketplaceCategory.business:
        return 'business';
      case WorkflowMarketplaceCategory.marketing:
        return 'campaign';
      case WorkflowMarketplaceCategory.education:
        return 'school';
      case WorkflowMarketplaceCategory.healthcare:
        return 'local_hospital';
      case WorkflowMarketplaceCategory.finance:
        return 'account_balance';
    }
  }
}

/// Workflow from the marketplace with metadata and community features
@JsonSerializable()
class MarketplaceWorkflow {
  final String id;
  final String name;
  final String description;
  final String author;
  final String? authorAvatar;
  final List<String> tags;
  final WorkflowMarketplaceCategory category;
  final double rating;
  final int ratingCount;
  final int downloadCount;
  final bool isPublic;
  final ReasoningWorkflow workflow;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketplaceWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    this.authorAvatar,
    required this.tags,
    required this.category,
    required this.rating,
    required this.ratingCount,
    required this.downloadCount,
    required this.isPublic,
    required this.workflow,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceWorkflow.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceWorkflowFromJson(json);

  Map<String, dynamic> toJson() => _$MarketplaceWorkflowToJson(this);

  MarketplaceWorkflow copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    String? authorAvatar,
    List<String>? tags,
    WorkflowMarketplaceCategory? category,
    double? rating,
    int? ratingCount,
    int? downloadCount,
    bool? isPublic,
    ReasoningWorkflow? workflow,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceWorkflow(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      downloadCount: downloadCount ?? this.downloadCount,
      isPublic: isPublic ?? this.isPublic,
      workflow: workflow ?? this.workflow,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted rating display
  String get ratingDisplay => '${rating.toStringAsFixed(1)} ($ratingCount)';

  /// Get formatted download count
  String get downloadCountDisplay {
    if (downloadCount >= 1000000) {
      return '${(downloadCount / 1000000).toStringAsFixed(1)}M';
    } else if (downloadCount >= 1000) {
      return '${(downloadCount / 1000).toStringAsFixed(1)}K';
    } else {
      return downloadCount.toString();
    }
  }

  /// Check if workflow is highly rated
  bool get isHighlyRated => rating >= 4.5 && ratingCount >= 10;

  /// Check if workflow is popular
  bool get isPopular => downloadCount >= 1000;

  /// Check if workflow is trending (recent and popular)
  bool get isTrending {
    final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreated <= 30 && downloadCount >= 100;
  }
}

/// User review for a marketplace workflow
@JsonSerializable()
class WorkflowReview {
  final String id;
  final String workflowId;
  final String userId;
  final String username;
  final String? userAvatar;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final int helpfulCount;

  const WorkflowReview({
    required this.id,
    required this.workflowId,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.helpfulCount,
  });

  factory WorkflowReview.fromJson(Map<String, dynamic> json) =>
      _$WorkflowReviewFromJson(json);

  Map<String, dynamic> toJson() => _$WorkflowReviewToJson(this);
}

/// Statistics for marketplace workflows
@JsonSerializable()
class MarketplaceStats {
  final int totalWorkflows;
  final int totalDownloads;
  final int totalUsers;
  final Map<String, int> categoryBreakdown;
  final List<MarketplaceWorkflow> trending;
  final List<MarketplaceWorkflow> mostDownloaded;
  final List<MarketplaceWorkflow> highestRated;

  const MarketplaceStats({
    required this.totalWorkflows,
    required this.totalDownloads,
    required this.totalUsers,
    required this.categoryBreakdown,
    required this.trending,
    required this.mostDownloaded,
    required this.highestRated,
  });

  factory MarketplaceStats.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceStatsFromJson(json);

  Map<String, dynamic> toJson() => _$MarketplaceStatsToJson(this);
}
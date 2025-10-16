// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_workflow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarketplaceWorkflow _$MarketplaceWorkflowFromJson(Map<String, dynamic> json) =>
    MarketplaceWorkflow(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      category:
          $enumDecode(_$WorkflowMarketplaceCategoryEnumMap, json['category']),
      rating: (json['rating'] as num).toDouble(),
      ratingCount: (json['ratingCount'] as num).toInt(),
      downloadCount: (json['downloadCount'] as num).toInt(),
      isPublic: json['isPublic'] as bool,
      workflow:
          ReasoningWorkflow.fromJson(json['workflow'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MarketplaceWorkflowToJson(
        MarketplaceWorkflow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'author': instance.author,
      'authorAvatar': instance.authorAvatar,
      'tags': instance.tags,
      'category': _$WorkflowMarketplaceCategoryEnumMap[instance.category]!,
      'rating': instance.rating,
      'ratingCount': instance.ratingCount,
      'downloadCount': instance.downloadCount,
      'isPublic': instance.isPublic,
      'workflow': instance.workflow,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$WorkflowMarketplaceCategoryEnumMap = {
  WorkflowMarketplaceCategory.general: 'general',
  WorkflowMarketplaceCategory.research: 'research',
  WorkflowMarketplaceCategory.creative: 'creative',
  WorkflowMarketplaceCategory.development: 'development',
  WorkflowMarketplaceCategory.dataScience: 'dataScience',
  WorkflowMarketplaceCategory.business: 'business',
  WorkflowMarketplaceCategory.marketing: 'marketing',
  WorkflowMarketplaceCategory.education: 'education',
  WorkflowMarketplaceCategory.healthcare: 'healthcare',
  WorkflowMarketplaceCategory.finance: 'finance',
};

WorkflowReview _$WorkflowReviewFromJson(Map<String, dynamic> json) =>
    WorkflowReview(
      id: json['id'] as String,
      workflowId: json['workflowId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userAvatar: json['userAvatar'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      helpfulCount: (json['helpfulCount'] as num).toInt(),
    );

Map<String, dynamic> _$WorkflowReviewToJson(WorkflowReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workflowId': instance.workflowId,
      'userId': instance.userId,
      'username': instance.username,
      'userAvatar': instance.userAvatar,
      'rating': instance.rating,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
      'helpfulCount': instance.helpfulCount,
    };

MarketplaceStats _$MarketplaceStatsFromJson(Map<String, dynamic> json) =>
    MarketplaceStats(
      totalWorkflows: (json['totalWorkflows'] as num).toInt(),
      totalDownloads: (json['totalDownloads'] as num).toInt(),
      totalUsers: (json['totalUsers'] as num).toInt(),
      categoryBreakdown:
          Map<String, int>.from(json['categoryBreakdown'] as Map),
      trending: (json['trending'] as List<dynamic>)
          .map((e) => MarketplaceWorkflow.fromJson(e as Map<String, dynamic>))
          .toList(),
      mostDownloaded: (json['mostDownloaded'] as List<dynamic>)
          .map((e) => MarketplaceWorkflow.fromJson(e as Map<String, dynamic>))
          .toList(),
      highestRated: (json['highestRated'] as List<dynamic>)
          .map((e) => MarketplaceWorkflow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MarketplaceStatsToJson(MarketplaceStats instance) =>
    <String, dynamic>{
      'totalWorkflows': instance.totalWorkflows,
      'totalDownloads': instance.totalDownloads,
      'totalUsers': instance.totalUsers,
      'categoryBreakdown': instance.categoryBreakdown,
      'trending': instance.trending,
      'mostDownloaded': instance.mostDownloaded,
      'highestRated': instance.highestRated,
    };

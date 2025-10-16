import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

import '../models/reasoning_workflow.dart';
import '../models/marketplace_workflow.dart';
import 'workflow_persistence_service.dart';

/// Service for integrating with workflow marketplace and community sharing
class WorkflowMarketplaceService {
  static WorkflowMarketplaceService? _instance;
  late final Dio _dio;
  late final WorkflowPersistenceService _persistenceService;
  
  WorkflowMarketplaceService._() {
    _dio = Dio();
    _persistenceService = WorkflowPersistenceService.instance;
  }
  
  static WorkflowMarketplaceService get instance {
    _instance ??= WorkflowMarketplaceService._();
    return _instance!;
  }

  /// Get featured workflows from marketplace
  Future<List<MarketplaceWorkflow>> getFeaturedWorkflows() async {
    try {
      // For now, return mock data. In production, this would call a real API
      return _getMockFeaturedWorkflows();
      
      // Future implementation:
      // final response = await _dio.get('${Config.marketplaceUrl}/featured');
      // final data = response.data as List;
      // return data.map((json) => MarketplaceWorkflow.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching featured workflows: $e');
      return _getMockFeaturedWorkflows();
    }
  }

  /// Search workflows in marketplace
  Future<List<MarketplaceWorkflow>> searchWorkflows({
    String? query,
    List<String>? tags,
    String? category,
    String? sortBy = 'popularity',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // For now, filter mock data. In production, this would be a proper API call
      final allWorkflows = _getMockMarketplaceWorkflows();
      
      var filtered = allWorkflows.where((workflow) {
        bool matchesQuery = query == null || 
            workflow.name.toLowerCase().contains(query.toLowerCase()) ||
            workflow.description.toLowerCase().contains(query.toLowerCase());
            
        bool matchesTags = tags == null || tags.isEmpty ||
            tags.any((tag) => workflow.tags.contains(tag));
            
        bool matchesCategory = category == null ||
            workflow.category.name == category;
            
        return matchesQuery && matchesTags && matchesCategory;
      }).toList();
      
      // Apply sorting
      switch (sortBy) {
        case 'popularity':
          filtered.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
          break;
        case 'rating':
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'recent':
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'name':
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
      
      // Apply pagination
      final start = offset;
      final end = (start + limit).clamp(0, filtered.length);
      
      return filtered.sublist(start, end);
    } catch (e) {
      print('Error searching workflows: $e');
      return [];
    }
  }

  /// Import workflow from marketplace
  Future<ReasoningWorkflow> importWorkflow(String marketplaceId) async {
    try {
      // In production, this would fetch the full workflow data from API
      final marketplaceWorkflow = _getMockMarketplaceWorkflows()
          .firstWhere((w) => w.id == marketplaceId);
      
      // Convert marketplace workflow to local workflow
      final localWorkflow = marketplaceWorkflow.workflow.copyWith(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
        name: '${marketplaceWorkflow.name} (Imported)',
        isTemplate: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to local database
      await _persistenceService.saveWorkflow(localWorkflow);
      
      return localWorkflow;
    } catch (e) {
      throw Exception('Failed to import workflow: $e');
    }
  }

  /// Submit rating for a workflow
  Future<void> rateWorkflow(String marketplaceId, double rating, String? review) async {
    try {
      // In production, this would submit to API
      print('Rating workflow $marketplaceId: $rating/5.0');
      if (review != null) {
        print('Review: $review');
      }
      
      // Future implementation:
      // await _dio.post('${Config.marketplaceUrl}/workflows/$marketplaceId/rate', data: {
      //   'rating': rating,
      //   'review': review,
      // });
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  /// Upload workflow to marketplace
  Future<String> shareWorkflow(ReasoningWorkflow workflow, {
    String? description,
    List<String>? tags,
    String? category,
    bool isPublic = true,
  }) async {
    try {
      // In production, this would upload to API
      final marketplaceWorkflow = MarketplaceWorkflow(
        id: 'shared_${workflow.id}',
        name: workflow.name,
        description: description ?? workflow.description ?? '',
        author: 'Current User', // Would be actual user info
        authorAvatar: null,
        tags: tags ?? workflow.tags,
        category: WorkflowMarketplaceCategory.values.firstWhere(
          (c) => c.name == category,
          orElse: () => WorkflowMarketplaceCategory.general,
        ),
        rating: 0.0,
        ratingCount: 0,
        downloadCount: 0,
        isPublic: isPublic,
        workflow: workflow,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('Sharing workflow: ${marketplaceWorkflow.name}');
      
      // Future implementation:
      // final response = await _dio.post('${Config.marketplaceUrl}/workflows', data: {
      //   'workflow': marketplaceWorkflow.toJson(),
      // });
      // return response.data['id'];
      
      return marketplaceWorkflow.id;
    } catch (e) {
      throw Exception('Failed to share workflow: $e');
    }
  }

  /// Get workflow statistics
  Future<Map<String, dynamic>> getWorkflowStats(String marketplaceId) async {
    try {
      // Mock statistics
      return {
        'views': 1250,
        'downloads': 89,
        'likes': 34,
        'forks': 12,
        'rating': 4.2,
        'ratingCount': 15,
      };
    } catch (e) {
      return {};
    }
  }

  /// Get mock featured workflows
  List<MarketplaceWorkflow> _getMockFeaturedWorkflows() {
    return [
      MarketplaceWorkflow(
        id: 'featured_1',
        name: 'Advanced Research Assistant',
        description: 'Comprehensive research workflow with source validation, fact-checking, and citation generation',
        author: 'ResearchBot Pro',
        authorAvatar: null,
        tags: ['research', 'academic', 'citations', 'fact-checking'],
        category: WorkflowMarketplaceCategory.research,
        rating: 4.8,
        ratingCount: 127,
        downloadCount: 2341,
        isPublic: true,
        workflow: _createMockWorkflow('Advanced Research Assistant'),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      MarketplaceWorkflow(
        id: 'featured_2',
        name: 'Creative Problem Solver',
        description: 'Multi-perspective creative problem solving with brainstorming, evaluation, and refinement',
        author: 'Innovation Labs',
        authorAvatar: null,
        tags: ['creative', 'brainstorming', 'innovation', 'design-thinking'],
        category: WorkflowMarketplaceCategory.creative,
        rating: 4.6,
        ratingCount: 89,
        downloadCount: 1567,
        isPublic: true,
        workflow: _createMockWorkflow('Creative Problem Solver'),
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MarketplaceWorkflow(
        id: 'featured_3',
        name: 'Code Review Assistant',
        description: 'Automated code analysis with security checks, performance optimization, and best practice recommendations',
        author: 'DevOps Masters',
        authorAvatar: null,
        tags: ['code-review', 'security', 'performance', 'development'],
        category: WorkflowMarketplaceCategory.development,
        rating: 4.9,
        ratingCount: 203,
        downloadCount: 3420,
        isPublic: true,
        workflow: _createMockWorkflow('Code Review Assistant'),
        createdAt: DateTime.now().subtract(const Duration(days: 22)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Get all mock marketplace workflows
  List<MarketplaceWorkflow> _getMockMarketplaceWorkflows() {
    return [
      ..._getMockFeaturedWorkflows(),
      MarketplaceWorkflow(
        id: 'marketplace_1',
        name: 'Data Analysis Pipeline',
        description: 'Statistical analysis workflow with data validation, cleaning, and visualization',
        author: 'DataScience Hub',
        authorAvatar: null,
        tags: ['data-science', 'statistics', 'visualization', 'analysis'],
        category: WorkflowMarketplaceCategory.dataScience,
        rating: 4.3,
        ratingCount: 67,
        downloadCount: 891,
        isPublic: true,
        workflow: _createMockWorkflow('Data Analysis Pipeline'),
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      MarketplaceWorkflow(
        id: 'marketplace_2',
        name: 'Customer Support Agent',
        description: 'Intelligent customer service workflow with sentiment analysis and escalation management',
        author: 'ServiceBot Inc',
        authorAvatar: null,
        tags: ['customer-service', 'sentiment', 'support', 'escalation'],
        category: WorkflowMarketplaceCategory.business,
        rating: 4.1,
        ratingCount: 45,
        downloadCount: 567,
        isPublic: true,
        workflow: _createMockWorkflow('Customer Support Agent'),
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MarketplaceWorkflow(
        id: 'marketplace_3',
        name: 'Content Generation Engine',
        description: 'Multi-format content creation with SEO optimization and brand voice consistency',
        author: 'ContentCraft AI',
        authorAvatar: null,
        tags: ['content', 'seo', 'marketing', 'writing'],
        category: WorkflowMarketplaceCategory.marketing,
        rating: 4.5,
        ratingCount: 112,
        downloadCount: 1834,
        isPublic: true,
        workflow: _createMockWorkflow('Content Generation Engine'),
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }

  /// Create a mock workflow for marketplace items
  ReasoningWorkflow _createMockWorkflow(String name) {
    return ReasoningWorkflow.empty().copyWith(
      name: name,
      description: 'A professionally crafted workflow template',
      isTemplate: true,
      tags: ['marketplace', 'template'],
    );
  }
}
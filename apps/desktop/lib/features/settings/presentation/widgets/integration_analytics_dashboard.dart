import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/integration_analytics_service.dart';
import 'package:agent_engine_core/agent_engine_core.dart';

class IntegrationAnalyticsDashboard extends ConsumerWidget {
  const IntegrationAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsService = ref.watch(integrationAnalyticsServiceProvider);
    final statistics = analyticsService.getStatistics();
    final insights = analyticsService.getPerformanceInsights();
    final recommendations = analyticsService.getUsageBasedRecommendations();
    final usageData = analyticsService.getAllUsageData();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: SpacingTokens.xxl),
          
          // Statistics Overview
          _buildStatisticsOverview(statistics),
          SizedBox(height: SpacingTokens.xxl),
          
          // Charts and Insights Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Usage Chart and Top Integrations
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildUsageChart(usageData),
                    SizedBox(height: SpacingTokens.lg),
                    _buildTopIntegrations(usageData),
                  ],
                ),
              ),
              SizedBox(width: SpacingTokens.lg),
              
              // Performance Insights
              Expanded(
                child: _buildPerformanceInsights(insights),
              ),
            ],
          ),
          
          SizedBox(height: SpacingTokens.xxl),
          
          // Usage-based Recommendations
          if (recommendations.isNotEmpty) ...[
            _buildUsageRecommendations(recommendations),
            SizedBox(height: SpacingTokens.xxl),
          ],
          
          // Detailed Usage Table
          _buildDetailedUsageTable(usageData),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Integration Analytics',
          style: TextStyles.pageTitle,
        ),
        SizedBox(height: SpacingTokens.xs),
        Text(
          'Monitor integration performance, usage patterns, and optimization opportunities',
          style: TextStyles.bodyMedium.copyWith(
            color: SemanticColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsOverview(IntegrationStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Integrations',
            stats.totalIntegrations.toString(),
            Icons.integration_instructions,
            SemanticColors.primary,
          ),
        ),
        SizedBox(width: SpacingTokens.lg),
        Expanded(
          child: _buildStatCard(
            'Active This Week',
            stats.activeIntegrations.toString(),
            Icons.timeline,
            SemanticColors.success,
          ),
        ),
        SizedBox(width: SpacingTokens.lg),
        Expanded(
          child: _buildStatCard(
            'Total Invocations',
            _formatNumber(stats.totalInvocations),
            Icons.play_arrow,
            SemanticColors.warning,
          ),
        ),
        SizedBox(width: SpacingTokens.lg),
        Expanded(
          child: _buildStatCard(
            'Success Rate',
            '${(stats.overallSuccessRate * 100).toStringAsFixed(1)}%',
            Icons.check_circle,
            SemanticColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AsmblCard(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              Spacer(),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            value,
            style: TextStyles.cardTitle.copyWith(color: color),
          ),
          SizedBox(height: SpacingTokens.xs),
          Text(
            title,
            style: TextStyles.bodySmall.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageChart(Map<String, IntegrationUsageData> usageData) {
    if (usageData.isEmpty) {
      return AsmblCard(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: _buildEmptyState('No usage data available'),
      );
    }

    // Sort by usage and take top 10
    final sortedEntries = usageData.entries.toList()
      ..sort((a, b) => b.value.totalInvocations.compareTo(a.value.totalInvocations));
    final topEntries = sortedEntries.take(10).toList();
    final maxUsage = topEntries.isNotEmpty ? topEntries.first.value.totalInvocations : 1;

    return AsmblCard(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: SemanticColors.primary, size: 16),
              SizedBox(width: SpacingTokens.xs),
              Text(
                'Integration Usage',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.lg),
          
          ...topEntries.map((entry) {
            final integration = IntegrationRegistry.getById(entry.key);
            final percentage = entry.value.totalInvocations / maxUsage;
            
            return Padding(
              padding: EdgeInsets.only(bottom: SpacingTokens.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        integration?.name ?? entry.key,
                        style: TextStyles.bodyMedium,
                      ),
                      Text(
                        '${entry.value.totalInvocations}',
                        style: TextStyles.bodySmall.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SpacingTokens.xs),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: SemanticColors.border,
                    valueColor: AlwaysStoppedAnimation(SemanticColors.primary),
                    minHeight: 6,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopIntegrations(Map<String, IntegrationUsageData> usageData) {
    if (usageData.isEmpty) {
      return AsmblCard(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: _buildEmptyState('No integrations configured'),
      );
    }

    final sortedByRecent = usageData.entries.toList()
      ..sort((a, b) => b.value.lastUsed.compareTo(a.value.lastUsed));

    return AsmblCard(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: SemanticColors.success, size: 16),
              SizedBox(width: SpacingTokens.xs),
              Text(
                'Recently Active',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.lg),
          
          ...sortedByRecent.take(5).map((entry) {
            final integration = IntegrationRegistry.getById(entry.key);
            final usage = entry.value;
            
            return Padding(
              padding: EdgeInsets.only(bottom: SpacingTokens.sm),
              child: Row(
                children: [
                  _buildIntegrationIcon(integration),
                  SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          integration?.name ?? entry.key,
                          style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatLastUsed(usage.lastUsed),
                          style: TextStyles.bodySmall.copyWith(
                            color: SemanticColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSuccessRateBadge(usage.successRate),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights(List<PerformanceInsight> insights) {
    return AsmblCard(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: SemanticColors.warning, size: 16),
              SizedBox(width: SpacingTokens.xs),
              Text(
                'Performance Insights',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.lg),
          
          if (insights.isEmpty)
            _buildEmptyState('All integrations performing well!')
          else
            ...insights.take(5).map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(PerformanceInsight insight) {
    final color = _getInsightColor(insight.severity);
    final icon = _getInsightIcon(insight.type);
    
    return Container(
      margin: EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.xs),
          Text(
            insight.description,
            style: TextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRecommendations(List<UsageBasedRecommendation> recommendations) {
    return AsmblCard(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.recommend, color: SemanticColors.primary, size: 16),
              SizedBox(width: SpacingTokens.xs),
              Text(
                'Usage-Based Recommendations',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: SpacingTokens.lg),
          
          ...recommendations.map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(UsageBasedRecommendation recommendation) {
    final integration = IntegrationRegistry.getById(recommendation.integrationId);
    if (integration == null) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: SemanticColors.border, width: 1),
      ),
      child: Row(
        children: [
          _buildIntegrationIcon(integration),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  integration.name,
                  style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  recommendation.reason,
                  style: TextStyles.bodySmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _buildConfidenceBadge(recommendation.confidence),
        ],
      ),
    );
  }

  Widget _buildDetailedUsageTable(Map<String, IntegrationUsageData> usageData) {
    if (usageData.isEmpty) {
      return AsmblCard(
        padding: EdgeInsets.all(SpacingTokens.lg),
        child: _buildEmptyState('No usage data available'),
      );
    }

    return AsmblCard(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Usage Statistics',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: SpacingTokens.lg),
          
          // Table headers
          Container(
            padding: EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: SemanticColors.border)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Integration', style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Invocations', style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Success Rate', style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Avg Response', style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Last Used', style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          
          // Table rows
          ...usageData.entries.map((entry) {
            final integration = IntegrationRegistry.getById(entry.key);
            final usage = entry.value;
            
            return Container(
              padding: EdgeInsets.symmetric(vertical: SpacingTokens.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: SemanticColors.border.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        _buildIntegrationIcon(integration),
                        SizedBox(width: SpacingTokens.xs),
                        Text(integration?.name ?? entry.key, style: TextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text('${usage.totalInvocations}', style: TextStyles.bodyMedium)),
                  Expanded(flex: 2, child: _buildSuccessRateBadge(usage.successRate)),
                  Expanded(flex: 2, child: Text('${usage.averageResponseTime}ms', style: TextStyles.bodyMedium)),
                  Expanded(flex: 2, child: Text(_formatLastUsed(usage.lastUsed), style: TextStyles.bodyMedium)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildIntegrationIcon(IntegrationDefinition? integration) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: SemanticColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        _getIntegrationIcon(integration),
        color: SemanticColors.primary,
        size: 12,
      ),
    );
  }

  Widget _buildSuccessRateBadge(double successRate) {
    final percentage = (successRate * 100).toStringAsFixed(1);
    final color = successRate >= 0.95 
      ? SemanticColors.success 
      : successRate >= 0.85 
        ? SemanticColors.warning 
        : SemanticColors.error;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${percentage}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final percentage = (confidence * 100).toInt();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: SemanticColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${percentage}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: SemanticColors.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.analytics,
            size: 32,
            color: SemanticColors.onSurfaceVariant,
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            message,
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);
    
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  Color _getInsightColor(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.error:
        return SemanticColors.error;
      case InsightSeverity.warning:
        return SemanticColors.warning;
      case InsightSeverity.info:
        return SemanticColors.primary;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.performance:
        return Icons.speed;
      case InsightType.reliability:
        return Icons.error_outline;
      case InsightType.usage:
        return Icons.trending_down;
      case InsightType.security:
        return Icons.security;
    }
  }

  IconData _getIntegrationIcon(IntegrationDefinition? integration) {
    if (integration == null) return Icons.help_outline;
    
    switch (integration.category) {
      case IntegrationCategory.local:
        return Icons.computer;
      case IntegrationCategory.cloudAPIs:
        return Icons.cloud;
      case IntegrationCategory.databases:
        return Icons.storage;
      case IntegrationCategory.aiML:
        return Icons.psychology;
      case IntegrationCategory.utilities:
        return Icons.build;
    }
  }
}
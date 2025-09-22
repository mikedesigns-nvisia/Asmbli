import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/integration_testing_service.dart';
import '../../../../core/services/integration_service.dart';
import 'package:agent_engine_core/agent_engine_core.dart';

class IntegrationTestingDashboard extends ConsumerStatefulWidget {
  const IntegrationTestingDashboard({super.key});

  @override
  ConsumerState<IntegrationTestingDashboard> createState() => _IntegrationTestingDashboardState();
}

class _IntegrationTestingDashboardState extends ConsumerState<IntegrationTestingDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedIntegrationId;
  bool _isRunningTests = false;
  TestSuite? _lastTestResult;
  BenchmarkResult? _lastBenchmarkResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testingService = ref.watch(integrationTestingServiceProvider);
    final integrationService = ref.watch(integrationServiceProvider);
    final configuredIntegrations = integrationService.getConfiguredIntegrations();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: SpacingTokens.xxl),
          
          // Quick Actions
          _buildQuickActions(configuredIntegrations),
          const SizedBox(height: SpacingTokens.xxl),
          
          // Integration Selector
          _buildIntegrationSelector(configuredIntegrations),
          const SizedBox(height: SpacingTokens.lg),
          
          // Tab Navigation
          _buildTabNavigation(),
          const SizedBox(height: SpacingTokens.lg),
          
          // Tab Content
          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTestRunnerTab(testingService),
                _buildValidationTab(testingService),
                _buildBenchmarkTab(testingService),
                _buildReportsTab(testingService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bug_report,
              color: SemanticColors.primary,
              size: 28,
            ),
            const SizedBox(width: SpacingTokens.sm),
            Text(
              'Integration Testing & Validation',
              style: TextStyles.pageTitle,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          'Test integration functionality, validate configurations, and benchmark performance',
          style: TextStyles.bodyMedium.copyWith(
            color: SemanticColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(List<IntegrationStatus> integrations) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            'Run All Tests',
            'Test all configured integrations',
            Icons.play_arrow,
            SemanticColors.primary,
            integrations.isNotEmpty && !_isRunningTests 
              ? () => _runAllTests(integrations) 
              : null,
          ),
        ),
        const SizedBox(width: SpacingTokens.lg),
        Expanded(
          child: _buildQuickActionCard(
            'Validate Configs',
            'Quick validation check',
            Icons.verified,
            SemanticColors.success,
            integrations.isNotEmpty && !_isRunningTests 
              ? () => _validateAllConfigs(integrations) 
              : null,
          ),
        ),
        const SizedBox(width: SpacingTokens.lg),
        Expanded(
          child: _buildQuickActionCard(
            'Performance Test',
            'Benchmark all integrations',
            Icons.speed,
            SemanticColors.warning,
            integrations.isNotEmpty && !_isRunningTests 
              ? () => _runBenchmarkSuite(integrations) 
              : null,
          ),
        ),
        const SizedBox(width: SpacingTokens.lg),
        Expanded(
          child: _buildQuickActionCard(
            'Generate Report',
            'Create test report',
            Icons.assessment,
            SemanticColors.onSurface,
            _lastTestResult != null 
              ? () => _generateReport() 
              : null,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              if (_isRunningTests && onPressed != null)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            title,
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            subtitle,
            style: TextStyles.bodySmall.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          SizedBox(
            width: double.infinity,
            child: AsmblButton.primary(
              text: 'Run',
              onPressed: onPressed,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationSelector(List<IntegrationStatus> integrations) {
    if (integrations.isEmpty) {
      return AsmblCard(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.info_outline,
                size: 48,
                color: SemanticColors.onSurfaceVariant,
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'No Configured Integrations',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                'Configure some integrations to start testing',
                style: TextStyles.bodyMedium.copyWith(
                  color: SemanticColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Integration to Test',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: integrations.map((integration) {
              final isSelected = _selectedIntegrationId == integration.definition.id;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedIntegrationId = integration.definition.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? SemanticColors.primary.withValues(alpha: 0.1)
                        : SemanticColors.background,
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    border: Border.all(
                      color: isSelected 
                          ? SemanticColors.primary
                          : SemanticColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIntegrationIcon(integration.definition),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        integration.definition.name,
                        style: TextStyles.bodyMedium.copyWith(
                          color: isSelected ? SemanticColors.primary : SemanticColors.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (integration.isEnabled) ...[
                        const SizedBox(width: SpacingTokens.xs),
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: SemanticColors.success,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: SemanticColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: SemanticColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Test Runner'),
          Tab(text: 'Validation'),
          Tab(text: 'Benchmarks'),
          Tab(text: 'Reports'),
        ],
        labelColor: SemanticColors.primary,
        unselectedLabelColor: SemanticColors.onSurfaceVariant,
        indicator: BoxDecoration(
          color: SemanticColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        ),
      ),
    );
  }

  Widget _buildTestRunnerTab(IntegrationTestingService testingService) {
    if (_selectedIntegrationId == null) {
      return _buildEmptyState('Select an integration to run tests');
    }

    final recommendations = testingService.getTestRecommendations(_selectedIntegrationId!);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Test Recommendations
          _buildTestRecommendations(recommendations, testingService),
          const SizedBox(height: SpacingTokens.xl),
          
          // Last Test Results
          if (_lastTestResult != null) ...[
            _buildLastTestResults(_lastTestResult!),
            const SizedBox(height: SpacingTokens.xl),
          ],
          
          // Active Test Sessions
          _buildActiveTestSessions(testingService),
        ],
      ),
    );
  }

  Widget _buildTestRecommendations(
    List<TestRecommendation> recommendations,
    IntegrationTestingService testingService,
  ) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.recommend, color: SemanticColors.primary, size: 16),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Recommended Tests',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              AsmblButton.primary(
                text: 'Run All Recommended',
                onPressed: _isRunningTests ? null : () => _runRecommendedTests(recommendations, testingService),
                              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          ...recommendations.map((rec) => _buildTestRecommendationItem(rec, testingService)),
        ],
      ),
    );
  }

  Widget _buildTestRecommendationItem(
    TestRecommendation recommendation,
    IntegrationTestingService testingService,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: SemanticColors.border),
      ),
      child: Row(
        children: [
          Icon(
            _getTestTypeIcon(recommendation.testType),
            color: _getPriorityColor(recommendation.priority),
            size: 16,
          ),
          const SizedBox(width: SpacingTokens.sm),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getTestTypeName(recommendation.testType),
                      style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    _buildPriorityBadge(recommendation.priority),
                    const Spacer(),
                    Text(
                      '~${recommendation.estimatedDuration.inSeconds}s',
                      style: TextStyles.bodySmall.copyWith(
                        color: SemanticColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  recommendation.reason,
                  style: TextStyles.bodySmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: SpacingTokens.sm),
          AsmblButton.secondary(
            text: 'Run',
            onPressed: _isRunningTests 
                ? null 
                : () => _runSingleTest(recommendation.testType, testingService),
                      ),
        ],
      ),
    );
  }

  Widget _buildLastTestResults(TestSuite testResult) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                testResult.overallStatus == TestStatus.passed
                    ? Icons.check_circle
                    : Icons.error,
                color: testResult.overallStatus == TestStatus.passed
                    ? SemanticColors.success
                    : SemanticColors.error,
                size: 16,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Last Test Results',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'Duration: ${testResult.duration.inSeconds}s',
                style: TextStyles.bodySmall.copyWith(
                  color: SemanticColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          // Test Results Summary
          Row(
            children: [
              _buildResultStat('Total', '${testResult.tests.length}', SemanticColors.onSurface),
              const SizedBox(width: SpacingTokens.lg),
              _buildResultStat(
                'Passed', 
                '${testResult.tests.where((t) => t.status == TestStatus.passed).length}',
                SemanticColors.success,
              ),
              const SizedBox(width: SpacingTokens.lg),
              _buildResultStat(
                'Failed',
                '${testResult.tests.where((t) => t.status == TestStatus.failed).length}',
                SemanticColors.error,
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          // Individual Test Results
          ...testResult.tests.map((test) => _buildTestResultItem(test)),
        ],
      ),
    );
  }

  Widget _buildActiveTestSessions(IntegrationTestingService testingService) {
    final activeSessions = testingService.getActiveTestSessions();
    
    if (activeSessions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Test Sessions',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          ...activeSessions.map((session) => _buildTestSessionItem(session, testingService)),
        ],
      ),
    );
  }

  Widget _buildValidationTab(IntegrationTestingService testingService) {
    if (_selectedIntegrationId == null) {
      return _buildEmptyState('Select an integration to validate');
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          AsmblButton.primary(
            text: 'Run Validation',
            onPressed: _isRunningTests ? null : () => _runValidation(testingService),
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          // Validation results would go here
          _buildEmptyState('Run validation to see results'),
        ],
      ),
    );
  }

  Widget _buildBenchmarkTab(IntegrationTestingService testingService) {
    if (_selectedIntegrationId == null) {
      return _buildEmptyState('Select an integration to benchmark');
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AsmblButton.primary(
                  text: 'Run Benchmark',
                  onPressed: _isRunningTests ? null : () => _runBenchmark(testingService),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              AsmblButton.secondary(
                text: 'Quick Test',
                onPressed: _isRunningTests ? null : () => _runQuickBenchmark(testingService),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          if (_lastBenchmarkResult != null)
            _buildBenchmarkResults(_lastBenchmarkResult!)
          else
            _buildEmptyState('Run benchmark to see performance metrics'),
        ],
      ),
    );
  }

  Widget _buildReportsTab(IntegrationTestingService testingService) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AsmblButton.primary(
            text: 'Generate Comprehensive Report',
            onPressed: () => _generateComprehensiveReport(testingService),
          ),
          const SizedBox(height: SpacingTokens.xl),
          
          _buildEmptyState('Generate a report to see detailed analytics'),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildIntegrationIcon(IntegrationDefinition integration) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: SemanticColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        _getCategoryIcon(integration.category),
        color: SemanticColors.primary,
        size: 12,
      ),
    );
  }

  Widget _buildPriorityBadge(RecommendationPriority priority) {
    final color = _getPriorityColor(priority);
    final text = priority.name.toUpperCase();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyles.cardTitle.copyWith(color: color),
        ),
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(
            color: SemanticColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTestResultItem(TestResult test) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: test.status == TestStatus.passed 
              ? SemanticColors.success.withValues(alpha: 0.3)
              : SemanticColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            test.status == TestStatus.passed ? Icons.check : Icons.close,
            color: test.status == TestStatus.passed 
                ? SemanticColors.success 
                : SemanticColors.error,
            size: 16,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTestTypeName(test.testType),
                  style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  test.message,
                  style: TextStyles.bodySmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${test.duration.inMilliseconds}ms',
            style: TextStyles.bodySmall.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSessionItem(TestSession session, IntegrationTestingService testingService) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: SemanticColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Testing ${session.integrationId}',
                  style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Started ${DateTime.now().difference(session.startTime).inSeconds}s ago',
                  style: TextStyles.bodySmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AsmblButton.secondary(
            text: 'Cancel',
            onPressed: () => testingService.cancelTestSession(session.sessionId),
                      ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkResults(BenchmarkResult result) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: SemanticColors.warning, size: 16),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Benchmark Results',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: SpacingTokens.xs),
                decoration: BoxDecoration(
                  color: _getScoreColor(result.overallScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  'Score: ${result.overallScore.toInt()}/100',
                  style: TextStyles.bodySmall.copyWith(
                    color: _getScoreColor(result.overallScore),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          ...result.tests.map((test) => _buildBenchmarkTestItem(test)),
        ],
      ),
    );
  }

  Widget _buildBenchmarkTestItem(BenchmarkTest test) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: SemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                test.testName,
                style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${test.averageTime.toStringAsFixed(1)} ${test.unit}',
                style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Row(
            children: [
              Text('Min: ${test.minTime.toStringAsFixed(1)}', style: TextStyles.bodySmall),
              const SizedBox(width: SpacingTokens.sm),
              Text('Max: ${test.maxTime.toStringAsFixed(1)}', style: TextStyles.bodySmall),
              const SizedBox(width: SpacingTokens.sm),
              Text('Iterations: ${test.iterations}', style: TextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.science,
            size: 64,
            color: SemanticColors.onSurfaceVariant,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            message,
            style: TextStyles.bodyLarge.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action methods
  void _runAllTests(List<IntegrationStatus> integrations) async {
    setState(() => _isRunningTests = true);
    
    try {
      // Run tests for all integrations sequentially
      for (final integration in integrations) {
        if (integration.isEnabled) {
          final testingService = ref.read(integrationTestingServiceProvider);
          final result = await testingService.runIntegrationTests(integration.definition.id);
          
          if (integration == integrations.last) {
            setState(() => _lastTestResult = result);
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tests completed successfully'),
          backgroundColor: SemanticColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test execution failed: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  void _validateAllConfigs(List<IntegrationStatus> integrations) async {
    setState(() => _isRunningTests = true);
    
    try {
      final testingService = ref.read(integrationTestingServiceProvider);
      
      for (final integration in integrations) {
        if (integration.isEnabled) {
          await testingService.validateConfiguration(integration.definition.id);
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All configurations validated'),
          backgroundColor: SemanticColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validation failed: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  void _runBenchmarkSuite(List<IntegrationStatus> integrations) async {
    setState(() => _isRunningTests = true);
    
    try {
      final testingService = ref.read(integrationTestingServiceProvider);
      
      for (final integration in integrations) {
        if (integration.isEnabled) {
          final result = await testingService.runBenchmarks(integration.definition.id);
          
          if (integration == integrations.last) {
            setState(() => _lastBenchmarkResult = result);
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Benchmark suite completed'),
          backgroundColor: SemanticColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Benchmark failed: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  void _generateReport() {
    if (_lastTestResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test report generated successfully'),
          backgroundColor: SemanticColors.success,
        ),
      );
    }
  }

  void _runRecommendedTests(
    List<TestRecommendation> recommendations,
    IntegrationTestingService testingService,
  ) async {
    if (_selectedIntegrationId == null) return;
    
    setState(() => _isRunningTests = true);
    
    try {
      final testTypes = recommendations.map((r) => r.testType).toList();
      final result = await testingService.runIntegrationTests(
        _selectedIntegrationId!,
        testTypes: testTypes,
      );
      
      setState(() => _lastTestResult = result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recommended tests completed'),
          backgroundColor: SemanticColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test execution failed: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  void _runSingleTest(TestType testType, IntegrationTestingService testingService) async {
    if (_selectedIntegrationId == null) return;
    
    setState(() => _isRunningTests = true);
    
    try {
      final result = await testingService.runIntegrationTests(
        _selectedIntegrationId!,
        testTypes: [testType],
      );
      
      setState(() => _lastTestResult = result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getTestTypeName(testType)} test completed'),
          backgroundColor: SemanticColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test execution failed: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  void _runValidation(IntegrationTestingService testingService) async {
    if (_selectedIntegrationId == null) return;
    
    setState(() => _isRunningTests = true);
    
    try {
      await testingService.validateConfiguration(_selectedIntegrationId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validation completed'),
          backgroundColor: SemanticColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validation failed: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  void _runBenchmark(IntegrationTestingService testingService) async {
    if (_selectedIntegrationId == null) return;
    
    setState(() => _isRunningTests = true);
    
    try {
      final result = await testingService.runBenchmarks(_selectedIntegrationId!);
      setState(() => _lastBenchmarkResult = result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Benchmark completed'),
          backgroundColor: SemanticColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Benchmark failed: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  void _runQuickBenchmark(IntegrationTestingService testingService) async {
    if (_selectedIntegrationId == null) return;
    
    setState(() => _isRunningTests = true);
    
    try {
      final result = await testingService.runBenchmarks(_selectedIntegrationId!, iterations: 3);
      setState(() => _lastBenchmarkResult = result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick benchmark completed'),
          backgroundColor: SemanticColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Benchmark failed: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  void _generateComprehensiveReport(IntegrationTestingService testingService) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comprehensive report generated'),
        backgroundColor: SemanticColors.success,
      ),
    );
  }

  // Helper methods
  IconData _getTestTypeIcon(TestType testType) {
    switch (testType) {
      case TestType.connectivity: return Icons.wifi;
      case TestType.authentication: return Icons.lock;
      case TestType.functional: return Icons.functions;
      case TestType.performance: return Icons.speed;
      case TestType.security: return Icons.security;
      case TestType.dataIntegrity: return Icons.verified_user;
      case TestType.errorHandling: return Icons.error_outline;
      case TestType.rateLimiting: return Icons.timer;
      case TestType.fileSystem: return Icons.folder;
    }
  }

  String _getTestTypeName(TestType testType) {
    switch (testType) {
      case TestType.connectivity: return 'Connectivity';
      case TestType.authentication: return 'Authentication';
      case TestType.functional: return 'Functional';
      case TestType.performance: return 'Performance';
      case TestType.security: return 'Security';
      case TestType.dataIntegrity: return 'Data Integrity';
      case TestType.errorHandling: return 'Error Handling';
      case TestType.rateLimiting: return 'Rate Limiting';
      case TestType.fileSystem: return 'File System';
    }
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low: return SemanticColors.onSurfaceVariant;
      case RecommendationPriority.medium: return SemanticColors.warning;
      case RecommendationPriority.high: return SemanticColors.error;
      case RecommendationPriority.critical: return SemanticColors.error;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return SemanticColors.success;
    if (score >= 60) return SemanticColors.warning;
    return SemanticColors.error;
  }

  IconData _getCategoryIcon(IntegrationCategory category) {
    switch (category) {
      case IntegrationCategory.local: return Icons.computer;
      case IntegrationCategory.cloudAPIs: return Icons.cloud;
      case IntegrationCategory.databases: return Icons.storage;
      case IntegrationCategory.aiML: return Icons.psychology;
      case IntegrationCategory.utilities: return Icons.build;
      case IntegrationCategory.devops: return Icons.settings;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/integration_documentation_service.dart';
import 'package:agent_engine_core/agent_engine_core.dart';

class IntegrationDocumentationWidget extends ConsumerStatefulWidget {
  final String? selectedIntegrationId;
  final VoidCallback? onIntegrationSelected;

  const IntegrationDocumentationWidget({
    super.key,
    this.selectedIntegrationId,
    this.onIntegrationSelected,
  });

  @override
  ConsumerState<IntegrationDocumentationWidget> createState() => _IntegrationDocumentationWidgetState();
}

class _IntegrationDocumentationWidgetState extends ConsumerState<IntegrationDocumentationWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedIntegrationId;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedIntegrationId = widget.selectedIntegrationId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final docService = ref.watch(integrationDocumentationServiceProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const SizedBox(height: SpacingTokens.lg),

          // Search Bar
          _buildSearchBar(colors),
          const SizedBox(height: SpacingTokens.lg),

          // Tab Navigation
          _buildTabNavigation(colors),
          const SizedBox(height: SpacingTokens.lg),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(colors, docService),
                _buildQuickStartTab(colors, docService),
                _buildDocumentationTab(colors, docService),
                _buildTroubleshootingTab(colors, docService),
                _buildSearchTab(colors, docService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Icon(
          Icons.help_outline,
          color: colors.primary,
          size: 24,
        ),
        const SizedBox(width: SpacingTokens.sm),
        Text(
          'Integration Help & Documentation',
          style: TextStyles.cardTitle,
        ),
        const Spacer(),
        if (_selectedIntegrationId != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: SpacingTokens.xs),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.integration_instructions, size: 14, color: colors.primary),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  IntegrationRegistry.getById(_selectedIntegrationId!)?.name ?? _selectedIntegrationId!,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                GestureDetector(
                  onTap: () => setState(() => _selectedIntegrationId = null),
                  child: Icon(Icons.close, size: 14, color: colors.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar(ThemeColors colors) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search documentation, guides, and help articles...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                borderSide: BorderSide(color: colors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg, vertical: SpacingTokens.sm),
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),

        Expanded(
          child: AsmblStringDropdown(
            value: _selectedCategory,
            items: const ['All', 'Local', 'Cloud APIs', 'Databases', 'AI Enhanced', 'Utilities'],
            onChanged: (value) => setState(() => _selectedCategory = value ?? 'All'),
          ),
        ),
      ],
    );
  }

  Widget _buildTabNavigation(ThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: colors.border),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Quick Start'),
          Tab(text: 'Documentation'),
          Tab(text: 'Troubleshooting'),
          Tab(text: 'Search Results'),
        ],
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicator: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(ThemeColors colors, IntegrationDocumentationService docService) {
    final categories = docService.getDocumentationCategories();
    final popularTopics = docService.getPopularTopics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Overview
          _buildCategoriesSection(colors, categories),
          const SizedBox(height: SpacingTokens.xxl),

          // Popular Topics
          _buildPopularTopicsSection(colors, popularTopics),
          const SizedBox(height: SpacingTokens.xxl),

          // Getting Started
          _buildGettingStartedSection(colors),
        ],
      ),
    );
  }

  Widget _buildQuickStartTab(ThemeColors colors, IntegrationDocumentationService docService) {
    if (_selectedIntegrationId == null) {
      return _buildIntegrationSelector(colors);
    }

    final quickStart = docService.getQuickStartGuide(_selectedIntegrationId!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStartHeader(colors, quickStart),
          const SizedBox(height: SpacingTokens.xl),

          // Prerequisites
          if (quickStart.prerequisites.isNotEmpty) ...[
            _buildPrerequisitesSection(colors, quickStart.prerequisites),
            const SizedBox(height: SpacingTokens.xl),
          ],

          // Setup Steps
          _buildSetupStepsSection(colors, quickStart.steps),
          const SizedBox(height: SpacingTokens.xl),

          // Common Issues
          if (quickStart.commonIssues.isNotEmpty) ...[
            _buildCommonIssuesSection(colors, quickStart.commonIssues),
            const SizedBox(height: SpacingTokens.xl),
          ],

          // Next Steps
          _buildNextStepsSection(colors, quickStart.nextSteps),
        ],
      ),
    );
  }

  Widget _buildDocumentationTab(ThemeColors colors, IntegrationDocumentationService docService) {
    if (_selectedIntegrationId == null) {
      return _buildIntegrationSelector(colors);
    }

    final documentation = docService.getDocumentation(_selectedIntegrationId!);
    final configExamples = docService.getConfigurationExamples(_selectedIntegrationId!);
    final apiReference = docService.getAPIReference(_selectedIntegrationId!);

    if (documentation == null) {
      return _buildEmptyState(colors, 'Documentation not available');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentationHeader(colors, documentation),
          const SizedBox(height: SpacingTokens.xl),

          // Overview
          _buildOverviewSection(documentation),
          const SizedBox(height: SpacingTokens.xl),

          // Features
          _buildFeaturesSection(colors, documentation),
          const SizedBox(height: SpacingTokens.xl),

          // Configuration Examples
          if (configExamples.isNotEmpty) ...[
            _buildConfigurationExamplesSection(colors, configExamples),
            const SizedBox(height: SpacingTokens.xl),
          ],

          // API Reference
          if (apiReference != null) ...[
            _buildAPIReferenceSection(colors, apiReference),
            const SizedBox(height: SpacingTokens.xl),
          ],

          // Use Cases
          _buildUseCasesSection(colors, documentation),
          const SizedBox(height: SpacingTokens.xl),

          // Requirements & Limitations
          _buildRequirementsSection(colors, documentation),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingTab(ThemeColors colors, IntegrationDocumentationService docService) {
    if (_selectedIntegrationId == null) {
      return _buildIntegrationSelector(colors);
    }

    final troubleshooting = docService.getTroubleshootingGuide(_selectedIntegrationId!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTroubleshootingHeader(colors, troubleshooting),
          const SizedBox(height: SpacingTokens.xl),

          // Common Issues
          _buildTroubleshootingIssuesSection(colors, troubleshooting.commonIssues),
          const SizedBox(height: SpacingTokens.xl),

          // Diagnostic Steps
          _buildDiagnosticStepsSection(colors, troubleshooting.diagnosticSteps),
          const SizedBox(height: SpacingTokens.xl),

          // Support Resources
          _buildSupportResourcesSection(colors, troubleshooting.supportResources),
        ],
      ),
    );
  }

  Widget _buildSearchTab(ThemeColors colors, IntegrationDocumentationService docService) {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'Enter a search query',
              style: TextStyles.bodyLarge.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'Search through documentation, guides, and help articles',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final searchResults = docService.searchDocumentation(_searchQuery);

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'No results found',
              style: TextStyles.bodyLarge.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'Try different search terms or browse categories',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results (${searchResults.length})',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.lg),

          ...searchResults.map((result) => _buildSearchResultItem(colors, result)),
        ],
      ),
    );
  }

  // Section builders
  Widget _buildCategoriesSection(ThemeColors colors, List<DocumentationCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Integration Categories',
          style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: SpacingTokens.lg),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            crossAxisSpacing: SpacingTokens.lg,
            mainAxisSpacing: SpacingTokens.lg,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) => _buildCategoryCard(colors, categories[index]),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(ThemeColors colors, DocumentationCategory category) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(category.icon),
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),

          Text(
            category.description,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${category.configuredCount}/${category.integrationCount} configured',
                style: TextStyles.bodySmall,
              ),
              AsmblButton.secondary(
                text: 'View',
                onPressed: () {
                  setState(() => _selectedCategory = category.name);
                  _tabController.animateTo(4); // Go to search tab
                },
                size: AsmblButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTopicsSection(ThemeColors colors, List<PopularTopic> topics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: colors.success, size: 16),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              'Popular Help Topics',
              style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.lg),

        ...topics.map((topic) => _buildPopularTopicItem(colors, topic)),
      ],
    );
  }

  Widget _buildPopularTopicItem(ThemeColors colors, PopularTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: AsmblCard(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        topic.title,
                        style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          topic.category,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    topic.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.visibility, size: 12, color: colors.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      '${topic.viewCount}',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.thumb_up, size: 12, color: colors.success),
                    const SizedBox(width: 2),
                    Text(
                      '${topic.helpfulVotes}',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGettingStartedSection(ThemeColors colors) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle, color: colors.primary, size: 20),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Getting Started',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),

          Text(
            'New to integrations? Follow these steps to get started:',
            style: TextStyles.bodyMedium,
          ),
          const SizedBox(height: SpacingTokens.sm),

          _buildStepItem(colors, '1', 'Choose an integration from the Marketplace'),
          _buildStepItem(colors, '2', 'Follow the Quick Start guide for setup'),
          _buildStepItem(colors, '3', 'Test your integration to ensure it works'),
          _buildStepItem(colors, '4', 'Monitor health and performance'),

          const SizedBox(height: SpacingTokens.lg),
          Row(
            children: [
              AsmblButton.primary(
                text: 'Browse Marketplace',
                onPressed: widget.onIntegrationSelected,
              ),
              const SizedBox(width: SpacingTokens.sm),
              AsmblButton.secondary(
                text: 'View Quick Start',
                onPressed: () => _tabController.animateTo(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(ThemeColors colors, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Start sections
  Widget _buildQuickStartHeader(ThemeColors colors, QuickStartGuide guide) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.title,
                  style: TextStyles.cardTitle,
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  'Get ${IntegrationRegistry.getById(guide.integrationId)?.name} up and running quickly',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: colors.primary),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    '~${guide.estimatedTime.inMinutes} min',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(colors, guide.difficulty).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  guide.difficulty,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getDifficultyColor(colors, guide.difficulty),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrerequisitesSection(ThemeColors colors, List<PrerequisiteStep> prerequisites) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: colors.warning, size: 16),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Prerequisites',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),

          ...prerequisites.map((prereq) => _buildPrerequisiteItem(colors, prereq)),
        ],
      ),
    );
  }

  Widget _buildPrerequisiteItem(ThemeColors colors, PrerequisiteStep prereq) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(
          color: prereq.isRequired ? colors.warning.withValues(alpha: 0.3) : colors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            prereq.isRequired ? Icons.warning : Icons.info,
            color: prereq.isRequired ? colors.warning : colors.primary,
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
                      prereq.title,
                      style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (prereq.isRequired) ...[
                      const SizedBox(width: SpacingTokens.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'REQUIRED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: colors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  prereq.description,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '~${prereq.estimatedTime.inMinutes}m',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStepsSection(ThemeColors colors, List<SetupStep> steps) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: colors.primary, size: 16),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Setup Steps',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),

          ...steps.map((step) => _buildSetupStepItem(colors, step)),
        ],
      ),
    );
  }

  Widget _buildSetupStepItem(ThemeColors colors, SetupStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),

          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  step.description,
                  style: TextStyles.bodyMedium,
                ),
                const SizedBox(height: SpacingTokens.sm),

                Container(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Action:',
                        style: TextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      Text(
                        step.action,
                        style: TextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SpacingTokens.sm),

                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: colors.success),
                    const SizedBox(width: SpacingTokens.xs),
                    Expanded(
                      child: Text(
                        'Expected: ${step.expectedResult}',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.success,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonIssuesSection(ThemeColors colors, List<CommonIssue> issues) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: colors.warning, size: 16),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'Common Issues',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),

          ...issues.map((issue) => _buildCommonIssueItem(colors, issue)),
        ],
      ),
    );
  }

  Widget _buildCommonIssueItem(ThemeColors colors, CommonIssue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: ExpansionTile(
        title: Text(
          issue.title,
          style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          issue.description,
          style: TextStyles.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(
                  color: colors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solution:',
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.success,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    issue.solution,
                    style: TextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsSection(ThemeColors colors, List<String> nextSteps) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_forward, color: colors.primary, size: 16),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'What\'s Next?',
                style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),

          ...nextSteps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Additional sections for Documentation tab...
  Widget _buildDocumentationHeader(ThemeColors colors, IntegrationDocumentation doc) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc.title,
            style: TextStyles.cardTitle,
          ),
          const SizedBox(height: SpacingTokens.xs),
          Row(
            children: [
              Text(
                'Version ${doc.version}',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Updated ${_formatDate(doc.lastUpdated)}',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(IntegrationDocumentation doc) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            doc.overview,
            style: TextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(ThemeColors colors, IntegrationDocumentation doc) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.sm),

          ...doc.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check, color: colors.success, size: 16),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildConfigurationExamplesSection(ThemeColors colors, List<ConfigurationExample> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Examples',
          style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: SpacingTokens.sm),

        ...examples.map((example) => _buildConfigurationExampleItem(colors, example)),
      ],
    );
  }

  Widget _buildConfigurationExampleItem(ThemeColors colors, ConfigurationExample example) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: AsmblCard(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  example.title,
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: SpacingTokens.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(colors, example.difficulty).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    example.difficulty,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: _getDifficultyColor(colors, example.difficulty),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              example.description,
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Configuration',
                        style: TextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () => _copyToClipboard(colors, example.config.toString()),
                        tooltip: 'Copy configuration',
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    JsonEncoder.withIndent('  ').convert(example.config),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: SpacingTokens.sm),
            Text(
              example.explanation,
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // More section builders...
  Widget _buildIntegrationSelector(ThemeColors colors) {
    final allIntegrations = IntegrationRegistry.allIntegrations
        .where((integration) =>
            _selectedCategory == 'All' || integration.category.displayName == _selectedCategory)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select an Integration',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.lg),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.2,
              crossAxisSpacing: SpacingTokens.sm,
              mainAxisSpacing: SpacingTokens.sm,
            ),
            itemCount: allIntegrations.length,
            itemBuilder: (context, index) {
              final integration = allIntegrations[index];
              return GestureDetector(
                onTap: () => setState(() => _selectedIntegrationId = integration.id),
                child: AsmblCard(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(integration.category.name),
                            color: colors.primary,
                            size: 16,
                          ),
                          const Spacer(),
                          if (!integration.isAvailable)
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: colors.warning.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.schedule,
                                size: 10,
                                color: colors.warning,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        integration.name,
                        style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        integration.difficulty,
                        style: TextStyles.bodySmall.copyWith(
                          color: _getDifficultyColor(colors, integration.difficulty),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(ThemeColors colors, SearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: AsmblCard(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSearchResultIcon(result.type),
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    result.title,
                    style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    result.type.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              result.excerpt,
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            message,
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'computer':
      case 'local': return Icons.computer;
      case 'cloud':
      case 'cloudapis': return Icons.cloud;
      case 'storage':
      case 'databases': return Icons.storage;
      case 'psychology':
      case 'aienhanced': return Icons.psychology;
      case 'build':
      case 'utilities': return Icons.build;
      default: return Icons.help_outline;
    }
  }

  Color _getDifficultyColor(ThemeColors colors, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return colors.success;
      case 'medium': return colors.warning;
      case 'hard': return colors.error;
      default: return colors.onSurfaceVariant;
    }
  }

  IconData _getSearchResultIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.integration: return Icons.integration_instructions;
      case SearchResultType.documentation: return Icons.description;
      case SearchResultType.feature: return Icons.star;
      case SearchResultType.helpArticle: return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    return '${(difference.inDays / 30).floor()} months ago';
  }

  void _copyToClipboard(ThemeColors colors, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: colors.success,
      ),
    );
  }

  // Additional helper methods for troubleshooting, API reference, etc.
  Widget _buildTroubleshootingHeader(ThemeColors colors, TroubleshootingGuide guide) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide.title,
            style: TextStyles.cardTitle,
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Common issues and solutions for this integration',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingIssuesSection(ThemeColors colors, List<CommonIssue> issues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Common Issues',
          style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: SpacingTokens.sm),

        ...issues.map((issue) => _buildCommonIssueItem(colors, issue)),
      ],
    );
  }

  Widget _buildDiagnosticStepsSection(ThemeColors colors, List<DiagnosticStep> steps) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnostic Steps',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Follow these steps to diagnose issues:',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),

          ...steps.map((step) => _buildDiagnosticStepItem(colors, step)),
        ],
      ),
    );
  }

  Widget _buildDiagnosticStepItem(ThemeColors colors, DiagnosticStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.step}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  step.description,
                  style: TextStyles.bodySmall,
                ),
                const SizedBox(height: SpacingTokens.xs),
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.xs),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    step.command,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportResourcesSection(ThemeColors colors, List<SupportResource> resources) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Resources',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.lg),

          ...resources.map((resource) => _buildSupportResourceItem(colors, resource)),
        ],
      ),
    );
  }

  Widget _buildSupportResourceItem(ThemeColors colors, SupportResource resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: AsmblCard(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Row(
          children: [
            Icon(
              _getSupportResourceIcon(resource.type),
              color: colors.primary,
              size: 20,
            ),
            const SizedBox(width: SpacingTokens.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    resource.description,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.open_in_new, size: 16, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildAPIReferenceSection(ThemeColors colors, APIReference apiRef) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Reference',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Base URL: ${apiRef.baseUrl}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: colors.onSurface,
            ),
          ),
          Text(
            'Authentication: ${apiRef.authentication}',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),

          // Endpoints
          ...apiRef.endpoints.map((endpoint) => _buildAPIEndpointItem(colors, endpoint)),
        ],
      ),
    );
  }

  Widget _buildAPIEndpointItem(ThemeColors colors, APIEndpoint endpoint) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getMethodColor(colors, endpoint.method).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  endpoint.method,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getMethodColor(colors, endpoint.method),
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                endpoint.path,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            endpoint.description,
            style: TextStyles.bodySmall,
          ),
          if (endpoint.parameters.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'Parameters: ${endpoint.parameters.join(', ')}',
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUseCasesSection(ThemeColors colors, IntegrationDocumentation doc) {
    return AsmblCard(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use Cases',
            style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.sm),

          ...doc.useCases.map((useCase) => Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.play_arrow, color: colors.primary, size: 16),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    useCase,
                    style: TextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection(ThemeColors colors, IntegrationDocumentation doc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AsmblCard(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requirements',
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: SpacingTokens.sm),

                ...doc.requirements.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_box, color: colors.success, size: 16),
                      const SizedBox(width: SpacingTokens.xs),
                      Expanded(
                        child: Text(
                          req,
                          style: TextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.lg),
        Expanded(
          child: AsmblCard(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Limitations',
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: SpacingTokens.sm),

                ...doc.limitations.map((limitation) => Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning, color: colors.warning, size: 16),
                      const SizedBox(width: SpacingTokens.xs),
                      Expanded(
                        child: Text(
                          limitation,
                          style: TextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getSupportResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'documentation': return Icons.description;
      case 'community': return Icons.group;
      case 'support': return Icons.support_agent;
      default: return Icons.help;
    }
  }

  Color _getMethodColor(ThemeColors colors, String method) {
    switch (method.toUpperCase()) {
      case 'GET': return colors.success;
      case 'POST': return colors.primary;
      case 'PUT': return colors.warning;
      case 'DELETE': return colors.error;
      default: return colors.onSurfaceVariant;
    }
  }
}
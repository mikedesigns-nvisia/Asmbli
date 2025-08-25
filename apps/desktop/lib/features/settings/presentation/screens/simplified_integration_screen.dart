import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/components/app_navigation_bar.dart';
import '../../../../core/constants/routes.dart';
import '../widgets/auto_detection_wizard.dart';

class SimplifiedIntegrationScreen extends ConsumerWidget {
  const SimplifiedIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              SemanticColors.primary.withValues(alpha: 0.05),
              SemanticColors.background.withValues(alpha: 0.8),
              SemanticColors.background,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Navigation Bar
              AppNavigationBar(currentRoute: AppRoutes.settings),
              
              // Main content
              Expanded(
                child: Padding(
                  padding: SpacingTokens.xxl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Add Integrations',
                        style: TextStyles.pageTitle,
                      ),
                      SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Connect your tools and services automatically',
                        style: TextStyles.bodyMedium.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: SpacingTokens.xxl),
                      
                      // Auto-detect everything button
                      _buildAutoDetectCard(context),
                      SizedBox(height: SpacingTokens.xxl),
                      
                      // Integration categories
                      Text(
                        'Or choose a specific category:',
                        style: TextStyles.titleMedium,
                      ),
                      SizedBox(height: SpacingTokens.lg),
                      
                      Expanded(
                        child: _buildCategoryGrid(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoDetectCard(BuildContext context) {
    return Container(
      padding: SpacingTokens.xxl,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SemanticColors.primary.withValues(alpha: 0.1),
            SemanticColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadiusTokens.xl,
        border: Border.all(color: SemanticColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: SpacingTokens.lg,
            decoration: BoxDecoration(
              color: SemanticColors.primary,
              borderRadius: BorderRadiusTokens.full,
            ),
            child: Icon(
              Icons.auto_fix_high,
              color: SemanticColors.surface,
              size: 32,
            ),
          ),
          SizedBox(height: SpacingTokens.lg),
          Text(
            'Detect Everything Automatically',
            style: TextStyles.headlineMedium.copyWith(
              color: SemanticColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SpacingTokens.md),
          Text(
            'Scan your system for all installed tools and services. We\'ll automatically configure the ones we find.',
            style: TextStyles.bodyMedium.copyWith(
              color: SemanticColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SpacingTokens.xxl),
          AsmblButton.primary(
            text: 'Start Auto-Detection',
            onPressed: () => _showAutoDetectionWizard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      CategoryItem(
        name: 'Development Tools',
        icon: Icons.code,
        description: 'VS Code, Git, GitHub, Docker, Node.js',
        color: Colors.blue,
      ),
      CategoryItem(
        name: 'Browsers',
        icon: Icons.web,
        description: 'Brave, Chrome, Edge, Firefox, Safari',
        color: Colors.orange,
      ),
      CategoryItem(
        name: 'Cloud Services',
        icon: Icons.cloud,
        description: 'AWS, Google Cloud, Azure, Vercel',
        color: Colors.purple,
      ),
      CategoryItem(
        name: 'Databases',
        icon: Icons.storage,
        description: 'PostgreSQL, MySQL, MongoDB, Redis',
        color: Colors.green,
      ),
      CategoryItem(
        name: 'Communication',
        icon: Icons.chat,
        description: 'Slack, Discord, Teams, Zoom',
        color: Colors.pink,
      ),
      CategoryItem(
        name: 'Design Tools',
        icon: Icons.design_services,
        description: 'Figma, Sketch, Adobe Creative Suite',
        color: Colors.indigo,
      ),
      CategoryItem(
        name: 'Productivity',
        icon: Icons.task_alt,
        description: 'Notion, Obsidian, Jira, Linear',
        color: Colors.teal,
      ),
      CategoryItem(
        name: 'AI & ML',
        icon: Icons.psychology,
        description: 'OpenAI, Anthropic, Hugging Face',
        color: Colors.amber,
      ),
      CategoryItem(
        name: 'File Storage',
        icon: Icons.folder_shared,
        description: 'Dropbox, Google Drive, OneDrive',
        color: Colors.cyan,
      ),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryItem category) {
    return InkWell(
      onTap: () => _showCategoryDetection(context, category.name),
      borderRadius: BorderRadiusTokens.lg,
      child: Container(
        padding: SpacingTokens.lg,
        decoration: BoxDecoration(
          color: SemanticColors.surface,
          borderRadius: BorderRadiusTokens.lg,
          border: Border.all(color: SemanticColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: SpacingTokens.md,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadiusTokens.md,
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 32,
              ),
            ),
            SizedBox(height: SpacingTokens.md),
            Text(
              category.name,
              style: TextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SpacingTokens.xs),
            Text(
              category.description,
              style: TextStyles.bodySmall.copyWith(
                color: SemanticColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: SpacingTokens.md),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: SemanticColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadiusTokens.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    size: 14,
                    color: SemanticColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Auto-Detect',
                    style: TextStyles.labelSmall.copyWith(
                      color: SemanticColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoDetectionWizard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AutoDetectionWizard(),
    );
  }

  void _showCategoryDetection(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => AutoDetectionWizard(
        specificIntegration: category,
      ),
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final String description;
  final Color color;

  const CategoryItem({
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
  });
}
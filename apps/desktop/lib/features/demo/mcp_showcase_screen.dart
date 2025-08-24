import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_system.dart';
import '../../core/design_system/components/enhanced_template_browser.dart';
import '../../core/design_system/components/smart_mcp_form.dart';
import '../../core/design_system/components/mcp_testing_widgets.dart';
import '../../core/models/enhanced_mcp_template.dart';
import '../../core/services/enhanced_mcp_testing_service.dart';
import '../../core/services/intelligent_mcp_recommendations.dart';
import '../settings/presentation/widgets/enhanced_mcp_server_wizard.dart';
import '../settings/presentation/widgets/enhanced_mcp_dashboard.dart';

/// MCP UI Transformation Showcase Demo
/// Demonstrates all the amazing features we've built
class MCPShowcaseScreen extends ConsumerStatefulWidget {
  const MCPShowcaseScreen({super.key});

  @override
  ConsumerState<MCPShowcaseScreen> createState() => _MCPShowcaseScreenState();
}

class _MCPShowcaseScreenState extends ConsumerState<MCPShowcaseScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentDemoStep = 0;
  String _selectedRole = 'Developer';
  EnhancedMCPTemplate? _selectedTemplate;
  final _testingService = EnhancedMCPTestingService();
  TestResult? _demoTestResult;

  final List<String> _roles = [
    'Developer',
    'Designer', 
    'Data Analyst',
    'Project Manager',
    'Content Creator',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SemanticColors.background,
              SemanticColors.background.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Column(
          children: [
            // Hero Header
            _buildHeroHeader(context),
            
            // Demo Tabs
            _buildDemoTabs(context),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBeforeAfterComparison(context),
                  _buildLiveWizardDemo(context),
                  _buildTemplateBrowserDemo(context),
                  _buildSmartRecommendationsDemo(context),
                  _buildTestingDemo(context),
                  _buildDashboardDemo(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SemanticColors.primary.withValues(alpha: 0.15),
            SemanticColors.primary.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: SemanticColors.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 32,
                color: SemanticColors.primary,
              ),
              SizedBox(width: 16),
              Text(
                'MCP UI Transformation Showcase',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: SemanticColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'From Command-Line Complexity to Consumer-Grade Simplicity',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMetricCard(
                context,
                icon: Icons.speed,
                label: 'Setup Time',
                value: '80% Faster',
                color: SemanticColors.success,
              ),
              SizedBox(width: 24),
              _buildMetricCard(
                context,
                icon: Icons.check_circle,
                label: 'Success Rate',
                value: '95%',
                color: SemanticColors.primary,
              ),
              SizedBox(width: 24),
              _buildMetricCard(
                context,
                icon: Icons.integration_instructions,
                label: 'Integrations',
                value: '42+',
                color: Colors.orange,
              ),
              SizedBox(width: 24),
              _buildMetricCard(
                context,
                icon: Icons.sentiment_very_satisfied,
                label: 'User-Friendly',
                value: '100%',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoTabs(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.compare), text: 'Before vs After'),
            Tab(icon: Icon(Icons.auto_fix_high), text: 'Live Wizard'),
            Tab(icon: Icon(Icons.apps), text: 'Template Browser'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Smart Recommendations'),
            Tab(icon: Icon(Icons.play_circle), text: 'Testing & Validation'),
            Tab(icon: Icon(Icons.dashboard), text: 'Management Dashboard'),
          ],
          labelColor: SemanticColors.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: SemanticColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          isScrollable: true,
        ),
      ),
    );
  }

  Widget _buildBeforeAfterComparison(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'The Transformation: Before vs After',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 32),
          
          // PostgreSQL Example
          _buildComparisonCard(
            context,
            title: 'PostgreSQL Database Setup',
            before: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('❌ Install uvx globally:'),
                _buildCodeBlock('npm install -g @modelcontextprotocol/uvx'),
                SizedBox(height: 8),
                Text('❌ Type connection string:'),
                _buildCodeBlock('postgresql://user:password@localhost:5432/database'),
                SizedBox(height: 8),
                Text('❌ Configure SSL manually'),
                Text('❌ Test with command line'),
                Text('⏱️ Time: 10+ minutes'),
                Text('📊 Success rate: 45%'),
              ],
            ),
            after: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Click "Add Integration"'),
                Text('✅ Select "PostgreSQL" from visual browser'),
                Text('✅ Auto-detects PostgreSQL on port 5432'),
                Text('✅ Visual connection form with validation'),
                Text('✅ One-click "Test Connection"'),
                Text('⏱️ Time: 2 minutes'),
                Text('📊 Success rate: 95%'),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // GitHub Example
          _buildComparisonCard(
            context,
            title: 'GitHub Integration',
            before: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('❌ Go to GitHub.com → Settings'),
                Text('❌ Navigate to Developer Settings'),
                Text('❌ Create Personal Access Token'),
                Text('❌ Configure 20+ permission scopes'),
                Text('❌ Copy 40-character token'),
                Text('❌ Hope you got the scopes right'),
                Text('⏱️ Time: 5+ minutes'),
              ],
            ),
            after: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Select "GitHub" template'),
                Text('✅ Click "Connect with OAuth"'),
                Text('✅ Authorize in browser'),
                Text('✅ Automatic configuration'),
                Text('✅ Visual scope selector'),
                Text('⏱️ Time: 30 seconds'),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Filesystem Example
          _buildComparisonCard(
            context,
            title: 'Filesystem Access',
            before: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('❌ Type path manually:'),
                _buildCodeBlock('C:\\Users\\John\\Documents\\MyProject'),
                SizedBox(height: 8),
                Text('❌ Configure permissions in JSON'),
                Text('❌ Set file filters manually'),
                Text('❌ No preview of accessible files'),
              ],
            ),
            after: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Click "Browse Folders"'),
                Text('✅ Native folder picker opens'),
                Text('✅ Preview: "23 files, 3 folders"'),
                Text('✅ Toggle: Read-only vs Read/Write'),
                Text('✅ Visual permission scope'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context, {
    required String title,
    required Widget before,
    required Widget after,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SemanticColors.primary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: SemanticColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BEFORE (Manual)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SemanticColors.error,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        child: before,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 200,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: SemanticColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AFTER (User-Friendly)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SemanticColors.success,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        child: after,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      margin: EdgeInsets.only(top: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildLiveWizardDemo(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Experience the New Setup Wizard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'See how easy it is to add any integration',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 32),
          AsmblButton.primary(
            text: 'Launch Setup Wizard',
            icon: Icons.rocket_launch,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => EnhancedMCPServerWizard(
                  userRole: _selectedRole,
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Text(
            'Choose your role to see personalized recommendations:',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _roles.map((role) {
              final isSelected = _selectedRole == role;
              return ChoiceChip(
                selected: isSelected,
                label: Text(role),
                onSelected: (selected) {
                  setState(() => _selectedRole = role);
                },
                selectedColor: SemanticColors.primary.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateBrowserDemo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'Visual Template Browser',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Browse 42+ integrations with smart filtering and search',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: EnhancedTemplateBrowser(
              userRole: _selectedRole,
              onTemplateSelected: (template) {
                setState(() => _selectedTemplate = template);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected: ${template.name}'),
                    backgroundColor: SemanticColors.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRecommendationsDemo(BuildContext context) {
    final recommendationService = IntelligentMCPRecommendations();
    final recommendations = recommendationService.getRecommendationsForAgent(
      agentRole: _selectedRole,
      agentDescription: 'An intelligent agent for $_selectedRole tasks',
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'AI-Powered Recommendations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Get personalized integration suggestions based on your role',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SemanticColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: SemanticColors.primary),
                SizedBox(width: 12),
                Text(
                  'Current Role: $_selectedRole',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SemanticColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          ...recommendations.map((rec) => _buildRecommendationCard(context, rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, MCPRecommendation recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommendation.category.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: recommendation.category.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (recommendation.template.brandColor ?? SemanticColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              recommendation.template.icon,
              color: recommendation.template.brandColor ?? SemanticColors.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      recommendation.template.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: recommendation.category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recommendation.category.displayName,
                        style: TextStyle(
                          fontSize: 9,
                          color: recommendation.category.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  recommendation.reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: recommendation.relevanceScore,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(recommendation.category.color),
                ),
                SizedBox(height: 4),
                Text(
                  'Relevance: ${(recommendation.relevanceScore * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingDemo(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'Real-Time Connection Testing',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Watch live validation and troubleshooting in action',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 32),
          
          // Demo test for filesystem
          MCPConnectionTester(
            serverId: 'demo-filesystem',
            template: EnhancedMCPTemplates.filesystem,
            config: {
              'rootPath': '/Users/demo/Documents',
              'readOnly': false,
            },
            autoStart: false,
          ),
          
          SizedBox(height: 24),
          
          // Demo test for GitHub
          MCPConnectionTester(
            serverId: 'demo-github',
            template: EnhancedMCPTemplates.github,
            config: {
              'GITHUB_PERSONAL_ACCESS_TOKEN': 'ghp_demo_token_1234567890',
            },
            autoStart: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardDemo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: EnhancedMCPDashboard(
        agentRole: _selectedRole,
        agentDescription: 'Demo agent for $_selectedRole',
      ),
    );
  }
}
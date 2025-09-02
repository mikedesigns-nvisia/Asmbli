import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/components/app_navigation_bar.dart';
import '../../../../core/constants/routes.dart';

/// High-fidelity demo chat screen for video recording
/// Shows realistic agentic workflows and interactions
class DemoChatScreen extends ConsumerStatefulWidget {
  const DemoChatScreen({super.key});

  @override
  ConsumerState<DemoChatScreen> createState() => _DemoChatScreenState();
}

class _DemoChatScreenState extends ConsumerState<DemoChatScreen>
    with TickerProviderStateMixin {
  bool isSidebarCollapsed = false;
  bool isTyping = false;
  int currentMessageIndex = 0;
  int currentWorkflowStep = 0;
  bool showCompletionNotification = false;
  late AnimationController _typingController;
  late AnimationController _workflowController;
  late AnimationController _notificationController;
  
  final List<DemoMessage> _demoMessages = [
    DemoMessage(
      role: 'user',
      content: 'Help me analyze our Q3 sales data and create a comprehensive report with insights and recommendations',
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
    ),
    DemoMessage(
      role: 'assistant',
      content: 'I\'ll help you analyze your Q3 sales data and create a comprehensive report. Let me break this down into steps:\n\n1. **Data Collection** - Gathering sales data from multiple sources\n2. **Analysis** - Processing metrics, trends, and patterns\n3. **Visualization** - Creating charts and graphs\n4. **Insights** - Identifying key findings\n5. **Recommendations** - Strategic suggestions',
      timestamp: DateTime.now().subtract(Duration(minutes: 4, seconds: 45)),
      mcpSteps: [
        MCPStep(
          type: 'database_query',
          title: 'Connecting to Sales Database',
          description: 'Retrieving Q3 2024 sales records',
          status: 'completed',
          icon: Icons.storage,
        ),
        MCPStep(
          type: 'excel_processing',
          title: 'Processing Excel Files', 
          description: 'Analyzing sales_q3_2024.xlsx',
          status: 'completed',
          icon: Icons.table_chart,
        ),
        MCPStep(
          type: 'data_analysis',
          title: 'Statistical Analysis',
          description: 'Computing trends and correlations',
          status: 'completed',
          icon: Icons.analytics,
        ),
      ],
    ),
    DemoMessage(
      role: 'assistant',
      content: 'Perfect! I\'ve analyzed your Q3 sales data. Here are the key insights:\n\n📈 **Performance Summary:**\n• Total Revenue: \$2.4M (+18% vs Q2)\n• Units Sold: 8,450 (+12% vs Q2)\n• Average Deal Size: \$284 (+5% vs Q2)\n\n🎯 **Top Performers:**\n• Product A: \$890K revenue (37% of total)\n• West Region: \$1.1M (best performing region)\n• Enterprise segment: +45% growth\n\n⚠️ **Areas for Attention:**\n• SMB segment declined 8%\n• East region underperforming (-5%)\n• Customer acquisition cost increased 12%\n\n📋 **Recommendations:**\n1. Expand Product A marketing in East region\n2. Review SMB pricing strategy\n3. Optimize lead qualification process\n4. Launch targeted campaigns for Q4\n\nWould you like me to create detailed visualizations or dive deeper into any specific area?',
      timestamp: DateTime.now().subtract(Duration(minutes: 3, seconds: 30)),
      mcpSteps: [
        MCPStep(
          type: 'chart_generation',
          title: 'Creating Visualizations',
          description: 'Generated 5 charts and graphs',
          status: 'completed',
          icon: Icons.bar_chart,
        ),
        MCPStep(
          type: 'report_generation',
          title: 'Building Report',
          description: 'Compiled insights into PDF format',
          status: 'completed',
          icon: Icons.description,
        ),
      ],
      attachments: [
        MessageAttachment(
          name: 'Q3_Sales_Analysis.pdf',
          type: 'pdf',
          size: '2.4 MB',
        ),
        MessageAttachment(
          name: 'Sales_Trends_Charts.png',
          type: 'image',
          size: '856 KB',
        ),
      ],
    ),
    DemoMessage(
      role: 'user',
      content: 'This is excellent! Can you also schedule a meeting with the sales team to discuss these findings and send the report to key stakeholders?',
      timestamp: DateTime.now().subtract(Duration(minutes: 1, seconds: 15)),
    ),
    DemoMessage(
      role: 'assistant',
      content: 'Absolutely! I\'ll take care of both tasks for you.',
      timestamp: DateTime.now().subtract(Duration(seconds: 30)),
      isTyping: true,
      isDynamic: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _workflowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _notificationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Start demo progression
    _startDemoProgression();
  }
  
  void _startDemoProgression() {
    // Auto-progress through workflow steps
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted && currentWorkflowStep < 2) {
        setState(() {
          currentWorkflowStep++;
          if (currentWorkflowStep == 2) {
            showCompletionNotification = true;
            _notificationController.forward().then((_) {
              Timer(Duration(seconds: 3), () {
                if (mounted) {
                  _notificationController.reverse();
                }
              });
            });
          }
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  List<MCPStep> _getDynamicMCPSteps() {
    return [
      MCPStep(
        type: 'calendar_integration',
        title: 'Calendar Integration',
        description: 'Scheduling meeting with sales team',
        status: currentWorkflowStep >= 0 ? 'completed' : 'in_progress',
        icon: Icons.event,
      ),
      MCPStep(
        type: 'email_composition',
        title: 'Email Automation',
        description: 'Sending report to stakeholders',
        status: currentWorkflowStep >= 1 ? 'completed' : 
               currentWorkflowStep >= 0 ? 'in_progress' : 'pending',
        icon: Icons.email,
      ),
      if (currentWorkflowStep >= 1)
        MCPStep(
          type: 'notification_dispatch',
          title: 'Notification Dispatch',
          description: 'Sending calendar invites to attendees',
          status: currentWorkflowStep >= 2 ? 'completed' : 'in_progress',
          icon: Icons.notifications,
        ),
    ];
  }

  @override
  void dispose() {
    _typingController.dispose();
    _workflowController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: SemanticColors.background,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  AppNavigationBar(currentRoute: AppRoutes.demoChat),
                  
                  // Main Content
                  Expanded(
                    child: Row(
                      children: [
                        // Sidebar
                        _buildDemoSidebar(),
                        
                        // Chat Area
                        Expanded(
                          child: _buildDemoChatArea(),
                        ),
                        
                        // Right Sidebar
                        _buildDemoConversationSidebar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Completion notification
          if (showCompletionNotification)
            _buildCompletionNotification(),
        ],
      ),
    );
  }

  Widget _buildDemoSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: SemanticColors.surface.withValues(alpha: 0.7),
        border: Border(right: BorderSide(color: SemanticColors.border.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Header
          Padding(
            padding: EdgeInsets.all(SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agent Control Panel',
                  style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'What your agent sees & can access',
                  style: TextStyles.caption.copyWith(color: SemanticColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // Active Agent Card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
            child: AsmblCard(
              padding: EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SemanticColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.psychology, size: 16, color: SemanticColors.primary),
                      ),
                      SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sales Analytics Agent', style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text('MCP-Enabled Agent', style: TextStyles.caption.copyWith(color: SemanticColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: SemanticColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                  SizedBox(height: SpacingTokens.sm),
                  Row(
                    children: [
                      _buildCapabilityChip('7 Tools', Icons.extension, SemanticColors.success),
                      SizedBox(width: SpacingTokens.sm),
                      _buildCapabilityChip('3 Docs', Icons.description, SemanticColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: SpacingTokens.lg),
          
          // Active Tools
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.extension, size: 14, color: SemanticColors.primary),
                    SizedBox(width: 6),
                    Text('Active Tools (7)', style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
                SizedBox(height: SpacingTokens.sm),
                _buildToolItem('Sales Database', 'connected', SemanticColors.success),
                _buildToolItem('Excel Processor', 'connected', SemanticColors.success),  
                _buildToolItem('Chart Generator', 'connected', SemanticColors.success),
                _buildToolItem('Email Client', currentWorkflowStep >= 1 ? 'connected' : 'active', currentWorkflowStep >= 1 ? SemanticColors.success : SemanticColors.warning),
                _buildToolItem('Calendar API', currentWorkflowStep >= 0 ? 'connected' : 'active', currentWorkflowStep >= 0 ? SemanticColors.success : SemanticColors.warning),
                _buildToolItem('PDF Generator', 'connected', SemanticColors.success),
                _buildToolItem('Slack Integration', 'connected', SemanticColors.success),
              ],
            ),
          ),
          
          Spacer(),
          
          // API Provider
          Padding(
            padding: EdgeInsets.all(SpacingTokens.lg),
            child: Container(
              padding: EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: SemanticColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SemanticColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.api, size: 16, color: SemanticColors.primary),
                  SizedBox(width: SpacingTokens.sm),
                  Text('AI Assistant', style: TextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoChatArea() {
    return Container(
      color: SemanticColors.background,
      child: Column(
        children: [
          // Chat Header
          _buildDemoChatHeader(),
          
          // Messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(SpacingTokens.lg),
              itemCount: _demoMessages.length,
              itemBuilder: (context, index) => _buildDemoMessage(_demoMessages[index]),
            ),
          ),
          
          // Input Area
          _buildDemoInputArea(),
        ],
      ),
    );
  }

  Widget _buildDemoChatHeader() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.psychology, size: 18, color: SemanticColors.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales Analytics Workflow', style: TextStyles.pageTitle),
                Row(
                  children: [
                    Text('Sales Analytics Agent', style: TextStyles.caption.copyWith(color: SemanticColors.onSurfaceVariant, fontStyle: FontStyle.italic)),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: SemanticColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('7 MCP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: SemanticColors.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SemanticColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.api, size: 12, color: SemanticColors.primary),
                SizedBox(width: 4),
                Text('AI Assistant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SemanticColors.primary)),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: SemanticColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SemanticColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: SemanticColors.success, shape: BoxShape.circle)),
                SizedBox(width: 4),
                Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: SemanticColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoMessage(DemoMessage message) {
    final isUser = message.role == 'user';
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: SemanticColors.primary,
              child: Icon(Icons.smart_toy, size: 20, color: Colors.white),
            ),
            SizedBox(width: SpacingTokens.lg),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                Container(
                  padding: EdgeInsets.all(SpacingTokens.lg),
                  decoration: BoxDecoration(
                    color: isUser ? SemanticColors.primary : SemanticColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: !isUser ? Border.all(color: SemanticColors.border.withValues(alpha: 0.3)) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isTyping) ...[
                        _buildTypingIndicator(),
                      ] else ...[
                        Text(
                          message.content,
                          style: TextStyles.bodyMedium.copyWith(
                            color: isUser ? Colors.white : SemanticColors.onSurface,
                          ),
                        ),
                      ],
                      SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyles.caption.copyWith(
                          color: (isUser ? Colors.white : SemanticColors.onSurface).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // MCP Steps
                if (message.mcpSteps.isNotEmpty || message.isDynamic) ...[
                  SizedBox(height: SpacingTokens.sm),
                  _buildMCPSteps(message.isDynamic ? _getDynamicMCPSteps() : message.mcpSteps),
                ],
                
                // Attachments
                if (message.attachments.isNotEmpty) ...[
                  SizedBox(height: SpacingTokens.sm),
                  _buildAttachments(message.attachments),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: SpacingTokens.lg),
            CircleAvatar(
              radius: 16,
              backgroundColor: SemanticColors.surface,
              child: Icon(Icons.person, size: 20, color: SemanticColors.onSurface),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMCPSteps(List<MCPStep> steps) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: SemanticColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SemanticColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: SemanticColors.primary),
              SizedBox(width: 6),
              Text('Agent Workflow', style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: SemanticColors.primary)),
            ],
          ),
          SizedBox(height: SpacingTokens.sm),
          ...steps.map((step) => _buildMCPStep(step)),
        ],
      ),
    );
  }

  Widget _buildMCPStep(MCPStep step) {
    Color statusColor;
    Widget statusWidget;
    
    switch (step.status) {
      case 'completed':
        statusColor = SemanticColors.success;
        statusWidget = Icon(Icons.check_circle, size: 14, color: statusColor);
        break;
      case 'in_progress':
        statusColor = SemanticColors.warning;
        statusWidget = SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        );
        break;
      default:
        statusColor = SemanticColors.onSurfaceVariant;
        statusWidget = Icon(Icons.schedule, size: 14, color: statusColor);
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: SpacingTokens.xs),
      child: Row(
        children: [
          statusWidget,
          SizedBox(width: SpacingTokens.sm),
          Icon(step.icon, size: 16, color: SemanticColors.onSurfaceVariant),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                Text(step.description, style: TextStyles.caption.copyWith(color: SemanticColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(List<MessageAttachment> attachments) {
    return Column(
      children: attachments.map((attachment) => Container(
        margin: EdgeInsets.only(bottom: SpacingTokens.xs),
        padding: EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          color: SemanticColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SemanticColors.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              attachment.type == 'pdf' ? Icons.picture_as_pdf :
              attachment.type == 'image' ? Icons.image :
              Icons.attach_file,
              size: 20,
              color: SemanticColors.primary,
            ),
            SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attachment.name, style: TextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                  Text(attachment.size, style: TextStyles.caption.copyWith(color: SemanticColors.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.download, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: SemanticColors.primary.withValues(alpha: 0.1),
                foregroundColor: SemanticColors.primary,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Text('Agent is working', style: TextStyles.bodyMedium.copyWith(color: SemanticColors.onSurfaceVariant)),
        SizedBox(width: SpacingTokens.sm),
        AnimatedBuilder(
          animation: _typingController,
          builder: (context, child) {
            return Row(
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final animation = Tween<double>(begin: 0.3, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _typingController,
                    curve: Interval(delay, delay + 0.4, curve: Curves.easeInOut),
                  ),
                );
                return Container(
                  margin: EdgeInsets.only(right: 2),
                  child: Opacity(
                    opacity: animation.value,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SemanticColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDemoInputArea() {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: SemanticColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SemanticColors.border),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Agent is processing your request...',
                  hintStyle: TextStyles.bodyMedium.copyWith(color: SemanticColors.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                enabled: false,
              ),
            ),
          ),
          SizedBox(width: SpacingTokens.lg),
          Container(
            decoration: BoxDecoration(
              color: SemanticColors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: null,
              icon: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(SemanticColors.onSurfaceVariant),
                ),
              ),
              style: IconButton.styleFrom(
                padding: EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoConversationSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: SemanticColors.surface.withValues(alpha: 0.7),
        border: Border(left: BorderSide(color: SemanticColors.border.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(SpacingTokens.lg),
            child: Text('Recent Conversations', style: TextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
              children: [
                _buildConversationItem('Sales Analytics Workflow', 'Active', true),
                _buildConversationItem('Q2 Financial Review', '2 hours ago', false),
                _buildConversationItem('Customer Segmentation', '1 day ago', false),
                _buildConversationItem('Marketing Campaign Analysis', '3 days ago', false),
                _buildConversationItem('Product Performance Review', '1 week ago', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(String title, String subtitle, bool isActive) {
    return Container(
      margin: EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: isActive ? SemanticColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: SemanticColors.primary.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.bodySmall.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? SemanticColors.primary : SemanticColors.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: TextStyles.caption.copyWith(color: SemanticColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _buildToolItem(String name, String status, Color statusColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(name, style: TextStyles.caption),
          ),
          Text(
            status.toUpperCase(),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionNotification() {
    return Positioned(
      top: 100,
      right: 20,
      child: AnimatedBuilder(
        animation: _notificationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(300 * (1 - _notificationController.value), 0),
            child: Opacity(
              opacity: _notificationController.value,
              child: Container(
                width: 320,
                padding: EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: SemanticColors.success.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: SpacingTokens.sm),
                        Text(
                          'Workflow Completed!',
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SpacingTokens.sm),
                    Text(
                      '✓ Meeting scheduled with sales team\n✓ Report sent to stakeholders\n✓ Calendar invites dispatched',
                      style: TextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Demo data models
class DemoMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final List<MCPStep> mcpSteps;
  final List<MessageAttachment> attachments;
  final bool isTyping;
  final bool isDynamic;

  DemoMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.mcpSteps = const [],
    this.attachments = const [],
    this.isTyping = false,
    this.isDynamic = false,
  });
}

class MCPStep {
  final String type;
  final String title;
  final String description;
  final String status;
  final IconData icon;

  MCPStep({
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.icon,
  });
}

class MessageAttachment {
  final String name;
  final String type;
  final String size;

  MessageAttachment({
    required this.name,
    required this.type,
    required this.size,
  });
}
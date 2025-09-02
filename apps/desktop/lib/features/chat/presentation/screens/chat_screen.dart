import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agent_engine_core/models/conversation.dart' as core;
import 'package:agent_engine_core/services/implementations/service_provider.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/tokens/theme_colors.dart';
import '../../../../core/design_system/components/app_navigation_bar.dart';
import '../../../../core/constants/routes.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../../core/services/mcp_bridge_service.dart';
import '../../../../core/services/mcp_settings_service.dart';
import '../../../../core/services/claude_api_service.dart';
import '../../../../core/services/api_config_service.dart';
import '../../../../core/services/llm/unified_llm_service.dart';
import '../../../../core/services/llm/llm_provider.dart';
import '../../../../core/services/model_config_service.dart';
import '../widgets/improved_conversation_sidebar.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/agent_deployment_section.dart';
import '../widgets/unified_model_selector.dart';
import '../widgets/streaming_message_widget.dart';
import '../widgets/editable_conversation_title.dart';
import '../widgets/context_sidebar_section.dart';

/// Chat screen that matches the screenshot with collapsible sidebar and MCP servers
class ChatScreen extends ConsumerStatefulWidget {
 final String? selectedTemplate;
  
  const ChatScreen({super.key, this.selectedTemplate});

 @override
 ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
 bool isSidebarCollapsed = false;
 final TextEditingController messageController = TextEditingController();
 
 @override
 void initState() {
 super.initState();
 _initializeServices();
 }
 
 Future<void> _initializeServices() async {
 try {
 // TODO: Implement ServiceProvider
 // ServiceProvider.configure(useInMemory: true);
 // await ServiceProvider.initialize();
 
 // Initialize default API conversation after services are ready
 WidgetsBinding.instance.addPostFrameCallback((_) {
 _initializeDefaultConversation();
 });
 } catch (e) {
 print('Service initialization failed: $e');
 }
 }

 Future<void> _initializeDefaultConversation() async {
 try {
 final getOrCreateDefault = ref.read(getOrCreateDefaultConversationProvider);
 final defaultConversation = await getOrCreateDefault();
 
 // Set as selected conversation if no conversation is currently selected
 final currentSelection = ref.read(selectedConversationIdProvider);
 if (currentSelection == null) {
 ref.read(selectedConversationIdProvider.notifier).state = defaultConversation.id;
 }
 } catch (e) {
 print('Failed to initialize default conversation: $e');
 }
 }



 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final isDark = theme.brightness == Brightness.dark;
 
 return Scaffold(
 body: Container(
  decoration: BoxDecoration(
 gradient: RadialGradient(
 center: Alignment.topCenter,
 radius: 1.5,
 colors: [
 ThemeColors(context).backgroundGradientStart,
 ThemeColors(context).backgroundGradientMiddle,
 ThemeColors(context).backgroundGradientEnd,
 ],
 stops: const [0.0, 0.6, 1.0],
 ),
 ),
 child: SafeArea(
 child: Column(
 children: [
 // Header
 AppNavigationBar(currentRoute: AppRoutes.chat),
 
 // Main Content
 Expanded(
 child: Row(
 children: [
 // Sidebar
 AnimatedContainer(
 duration: Duration(milliseconds: 300),
 width: isSidebarCollapsed ? 0 : 280,
 child: isSidebarCollapsed ? null : _buildSidebar(context),
 ),
 
 // Sidebar Toggle (when collapsed)
 if (isSidebarCollapsed)
 Container(
 width: 48,
 decoration: BoxDecoration(
 color: theme.colorScheme.surface.withValues(alpha: 0.7),
 border: Border(right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3))),
 ),
 child: Column(
 children: [
 SizedBox(height: SpacingTokens.elementSpacing),
 IconButton(
 onPressed: () => setState(() => isSidebarCollapsed = false),
 icon: Icon(Icons.chevron_right, size: 20),
 style: IconButton.styleFrom(
 backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
 foregroundColor: theme.colorScheme.onSurfaceVariant,
 side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
 ),
 ),
 ],
 ),
 ),
 
 // Chat Area
 Expanded(
 child: _buildChatArea(context),
 ),
 
 // Right Sidebar for Conversations
 const ImprovedConversationSidebar(),
 ],
 ),
 ),
 ],
 ),
 ),
 ),
 );
 }

 Widget _buildChatHeader(ThemeData theme) {
 final selectedConversationId = ref.watch(selectedConversationIdProvider);
 
 if (selectedConversationId == null) {
 // No conversation selected - show default
 return Container(
 padding: EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Row(
 children: [
 Text(
 'Let\'s Talk',
 style: GoogleFonts.fustat(
  fontSize: 20,
 fontWeight: FontWeight.w600,
 color: theme.colorScheme.onSurface,
 ),
 ),
 Spacer(),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: theme.colorScheme.surfaceVariant,
 borderRadius: BorderRadius.circular(12),
 ),
 child: Text(
 'Select a conversation',
 style: GoogleFonts.fustat(
  fontSize: 12,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ),
 ],
 ),
 );
 }

 return ref.watch(conversationProvider(selectedConversationId)).when(
 data: (conversation) {
 final isAgent = conversation.metadata?['type'] == 'agent';
 final isDefaultApi = conversation.metadata?['type'] == 'default_api';
 
 return Container(
 padding: EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Row(
 children: [
 // Conversation type icon
 Container(
 padding: const EdgeInsets.all(6),
 decoration: BoxDecoration(
 color: _getConversationTypeColor(conversation, theme).withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 ),
 child: Icon(
 _getConversationTypeIcon(conversation),
 size: 18,
 color: _getConversationTypeColor(conversation, theme),
 ),
 ),
 SizedBox(width: 12),
 
 // Conversation title and info
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 EditableConversationTitle(
 conversation: conversation,
 style: GoogleFonts.fustat(
  fontSize: 20,
 fontWeight: FontWeight.w600,
 color: theme.colorScheme.onSurface,
 ),
 ),
 if (isAgent) ...[
 SizedBox(height: 2),
 Row(
 children: [
 Text(
 conversation.metadata?['agentName'] ?? 'Agent',
 style: GoogleFonts.fustat(
  fontSize: 13,
 color: theme.colorScheme.onSurfaceVariant,
 fontStyle: FontStyle.italic,
 ),
 ),
 SizedBox(width: 8),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
 decoration: BoxDecoration(
 color: theme.colorScheme.surfaceVariant,
 borderRadius: BorderRadius.circular(4),
 ),
 child: Text(
 '${(conversation.metadata?['mcpServers'] as List?)?.length ?? 0} MCP',
 style: GoogleFonts.fustat(
  fontSize: 10,
 color: theme.colorScheme.onSurfaceVariant,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 ],
 ),
 ],
 ],
 ),
 ),
 
 // API Provider badge
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: _getConversationTypeColor(conversation, theme).withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: _getConversationTypeColor(conversation, theme).withValues(alpha: 0.3),
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 _getConversationIcon(conversation),
 size: 12,
 color: _getConversationTypeColor(conversation, theme),
 ),
 SizedBox(width: 4),
 Text(
 _getConversationBadgeText(conversation),
 style: GoogleFonts.fustat(
  fontSize: 12,
 fontWeight: FontWeight.w500,
 color: _getConversationTypeColor(conversation, theme),
 ),
 ),
 ],
 ),
 ),
 
 // Agent status indicator for agent conversations
 if (isAgent) ...[
 SizedBox(width: 8),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
 decoration: BoxDecoration(
 color: ThemeColors(context).success.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: ThemeColors(context).success.withValues(alpha: 0.3),
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Container(
 width: 6,
 height: 6,
 decoration: BoxDecoration(
 color: ThemeColors(context).success,
 shape: BoxShape.circle,
 ),
 ),
 SizedBox(width: 4),
 Text(
 'ACTIVE',
 style: GoogleFonts.fustat(
  fontSize: 9,
 fontWeight: FontWeight.w600,
 color: ThemeColors(context).success,
 ),
 ),
 ],
 ),
 ),
 ],
 ],
 ),
 );
 },
 loading: () => Container(
 padding: EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Row(
 children: [
 SizedBox(
 width: 16,
 height: 16,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
 ),
 ),
 SizedBox(width: 12),
 Text(
 'Loading conversation...',
 style: GoogleFonts.fustat(
  fontSize: 16,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 error: (error, stack) => Container(
 padding: EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Text(
 'Error loading conversation',
 style: GoogleFonts.fustat(
  fontSize: 16,
 color: theme.colorScheme.error,
 ),
 ),
 ),
 );
 }

 Color _getConversationTypeColor(core.Conversation conversation, ThemeData theme) {
 final metadata = conversation.metadata;
 final type = metadata?['type'] as String?;
 final modelType = metadata?['modelType'] as String?;
 
 switch (type) {
 case 'agent':
 return ThemeColors(context).primary;
 case 'default_api':
 case 'direct_chat':
   // Use different colors for local vs API models
   if (modelType == 'local') {
     return ThemeColors(context).accent; // Use accent color for local models
   } else {
     return theme.colorScheme.onSurfaceVariant; // API models
   }
 default:
 return theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
 }
 }

 IconData _getConversationTypeIcon(core.Conversation conversation) {
 final type = conversation.metadata?['type'] as String?;
 switch (type) {
 case 'agent':
 return Icons.smart_toy;
 case 'default_api':
 return Icons.api;
 default:
 return Icons.chat;
 }
 }

 /// Get appropriate icon for conversation badge based on model type
 IconData _getConversationIcon(core.Conversation conversation) {
 final metadata = conversation.metadata;
 final modelType = metadata?['modelType'] as String?;
 final type = metadata?['type'] as String?;
 
 if (type == 'agent') {
   return Icons.smart_toy;
 }
 
 if (modelType == 'local') {
   return Icons.storage; // Local storage icon for local models
 } else {
   return Icons.cloud; // Cloud icon for API models
 }
 }

 /// Get contextual text for conversation badge
 String _getConversationBadgeText(core.Conversation conversation) {
 final metadata = conversation.metadata;
 final modelType = metadata?['modelType'] as String?;
 final modelName = metadata?['defaultModelName'] as String?;
 final provider = metadata?['defaultModelProvider'] as String?;
 final type = metadata?['type'] as String?;
 
 if (type == 'agent') {
   return 'Agent';
 }
 
 if (modelType == 'local' && modelName != null) {
   return 'Local';
 } else if (provider != null) {
   return provider;
 } else if (modelName != null) {
   return modelName;
 } else {
   // Fallback to current selected model
   final selectedModel = ref.read(selectedModelProvider);
   if (selectedModel != null) {
     if (selectedModel.isLocal) {
       return 'Local';
     } else {
       return selectedModel.provider;
     }
   }
   return 'LLM';
 }
 }

 Widget _buildSidebar(BuildContext context) {
 final theme = Theme.of(context);
 return Container(
 decoration: BoxDecoration(
 color: theme.colorScheme.surface.withValues(alpha: 0.7),
 border: Border(right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3))),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Sidebar Header (fixed)
 Padding(
 padding: EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Row(
 children: [
 Flexible(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Agent Control Panel',
 style: GoogleFonts.fustat(
  fontSize: 16,
 fontWeight: FontWeight.w600,
 color: theme.colorScheme.onSurface,
 ),
 overflow: TextOverflow.visible,
 softWrap: true,
 ),
 Text(
 'What your agent sees & can access',
 style: GoogleFonts.fustat(
  fontSize: 11,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 overflow: TextOverflow.visible,
 softWrap: true,
 ),
 ],
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 IconButton(
 onPressed: () => setState(() => isSidebarCollapsed = true),
 icon: Icon(Icons.chevron_left, size: 20),
 style: IconButton.styleFrom(
 foregroundColor: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 
 // Scrollable content
 Expanded(
 child: SingleChildScrollView(
 padding: EdgeInsets.only(bottom: SpacingTokens.elementSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Active Agent Context
 _buildActiveAgentContext(context),
 
 SizedBox(height: SpacingTokens.sectionSpacing),
 
 // Agent Loader Section - Wrapped in Flexible to prevent overflow
 AgentLoaderSection(),
                  
                  SizedBox(height: SpacingTokens.elementSpacing),

                  // Context Documents Section - Works for both Agent and Direct API conversations
                  ContextSidebarSection(),
 
 SizedBox(height: SpacingTokens.sectionSpacing),
 
 // Agent Tools & MCP Status (Only shown for agent conversations)
 _buildAgentToolsContext(context),
 
 SizedBox(height: SpacingTokens.sectionSpacing),
 
 // LLM Provider Section - Separated from Context
 Padding(
 padding: EdgeInsets.symmetric(horizontal: SpacingTokens.elementSpacing),
 child: Column(
 children: [
 // API Dropdown
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Padding(
 padding: EdgeInsets.only(left: 4, bottom: 6),
 child: Text(
 'LLM Provider',
 style: GoogleFonts.fustat(
  fontSize: 11,
 fontWeight: FontWeight.w500,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ),
 UnifiedModelSelector(),
 ],
 ),
 
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Browse Templates Button
 GestureDetector(
 onTap: () => context.go(AppRoutes.context),
 child: Container(
 width: double.infinity,
 padding: const EdgeInsets.symmetric(vertical: 12),
 child: Center(
 child: Text(
 'Browse Templates',
 style: GoogleFonts.fustat(
  fontSize: 13,
 fontWeight: FontWeight.w500,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildChatArea(BuildContext context) {
 final theme = Theme.of(context);
 return Container(
 decoration: BoxDecoration(
 color: Colors.transparent,
 ),
 child: Column(
 children: [
 // Chat Header - shows current conversation/agent
 _buildChatHeader(theme),
 
 // Messages Area or Empty State
 Expanded(
 child: _buildMessagesArea(context),
 ),
 
 // Input Area
 Container(
 padding: EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Row(
 children: [
 Expanded(
 child: Container(
 decoration: BoxDecoration(
 color: theme.colorScheme.surface.withValues(alpha: 0.8),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: theme.colorScheme.outline),
 ),
 child: KeyboardListener(
 focusNode: FocusNode(),
 onKeyEvent: (KeyEvent event) {
 if (event is KeyDownEvent) {
 final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
 final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
 
 if (isEnterPressed && isShiftPressed) {
 // Shift+Enter: send message
 _sendMessage();
 return;
 }
 // Enter alone: let TextField handle naturally for new line
 }
 },
 child: TextField(
 controller: messageController,
 decoration: InputDecoration(
 hintText: 'Type your message... (Shift+Enter to send, Enter for new line)',
 hintStyle: GoogleFonts.fustat(
  color: theme.colorScheme.onSurfaceVariant,
 ),
 border: InputBorder.none,
 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
 ),
 style: GoogleFonts.fustat(
  color: theme.colorScheme.onSurface,
 ),
 maxLines: 5,
 minLines: 1,
 keyboardType: TextInputType.multiline,
 textInputAction: TextInputAction.newline,
 onChanged: (value) => setState(() {}), // Trigger rebuild for send button state
 ),
 ),
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 Container(
 decoration: BoxDecoration(
 color: messageController.text.trim().isNotEmpty && !ref.watch(isLoadingProvider)
 ? ThemeColors(context).primary
 : theme.colorScheme.surface,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: messageController.text.trim().isNotEmpty && !ref.watch(isLoadingProvider)
 ? ThemeColors(context).primary
 : theme.colorScheme.outline,
 ),
 ),
 child: IconButton(
 onPressed: messageController.text.trim().isNotEmpty && !ref.watch(isLoadingProvider)
 ? _sendMessage
 : null,
 icon: ref.watch(isLoadingProvider) 
 ? SizedBox(
 width: 16,
 height: 16,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
 ),
 )
 : Icon(Icons.send, size: 18),
 style: IconButton.styleFrom(
 foregroundColor: messageController.text.trim().isNotEmpty && !ref.watch(isLoadingProvider)
? Colors.white
: theme.colorScheme.onSurfaceVariant,
 padding: const EdgeInsets.all(12),
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

 Widget _buildEmptyState(BuildContext context) {
 final theme = Theme.of(context);
 return Center(
 child: Container(
 constraints: BoxConstraints(maxWidth: 400),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 // Robot icon
 Container(
 width: 64,
 height: 64,
 decoration: BoxDecoration(
 color: theme.colorScheme.surfaceVariant,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: theme.colorScheme.outline),
 ),
 child: Icon(
 Icons.smart_toy_outlined,
 size: 32,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 
 SizedBox(height: SpacingTokens.textSectionSpacing),
 
 // Start a Conversation
 Text(
 'LLM Chat',
 style: GoogleFonts.fustat(
  fontSize: 24,
 fontWeight: FontWeight.w600,
 color: theme.colorScheme.onSurface,
 ),
 ),
 
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Description
 Text(
 'Chat directly with ${ref.read(defaultModelConfigProvider)?.name ?? 'your AI assistant'}.\nAdd context documents for better help, or load an agent\nfrom the sidebar for enhanced capabilities.',
 style: GoogleFonts.fustat(
  fontSize: 14,
 color: theme.colorScheme.onSurfaceVariant,
 height: 1.5,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildMessagesArea(BuildContext context) {
 final selectedConversationId = ref.watch(selectedConversationIdProvider);
 
 if (selectedConversationId == null) {
 return _buildEmptyState(context);
 }
 
 return _buildMessagesList(context, selectedConversationId);
 }
 
 Widget _buildMessagesList(BuildContext context, String conversationId) {
 final messagesAsync = ref.watch(messagesProvider(conversationId));
 
 return messagesAsync.when(
 data: (messages) {
 if (messages.isEmpty) {
 return _buildEmptyConversationState(context);
 }
 
 final theme = Theme.of(context);
 final colorScheme = theme.colorScheme;
 
 return ListView.builder(
 padding: const EdgeInsets.all(16),
 itemCount: messages.length + (ref.watch(isLoadingProvider) ? 1 : 0),
 itemBuilder: (context, index) {
 // Show streaming message widget as last item when loading
 if (index == messages.length && ref.watch(isLoadingProvider)) {
 // Check if we're in an agent conversation to show streaming response
 final conversation = ref.watch(conversationProvider(conversationId)).value;
 final isAgentConversation = conversation?.metadata?['type'] == 'agent';
 
 if (isAgentConversation) {
 return Container(
 margin: const EdgeInsets.symmetric(vertical: 8),
 child: StreamingMessageWidget(
 messageId: 'streaming-temp',
 role: 'assistant',
 ),
 );
 } else {
 return const MessageLoadingIndicator();
 }
 }
 
 final message = messages[index];
 final isUser = message.role == core.MessageRole.user;
 final hasStreamingData = message.metadata?.containsKey('streaming') == true ||
 message.metadata?.containsKey('mcpInteractions') == true ||
 message.metadata?.containsKey('toolResults') == true;

 // Use streaming widget for assistant messages with MCP data
 if (!isUser && hasStreamingData) {
 return Container(
 margin: const EdgeInsets.symmetric(vertical: 8),
 child: StreamingMessageWidget(
 messageId: message.id,
 role: 'assistant',
 ),
 );
 }

 // Standard message display for simple messages
 return Container(
 margin: const EdgeInsets.symmetric(vertical: 8),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 if (!isUser) ...[
 CircleAvatar(
 radius: 16,
 backgroundColor: colorScheme.primary,
 child: Icon(
 Icons.smart_toy,
 size: 20,
 color: colorScheme.onPrimary,
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 ],
 Expanded(
 child: Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: isUser ? colorScheme.primary : colorScheme.surface,
 borderRadius: BorderRadius.circular(8),
 border: !isUser ? Border.all(
 color: colorScheme.outline.withValues(alpha: 0.3),
 ) : null,
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 message.content,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
  ),
 ),
 SizedBox(height: 4),
 Text(
 _formatTime(message.timestamp),
 style: theme.textTheme.bodySmall?.copyWith(
 color: (isUser ? colorScheme.onPrimary : colorScheme.onSurface).withValues(alpha: 0.7),
  ),
 ),
 ],
 ),
 ),
 ),
 if (isUser) ...[
 SizedBox(width: SpacingTokens.componentSpacing),
 CircleAvatar(
 radius: 16,
 backgroundColor: colorScheme.surface,
 child: Icon(
 Icons.person,
 size: 20,
 color: colorScheme.onSurface,
 ),
 ),
 ],
 ],
 ),
 );
 },
 );
 },
 loading: () => Center(
 child: CircularProgressIndicator(color: ThemeColors(context).primary),
 ),
 error: (error, stack) => Center(
 child: ErrorMessage(
 message: 'Failed to load messages: ${error.toString()}',
 onRetry: () {
 ref.invalidate(messagesProvider(conversationId));
 },
 ),
 ),
 );
 }

 Widget _buildActiveAgentContext(BuildContext context) {
   final selectedConversationId = ref.watch(selectedConversationIdProvider);
   final theme = Theme.of(context);
   
   if (selectedConversationId == null) {
     return _buildNoActiveAgentCard(theme);
   }
   
   final conversationAsync = ref.watch(conversationProvider(selectedConversationId));
   
   return conversationAsync.when(
     data: (conversation) => _buildAgentContextCard(conversation, theme),
     loading: () => _buildLoadingAgentCard(theme),
     error: (_, __) => _buildErrorAgentCard(theme),
   );
 }

 Widget _buildAgentToolsContext(BuildContext context) {
   final selectedConversationId = ref.watch(selectedConversationIdProvider);
   final theme = Theme.of(context);
   
   if (selectedConversationId == null) {
     return Container();
   }
   
   final conversationAsync = ref.watch(conversationProvider(selectedConversationId));
   
   return conversationAsync.when(
     data: (conversation) => _buildToolsContextCard(conversation, theme),
     loading: () => Container(),
     error: (_, __) => Container(),
   );
 }

 Widget _buildAgentContextCard(core.Conversation conversation, ThemeData theme) {
   final agentName = _getDisplayName(conversation);
   final agentType = conversation.metadata?['type'] ?? 'default_api';
   final mcpServers = conversation.metadata?['mcpServers'] as List<dynamic>? ?? [];
   final contextDocs = conversation.metadata?['contextDocuments'] as List<dynamic>? ?? [];
   
   return Padding(
     padding: EdgeInsets.symmetric(horizontal: SpacingTokens.elementSpacing),
     child: Container(
       padding: EdgeInsets.all(SpacingTokens.cardPadding),
       decoration: BoxDecoration(
         color: agentType == 'agent' 
           ? theme.colorScheme.primary.withValues(alpha: 0.08)
           : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.05),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(
           color: agentType == 'agent' 
             ? theme.colorScheme.primary.withValues(alpha: 0.2)
             : theme.colorScheme.outline.withValues(alpha: 0.2),
         ),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           // Agent header
           Row(
             children: [
               Container(
                 padding: EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: agentType == 'agent'
                     ? theme.colorScheme.primary.withValues(alpha: 0.1)
                     : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(
                   agentType == 'agent' ? Icons.psychology : Icons.chat,
                   size: 16,
                   color: agentType == 'agent'
                     ? theme.colorScheme.primary
                     : theme.colorScheme.onSurfaceVariant,
                 ),
               ),
               SizedBox(width: SpacingTokens.componentSpacing),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       agentName,
                       style: GoogleFonts.fustat(
                                                  fontSize: 14,
                         fontWeight: FontWeight.w600,
                         color: theme.colorScheme.onSurface,
                       ),
                     ),
                     Text(
                       _getConversationDescription(conversation),
                       style: GoogleFonts.fustat(
                                                  fontSize: 11,
                         color: theme.colorScheme.onSurfaceVariant,
                       ),
                     ),
                   ],
                 ),
               ),
               Container(
                 padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                 decoration: BoxDecoration(
                   color: agentType == 'agent' ? Colors.green : Colors.orange,
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   agentType == 'agent' ? 'LIVE' : 'BASIC',
                   style: GoogleFonts.fustat(
                                          fontSize: 9,
                     fontWeight: FontWeight.w600,
                     color: Colors.white,
                   ),
                 ),
               ),
             ],
           ),
           
           // Agent capabilities summary
           SizedBox(height: SpacingTokens.componentSpacing),
           Row(
             children: [
               _buildCapabilityChip(
                 '${mcpServers.length} Tools',
                 Icons.extension,
                 mcpServers.isNotEmpty ? Colors.green : theme.colorScheme.onSurfaceVariant,
                 theme,
               ),
               SizedBox(width: SpacingTokens.componentSpacing),
               _buildCapabilityChip(
                 '${contextDocs.length} Docs',
                 Icons.description,
                 contextDocs.isNotEmpty ? Colors.blue : theme.colorScheme.onSurfaceVariant,
                 theme,
               ),
             ],
           ),
         ],
       ),
     ),
   );
 }

 Widget _buildToolsContextCard(core.Conversation conversation, ThemeData theme) {
   final mcpServers = conversation.metadata?['mcpServers'] as List<dynamic>? ?? [];
   final mcpConfigs = conversation.metadata?['mcpServerConfigs'] as Map<String, dynamic>? ?? {};
   final contextDocs = conversation.metadata?['contextDocuments'] as List<dynamic>? ?? [];
   
   if (mcpServers.isEmpty && contextDocs.isEmpty) {
     return Container();
   }
   
   return Padding(
     padding: EdgeInsets.symmetric(horizontal: SpacingTokens.elementSpacing),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         // Section header
         Text(
           'Agent Resources',
           style: GoogleFonts.fustat(
                          fontSize: 13,
             fontWeight: FontWeight.w600,
             color: theme.colorScheme.onSurface,
           ),
         ),
         SizedBox(height: SpacingTokens.componentSpacing),
         
         // MCP Tools
         if (mcpServers.isNotEmpty) ...[
           _buildSectionTitle('Active Tools (${mcpServers.length})', Icons.extension, theme),
           SizedBox(height: SpacingTokens.iconSpacing),
           ...mcpServers.take(4).map((serverId) {
             final config = mcpConfigs[serverId] as Map<String, dynamic>?;
             final status = config?['status'] ?? 'connected';
             return _buildToolItem(serverId.toString(), status, theme);
           }),
           if (mcpServers.length > 4)
             Text(
               '+ ${mcpServers.length - 4} more tools',
               style: GoogleFonts.fustat(
                                  fontSize: 11,
                 color: theme.colorScheme.onSurfaceVariant,
                 fontStyle: FontStyle.italic,
               ),
             ),
           SizedBox(height: SpacingTokens.componentSpacing),
         ],
         
         // Context Documents
         if (contextDocs.isNotEmpty) ...[
           _buildSectionTitle('Context Documents (${contextDocs.length})', Icons.description, theme),
           SizedBox(height: SpacingTokens.iconSpacing),
           ...contextDocs.take(3).map((doc) => _buildContextDocItem(doc.toString(), theme)),
           if (contextDocs.length > 3)
             Text(
               '+ ${contextDocs.length - 3} more documents',
               style: GoogleFonts.fustat(
                                  fontSize: 11,
                 color: theme.colorScheme.onSurfaceVariant,
                 fontStyle: FontStyle.italic,
               ),
             ),
         ],
       ],
     ),
   );
 }

 Widget _buildCapabilityChip(String text, IconData icon, Color color, ThemeData theme) {
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
         Text(
           text,
           style: GoogleFonts.fustat(
                          fontSize: 10,
             fontWeight: FontWeight.w500,
             color: color,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildSectionTitle(String title, IconData icon, ThemeData theme) {
   return Row(
     children: [
       Icon(icon, size: 14, color: theme.colorScheme.primary),
       SizedBox(width: 6),
       Text(
         title,
         style: GoogleFonts.fustat(
                      fontSize: 12,
           fontWeight: FontWeight.w500,
           color: theme.colorScheme.onSurface,
         ),
       ),
     ],
   );
 }

 Widget _buildToolItem(String serverId, String status, ThemeData theme) {
   final statusColor = status == 'connected' ? Colors.green : 
                      status == 'error' ? Colors.red : Colors.orange;
   
   return Padding(
     padding: EdgeInsets.only(bottom: 6),
     child: Row(
       children: [
         Container(
           width: 6,
           height: 6,
           decoration: BoxDecoration(
             color: statusColor,
             shape: BoxShape.circle,
           ),
         ),
         SizedBox(width: 8),
         Expanded(
           child: Text(
             serverId,
             style: GoogleFonts.fustat(
                              fontSize: 11,
               color: theme.colorScheme.onSurface,
             ),
           ),
         ),
         Text(
           status.toUpperCase(),
           style: GoogleFonts.fustat(
                          fontSize: 9,
             fontWeight: FontWeight.w600,
             color: statusColor,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildContextDocItem(String docName, ThemeData theme) {
   return Padding(
     padding: EdgeInsets.only(bottom: 6),
     child: Row(
       children: [
         Icon(Icons.description, size: 12, color: theme.colorScheme.primary),
         SizedBox(width: 8),
         Expanded(
           child: Text(
             docName,
             style: GoogleFonts.fustat(
                              fontSize: 11,
               color: theme.colorScheme.onSurface,
             ),
             overflow: TextOverflow.ellipsis,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildNoActiveAgentCard(ThemeData theme) {
   return Padding(
     padding: EdgeInsets.symmetric(horizontal: SpacingTokens.elementSpacing),
     child: Container(
       padding: EdgeInsets.all(SpacingTokens.cardPadding),
       decoration: BoxDecoration(
         color: theme.colorScheme.surface.withValues(alpha: 0.5),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(
           color: theme.colorScheme.outline.withValues(alpha: 0.2),
         ),
       ),
       child: Column(
         children: [
           Icon(
             Icons.chat_bubble_outline,
             size: 32,
             color: theme.colorScheme.onSurfaceVariant,
           ),
           SizedBox(height: SpacingTokens.componentSpacing),
           Text(
             'No conversation selected',
             style: GoogleFonts.fustat(
                              fontSize: 12,
               fontWeight: FontWeight.w500,
               color: theme.colorScheme.onSurfaceVariant,
             ),
           ),
         ],
       ),
     ),
   );
 }

 Widget _buildLoadingAgentCard(ThemeData theme) {
   return Padding(
     padding: EdgeInsets.symmetric(horizontal: SpacingTokens.elementSpacing),
     child: Container(
       padding: EdgeInsets.all(SpacingTokens.cardPadding),
       decoration: BoxDecoration(
         color: theme.colorScheme.surface.withValues(alpha: 0.5),
         borderRadius: BorderRadius.circular(12),
       ),
       child: Row(
         children: [
           SizedBox(
             width: 16,
             height: 16,
             child: CircularProgressIndicator(strokeWidth: 2),
           ),
           SizedBox(width: SpacingTokens.componentSpacing),
           Text(
             'Loading agent context...',
             style: GoogleFonts.fustat(
                              fontSize: 12,
               color: theme.colorScheme.onSurfaceVariant,
             ),
           ),
         ],
       ),
     ),
   );
 }

 Widget _buildErrorAgentCard(ThemeData theme) {
   return Padding(
     padding: EdgeInsets.symmetric(horizontal: SpacingTokens.elementSpacing),
     child: Container(
       padding: EdgeInsets.all(SpacingTokens.cardPadding),
       decoration: BoxDecoration(
         color: Colors.red.withValues(alpha: 0.1),
         borderRadius: BorderRadius.circular(12),
       ),
       child: Text(
         'Error loading agent context',
         style: GoogleFonts.fustat(
                      fontSize: 12,
           color: Colors.red,
         ),
       ),
     ),
   );
 }

 void _sendMessage() async {
 final selectedConversationId = ref.read(selectedConversationIdProvider);
 if (messageController.text.trim().isEmpty || 
 ref.read(isLoadingProvider) || 
 selectedConversationId == null) return;

 try {
 ref.read(isLoadingProvider.notifier).state = true;
 
 final sendMessage = ref.read(sendMessageProvider);
 await sendMessage(
 conversationId: selectedConversationId,
 content: messageController.text.trim(),
 );
 
 final messageContent = messageController.text.trim();
 messageController.clear();
 
 // Get conversation details to check if it's an agent conversation
 final conversation = await ref.read(conversationProvider(selectedConversationId).future);
 final isAgentConversation = conversation.metadata?['type'] == 'agent';
 
 if (isAgentConversation) {
 // Use MCP bridge for agent conversations
 final settingsService = ref.read(mcpSettingsServiceProvider);
 final mcpBridge = MCPBridgeService(settingsService);
 await _handleMCPResponse(mcpBridge, selectedConversationId, messageContent, conversation);
 } else {
 // Standard API response for non-agent conversations
 await _handleStandardResponse(selectedConversationId);
 }
 
 } catch (e) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text('Failed to send message: $e'),
 backgroundColor: ThemeColors(context).error,
 ),
 );
 }
 } finally {
 ref.read(isLoadingProvider.notifier).state = false;
 }
 }

 Future<void> _handleMCPResponse(MCPBridgeService mcpBridge, String conversationId, String userMessage, core.Conversation conversation) async {
 try {
 // Create streaming message with MCP metadata
 final streamingMessage = core.Message(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 content: '',
 role: core.MessageRole.assistant,
 timestamp: DateTime.now(),
 metadata: {
 'streaming': true,
 'processingStatus': 'initializing',
 'mcpInteractions': <Map<String, dynamic>>[],
 'toolResults': <Map<String, dynamic>>[],
 },
 );

 final service = ref.read(conversationServiceProvider);
 await service.addMessage(conversationId, streamingMessage);
 ref.invalidate(messagesProvider(conversationId));

 // Process message through MCP bridge
 final enabledServers = (conversation.metadata?['mcpServers'] as List<dynamic>?)
 ?.map((server) => server['id'] as String)
 ?.toList() ?? <String>[];
 
 final response = await mcpBridge.processMessage(
 conversationId: conversationId,
 message: userMessage,
 enabledServerIds: enabledServers,
 conversationMetadata: conversation.metadata,
 );

 // Update message with final content and MCP interaction data
 final finalMessage = core.Message(
 id: streamingMessage.id,
 content: response.response,
 role: core.MessageRole.assistant,
 timestamp: streamingMessage.timestamp,
 metadata: {
 'streaming': false,
 'processingStatus': 'completed',
 'mcpInteractions': response.metadata['interactions'] ?? [],
 'toolResults': response.metadata['toolResults'] ?? [],
 'executionTime': response.latency,
 'mcpServersUsed': response.usedServers,
 },
 );

 await service.addMessage(conversationId, finalMessage);
 ref.invalidate(messagesProvider(conversationId));

 } catch (e) {
 print('MCP response error: $e');
 // Fallback to standard response
 await _handleStandardResponse(conversationId);
 }
 }

 Future<void> _handleStandardResponse(String conversationId) async {
 try {
 // Get unified LLM service and selected model
 final unifiedLLMService = ref.read(unifiedLLMServiceProvider);
 final selectedModel = ref.read(selectedModelProvider);

 // Check if model is configured - different logic for local vs API models
 print('DEBUG: Selected model: ${selectedModel?.name}, isLocal: ${selectedModel?.isLocal}, isConfigured: ${selectedModel?.isConfigured}, status: ${selectedModel?.status}');
 
 if (selectedModel == null) {
   if (mounted) {
     _showApiKeyConfigurationDialog();
   }
   throw Exception('No model selected. Please select an AI model to start chatting.');
 }
 
 if (!selectedModel.isConfigured) {
   if (selectedModel.isLocal) {
     // For local models, try to make them ready if Ollama is available
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Local model "${selectedModel.name}" is not ready. Status: ${selectedModel.status}.\n\nTo fix:\n1. Install Ollama from ollama.ai\n2. Run: ollama pull ${selectedModel.ollamaModelId ?? selectedModel.name.toLowerCase()}'),
           backgroundColor: ThemeColors(context).error,
           duration: Duration(seconds: 6),
         ),
       );
     }
     throw Exception('Local model not ready. Status: ${selectedModel.status}. Please install Ollama and run: ollama pull ${selectedModel.ollamaModelId ?? selectedModel.name.toLowerCase()}');
   } else {
     // For API models, show API key configuration
     if (mounted) {
       _showApiKeyConfigurationDialog();
     }
     throw Exception('API model not configured. Please configure your API key to start chatting.');
   }
 }

 // Get conversation messages for context
 final service = ref.read(conversationServiceProvider);
 final messages = await service.getMessages(conversationId);
 
 // Build conversation history for LLM
 final conversationHistory = messages
 .where((msg) => msg.role != core.MessageRole.system)
 .map((msg) => {
 'role': msg.role == core.MessageRole.user ? 'user' : 'assistant',
 'content': msg.content,
 })
 .toList();

 // Remove the last user message since it will be sent separately
 final lastUserMessage = conversationHistory.removeLast();
 final userMessage = lastUserMessage['content'] as String;

 // Get conversation details to check for system prompt
 final conversation = await ref.read(conversationProvider(conversationId).future);
 final systemPrompt = conversation.metadata?['systemPrompt'] as String?;

 // Create chat context
 final chatContext = ChatContext(
 messages: conversationHistory,
 systemPrompt: systemPrompt,
 );

 // Call unified LLM service
 final response = await unifiedLLMService.chat(
 message: userMessage,
 modelId: selectedModel.id,
 context: chatContext,
 );

 // Create assistant message with the response
 final assistantMessage = core.Message(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 content: response.content,
 role: core.MessageRole.assistant,
 timestamp: DateTime.now(),
 metadata: {
 'modelUsed': response.modelUsed,
 'modelType': selectedModel.type.name,
 'modelProvider': selectedModel.provider,
 'tokenUsage': response.usage != null ? {
 'inputTokens': response.usage!.inputTokens,
 'outputTokens': response.usage!.outputTokens,
 'totalTokens': response.usage!.totalTokens,
 'estimatedCost': response.usage!.estimatedCost,
 } : null,
 'responseMetadata': response.metadata,
 },
 );

 await service.addMessage(conversationId, assistantMessage);
 ref.invalidate(messagesProvider(conversationId));
 
 } catch (e) {
 // Create error message
 final errorMessage = core.Message(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 content: 'Sorry, I encountered an error: ${e.toString()}',
 role: core.MessageRole.assistant,
 timestamp: DateTime.now(),
 metadata: {
 'isError': true,
 'errorType': e.runtimeType.toString(),
 },
 );

 final service = ref.read(conversationServiceProvider);
 await service.addMessage(conversationId, errorMessage);
 ref.invalidate(messagesProvider(conversationId));
 }
 }

 Widget _buildEmptyConversationState(BuildContext context) {
 final theme = Theme.of(context);
 return Center(
 child: Container(
 constraints: BoxConstraints(maxWidth: 400),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Container(
 width: 64,
 height: 64,
 decoration: BoxDecoration(
 color: theme.colorScheme.surfaceVariant,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: theme.colorScheme.outline),
 ),
 child: Icon(
 Icons.chat_bubble_outline,
 size: 32,
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 SizedBox(height: SpacingTokens.textSectionSpacing),
 Text(
 'Let\'s Talk',
 style: GoogleFonts.fustat(
  fontSize: 20,
 fontWeight: FontWeight.w600,
 color: theme.colorScheme.onSurface,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'Type a message below to begin this conversation.',
 style: GoogleFonts.fustat(
  fontSize: 14,
 color: theme.colorScheme.onSurfaceVariant,
 height: 1.5,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 ),
 );
 }
 
 String _formatTime(DateTime time) {
 return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
 }

 /// Get display name for conversation - shows the actual conversation title or appropriate default
 String _getDisplayName(core.Conversation conversation) {
 final agentType = conversation.metadata?['type'] as String?;
 final agentName = conversation.metadata?['agentName'] as String?;
 
 // For agent conversations, prefer agent name
 if (agentType == 'agent' && agentName != null && agentName.isNotEmpty) {
 return agentName;
 }
 
 // For non-agent conversations, use the conversation title if it's meaningful
 if (conversation.title.isNotEmpty && 
 conversation.title != 'Let\'s Talk' && 
 conversation.title != 'New Chat' &&
 !conversation.title.startsWith('New Conversation')) {
 return conversation.title;
 }
 
 // Fallback based on conversation type
 switch (agentType) {
 case 'agent':
 return agentName ?? 'Agent Assistant';
 case 'default_api':
 case 'direct_chat':
 // Check if conversation has stored model information
 final storedModelName = conversation.metadata?['defaultModelName'] as String?;
 final modelType = conversation.metadata?['modelType'] as String?;
 if (storedModelName != null && storedModelName.isNotEmpty) {
 if (modelType == 'local') {
 return 'Local $storedModelName';
 } else {
 final provider = conversation.metadata?['defaultModelProvider'] as String?;
 return provider != null ? '$provider Chat' : '$storedModelName Chat';
 }
 }

 // Fallback to current selected model if no stored model
 final selectedModel = ref.read(selectedModelProvider);
 if (selectedModel != null) {
 return selectedModel.isLocal 
 ? 'Local ${selectedModel.name}'
 : '${selectedModel.provider} Chat';
 }
 return 'AI Assistant';
 default:
 return 'Chat Session';
 }
 }

 /// Get description for conversation based on its type and current model
 String _getConversationDescription(core.Conversation conversation) {
 final agentType = conversation.metadata?['type'] as String?;
 final selectedModel = ref.read(selectedModelProvider);
 
 switch (agentType) {
 case 'agent':
 final mcpServers = conversation.metadata?['mcpServers'] as List<dynamic>? ?? [];
 return mcpServers.isNotEmpty 
 ? 'MCP-Enabled Agent with ${mcpServers.length} tool(s)'
 : 'Custom Agent Assistant';
 
 case 'default_api':
 case 'direct_chat':
 // Check if conversation has stored model information
 final storedModelName = conversation.metadata?['defaultModelName'] as String?;
 final modelType = conversation.metadata?['modelType'] as String?;
 final provider = conversation.metadata?['defaultModelProvider'] as String?;
 
 if (storedModelName != null && storedModelName.isNotEmpty) {
 if (modelType == 'local') {
 return 'Local model via Ollama';
 } else if (provider != null) {
 return 'API model via $provider';
 } else {
 return 'API-based assistant';
 }
 }
 
 // Fallback to current selected model
 if (selectedModel != null) {
 if (selectedModel.isLocal) {
 return 'Local model via Ollama';
 } else {
 return 'API model via ${selectedModel.provider}';
 }
 }
 return 'AI Assistant';
 
 default:
 return 'Chat Session';
 }
 }

  /// Show API key configuration dialog when user tries to chat without API key
 void _showApiKeyConfigurationDialog() {
   showDialog(
     context: context,
     barrierDismissible: false, // Force user to configure or cancel
     builder: (context) => AlertDialog(
       title: Row(
         children: [
           Icon(Icons.key, color: SemanticColors.primary),
           SizedBox(width: 8),
           Text('API Key Required'),
         ],
       ),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text('To start chatting with AI, you need to configure your API key.'),
           SizedBox(height: 8),
           Text('This enables real AI conversations with Claude or other providers.'),
         ],
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.of(context).pop(),
           child: Text('Later'),
         ),
         ElevatedButton.icon(
           onPressed: () {
             Navigator.of(context).pop();
             context.push(AppRoutes.settings);
           },
           icon: Icon(Icons.settings),
           label: Text('Configure API Key'),
           style: ElevatedButton.styleFrom(
             backgroundColor: SemanticColors.primary,
             foregroundColor: SemanticColors.onPrimary,
           ),
         ),
       ],
     ),
   );
 }
}



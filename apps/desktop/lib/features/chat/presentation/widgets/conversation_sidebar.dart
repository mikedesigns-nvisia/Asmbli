import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';
import 'conversation_list.dart';
import 'conversation_archive_modal.dart';
import 'topic_management_section.dart';

class ConversationSidebar extends ConsumerStatefulWidget {
 const ConversationSidebar({super.key});

 @override
 ConsumerState<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends ConsumerState<ConversationSidebar> {
 bool isCollapsed = false;
 final bool _showTopicsSection = false;
 final int _selectedTab = 1; // 0 for topics, 1 for conversations

 @override
 Widget build(BuildContext context) {
 return Row(
 children: [
 // Collapse/expand toggle when collapsed
 if (isCollapsed)
 Container(
 width: 48,
 decoration: BoxDecoration(
 color: ThemeColors(context).surface.withOpacity(0.7),
 border: Border(
 left: BorderSide(color: ThemeColors(context).border.withOpacity(0.3)),
 ),
 ),
 child: Column(
 children: [
 const SizedBox(height: SpacingTokens.elementSpacing),
 IconButton(
 onPressed: () => setState(() => isCollapsed = false),
 icon: const Icon(Icons.chevron_left, size: 20),
 style: IconButton.styleFrom(
 backgroundColor: ThemeColors(context).surface.withOpacity(0.8),
 foregroundColor: ThemeColors(context).onSurfaceVariant,
 side: BorderSide(color: ThemeColors(context).border.withOpacity(0.5)),
 ),
 tooltip: 'Show Conversations',
 ),
 ],
 ),
 ),

 // Main sidebar content
 AnimatedContainer(
 duration: const Duration(milliseconds: 300),
 width: isCollapsed ? 0 : 320,
 child: isCollapsed ? null : _buildSidebarContent(),
 ),
 ],
 );
 }

 Widget _buildSidebarContent() {
 return Container(
 decoration: BoxDecoration(
 color: ThemeColors(context).surface.withOpacity(0.7),
 border: Border(
 left: BorderSide(color: ThemeColors(context).border.withOpacity(0.3)),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header
 Container(
 padding: const EdgeInsets.all(SpacingTokens.cardPadding),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Title and collapse button row
 Row(
 children: [
 Text(
 'Conversations',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.w600,
 fontSize: 14,
 ),
 ),
 const Spacer(),
 IconButton(
 onPressed: () => setState(() => isCollapsed = true),
 icon: const Icon(Icons.chevron_right, size: 20),
 style: IconButton.styleFrom(
 foregroundColor: ThemeColors(context).onSurfaceVariant,
 ),
 tooltip: 'Hide Conversations',
 ),
 ],
 ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 // New Chat Button on its own row
 AsmblButton.primary(
 text: 'New Chat',
 icon: Icons.add,
 onPressed: _startNewChat,
  ),
 ],
 ),
 ),
 
 // Conversation List
 Expanded(
 child: _selectedTab == 0 
              ? const TopicManagementSection()
              : const ConversationList(),
 ),
 
 // Footer with additional actions
 Container(
 padding: const EdgeInsets.all(SpacingTokens.cardPadding),
 decoration: BoxDecoration(
 border: Border(
 top: BorderSide(color: ThemeColors(context).border.withOpacity(0.3)),
 ),
 ),
 child: Column(
 children: [
 // Archive conversations button
 AsmblButton.secondary(
 text: 'View Archived',
 icon: Icons.archive_outlined,
 onPressed: () => _showArchiveModal(context),
  ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 
 // Export conversations button
 AsmblButton.secondary(
 text: 'Export Conversations',
 icon: Icons.download_outlined,
 onPressed: () {
 // Show export dialog
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(
 content: Text('Export feature coming soon'),
 duration: Duration(seconds: 2),
 ),
 );
 },
  ),
 ],
 ),
 ),
 ],
 ),
 );
 }

 void _showArchiveModal(BuildContext context) {
 showDialog(
 context: context,
 builder: (context) => const ConversationArchiveModal(),
 );
 }

 void _startNewChat() async {
 try {
 // Create a new conversation
 final createConversation = ref.read(createConversationProvider);
 final conversation = await createConversation(title: 'Let\'s Talk');
 
 // Set as selected conversation
 ref.read(selectedConversationIdProvider.notifier).state = conversation.id;
 
 // Refresh conversations list
 ref.invalidate(conversationsProvider);
 } catch (e) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text('Failed to create new chat: $e'),
 backgroundColor: ThemeColors(context).error,
 ),
 );
 }
 }
 }
}
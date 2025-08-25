import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';
import 'conversation_list.dart';
import 'conversation_archive_modal.dart';

class ConversationSidebar extends ConsumerStatefulWidget {
 const ConversationSidebar({super.key});

 @override
 ConsumerState<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends ConsumerState<ConversationSidebar> {
 bool isCollapsed = false;
 int _selectedTab = 0; // 0: Conversations, 1: Agent Context

 @override
 Widget build(BuildContext context) {
 return Row(
 children: [
 // Collapse/expand toggle when collapsed
 if (isCollapsed)
 Container(
 width: 48,
 decoration: BoxDecoration(
 color: ThemeColors(context).surface.withValues(alpha: 0.7),
 border: Border(
 left: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
 ),
 ),
 child: Column(
 children: [
 SizedBox(height: SpacingTokens.elementSpacing),
 IconButton(
 onPressed: () => setState(() => isCollapsed = false),
 icon: Icon(Icons.chevron_left, size: 20),
 style: IconButton.styleFrom(
 backgroundColor: ThemeColors(context).surface.withValues(alpha: 0.8),
 foregroundColor: ThemeColors(context).onSurfaceVariant,
 side: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.5)),
 ),
 tooltip: 'Show Conversations',
 ),
 ],
 ),
 ),

 // Main sidebar content
 AnimatedContainer(
 duration: Duration(milliseconds: 300),
 width: isCollapsed ? 0 : 320,
 child: isCollapsed ? null : _buildSidebarContent(),
 ),
 ],
 );
 }

 Widget _buildSidebarContent() {
 return Container(
 decoration: BoxDecoration(
 color: ThemeColors(context).surface.withValues(alpha: 0.7),
 border: Border(
 left: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header
 Container(
 padding: EdgeInsets.all(SpacingTokens.cardPadding),
 child: Row(
 children: [
 Text(
 'Conversations',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.w600,
 fontSize: 14,
 ),
 ),
 Spacer(),
 IconButton(
 onPressed: () => setState(() => isCollapsed = true),
 icon: Icon(Icons.chevron_right, size: 20),
 style: IconButton.styleFrom(
 foregroundColor: ThemeColors(context).onSurfaceVariant,
 ),
 tooltip: 'Hide Conversations',
 ),
 ],
 ),
 ),
 
 // Conversation List
 Expanded(
 child: ConversationList(),
 ),
 
 // Footer with additional actions
 Container(
 padding: EdgeInsets.all(SpacingTokens.cardPadding),
 decoration: BoxDecoration(
 border: Border(
 top: BorderSide(color: ThemeColors(context).border.withValues(alpha: 0.3)),
 ),
 ),
 child: Column(
 children: [
 // Archive conversations button
 AsmblButton.secondary(
 text: 'View Archived',
 icon: Icons.archive_outlined,
 onPressed: () => _showArchiveModal(context),
 isFullWidth: true,
 ),
 SizedBox(height: SpacingTokens.iconSpacing),
 
 // Export conversations button
 AsmblButton.secondary(
 text: 'Export Conversations',
 icon: Icons.download_outlined,
 onPressed: () {
 // Show export dialog
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text('Export feature coming soon'),
 duration: Duration(seconds: 2),
 ),
 );
 },
 isFullWidth: true,
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
}
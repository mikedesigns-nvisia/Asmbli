import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';

class ConversationArchiveModal extends ConsumerWidget {
 const ConversationArchiveModal({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final archivedConversationsAsync = ref.watch(archivedConversationsProvider);
 
 return Dialog(
 backgroundColor: Colors.transparent,
 child: Container(
 width: 600,
 height: 500,
 decoration: BoxDecoration(
 color: ThemeColors(context).surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
 border: Border.all(color: ThemeColors(context).border),
 ),
 child: Column(
 children: [
 // Header
 Container(
 padding: const EdgeInsets.all(SpacingTokens.xl),
 decoration: BoxDecoration(
 border: Border(
 bottom: BorderSide(color: ThemeColors(context).border),
 ),
 ),
 child: Row(
 children: [
 Icon(
 Icons.archive,
 color: ThemeColors(context).onSurface,
 size: 20,
 ),
 const SizedBox(width: SpacingTokens.sm),
 Text(
 'Archived Conversations',
 style: TextStyles.sectionTitle.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.w600,
 ),
 ),
 const Spacer(),
 IconButton(
 onPressed: () => Navigator.of(context).pop(),
 icon: const Icon(Icons.close, size: 20),
 style: IconButton.styleFrom(
 foregroundColor: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 
 // Content
 Expanded(
 child: archivedConversationsAsync.when(
 data: (archivedConversations) {
 if (archivedConversations.isEmpty) {
 return _buildEmptyState(context);
 }
 
 return ListView.builder(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 itemCount: archivedConversations.length,
 itemBuilder: (context, index) {
 final conversation = archivedConversations[index];
 return _ArchivedConversationItem(
 conversation: conversation,
 onRestore: () => _restoreConversation(ref, conversation.id),
 onDelete: () => _showDeleteConfirmation(context, ref, conversation),
 );
 },
 );
 },
 loading: () => Center(
 child: CircularProgressIndicator(
 color: ThemeColors(context).primary,
 ),
 ),
 error: (error, stack) => Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.error_outline,
 size: 48,
 color: ThemeColors(context).error,
 ),
 const SizedBox(height: SpacingTokens.lg),
 Text(
 'Failed to load archived conversations',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).error,
 ),
 ),
 const SizedBox(height: SpacingTokens.sm),
 Text(
 error.toString(),
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 ),
 ),
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildEmptyState(BuildContext context) {
 return Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.archive_outlined,
 size: 64,
 color: ThemeColors(context).onSurfaceVariant.withOpacity(0.5),
 ),
 const SizedBox(height: SpacingTokens.xl),
 Text(
 'No archived conversations',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: SpacingTokens.sm),
 Text(
 'Conversations you archive will appear here',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 );
 }

 Future<void> _restoreConversation(WidgetRef ref, String conversationId) async {
 try {
 final archiveConversation = ref.read(archiveConversationProvider);
 await archiveConversation(conversationId, false); // false = unarchive
 } catch (e) {
 // Handle error - could show a snackbar
 }
 }

 Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref, Conversation conversation) async {
 final confirmed = await showDialog<bool>(
 context: context,
 builder: (context) => AlertDialog(
 backgroundColor: ThemeColors(context).surface,
 title: Text(
 'Delete Conversation',
 style: TextStyles.sectionTitle.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 content: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Are you sure you want to permanently delete this conversation?',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.sm),
 Text(
 '"${conversation.title}"',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontStyle: FontStyle.italic,
 ),
 ),
 const SizedBox(height: SpacingTokens.sm),
 Text(
 'This action cannot be undone.',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).error,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 actions: [
 AsmblButton.secondary(
 text: 'Cancel',
 onPressed: () => Navigator.of(context).pop(false),
 ),
 const SizedBox(width: SpacingTokens.sm),
 Container(
 decoration: BoxDecoration(
 color: ThemeColors(context).error,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: TextButton(
 onPressed: () => Navigator.of(context).pop(true),
 style: TextButton.styleFrom(
 foregroundColor: ThemeColors(context).surface,
 padding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.lg,
 vertical: SpacingTokens.sm,
 ),
 ),
 child: Text(
 'Delete Forever',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).surface,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 ),
 ],
 ),
 );

 if (confirmed == true && context.mounted) {
 try {
 final deleteConversation = ref.read(deleteConversationProvider);
 await deleteConversation(conversation.id);
 } catch (e) {
 // Handle error
 }
 }
 }
}

class _ArchivedConversationItem extends StatelessWidget {
 final Conversation conversation;
 final VoidCallback onRestore;
 final VoidCallback onDelete;

 const _ArchivedConversationItem({
 required this.conversation,
 required this.onRestore,
 required this.onDelete,
 });

 @override
 Widget build(BuildContext context) {
 return Container(
 margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
 padding: const EdgeInsets.all(SpacingTokens.md),
 decoration: BoxDecoration(
 color: ThemeColors(context).surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 border: Border.all(color: ThemeColors(context).border),
 ),
 child: Row(
 children: [
 // Conversation info
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 conversation.title,
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.w500,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 const SizedBox(height: SpacingTokens.xs),
 Row(
 children: [
 Icon(
 Icons.message,
 size: 12,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 const SizedBox(width: SpacingTokens.xs),
 Text(
 '${conversation.messages.length} messages',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 const SizedBox(width: SpacingTokens.sm),
 Icon(
 Icons.schedule,
 size: 12,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 const SizedBox(width: SpacingTokens.xs),
 Text(
 _formatDate(conversation.createdAt),
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 
 // Actions
 Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 // Restore button
 IconButton(
 onPressed: onRestore,
 icon: const Icon(Icons.unarchive, size: 18),
 style: IconButton.styleFrom(
 backgroundColor: ThemeColors(context).primary.withOpacity(0.1),
 foregroundColor: ThemeColors(context).primary,
 ),
 tooltip: 'Restore',
 ),
 const SizedBox(width: SpacingTokens.xs),
 
 // Delete button
 IconButton(
 onPressed: onDelete,
 icon: const Icon(Icons.delete_forever, size: 18),
 style: IconButton.styleFrom(
 backgroundColor: ThemeColors(context).error.withOpacity(0.1),
 foregroundColor: ThemeColors(context).error,
 ),
 tooltip: 'Delete Forever',
 ),
 ],
 ),
 ],
 ),
 );
 }

 String _formatDate(DateTime date) {
 final now = DateTime.now();
 final diff = now.difference(date);
 
 if (diff.inDays == 0) {
 return 'Today';
 } else if (diff.inDays == 1) {
 return 'Yesterday';
 } else if (diff.inDays < 7) {
 return '${diff.inDays}d ago';
 } else if (diff.inDays < 30) {
 return '${(diff.inDays / 7).floor()}w ago';
 } else {
 return '${date.day}/${date.month}/${date.year}';
 }
 }
}
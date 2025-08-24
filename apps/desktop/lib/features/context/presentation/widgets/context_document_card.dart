import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/context_document.dart';

class ContextDocumentCard extends StatelessWidget {
 final ContextDocument document;
 final Function(ContextDocument) onEdit;
 final Function(String) onDelete;
 final Function(String) onAssignToAgent;

 const ContextDocumentCard({
 super.key,
 required this.document,
 required this.onEdit,
 required this.onDelete,
 required this.onAssignToAgent,
 });

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 
 return AsmblCardEnhanced.elevated(
 isInteractive: true,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 // Header with type and actions
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Container(
 padding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.sm,
 vertical: SpacingTokens.xs,
 ),
 decoration: BoxDecoration(
 color: _getTypeColor(document.type, colors),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Text(
 document.type.displayName,
 style: TextStyles.caption.copyWith(
 color: colors.onPrimary,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 PopupMenuButton<String>(
 icon: Icon(
 Icons.more_vert,
 color: colors.onSurfaceVariant,
 size: 20,
 ),
 itemBuilder: (context) => [
 PopupMenuItem(
 value: 'edit',
 child: Row(
 children: [
 Icon(Icons.edit, size: 16, color: colors.onSurface),
 SizedBox(width: SpacingTokens.sm),
 Text('Edit', style: TextStyles.bodyMedium),
 ],
 ),
 ),
 PopupMenuItem(
 value: 'assign',
 child: Row(
 children: [
 Icon(Icons.person_add, size: 16, color: colors.onSurface),
 SizedBox(width: SpacingTokens.sm),
 Text('Assign to Agent', style: TextStyles.bodyMedium),
 ],
 ),
 ),
 PopupMenuItem(
 value: 'delete',
 child: Row(
 children: [
 Icon(Icons.delete, size: 16, color: colors.error),
 SizedBox(width: SpacingTokens.sm),
 Text(
 'Delete',
 style: TextStyles.bodyMedium.copyWith(color: colors.error),
 ),
 ],
 ),
 ),
 ],
 onSelected: (value) => _handleMenuAction(value, context),
 ),
 ],
 ),

 SizedBox(height: SpacingTokens.lg),

 // Title
 Text(
 document.title,
 style: TextStyles.cardTitle.copyWith(
 color: colors.onSurface,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 textAlign: TextAlign.center,
 ),

 SizedBox(height: SpacingTokens.sm),

 // Content preview
 Expanded(
 child: Padding(
 padding: EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
 child: Text(
 document.content,
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 maxLines: 4,
 overflow: TextOverflow.ellipsis,
 textAlign: TextAlign.center,
 ),
 ),
 ),

 SizedBox(height: SpacingTokens.lg),

 // Tags
 if (document.tags.isNotEmpty) ...[
 Wrap(
 spacing: SpacingTokens.xs,
 runSpacing: SpacingTokens.xs,
 alignment: WrapAlignment.center,
 children: document.tags.take(3).map((tag) {
 return Container(
 padding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.sm,
 vertical: SpacingTokens.xs,
 ),
 decoration: BoxDecoration(
 color: colors.surfaceVariant,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Text(
 tag,
 style: TextStyles.caption.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 );
 }).toList(),
 ),
 SizedBox(height: SpacingTokens.sm),
 ],

 // Footer with timestamp
 Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Text(
 'Updated ${_formatDate(document.updatedAt)}',
 style: TextStyles.caption.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 if (document.isActive) ...[
 SizedBox(width: SpacingTokens.sm),
 Container(
 width: 6,
 height: 6,
 decoration: BoxDecoration(
 color: colors.success,
 shape: BoxShape.circle,
 ),
 ),
 ],
 ],
 ),
 ],
 ),
 );
 }

 Color _getTypeColor(ContextType type, ThemeColors colors) {
 switch (type) {
 case ContextType.documentation:
 return colors.primary;
 case ContextType.codebase:
 return colors.info;
 case ContextType.guidelines:
 return colors.warning;
 case ContextType.examples:
 return colors.success;
 case ContextType.knowledge:
 return colors.primary.withValues(alpha: 0.8);
 case ContextType.custom:
 return colors.onSurfaceVariant;
 }
 }

 void _handleMenuAction(String action, BuildContext context) {
 switch (action) {
 case 'edit':
 _showEditDialog(context);
 break;
 case 'assign':
 onAssignToAgent(document.id);
 break;
 case 'delete':
 _showDeleteDialog(context);
 break;
 }
 }

 void _showEditDialog(BuildContext context) {
 showDialog(
 context: context,
 builder: (context) => AlertDialog(
 backgroundColor: ThemeColors(context).surface,
 title: Text(
 'Edit Document',
 style: TextStyles.cardTitle.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 content: Text(
 'Edit functionality will be implemented here',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.of(context).pop(),
 child: Text('Cancel'),
 ),
 ],
 ),
 );
 }

 void _showDeleteDialog(BuildContext context) {
 showDialog(
 context: context,
 builder: (context) => AlertDialog(
 backgroundColor: ThemeColors(context).surface,
 title: Text(
 'Delete Document',
 style: TextStyles.cardTitle.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 content: Text(
 'Are you sure you want to delete "${document.title}"? This action cannot be undone.',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.of(context).pop(),
 child: Text('Cancel'),
 ),
 TextButton(
 onPressed: () {
 Navigator.of(context).pop();
 onDelete(document.id);
 },
 style: TextButton.styleFrom(
 foregroundColor: ThemeColors(context).error,
 ),
 child: const Text('Delete'),
 ),
 ],
 ),
 );
 }

 String _formatDate(DateTime date) {
 final now = DateTime.now();
 final difference = now.difference(date);

 if (difference.inDays > 7) {
 return '${date.day}/${date.month}/${date.year}';
 } else if (difference.inDays > 0) {
 return '${difference.inDays}d ago';
 } else if (difference.inHours > 0) {
 return '${difference.inHours}h ago';
 } else if (difference.inMinutes > 0) {
 return '${difference.inMinutes}m ago';
 } else {
 return 'Just now';
 }
 }
}
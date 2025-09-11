import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../context/data/models/context_document.dart';
import '../../../context/presentation/providers/context_provider.dart';

/// Modal for browsing and managing existing context documents
class DocumentBrowserModal extends ConsumerStatefulWidget {
  final Function(String) onAddContext;
  
  const DocumentBrowserModal({
    super.key,
    required this.onAddContext,
  });

  @override
  ConsumerState<DocumentBrowserModal> createState() => _DocumentBrowserModalState();
}

class _DocumentBrowserModalState extends ConsumerState<DocumentBrowserModal> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final contextDocuments = ref.watch(contextDocumentsWithVectorProvider);
    
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Browse Context Library',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.lg),
            
            // Search field
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search context documents...',
                prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            
            // Documents list
            Expanded(
              child: contextDocuments.when(
                data: (documents) {
                  final filteredDocs = documents.where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    return doc.title.toLowerCase().contains(query) ||
                           doc.content.toLowerCase().contains(query) ||
                           doc.tags.any((tag) => tag.toLowerCase().contains(query));
                  }).toList();
                  
                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty 
                          ? 'No context documents found'
                          : 'No documents match your search',
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return _buildDocumentCard(doc, colors);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading documents: $error',
                    style: TextStyles.bodyMedium.copyWith(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDocumentCard(ContextDocument doc, ThemeColors colors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.title,
                        style: TextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.type.displayName,
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add button
                    IconButton(
                      onPressed: () {
                        widget.onAddContext(doc.id);
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.add, color: colors.primary),
                      tooltip: 'Add to chat',
                    ),
                    // Delete button
                    IconButton(
                      onPressed: () {
                        print('🖱️ Delete button pressed for document: ${doc.id}');
                        _showDeleteConfirmation(doc);
                      },
                      icon: Icon(Icons.delete_outline, color: colors.onSurfaceVariant),
                      tooltip: 'Delete document',
                    ),
                  ],
                ),
              ],
            ),
            if (doc.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                doc.content.length > 150 
                  ? '${doc.content.substring(0, 150)}...'
                  : doc.content,
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (doc.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: doc.tags.take(3).map((tag) => Chip(
                  label: Text(
                    tag,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  backgroundColor: colors.primary.withOpacity(0.1),
                  side: BorderSide.none,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(ContextDocument doc) {
    final colors = ThemeColors(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Delete Context Document',
          style: TextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${doc.title}"? This action cannot be undone.',
          style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              print('✅ Delete confirmation button pressed for: ${doc.id}');
              Navigator.of(context).pop(); // Close confirmation dialog
              
              try {
                print('🔍 Getting delete action provider...');
                final deleteAction = ref.read(deleteContextDocumentActionProvider);
                print('🚀 Calling delete action for: ${doc.id}');
                await deleteAction(doc.id);
                print('✅ Delete action completed successfully');
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Context document "${doc.title}" deleted'),
                      backgroundColor: colors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Delete action failed with error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete document: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyles.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
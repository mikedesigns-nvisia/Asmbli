import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/design_system/components/asmbli_card_enhanced.dart';
import '../../data/models/context_document.dart';
import '../providers/context_provider.dart';
import '../../data/repositories/context_repository.dart';
import '../../../../core/services/vector_database_service.dart';
import '../../../../core/vector/models/vector_models.dart';
import 'context_document_card.dart';
import 'context_creation_flow.dart';

class ContextHubWidget extends ConsumerStatefulWidget {
  const ContextHubWidget({super.key});

  @override
  ConsumerState<ContextHubWidget> createState() => _ContextHubWidgetState();
}

class _ContextHubWidgetState extends ConsumerState<ContextHubWidget> {
  ContextHubCategory _selectedCategory = ContextHubCategory.all;
  final ScrollController _categoryScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return AsmblCardEnhanced.outlined(
      isInteractive: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Knowledge Library',
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.componentSpacing),
          
          // Context Library Content
          _buildContextLibraryContent(colors),
        ],
      ),
    );
  }

  Widget _buildContextLibraryContent(ThemeColors colors) {
    final contextDocuments = ref.watch(contextDocumentsWithVectorProvider);
    final vectorStats = ref.watch(vectorDatabaseProvider);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vector Database Stats - only show when there are documents
          contextDocuments.when(
            data: (documents) {
              if (documents.isNotEmpty) {
                return Column(
                  children: [
                    vectorStats.when(
                      data: (vectorDB) => FutureBuilder<VectorDatabaseStats>(
                        future: vectorDB.getStats(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final stats = snapshot.data!;
                            return Container(
                              padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.storage, size: 16, color: colors.primary),
                                  const SizedBox(width: SpacingTokens.iconSpacing),
                                  Text(
                                    'Vector DB: ${stats.totalDocuments} docs, ${stats.totalChunks} chunks',
                                    style: TextStyles.bodySmall.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: SpacingTokens.componentSpacing),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Context Documents
          contextDocuments.when(
            data: (documents) {
              if (documents.isEmpty) {
                return Column(
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 32,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: SpacingTokens.iconSpacing),
                    Text(
                      'No context documents available',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Documents (${documents.length})',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.iconSpacing),
                  _buildDocumentsGrid(documents, colors),
                ],
              );
            },
            loading: () => Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
                const SizedBox(width: SpacingTokens.iconSpacing),
                Text(
                  'Loading context documents...',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            error: (error, _) => Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 32,
                  color: colors.error,
                ),
                const SizedBox(height: SpacingTokens.iconSpacing),
                Text(
                  'Error loading context documents',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(List<ContextDocument> documents, ThemeColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double aspectRatio = 0.7; // Slightly taller for enhanced cards
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: constraints.maxWidth / 4,
            crossAxisSpacing: SpacingTokens.md,
            mainAxisSpacing: SpacingTokens.md,
            childAspectRatio: aspectRatio,
          ),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            return ContextDocumentCard(
              document: doc,
              onEdit: _handleEditDocument,
              onDelete: _handleDeleteDocument,
              onAssignToAgent: _handleAssignToAgent,
              onPreview: () => _handlePreviewDocument(doc),
            );
          },
        );
      },
    );
  }

  void _handleEditDocument(ContextDocument document) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ContextCreationFlow(
          initialDocument: document,
          onSave: (updatedDocument) async {
            Navigator.of(context).pop();
            try {
              final notifier = ref.read(contextDocumentNotifierProvider.notifier);
              await notifier.updateDocument(updatedDocument);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Context document "${updatedDocument.title}" updated successfully'),
                    backgroundColor: ThemeColors(context).success,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update context document: $e'),
                    backgroundColor: ThemeColors(context).error,
                  ),
                );
              }
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _handleDeleteDocument(String documentId) async {
    print('🎯 Hub widget delete called for: $documentId');
    try {
      final deleteAction = ref.read(deleteContextDocumentActionProvider);
      await deleteAction(documentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      print('❌ Hub widget delete failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete document: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  void _handleAssignToAgent(String documentId) {
    // Show agent selection dialog or navigate to assignment screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assign document $documentId to agent'),
        backgroundColor: ThemeColors(context).info,
      ),
    );
  }

  void _handlePreviewDocument(ContextDocument document) {
    // Show preview dialog with document content
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ThemeColors(context).surface,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(SpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getDocumentIcon(document.type),
                    color: ThemeColors(context).primary,
                  ),
                  SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      document.title,
                      style: TextStyles.pageTitle.copyWith(
                        color: ThemeColors(context).onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: ThemeColors(context).onSurfaceVariant),
                  ),
                ],
              ),
              SizedBox(height: SpacingTokens.lg),
              Container(
                padding: EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: ThemeColors(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  document.type.displayName,
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: SpacingTokens.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    document.content,
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon(ContextType type) {
    switch (type) {
      case ContextType.documentation:
        return Icons.description_outlined;
      case ContextType.codebase:
        return Icons.code;
      case ContextType.guidelines:
        return Icons.rule_outlined;
      case ContextType.examples:
        return Icons.lightbulb_outlined;
      case ContextType.knowledge:
        return Icons.psychology_outlined;
      case ContextType.custom:
        return Icons.settings;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
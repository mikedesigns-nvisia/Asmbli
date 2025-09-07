import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../data/models/context_document.dart';
import '../providers/context_provider.dart';
import '../../data/repositories/context_repository.dart';
import '../../../../core/services/vector_database_service.dart';
import '../../../../core/vector/models/vector_models.dart';

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
          // Vector Database Stats
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
                  ...documents.take(3).map((doc) => Container(
                    margin: const EdgeInsets.only(bottom: SpacingTokens.iconSpacing),
                    padding: const EdgeInsets.all(SpacingTokens.iconSpacing),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getDocumentIcon(doc.type),
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: SpacingTokens.iconSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.title,
                                style: TextStyles.bodySmall.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                doc.type.displayName,
                                style: TextStyles.caption.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  if (documents.length > 3) ...[
                    const SizedBox(height: SpacingTokens.iconSpacing),
                    Text(
                      '... and ${documents.length - 3} more',
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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
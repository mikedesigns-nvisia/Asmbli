import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/context_provider.dart';
import '../../data/models/context_document.dart';

class ContextAssignmentModal extends ConsumerStatefulWidget {
  final String agentId;
  final String agentName;

  const ContextAssignmentModal({
    super.key,
    required this.agentId,
    required this.agentName,
  });

  @override
  ConsumerState<ContextAssignmentModal> createState() => _ContextAssignmentModalState();
}

class _ContextAssignmentModalState extends ConsumerState<ContextAssignmentModal> {
  final Set<String> selectedDocuments = {};

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final contextDocuments = ref.watch(contextDocumentsProvider);
    final assignedContext = ref.watch(contextForAgentProvider(widget.agentId));

    return Dialog(
      backgroundColor: colors.surface,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Context to Agent',
                      style: TextStyles.pageTitle.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      'Agent: ${widget.agentName}',
                      style: TextStyles.bodyLarge.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: SpacingTokens.xl),

            // Current assignments
            assignedContext.when(
              data: (assignments) => assignments.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Currently Assigned Context:',
                          style: TextStyles.sectionTitle.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        ...assignments.map((doc) => Padding(
                              padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                              child: Container(
                                padding: const EdgeInsets.all(SpacingTokens.sm),
                                decoration: BoxDecoration(
                                  color: colors.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: colors.success,
                                    ),
                                    const SizedBox(width: SpacingTokens.sm),
                                    Expanded(
                                      child: Text(
                                        doc.title,
                                        style: TextStyles.bodyMedium.copyWith(
                                          color: colors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: SpacingTokens.lg),
                      ],
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Available documents
            Text(
              'Available Context Documents:',
              style: TextStyles.sectionTitle.copyWith(
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: SpacingTokens.sm),

            // Document list
            Expanded(
              child: contextDocuments.when(
                data: (documents) => documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 48,
                              color: colors.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            Text(
                              'No context documents available',
                              style: TextStyles.bodyLarge.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final document = documents[index];
                          final isSelected = selectedDocuments.contains(document.id);
                          
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  selectedDocuments.add(document.id);
                                } else {
                                  selectedDocuments.remove(document.id);
                                }
                              });
                            },
                            title: Text(
                              document.title,
                              style: TextStyles.bodyMedium.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document.type.displayName,
                                  style: TextStyles.caption.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: SpacingTokens.xs),
                                Text(
                                  document.content.length > 100
                                      ? '${document.content.substring(0, 100)}...'
                                      : document.content,
                                  style: TextStyles.caption.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: colors.primary,
                          );
                        },
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading documents: $error',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: SpacingTokens.xl),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AsmblButton.secondary(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: SpacingTokens.md),
                AsmblButton.primary(
                  text: 'Assign Selected',
                  onPressed: selectedDocuments.isEmpty
                      ? null
                      : () => _assignSelectedDocuments(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _assignSelectedDocuments() async {
    try {
      final repository = ref.read(contextRepositoryProvider);
      
      for (final documentId in selectedDocuments) {
        await repository.assignDocumentToAgent(
          agentId: widget.agentId,
          contextDocumentId: documentId,
        );
      }

      // Refresh the assigned context
      ref.invalidate(contextForAgentProvider(widget.agentId));
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully assigned ${selectedDocuments.length} context document(s) to ${widget.agentName}',
            ),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign context: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }
}
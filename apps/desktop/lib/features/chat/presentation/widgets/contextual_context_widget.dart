import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/design_system/design_system.dart';
import 'document_browser_modal.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../context/data/models/context_document.dart';
import '../../../context/data/repositories/context_repository.dart';
import '../../../context/presentation/providers/context_provider.dart';
import '../../../../core/utils/file_validation_utils.dart';
import '../../../../core/services/desktop/desktop_service_provider.dart';

/// Provider for session context state per conversation
final sessionContextProvider = StateProvider.family<List<String>, String?>((ref, conversationId) => []);

/// Provider to show/hide context prompt
final showContextPromptProvider = StateProvider.family<bool, String?>((ref, conversationId) => true);

/// Main contextual input area that replaces the standard chat input
class ContextualInputArea extends ConsumerStatefulWidget {
  final TextEditingController messageController;
  final VoidCallback onSendMessage;
  final bool isLoading;

  const ContextualInputArea({
    super.key,
    required this.messageController,
    required this.onSendMessage,
    required this.isLoading,
  });

  @override
  ConsumerState<ContextualInputArea> createState() => _ContextualInputAreaState();
}

class _ContextualInputAreaState extends ConsumerState<ContextualInputArea> {
  @override
  Widget build(BuildContext context) {
    final selectedConversationId = ref.watch(selectedConversationIdProvider);
    final sessionContext = ref.watch(sessionContextProvider(selectedConversationId));
    final showContextPrompt = ref.watch(showContextPromptProvider(selectedConversationId));
    final hasConversation = selectedConversationId != null;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context indicator bar (when context is added and has conversation)
          if (hasConversation && sessionContext.isNotEmpty)
            _buildContextIndicatorBar(context, sessionContext, selectedConversationId),

          // Context prompt bar (only show when has conversation, no context, and prompt not dismissed)
          if (hasConversation && sessionContext.isEmpty && showContextPrompt)
            _buildContextPromptBar(context, selectedConversationId),

          // Space between context bars and input
          if (hasConversation && (sessionContext.isNotEmpty || (sessionContext.isEmpty && showContextPrompt)))
            const SizedBox(height: SpacingTokens.sm),

          // Main input area
          _buildMainInputArea(context),
        ],
      ),
    );
  }

  Widget _buildContextIndicatorBar(BuildContext context, List<String> contextIds, String? conversationId) {
    final contextDocuments = ref.watch(contextDocumentsWithVectorProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ThemeColors(context).primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: ThemeColors(context).primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 16,
                color: ThemeColors(context).primary,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: Text(
                  'Context: ${contextIds.length} item${contextIds.length == 1 ? '' : 's'}',
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Add more context button
              TextButton.icon(
                onPressed: () => _showContextFlow(context),
                icon: Icon(
                  Icons.add,
                  size: 14,
                  color: ThemeColors(context).primary,
                ),
                label: Text(
                  'Add more',
                  style: TextStyles.bodySmall.copyWith(
                    color: ThemeColors(context).primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              // Clear all context button
              IconButton(
                onPressed: () => _clearSessionContext(conversationId),
                icon: Icon(
                  Icons.clear_all,
                  size: 16,
                  color: ThemeColors(context).primary,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: 'Clear all context',
              ),
            ],
          ),
          
          // Context chips
          if (contextIds.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.xs),
            contextDocuments.when(
              data: (documents) {
                final documentMap = {for (var doc in documents) doc.id: doc};
                return Wrap(
                  spacing: SpacingTokens.xs,
                  runSpacing: SpacingTokens.xs,
                  children: contextIds.map((contextId) {
                    final document = documentMap[contextId];
                    return _buildContextChip(
                      context,
                      contextId,
                      document?.title ?? 'Unknown Document',
                      conversationId,
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 20,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => Text(
                'Error loading context details',
                style: TextStyles.bodySmall.copyWith(
                  color: ThemeColors(context).onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildContextChip(BuildContext context, String contextId, String title, String? conversationId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeColors(context).surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: ThemeColors(context).border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          GestureDetector(
            onTap: () => _removeContextFromSession(contextId, conversationId),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(
                Icons.close,
                size: 12,
                color: ThemeColors(context).onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _removeContextFromSession(String contextId, String? conversationId) {
    if (conversationId != null) {
      ref.read(sessionContextProvider(conversationId).notifier).update((state) {
        return state.where((id) => id != contextId).toList();
      });
      
      // Show context prompt again if no context remains
      final remainingContext = ref.read(sessionContextProvider(conversationId));
      if (remainingContext.isEmpty) {
        ref.read(showContextPromptProvider(conversationId).notifier).state = true;
      }
    }
  }

  Widget _buildContextPromptBar(BuildContext context, String? conversationId) {
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
            child: Text(
              'Have documents or context to share?',
              style: TextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showContextFlow(context),
            child: Text(
              'Add context',
              style: TextStyles.bodySmall.copyWith(
                color: ThemeColors(context).primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          TextButton(
            onPressed: () => _dismissContextPrompt(conversationId),
            child: Text(
              'Just chat',
              style: TextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInputArea(BuildContext context) {
    final theme = Theme.of(context);
    final selectedConversationId = ref.watch(selectedConversationIdProvider);
    final hasConversation = selectedConversationId != null;

    // Centered design when no conversation (Gemini-style)
    // Bottom-aligned when conversation exists
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800), // Max width for centered input
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(hasConversation ? BorderRadiusTokens.sm : BorderRadiusTokens.xl),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
                final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

                if (isEnterPressed && isShiftPressed) {
                  widget.onSendMessage();
                  return;
                }
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Context attachment button
                Padding(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  child: IconButton(
                    onPressed: () => _showContextFlow(context),
                    icon: Icon(
                      Icons.attach_file,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    tooltip: 'Add context',
                  ),
                ),

                // Main text input - RESPONSIVE, expands with content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
                    child: TextField(
                      controller: widget.messageController,
                      decoration: InputDecoration(
                        hintText: hasConversation
                            ? 'Type your message... (Shift+Enter to send)'
                            : 'Ask anything...',
                        hintStyle: GoogleFonts.fustat(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: hasConversation ? 14 : 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                          vertical: SpacingTokens.md,
                        ),
                      ),
                      style: GoogleFonts.fustat(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      maxLines: null, // CRITICAL: null allows unlimited expansion
                      minLines: 1, // Start with 1 line
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),

                // Send button
                Padding(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: widget.messageController.text.trim().isNotEmpty && !widget.isLoading
                          ? ThemeColors(context).primary
                          : theme.colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: IconButton(
                      onPressed: widget.messageController.text.trim().isNotEmpty && !widget.isLoading
                          ? widget.onSendMessage
                          : null,
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward,
                              size: 20,
                              color: widget.messageController.text.trim().isNotEmpty && !widget.isLoading
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextFlow(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContextFlowModal(
        onContextAdded: (contextId) => _addToSessionContext(contextId),
      ),
    );
  }

  void _addToSessionContext(String contextId) {
    final conversationId = ref.read(selectedConversationIdProvider);
    if (conversationId != null) {
      ref.read(sessionContextProvider(conversationId).notifier).update((state) {
        if (!state.contains(contextId)) {
          return [...state, contextId];
        }
        return state;
      });
      
      // Hide context prompt once context is added
      ref.read(showContextPromptProvider(conversationId).notifier).state = false;
    }
  }

  void _clearSessionContext(String? conversationId) {
    if (conversationId != null) {
      ref.read(sessionContextProvider(conversationId).notifier).state = [];
      // Show context prompt again when context is cleared
      ref.read(showContextPromptProvider(conversationId).notifier).state = true;
    }
  }

  void _dismissContextPrompt(String? conversationId) {
    // Close any open modals/dialogs first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    // Then dismiss the context prompt
    if (conversationId != null) {
      ref.read(showContextPromptProvider(conversationId).notifier).state = false;
    }
  }
}

/// Modal for context addition flow
class ContextFlowModal extends ConsumerStatefulWidget {
  final Function(String) onContextAdded;

  const ContextFlowModal({
    super.key,
    required this.onContextAdded,
  });

  @override
  ConsumerState<ContextFlowModal> createState() => _ContextFlowModalState();
}

class _ContextFlowModalState extends ConsumerState<ContextFlowModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: ThemeColors(context).surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          border: Border.all(color: ThemeColors(context).border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: ThemeColors(context).surface.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(BorderRadiusTokens.lg),
                  topRight: Radius.circular(BorderRadiusTokens.lg),
                ),
                border: Border(
                  bottom: BorderSide(color: ThemeColors(context).border),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: ThemeColors(context).primary, size: 24),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Context',
                          style: TextStyles.pageTitle.copyWith(
                            color: ThemeColors(context).onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share documents or information to help with your conversation',
                          style: TextStyles.bodySmall.copyWith(
                            color: ThemeColors(context).onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                children: [
                  // Upload files option
                  _buildContextOption(
                    icon: Icons.upload_file,
                    title: 'Upload Files',
                    description: 'PDF, DOC, TXT, and more',
                    onTap: () => _handleFileUpload(),
                  ),
                  
                  const SizedBox(height: SpacingTokens.md),
                  
                  // Write text option
                  _buildContextOption(
                    icon: Icons.edit_note,
                    title: 'Write Text',
                    description: 'Add custom text or notes',
                    onTap: () => _showTextInput(),
                  ),
                  
                  const SizedBox(height: SpacingTokens.md),
                  
                  // Browse library option
                  _buildContextOption(
                    icon: Icons.library_books,
                    title: 'Browse Library',
                    description: 'Choose from saved documents',
                    onTap: () => _showDocumentBrowser(),
                  ),
                  
                  const SizedBox(height: SpacingTokens.md),
                  
                  // Just chat option (dismiss modal)
                  _buildContextOption(
                    icon: Icons.chat_bubble_outline,
                    title: 'Just Chat',
                    description: 'Continue without adding context',
                    onTap: () => _dismissModalAndPrompt(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          border: Border.all(color: ThemeColors(context).border),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: ThemeColors(context).primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: Icon(
                icon,
                color: ThemeColors(context).primary,
                size: 24,
              ),
            ),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.bodyMedium.copyWith(
                      color: ThemeColors(context).onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyles.bodySmall.copyWith(
                      color: ThemeColors(context).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ThemeColors(context).onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFileUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'json', 'csv', 'docx', 'doc', 'rtf', 'xml'],
        dialogTitle: 'Select Context Documents',
      );

      if (result != null && result.files.isNotEmpty) {
        Navigator.of(context).pop(); // Close modal
        
        final validationResult = FileValidationUtils.validateContextFiles(result.files);
        
        if (validationResult.isValid) {
          await _processUploadedFiles(result.files);
        } else {
          _showError(validationResult.error ?? 'Validation failed');
        }
      }
    } catch (e) {
      _showError('Failed to open file picker: ${e.toString()}');
    }
  }

  Future<void> _processUploadedFiles(List<PlatformFile> files) async {
    try {
      final repository = ref.read(contextRepositoryProvider);
      int successCount = 0;
      
      for (final file in files) {
        if (file.bytes != null || file.path != null) {
          String content = '';
          
          // Read file content
          if (file.bytes != null) {
            content = String.fromCharCodes(file.bytes!);
          } else if (file.path != null) {
            final fileSystemService = ref.read(fileSystemServiceProvider);
            content = await fileSystemService.readFile(file.path!);
          }
          
          if (content.trim().isEmpty) continue;
          
          final document = await repository.createDocument(
            title: file.name,
            content: content,
            type: _getContextTypeFromExtension(file.extension ?? ''),
            tags: ['uploaded', 'session'],
            metadata: {
              'uploadedAt': DateTime.now().toIso8601String(),
              'fileSize': file.size,
              'fileName': file.name,
              'fileExtension': file.extension,
            },
          );
          
          widget.onContextAdded(document.id);
          successCount++;
        }
      }
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully uploaded $successCount document${successCount == 1 ? '' : 's'}'),
            backgroundColor: ThemeColors(context).primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to process uploaded files: ${e.toString()}');
    }
  }

  void _showTextInput() {
    Navigator.of(context).pop(); // Close current modal
    
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: ThemeColors(context).surface,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            border: Border.all(color: ThemeColors(context).border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: ThemeColors(context).surface.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(BorderRadiusTokens.lg),
                    topRight: Radius.circular(BorderRadiusTokens.lg),
                  ),
                  border: Border(
                    bottom: BorderSide(color: ThemeColors(context).border),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: ThemeColors(context).primary, size: 24),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: Text(
                        'Add Text Context',
                        style: TextStyles.pageTitle.copyWith(
                          color: ThemeColors(context).onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: ThemeColors(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter a descriptive title...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                          ),
                        ),
                        style: GoogleFonts.fustat(),
                      ),
                      
                      const SizedBox(height: SpacingTokens.md),
                      
                      Expanded(
                        child: TextField(
                          controller: contentController,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            labelText: 'Content',
                            hintText: 'Enter your text content here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                            ),
                            alignLabelWithHint: true,
                          ),
                          style: GoogleFonts.fustat(),
                        ),
                      ),
                      
                      const SizedBox(height: SpacingTokens.lg),
                      
                      Row(
                        children: [
                          Expanded(
                            child: AsmblButton.secondary(
                              text: 'Cancel',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.sm),
                          Expanded(
                            child: AsmblButton.primary(
                              text: 'Add Context',
                              onPressed: () => _createTextContext(
                                titleController.text,
                                contentController.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      titleController.dispose();
      contentController.dispose();
    });
  }

  Future<void> _createTextContext(String title, String content) async {
    if (title.trim().isEmpty || content.trim().isEmpty) {
      _showError('Please provide both title and content');
      return;
    }
    
    try {
      final repository = ref.read(contextRepositoryProvider);
      
      final document = await repository.createDocument(
        title: title.trim(),
        content: content.trim(),
        type: ContextType.custom,
        tags: ['manual', 'session'],
        metadata: {
          'createdAt': DateTime.now().toIso8601String(),
          'source': 'manual_input',
        },
      );
      
      widget.onContextAdded(document.id);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text context "$title" added successfully'),
            backgroundColor: ThemeColors(context).primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to create text context: ${e.toString()}');
    }
  }

  void _showDocumentBrowser() {
    Navigator.of(context).pop(); // Close current modal
    
    showDialog(
      context: context,
      builder: (context) => DocumentBrowserModal(
        onAddContext: (documentId) => widget.onContextAdded(documentId),
      ),
    );
  }

  ContextType _getContextTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'md':
      case 'txt':
      case 'rtf':
        return ContextType.documentation;
      case 'json':
      case 'xml':
        return ContextType.codebase;
      case 'pdf':
      case 'docx':
      case 'doc':
        return ContextType.knowledge;
      case 'csv':
        return ContextType.examples;
      default:
        return ContextType.custom;
    }
  }

  void _showError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _dismissModalAndPrompt() {
    // Close the modal
    Navigator.of(context).pop();
    
    // Find and dismiss the context prompt using a global approach
    // This ensures the prompt is dismissed regardless of context hierarchy
    final contextWidget = context.findAncestorStateOfType<_ContextualInputAreaState>();
    if (contextWidget != null) {
      final selectedConversationId = contextWidget.ref.read(selectedConversationIdProvider);
      if (selectedConversationId != null) {
        contextWidget.ref.read(showContextPromptProvider(selectedConversationId).notifier).state = false;
      }
    }
  }
}
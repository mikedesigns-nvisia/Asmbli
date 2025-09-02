import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';

/// Editable conversation title widget with click-to-edit functionality
class EditableConversationTitle extends ConsumerStatefulWidget {
  final Conversation conversation;
  final TextStyle? style;
  
  const EditableConversationTitle({
    super.key,
    required this.conversation,
    this.style,
  });

  @override
  ConsumerState<EditableConversationTitle> createState() => _EditableConversationTitleState();
}

class _EditableConversationTitleState extends ConsumerState<EditableConversationTitle> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _displayTitle = '';
  
  @override
  void initState() {
    super.initState();
    _displayTitle = widget.conversation.title;
    _controller = TextEditingController(text: _displayTitle);
    _focusNode = FocusNode();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isEditing) {
      return _buildEditMode(theme);
    } else {
      return _buildDisplayMode(theme);
    }
  }

  Widget _buildDisplayMode(ThemeData theme) {
    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _displayTitle,
                style: widget.style ??
                    GoogleFonts.fustat(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditMode(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ThemeColors(context).primary,
          width: 2,
        ),
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: widget.style ??
                  GoogleFonts.fustat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                hintText: 'Enter conversation title',
                hintStyle: GoogleFonts.fustat(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveTitle(),
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              // Save button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _isSaving ? null : _saveTitle,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ThemeColors(context).success,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.check,
                            size: 18,
                            color: ThemeColors(context).success,
                          ),
                  ),
                ),
              ),
              
              // Cancel button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _isSaving ? null : _cancelEditing,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startEditing() {
    if (_isSaving) return;
    
    setState(() {
      _isEditing = true;
      _controller.text = _displayTitle;
    });
    
    // Focus and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _cancelEditing() {
    if (_isSaving) return;
    
    setState(() {
      _isEditing = false;
      _controller.text = _displayTitle; // Reset to current title
    });
  }

  void _saveTitle() async {
    if (_isSaving) return;
    
    final newTitle = _controller.text.trim();
    
    // Validate title
    if (newTitle.isEmpty) {
      _showMessage('Title cannot be empty', isError: true);
      return;
    }
    
    if (newTitle == _displayTitle) {
      // No change, just exit editing mode
      setState(() {
        _isEditing = false;
      });
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Get the conversation service directly
      final conversationService = ref.read(conversationServiceProvider);
      
      // Create updated conversation
      final updatedConversation = widget.conversation.copyWith(
        title: newTitle,
        lastModified: DateTime.now(),
      );
      
      // Save the conversation
      await conversationService.updateConversation(updatedConversation);
      
      // Update local state immediately
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _displayTitle = newTitle; // Update displayed title immediately
      });
      
      // Force refresh providers after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        ref.invalidate(conversationProvider(widget.conversation.id));
        ref.invalidate(conversationsProvider);
      });
      
      // Show success feedback
      _showMessage('Conversation renamed successfully', isError: false);
      
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showMessage('Failed to save title: ${e.toString()}', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.fustat(),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? ThemeColors(context).error
            : ThemeColors(context).success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
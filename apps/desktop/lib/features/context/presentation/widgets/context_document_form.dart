import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/context_document.dart';

class ContextDocumentForm extends StatefulWidget {
  final ContextDocument? initialDocument;
  final Function(ContextDocument) onSave;
  final VoidCallback onCancel;

  const ContextDocumentForm({
    super.key,
    this.initialDocument,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ContextDocumentForm> createState() => _ContextDocumentFormState();
}

class _ContextDocumentFormState extends State<ContextDocumentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  ContextType _selectedType = ContextType.documentation;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    
    if (widget.initialDocument != null) {
      final doc = widget.initialDocument!;
      _titleController.text = doc.title;
      _contentController.text = doc.content;
      _selectedType = doc.type;
      _tags = List.from(doc.tags);
      _tagsController.text = _tags.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialDocument != null ? 'Edit Document' : 'Create Document',
                style: TextStyles.sectionTitle.copyWith(
                  color: colors.onSurface,
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: Icon(
                  Icons.close,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.xl),

          // Title Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter document title...',
                  hintStyle: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: colors.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.lg),

          // Type Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              DropdownButtonFormField<ContextType>(
                value: _selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                dropdownColor: colors.surface,
                items: ContextType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.displayName,
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.lg),

          // Tags Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tags',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                'Separate tags with commas',
                style: TextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: 'api, documentation, reference...',
                  hintStyle: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: colors.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                onChanged: (value) {
                  _tags = value
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList();
                },
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.lg),

          // Content Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              TextFormField(
                controller: _contentController,
                maxLines: 12,
                decoration: InputDecoration(
                  hintText: 'Enter the context content that will be provided to agents...',
                  hintStyle: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: colors.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                  alignLabelWithHint: true,
                ),
                style: TextStyles.bodyMedium.copyWith(color: colors.onSurface),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Content is required';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.xl),

          // Form Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AsmblButtonEnhanced.secondary(
                text: 'Cancel',
                onPressed: widget.onCancel,
                size: AsmblButtonSize.medium,
              ),
              const SizedBox(width: SpacingTokens.md),
              AsmblButtonEnhanced.accent(
                text: widget.initialDocument != null ? 'Update' : 'Create',
                onPressed: _handleSave,
                size: AsmblButtonSize.medium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      final document = ContextDocument(
        id: widget.initialDocument?.id ?? '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        tags: _tags,
        createdAt: widget.initialDocument?.createdAt ?? now,
        updatedAt: now,
        isActive: widget.initialDocument?.isActive ?? true,
        metadata: widget.initialDocument?.metadata ?? {},
      );

      widget.onSave(document);
    }
  }
}
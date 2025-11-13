import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// Advanced context dropdown with file uploads, templates, and smart suggestions
class DesignContextDropdown extends ConsumerStatefulWidget {
  final String label;
  final String contextType;
  final List<ContextItem> items;
  final Function(ContextItem) onItemSelected;
  final Function(ContextItem) onItemAdded;
  final bool allowCustom;
  final bool allowFileUpload;
  
  const DesignContextDropdown({
    super.key,
    required this.label,
    required this.contextType,
    required this.items,
    required this.onItemSelected,
    required this.onItemAdded,
    this.allowCustom = true,
    this.allowFileUpload = true,
  });

  @override
  ConsumerState<DesignContextDropdown> createState() => _DesignContextDropdownState();
}

class _DesignContextDropdownState extends ConsumerState<DesignContextDropdown> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;
  List<ContextItem> _filteredItems = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _controller.text;
      _filterItems();
    });
  }

  void _onFocusChanged() {
    setState(() {
      _isExpanded = _focusNode.hasFocus;
    });
  }

  void _filterItems() {
    if (_searchText.isEmpty) {
      _filteredItems = widget.items;
    } else {
      _filteredItems = widget.items.where((item) {
        return item.name.toLowerCase().contains(_searchText.toLowerCase()) ||
               item.description.toLowerCase().contains(_searchText.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Search or add ${widget.label.toLowerCase()}...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.allowFileUpload)
                        IconButton(
                          icon: Icon(Icons.upload_file, size: 20),
                          onPressed: _uploadFile,
                          tooltip: 'Upload file',
                        ),
                      if (_searchText.isNotEmpty && widget.allowCustom)
                        IconButton(
                          icon: Icon(Icons.add_circle, color: colors.primary, size: 20),
                          onPressed: _addCustomItem,
                          tooltip: 'Add custom item',
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(SpacingTokens.md),
                ),
              ),
              
              // Dropdown content
              if (_isExpanded) ...[
                Divider(height: 1, color: colors.border),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _buildDropdownContent(colors),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContent(ThemeColors colors) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick templates section
          _buildTemplatesSection(colors),
          
          // Divider
          if (_getTemplatesForType().isNotEmpty && _filteredItems.isNotEmpty)
            Divider(height: 1, color: colors.border),
          
          // Existing items
          if (_filteredItems.isNotEmpty)
            _buildItemsList(colors)
          else if (_searchText.isNotEmpty && widget.allowCustom)
            _buildCreateNewOption(colors)
          else
            _buildEmptyState(colors),
        ],
      ),
    );
  }

  Widget _buildTemplatesSection(ThemeColors colors) {
    final templates = _getTemplatesForType();
    if (templates.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      color: colors.surface.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Templates',
            style: TextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Wrap(
            spacing: SpacingTokens.xs,
            runSpacing: SpacingTokens.xs,
            children: templates.map((template) {
              return _buildTemplateChip(template, colors);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(ContextTemplate template, ThemeColors colors) {
    return Material(
      color: colors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
            vertical: SpacingTokens.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(template.icon, size: 14, color: colors.primary),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                template.name,
                style: TextStyles.caption.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(ThemeColors colors) {
    return Column(
      children: _filteredItems.map((item) {
        return _buildItemTile(item, colors);
      }).toList(),
    );
  }

  Widget _buildItemTile(ContextItem item, ThemeColors colors) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(SpacingTokens.xs),
        decoration: BoxDecoration(
          color: _getTypeColor(item.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        ),
        child: Icon(
          _getTypeIcon(item.type),
          size: 16,
          color: _getTypeColor(item.type),
        ),
      ),
      title: Text(
        item.name,
        style: TextStyles.bodySmall,
      ),
      subtitle: item.description.isNotEmpty 
          ? Text(
              item.description,
              style: TextStyles.caption.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: item.isFile 
          ? Icon(Icons.file_present, size: 16, color: colors.onSurfaceVariant)
          : null,
      onTap: () => _selectItem(item),
    );
  }

  Widget _buildCreateNewOption(ThemeColors colors) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.add_circle_outline, color: colors.primary),
      title: Text(
        'Create "$_searchText"',
        style: TextStyles.bodySmall.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: _addCustomItem,
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 32,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'No items found',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Try typing to search or upload a file',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<ContextTemplate> _getTemplatesForType() {
    final templates = <ContextTemplate>[];
    
    switch (widget.contextType) {
      case 'brand_guidelines':
        templates.addAll([
          ContextTemplate('Logo Usage', Icons.logo_dev, 'Logo specifications and usage rules'),
          ContextTemplate('Brand Colors', Icons.palette, 'Primary and secondary color palette'),
          ContextTemplate('Typography', Icons.text_fields, 'Font families and hierarchy'),
          ContextTemplate('Voice & Tone', Icons.record_voice_over, 'Brand voice guidelines'),
        ]);
        break;
      case 'design_system':
        templates.addAll([
          ContextTemplate('Component Library', Icons.widgets, 'UI component specifications'),
          ContextTemplate('Spacing System', Icons.straighten, 'Spacing and layout rules'),
          ContextTemplate('Grid System', Icons.grid_on, 'Layout grid specifications'),
          ContextTemplate('Icon Library', Icons.apps, 'Icon set and usage guidelines'),
        ]);
        break;
      case 'user_personas':
        templates.addAll([
          ContextTemplate('Primary User', Icons.person, 'Main target user persona'),
          ContextTemplate('Secondary User', Icons.people, 'Secondary user group'),
          ContextTemplate('User Journey', Icons.timeline, 'User experience journey map'),
          ContextTemplate('Pain Points', Icons.warning, 'User frustrations and needs'),
        ]);
        break;
      case 'competitor_analysis':
        templates.addAll([
          ContextTemplate('Direct Competitors', Icons.compare, 'Main competitive landscape'),
          ContextTemplate('Feature Comparison', Icons.compare_arrows, 'Feature analysis matrix'),
          ContextTemplate('Visual Benchmarks', Icons.image, 'Visual design comparison'),
          ContextTemplate('UX Patterns', Icons.pattern, 'Common UX patterns analysis'),
        ]);
        break;
      case 'constraints':
        templates.addAll([
          ContextTemplate('Technical Limits', Icons.code, 'Development constraints'),
          ContextTemplate('Brand Requirements', Icons.business, 'Brand compliance rules'),
          ContextTemplate('Accessibility', Icons.accessibility, 'WCAG compliance requirements'),
          ContextTemplate('Performance', Icons.speed, 'Performance requirements'),
        ]);
        break;
    }
    
    return templates;
  }

  void _useTemplate(ContextTemplate template) {
    final item = ContextItem(
      name: template.name,
      type: widget.contextType,
      description: template.description,
      isTemplate: true,
      content: _generateTemplateContent(template),
    );
    
    widget.onItemAdded(item);
    _controller.clear();
    setState(() {
      _isExpanded = false;
    });
    _focusNode.unfocus();
  }

  void _selectItem(ContextItem item) {
    widget.onItemSelected(item);
    _controller.text = item.name;
    setState(() {
      _isExpanded = false;
    });
    _focusNode.unfocus();
  }

  void _addCustomItem() {
    if (_searchText.isNotEmpty) {
      final item = ContextItem(
        name: _searchText,
        type: widget.contextType,
        description: 'Custom ${widget.contextType.replaceAll('_', ' ')}',
      );
      widget.onItemAdded(item);
      _controller.clear();
      setState(() {
        _isExpanded = false;
      });
      _focusNode.unfocus();
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'svg', 'txt', 'md', 'doc', 'docx'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final item = ContextItem(
          name: file.name,
          type: widget.contextType,
          description: 'Uploaded file (${_formatFileSize(file.size)})',
          isFile: true,
          filePath: file.path,
          content: await _readFileContent(file),
        );
        
        widget.onItemAdded(item);
        _controller.clear();
        setState(() {
          _isExpanded = false;
        });
        _focusNode.unfocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added file: ${file.name}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<String> _readFileContent(PlatformFile file) async {
    if (file.path == null) return '';
    
    try {
      final fileObj = File(file.path!);
      final content = await fileObj.readAsString();
      return content.length > 10000 
          ? content.substring(0, 10000) + '...[truncated]'
          : content;
    } catch (e) {
      return 'Could not read file content: $e';
    }
  }

  String _generateTemplateContent(ContextTemplate template) {
    // Generate template-specific content structure
    switch (template.name) {
      case 'Logo Usage':
        return '''
Logo Guidelines:
- Minimum size: 24px height
- Clear space: 1.5x logo height
- Acceptable formats: SVG, PNG
- Background: Light and dark versions
- Don'ts: Distort, change colors, add effects
        ''';
      case 'Brand Colors':
        return '''
Color Palette:
Primary: #YOUR_PRIMARY_COLOR
Secondary: #YOUR_SECONDARY_COLOR
Accent: #YOUR_ACCENT_COLOR
Neutral: #YOUR_NEUTRAL_COLOR
Background: #YOUR_BG_COLOR
Text: #YOUR_TEXT_COLOR
        ''';
      case 'Component Library':
        return '''
Component Specifications:
- Button styles: Primary, Secondary, Ghost
- Input fields: Text, Select, Textarea
- Cards: Basic, Enhanced, Interactive
- Navigation: Header, Sidebar, Breadcrumbs
- Feedback: Alerts, Toasts, Progress
        ''';
      default:
        return 'Template content for ${template.name}';
    }
  }

  IconData _getTypeIcon(String type) {
    final icons = {
      'brand_guidelines': Icons.business,
      'design_system': Icons.dashboard,
      'user_personas': Icons.person,
      'competitor_analysis': Icons.compare,
      'constraints': Icons.warning,
    };
    return icons[type] ?? Icons.folder;
  }

  Color _getTypeColor(String type) {
    final colors = ThemeColors(context);
    final colorMap = {
      'brand_guidelines': colors.primary,
      'design_system': colors.accent,
      'user_personas': colors.success,
      'competitor_analysis': colors.warning,
      'constraints': colors.error,
    };
    return colorMap[type] ?? colors.onSurfaceVariant;
  }
}

/// Model for context items
class ContextItem {
  final String name;
  final String type;
  final String description;
  final bool isFile;
  final bool isTemplate;
  final String? filePath;
  final String? content;
  final Map<String, dynamic>? metadata;

  ContextItem({
    required this.name,
    required this.type,
    this.description = '',
    this.isFile = false,
    this.isTemplate = false,
    this.filePath,
    this.content,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'isFile': isFile,
      'isTemplate': isTemplate,
      if (filePath != null) 'filePath': filePath,
      if (content != null) 'content': content,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Model for context templates
class ContextTemplate {
  final String name;
  final IconData icon;
  final String description;

  ContextTemplate(this.name, this.icon, this.description);
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../data/models/context_document.dart';
import '../providers/context_provider.dart';
import '../../data/repositories/context_repository.dart';
import '../../data/sample_context_data.dart';

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
 AsmblButtonEnhanced.accent(
 text: 'Add',
 icon: Icons.add,
 onPressed: () => _showCreateDialog(),
 size: AsmblButtonSize.small,
 ),
 ],
 ),
 
 const SizedBox(height: SpacingTokens.elementSpacing),
 
 Text(
 'Add helpful examples and knowledge to make your agent smarter',
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 
 const SizedBox(height: SpacingTokens.sectionSpacing),
 
 // Category Tabs
 _buildCategoryTabs(colors),
 
 const SizedBox(height: SpacingTokens.elementSpacing),
 
 // Sample Context Cards - Make scrollable
 Flexible(
 child: SingleChildScrollView(
 child: _buildSampleContextCards(),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildCategoryTabs(ThemeColors colors) {
 return SingleChildScrollView(
 controller: _categoryScrollController,
 scrollDirection: Axis.horizontal,
 child: Row(
 children: ContextHubCategory.values.asMap().entries.map((entry) {
 final index = entry.key;
 final category = entry.value;
 final isSelected = category == _selectedCategory;
 
 return Padding(
 padding: const EdgeInsets.only(right: SpacingTokens.componentSpacing),
 child: FilterChip(
 label: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 category.icon,
 size: 14,
 color: isSelected ? colors.primary : colors.onSurfaceVariant,
 ),
 const SizedBox(width: 6),
 Text(category.displayName),
 ],
 ),
 selected: isSelected,
 onSelected: (selected) {
 setState(() => _selectedCategory = category);
 _scrollToSelectedChip(index);
 },
 selectedColor: colors.primary.withValues(alpha: 0.1),
 backgroundColor: colors.surface,
 side: BorderSide(
 color: isSelected ? colors.primary : colors.border,
 ),
 labelStyle: TextStyles.bodySmall.copyWith(
 color: isSelected ? colors.primary : colors.onSurfaceVariant,
 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
 ),
 ),
 );
 }).toList(),
 ),
 );
 }

 void _scrollToSelectedChip(int selectedIndex) {
 if (_categoryScrollController.hasClients) {
 // Calculate approximate position of the selected chip
 const chipWidth = 120.0; // Approximate width of each chip including padding
 const spacing = SpacingTokens.componentSpacing;
 
 final targetOffset = (chipWidth + spacing) * selectedIndex;
 final maxScrollExtent = _categoryScrollController.position.maxScrollExtent;
 final viewportWidth = _categoryScrollController.position.viewportDimension;
 
 // Calculate the ideal scroll position to center the selected chip
 double scrollPosition = targetOffset - (viewportWidth / 2) + (chipWidth / 2);
 
 // Clamp the scroll position within valid bounds
 scrollPosition = scrollPosition.clamp(0.0, maxScrollExtent);
 
 _categoryScrollController.animateTo(
 scrollPosition,
 duration: const Duration(milliseconds: 300),
 curve: Curves.easeInOut,
 );
 }
 }

 Widget _buildSampleContextCards() {
 final sampleContexts = _getSampleContextsForCategory(_selectedCategory);
 
 if (sampleContexts.isEmpty) {
 return _buildEmptyState();
 }
 
 return Wrap(
 spacing: SpacingTokens.componentSpacing,
 runSpacing: SpacingTokens.componentSpacing,
 children: sampleContexts.map((sample) {
 return SampleContextCard(
 sample: sample,
 onQuickAdd: () => _handleQuickAdd(sample),
 onPreview: () => _showPreview(sample),
onConfigure: () => _showConfigureDialog(sample),
 );
 }).toList(),
 );
 }

 Widget _buildEmptyState() {
 final colors = ThemeColors(context);
 
 return Center(
 child: Padding(
 padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sectionSpacing),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.category_outlined,
 size: 32,
 color: colors.onSurfaceVariant.withValues(alpha: 0.6),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'No sample contexts in this category yet',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 ),
 );
 }

 List<SampleContext> _getSampleContextsForCategory(ContextHubCategory category) {
 final allSamples = SampleContextData.getAllSamples();
 
 if (category == ContextHubCategory.all) {
 return allSamples;
 }
 
 return allSamples.where((sample) => sample.category == category).toList();
 }

 Future<void> _handleQuickAdd(SampleContext sample) async {
 try {
 await ref.read(contextRepositoryProvider).createDocument(
 title: sample.title,
 content: sample.content,
 type: sample.contextType,
 tags: sample.tags,
 );
 
 ref.invalidate(contextDocumentsProvider);
 
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Row(
 children: [
 const Icon(Icons.check_circle, color: Colors.white, size: 16),
 const SizedBox(width: 4),
 Expanded(
 child: Text(
 'Added "${sample.title}" to your context library',
 style: GoogleFonts.fustat(),
 ),
 ),
 ],
 ),
 backgroundColor: SemanticColors.success,
 behavior: SnackBarBehavior.floating,
 duration: const Duration(seconds: 3),
 ),
 );
 }
 } catch (e) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 'Failed to add context: ${e.toString()}',
 style: GoogleFonts.fustat(),
 ),
 backgroundColor: SemanticColors.error,
 behavior: SnackBarBehavior.floating,
 ),
 );
 }
 }
 }

 void _showPreview(SampleContext sample) {
 showDialog(
 context: context,
 builder: (context) => SampleContextPreviewDialog(sample: sample),
 );
 }

 void _showCreateDialog() {
 // Navigate to create context form or show modal
 // This would integrate with existing context creation flow
 }

 void _showConfigureDialog(SampleContext sample) {
 showDialog(
 context: context,
 builder: (context) => SampleContextConfigureDialog(sample: sample),
 );
 }

 @override
 void dispose() {
 _categoryScrollController.dispose();
 super.dispose();
 }
}

class SampleContextCard extends StatefulWidget {
 final SampleContext sample;
 final VoidCallback onQuickAdd;
 final VoidCallback onPreview;
 final VoidCallback onConfigure;

 const SampleContextCard({
 super.key,
 required this.sample,
 required this.onQuickAdd,
 required this.onPreview,
 required this.onConfigure,
 });

 @override
 State<SampleContextCard> createState() => _SampleContextCardState();
}

class _SampleContextCardState extends State<SampleContextCard> {
 bool _isHovered = false;

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 
 return MouseRegion(
 onEnter: (_) => setState(() => _isHovered = true),
 onExit: (_) => setState(() => _isHovered = false),
 child: SizedBox(
 width: 280,
 child: AsmblCardEnhanced.outlined(
 onTap: widget.onPreview,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 // Header with icon and type
 Row(
 children: [
 Container(
 padding: const EdgeInsets.all(8),
 decoration: BoxDecoration(
 color: colors.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(8),
 ),
 child: Icon(
 widget.sample.icon,
 size: 18,
 color: colors.primary,
 ),
 ),
 const SizedBox(width: 4),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 widget.sample.title,
 style: TextStyles.bodyMedium.copyWith(
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 const SizedBox(height: 2),
 Text(
 widget.sample.contextType.displayName,
 style: TextStyles.caption.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 // Description
 Text(
 widget.sample.description,
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 // Tags
 if (widget.sample.tags.isNotEmpty) ...[
 Wrap(
 spacing: 4,
 runSpacing: 4,
 children: widget.sample.tags.take(3).map((tag) {
 return Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 6,
 vertical: 2,
 ),
 decoration: BoxDecoration(
 color: colors.surfaceVariant.withValues(alpha: 0.5),
 borderRadius: BorderRadius.circular(4),
 ),
 child: Text(
 tag,
 style: TextStyles.caption.copyWith(
 color: colors.onSurfaceVariant,
 fontSize: 10,
 ),
 ),
 );
 }).toList(),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 ],
 
 // Action buttons
 Row(
 children: [
 Expanded(
 child: AsmblButtonEnhanced.accent(
 text: 'Quick Add',
 icon: Icons.add,
 onPressed: widget.onQuickAdd,
 size: AsmblButtonSize.small,
 ),
 ),
 const SizedBox(width: 4),
 AsmblButtonEnhanced.secondary(
 text: '',
 icon: Icons.tune,
 onPressed: widget.onConfigure,
 size: AsmblButtonSize.small,
 ),
 const SizedBox(width: 4),
 AsmblButtonEnhanced.secondary(
 text: '',
 icon: Icons.visibility_outlined,
 onPressed: widget.onPreview,
 size: AsmblButtonSize.small,
 ),
 ],
 ),
 ],
 ),
 ),
 ),
 );
 }
}

class SampleContextPreviewDialog extends StatelessWidget {
 final SampleContext sample;

 const SampleContextPreviewDialog({
 super.key,
 required this.sample,
 });

 @override
 Widget build(BuildContext context) {
 final colors = ThemeColors(context);
 
 return Dialog(
 backgroundColor: Colors.transparent,
 child: AsmblCardEnhanced.outlined(
 isInteractive: false,
 child: Container(
 width: 600,
 constraints: const BoxConstraints(maxHeight: 500),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header
 Row(
 children: [
 Icon(
 sample.icon,
 size: 24,
 color: colors.primary,
 ),
 const SizedBox(width: 4),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 sample.title,
 style: TextStyles.pageTitle.copyWith(
 color: colors.onSurface,
 ),
 ),
 Text(
 sample.contextType.displayName,
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 IconButton(
 onPressed: () => Navigator.of(context).pop(),
 icon: const Icon(Icons.close),
 style: IconButton.styleFrom(
 foregroundColor: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 
 const SizedBox(height: SpacingTokens.elementSpacing),
 
 // Content preview
 Expanded(
 child: SingleChildScrollView(
 child: Container(
 padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
 decoration: BoxDecoration(
 color: colors.surfaceVariant.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(8),
 ),
 child: Text(
 sample.content,
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurface,
 fontFamily: 'monospace',
 ),
 ),
 ),
 ),
 ),
 
 const SizedBox(height: SpacingTokens.elementSpacing),
 
 // Footer
 Row(
 mainAxisAlignment: MainAxisAlignment.end,
 children: [
 AsmblButtonEnhanced.secondary(
 text: 'Close',
 onPressed: () => Navigator.of(context).pop(),
 size: AsmblButtonSize.medium,
 ),
 const SizedBox(width: 4),
 AsmblButtonEnhanced.accent(
 text: 'Add to Library',
 icon: Icons.add,
 onPressed: () {
 Navigator.of(context).pop();
 // Handle add action
 },
 size: AsmblButtonSize.medium,
 ),
 ],
 ),
 ],
 ),
 ),
 ),
 );
 }
}

enum ContextHubCategory {
 all,
 development,
 business,
 research,
 documentation,
 templates,
}

extension ContextHubCategoryExtension on ContextHubCategory {
 String get displayName {
 switch (this) {
 case ContextHubCategory.all:
 return 'All';
 case ContextHubCategory.development:
 return 'Development';
 case ContextHubCategory.business:
 return 'Business';
 case ContextHubCategory.research:
 return 'Research';
 case ContextHubCategory.documentation:
 return 'Documentation';
 case ContextHubCategory.templates:
 return 'Templates';
 }
 }

 IconData get icon {
 switch (this) {
 case ContextHubCategory.all:
 return Icons.apps;
 case ContextHubCategory.development:
 return Icons.code;
 case ContextHubCategory.business:
 return Icons.business;
 case ContextHubCategory.research:
 return Icons.search;
 case ContextHubCategory.documentation:
 return Icons.description;
 case ContextHubCategory.templates:
 return Icons.article_outlined;
 }
 }
}

class SampleContext {
 final String title;
 final String description;
 final String content;
 final ContextType contextType;
 final ContextHubCategory category;
 final List<String> tags;
 final IconData icon;

 const SampleContext({
 required this.title,
 required this.description,
 required this.content,
 required this.contextType,
 required this.category,
 required this.tags,
 required this.icon,
 });
}

class SampleContextConfigureDialog extends StatefulWidget {
final SampleContext sample;

const SampleContextConfigureDialog({
super.key,
required this.sample,
});

@override
State<SampleContextConfigureDialog> createState() => _SampleContextConfigureDialogState();
}

class _SampleContextConfigureDialogState extends State<SampleContextConfigureDialog> {
late TextEditingController _titleController;
late TextEditingController _contentController;
late List<String> _tags;
late ContextType _selectedType;

@override
void initState() {
super.initState();
_titleController = TextEditingController(text: widget.sample.title);
_contentController = TextEditingController(text: widget.sample.content);
_tags = List<String>.from(widget.sample.tags);
_selectedType = widget.sample.contextType;
}

@override
Widget build(BuildContext context) {
final colors = ThemeColors(context);

return Dialog(
backgroundColor: Colors.transparent,
child: AsmblCardEnhanced.outlined(
isInteractive: false,
child: Container(
width: 700,
constraints: const BoxConstraints(maxHeight: 600),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Header
Row(
children: [
Icon(
Icons.tune,
size: 24,
color: colors.primary,
),
const SizedBox(width: 4),
Expanded(
child: Text(
'Configure Context',
style: TextStyles.pageTitle.copyWith(
color: colors.onSurface,
),
),
),
IconButton(
onPressed: () => Navigator.of(context).pop(),
icon: const Icon(Icons.close),
style: IconButton.styleFrom(
foregroundColor: colors.onSurfaceVariant,
),
),
],
),

const SizedBox(height: SpacingTokens.elementSpacing),

// Form
Expanded(
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Title
Text(
'Title',
style: TextStyles.bodyMedium.copyWith(
fontWeight: FontWeight.w600,
color: colors.onSurface,
),
),
const SizedBox(height: SpacingTokens.iconSpacing),
TextField(
controller: _titleController,
decoration: InputDecoration(
hintText: 'Enter context title',
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
borderSide: BorderSide(color: colors.border),
),
filled: true,
fillColor: colors.surface,
),
),

const SizedBox(height: SpacingTokens.componentSpacing),

// Type
Text(
'Type',
style: TextStyles.bodyMedium.copyWith(
fontWeight: FontWeight.w600,
color: colors.onSurface,
),
),
const SizedBox(height: SpacingTokens.iconSpacing),
DropdownButtonFormField<ContextType>(
initialValue: _selectedType,
decoration: InputDecoration(
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
borderSide: BorderSide(color: colors.border),
),
filled: true,
fillColor: colors.surface,
),
items: ContextType.values.map((type) {
return DropdownMenuItem(
value: type,
child: Text(type.displayName),
);
}).toList(),
onChanged: (value) {
if (value != null) {
setState(() => _selectedType = value);
}
},
),

const SizedBox(height: SpacingTokens.componentSpacing),

// Content
Text(
'Content',
style: TextStyles.bodyMedium.copyWith(
fontWeight: FontWeight.w600,
color: colors.onSurface,
),
),
const SizedBox(height: SpacingTokens.iconSpacing),
TextField(
controller: _contentController,
decoration: InputDecoration(
hintText: 'Enter context content',
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
borderSide: BorderSide(color: colors.border),
),
filled: true,
fillColor: colors.surface,
),
maxLines: 8,
minLines: 4,
),

const SizedBox(height: SpacingTokens.componentSpacing),

// Tags
Text(
'Tags',
style: TextStyles.bodyMedium.copyWith(
fontWeight: FontWeight.w600,
color: colors.onSurface,
),
),
const SizedBox(height: SpacingTokens.iconSpacing),
if (_tags.isNotEmpty)
Wrap(
spacing: SpacingTokens.iconSpacing,
runSpacing: SpacingTokens.iconSpacing,
children: _tags.map((tag) {
return Chip(
label: Text(tag),
onDeleted: () {
setState(() => _tags.remove(tag));
},
deleteIconColor: colors.onSurfaceVariant,
backgroundColor: colors.surfaceVariant.withValues(alpha: 0.5),
);
}).toList(),
),
],
),
),
),

const SizedBox(height: SpacingTokens.elementSpacing),

// Footer
Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
AsmblButtonEnhanced.secondary(
text: 'Cancel',
onPressed: () => Navigator.of(context).pop(),
size: AsmblButtonSize.medium,
),
const SizedBox(width: 4),
AsmblButtonEnhanced.accent(
text: 'Add to Library',
icon: Icons.add,
onPressed: _handleAddToLibrary,
size: AsmblButtonSize.medium,
),
],
),
],
),
),
),
);
}

void _handleAddToLibrary() async {
try {
final context = this.context;
if (context.mounted) {
final container = ProviderScope.containerOf(context);
await container.read(contextRepositoryProvider).createDocument(
title: _titleController.text,
content: _contentController.text,
type: _selectedType,
tags: _tags,
);

container.invalidate(contextDocumentsProvider);

if (context.mounted) {
Navigator.of(context).pop();
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Row(
children: [
const Icon(Icons.check_circle, color: Colors.white, size: 16),
const SizedBox(width: 4),
Expanded(
child: Text(
'Added "${_titleController.text}" to your context library',
style: GoogleFonts.fustat(),
),
),
],
),
backgroundColor: SemanticColors.success,
behavior: SnackBarBehavior.floating,
duration: const Duration(seconds: 3),
),
);
}
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Failed to add context: ${e.toString()}',
style: GoogleFonts.fustat(),
),
backgroundColor: SemanticColors.error,
behavior: SnackBarBehavior.floating,
),
);
}
}
}

@override
void dispose() {
_titleController.dispose();
_contentController.dispose();
super.dispose();
}
}
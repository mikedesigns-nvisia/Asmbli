import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/context_document.dart';

enum CreationStep {
 sourceSelection,
 typeConfiguration,
 contentInput,
 validation,
 finalization,
}

enum CreationSource {
 manual,
 fileUpload,
 template,
}

class ContextCreationFlow extends StatefulWidget {
 final Function(ContextDocument) onSave;
 final VoidCallback onCancel;

 const ContextCreationFlow({
 super.key,
 required this.onSave,
 required this.onCancel,
 });

 @override
 State<ContextCreationFlow> createState() => _ContextCreationFlowState();
}

class _ContextCreationFlowState extends State<ContextCreationFlow> {
 CreationStep _currentStep = CreationStep.sourceSelection;
 CreationSource? _selectedSource;
 ContextType _selectedType = ContextType.documentation;
 
 final _titleController = TextEditingController();
 final _contentController = TextEditingController();
 final _tagsController = TextEditingController();
 
 List<String> _tags = [];
 final List<PlatformFile> _uploadedFiles = [];
 final bool _isProcessing = false;
 String? _validationMessage;

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
 
 return AsmblCard(
 padding: EdgeInsets.zero,
 isInteractive: false,
 child: Container(
 width: 800,
 constraints: const BoxConstraints(
 minHeight: 500,
 maxHeight: 700,
 ),
 child: Column(
 children: [
 // Flow Header
 _buildFlowHeader(context, colors),
 
 // Progress Indicator
 _buildProgressIndicator(context, colors),
 
 // Step Content
 Expanded(
 child: _buildStepContent(context, colors),
 ),
 
 // Navigation Footer
 _buildNavigationFooter(context, colors),
 ],
 ),
 ),
 );
 }

 Widget _buildFlowHeader(BuildContext context, ThemeColors colors) {
 return Container(
 padding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.elementSpacing,
 vertical: SpacingTokens.componentSpacing,
 ),
 decoration: BoxDecoration(
 color: colors.surface.withValues(alpha: 0.95),
 borderRadius: const BorderRadius.only(
 topLeft: Radius.circular(BorderRadiusTokens.xl),
 topRight: Radius.circular(BorderRadiusTokens.xl),
 ),
 border: Border(
 bottom: BorderSide(color: colors.border),
 ),
 ),
 child: Row(
 children: [
 Icon(
 Icons.auto_stories,
 size: 20,
 color: colors.primary,
 ),
 const SizedBox(width: SpacingTokens.iconSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Create Context Document',
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 _getStepDescription(),
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 IconButton(
 onPressed: widget.onCancel,
 icon: const Icon(Icons.close, size: 18),
 style: IconButton.styleFrom(
 foregroundColor: colors.onSurfaceVariant,
 minimumSize: const Size(36, 36),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildProgressIndicator(BuildContext context, ThemeColors colors) {
 const steps = CreationStep.values;
 final currentIndex = steps.indexOf(_currentStep);
 
 return Container(
 padding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.elementSpacing,
 vertical: SpacingTokens.componentSpacing,
 ),
 child: Row(
 children: List.generate(steps.length, (index) {
 final isCompleted = index < currentIndex;
 final isCurrent = index == currentIndex;
 final isUpcoming = index > currentIndex;
 
 return Expanded(
 child: Row(
 children: [
 // Step Circle
 Container(
 width: 24,
 height: 24,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: isCompleted 
 ? SemanticColors.success
 : isCurrent 
 ? colors.primary 
 : colors.surfaceVariant,
 border: isUpcoming ? Border.all(color: colors.border) : null,
 ),
 child: Center(
 child: isCompleted
 ? const Icon(Icons.check, size: 14, color: Colors.white)
 : Text(
 '${index + 1}',
 style: TextStyles.caption.copyWith(
 color: isCurrent || isCompleted 
 ? Colors.white 
 : colors.onSurfaceVariant,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 ),
 
 // Connecting Line
 if (index < steps.length - 1)
 Expanded(
 child: Container(
 height: 2,
 margin: const EdgeInsets.symmetric(horizontal: 8),
 color: isCompleted 
 ? SemanticColors.success 
 : colors.border,
 ),
 ),
 ],
 ),
 );
 }),
 ),
 );
 }

 Widget _buildStepContent(BuildContext context, ThemeColors colors) {
 switch (_currentStep) {
 case CreationStep.sourceSelection:
 return _buildSourceSelectionStep(context, colors);
 case CreationStep.typeConfiguration:
 return _buildTypeConfigurationStep(context, colors);
 case CreationStep.contentInput:
 return _buildContentInputStep(context, colors);
 case CreationStep.validation:
 return _buildValidationStep(context, colors);
 case CreationStep.finalization:
 return _buildFinalizationStep(context, colors);
 }
 }

 Widget _buildSourceSelectionStep(BuildContext context, ThemeColors colors) {
 return Padding(
 padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'How would you like to create your context document?',
 style: TextStyles.sectionTitle.copyWith(
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.elementSpacing),
 
 Expanded(
 child: GridView.count(
 crossAxisCount: 3,
 crossAxisSpacing: SpacingTokens.elementSpacing,
 mainAxisSpacing: SpacingTokens.elementSpacing,
 childAspectRatio: 1.1,
 children: [
 _buildSourceOption(
 context, 
 colors,
 CreationSource.manual,
 Icons.edit_outlined,
 'Manual Creation',
 'Write content directly with full control over formatting',
 ),
 _buildSourceOption(
 context, 
 colors,
 CreationSource.fileUpload,
 Icons.upload_file,
 'File Upload',
 'Upload documents and extract content automatically',
 ),
 _buildSourceOption(
 context, 
 colors,
 CreationSource.template,
 Icons.content_copy,
 'From Template',
 'Start with pre-built templates for common use cases',
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildSourceOption(
 BuildContext context,
 ThemeColors colors,
 CreationSource source,
 IconData icon,
 String title,
 String description,
 ) {
 final isSelected = _selectedSource == source;
 
 return GestureDetector(
 onTap: () => setState(() => _selectedSource = source),
 child: AsmblCard(
 isInteractive: true,
 child: Container(
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 border: isSelected 
 ? Border.all(color: colors.primary, width: 2)
 : null,
 ),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 icon,
 size: 48,
 color: isSelected ? colors.primary : colors.onSurfaceVariant,
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 title,
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 color: isSelected ? colors.primary : colors.onSurface,
 ),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 description,
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 ),
 ),
 );
 }

 Widget _buildTypeConfigurationStep(BuildContext context, ThemeColors colors) {
 return Padding(
 padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Select the type of context document',
 style: TextStyles.sectionTitle.copyWith(
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'This helps optimize how agents understand and use your content',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: SpacingTokens.sectionSpacing),
 
 Expanded(
 child: GridView.count(
 crossAxisCount: 2,
 crossAxisSpacing: SpacingTokens.elementSpacing,
 mainAxisSpacing: SpacingTokens.elementSpacing,
 childAspectRatio: 2.5,
 children: ContextType.values.map((type) {
 final isSelected = _selectedType == type;
 return _buildTypeOption(context, colors, type, isSelected);
 }).toList(),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildTypeOption(BuildContext context, ThemeColors colors, ContextType type, bool isSelected) {
 return GestureDetector(
 onTap: () => setState(() => _selectedType = type),
 child: AsmblCard(
 isInteractive: true,
 child: Container(
 padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 border: isSelected ? Border.all(color: colors.primary, width: 2) : null,
 ),
 child: Row(
 children: [
 Icon(
 _getTypeIcon(type),
 size: 24,
 color: isSelected ? colors.primary : colors.onSurfaceVariant,
 ),
 const SizedBox(width: SpacingTokens.componentSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Text(
 type.displayName,
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 color: isSelected ? colors.primary : colors.onSurface,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 _getTypeDescription(type),
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 ),
 );
 }

 Widget _buildContentInputStep(BuildContext context, ThemeColors colors) {
 if (_selectedSource == CreationSource.fileUpload) {
 return _buildFileUploadContent(context, colors);
 } else if (_selectedSource == CreationSource.template) {
 return _buildTemplateContent(context, colors);
 } else {
 return _buildManualContent(context, colors);
 }
 }

 Widget _buildFileUploadContent(BuildContext context, ThemeColors colors) {
 return Padding(
 padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Upload your documents',
 style: TextStyles.sectionTitle.copyWith(
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 // Upload Area
 GestureDetector(
 onTap: _pickFiles,
 child: AsmblCard(
 isInteractive: true,
 child: SizedBox(
 height: _uploadedFiles.isEmpty ? 160 : 120,
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.cloud_upload_outlined,
 size: _uploadedFiles.isEmpty ? 48 : 40,
 color: colors.primary,
 ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 'Click to browse or drag and drop',
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: 4),
 Text(
 'PDF, TXT, MD, JSON, CSV (max 10MB each)',
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 ),
 ),
 
 // Uploaded Files List
 if (_uploadedFiles.isNotEmpty) ...[
 const SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'Uploaded Files (${_uploadedFiles.length})',
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 
 Expanded(
 child: ListView.separated(
 itemCount: _uploadedFiles.length,
 separatorBuilder: (context, index) => const SizedBox(height: 6),
 itemBuilder: (context, index) {
 final file = _uploadedFiles[index];
 return AsmblCard(
 isInteractive: false,
 child: Padding(
 padding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing,
 vertical: SpacingTokens.iconSpacing,
 ),
 child: Row(
 children: [
 Icon(
 _getFileIcon(file.extension ?? ''),
 size: 20,
 color: colors.primary,
 ),
 const SizedBox(width: SpacingTokens.iconSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 file.name,
 style: TextStyles.bodySmall.copyWith(
 fontWeight: FontWeight.w500,
 color: colors.onSurface,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 Text(
 _formatFileSize(file.size),
 style: TextStyles.caption.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 IconButton(
 onPressed: () => _removeFile(index),
 icon: const Icon(Icons.close, size: 14),
 style: IconButton.styleFrom(
 foregroundColor: colors.onSurfaceVariant,
 minimumSize: const Size(32, 32),
 ),
 ),
 ],
 ),
 ),
 );
 },
 ),
 ),
 ],
 ],
 ),
 );
 }

 Widget _buildManualContent(BuildContext context, ThemeColors colors) {
 return Padding(
 padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Create your content',
 style: TextStyles.sectionTitle.copyWith(
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 // Title Field
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Document Title',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurface,
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 TextFormField(
 controller: _titleController,
 decoration: InputDecoration(
 hintText: 'Enter a descriptive title...',
 hintStyle: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant.withValues(alpha: 0.6),
 ),
 filled: true,
 fillColor: colors.surfaceVariant.withValues(alpha: 0.3),
 contentPadding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing,
 vertical: SpacingTokens.iconSpacing,
 ),
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
 ),
 ],
 ),
 
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 // Content Field
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Content',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurface,
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 Expanded(
 child: TextFormField(
 controller: _contentController,
 maxLines: null,
 expands: true,
 textAlignVertical: TextAlignVertical.top,
 decoration: InputDecoration(
 hintText: 'Enter your ${_selectedType.displayName.toLowerCase()} content here...',
 hintStyle: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant.withValues(alpha: 0.6),
 ),
 filled: true,
 fillColor: colors.surfaceVariant.withValues(alpha: 0.3),
 contentPadding: const EdgeInsets.all(SpacingTokens.componentSpacing),
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
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildTemplateContent(BuildContext context, ThemeColors colors) {
 return Padding(
 padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Choose a template',
 style: TextStyles.sectionTitle.copyWith(
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.elementSpacing),
 
 Expanded(
 child: GridView.count(
 crossAxisCount: 2,
 crossAxisSpacing: SpacingTokens.elementSpacing,
 mainAxisSpacing: SpacingTokens.elementSpacing,
 childAspectRatio: 1.8,
 children: _getTemplatesForType(_selectedType).map((template) {
 return _buildTemplateOption(context, colors, template);
 }).toList(),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildValidationStep(BuildContext context, ThemeColors colors) {
 return Padding(
 padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Review and validate',
 style: TextStyles.sectionTitle.copyWith(
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.elementSpacing),
 
 if (_validationMessage != null) ...[
 Container(
 padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 color: SemanticColors.warning.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 border: Border.all(color: SemanticColors.warning),
 ),
 child: Row(
 children: [
 const Icon(Icons.warning_amber, color: SemanticColors.warning, size: 20),
 const SizedBox(width: SpacingTokens.componentSpacing),
 Expanded(
 child: Text(
 _validationMessage!,
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurface,
 ),
 ),
 ),
 ],
 ),
 ),
 const SizedBox(height: SpacingTokens.elementSpacing),
 ],
 
 // Content Preview
 Expanded(
 child: AsmblCard(
 isInteractive: false,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 _getTypeIcon(_selectedType),
 size: 20,
 color: colors.primary,
 ),
 const SizedBox(width: SpacingTokens.componentSpacing),
 Text(
 _titleController.text.isNotEmpty 
 ? _titleController.text 
 : 'Untitled Document',
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 const Spacer(),
 Chip(
 label: Text(
 _selectedType.displayName,
 style: TextStyles.caption.copyWith(
 color: colors.primary,
 ),
 ),
 backgroundColor: colors.primary.withValues(alpha: 0.1),
 side: BorderSide(color: colors.primary),
 ),
 ],
 ),
 const SizedBox(height: SpacingTokens.elementSpacing),
 Divider(color: colors.border),
 const SizedBox(height: SpacingTokens.elementSpacing),
 Expanded(
 child: SingleChildScrollView(
 child: Text(
 _contentController.text.isNotEmpty
 ? _contentController.text
 : 'No content provided',
 style: TextStyles.bodyMedium.copyWith(
 color: _contentController.text.isNotEmpty
 ? colors.onSurface
 : colors.onSurfaceVariant,
 ),
 ),
 ),
 ),
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildFinalizationStep(BuildContext context, ThemeColors colors) {
 return Padding(
 padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Add tags and metadata',
 style: TextStyles.sectionTitle.copyWith(
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 
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
 const SizedBox(height: SpacingTokens.iconSpacing),
 TextFormField(
 controller: _tagsController,
 decoration: InputDecoration(
 hintText: 'api, documentation, reference...',
 hintStyle: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant.withValues(alpha: 0.6),
 ),
 filled: true,
 fillColor: colors.surfaceVariant.withValues(alpha: 0.3),
 contentPadding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing,
 vertical: SpacingTokens.iconSpacing,
 ),
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
 const SizedBox(height: 4),
 Text(
 'Separate tags with commas',
 style: TextStyles.caption.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 ],
 ),
 
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 // Final Summary
 Expanded(
 child: AsmblCard(
 isInteractive: false,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Document Summary',
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 _buildSummaryRow('Title', _titleController.text.isNotEmpty ? _titleController.text : 'Untitled', colors),
 _buildSummaryRow('Type', _selectedType.displayName, colors),
 _buildSummaryRow('Source', _selectedSource?.name ?? 'Unknown', colors),
 _buildSummaryRow('Content Length', '${_contentController.text.length} characters', colors),
 if (_tags.isNotEmpty)
 _buildSummaryRow('Tags', _tags.join(', '), colors),
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildSummaryRow(String label, String value, ThemeColors colors) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 8),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 SizedBox(
 width: 120,
 child: Text(
 label,
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 Expanded(
 child: Text(
 value,
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurface,
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildNavigationFooter(BuildContext context, ThemeColors colors) {
 final canGoNext = _canGoToNextStep();
 final canGoPrevious = _currentStep.index > 0;
 final isLastStep = _currentStep == CreationStep.values.last;
 
 return Container(
 padding: const EdgeInsets.symmetric(
 horizontal: SpacingTokens.elementSpacing,
 vertical: SpacingTokens.componentSpacing,
 ),
 decoration: BoxDecoration(
 color: colors.surface.withValues(alpha: 0.95),
 borderRadius: const BorderRadius.only(
 bottomLeft: Radius.circular(BorderRadiusTokens.xl),
 bottomRight: Radius.circular(BorderRadiusTokens.xl),
 ),
 border: Border(
 top: BorderSide(color: colors.border),
 ),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 // Previous Button
 canGoPrevious
 ? AsmblButton.secondary(
 text: 'Previous',
 icon: Icons.arrow_back,
 onPressed: _goToPreviousStep,
 )
 : const SizedBox.shrink(),
 
 // Cancel Button (always visible)
 AsmblButton.secondary(
 text: 'Cancel',
 onPressed: widget.onCancel,
 ),
 
 // Next/Create Button
 AsmblButton.primary(
 text: isLastStep ? 'Create Document' : 'Next',
 icon: isLastStep ? Icons.check : Icons.arrow_forward,
 onPressed: canGoNext ? (isLastStep ? _createDocument : _goToNextStep) : null,
 ),
 ],
 ),
 );
 }

 Widget _buildTemplateOption(BuildContext context, ThemeColors colors, Map<String, String> template) {
 return GestureDetector(
 onTap: () => _selectTemplate(template),
 child: AsmblCard(
 isInteractive: true,
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.componentSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 template['title']!,
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 color: colors.onSurface,
 ),
 ),
 const SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 template['description']!,
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 ],
 ),
 ),
 ),
 );
 }

 String _getStepDescription() {
 switch (_currentStep) {
 case CreationStep.sourceSelection:
 return 'Choose how to create your document';
 case CreationStep.typeConfiguration:
 return 'Configure document type and settings';
 case CreationStep.contentInput:
 return 'Add your content or upload files';
 case CreationStep.validation:
 return 'Review and validate your document';
 case CreationStep.finalization:
 return 'Add tags and finalize';
 }
 }

 IconData _getTypeIcon(ContextType type) {
 switch (type) {
 case ContextType.documentation:
 return Icons.description;
 case ContextType.codebase:
 return Icons.code;
 case ContextType.knowledge:
 return Icons.school;
 case ContextType.guidelines:
 return Icons.rule;
 case ContextType.examples:
 return Icons.lightbulb_outline;
 case ContextType.custom:
 return Icons.tune;
 }
 }

 String _getTypeDescription(ContextType type) {
 return type.description;
 }

 IconData _getFileIcon(String extension) {
 switch (extension.toLowerCase()) {
 case 'pdf':
 return Icons.picture_as_pdf;
 case 'txt':
 case 'md':
 return Icons.description;
 case 'json':
 case 'csv':
 return Icons.data_object;
 default:
 return Icons.insert_drive_file;
 }
 }

 String _formatFileSize(int bytes) {
 if (bytes < 1024) {
 return '$bytes B';
 } else if (bytes < 1024 * 1024) {
 return '${(bytes / 1024).toStringAsFixed(1)} KB';
 } else {
 return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
 }
 }

 bool _canGoToNextStep() {
 switch (_currentStep) {
 case CreationStep.sourceSelection:
 return _selectedSource != null;
 case CreationStep.typeConfiguration:
 return true; // Type is always selected
 case CreationStep.contentInput:
 if (_selectedSource == CreationSource.fileUpload) {
 return _uploadedFiles.isNotEmpty;
 } else {
 return _titleController.text.isNotEmpty && _contentController.text.isNotEmpty;
 }
 case CreationStep.validation:
 return _validationMessage == null;
 case CreationStep.finalization:
 return true;
 }
 }

 void _goToNextStep() {
 if (_currentStep.index < CreationStep.values.length - 1) {
 setState(() {
 _currentStep = CreationStep.values[_currentStep.index + 1];
 if (_currentStep == CreationStep.validation) {
 _validateContent();
 }
 });
 }
 }

 void _goToPreviousStep() {
 if (_currentStep.index > 0) {
 setState(() {
 _currentStep = CreationStep.values[_currentStep.index - 1];
 });
 }
 }

 Future<void> _pickFiles() async {
 final result = await FilePicker.platform.pickFiles(
 allowMultiple: true,
 type: FileType.custom,
 allowedExtensions: ['pdf', 'txt', 'md', 'json', 'csv'],
 );

 if (result != null) {
 setState(() {
 _uploadedFiles.addAll(
 result.files.where((file) => file.size <= 10 * 1024 * 1024),
 );
 });
 
 // Auto-generate content from uploaded files
 _processUploadedFiles();
 }
 }

 void _removeFile(int index) {
 setState(() {
 _uploadedFiles.removeAt(index);
 });
 }

 void _processUploadedFiles() {
 // Simulate processing uploaded files to extract content
 if (_uploadedFiles.isNotEmpty && _titleController.text.isEmpty) {
 _titleController.text = _uploadedFiles.first.name.split('.').first;
 }
 
 if (_contentController.text.isEmpty) {
 _contentController.text = 'Content extracted from uploaded files:\n\n${_uploadedFiles.map((f) => '- ${f.name}').join('\n')}';
 }
 }

 void _selectTemplate(Map<String, String> template) {
 _titleController.text = template['title']!;
 _contentController.text = template['content']!;
 _goToNextStep();
 }

 List<Map<String, String>> _getTemplatesForType(ContextType type) {
 switch (type) {
 case ContextType.documentation:
 return [
 {
 'title': 'API Documentation',
 'description': 'Template for documenting REST APIs',
 'content': '# API Documentation\n\n## Overview\n\n## Endpoints\n\n### GET /api/endpoint\n\n**Description:** \n\n**Parameters:**\n\n**Response:**\n\n## Examples\n\n## Error Codes',
 },
 {
 'title': 'User Guide',
 'description': 'Template for user guides and tutorials',
 'content': '# User Guide\n\n## Getting Started\n\n## Step-by-Step Instructions\n\n### Step 1:\n\n### Step 2:\n\n### Step 3:\n\n## Troubleshooting\n\n## FAQ',
 },
 ];
 case ContextType.codebase:
 return [
 {
 'title': 'Function Reference',
 'description': 'Template for documenting code functions',
 'content': '# Function Reference\n\n## Function Name\n\n**Syntax:** `function_name(parameters)`\n\n**Description:** \n\n**Parameters:**\n- `param1` (type): Description\n- `param2` (type): Description\n\n**Returns:** Description\n\n**Example:**\n```\ncode example here\n```',
 },
 {
 'title': 'Component Structure',
 'description': 'Template for documenting code structure',
 'content': '# Component: [Component Name]\n\n## Purpose\n\n## Dependencies\n\n## Structure\n\n```\nproject/\n├── src/\n│ ├── components/\n│ └── utils/\n└── tests/\n```\n\n## Key Files\n\n## Usage Examples',
 },
 ];
 case ContextType.guidelines:
 return [
 {
 'title': 'Coding Standards',
 'description': 'Template for coding guidelines',
 'content': '# Coding Standards\n\n## General Principles\n\n## Naming Conventions\n\n### Variables\n\n### Functions\n\n### Classes\n\n## Code Structure\n\n## Best Practices\n\n## Examples\n\n## Forbidden Practices',
 },
 {
 'title': 'Review Guidelines',
 'description': 'Template for code review guidelines',
 'content': '# Code Review Guidelines\n\n## Review Process\n\n## What to Look For\n\n### Functionality\n### Code Quality\n### Performance\n### Security\n\n## Common Issues\n\n## Approval Criteria',
 },
 ];
 case ContextType.examples:
 return [
 {
 'title': 'Implementation Example',
 'description': 'Template for code examples',
 'content': '# Implementation Example: [Feature Name]\n\n## Overview\n\n## Prerequisites\n\n## Step-by-Step Implementation\n\n### Step 1: Setup\n```\ncode here\n```\n\n### Step 2: Core Logic\n```\ncode here\n```\n\n### Step 3: Testing\n```\ncode here\n```\n\n## Common Pitfalls\n\n## Alternative Approaches',
 },
 {
 'title': 'Usage Pattern',
 'description': 'Template for usage patterns',
 'content': '# Usage Pattern: [Pattern Name]\n\n## When to Use\n\n## Implementation\n\n```\nexample code\n```\n\n## Benefits\n\n## Drawbacks\n\n## Related Patterns',
 },
 ];
 case ContextType.knowledge:
 return [
 {
 'title': 'Domain Knowledge',
 'description': 'Template for domain-specific knowledge',
 'content': '# Domain: [Domain Name]\n\n## Overview\n\n## Key Concepts\n\n### Concept 1\nDefinition and explanation\n\n### Concept 2\nDefinition and explanation\n\n## Rules and Constraints\n\n## Common Scenarios\n\n## Related Domains',
 },
 {
 'title': 'Process Knowledge',
 'description': 'Template for business processes',
 'content': '# Process: [Process Name]\n\n## Purpose\n\n## Scope\n\n## Prerequisites\n\n## Process Steps\n\n1. Step 1\n2. Step 2\n3. Step 3\n\n## Roles and Responsibilities\n\n## Related Processes',
 },
 ];
 case ContextType.custom:
 return [
 {
 'title': 'Custom Template',
 'description': 'Blank template for custom content',
 'content': '# [Your Title Here]\n\n## Section 1\n\nYour content here...\n\n## Section 2\n\nYour content here...\n\n## Additional Notes\n\n',
 },
 {
 'title': 'Structured Data',
 'description': 'Template for structured information',
 'content': '# [Data Structure Name]\n\n## Overview\n\n## Data Elements\n\n### Element 1\n- **Type:** \n- **Description:** \n- **Format:** \n- **Valid Values:** \n\n### Element 2\n- **Type:** \n- **Description:** \n- **Format:** \n- **Valid Values:** \n\n## Relationships\n\n## Usage Notes',
 },
 ];
 }
 }

 void _validateContent() {
 setState(() {
 _validationMessage = null;
 });

 // Basic validation checks
 if (_titleController.text.trim().isEmpty) {
 setState(() {
 _validationMessage = 'Document title is required';
 });
 return;
 }

 if (_contentController.text.trim().isEmpty) {
 setState(() {
 _validationMessage = 'Document content is required';
 });
 return;
 }

 if (_contentController.text.length < 50) {
 setState(() {
 _validationMessage = 'Content seems too short. Consider adding more detail.';
 });
 return;
 }

 // Type-specific validation
 switch (_selectedType) {
 case ContextType.codebase:
 if (!_contentController.text.contains('```') && !_contentController.text.contains('`')) {
 setState(() {
 _validationMessage = 'Codebase documents should include code examples with backticks or code blocks.';
 });
 }
 break;
 case ContextType.documentation:
 if (!_contentController.text.contains('#') && !_contentController.text.contains('##')) {
 setState(() {
 _validationMessage = 'Documentation should include headers using # or ## for better structure.';
 });
 }
 break;
 default:
 break;
 }
 }

 void _createDocument() {
 final document = ContextDocument(
 id: '',
 title: _titleController.text.trim(),
 content: _contentController.text.trim(),
 type: _selectedType,
 tags: _tags,
 createdAt: DateTime.now(),
 updatedAt: DateTime.now(),
 isActive: true,
 metadata: {
 'source': _selectedSource?.name ?? 'manual',
 'hasFiles': _uploadedFiles.isNotEmpty,
 'fileCount': _uploadedFiles.length,
 },
 );

 widget.onSave(document);
 }
}
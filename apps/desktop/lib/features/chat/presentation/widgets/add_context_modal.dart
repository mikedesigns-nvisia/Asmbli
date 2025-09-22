import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../providers/conversation_provider.dart';
import '../../../context/presentation/widgets/context_creation_flow.dart';

class AddContextModal extends ConsumerStatefulWidget {
 final String? conversationId;
 
 const AddContextModal({
 super.key,
 this.conversationId,
 });

 @override
 ConsumerState<AddContextModal> createState() => _AddContextModalState();
}

class _AddContextModalState extends ConsumerState<AddContextModal> {
 final List<ContextDocument> _selectedDocuments = [];
 bool _isUploading = false;
 List<String> _existingContextDocuments = [];
 String? _agentName;
 bool _isAgentConversation = false;
 String _selectedContextType = 'Knowledge Base';
 bool _showAdvancedFlow = false;

 @override
 void initState() {
 super.initState();
 _loadConversationContext();
 }
 
 void _loadConversationContext() async {
 if (widget.conversationId != null) {
 final conversationService = ref.read(conversationServiceProvider);
 try {
 final conversation = await conversationService.getConversation(widget.conversationId!);
 if (conversation.metadata != null) {
 setState(() {
 _isAgentConversation = conversation.metadata!['type'] == 'agent';
 if (_isAgentConversation) {
 _agentName = conversation.metadata!['agentName'];
 _existingContextDocuments = List<String>.from(
 conversation.metadata!['contextDocuments'] ?? []
 );
 }
 });
 }
 } catch (e) {
 // Handle error silently
 }
 }
 }
 
 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 
 // Show advanced flow if requested
 if (_showAdvancedFlow) {
 return Dialog(
 backgroundColor: ThemeColors(context).surface,
 surfaceTintColor: Colors.transparent,
 child: ContextCreationFlow(
 onSave: (document) async {
 // Add the created document to the conversation context
 if (widget.conversationId != null && _isAgentConversation) {
 final conversationService = ref.read(conversationServiceProvider);
 try {
 final conversation = await conversationService.getConversation(widget.conversationId!);
 if (conversation.metadata != null && conversation.metadata!['type'] == 'agent') {
 final existingDocs = List<String>.from(conversation.metadata!['contextDocuments'] ?? []);
 existingDocs.add(document.title);
 conversation.metadata!['contextDocuments'] = existingDocs;
 await conversationService.updateConversation(conversation);
 ref.invalidate(conversationProvider(widget.conversationId!));
 }
 } catch (e) {
 // Handle error silently
 }
 }
 
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Row(
 children: [
 const Icon(Icons.check_circle, color: Colors.white, size: 16),
 const SizedBox(width: 8),
 Text(
 'Document "${document.title}" created and added to context',
 style: GoogleFonts.fustat(),
 ),
 ],
 ),
 backgroundColor: ThemeColors(context).success,
 behavior: SnackBarBehavior.floating,
 ),
 );
 Navigator.of(context).pop();
 }
 },
 onCancel: () => setState(() => _showAdvancedFlow = false),
 ),
 );
 }
 
 return Dialog(
 backgroundColor: ThemeColors(context).surface,
 surfaceTintColor: Colors.transparent,
 child: AsmblCard(
 padding: EdgeInsets.zero,
 isInteractive: false,
 child: Container(
 width: 500,
 constraints: const BoxConstraints(maxHeight: 600),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 // Header
 Container(
 padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
 decoration: BoxDecoration(
 color: ThemeColors(context).surface,
 borderRadius: const BorderRadius.only(
 topLeft: Radius.circular(BorderRadiusTokens.xl),
 topRight: Radius.circular(BorderRadiusTokens.xl),
 ),
 border: Border(
 bottom: BorderSide(color: ThemeColors(context).border),
 ),
 ),
 child: Row(
 children: [
 Icon(
 Icons.library_add,
 size: 20,
 color: ThemeColors(context).primary,
 ),
 const SizedBox(width: SpacingTokens.componentSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 _isAgentConversation 
 ? 'Add Context to $_agentName' 
 : 'Add Context',
 style: TextStyles.bodyLarge.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 _isAgentConversation
 ? 'Upload documents to enhance agent knowledge'
 : 'Upload documents to enhance AI understanding',
 style: TextStyles.bodySmall.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 IconButton(
 onPressed: () => Navigator.of(context).pop(),
 icon: const Icon(Icons.close, size: 20),
 style: IconButton.styleFrom(
 foregroundColor: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 
 // Content
 Flexible(
 child: SingleChildScrollView(
 padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Upload area
 GestureDetector(
 onTap: _isUploading ? null : _pickFiles,
 child: AsmblCard(
 padding: const EdgeInsets.all(SpacingTokens.sectionSpacing),
 isInteractive: !_isUploading,
 child: Column(
 children: [
 Icon(
 Icons.cloud_upload_outlined,
 size: 48,
 color: ThemeColors(context).primary,
 ),
 const SizedBox(height: SpacingTokens.elementSpacing),
 Text(
 'Click to browse or drag and drop',
 style: TextStyles.bodyMedium.copyWith(
 fontWeight: FontWeight.w500,
 color: ThemeColors(context).onSurface,
 ),
 ),
 const SizedBox(height: 4),
 Text(
 'PDF, TXT, MD, JSON, CSV (max 10MB each)',
 style: TextStyles.bodySmall.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 ),
 
 if (_selectedDocuments.isNotEmpty) ...[
 const SizedBox(height: SpacingTokens.textSectionSpacing),
 
 // Selected documents
 Text(
 'Selected Documents (${_selectedDocuments.length})',
 style: TextStyles.bodyMedium.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 ..._selectedDocuments.map((doc) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 8),
 child: AsmblCard(
 padding: const EdgeInsets.symmetric(
 horizontal: 12,
 vertical: 8,
 ),
 isInteractive: false,
 child: Row(
 children: [
 Icon(
 _getFileIcon(doc.extension),
 size: 20,
 color: ThemeColors(context).primary,
 ),
 const SizedBox(width: SpacingTokens.componentSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 doc.name,
 style: TextStyles.bodySmall.copyWith(
 fontWeight: FontWeight.w500,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 Text(
 doc.sizeFormatted,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 if (doc.isProcessing)
 SizedBox(
 width: 16,
 height: 16,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 valueColor: AlwaysStoppedAnimation<Color>(
 ThemeColors(context).primary,
 ),
 ),
 )
 else if (doc.isUploaded)
 Icon(
 Icons.check_circle,
 size: 18,
 color: ThemeColors(context).success,
 )
 else
 GestureDetector(
 onTap: () => _removeDocument(doc),
 child: Container(
 width: 24,
 height: 24,
 alignment: Alignment.center,
 child: Icon(
 Icons.close,
 size: 16,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ),
 ],
 ),
 ),
 );
 }),
 ],
 
 // Show existing context documents if agent conversation
 if (_isAgentConversation && _existingContextDocuments.isNotEmpty) ...[
 const SizedBox(height: SpacingTokens.textSectionSpacing),
 
 Text(
 'Existing Agent Context (${_existingContextDocuments.length})',
 style: TextStyles.bodyMedium.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 Container(
 width: double.infinity,
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: ThemeColors(context).surfaceVariant,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 border: Border.all(
 color: ThemeColors(context).border.withValues(alpha: 0.5),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: _existingContextDocuments.take(3).map<Widget>((doc) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 4),
 child: Row(
 children: [
 Icon(
 Icons.check_circle,
 size: 14,
 color: ThemeColors(context).success,
 ),
 const SizedBox(width: 6),
 Expanded(
 child: Text(
 doc,
 style: TextStyles.bodySmall.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ],
 ),
 );
 }).toList(),
 ),
 ),
 ],
 
 const SizedBox(height: SpacingTokens.sectionSpacing),
 
 // Context type selection
 Text(
 'Context Type',
 style: TextStyles.bodyMedium.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: SpacingTokens.componentSpacing),
 
 Wrap(
 spacing: 8,
 runSpacing: 8,
 children: [
 _buildContextTypeChip('Knowledge Base', Icons.school, _selectedContextType == 'Knowledge Base'),
 _buildContextTypeChip('Code Reference', Icons.code, _selectedContextType == 'Code Reference'),
 _buildContextTypeChip('Documentation', Icons.description, _selectedContextType == 'Documentation'),
 _buildContextTypeChip('Data Source', Icons.storage, _selectedContextType == 'Data Source'),
 ],
 ),
 ],
 ),
 ),
 ),
 
 // Footer
 Container(
 padding: const EdgeInsets.all(SpacingTokens.elementSpacing),
 decoration: BoxDecoration(
 color: ThemeColors(context).surface,
 borderRadius: const BorderRadius.only(
 bottomLeft: Radius.circular(BorderRadiusTokens.xl),
 bottomRight: Radius.circular(BorderRadiusTokens.xl),
 ),
 border: Border(
 top: BorderSide(color: ThemeColors(context).border),
 ),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 // Advanced Flow Button
 AsmblButton.secondary(
 text: 'Advanced',
 icon: Icons.auto_stories,
 onPressed: () => setState(() => _showAdvancedFlow = true),
 ),
 
 // Main Actions
 Row(
 children: [
 AsmblButton.secondary(
 text: 'Cancel',
 onPressed: () => Navigator.of(context).pop(),
 ),
 const SizedBox(width: SpacingTokens.componentSpacing),
 AsmblButton.primary(
 text: _isUploading 
 ? 'Processing...' 
 : (_isAgentConversation ? 'Add to Agent' : 'Add to Context'),
 onPressed: _selectedDocuments.isEmpty || _isUploading
 ? null
 : _uploadDocuments,
 icon: _isUploading ? null : Icons.add,
 ),
 ],
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

 Widget _buildContextTypeChip(String label, IconData icon, bool isSelected) {
 final theme = Theme.of(context);
 return GestureDetector(
 onTap: () {
 setState(() {
 _selectedContextType = label;
 });
 },
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 color: isSelected 
 ? ThemeColors(context).primary.withValues(alpha: 0.1)
 : ThemeColors(context).surface,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
 border: Border.all(
 color: isSelected ? ThemeColors(context).primary : ThemeColors(context).border,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 icon,
 size: 14,
 color: isSelected ? ThemeColors(context).primary : ThemeColors(context).onSurfaceVariant,
 ),
 const SizedBox(width: 6),
 Text(
 label,
 style: TextStyles.bodySmall.copyWith(
 color: isSelected ? ThemeColors(context).primary : ThemeColors(context).onSurfaceVariant,
 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
 ),
 ),
 ],
 ),
 ),
 );
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

 Future<void> _pickFiles() async {
 final result = await FilePicker.platform.pickFiles(
 allowMultiple: true,
 type: FileType.custom,
 allowedExtensions: ['pdf', 'txt', 'md', 'json', 'csv'],
 );

 if (result != null) {
 setState(() {
 for (final file in result.files) {
 if (file.size <= 10 * 1024 * 1024) { // 10MB limit
 _selectedDocuments.add(ContextDocument(
 name: file.name,
 size: file.size,
 extension: file.extension ?? 'unknown',
 path: file.path,
 ));
 }
 }
 });
 }
 }

 void _removeDocument(ContextDocument doc) {
 setState(() {
 _selectedDocuments.remove(doc);
 });
 }

 Future<void> _uploadDocuments() async {
 setState(() {
 _isUploading = true;
 for (final doc in _selectedDocuments) {
 doc.isProcessing = true;
 }
 });

 // Simulate upload process
 for (final doc in _selectedDocuments) {
 await Future.delayed(const Duration(milliseconds: 500));
 setState(() {
 doc.isProcessing = false;
 doc.isUploaded = true;
 });
 }
 
 // Update conversation metadata with new context documents
 if (widget.conversationId != null && _isAgentConversation) {
 final conversationService = ref.read(conversationServiceProvider);
 try {
 final conversation = await conversationService.getConversation(widget.conversationId!);
 if (conversation.metadata != null && conversation.metadata!['type'] == 'agent') {
 // Add new documents to existing context documents
 final existingDocs = List<String>.from(conversation.metadata!['contextDocuments'] ?? []);
 final newDocs = _selectedDocuments.map((doc) => doc.name).toList();
 existingDocs.addAll(newDocs);
 
 // Update metadata
 conversation.metadata!['contextDocuments'] = existingDocs;
 await conversationService.updateConversation(conversation);
 
 // Refresh conversation provider
 ref.invalidate(conversationProvider(widget.conversationId!));
 }
 } catch (e) {
 // Handle error silently
 }
 }

 await Future.delayed(const Duration(milliseconds: 500));

 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Row(
 children: [
 const Icon(Icons.check_circle, color: Colors.white, size: 16),
 const SizedBox(width: 8),
 Text(
 _isAgentConversation
 ? '${_selectedDocuments.length} documents added to $_agentName'
 : '${_selectedDocuments.length} documents added to context',
 style: GoogleFonts.fustat(),
 ),
 ],
 ),
 backgroundColor: ThemeColors(context).success,
 behavior: SnackBarBehavior.floating,
 ),
 );
 Navigator.of(context).pop();
 }
 }
}

class ContextDocument {
 final String name;
 final int size;
 final String extension;
 final String? path;
 bool isProcessing;
 bool isUploaded;

 ContextDocument({
 required this.name,
 required this.size,
 required this.extension,
 this.path,
 this.isProcessing = false,
 this.isUploaded = false,
 });

 String get sizeFormatted {
 if (size < 1024) {
 return '$size B';
 } else if (size < 1024 * 1024) {
 return '${(size / 1024).toStringAsFixed(1)} KB';
 } else {
 return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
 }
 }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/constants/routes.dart';
import '../providers/context_provider.dart';
import '../../data/repositories/context_repository.dart';
import '../widgets/context_creation_flow.dart';
import '../../data/models/context_document.dart';
import '../../data/models/context_assignment.dart';

class ContextLibraryScreen extends ConsumerStatefulWidget {
 const ContextLibraryScreen({super.key});

 @override
 ConsumerState<ContextLibraryScreen> createState() => _ContextLibraryScreenState();
}

class _ContextLibraryScreenState extends ConsumerState<ContextLibraryScreen> {
 int selectedTab = 0; // 0 = My Context, 1 = Context Library
 String searchQuery = '';
 String selectedCategory = 'All';
 bool _showCreateFlow = false;

 final List<String> categories = [
 'All', 'Documentation', 'Codebase', 'Guidelines', 'Examples', 
 'Knowledge', 'Custom', 'API Reference', 'Tutorials', 'Best Practices',
 'Code Samples', 'Architecture', 'Security', 'Performance', 'Testing',
 'Deployment', 'Database', 'Frontend', 'Backend', 'Mobile'
 ];

 final List<ContextTemplate> templates = [
 ContextTemplate(
 name: 'API Documentation Template',
 description: 'Complete REST API documentation with examples',
 category: 'Documentation',
 tags: ['api', 'rest', 'documentation', 'examples'],
 contentPreview: '# API Documentation\n\n## Overview\nThis API provides...\n\n## Endpoints\n\n### GET /api/users\n...',
 useCase: 'Document REST APIs with clear examples and response formats',
 ),
 ContextTemplate(
 name: 'Code Style Guide',
 description: 'Comprehensive coding standards and conventions',
 category: 'Guidelines',
 tags: ['style', 'conventions', 'best-practices', 'standards'],
 contentPreview: '# Code Style Guide\n\n## Naming Conventions\n\n### Variables\n- Use camelCase for variables...',
 useCase: 'Establish consistent coding standards across your team',
 ),
 ContextTemplate(
 name: 'React Component Library',
 description: 'Reusable React components with TypeScript',
 category: 'Codebase',
 tags: ['react', 'typescript', 'components', 'ui'],
 contentPreview: '''// Button Component
import React from 'react';

interface ButtonProps {
 variant: 'primary' | 'secondary';
 children: React.ReactNode;
}''',
 useCase: 'Document and share reusable React component patterns',
 ),
 ContextTemplate(
 name: 'Database Schema Documentation',
 description: 'Complete database structure and relationships',
 category: 'Documentation',
 tags: ['database', 'schema', 'sql', 'relationships'],
 contentPreview: '# Database Schema\n\n## Tables\n\n### users\n- id (Primary Key)\n- email (Unique)\n- created_at...',
 useCase: 'Document database structure and table relationships',
 ),
 ContextTemplate(
 name: 'Security Best Practices',
 description: 'Security guidelines and vulnerability prevention',
 category: 'Guidelines',
 tags: ['security', 'vulnerabilities', 'best-practices', 'authentication'],
 contentPreview: '# Security Guidelines\n\n## Authentication\n\n### Password Requirements\n- Minimum 8 characters...',
 useCase: 'Implement security measures and prevent common vulnerabilities',
 ),
 ContextTemplate(
 name: 'Testing Strategies',
 description: 'Unit, integration, and E2E testing approaches',
 category: 'Best Practices',
 tags: ['testing', 'unit-tests', 'integration', 'e2e'],
 contentPreview: '''# Testing Strategy

## Unit Testing

### Jest Configuration
```javascript
module.exports = {
 testEnvironment: 'node'...''',
 useCase: 'Establish comprehensive testing practices for your codebase',
 ),
 ContextTemplate(
 name: 'Python Data Analysis',
 description: 'Data science workflows with pandas and numpy',
 category: 'Examples',
 tags: ['python', 'pandas', 'numpy', 'data-science'],
 contentPreview: '''# Data Analysis Workflows

## Data Loading

```python
import pandas as pd
import numpy as np

df = pd.read_csv('data.csv')''',
 useCase: 'Analyze data using Python libraries with proven patterns',
 ),
 ContextTemplate(
 name: 'DevOps Pipeline',
 description: 'CI/CD pipeline configuration and deployment',
 category: 'Deployment',
 tags: ['devops', 'ci-cd', 'docker', 'kubernetes'],
 contentPreview: '# CI/CD Pipeline\n\n## GitHub Actions\n\n```yaml\nname: Deploy\non:\n push:\n branches: [main]',
 useCase: 'Set up automated deployment pipelines with best practices',
 ),
 ContextTemplate(
 name: 'Mobile App Architecture',
 description: 'Flutter/React Native app structure patterns',
 category: 'Architecture',
 tags: ['mobile', 'flutter', 'react-native', 'architecture'],
 contentPreview: '# Mobile App Architecture\n\n## Folder Structure\n\n```\nlib/\n├── core/\n│ ├── constants/\n│ └── utils/',
 useCase: 'Structure mobile applications with scalable architecture',
 ),
 ContextTemplate(
 name: 'Cloud Infrastructure',
 description: 'AWS/Azure cloud deployment configurations',
 category: 'Deployment',
 tags: ['cloud', 'aws', 'azure', 'infrastructure'],
 contentPreview: '# Cloud Infrastructure\n\n## AWS Setup\n\n### EC2 Configuration\n```json\n{\n "InstanceType": "t3.micro"',
 useCase: 'Deploy applications to cloud platforms with proper configuration',
 ),
 ];

 List<ContextTemplate> get filteredTemplates {
 return templates.where((template) {
 final matchesSearch = template.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
 template.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
 template.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));
 
 final matchesCategory = selectedCategory == 'All' || template.category == selectedCategory;
 
 return matchesSearch && matchesCategory;
 }).toList();
 }

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 body: Container(
 decoration: BoxDecoration(
 gradient: RadialGradient(
 center: Alignment.topCenter,
 radius: 1.5,
 colors: [
 ThemeColors(context).backgroundGradientStart,
 ThemeColors(context).backgroundGradientMiddle,
 ThemeColors(context).backgroundGradientEnd,
 ],
 stops: const [0.0, 0.6, 1.0],
 ),
 ),
 child: SafeArea(
 child: Column(
 children: [
 // Header
 AppNavigationBar(currentRoute: AppRoutes.context),

 // Main Content
 Expanded(
 child: Padding(
 padding: EdgeInsets.all(SpacingTokens.pageHorizontal),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header with Title and Tab Selector
 Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 selectedTab == 0 ? 'My Context Documents' : 'Context Library',
 style: TextStyles.pageTitle.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 selectedTab == 0 
 ? 'Manage and organize your context documents for AI agents'
 : 'Start with pre-built templates and customize them to your needs',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 SizedBox(width: SpacingTokens.elementSpacing),
 // Tab Selector
 Row(
 children: [
 _TabButton(
 text: 'My Context',
 isSelected: selectedTab == 0,
 onTap: () => setState(() => selectedTab = 0),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 _TabButton(
 text: 'Context Library',
 isSelected: selectedTab == 1,
 onTap: () => setState(() => selectedTab = 1),
 ),
 ],
 ),
 ],
 ),
 SizedBox(height: SpacingTokens.sectionSpacing),

 // Content based on selected tab
 Expanded(
 child: selectedTab == 0 ? _buildMyContextContent() : _buildContextLibraryContent(),
 ),
 ],
 ),
 ),
 ),
 ],
 ),
 ),
 ),
 );
 }

 Widget _buildMyContextContent() {
 final contextDocuments = ref.watch(contextDocumentsProvider);
 
 return contextDocuments.when(
 data: (documents) {
 // Show create flow if requested
 if (_showCreateFlow) {
 return ContextCreationFlow(
 onSave: (document) async {
 await ref.read(contextRepositoryProvider).createDocument(
 title: document.title,
 content: document.content,
 type: document.type,
 tags: document.tags,
 );
 ref.invalidate(contextDocumentsProvider);
 setState(() => _showCreateFlow = false);
 },
 onCancel: () => setState(() => _showCreateFlow = false),
 );
 }

 return Column(
 children: [
 // Create button
 Row(
 mainAxisAlignment: MainAxisAlignment.end,
 children: [
 AsmblButton.primary(
 text: 'Create Document',
 icon: Icons.add,
 onPressed: () => setState(() => _showCreateFlow = true),
 ),
 ],
 ),
 SizedBox(height: SpacingTokens.elementSpacing),
 
 // Documents Grid
 Expanded(
 child: documents.isEmpty 
 ? _buildMyContextEmptyState()
 : GridView.builder(
 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 3,
 crossAxisSpacing: SpacingTokens.componentSpacing,
 mainAxisSpacing: SpacingTokens.componentSpacing,
 childAspectRatio: 1.4,
 ),
 itemCount: documents.length,
 itemBuilder: (context, index) {
 final document = documents[index];
 return _ContextDocumentCard(
 document: document,
 onEdit: () => _editDocument(document),
 onDelete: () => _deleteDocument(document.id),
 onAssign: () => _showAgentAssignmentModal(context, document),
 );
 },
 ),
 ),
 ],
 );
 },
 loading: () => Center(child: CircularProgressIndicator()),
 error: (error, stack) => _buildErrorState(error.toString()),
 );
 }

 Widget _buildContextLibraryContent() {
 return Column(
 children: [
 // Search and Filter Section - Responsive Layout
 LayoutBuilder(
 builder: (context, constraints) {
 // Determine if we should stack (when width is less than 800px)
 final shouldStack = constraints.maxWidth < 800;
 
 if (shouldStack) {
 // Stacked layout for smaller screens
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Search Bar (full width when stacked)
 AsmblCard(
 child: TextField(
 onChanged: (value) => setState(() => searchQuery = value),
 decoration: InputDecoration(
 hintText: 'Search templates...',
 hintStyle: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 prefixIcon: Icon(
 Icons.search,
 color: ThemeColors(context).onSurfaceVariant,
 size: 18,
 ),
 border: InputBorder.none,
 contentPadding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing, 
 vertical: SpacingTokens.sm,
 ),
 ),
 style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurface),
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Filter Chips
 Wrap(
 spacing: SpacingTokens.xs,
 runSpacing: SpacingTokens.xs,
 children: _buildFilterChips(),
 ),
 ],
 );
 } else {
 // Horizontal layout for larger screens
 return Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Search Bar (flexible width)
 Expanded(
 flex: 2,
 child: AsmblCard(
 child: TextField(
 onChanged: (value) => setState(() => searchQuery = value),
 decoration: InputDecoration(
 hintText: 'Search templates...',
 hintStyle: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 prefixIcon: Icon(
 Icons.search,
 color: ThemeColors(context).onSurfaceVariant,
 size: 18,
 ),
 border: InputBorder.none,
 contentPadding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing, 
 vertical: SpacingTokens.sm,
 ),
 ),
 style: TextStyles.bodyMedium.copyWith(color: ThemeColors(context).onSurface),
 ),
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 
 // Filter Chips (flexible width)
 Expanded(
 flex: 3,
 child: Wrap(
 spacing: SpacingTokens.xs,
 runSpacing: SpacingTokens.xs,
 children: _buildFilterChips(),
 ),
 ),
 ],
 );
 }
 },
 ),
 SizedBox(height: SpacingTokens.elementSpacing),
 
 // Templates Grid
 Expanded(
 child: filteredTemplates.isEmpty 
 ? _buildLibraryEmptyState()
 : GridView.builder(
 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 3,
 crossAxisSpacing: SpacingTokens.componentSpacing,
 mainAxisSpacing: SpacingTokens.componentSpacing,
 childAspectRatio: 1.3,
 ),
 itemCount: filteredTemplates.length,
 itemBuilder: (context, index) {
 return _TemplateCard(
 template: filteredTemplates[index],
 onUseTemplate: () => _useTemplate(filteredTemplates[index]),
 );
 },
 ),
 ),
 ],
 );
 }

 Widget _buildMyContextEmptyState() {
 return Center(
 child: AsmblCard(
 isInteractive: false,
 child: Padding(
 padding: EdgeInsets.all(SpacingTokens.sectionSpacing),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.library_books_outlined,
 size: 64,
 color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'No context documents yet',
 style: TextStyles.cardTitle.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 'Create your first context document to get started',
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 AsmblButton.primary(
 text: 'Create Document',
 icon: Icons.add,
 onPressed: () => setState(() => _showCreateFlow = true),
 ),
 ],
 ),
 ),
 ),
 );
 }

 Widget _buildLibraryEmptyState() {
 return Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.search_off,
 size: 48,
 color: ThemeColors(context).onSurfaceVariant.withValues(alpha: 0.5),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'No templates found',
 style: TextStyles.bodyLarge.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 SizedBox(height: SpacingTokens.xs),
 Text(
 'Try adjusting your search or filters',
 style: TextStyles.bodySmall.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 AsmblButton.secondary(
 text: 'Clear Filters',
 onPressed: () {
 setState(() {
 searchQuery = '';
 selectedCategory = 'All';
 });
 },
 ),
 ],
 ),
 );
 }

 Widget _buildErrorState(String error) {
 return Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.error_outline,
 size: 48,
 color: ThemeColors(context).error,
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'Error loading context documents',
 style: TextStyles.pageTitle.copyWith(
 color: ThemeColors(context).onSurface,
 ),
 ),
 SizedBox(height: SpacingTokens.iconSpacing),
 Text(
 error,
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 );
 }

 List<Widget> _buildFilterChips() {
 return categories.map((category) {
 final isSelected = selectedCategory == category;
 return GestureDetector(
 onTap: () => setState(() => selectedCategory = category),
 child: Container(
 padding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.componentSpacing,
 vertical: SpacingTokens.xs,
 ),
 decoration: BoxDecoration(
 color: isSelected 
 ? ThemeColors(context).primary 
 : ThemeColors(context).surfaceVariant.withValues(alpha: 0.7),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.pill),
 border: Border.all(
 color: isSelected 
 ? ThemeColors(context).primary 
 : ThemeColors(context).border,
 width: 1,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 if (category != 'All') ...[
 Icon(
 _getCategoryIcon(category),
 size: 12,
 color: isSelected 
 ? Colors.white 
 : ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 4),
 ],
 Text(
 category,
 style: TextStyles.caption.copyWith(
 color: isSelected 
 ? Colors.white 
 : ThemeColors(context).onSurfaceVariant,
 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
 fontSize: 11,
 ),
 ),
 ],
 ),
 ),
 );
 }).toList();
 }


 void _editDocument(ContextDocument document) {
 // Open edit dialog for the document
 showDialog(
 context: context,
 builder: (context) => AlertDialog(
 title: Text('Edit Document'),
 content: Text('Editing: ${document.title}'),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(context),
 child: const Text('Cancel'),
 ),
 ElevatedButton(
 onPressed: () {
 // Implementation pending
 Navigator.pop(context);
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('Document edit feature coming soon')),
 );
 },
 child: const Text('Save'),
 ),
 ],
 ),
 );
 }

 void _deleteDocument(String documentId) async {
 try {
 await ref.read(contextRepositoryProvider).deleteDocument(documentId);
 ref.invalidate(contextDocumentsProvider);
 } catch (e) {
 // Handle error
 }
 }

 IconData _getCategoryIcon(String category) {
 switch (category) {
 case 'Documentation': return Icons.description;
 case 'Codebase': return Icons.code;
 case 'Guidelines': return Icons.rule;
 case 'Examples': return Icons.lightbulb_outline;
 case 'Knowledge': return Icons.school;
 case 'Custom': return Icons.tune;
 case 'API Reference': return Icons.api;
 case 'Tutorials': return Icons.play_lesson;
 case 'Best Practices': return Icons.star;
 case 'Security': return Icons.security;
 case 'Performance': return Icons.speed;
 case 'Testing': return Icons.bug_report;
 case 'Deployment': return Icons.cloud_upload;
 case 'Database': return Icons.storage;
 case 'Frontend': return Icons.web;
 case 'Backend': return Icons.dns;
 case 'Mobile': return Icons.phone_android;
 default: return Icons.folder;
 }
 }

 void _showAgentAssignmentModal(BuildContext context, ContextDocument document) {
 showDialog(
 context: context,
 builder: (context) => _AgentAssignmentModal(document: document),
 );
 }

 void _useTemplate(ContextTemplate template) {
 // For now, just show a success message and switch to create flow
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Row(
 children: [
 Icon(Icons.check_circle, color: Colors.white, size: 16),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 'Template "${template.name}" will be used to create a new document',
 style: TextStyle(fontFamily: 'Space Grotesk'),
 ),
 ),
 ],
 ),
 backgroundColor: SemanticColors.success,
 behavior: SnackBarBehavior.floating,
 ),
 );
 }
}

class _TabButton extends StatelessWidget {
 final String text;
 final bool isSelected;
 final VoidCallback onTap;

 const _TabButton({
 required this.text,
 required this.isSelected,
 required this.onTap,
 });

 @override
 Widget build(BuildContext context) {
 return isSelected 
 ? AsmblButton.primary(text: text, onPressed: onTap)
 : AsmblButton.secondary(text: text, onPressed: onTap);
 }
}

class _ContextDocumentCard extends StatelessWidget {
 final ContextDocument document;
 final VoidCallback onEdit;
 final VoidCallback onDelete;
 final VoidCallback onAssign;

 const _ContextDocumentCard({
 required this.document,
 required this.onEdit,
 required this.onDelete,
 required this.onAssign,
 });

 @override
 Widget build(BuildContext context) {
 return AsmblCard(
 onTap: onEdit,
 child: Padding(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header with type icon and actions
 Row(
 children: [
 // Type icon
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: ThemeColors(context).surfaceVariant,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 _getTypeIcon(document.type),
 size: 18,
 color: ThemeColors(context).primary,
 ),
 ),
 SizedBox(width: SpacingTokens.sm),
 
 // Document title and type
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 document.title,
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.w600,
 fontSize: 13,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 SizedBox(height: 2),
 Text(
 document.type.displayName,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 10,
 ),
 ),
 ],
 ),
 ),
 
 // Action buttons
 PopupMenuButton(
 icon: Icon(
 Icons.more_vert,
 color: ThemeColors(context).onSurfaceVariant,
 size: 14,
 ),
 padding: EdgeInsets.zero,
 iconSize: 14,
 itemBuilder: (context) => [
 PopupMenuItem(
 value: 'edit',
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.edit, size: 12, color: ThemeColors(context).onSurface),
 SizedBox(width: 6),
 Text('Edit', style: TextStyle(fontSize: 11, color: ThemeColors(context).onSurface)),
 ],
 ),
 ),
 PopupMenuItem(
 value: 'assign',
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.person_add, size: 12, color: ThemeColors(context).onSurface),
 SizedBox(width: 6),
 Text('Assign to Agent', style: TextStyle(fontSize: 11, color: ThemeColors(context).onSurface)),
 ],
 ),
 ),
 PopupMenuItem(
 value: 'duplicate',
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.copy, size: 12, color: ThemeColors(context).onSurface),
 SizedBox(width: 6),
 Text('Duplicate', style: TextStyle(fontSize: 11, color: ThemeColors(context).onSurface)),
 ],
 ),
 ),
 PopupMenuItem(
 value: 'delete',
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.delete, color: Colors.red, size: 12),
 SizedBox(width: 6),
 Text('Delete', style: TextStyle(color: Colors.red, fontSize: 11)),
 ],
 ),
 ),
 ],
 onSelected: (value) {
 switch (value) {
 case 'edit':
 onEdit();
 break;
 case 'assign':
 onAssign();
 break;
 case 'delete':
 onDelete();
 break;
 }
 },
 ),
 ],
 ),
 
 SizedBox(height: SpacingTokens.sm),
 
 // Content preview
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.preview,
 size: 11,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 4),
 Text(
 'Content Preview',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 10,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 SizedBox(height: 4),
 
 // Content preview
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: ThemeColors(context).surfaceVariant.withValues(alpha: 0.3),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 border: Border.all(
 color: ThemeColors(context).border.withValues(alpha: 0.5),
 width: 0.5,
 ),
 ),
 child: Text(
 document.content,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurface,
 fontSize: 10,
 height: 1.2,
 ),
 maxLines: 3,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 
 Spacer(),
 
 // Stats row
 Row(
 children: [
 Icon(
 Icons.access_time,
 size: 10,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 3),
 Expanded(
 child: Text(
 _formatDate(document.updatedAt),
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 9,
 ),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 if (document.tags.isNotEmpty) ...[
 SizedBox(width: SpacingTokens.xs),
 Icon(
 Icons.tag,
 size: 10,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 3),
 Text(
 '${document.tags.length}',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 9,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ],
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 );
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

 String _formatDate(DateTime date) {
 final now = DateTime.now();
 final difference = now.difference(date);
 
 if (difference.inDays < 1) {
 if (difference.inHours < 1) {
 return '${difference.inMinutes}m ago';
 }
 return '${difference.inHours}h ago';
 } else if (difference.inDays < 7) {
 return '${difference.inDays}d ago';
 } else {
 return '${date.day}/${date.month}/${date.year}';
 }
 }
}

class _TemplateCard extends StatelessWidget {
 final ContextTemplate template;
 final VoidCallback onUseTemplate;

 const _TemplateCard({
 required this.template,
 required this.onUseTemplate,
 });

 @override
 Widget build(BuildContext context) {
 return AsmblCard(
 onTap: onUseTemplate,
 child: Padding(
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header with icon, name, and popularity
 Row(
 children: [
 // Category icon
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: ThemeColors(context).surfaceVariant,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 _getCategoryIcon(template.category),
 size: 18,
 color: ThemeColors(context).primary,
 ),
 ),
 SizedBox(width: SpacingTokens.sm),
 
 // Template name and category
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 template.name,
 style: TextStyles.bodyMedium.copyWith(
 color: ThemeColors(context).onSurface,
 fontWeight: FontWeight.w600,
 fontSize: 13,
 ),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 ),
 SizedBox(height: 2),
 Text(
 template.category,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 10,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 
 SizedBox(height: SpacingTokens.sm),
 
 // Use case preview
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.lightbulb_outline,
 size: 11,
 color: ThemeColors(context).onSurfaceVariant,
 ),
 SizedBox(width: 4),
 Text(
 'Use Case',
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurfaceVariant,
 fontSize: 10,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 SizedBox(height: 4),
 
 // Use case
 Container(
 padding: EdgeInsets.all(SpacingTokens.xs),
 decoration: BoxDecoration(
 color: ThemeColors(context).primary.withValues(alpha: 0.05),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 border: Border.all(
 color: ThemeColors(context).primary.withValues(alpha: 0.1),
 width: 0.5,
 ),
 ),
 child: Text(
 template.useCase,
 style: TextStyles.caption.copyWith(
 color: ThemeColors(context).onSurface,
 fontSize: 10,
 height: 1.2,
 ),
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 ),
 ),
 
 Spacer(),
 
 // Action buttons row
 Row(
 children: [
 Expanded(
 child: AsmblButton.secondary(
 text: 'Preview',
 icon: Icons.visibility_outlined,
 onPressed: () => _showTemplatePreview(context, template),
 ),
 ),
 SizedBox(width: SpacingTokens.xs),
 Expanded(
 child: AsmblButton.primary(
 text: 'Add',
 icon: Icons.add,
 onPressed: onUseTemplate,
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 );
 }

 IconData _getCategoryIcon(String category) {
 switch (category) {
 case 'Documentation': return Icons.description;
 case 'Codebase': return Icons.code;
 case 'Guidelines': return Icons.rule;
 case 'Examples': return Icons.lightbulb_outline;
 case 'Knowledge': return Icons.school;
 case 'Custom': return Icons.tune;
 case 'API Reference': return Icons.api;
 case 'Tutorials': return Icons.play_lesson;
 case 'Best Practices': return Icons.star;
 case 'Security': return Icons.security;
 case 'Performance': return Icons.speed;
 case 'Testing': return Icons.bug_report;
 case 'Deployment': return Icons.cloud_upload;
 case 'Database': return Icons.storage;
 case 'Frontend': return Icons.web;
 case 'Backend': return Icons.dns;
 case 'Mobile': return Icons.phone_android;
 default: return Icons.folder;
 }
 }

 void _showTemplatePreview(BuildContext context, ContextTemplate template) {
 showDialog(
 context: context,
 builder: (context) => Dialog(
 backgroundColor: ColorTokens.surface,
 child: Container(
 width: 600,
 height: 500,
 padding: EdgeInsets.all(SpacingTokens.xl),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header
 Row(
 children: [
 Container(
 padding: EdgeInsets.all(SpacingTokens.sm),
 decoration: BoxDecoration(
 color: ColorTokens.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 _getCategoryIcon(template.category),
 color: ColorTokens.primary,
 size: 20,
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 template.name,
 style: TextStyles.cardTitle.copyWith(
 color: ColorTokens.foreground,
 ),
 ),
 Text(
 template.category,
 style: TextStyles.bodySmall.copyWith(
 color: ColorTokens.mutedForeground,
 ),
 ),
 ],
 ),
 ),
 IconButton(
 onPressed: () => Navigator.of(context).pop(),
 icon: Icon(Icons.close),
 color: ColorTokens.mutedForeground,
 ),
 ],
 ),
 SizedBox(height: SpacingTokens.elementSpacing),
 
 // Description and use case
 Text(
 'Description',
 style: TextStyles.bodyLarge.copyWith(
 color: ColorTokens.foreground,
 fontWeight: FontWeight.w600,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 template.description,
 style: TextStyles.bodyMedium.copyWith(
 color: ColorTokens.mutedForeground,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'Use Case',
 style: TextStyles.bodyLarge.copyWith(
 color: ColorTokens.foreground,
 fontWeight: FontWeight.w600,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 template.useCase,
 style: TextStyles.bodyMedium.copyWith(
 color: ColorTokens.mutedForeground,
 ),
 ),
 SizedBox(height: SpacingTokens.elementSpacing),
 
 // Content preview
 Text(
 'Content Preview',
 style: TextStyles.bodyLarge.copyWith(
 color: ColorTokens.foreground,
 fontWeight: FontWeight.w600,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Expanded(
 child: Container(
 width: double.infinity,
 padding: EdgeInsets.all(SpacingTokens.componentSpacing),
 decoration: BoxDecoration(
 color: ColorTokens.muted,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 border: Border.all(color: ColorTokens.border),
 ),
 child: SingleChildScrollView(
 child: Text(
 template.contentPreview,
 style: TextStyles.bodySmall.copyWith(
 color: ColorTokens.foreground,
 fontFamily: 'monospace',
 ),
 ),
 ),
 ),
 ),
 SizedBox(height: SpacingTokens.elementSpacing),
 
 // Actions
 Row(
 mainAxisAlignment: MainAxisAlignment.end,
 children: [
 AsmblButton.secondary(
 text: 'Cancel',
 onPressed: () => Navigator.of(context).pop(),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 AsmblButton.primary(
 text: 'Use Template',
 icon: Icons.add,
 onPressed: () {
 Navigator.of(context).pop();
 onUseTemplate();
 },
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

class _AgentAssignmentModal extends StatefulWidget {
 final ContextDocument document;

 const _AgentAssignmentModal({required this.document});

 @override
 State<_AgentAssignmentModal> createState() => _AgentAssignmentModalState();
}

class _AgentAssignmentModalState extends State<_AgentAssignmentModal> {
 String? selectedAgentId;
 int priority = 0;
 bool isLoading = false;

 // Sample agents data - in real app this would come from a provider
 final List<AgentItem> availableAgents = [
 AgentItem(
 id: 'agent-1',
 name: 'Research Assistant',
 description: 'Academic research agent with citation management',
 category: 'Research',
 isActive: true,
 lastUsed: DateTime.now().subtract(Duration(minutes: 15)),
 totalChats: 23,
 recentChats: [],
 ),
 AgentItem(
 id: 'agent-2', 
 name: 'Code Reviewer',
 description: 'Automated code review with best practices',
 category: 'Development',
 isActive: true,
 lastUsed: DateTime.now().subtract(Duration(hours: 2)),
 totalChats: 8,
 recentChats: [],
 ),
 AgentItem(
 id: 'agent-3',
 name: 'Content Writer',
 description: 'Creative writing and content generation',
 category: 'Writing',
 isActive: false,
 lastUsed: DateTime.now().subtract(const Duration(days: 5)),
 totalChats: 15,
 recentChats: [],
 ),
 AgentItem(
 id: 'agent-4',
 name: 'Data Analyst',
 description: 'Statistical analysis and data visualization',
 category: 'Data Analysis',
 isActive: true,
 lastUsed: DateTime.now().subtract(const Duration(hours: 6)),
 totalChats: 12,
 recentChats: [],
 ),
 ];

 @override
 Widget build(BuildContext context) {
 return Dialog(
 backgroundColor: ColorTokens.surface,
 child: Container(
 width: 500,
 height: 600,
 padding: EdgeInsets.all(SpacingTokens.xl),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Header
 Row(
 children: [
 Container(
 padding: EdgeInsets.all(SpacingTokens.sm),
 decoration: BoxDecoration(
 color: ColorTokens.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 Icons.person_add,
 color: ColorTokens.primary,
 size: 20,
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Assign to Agent',
 style: TextStyles.cardTitle.copyWith(
 color: ColorTokens.foreground,
 ),
 ),
 Text(
 'Document: ${widget.document.title}',
 style: TextStyles.bodySmall.copyWith(
 color: ColorTokens.mutedForeground,
 ),
 ),
 ],
 ),
 ),
 IconButton(
 onPressed: () => Navigator.of(context).pop(),
 icon: Icon(Icons.close),
 color: ColorTokens.mutedForeground,
 ),
 ],
 ),
 SizedBox(height: SpacingTokens.elementSpacing),
 
 // Available Agents
 Text(
 'Select Agent',
 style: TextStyles.bodyLarge.copyWith(
 color: ColorTokens.foreground,
 fontWeight: FontWeight.w600,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 
 // Agents List
 Expanded(
 child: Container(
 decoration: BoxDecoration(
 border: Border.all(color: ColorTokens.border),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
 ),
 child: ListView.separated(
 itemCount: availableAgents.length,
 separatorBuilder: (context, index) => Divider(
 color: ColorTokens.border,
 height: 1,
 ),
 itemBuilder: (context, index) {
 final agent = availableAgents[index];
 final isSelected = selectedAgentId == agent.id;
 
 return ListTile(
 contentPadding: EdgeInsets.all(SpacingTokens.componentSpacing),
 leading: Container(
 width: 40,
 height: 40,
 decoration: BoxDecoration(
 color: agent.isActive 
 ? ColorTokens.primary.withValues(alpha: 0.1)
 : ColorTokens.mutedForeground.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Icon(
 agent.isActive ? Icons.smart_toy : Icons.smart_toy_outlined,
 color: agent.isActive ? ColorTokens.primary : ColorTokens.mutedForeground,
 size: 20,
 ),
 ),
 title: Row(
 children: [
 Expanded(
 child: Text(
 agent.name,
 style: TextStyles.bodyMedium.copyWith(
 color: ColorTokens.foreground,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 if (!agent.isActive)
 Container(
 padding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.xs,
 vertical: 2,
 ),
 decoration: BoxDecoration(
 color: ColorTokens.mutedForeground.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Text(
 'INACTIVE',
 style: TextStyles.caption.copyWith(
 color: ColorTokens.mutedForeground,
 fontSize: 9,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 ],
 ),
 subtitle: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 SizedBox(height: 4),
 Text(
 agent.description,
 style: TextStyles.bodySmall.copyWith(
 color: ColorTokens.mutedForeground,
 ),
 ),
 SizedBox(height: 4),
 Row(
 children: [
 Container(
 padding: EdgeInsets.symmetric(
 horizontal: SpacingTokens.xs,
 vertical: 2,
 ),
 decoration: BoxDecoration(
 color: ColorTokens.primary.withValues(alpha: 0.1),
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Text(
 agent.category,
 style: TextStyles.caption.copyWith(
 color: ColorTokens.primary,
 fontSize: 10,
 ),
 ),
 ),
 SizedBox(width: SpacingTokens.xs),
 Text(
 '${agent.totalChats} chats',
 style: TextStyles.caption.copyWith(
 color: ColorTokens.mutedForeground,
 fontSize: 10,
 ),
 ),
 ],
 ),
 ],
 ),
 trailing: Radio<String>(
 value: agent.id,
 groupValue: selectedAgentId,
 onChanged: agent.isActive ? (value) {
 setState(() {
 selectedAgentId = value;
 });
 } : null,
 activeColor: ColorTokens.primary,
 ),
 selected: isSelected,
 selectedTileColor: ColorTokens.primary.withValues(alpha: 0.05),
 onTap: agent.isActive ? () {
 setState(() {
 selectedAgentId = agent.id;
 });
 } : null,
 );
 },
 ),
 ),
 ),
 
 SizedBox(height: SpacingTokens.elementSpacing),
 
 // Priority Selector
 if (selectedAgentId != null) ...[
 Text(
 'Priority Level',
 style: TextStyles.bodyLarge.copyWith(
 color: ColorTokens.foreground,
 fontWeight: FontWeight.w600,
 ),
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Row(
 children: [
 Expanded(
 child: Slider(
 value: priority.toDouble(),
 min: 0,
 max: 10,
 divisions: 10,
 label: priority.toString(),
 activeColor: ColorTokens.primary,
 inactiveColor: ColorTokens.border,
 onChanged: (value) {
 setState(() {
 priority = value.round();
 });
 },
 ),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 Container(
 width: 40,
 height: 30,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 color: ColorTokens.muted,
 borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
 ),
 child: Text(
 priority.toString(),
 style: TextStyles.bodyMedium.copyWith(
 color: ColorTokens.foreground,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 ],
 ),
 SizedBox(height: SpacingTokens.componentSpacing),
 Text(
 'Higher priority documents will be processed first by the agent.',
 style: TextStyles.caption.copyWith(
 color: ColorTokens.mutedForeground,
 ),
 ),
 SizedBox(height: SpacingTokens.elementSpacing),
 ],
 
 // Actions
 Row(
 mainAxisAlignment: MainAxisAlignment.end,
 children: [
 AsmblButton.secondary(
 text: 'Cancel',
 onPressed: () => Navigator.of(context).pop(),
 ),
 SizedBox(width: SpacingTokens.componentSpacing),
 AsmblButton.primary(
 text: isLoading ? 'Assigning...' : 'Assign Document',
 icon: isLoading ? null : Icons.person_add,
 onPressed: selectedAgentId == null || isLoading ? null : _assignDocument,
 ),
 ],
 ),
 ],
 ),
 ),
 );
 }

 Future<void> _assignDocument() async {
 if (selectedAgentId == null) return;
 
 setState(() => isLoading = true);
 
 try {
 // Create assignment through repository
 final assignment = ContextAssignment(
 id: DateTime.now().millisecondsSinceEpoch.toString(),
 contextDocumentId: widget.document.id,
 agentId: selectedAgentId!,
 assignedAt: DateTime.now(),
 );
 
 // Save assignment (simulated for now, will connect to repository when available)
 await Future.delayed(const Duration(seconds: 1)); // Placeholder for actual API call
 
 if (mounted) {
 Navigator.of(context).pop();
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Row(
 children: [
 Icon(Icons.check_circle, color: Colors.white, size: 16),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 'Document "${widget.document.title}" assigned to ${availableAgents.firstWhere((a) => a.id == selectedAgentId).name}',
 style: TextStyle(fontFamily: 'Space Grotesk'),
 ),
 ),
 ],
 ),
 backgroundColor: SemanticColors.success,
 behavior: SnackBarBehavior.floating,
 ),
 );
 }
 } catch (e) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text('Failed to assign document: $e'),
 backgroundColor: SemanticColors.error,
 behavior: SnackBarBehavior.floating,
 ),
 );
 }
 } finally {
 if (mounted) {
 setState(() => isLoading = false);
 }
 }
 }
}

class AgentItem {
 final String id;
 final String name;
 final String description;
 final String category;
 final bool isActive;
 final DateTime lastUsed;
 final int totalChats;
 final List<String> recentChats;

 AgentItem({
 required this.id,
 required this.name,
 required this.description,
 required this.category,
 required this.isActive,
 required this.lastUsed,
 required this.totalChats,
 required this.recentChats,
 });
}

class ContextTemplate {
 final String name;
 final String description;
 final String category;
 final List<String> tags;
 final String contentPreview;
 final String useCase;

 ContextTemplate({
 required this.name,
 required this.description,
 required this.category,
 required this.tags,
 required this.contentPreview,
 required this.useCase,
 });
}
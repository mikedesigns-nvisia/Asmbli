import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/context_document.dart';
import '../models/context_assignment.dart';
import '../../../../core/services/desktop/desktop_storage_service.dart';

/// Repository for managing context documents and assignments
class ContextRepository {
 static const String _documentsKey = 'context_documents';
 static const String _assignmentsKey = 'context_assignments';
 
 final Uuid _uuid = const Uuid();
 
 /// Get all context documents
 Future<List<ContextDocument>> getDocuments() async {
 try {
 final String? documentsJson = DesktopStorageService.instance.getPreference<String>(_documentsKey);
 if (documentsJson == null) return [];
 
 final List<dynamic> documentsList = jsonDecode(documentsJson);
 return documentsList
 .map((json) => ContextDocument.fromJson(json))
 .toList();
 } catch (e) {
 print('Error loading context documents: $e');
 return [];
 }
 }

 /// Get documents by type
 Future<List<ContextDocument>> getDocumentsByType(ContextType type) async {
 final documents = await getDocuments();
 return documents.where((doc) => doc.type == type && doc.isActive).toList();
 }

 /// Get documents by tags
 Future<List<ContextDocument>> getDocumentsByTags(List<String> tags) async {
 final documents = await getDocuments();
 return documents.where((doc) {
 return doc.isActive && 
 tags.any((tag) => doc.tags.contains(tag));
 }).toList();
 }

 /// Search documents by title or content
 Future<List<ContextDocument>> searchDocuments(String query) async {
 final documents = await getDocuments();
 final lowercaseQuery = query.toLowerCase();
 
 return documents.where((doc) {
 return doc.isActive &&
 (doc.title.toLowerCase().contains(lowercaseQuery) ||
 doc.content.toLowerCase().contains(lowercaseQuery) ||
 doc.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)));
 }).toList();
 }

 /// Create a new context document
 Future<ContextDocument> createDocument({
 required String title,
 required String content,
 required ContextType type,
 List<String> tags = const [],
 Map<String, dynamic> metadata = const {},
 }) async {
 final document = ContextDocument(
 id: _uuid.v4(),
 title: title,
 content: content,
 type: type,
 tags: tags,
 createdAt: DateTime.now(),
 updatedAt: DateTime.now(),
 metadata: metadata,
 );

 await _saveDocument(document);
 return document;
 }

 /// Add a context document (for compatibility with providers)
 Future<ContextDocument> addDocument(ContextDocument document) async {
 await _saveDocument(document);
 return document;
 }

 /// Update an existing context document
 Future<ContextDocument> updateDocument(ContextDocument document) async {
 final updatedDocument = document.copyWith(
 updatedAt: DateTime.now(),
 );
 
 await _saveDocument(updatedDocument);
 return updatedDocument;
 }

 /// Delete a context document
 Future<void> deleteDocument(String documentId) async {
 final documents = await getDocuments();
 final updatedDocuments = documents
 .where((doc) => doc.id != documentId)
 .toList();
 
 await _saveDocuments(updatedDocuments);
 
 // Also remove any assignments for this document
 await _removeAssignmentsForDocument(documentId);
 }

 /// Save a single document
 Future<void> _saveDocument(ContextDocument document) async {
 final documents = await getDocuments();
 final index = documents.indexWhere((doc) => doc.id == document.id);
 
 if (index >= 0) {
 documents[index] = document;
 } else {
 documents.add(document);
 }
 
 await _saveDocuments(documents);
 }

 /// Save all documents
 Future<void> _saveDocuments(List<ContextDocument> documents) async {
 final documentsJson = jsonEncode(
 documents.map((doc) => doc.toJson()).toList(),
 );
 await DesktopStorageService.instance.setPreference<String>(_documentsKey, documentsJson);
 }

 /// Get all context assignments
 Future<List<ContextAssignment>> getAssignments() async {
 try {
 final String? assignmentsJson = DesktopStorageService.instance.getPreference<String>(_assignmentsKey);
 if (assignmentsJson == null) return [];
 
 final List<dynamic> assignmentsList = jsonDecode(assignmentsJson);
 return assignmentsList
 .map((json) => ContextAssignment.fromJson(json))
 .toList();
 } catch (e) {
 print('Error loading context assignments: $e');
 return [];
 }
 }

 /// Get assignments for a specific agent
 Future<List<ContextAssignment>> getAssignmentsForAgent(String agentId) async {
 final assignments = await getAssignments();
 return assignments
 .where((assignment) => assignment.agentId == agentId && assignment.isActive)
 .toList()
 ..sort((a, b) => b.priority.compareTo(a.priority)); // Sort by priority desc
 }

 /// Get assignments for a specific document
 Future<List<ContextAssignment>> getAssignmentsForDocument(String documentId) async {
 final assignments = await getAssignments();
 return assignments
 .where((assignment) => assignment.contextDocumentId == documentId && assignment.isActive)
 .toList();
 }

 /// Assign a context document to an agent
 Future<ContextAssignment> assignDocumentToAgent({
 required String agentId,
 required String contextDocumentId,
 int priority = 0,
 Map<String, dynamic> settings = const {},
 }) async {
 final assignment = ContextAssignment(
 id: _uuid.v4(),
 agentId: agentId,
 contextDocumentId: contextDocumentId,
 assignedAt: DateTime.now(),
 priority: priority,
 settings: settings,
 );

 await _saveAssignment(assignment);
 return assignment;
 }

 /// Update a context assignment
 Future<ContextAssignment> updateAssignment(ContextAssignment assignment) async {
 await _saveAssignment(assignment);
 return assignment;
 }

 /// Remove a context assignment
 Future<void> removeAssignment(String assignmentId) async {
 final assignments = await getAssignments();
 final updatedAssignments = assignments
 .where((assignment) => assignment.id != assignmentId)
 .toList();
 
 await _saveAssignments(updatedAssignments);
 }

 /// Remove all assignments for a specific document
 Future<void> _removeAssignmentsForDocument(String documentId) async {
 final assignments = await getAssignments();
 final updatedAssignments = assignments
 .where((assignment) => assignment.contextDocumentId != documentId)
 .toList();
 
 await _saveAssignments(updatedAssignments);
 }

 /// Save a single assignment
 Future<void> _saveAssignment(ContextAssignment assignment) async {
 final assignments = await getAssignments();
 final index = assignments.indexWhere((a) => a.id == assignment.id);
 
 if (index >= 0) {
 assignments[index] = assignment;
 } else {
 assignments.add(assignment);
 }
 
 await _saveAssignments(assignments);
 }

 /// Save all assignments
 Future<void> _saveAssignments(List<ContextAssignment> assignments) async {
 final assignmentsJson = jsonEncode(
 assignments.map((assignment) => assignment.toJson()).toList(),
 );
 await DesktopStorageService.instance.setPreference<String>(_assignmentsKey, assignmentsJson);
 }

 /// Get context documents assigned to an agent (with document details)
 Future<List<ContextDocument>> getContextForAgent(String agentId) async {
 final assignments = await getAssignmentsForAgent(agentId);
 final documents = await getDocuments();
 
 final contextDocuments = <ContextDocument>[];
 for (final assignment in assignments) {
 final document = documents.firstWhere(
 (doc) => doc.id == assignment.contextDocumentId && doc.isActive,
 orElse: () => throw StateError('Document not found'),
 );
 contextDocuments.add(document);
 }
 
 return contextDocuments;
 }

 /// DEBUG: Sync missing vector database document back to context repository
 Future<void> syncVectorDatabaseDocument() async {
   try {
     // Create the missing README.md document from vector database data
     final missingDocument = ContextDocument(
       id: 'f8948349-cfc4-4518-a46f-89a2d64a5861',
       title: 'README.md',
       content: '''# Asmbli Desktop

Professional agent builder for developers with local MCP server integration.

## Features

- Full wizard-based agent creation flow
- Local MCP server integration for filesystem, git, and other tools
- Advanced configuration options for power users
- Direct filesystem access for local development
- Git integration for version control
- Desktop application connections
- Template library with community contributions
- Export agents for deployment

## Setup

### Prerequisites

1. Install Flutter SDK (3.24.3 or later)
   - Download from https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. Enable desktop support
   ```bash
   flutter config --enable-windows-desktop  # For Windows
   flutter config --enable-macos-desktop    # For macOS
   flutter config --enable-linux-desktop    # For Linux
   ```

### Installation

1. Navigate to the desktop app directory
   ```bash
   cd apps/desktop
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the application
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d macos    # For macOS
   flutter run -d linux    # For Linux
   ```

### Building for Distribution

1. Build release version
   ```bash
   flutter build windows  # For Windows
   flutter build macos    # For macOS
   flutter build linux    # For Linux
   ```

2. The built application will be in:
   - Windows: `build/windows/x64/runner/Release/`
   - macOS: `build/macos/Build/Products/Release/`
   - Linux: `build/linux/x64/release/bundle/`

## Architecture

The desktop application provides:

- **Wizard Flow**: Complete agent configuration wizard from the web version
- **MCP Integration**: Direct integration with Model Context Protocol servers
- **Local Storage**: Agent configurations stored locally with cloud sync option
- **Template System**: Access to community templates and ability to create custom ones
- **Export Options**: Multiple deployment formats for different platforms

## Development

### Project Structure

```
apps/desktop/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable widgets
│   ├── services/              # API and MCP services
│   ├── models/                # Data models
│   └── utils/                 # Utility functions
├── assets/                    # Images, fonts, etc.
├── test/                      # Unit and widget tests
└── pubspec.yaml              # Dependencies
```

### API Integration

The desktop app connects to the Asmbli platform API for:
- Template library access
- Cloud synchronization
- Community sharing features

### MCP Server Support

Supported MCP servers include:
- Filesystem access
- Git operations
- GitHub integration
- Figma design tools
- Database connections
- Custom server implementations

## Contributing

Please see the main repository README for contribution guidelines.

## License

See LICENSE file in the root directory.''',
       type: ContextType.documentation,
       tags: ['uploaded', 'session'],
       isActive: true,
       createdAt: DateTime.parse('2025-09-06T13:23:25.935179'),
       updatedAt: DateTime.parse('2025-09-06T13:23:25.935179'),
       metadata: {
         'uploadedAt': '2025-09-06T13:23:25.932177',
         'fileSize': 3081,
         'fileName': 'README.md',
         'fileExtension': 'md',
       },
     );

     await _saveDocument(missingDocument);
     print('✅ Successfully synced vector database document to context repository');
   } catch (e) {
     print('❌ Failed to sync vector database document: $e');
     rethrow;
   }
 }
}

/// Provider for the context repository
final contextRepositoryProvider = Provider<ContextRepository>((ref) {
 return ContextRepository();
});
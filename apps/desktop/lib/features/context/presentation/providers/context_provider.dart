import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/context_document.dart';
import '../../data/models/context_assignment.dart';
import '../../data/repositories/context_repository.dart';

/// Provider for context documents
final contextDocumentsProvider = FutureProvider<List<ContextDocument>>((ref) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getDocuments();
});

/// Provider for context documents filtered by type
final contextDocumentsByTypeProvider = FutureProvider.family<List<ContextDocument>, ContextType>((ref, type) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getDocumentsByType(type);
});

/// Provider for context assignments
final contextAssignmentsProvider = FutureProvider<List<ContextAssignment>>((ref) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getAssignments();
});

/// Provider for context assignments for a specific agent
final contextAssignmentsForAgentProvider = FutureProvider.family<List<ContextAssignment>, String>((ref, agentId) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getAssignmentsForAgent(agentId);
});

/// Provider for context documents assigned to a specific agent
final contextForAgentProvider = FutureProvider.family<List<ContextDocument>, String>((ref, agentId) async {
 final repository = ref.read(contextRepositoryProvider);
 return repository.getContextForAgent(agentId);
});

/// Provider for searching context documents
final searchContextDocumentsProvider = FutureProvider.family<List<ContextDocument>, String>((ref, query) async {
 if (query.isEmpty) {
 return ref.read(contextDocumentsProvider.future);
 }
 
 final repository = ref.read(contextRepositoryProvider);
 return repository.searchDocuments(query);
});
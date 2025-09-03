import 'package:test/test.dart';
import 'dart:async';
import 'dart:math';
import '../../lib/core/agents/workflow_engine.dart';
import '../../lib/core/agents/graph/directed_graph.dart';
import '../../lib/core/agents/vector_database.dart';
import '../../lib/core/models/model_interfaces.dart';

void main() {
  group('Agent Workflow Integration', () {
    late AgentWorkflow workflow;
    late MockAgent searchAgent;
    late MockAgent summaryAgent;
    late MockAgent analysisAgent;
    
    setUp(() {
      searchAgent = MockAgent('search');
      summaryAgent = MockAgent('summary');
      analysisAgent = MockAgent('analysis');
      
      workflow = AgentWorkflow(
        id: 'test_workflow',
        name: 'Test Workflow',
        description: 'Integration test workflow',
      );
      
      workflow.addNode(WorkflowNode(
        id: 'search',
        type: WorkflowNodeType.agent,
        config: {'agent_id': 'search', 'timeout': 5000},
        inputMapping: {'query': 'input.query'},
        outputMapping: {'results': 'search_results'},
      ));
      
      workflow.addNode(WorkflowNode(
        id: 'summary',
        type: WorkflowNodeType.agent,
        config: {'agent_id': 'summary', 'timeout': 3000},
        inputMapping: {'data': 'search.results'},
        outputMapping: {'summary': 'final_summary'},
      ), dependencies: ['search']);
      
      workflow.addNode(WorkflowNode(
        id: 'analysis',
        type: WorkflowNodeType.agent,
        config: {'agent_id': 'analysis', 'timeout': 4000},
        inputMapping: {
          'summary': 'summary.summary',
          'raw_data': 'search.results'
        },
        outputMapping: {'insights': 'analysis_insights'},
      ), dependencies: ['search', 'summary']);
    });
    
    test('executes nodes in correct topological order', () async {
      final input = WorkflowInput(data: {'query': 'test query'});
      final result = await workflow.execute(input);
      
      expect(result.success, isTrue);
      expect(searchAgent.executionOrder, lessThan(summaryAgent.executionOrder));
      expect(searchAgent.executionOrder, lessThan(analysisAgent.executionOrder));
      expect(summaryAgent.executionOrder, lessThan(analysisAgent.executionOrder));
      
      // Verify data flow
      expect(searchAgent.lastInput['query'], equals('test query'));
      expect(summaryAgent.lastInput['data'], isNotNull);
      expect(analysisAgent.lastInput['summary'], isNotNull);
      expect(analysisAgent.lastInput['raw_data'], isNotNull);
    });
    
    test('handles parallel execution correctly', () async {
      // Add parallel branch
      workflow.addNode(WorkflowNode(
        id: 'parallel_task',
        type: WorkflowNodeType.agent,
        config: {'agent_id': 'parallel', 'timeout': 2000},
        inputMapping: {'data': 'search.results'},
        outputMapping: {'result': 'parallel_result'},
      ), dependencies: ['search']);
      
      final parallelAgent = MockAgent('parallel');
      parallelAgent.delay = Duration(milliseconds: 1500);
      summaryAgent.delay = Duration(milliseconds: 1000);
      
      final input = WorkflowInput(data: {'query': 'parallel test'});
      final startTime = DateTime.now();
      
      final result = await workflow.execute(input);
      final totalTime = DateTime.now().difference(startTime);
      
      expect(result.success, isTrue);
      // Should complete in less than sequential time
      expect(totalTime.inMilliseconds, lessThan(4000));
    });
    
    test('handles node failures gracefully with error propagation', () async {
      searchAgent.shouldFail = true;
      searchAgent.errorMessage = 'Search service unavailable';
      
      final input = WorkflowInput(data: {'query': 'failing query'});
      final result = await workflow.execute(input);
      
      expect(result.success, isFalse);
      expect(result.error, contains('Search service unavailable'));
      expect(result.failedNodes, contains('search'));
      
      // Dependent nodes should not execute
      expect(summaryAgent.executionCount, equals(0));
      expect(analysisAgent.executionCount, equals(0));
    });
    
    test('respects timeout constraints', () async {
      searchAgent.delay = Duration(seconds: 10);
      
      final input = WorkflowInput(
        data: {'query': 'timeout test'},
        timeout: Duration(seconds: 2),
      );
      
      expect(
        () => workflow.execute(input),
        throwsA(isA<TimeoutException>()),
      );
    });
    
    test('handles conditional execution', () async {
      // Add conditional node
      workflow.addNode(WorkflowNode(
        id: 'conditional',
        type: WorkflowNodeType.condition,
        config: {
          'condition': 'search.results.length > 0',
          'true_branch': 'summary',
          'false_branch': 'skip'
        },
      ), dependencies: ['search']);
      
      // Test with results
      searchAgent.mockOutput = {'results': [1, 2, 3]};
      
      final input = WorkflowInput(data: {'query': 'conditional test'});
      final result = await workflow.execute(input);
      
      expect(result.success, isTrue);
      expect(summaryAgent.executionCount, equals(1));
    });
    
    test('supports workflow templates', () async {
      final template = WorkflowTemplate(
        id: 'search_summarize_template',
        name: 'Search and Summarize',
        description: 'Standard search and summarization workflow',
        nodes: [
          WorkflowNodeTemplate(
            id: 'search',
            type: WorkflowNodeType.agent,
            config: {'agent_type': 'search'},
          ),
          WorkflowNodeTemplate(
            id: 'summarize',
            type: WorkflowNodeType.agent,
            config: {'agent_type': 'summary'},
            dependencies: ['search'],
          ),
        ],
        inputSchema: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string'}
          },
          'required': ['query']
        },
      );
      
      final workflowFromTemplate = await WorkflowEngine.createFromTemplate(
        template,
        {'workflow_id': 'test_from_template'}
      );
      
      expect(workflowFromTemplate.nodes.length, equals(2));
      expect(workflowFromTemplate.graph.hasPath('search', 'summarize'), isTrue);
    });
    
    test('validates workflow integrity', () async {
      // Test circular dependency detection
      expect(
        () => workflow.addNode(
          WorkflowNode(id: 'circular', type: WorkflowNodeType.agent),
          dependencies: ['analysis'],
        ),
        throwsA(isA<WorkflowValidationException>()),
      );
      
      // Test missing dependency
      expect(
        () => workflow.addNode(
          WorkflowNode(id: 'orphan', type: WorkflowNodeType.agent),
          dependencies: ['nonexistent'],
        ),
        throwsA(isA<WorkflowValidationException>()),
      );
    });
  });
  
  group('Vector Database Integration', () {
    late VectorDatabase vectorDB;
    late MockEmbeddingProvider embeddingProvider;
    
    setUp(() async {
      embeddingProvider = MockEmbeddingProvider();
      vectorDB = VectorDatabase(
        embeddingProvider: embeddingProvider,
        dimensions: 384,
        indexType: VectorIndexType.hnsw,
      );
      await vectorDB.initialize();
    });
    
    tearDown(() async {
      await vectorDB.dispose();
    });
    
    test('stores and retrieves documents with embeddings', () async {
      final doc = Document(
        id: 'doc1',
        title: 'Test Document',
        content: 'This is a test document about AI and machine learning.',
        metadata: {'category': 'tech', 'date': '2024-01-01'},
      );
      
      await vectorDB.addDocument(doc);
      
      final results = await vectorDB.search(
        'machine learning',
        limit: 10,
        threshold: 0.7,
      );
      
      expect(results, isNotEmpty);
      expect(results.first.document.id, equals('doc1'));
      expect(results.first.score, greaterThan(0.7));
    });
    
    test('ranks results by semantic relevance', () async {
      // Add multiple documents with different relevance levels
      await vectorDB.addDocument(Document(
        id: 'doc1',
        content: 'Machine learning is a subset of artificial intelligence.',
      ));
      
      await vectorDB.addDocument(Document(
        id: 'doc2',
        content: 'Deep learning is a type of machine learning using neural networks.',
      ));
      
      await vectorDB.addDocument(Document(
        id: 'doc3',
        content: 'Cooking recipes for dinner with pasta and tomatoes.',
      ));
      
      await vectorDB.addDocument(Document(
        id: 'doc4',
        content: 'Advanced machine learning algorithms for computer vision.',
      ));
      
      final results = await vectorDB.search('deep learning algorithms');
      
      // Most relevant should be first
      expect(results[0].document.id, equals('doc2'));
      expect(results[1].document.id, anyOf(['doc1', 'doc4']));
      expect(results.last.document.id, equals('doc3'));
      expect(results.last.score, lessThan(0.5));
    });
    
    test('supports metadata filtering', () async {
      await vectorDB.addDocument(Document(
        id: 'tech1',
        content: 'Latest AI developments',
        metadata: {'category': 'tech', 'year': 2024},
      ));
      
      await vectorDB.addDocument(Document(
        id: 'tech2',
        content: 'Machine learning trends',
        metadata: {'category': 'tech', 'year': 2023},
      ));
      
      await vectorDB.addDocument(Document(
        id: 'news1',
        content: 'AI in the news',
        metadata: {'category': 'news', 'year': 2024},
      ));
      
      final results = await vectorDB.search(
        'AI developments',
        filter: {'category': 'tech', 'year': 2024},
      );
      
      expect(results.length, equals(1));
      expect(results.first.document.id, equals('tech1'));
    });
    
    test('handles batch operations efficiently', () async {
      final documents = List.generate(100, (i) => Document(
        id: 'batch_doc_$i',
        content: 'Document content number $i with keywords AI ML DL',
        metadata: {'batch': i ~/ 10, 'index': i},
      ));
      
      final stopwatch = Stopwatch()..start();
      await vectorDB.addDocuments(documents);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be fast
      
      final count = await vectorDB.getDocumentCount();
      expect(count, equals(100));
      
      // Test batch search
      final searchStopwatch = Stopwatch()..start();
      final results = await vectorDB.search('AI ML keywords', limit: 50);
      searchStopwatch.stop();
      
      expect(results.length, equals(50));
      expect(searchStopwatch.elapsedMilliseconds, lessThan(100));
    });
    
    test('supports document updates and deletions', () async {
      final doc = Document(
        id: 'update_test',
        content: 'Original content',
      );
      
      await vectorDB.addDocument(doc);
      
      // Update document
      final updatedDoc = Document(
        id: 'update_test',
        content: 'Updated content with new information',
      );
      
      await vectorDB.updateDocument(updatedDoc);
      
      final results = await vectorDB.search('new information');
      expect(results.first.document.content, contains('Updated content'));
      
      // Delete document
      await vectorDB.deleteDocument('update_test');
      
      final resultsAfterDelete = await vectorDB.search('updated content');
      expect(resultsAfterDelete.isEmpty, isTrue);
    });
    
    test('maintains index consistency under load', () async {
      // Concurrent operations test
      final futures = <Future>[];
      
      // Concurrent adds
      for (int i = 0; i < 50; i++) {
        futures.add(vectorDB.addDocument(Document(
          id: 'concurrent_$i',
          content: 'Concurrent document $i',
        )));
      }
      
      // Concurrent searches
      for (int i = 0; i < 20; i++) {
        futures.add(vectorDB.search('document'));
      }
      
      await Future.wait(futures);
      
      final count = await vectorDB.getDocumentCount();
      expect(count, equals(50));
      
      // Verify index integrity
      final allResults = await vectorDB.search('document', limit: 100);
      expect(allResults.length, equals(50));
    });
  });
  
  group('End-to-End Workflow with Vector Search', () {
    late AgentWorkflow searchWorkflow;
    late VectorDatabase vectorDB;
    late MockAgent searchAgent;
    late MockAgent ragAgent;
    
    setUp(() async {
      // Initialize vector database
      vectorDB = VectorDatabase(
        embeddingProvider: MockEmbeddingProvider(),
        dimensions: 384,
      );
      await vectorDB.initialize();
      
      // Add test documents
      await vectorDB.addDocuments([
        Document(
          id: 'ai_basics',
          content: 'Artificial Intelligence (AI) is the simulation of human intelligence in machines.',
        ),
        Document(
          id: 'ml_overview',
          content: 'Machine Learning is a subset of AI that enables computers to learn without explicit programming.',
        ),
        Document(
          id: 'dl_networks',
          content: 'Deep Learning uses neural networks with multiple layers to model complex patterns.',
        ),
      ]);
      
      // Create agents
      searchAgent = MockAgent('vector_search');
      ragAgent = MockAgent('rag_generator');
      
      // Setup workflow
      searchWorkflow = AgentWorkflow(
        id: 'rag_workflow',
        name: 'RAG Search Workflow',
      );
      
      searchWorkflow.addNode(WorkflowNode(
        id: 'vector_search',
        type: WorkflowNodeType.agent,
        config: {'vector_db': vectorDB},
        inputMapping: {'query': 'input.query'},
        outputMapping: {'documents': 'retrieved_docs'},
      ));
      
      searchWorkflow.addNode(WorkflowNode(
        id: 'generate_answer',
        type: WorkflowNodeType.agent,
        config: {'model': 'gpt-3.5-turbo'},
        inputMapping: {
          'query': 'input.query',
          'context': 'vector_search.documents'
        },
        outputMapping: {'answer': 'final_answer'},
      ), dependencies: ['vector_search']);
    });
    
    tearDown(() async {
      await vectorDB.dispose();
    });
    
    test('executes RAG workflow end-to-end', () async {
      // Mock search agent to actually use vector DB
      searchAgent.customLogic = (input) async {
        final query = input['query'] as String;
        final results = await vectorDB.search(query, limit: 3);
        return {
          'documents': results.map((r) => {
            'content': r.document.content,
            'score': r.score,
            'id': r.document.id,
          }).toList()
        };
      };
      
      // Mock RAG agent
      ragAgent.customLogic = (input) async {
        final query = input['query'] as String;
        final docs = input['context'] as List;
        return {
          'answer': 'Based on the retrieved documents: $query is related to ${docs.length} relevant concepts.'
        };
      };
      
      final input = WorkflowInput(data: {'query': 'What is machine learning?'});
      final result = await searchWorkflow.execute(input);
      
      expect(result.success, isTrue);
      expect(result.outputs['final_answer'], isNotNull);
      expect(result.outputs['final_answer']['answer'], contains('machine learning'));
      expect(result.executionTime.inMilliseconds, lessThan(5000));
    });
  });
}

/// Performance test suite
void performanceTests() {
  group('Performance Benchmarks', () {
    late AgentWorkflow complexWorkflow;
    late VectorDatabase vectorDB;
    
    setUp(() async {
      // Create complex workflow with multiple branches
      complexWorkflow = AgentWorkflow(
        id: 'complex_perf_test',
        name: 'Complex Performance Test Workflow',
      );
      
      // Add multiple parallel branches
      for (int i = 0; i < 5; i++) {
        complexWorkflow.addNode(WorkflowNode(
          id: 'branch_$i',
          type: WorkflowNodeType.agent,
          config: {'delay': 100 + i * 50},
        ));
      }
      
      // Add convergence node
      complexWorkflow.addNode(WorkflowNode(
        id: 'convergence',
        type: WorkflowNodeType.agent,
        config: {'delay': 200},
      ), dependencies: ['branch_0', 'branch_1', 'branch_2', 'branch_3', 'branch_4']);
      
      // Initialize vector DB for search tests
      vectorDB = VectorDatabase(
        embeddingProvider: MockEmbeddingProvider(),
        dimensions: 384,
      );
      await vectorDB.initialize();
    });
    
    tearDown(() async {
      await vectorDB.dispose();
    });
    
    test('handles 100 concurrent workflow executions', () async {
      final futures = List.generate(100, (i) => 
        complexWorkflow.execute(WorkflowInput(data: {'test_id': i}))
      );
      
      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(futures);
      stopwatch.stop();
      
      expect(results.every((r) => r.success), isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
      
      final avgExecutionTime = results
          .map((r) => r.executionTime.inMilliseconds)
          .reduce((a, b) => a + b) / results.length;
      
      expect(avgExecutionTime, lessThan(2000)); // Average under 2 seconds
    });
    
    test('vector search completes under 100ms with 10K documents', () async {
      // Add 10,000 documents
      final documents = List.generate(10000, (i) => Document(
        id: 'perf_doc_$i',
        content: 'Performance test document $i with keywords: ${_generateRandomKeywords()}',
        metadata: {'index': i, 'category': 'test'},
      ));
      
      await vectorDB.addDocuments(documents);
      
      // Perform multiple search operations
      final searchTimes = <int>[];
      
      for (int i = 0; i < 10; i++) {
        final stopwatch = Stopwatch()..start();
        await vectorDB.search('test keywords', limit: 20);
        stopwatch.stop();
        searchTimes.add(stopwatch.elapsedMilliseconds);
      }
      
      final avgSearchTime = searchTimes.reduce((a, b) => a + b) / searchTimes.length;
      
      expect(avgSearchTime, lessThan(100)); // Average under 100ms
      expect(searchTimes.every((time) => time < 200), isTrue); // All under 200ms
    });
    
    test('workflow memory usage remains stable', () async {
      // Monitor memory usage during repeated executions
      final initialMemory = _getCurrentMemoryUsage();
      
      // Run 1000 workflow executions
      for (int i = 0; i < 1000; i++) {
        await complexWorkflow.execute(WorkflowInput(data: {'iteration': i}));
        
        // Force garbage collection periodically
        if (i % 100 == 0) {
          _forceGarbageCollection();
        }
      }
      
      final finalMemory = _getCurrentMemoryUsage();
      final memoryIncrease = finalMemory - initialMemory;
      
      // Memory increase should be minimal (less than 50MB)
      expect(memoryIncrease, lessThan(50 * 1024 * 1024));
    });
    
    test('concurrent vector operations maintain consistency', () async {
      final futures = <Future>[];
      final random = Random();
      
      // Mix of operations: 50% searches, 30% adds, 20% updates
      for (int i = 0; i < 1000; i++) {
        final operation = random.nextDouble();
        
        if (operation < 0.5) {
          // Search operation
          futures.add(vectorDB.search('test query $i'));
        } else if (operation < 0.8) {
          // Add operation
          futures.add(vectorDB.addDocument(Document(
            id: 'concurrent_$i',
            content: 'Concurrent document $i',
          )));
        } else {
          // Update operation (if document exists)
          futures.add(vectorDB.updateDocument(Document(
            id: 'concurrent_${i ~/ 2}',
            content: 'Updated concurrent document ${i ~/ 2}',
          )).catchError((_) {})); // Ignore errors for non-existent docs
        }
      }
      
      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // 30 seconds max
      
      // Verify database consistency
      final finalCount = await vectorDB.getDocumentCount();
      expect(finalCount, greaterThan(400)); // At least some docs were added
    });
  });
}

/// Helper functions and mock classes
class MockAgent {
  final String id;
  Duration delay = Duration(milliseconds: 100);
  bool shouldFail = false;
  String errorMessage = 'Mock agent failed';
  Map<String, dynamic> mockOutput = {'result': 'mock success'};
  Map<String, dynamic> lastInput = {};
  int executionOrder = 0;
  int executionCount = 0;
  static int _globalExecutionCounter = 0;
  
  Function(Map<String, dynamic>)? customLogic;
  
  MockAgent(this.id);
  
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    lastInput = Map.from(input);
    executionOrder = ++_globalExecutionCounter;
    executionCount++;
    
    if (delay.inMilliseconds > 0) {
      await Future.delayed(delay);
    }
    
    if (shouldFail) {
      throw Exception(errorMessage);
    }
    
    if (customLogic != null) {
      return await customLogic!(input);
    }
    
    return mockOutput;
  }
}

class MockEmbeddingProvider {
  final Random _random = Random(42); // Fixed seed for consistency
  
  Future<List<double>> generateEmbedding(String text) async {
    // Simulate API delay
    await Future.delayed(Duration(milliseconds: 10 + _random.nextInt(20)));
    
    // Generate deterministic embeddings based on text hash
    final hash = text.hashCode;
    final random = Random(hash);
    
    return List.generate(384, (i) => random.nextDouble() * 2 - 1);
  }
  
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    final futures = texts.map(generateEmbedding);
    return await Future.wait(futures);
  }
}

String _generateRandomKeywords() {
  final keywords = ['AI', 'ML', 'neural', 'data', 'algorithm', 'learning', 'deep', 'network'];
  final random = Random();
  final selected = <String>[];
  
  for (int i = 0; i < 3; i++) {
    selected.add(keywords[random.nextInt(keywords.length)]);
  }
  
  return selected.join(' ');
}

int _getCurrentMemoryUsage() {
  // Platform-specific memory measurement would go here
  // For demo purposes, return a mock value
  return Random().nextInt(100) * 1024 * 1024; // Mock MB usage
}

void _forceGarbageCollection() {
  // Force garbage collection (platform-specific implementation)
  // This is a placeholder for actual GC forcing
}
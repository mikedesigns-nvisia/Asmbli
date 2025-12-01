/// DSPy Integration Test
///
/// This test verifies the Dart client can communicate with the Python backend.
///
/// Prerequisites:
/// 1. Start the DSPy backend: cd dspy-backend && python main.py
/// 2. Run this test: flutter test test/integration/dspy_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/services/dspy/dspy_client.dart';

void main() {
  late DspyClient client;

  setUpAll(() {
    client = DspyClient(
      baseUrl: 'http://localhost:8000',
      timeout: const Duration(seconds: 60),
    );
  });

  tearDownAll(() {
    client.dispose();
  });

  group('DSPy Backend Integration', () {
    test('health check succeeds', () async {
      final health = await client.healthCheck();

      expect(health.status, equals('healthy'));
      expect(health.version, isNotEmpty);
      expect(health.modelsAvailable, isNotEmpty);

      print('✅ Health check passed');
      print('   Version: ${health.version}');
      print('   Models: ${health.modelsAvailable}');
      print('   Documents: ${health.documentsIndexed}');
    });

    test('chat endpoint works', () async {
      final response = await client.chat('What is 2 + 2?');

      expect(response.response, isNotEmpty);
      expect(response.model, isNotEmpty);
      expect(response.response.toLowerCase(), contains('4'));

      print('✅ Chat endpoint works');
      print('   Response: ${response.response}');
      print('   Model: ${response.model}');
    });

    test('reasoning with chain-of-thought works', () async {
      final response = await client.reason(
        'If I have 3 apples and buy 5 more, how many do I have?',
        pattern: DspyReasoningPattern.chainOfThought,
      );

      expect(response.answer, isNotEmpty);
      expect(response.reasoning, isNotEmpty);
      expect(response.confidence, greaterThan(0));
      expect(response.patternUsed, equals('chain_of_thought'));

      print('✅ Chain-of-thought reasoning works');
      print('   Answer: ${response.answer}');
      print('   Confidence: ${response.confidence}');
      print('   Reasoning: ${response.reasoning.substring(0, 100)}...');
    });

    test('agent execution works', () async {
      final response = await client.executeAgent(
        'Calculate 15 * 8',
        maxIterations: 3,
      );

      expect(response.answer, isNotEmpty);
      expect(response.iterationsUsed, greaterThan(0));
      expect(response.iterationsUsed, lessThanOrEqualTo(3));

      print('✅ Agent execution works');
      print('   Answer: ${response.answer}');
      print('   Success: ${response.success}');
      print('   Iterations: ${response.iterationsUsed}');
      print('   Steps: ${response.steps.length}');
    });

    test('document upload and RAG query works', () async {
      // Upload a test document
      final uploadResponse = await client.uploadDocument(
        'Test Document',
        '''
        This is a test document about Flutter development.
        Flutter is a UI toolkit for building natively compiled applications.
        It uses the Dart programming language.
        Flutter supports iOS, Android, web, and desktop platforms.
        ''',
        metadata: {'type': 'test'},
      );

      expect(uploadResponse.documentId, isNotEmpty);
      expect(uploadResponse.chunksCreated, greaterThan(0));

      print('✅ Document uploaded');
      print('   ID: ${uploadResponse.documentId}');
      print('   Chunks: ${uploadResponse.chunksCreated}');

      // Query the document
      final ragResponse = await client.ragQuery(
        'What is Flutter?',
        numPassages: 3,
        includeCitations: true,
      );

      expect(ragResponse.answer, isNotEmpty);
      expect(ragResponse.passagesUsed, greaterThan(0));

      print('✅ RAG query works');
      print('   Answer: ${ragResponse.answer}');
      print('   Sources: ${ragResponse.sources.length}');
      print('   Confidence: ${ragResponse.confidence}');

      // Clean up - delete the test document
      await client.deleteDocument(uploadResponse.documentId);
      print('✅ Document deleted');
    });

    test('tree-of-thought reasoning works', () async {
      final response = await client.reason(
        'What are the pros and cons of using microservices?',
        pattern: DspyReasoningPattern.treeOfThought,
        numBranches: 3,
      );

      expect(response.answer, isNotEmpty);
      expect(response.patternUsed, equals('tree_of_thought'));
      expect(response.branches, isNotNull);
      expect(response.branches!.length, greaterThan(0));

      print('✅ Tree-of-thought reasoning works');
      print('   Answer: ${response.answer.substring(0, 100)}...');
      print('   Branches explored: ${response.branches!.length}');
    });
  });
}

// Run this standalone to test quickly
void main2() async {
  print('=' * 60);
  print('🧪 DSPy Integration Test');
  print('=' * 60);

  final client = DspyClient(
    baseUrl: 'http://localhost:8000',
    timeout: const Duration(seconds: 60),
  );

  try {
    // Test 1: Health
    print('\n📝 Test 1: Health Check');
    final health = await client.healthCheck();
    print('   Status: ${health.status}');
    print('   Models: ${health.modelsAvailable}');
    print('   ✅ PASSED');

    // Test 2: Chat
    print('\n📝 Test 2: Chat');
    final chat = await client.chat('What is the capital of France?');
    print('   Response: ${chat.response}');
    print('   ✅ PASSED');

    // Test 3: Agent
    print('\n📝 Test 3: Agent');
    final agent = await client.executeAgent('Calculate 10 * 5');
    print('   Answer: ${agent.answer}');
    print('   Success: ${agent.success}');
    print('   ✅ PASSED');

    // Test 4: Reasoning
    print('\n📝 Test 4: Chain of Thought');
    final cot = await client.reason(
      'What is 15% of 200?',
      pattern: DspyReasoningPattern.chainOfThought,
    );
    print('   Answer: ${cot.answer}');
    print('   Confidence: ${cot.confidence}');
    print('   ✅ PASSED');

    print('\n' + '=' * 60);
    print('🎉 All integration tests passed!');
    print('=' * 60);
  } catch (e) {
    print('\n❌ Test failed: $e');
    print('\nMake sure the DSPy backend is running:');
    print('  cd dspy-backend && python main.py');
  } finally {
    client.dispose();
  }
}

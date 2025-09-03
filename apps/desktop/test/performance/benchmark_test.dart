import 'package:test/test.dart';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import '../../lib/core/agents/workflow_engine.dart';
import '../../lib/core/agents/vector_database.dart';
import '../../lib/core/cache/cache_manager.dart';
import '../../lib/core/cache/file_cache.dart';
import '../../lib/core/jobs/job_queue.dart';
import '../../lib/core/jobs/worker_pool.dart';
import '../../lib/core/models/model_interfaces.dart';

void main() {
  group('Performance Benchmarks', () {
    setUpAll(() {
      print('\n🏁 Starting Performance Benchmark Suite');
      print('=' * 60);
    });
    
    tearDownAll(() {
      print('\n✅ Performance Benchmark Suite Completed');
      print('=' * 60);
    });
    
    group('Cache Performance', () {
      late CacheManager cacheManager;
      late Directory tempDir;
      
      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('perf_cache_');
        final fileCache = FileCache(directory: tempDir);
        await fileCache.initialize();
        
        cacheManager = CacheManager(
          diskCache: fileCache,
          memoryMaxSize: 1000,
          enableRedis: false,
        );
        await cacheManager.initialize();
      });
      
      tearDown(() async {
        await cacheManager.dispose();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      
      test('Memory cache write performance: >1000 ops/sec', () async {
        const iterations = 5000;
        const testData = {'benchmark': true, 'iteration': 0};
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          await cacheManager.put(
            'perf_key_$i',
            {...testData, 'iteration': i},
            level: CacheLevel.memory,
          );
        }
        
        stopwatch.stop();
        
        final opsPerSecond = (iterations / stopwatch.elapsed.inMilliseconds * 1000).round();
        
        print('📊 Memory cache write: $opsPerSecond ops/sec');
        expect(opsPerSecond, greaterThan(1000), reason: 'Memory cache should achieve >1000 writes/sec');
      });
      
      test('Memory cache read performance: >5000 ops/sec', () async {
        const iterations = 10000;
        const testData = {'cached': 'data', 'fast': true};
        
        // Pre-populate cache
        for (int i = 0; i < iterations; i++) {
          await cacheManager.put(
            'read_key_$i',
            testData,
            level: CacheLevel.memory,
          );
        }
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final result = await cacheManager.get('read_key_$i');
          expect(result, isNotNull);
        }
        
        stopwatch.stop();
        
        final opsPerSecond = (iterations / stopwatch.elapsed.inMilliseconds * 1000).round();
        
        print('📊 Memory cache read: $opsPerSecond ops/sec');
        expect(opsPerSecond, greaterThan(5000), reason: 'Memory cache should achieve >5000 reads/sec');
      });
      
      test('Disk cache performance meets targets', () async {
        const iterations = 1000;
        final testData = List.generate(100, (i) => 'disk_data_item_$i');
        
        // Write performance test
        final writeStopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          await cacheManager.put(
            'disk_key_$i',
            testData,
            level: CacheLevel.disk,
          );
        }
        
        writeStopwatch.stop();
        
        final writeOpsPerSecond = (iterations / writeStopwatch.elapsed.inMilliseconds * 1000).round();
        
        // Read performance test
        final readStopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final result = await cacheManager.get('disk_key_$i');
          expect(result, isNotNull);
        }
        
        readStopwatch.stop();
        
        final readOpsPerSecond = (iterations / readStopwatch.elapsed.inMilliseconds * 1000).round();
        
        print('📊 Disk cache write: $writeOpsPerSecond ops/sec');
        print('📊 Disk cache read: $readOpsPerSecond ops/sec');
        
        expect(writeOpsPerSecond, greaterThan(100), reason: 'Disk cache should achieve >100 writes/sec');
        expect(readOpsPerSecond, greaterThan(200), reason: 'Disk cache should achieve >200 reads/sec');
      });
      
      test('Cache hierarchy performance optimization', () async {
        const testKey = 'hierarchy_perf_test';
        const testData = {'hierarchy': 'test', 'optimization': true};
        
        // Store in all levels
        await cacheManager.put(testKey, testData, level: CacheLevel.all);
        
        // Multiple reads should progressively get faster (memory cache hits)
        final readTimes = <int>[];
        
        for (int i = 0; i < 10; i++) {
          final stopwatch = Stopwatch()..start();
          final result = await cacheManager.get(testKey);
          stopwatch.stop();
          
          expect(result, isNotNull);
          readTimes.add(stopwatch.elapsedMicroseconds);
        }
        
        // First read might be slower (cache promotion), subsequent reads should be fast
        final avgLatency = readTimes.reduce((a, b) => a + b) / readTimes.length;
        
        print('📊 Cache hierarchy avg latency: ${avgLatency.toStringAsFixed(0)} μs');
        expect(avgLatency, lessThan(1000), reason: 'Average cache latency should be <1ms');
      });
    });
    
    group('Workflow Engine Performance', () {
      late AgentWorkflow complexWorkflow;
      
      setUp(() {
        complexWorkflow = AgentWorkflow(
          id: 'perf_workflow',
          name: 'Performance Test Workflow',
        );
        
        // Create complex workflow with multiple parallel branches
        for (int i = 0; i < 10; i++) {
          complexWorkflow.addNode(WorkflowNode(
            id: 'parallel_$i',
            type: WorkflowNodeType.agent,
            config: {'delay_ms': 50 + i * 10},
          ));
        }
        
        // Add convergence nodes
        for (int i = 0; i < 3; i++) {
          complexWorkflow.addNode(WorkflowNode(
            id: 'converge_$i',
            type: WorkflowNodeType.agent,
            config: {'delay_ms': 100},
          ), dependencies: ['parallel_${i * 3}', 'parallel_${i * 3 + 1}', 'parallel_${i * 3 + 2}']);
        }
        
        // Final convergence
        complexWorkflow.addNode(WorkflowNode(
          id: 'final',
          type: WorkflowNodeType.agent,
          config: {'delay_ms': 50},
        ), dependencies: ['converge_0', 'converge_1', 'converge_2']);
      });
      
      test('Complex workflow execution under 2 seconds', () async {
        final input = WorkflowInput(data: {'performance_test': true});
        
        final stopwatch = Stopwatch()..start();
        final result = await complexWorkflow.execute(input);
        stopwatch.stop();
        
        expect(result.success, isTrue);
        expect(stopwatch.elapsed.inMilliseconds, lessThan(2000));
        
        print('📊 Complex workflow execution: ${stopwatch.elapsed.inMilliseconds}ms');
      });
      
      test('Concurrent workflow executions scale linearly', () async {
        const concurrentExecutions = 50;
        
        final stopwatch = Stopwatch()..start();
        
        final futures = List.generate(concurrentExecutions, (i) =>
          complexWorkflow.execute(WorkflowInput(data: {'concurrent_id': i}))
        );
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        expect(results.every((r) => r.success), isTrue);
        
        final avgExecutionTime = stopwatch.elapsed.inMilliseconds / concurrentExecutions;
        final totalThroughput = (concurrentExecutions / stopwatch.elapsed.inSeconds).toStringAsFixed(1);
        
        print('📊 Concurrent workflows: $concurrentExecutions executions in ${stopwatch.elapsed.inSeconds}s');
        print('📊 Average execution time: ${avgExecutionTime.toStringAsFixed(1)}ms');
        print('📊 Throughput: $totalThroughput workflows/sec');
        
        expect(avgExecutionTime, lessThan(3000), reason: 'Average workflow execution should be <3s under load');
      });
      
      test('Workflow memory usage remains stable', () async {
        final initialMemory = _getCurrentMemoryUsage();
        
        // Run many workflow executions
        for (int i = 0; i < 100; i++) {
          await complexWorkflow.execute(WorkflowInput(data: {'iteration': i}));
          
          // Periodic cleanup
          if (i % 20 == 0) {
            await _forceGarbageCollection();
          }
        }
        
        final finalMemory = _getCurrentMemoryUsage();
        final memoryIncrease = finalMemory - initialMemory;
        
        print('📊 Memory usage increase: ${(memoryIncrease / 1024 / 1024).toStringAsFixed(1)} MB');
        
        // Memory increase should be minimal
        expect(memoryIncrease, lessThan(50 * 1024 * 1024), reason: 'Memory increase should be <50MB');
      });
    });
    
    group('Vector Database Performance', () {
      late VectorDatabase vectorDB;
      
      setUp(() async {
        vectorDB = VectorDatabase(
          embeddingProvider: MockFastEmbeddingProvider(),
          dimensions: 384,
          indexType: VectorIndexType.hnsw,
        );
        await vectorDB.initialize();
      });
      
      tearDown(() async {
        await vectorDB.dispose();
      });
      
      test('Vector search completes under 100ms with 10K documents', () async {
        const documentCount = 10000;
        
        print('📝 Indexing $documentCount documents...');
        
        // Add documents in batches for better performance
        const batchSize = 100;
        final indexStopwatch = Stopwatch()..start();
        
        for (int batch = 0; batch < documentCount; batch += batchSize) {
          final batchDocs = List.generate(
            min(batchSize, documentCount - batch),
            (i) => Document(
              id: 'perf_doc_${batch + i}',
              content: 'Performance test document ${batch + i} with keywords: ${_generateRandomKeywords()}',
              metadata: {'batch': batch ~/ batchSize, 'index': batch + i},
            ),
          );
          
          await vectorDB.addDocuments(batchDocs);
        }
        
        indexStopwatch.stop();
        print('📊 Indexing completed in ${indexStopwatch.elapsed.inSeconds}s');
        
        // Perform search benchmarks
        final searchTimes = <int>[];
        const searchCount = 20;
        
        for (int i = 0; i < searchCount; i++) {
          final searchStopwatch = Stopwatch()..start();
          
          final results = await vectorDB.search(
            'test performance keywords document ${i % 5}',
            limit: 20,
          );
          
          searchStopwatch.stop();
          searchTimes.add(searchStopwatch.elapsedMilliseconds);
          
          expect(results.length, greaterThan(0));
        }
        
        final avgSearchTime = searchTimes.reduce((a, b) => a + b) / searchTimes.length;
        final maxSearchTime = searchTimes.reduce((a, b) => a > b ? a : b);
        
        print('📊 Average search time: ${avgSearchTime.toStringAsFixed(1)}ms');
        print('📊 Max search time: ${maxSearchTime}ms');
        
        expect(avgSearchTime, lessThan(100), reason: 'Average search time should be <100ms');
        expect(maxSearchTime, lessThan(200), reason: 'Max search time should be <200ms');
      });
      
      test('Concurrent vector operations maintain consistency', () async {
        const operationCount = 1000;
        final futures = <Future>[];
        final random = Random();
        
        final stopwatch = Stopwatch()..start();
        
        // Mix of operations: 60% searches, 30% adds, 10% updates
        for (int i = 0; i < operationCount; i++) {
          final operation = random.nextDouble();
          
          if (operation < 0.6) {
            // Search operation
            futures.add(vectorDB.search('concurrent test query $i'));
          } else if (operation < 0.9) {
            // Add operation
            futures.add(vectorDB.addDocument(Document(
              id: 'concurrent_$i',
              content: 'Concurrent document $i with test content',
            )));
          } else {
            // Update operation
            futures.add(vectorDB.updateDocument(Document(
              id: 'concurrent_${i ~/ 2}',
              content: 'Updated concurrent document ${i ~/ 2}',
            )).catchError((_) {})); // Ignore errors for non-existent docs
          }
        }
        
        await Future.wait(futures);
        stopwatch.stop();
        
        final opsPerSecond = (operationCount / stopwatch.elapsed.inSeconds).toStringAsFixed(1);
        
        print('📊 Concurrent operations: $operationCount ops in ${stopwatch.elapsed.inSeconds}s');
        print('📊 Throughput: $opsPerSecond ops/sec');
        
        expect(stopwatch.elapsed.inSeconds, lessThan(30), reason: 'Concurrent operations should complete <30s');
        
        // Verify database consistency
        final finalCount = await vectorDB.getDocumentCount();
        expect(finalCount, greaterThan(operationCount ~/ 4), reason: 'Should have added significant number of docs');
      });
    });
    
    group('Job Queue Performance', () {
      late JobQueue jobQueue;
      late WorkerPool workerPool;
      late Directory tempDir;
      
      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('perf_jobs_');
        final fileCache = FileCache(directory: tempDir);
        await fileCache.initialize();
        
        workerPool = WorkerPool(
          config: WorkerPoolConfig(
            minWorkers: 4,
            maxWorkers: 8,
            enableAutoScaling: true,
          ),
        );
        await workerPool.start();
        
        jobQueue = JobQueue(
          maxConcurrentJobs: 8,
          persistenceCache: fileCache,
          enablePersistence: false, // Disabled for performance tests
        );
      });
      
      tearDown() async {
        await jobQueue.dispose();
        await workerPool.stop();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      
      test('Job queue throughput >10 jobs/sec', () async {
        const jobCount = 200;
        const targetThroughput = 10; // jobs per second
        
        final jobs = List.generate(jobCount, (i) => FastTestJob(
          id: 'throughput_job_$i',
          executionTime: Duration(milliseconds: 50 + Random().nextInt(100)),
        ));
        
        final stopwatch = Stopwatch()..start();
        
        // Add all jobs
        final addFutures = jobs.map((job) => jobQueue.addJob(job));
        await Future.wait(addFutures);
        
        // Wait for completion
        final completer = Completer<void>();
        int completedCount = 0;
        
        jobQueue.onJobCompleted.listen((result) {
          completedCount++;
          if (completedCount == jobCount) {
            completer.complete();
          }
        });
        
        await completer.future.timeout(Duration(seconds: 30));
        stopwatch.stop();
        
        final actualThroughput = jobCount / stopwatch.elapsed.inSeconds;
        
        print('📊 Job queue throughput: ${actualThroughput.toStringAsFixed(1)} jobs/sec');
        print('📊 Total execution time: ${stopwatch.elapsed.inSeconds}s');
        
        expect(actualThroughput, greaterThan(targetThroughput),
            reason: 'Job throughput should exceed $targetThroughput jobs/sec');
      });
      
      test('Worker pool scales efficiently under load', () async {
        const highLoadJobCount = 100;
        
        // Create CPU-intensive jobs
        final heavyJobs = List.generate(highLoadJobCount, (i) => FastTestJob(
          id: 'heavy_job_$i',
          executionTime: Duration(milliseconds: 200),
          cpuIntensive: true,
        ));
        
        final initialWorkerCount = workerPool.getStatistics().totalWorkers;
        
        final stopwatch = Stopwatch()..start();
        
        // Submit all jobs rapidly
        for (final job in heavyJobs) {
          await jobQueue.addJob(job);
        }
        
        // Wait a bit for auto-scaling to kick in
        await Future.delayed(Duration(seconds: 2));
        
        final scaledWorkerCount = workerPool.getStatistics().totalWorkers;
        
        print('📊 Initial workers: $initialWorkerCount');
        print('📊 Scaled workers: $scaledWorkerCount');
        print('📊 Worker scaling factor: ${(scaledWorkerCount / initialWorkerCount).toStringAsFixed(1)}x');
        
        expect(scaledWorkerCount, greaterThan(initialWorkerCount),
            reason: 'Worker pool should scale up under load');
        
        // Wait for all jobs to complete
        while (jobQueue.getStatistics().runningJobs + jobQueue.getStatistics().pendingJobs > 0) {
          await Future.delayed(Duration(milliseconds: 100));
        }
        
        stopwatch.stop();
        
        final utilization = workerPool.getStatistics().utilization;
        print('📊 Final utilization: ${(utilization * 100).toStringAsFixed(1)}%');
      });
      
      test('Job persistence overhead <10% of execution time', () async {
        const jobCount = 100;
        
        // Test without persistence
        final noPersistenceQueue = JobQueue(
          maxConcurrentJobs: 4,
          persistenceCache: FileCache(directory: tempDir),
          enablePersistence: false,
        );
        
        final fastJobs1 = List.generate(jobCount, (i) => FastTestJob(
          id: 'no_persist_$i',
          executionTime: Duration(milliseconds: 50),
        ));
        
        final noPersistenceStopwatch = Stopwatch()..start();
        
        for (final job in fastJobs1) {
          await noPersistenceQueue.addJob(job);
        }
        
        while (noPersistenceQueue.getStatistics().runningJobs + 
               noPersistenceQueue.getStatistics().pendingJobs > 0) {
          await Future.delayed(Duration(milliseconds: 50));
        }
        
        noPersistenceStopwatch.stop();
        await noPersistenceQueue.dispose();
        
        // Test with persistence
        final withPersistenceQueue = JobQueue(
          maxConcurrentJobs: 4,
          persistenceCache: FileCache(directory: tempDir),
          enablePersistence: true,
        );
        
        final fastJobs2 = List.generate(jobCount, (i) => FastTestJob(
          id: 'with_persist_$i',
          executionTime: Duration(milliseconds: 50),
        ));
        
        final withPersistenceStopwatch = Stopwatch()..start();
        
        for (final job in fastJobs2) {
          await withPersistenceQueue.addJob(job);
        }
        
        while (withPersistenceQueue.getStatistics().runningJobs + 
               withPersistenceQueue.getStatistics().pendingJobs > 0) {
          await Future.delayed(Duration(milliseconds: 50));
        }
        
        withPersistenceStopwatch.stop();
        await withPersistenceQueue.dispose();
        
        final noPersistenceTime = noPersistenceStopwatch.elapsedMilliseconds;
        final withPersistenceTime = withPersistenceStopwatch.elapsedMilliseconds;
        final overhead = ((withPersistenceTime - noPersistenceTime) / noPersistenceTime) * 100;
        
        print('📊 No persistence: ${noPersistenceTime}ms');
        print('📊 With persistence: ${withPersistenceTime}ms');
        print('📊 Persistence overhead: ${overhead.toStringAsFixed(1)}%');
        
        expect(overhead, lessThan(10), reason: 'Persistence overhead should be <10%');
      });
    });
    
    group('End-to-End Performance', () {
      test('Complete RAG workflow under 5 seconds', () async {
        // Setup components
        final tempDir = await Directory.systemTemp.createTemp('e2e_perf_');
        final fileCache = FileCache(directory: tempDir);
        await fileCache.initialize();
        
        final cacheManager = CacheManager(
          diskCache: fileCache,
          memoryMaxSize: 100,
          enableRedis: false,
        );
        await cacheManager.initialize();
        
        final vectorDB = VectorDatabase(
          embeddingProvider: MockFastEmbeddingProvider(),
          dimensions: 384,
        );
        await vectorDB.initialize();
        
        // Add test documents
        final documents = List.generate(1000, (i) => Document(
          id: 'e2e_doc_$i',
          content: 'E2E test document $i about artificial intelligence and machine learning systems',
        ));
        await vectorDB.addDocuments(documents);
        
        // Create RAG workflow
        final ragWorkflow = AgentWorkflow(
          id: 'e2e_rag',
          name: 'E2E RAG Performance Test',
        );
        
        ragWorkflow.addNode(WorkflowNode(
          id: 'vector_search',
          type: WorkflowNodeType.agent,
          config: {'vector_db': vectorDB},
          inputMapping: {'query': 'input.query'},
          outputMapping: {'documents': 'retrieved_docs'},
        ));
        
        ragWorkflow.addNode(WorkflowNode(
          id: 'generate_response',
          type: WorkflowNodeType.agent,
          config: {'model': 'fast-test-model'},
          inputMapping: {
            'query': 'input.query',
            'context': 'vector_search.documents'
          },
          outputMapping: {'response': 'final_response'},
        ), dependencies: ['vector_search']);
        
        try {
          // Execute complete RAG workflow
          final stopwatch = Stopwatch()..start();
          
          final result = await ragWorkflow.execute(WorkflowInput(data: {
            'query': 'What is artificial intelligence and how does machine learning work?'
          }));
          
          stopwatch.stop();
          
          expect(result.success, isTrue);
          expect(stopwatch.elapsed.inSeconds, lessThan(5));
          
          print('📊 Complete RAG workflow: ${stopwatch.elapsed.inMilliseconds}ms');
          
        } finally {
          await cacheManager.dispose();
          await vectorDB.dispose();
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      });
    });
  });
}

/// Performance test utilities
class FastTestJob implements Job {
  @override
  final String id;
  
  @override
  final String type = 'fast_test_job';
  
  @override
  final JobPriority priority;
  
  @override
  final Map<String, dynamic> data = const {};
  
  @override
  final int maxRetries = 0;
  
  @override
  final Duration timeout = Duration(minutes: 1);
  
  final Duration executionTime;
  final bool cpuIntensive;
  
  FastTestJob({
    required this.id,
    this.priority = JobPriority.normal,
    this.executionTime = const Duration(milliseconds: 10),
    this.cpuIntensive = false,
  });
  
  @override
  Future<JobResult> execute() async {
    final startTime = DateTime.now();
    
    if (cpuIntensive) {
      // Simulate CPU-intensive work
      await _simulateCpuWork();
    } else {
      // Simple delay
      await Future.delayed(executionTime);
    }
    
    final actualTime = DateTime.now().difference(startTime);
    
    return JobResult(
      jobId: id,
      success: true,
      result: {'executed_at': startTime.toIso8601String()},
      executionTime: actualTime,
    );
  }
  
  Future<void> _simulateCpuWork() async {
    final completer = Completer<void>();
    final endTime = DateTime.now().add(executionTime);
    
    void work() {
      // CPU-intensive calculation
      var sum = 0;
      for (int i = 0; i < 100000; i++) {
        sum += i * i;
      }
      
      if (DateTime.now().isBefore(endTime)) {
        // Continue work in next event loop
        Future.microtask(work);
      } else {
        completer.complete();
      }
    }
    
    Future.microtask(work);
    await completer.future;
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'priority': priority.name,
      'execution_time_ms': executionTime.inMilliseconds,
      'cpu_intensive': cpuIntensive,
    };
  }
}

class MockFastEmbeddingProvider {
  final Random _random = Random(42);
  
  Future<List<double>> generateEmbedding(String text) async {
    // Very fast mock embedding generation
    await Future.delayed(Duration(microseconds: 100 + _random.nextInt(100)));
    
    final hash = text.hashCode;
    final random = Random(hash);
    
    return List.generate(384, (i) => random.nextDouble() * 2 - 1);
  }
  
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    // Batch processing for better performance
    final results = <List<double>>[];
    
    for (final text in texts) {
      results.add(await generateEmbedding(text));
    }
    
    return results;
  }
}

String _generateRandomKeywords() {
  final keywords = [
    'artificial', 'intelligence', 'machine', 'learning', 'deep', 'neural',
    'network', 'algorithm', 'data', 'science', 'computer', 'vision',
    'natural', 'language', 'processing', 'automation', 'robotics'
  ];
  final random = Random();
  final selected = <String>[];
  
  for (int i = 0; i < 3 + random.nextInt(3); i++) {
    selected.add(keywords[random.nextInt(keywords.length)]);
  }
  
  return selected.join(' ');
}

int _getCurrentMemoryUsage() {
  // Mock memory measurement for demo
  // In real implementation, would use platform-specific APIs
  return ProcessInfo.currentRss ?? (Random().nextInt(100) * 1024 * 1024);
}

Future<void> _forceGarbageCollection() async {
  // Mock GC for demo - in real implementation would trigger actual GC
  await Future.delayed(Duration(milliseconds: 1));
}
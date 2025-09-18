import 'dart:async';
import 'dart:collection';
import '../models/agent_terminal.dart';
import 'production_logger.dart';

/// Service for managing terminal output streaming and buffering
class TerminalOutputService {
  final Map<String, StreamController<TerminalOutput>> _outputControllers = {};
  final Map<String, Queue<TerminalOutput>> _outputBuffers = {};
  final Map<String, StreamSubscription> _outputSubscriptions = {};
  
  static const int _maxBufferSize = 1000;
  static const Duration _bufferFlushInterval = Duration(milliseconds: 100);

  /// Create output stream for an agent terminal
  StreamController<TerminalOutput> createOutputStream(String agentId) {
    if (_outputControllers.containsKey(agentId)) {
      throw Exception('Output stream already exists for agent $agentId');
    }

    final controller = StreamController<TerminalOutput>.broadcast();
    final buffer = Queue<TerminalOutput>();
    
    _outputControllers[agentId] = controller;
    _outputBuffers[agentId] = buffer;

    // Set up periodic buffer flushing for batched output
    _setupBufferFlushing(agentId);

    ProductionLogger.instance.info(
      'Terminal output stream created',
      data: {'agent_id': agentId},
      category: 'terminal_output',
    );

    return controller;
  }

  /// Get output stream for an agent
  Stream<TerminalOutput>? getOutputStream(String agentId) {
    return _outputControllers[agentId]?.stream;
  }

  /// Add output to stream with buffering
  void addOutput(String agentId, TerminalOutput output) {
    final controller = _outputControllers[agentId];
    final buffer = _outputBuffers[agentId];
    
    if (controller == null || buffer == null) {
      ProductionLogger.instance.warning(
        'No output stream found for agent',
        data: {'agent_id': agentId},
        category: 'terminal_output',
      );
      return;
    }

    // Add to buffer
    buffer.add(output);
    
    // Maintain buffer size limit
    while (buffer.length > _maxBufferSize) {
      buffer.removeFirst();
    }

    // Immediately send to stream for real-time display
    if (!controller.isClosed) {
      controller.add(output);
    }
  }

  /// Add multiple outputs in batch
  void addOutputBatch(String agentId, List<TerminalOutput> outputs) {
    final controller = _outputControllers[agentId];
    final buffer = _outputBuffers[agentId];
    
    if (controller == null || buffer == null) {
      return;
    }

    for (final output in outputs) {
      buffer.add(output);
      
      // Maintain buffer size limit
      while (buffer.length > _maxBufferSize) {
        buffer.removeFirst();
      }

      if (!controller.isClosed) {
        controller.add(output);
      }
    }
  }

  /// Get buffered output history
  List<TerminalOutput> getOutputHistory(String agentId, {int? limit}) {
    final buffer = _outputBuffers[agentId];
    if (buffer == null) {
      return [];
    }

    final history = buffer.toList();
    
    if (limit != null && limit > 0) {
      return history.length > limit 
          ? history.sublist(history.length - limit)
          : history;
    }
    
    return history;
  }

  /// Get filtered output history
  List<TerminalOutput> getFilteredOutput(
    String agentId, {
    List<TerminalOutputType>? types,
    DateTime? since,
    String? searchTerm,
    int? limit,
  }) {
    final buffer = _outputBuffers[agentId];
    if (buffer == null) {
      return [];
    }

    var outputs = buffer.toList();

    // Filter by types
    if (types != null && types.isNotEmpty) {
      outputs = outputs.where((output) => types.contains(output.type)).toList();
    }

    // Filter by timestamp
    if (since != null) {
      outputs = outputs.where((output) => output.timestamp.isAfter(since)).toList();
    }

    // Filter by search term
    if (searchTerm != null && searchTerm.isNotEmpty) {
      outputs = outputs.where((output) => 
          output.content.toLowerCase().contains(searchTerm.toLowerCase())).toList();
    }

    // Apply limit
    if (limit != null && limit > 0) {
      outputs = outputs.length > limit 
          ? outputs.sublist(outputs.length - limit)
          : outputs;
    }

    return outputs;
  }

  /// Clear output buffer for an agent
  void clearOutput(String agentId) {
    final buffer = _outputBuffers[agentId];
    if (buffer != null) {
      buffer.clear();
      ProductionLogger.instance.info(
        'Terminal output buffer cleared',
        data: {'agent_id': agentId},
        category: 'terminal_output',
      );
    }
  }

  /// Get output statistics
  Map<String, dynamic> getOutputStats(String agentId) {
    final buffer = _outputBuffers[agentId];
    if (buffer == null) {
      return {};
    }

    final outputs = buffer.toList();
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentOutputs = outputs.where((o) => o.timestamp.isAfter(last24Hours)).toList();
    
    final typeStats = <String, int>{};
    for (final output in recentOutputs) {
      typeStats[output.type.name] = (typeStats[output.type.name] ?? 0) + 1;
    }

    return {
      'agentId': agentId,
      'totalOutputs': outputs.length,
      'recentOutputs24h': recentOutputs.length,
      'bufferSize': buffer.length,
      'maxBufferSize': _maxBufferSize,
      'typeBreakdown': typeStats,
      'oldestOutput': outputs.isNotEmpty ? outputs.first.timestamp.toIso8601String() : null,
      'newestOutput': outputs.isNotEmpty ? outputs.last.timestamp.toIso8601String() : null,
    };
  }

  /// Set up periodic buffer flushing for performance
  void _setupBufferFlushing(String agentId) {
    final subscription = Stream.periodic(_bufferFlushInterval).listen((_) {
      _flushBuffer(agentId);
    });
    
    _outputSubscriptions[agentId] = subscription;
  }

  /// Flush buffer to optimize memory usage
  void _flushBuffer(String agentId) {
    final buffer = _outputBuffers[agentId];
    if (buffer == null) return;

    // Keep only recent outputs in memory for performance
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));
    
    while (buffer.isNotEmpty && buffer.first.timestamp.isBefore(cutoffTime)) {
      if (buffer.length <= _maxBufferSize ~/ 2) {
        break; // Keep minimum buffer size
      }
      buffer.removeFirst();
    }
  }

  /// Create output with automatic formatting
  TerminalOutput createOutput(
    String agentId,
    String content,
    TerminalOutputType type, {
    Map<String, dynamic>? metadata,
  }) {
    return TerminalOutput(
      agentId: agentId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
    );
  }

  /// Create formatted command output
  TerminalOutput createCommandOutput(String agentId, String command) {
    return createOutput(
      agentId,
      '> $command',
      TerminalOutputType.command,
    );
  }

  /// Create formatted system message
  TerminalOutput createSystemOutput(String agentId, String message) {
    return createOutput(
      agentId,
      '[SYSTEM] $message',
      TerminalOutputType.system,
    );
  }

  /// Create formatted error message
  TerminalOutput createErrorOutput(String agentId, String error) {
    return createOutput(
      agentId,
      '[ERROR] $error',
      TerminalOutputType.error,
    );
  }

  /// Close output stream for an agent
  Future<void> closeOutputStream(String agentId) async {
    final controller = _outputControllers.remove(agentId);
    final subscription = _outputSubscriptions.remove(agentId);
    
    _outputBuffers.remove(agentId);
    
    await subscription?.cancel();
    await controller?.close();

    ProductionLogger.instance.info(
      'Terminal output stream closed',
      data: {'agent_id': agentId},
      category: 'terminal_output',
    );
  }

  /// Close all output streams
  Future<void> closeAllStreams() async {
    final futures = <Future>[];
    
    for (final agentId in _outputControllers.keys.toList()) {
      futures.add(closeOutputStream(agentId));
    }
    
    await Future.wait(futures);
    
    ProductionLogger.instance.info(
      'All terminal output streams closed',
      category: 'terminal_output',
    );
  }

  /// Get active stream count
  int get activeStreamCount => _outputControllers.length;

  /// Check if stream exists for agent
  bool hasOutputStream(String agentId) {
    return _outputControllers.containsKey(agentId);
  }

  /// Stream filtered output in real-time
  Stream<TerminalOutput> streamFilteredOutput(
    String agentId, {
    List<TerminalOutputType>? types,
    String? searchTerm,
  }) async* {
    final stream = getOutputStream(agentId);
    if (stream == null) {
      throw Exception('No output stream found for agent $agentId');
    }

    await for (final output in stream) {
      // Apply type filter
      if (types != null && types.isNotEmpty && !types.contains(output.type)) {
        continue;
      }

      // Apply search filter
      if (searchTerm != null && searchTerm.isNotEmpty) {
        if (!output.content.toLowerCase().contains(searchTerm.toLowerCase())) {
          continue;
        }
      }

      yield output;
    }
  }

  /// Stream output with rate limiting for performance
  Stream<List<TerminalOutput>> streamBatchedOutput(
    String agentId, {
    Duration batchInterval = const Duration(milliseconds: 100),
    int maxBatchSize = 50,
  }) {
    final stream = getOutputStream(agentId);
    if (stream == null) {
      throw Exception('No output stream found for agent $agentId');
    }

    late StreamController<List<TerminalOutput>> controller;
    final batch = <TerminalOutput>[];
    Timer? batchTimer;
    StreamSubscription? subscription;

    controller = StreamController<List<TerminalOutput>>(
      onListen: () {
        subscription = stream.listen(
          (output) {
            batch.add(output);

            // Cancel existing timer
            batchTimer?.cancel();

            // Emit immediately if batch is full
            if (batch.length >= maxBatchSize) {
              controller.add(List.from(batch));
              batch.clear();
            } else {
              // Set timer to emit batch after interval
              batchTimer = Timer(batchInterval, () {
                if (batch.isNotEmpty) {
                  controller.add(List.from(batch));
                  batch.clear();
                }
              });
            }
          },
          onDone: () {
            // Emit any remaining items
            if (batch.isNotEmpty) {
              controller.add(batch);
            }
            batchTimer?.cancel();
            controller.close();
          },
          onError: (error, stackTrace) {
            batchTimer?.cancel();
            controller.addError(error, stackTrace);
          },
        );
      },
      onCancel: () {
        batchTimer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  /// Get live output statistics
  Stream<Map<String, dynamic>> streamOutputStatistics(
    String agentId, {
    Duration updateInterval = const Duration(seconds: 5),
  }) async* {
    while (hasOutputStream(agentId)) {
      yield getOutputStats(agentId);
      await Future.delayed(updateInterval);
    }
  }

  /// Stream output with highlighting for specific patterns
  Stream<TerminalOutput> streamHighlightedOutput(
    String agentId, {
    List<String> highlightPatterns = const [],
  }) async* {
    final stream = getOutputStream(agentId);
    if (stream == null) {
      throw Exception('No output stream found for agent $agentId');
    }

    await for (final output in stream) {
      var content = output.content;
      var isHighlighted = false;

      // Check for highlight patterns
      for (final pattern in highlightPatterns) {
        if (content.toLowerCase().contains(pattern.toLowerCase())) {
          isHighlighted = true;
          break;
        }
      }

      // Create highlighted output if needed
      if (isHighlighted) {
        yield TerminalOutput(
          agentId: output.agentId,
          content: '🔍 ${output.content}', // Add highlight indicator
          type: output.type,
          timestamp: output.timestamp,
        );
      } else {
        yield output;
      }
    }
  }
}
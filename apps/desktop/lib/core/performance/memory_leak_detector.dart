import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/desktop/desktop_storage_service.dart';

enum MemoryLeakSeverity {
  low,
  medium,
  high,
  critical,
}

class MemoryLeakReport {
  final String id;
  final DateTime timestamp;
  final String objectType;
  final int instanceCount;
  final int expectedCount;
  final MemoryLeakSeverity severity;
  final Map<String, dynamic> metadata;
  final String? stackTrace;
  
  MemoryLeakReport({
    required this.id,
    required this.timestamp,
    required this.objectType,
    required this.instanceCount,
    required this.expectedCount,
    required this.severity,
    this.metadata = const {},
    this.stackTrace,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'objectType': objectType,
      'instanceCount': instanceCount,
      'expectedCount': expectedCount,
      'severity': severity.name,
      'metadata': metadata,
      'stackTrace': stackTrace,
    };
  }
  
  factory MemoryLeakReport.fromJson(Map<String, dynamic> json) {
    return MemoryLeakReport(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      objectType: json['objectType'],
      instanceCount: json['instanceCount'],
      expectedCount: json['expectedCount'],
      severity: MemoryLeakSeverity.values.firstWhere((s) => s.name == json['severity']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      stackTrace: json['stackTrace'],
    );
  }
  
  @override
  String toString() {
    return 'Memory Leak [${severity.name.toUpperCase()}] - $objectType: '
           '$instanceCount instances (expected: $expectedCount)';
  }
}

class MemoryUsageSnapshot {
  final DateTime timestamp;
  final int totalMemoryMB;
  final int usedMemoryMB;
  final int freeMemoryMB;
  final Map<String, int> objectCounts;
  final int activeStreamSubscriptions;
  final int activeTimers;
  final int activeFutures;
  
  MemoryUsageSnapshot({
    required this.timestamp,
    required this.totalMemoryMB,
    required this.usedMemoryMB,
    required this.freeMemoryMB,
    required this.objectCounts,
    required this.activeStreamSubscriptions,
    required this.activeTimers,
    required this.activeFutures,
  });
  
  double get memoryUsagePercentage => (usedMemoryMB / totalMemoryMB) * 100;
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'totalMemoryMB': totalMemoryMB,
      'usedMemoryMB': usedMemoryMB,
      'freeMemoryMB': freeMemoryMB,
      'objectCounts': objectCounts,
      'activeStreamSubscriptions': activeStreamSubscriptions,
      'activeTimers': activeTimers,
      'activeFutures': activeFutures,
      'memoryUsagePercentage': memoryUsagePercentage,
    };
  }
}

class ResourceTracker {
  static final Map<String, int> _objectCounts = <String, int>{};
  static final Map<String, List<WeakReference>> _objectReferences = <String, List<WeakReference>>{};
  static final Set<StreamSubscription> _activeSubscriptions = <StreamSubscription>{};
  static final Set<Timer> _activeTimers = <Timer>{};
  static final Set<Future> _activeFutures = <Future>{};
  
  static void trackObject(String type, Object object) {
    _objectCounts[type] = (_objectCounts[type] ?? 0) + 1;
    
    final references = _objectReferences.putIfAbsent(type, () => <WeakReference>[]);
    references.add(WeakReference(object));
    
    // Clean up dead references periodically
    if (references.length % 100 == 0) {
      references.removeWhere((ref) => ref.target == null);
    }
  }
  
  static void untrackObject(String type) {
    final currentCount = _objectCounts[type] ?? 0;
    if (currentCount > 0) {
      _objectCounts[type] = currentCount - 1;
    }
  }
  
  static void trackSubscription(StreamSubscription subscription) {
    _activeSubscriptions.add(subscription);
  }
  
  static void untrackSubscription(StreamSubscription subscription) {
    _activeSubscriptions.remove(subscription);
  }
  
  static void trackTimer(Timer timer) {
    _activeTimers.add(timer);
  }
  
  static void untrackTimer(Timer timer) {
    _activeTimers.remove(timer);
  }
  
  static void trackFuture(Future future) {
    _activeFutures.add(future);
    
    // Remove from tracking when completed
    future.whenComplete(() {
      _activeFutures.remove(future);
    });
  }
  
  static Map<String, int> getObjectCounts() {
    // Clean up dead references before reporting
    _objectReferences.forEach((type, references) {
      references.removeWhere((ref) => ref.target == null);
      _objectCounts[type] = references.length;
    });
    
    return Map<String, int>.from(_objectCounts);
  }
  
  static int get activeSubscriptionCount => _activeSubscriptions.length;
  static int get activeTimerCount => _activeTimers.length;
  static int get activeFutureCount => _activeFutures.length;
  
  static void cleanup() {
    // Force cleanup of dead references
    _objectReferences.forEach((type, references) {
      references.removeWhere((ref) => ref.target == null);
      _objectCounts[type] = references.length;
    });
    
    // Remove completed timers
    _activeTimers.removeWhere((timer) => !timer.isActive);
  }
}

class MemoryLeakDetector extends StateNotifier<List<MemoryLeakReport>> {
  static const Duration _checkInterval = Duration(minutes: 5);
  static const int _maxReportsStored = 100;
  
  final DesktopStorageService _storage;
  final Queue<MemoryUsageSnapshot> _memoryHistory = Queue<MemoryUsageSnapshot>();
  
  Timer? _detectionTimer;
  Timer? _cleanupTimer;
  Map<String, int> _baselineCounts = <String, int>{};
  bool _isInitialized = false;
  
  MemoryLeakDetector(this._storage) : super([]) {
    _initialize();
  }
  
  void _initialize() {
    if (_isInitialized) return;
    
    // Wait for app to stabilize before starting detection
    Timer(const Duration(seconds: 30), () {
      _establishBaseline();
      _startDetection();
      _startPeriodicCleanup();
      _isInitialized = true;
    });
  }
  
  void _establishBaseline() {
    // Take initial snapshot of object counts as baseline
    _baselineCounts = ResourceTracker.getObjectCounts();
    
    if (kDebugMode) {
      print('🔍 Memory leak detection baseline established:');
      _baselineCounts.forEach((type, count) {
        print('  $type: $count instances');
      });
    }
  }
  
  void _startDetection() {
    _detectionTimer = Timer.periodic(_checkInterval, (_) {
      _performLeakDetection();
    });
  }
  
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ResourceTracker.cleanup();
      _cleanupOldSnapshots();
    });
  }
  
  Future<void> _performLeakDetection() async {
    try {
      // Take memory snapshot
      final snapshot = await _takeMemorySnapshot();
      _memoryHistory.add(snapshot);
      
      // Check for memory leaks
      final leaks = _detectLeaks(snapshot);
      
      // Report any leaks found
      for (final leak in leaks) {
        await _reportLeak(leak);
      }
      
      // Store snapshot for analysis
      await _storeSnapshot(snapshot);
      
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Memory leak detection failed: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }
  
  Future<MemoryUsageSnapshot> _takeMemorySnapshot() async {
    final objectCounts = ResourceTracker.getObjectCounts();
    
    // Get memory information (platform-specific)
    int totalMemoryMB = 0;
    int usedMemoryMB = 0;
    
    try {
      final currentPid = pid;
      if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('ps', ['-o', 'rss,vsz', '-p', currentPid.toString()]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final parts = lines[1].trim().split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              usedMemoryMB = (int.tryParse(parts[0]) ?? 0) ~/ 1024; // RSS in MB
              totalMemoryMB = (int.tryParse(parts[1]) ?? 0) ~/ 1024; // VSZ in MB
            }
          }
        }
      } else if (Platform.isWindows) {
        // Use tasklist on Windows
        final result = await Process.run('tasklist', ['/FI', 'PID eq $currentPid', '/FO', 'CSV']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final csvLine = lines[1];
            final memMatch = RegExp(r'"([0-9,]+) K"').firstMatch(csvLine);
            if (memMatch != null) {
              final memStr = memMatch.group(1)?.replaceAll(',', '') ?? '0';
              usedMemoryMB = (int.tryParse(memStr) ?? 0) ~/ 1024;
              totalMemoryMB = usedMemoryMB * 2; // Rough estimate
            }
          }
        }
      }
    } catch (e) {
      // Fallback to rough estimates
      usedMemoryMB = 100; // Default estimate
      totalMemoryMB = 500; // Default estimate
    }
    
    return MemoryUsageSnapshot(
      timestamp: DateTime.now(),
      totalMemoryMB: totalMemoryMB,
      usedMemoryMB: usedMemoryMB,
      freeMemoryMB: totalMemoryMB - usedMemoryMB,
      objectCounts: objectCounts,
      activeStreamSubscriptions: ResourceTracker.activeSubscriptionCount,
      activeTimers: ResourceTracker.activeTimerCount,
      activeFutures: ResourceTracker.activeFutureCount,
    );
  }
  
  List<MemoryLeakReport> _detectLeaks(MemoryUsageSnapshot snapshot) {
    final leaks = <MemoryLeakReport>[];
    
    // Check for object count increases beyond reasonable thresholds
    snapshot.objectCounts.forEach((type, currentCount) {
      final baselineCount = _baselineCounts[type] ?? 0;
      final increase = currentCount - baselineCount;
      
      // Define thresholds based on object type
      final threshold = _getThreshold(type, baselineCount);
      
      if (increase > threshold) {
        final severity = _calculateSeverity(type, increase, threshold);
        
        final leak = MemoryLeakReport(
          id: 'leak_${DateTime.now().millisecondsSinceEpoch}_${type.hashCode}',
          timestamp: DateTime.now(),
          objectType: type,
          instanceCount: currentCount,
          expectedCount: baselineCount + threshold,
          severity: severity,
          metadata: {
            'increase': increase,
            'threshold': threshold,
            'baselineCount': baselineCount,
            'memoryUsagePercentage': snapshot.memoryUsagePercentage,
          },
        );
        
        leaks.add(leak);
      }
    });
    
    // Check for excessive resource usage
    final resourceLeaks = _detectResourceLeaks(snapshot);
    leaks.addAll(resourceLeaks);
    
    return leaks;
  }
  
  List<MemoryLeakReport> _detectResourceLeaks(MemoryUsageSnapshot snapshot) {
    final leaks = <MemoryLeakReport>[];
    
    // Check for too many active subscriptions
    if (snapshot.activeStreamSubscriptions > 50) {
      leaks.add(MemoryLeakReport(
        id: 'sub_leak_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        objectType: 'StreamSubscription',
        instanceCount: snapshot.activeStreamSubscriptions,
        expectedCount: 20,
        severity: snapshot.activeStreamSubscriptions > 100 
          ? MemoryLeakSeverity.high 
          : MemoryLeakSeverity.medium,
        metadata: {'type': 'stream_subscriptions'},
      ));
    }
    
    // Check for too many active timers
    if (snapshot.activeTimers > 20) {
      leaks.add(MemoryLeakReport(
        id: 'timer_leak_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        objectType: 'Timer',
        instanceCount: snapshot.activeTimers,
        expectedCount: 10,
        severity: snapshot.activeTimers > 50 
          ? MemoryLeakSeverity.high 
          : MemoryLeakSeverity.medium,
        metadata: {'type': 'timers'},
      ));
    }
    
    // Check for excessive memory usage
    if (snapshot.memoryUsagePercentage > 85) {
      leaks.add(MemoryLeakReport(
        id: 'mem_leak_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        objectType: 'Memory',
        instanceCount: snapshot.usedMemoryMB,
        expectedCount: (snapshot.totalMemoryMB * 0.7).round(),
        severity: snapshot.memoryUsagePercentage > 95 
          ? MemoryLeakSeverity.critical 
          : MemoryLeakSeverity.high,
        metadata: {
          'type': 'memory_usage',
          'percentage': snapshot.memoryUsagePercentage,
          'totalMB': snapshot.totalMemoryMB,
        },
      ));
    }
    
    return leaks;
  }
  
  int _getThreshold(String objectType, int baselineCount) {
    // Define thresholds based on object type
    switch (objectType.toLowerCase()) {
      case 'widget':
      case 'state':
        return (baselineCount * 0.5).round() + 10; // Allow 50% increase + 10
      case 'provider':
      case 'notifier':
        return (baselineCount * 0.3).round() + 5; // Allow 30% increase + 5
      case 'stream':
      case 'subscription':
        return (baselineCount * 0.2).round() + 3; // Allow 20% increase + 3
      case 'timer':
      case 'future':
        return (baselineCount * 0.4).round() + 5; // Allow 40% increase + 5
      default:
        return (baselineCount * 1.0).round() + 20; // Allow 100% increase + 20 for unknown types
    }
  }
  
  MemoryLeakSeverity _calculateSeverity(String objectType, int increase, int threshold) {
    final ratio = increase / threshold;
    
    if (ratio >= 5) return MemoryLeakSeverity.critical;
    if (ratio >= 3) return MemoryLeakSeverity.high;
    if (ratio >= 2) return MemoryLeakSeverity.medium;
    return MemoryLeakSeverity.low;
  }
  
  Future<void> _reportLeak(MemoryLeakReport leak) async {
    // Add to state
    final updatedLeaks = [...state, leak];
    if (updatedLeaks.length > _maxReportsStored) {
      updatedLeaks.removeRange(0, updatedLeaks.length - _maxReportsStored);
    }
    state = updatedLeaks;
    
    // Store persistently
    await _storage.setHiveData('memory_leaks', leak.id, leak.toJson());
    
    // Log to console in debug mode
    if (kDebugMode) {
      print('🔍 Memory leak detected: ${leak.toString()}');
      if (leak.severity == MemoryLeakSeverity.critical) {
        print('⚠️ CRITICAL MEMORY LEAK - Immediate attention required!');
      }
    }
  }
  
  Future<void> _storeSnapshot(MemoryUsageSnapshot snapshot) async {
    try {
      final snapshotId = 'snapshot_${snapshot.timestamp.millisecondsSinceEpoch}';
      await _storage.setHiveData('memory_snapshots', snapshotId, snapshot.toJson());
    } catch (e) {
      // Ignore storage failures
    }
  }
  
  void _cleanupOldSnapshots() {
    // Keep only last 100 snapshots in memory
    while (_memoryHistory.length > 100) {
      _memoryHistory.removeFirst();
    }
  }
  
  // Public API methods
  MemoryUsageSnapshot? get latestSnapshot => 
    _memoryHistory.isNotEmpty ? _memoryHistory.last : null;
  
  List<MemoryUsageSnapshot> get memoryHistory => _memoryHistory.toList();
  
  List<MemoryLeakReport> getLeaksByType(String objectType) {
    return state.where((leak) => leak.objectType == objectType).toList();
  }
  
  List<MemoryLeakReport> getLeaksBySeverity(MemoryLeakSeverity severity) {
    return state.where((leak) => leak.severity == severity).toList();
  }
  
  Map<String, int> getLeakSummary() {
    final summary = <String, int>{};
    for (final leak in state) {
      final key = '${leak.objectType}_${leak.severity.name}';
      summary[key] = (summary[key] ?? 0) + 1;
    }
    return summary;
  }
  
  bool get hasActiveLeaks => state.any((leak) => 
    leak.severity == MemoryLeakSeverity.high || 
    leak.severity == MemoryLeakSeverity.critical);
  
  Future<void> forceMemoryCleanup() async {
    // Force garbage collection if possible
    ResourceTracker.cleanup();
    
    if (kDebugMode) {
      print('🧹 Forced memory cleanup completed');
    }
  }
  
  Future<Map<String, dynamic>> exportMemoryReport() async {
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'total_leaks': state.length,
      'active_leaks': hasActiveLeaks,
      'leak_summary': getLeakSummary(),
      'latest_snapshot': latestSnapshot?.toJson(),
      'leaks': state.map((leak) => leak.toJson()).toList(),
      'baseline_counts': _baselineCounts,
    };
  }
  
  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }
}

// Provider for memory leak detector
final memoryLeakDetectorProvider = StateNotifierProvider<MemoryLeakDetector, List<MemoryLeakReport>>((ref) {
  final storage = DesktopStorageService.instance;
  return MemoryLeakDetector(storage);
});

// Helper class for resource tracking in ConsumerWidgets
class ResourceTrackingHelper {
  final String _widgetType;
  final Object _widgetInstance;
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  
  ResourceTrackingHelper(this._widgetType, this._widgetInstance) {
    ResourceTracker.trackObject(_widgetType, _widgetInstance);
  }
  
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
    ResourceTracker.trackSubscription(subscription);
  }
  
  void addTimer(Timer timer) {
    _timers.add(timer);
    ResourceTracker.trackTimer(timer);
  }
  
  void trackFuture(Future future) {
    ResourceTracker.trackFuture(future);
  }
  
  void dispose() {
    // Cancel all tracked subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
      ResourceTracker.untrackSubscription(subscription);
    }
    _subscriptions.clear();
    
    // Cancel all tracked timers
    for (final timer in _timers) {
      timer.cancel();
      ResourceTracker.untrackTimer(timer);
    }
    _timers.clear();
    
    ResourceTracker.untrackObject(_widgetType);
  }
}
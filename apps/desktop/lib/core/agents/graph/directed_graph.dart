import 'dart:collection';

/// A directed graph implementation for workflow DAG representation
class DirectedGraph<T> {
  final Map<String, T> _nodes = {};
  final Map<String, Set<String>> _edges = {};
  final Map<String, Set<String>> _incomingEdges = {};

  /// Add a node to the graph
  void addNode(String id, T node) {
    _nodes[id] = node;
    _edges.putIfAbsent(id, () => <String>{});
    _incomingEdges.putIfAbsent(id, () => <String>{});
  }

  /// Add an edge from source to target node
  void addEdge(String from, String to) {
    if (!_nodes.containsKey(from) || !_nodes.containsKey(to)) {
      throw ArgumentError('Both nodes must exist before adding an edge');
    }

    _edges[from]!.add(to);
    _incomingEdges[to]!.add(from);
  }

  /// Remove a node and all its connections
  void removeNode(String id) {
    if (!_nodes.containsKey(id)) return;

    // Remove all outgoing edges
    final outgoing = Set<String>.from(_edges[id]!);
    for (final target in outgoing) {
      removeEdge(id, target);
    }

    // Remove all incoming edges
    final incoming = Set<String>.from(_incomingEdges[id]!);
    for (final source in incoming) {
      removeEdge(source, id);
    }

    // Remove the node itself
    _nodes.remove(id);
    _edges.remove(id);
    _incomingEdges.remove(id);
  }

  /// Remove an edge between two nodes
  void removeEdge(String from, String to) {
    _edges[from]?.remove(to);
    _incomingEdges[to]?.remove(from);
  }

  /// Get a node by ID
  T? getNode(String id) => _nodes[id];

  /// Get all node IDs
  Set<String> get nodeIds => _nodes.keys.toSet();

  /// Get all nodes
  Map<String, T> get nodes => Map.unmodifiable(_nodes);

  /// Get children (outgoing edges) of a node
  Set<String> getChildren(String nodeId) {
    return Set.from(_edges[nodeId] ?? <String>{});
  }

  /// Get parents (incoming edges) of a node
  Set<String> getParents(String nodeId) {
    return Set.from(_incomingEdges[nodeId] ?? <String>{});
  }

  /// Check if there's a direct edge between two nodes
  bool hasEdge(String from, String to) {
    return _edges[from]?.contains(to) ?? false;
  }

  /// Check if the graph has any cycles using DFS
  bool hasCycles() {
    final visited = <String>{};
    final recursionStack = <String>{};

    bool dfsHasCycle(String nodeId) {
      visited.add(nodeId);
      recursionStack.add(nodeId);

      for (final child in getChildren(nodeId)) {
        if (!visited.contains(child)) {
          if (dfsHasCycle(child)) {
            return true;
          }
        } else if (recursionStack.contains(child)) {
          return true; // Back edge found, cycle detected
        }
      }

      recursionStack.remove(nodeId);
      return false;
    }

    for (final nodeId in nodeIds) {
      if (!visited.contains(nodeId)) {
        if (dfsHasCycle(nodeId)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get topological ordering of nodes (for DAG execution order)
  List<String> getTopologicalOrder() {
    if (hasCycles()) {
      throw StateError('Cannot get topological order: graph contains cycles');
    }

    final visited = <String>{};
    final stack = <String>[];

    void dfs(String nodeId) {
      visited.add(nodeId);

      for (final child in getChildren(nodeId)) {
        if (!visited.contains(child)) {
          dfs(child);
        }
      }

      stack.add(nodeId);
    }

    for (final nodeId in nodeIds) {
      if (!visited.contains(nodeId)) {
        dfs(nodeId);
      }
    }

    return stack.reversed.toList();
  }

  /// Get nodes that can be executed in parallel at each level
  List<List<String>> getParallelExecutionLevels() {
    if (hasCycles()) {
      throw StateError('Cannot determine execution levels: graph contains cycles');
    }

    final levels = <List<String>>[];
    final processed = <String>{};
    final inDegree = <String, int>{};

    // Initialize in-degree for all nodes
    for (final nodeId in nodeIds) {
      inDegree[nodeId] = getParents(nodeId).length;
    }

    // Process nodes level by level
    while (processed.length < nodeIds.length) {
      final currentLevel = <String>[];

      // Find all nodes with no remaining dependencies
      for (final nodeId in nodeIds) {
        if (!processed.contains(nodeId) && inDegree[nodeId] == 0) {
          currentLevel.add(nodeId);
        }
      }

      if (currentLevel.isEmpty) {
        throw StateError('Unable to find nodes for next execution level');
      }

      levels.add(currentLevel);
      processed.addAll(currentLevel);

      // Update in-degree for remaining nodes
      for (final nodeId in currentLevel) {
        for (final child in getChildren(nodeId)) {
          inDegree[child] = (inDegree[child] ?? 0) - 1;
        }
      }
    }

    return levels;
  }

  /// Find the root nodes (nodes with no incoming edges)
  Set<String> getRootNodes() {
    return nodeIds.where((id) => getParents(id).isEmpty).toSet();
  }

  /// Find the leaf nodes (nodes with no outgoing edges)
  Set<String> getLeafNodes() {
    return nodeIds.where((id) => getChildren(id).isEmpty).toSet();
  }

  /// Get all nodes reachable from a given node
  Set<String> getReachableNodes(String startNodeId) {
    if (!_nodes.containsKey(startNodeId)) {
      throw ArgumentError('Start node does not exist: $startNodeId');
    }

    final reachable = <String>{};
    final queue = Queue<String>();
    queue.add(startNodeId);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (reachable.contains(current)) continue;

      reachable.add(current);
      queue.addAll(getChildren(current));
    }

    return reachable;
  }

  /// Find cycles in the graph and return the cycle paths
  List<List<String>> findCycles() {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>{};
    final path = <String>[];

    void dfs(String nodeId) {
      visited.add(nodeId);
      recursionStack.add(nodeId);
      path.add(nodeId);

      for (final child in getChildren(nodeId)) {
        if (!visited.contains(child)) {
          dfs(child);
        } else if (recursionStack.contains(child)) {
          // Found a back edge - extract the cycle
          final cycleStart = path.indexOf(child);
          final cycle = path.sublist(cycleStart)..add(child);
          cycles.add(List.from(cycle));
        }
      }

      recursionStack.remove(nodeId);
      path.removeLast();
    }

    for (final nodeId in nodeIds) {
      if (!visited.contains(nodeId)) {
        dfs(nodeId);
      }
    }

    return cycles;
  }

  /// Get graph statistics
  GraphStats getStats() {
    return GraphStats(
      nodeCount: _nodes.length,
      edgeCount: _edges.values.fold(0, (sum, edges) => sum + edges.length),
      rootNodeCount: getRootNodes().length,
      leafNodeCount: getLeafNodes().length,
      hasCycles: hasCycles(),
      maxDepth: _calculateMaxDepth(),
    );
  }

  /// Calculate the maximum depth of the graph
  int _calculateMaxDepth() {
    if (_nodes.isEmpty) return 0;
    if (hasCycles()) return -1; // Infinite depth due to cycles

    final depths = <String, int>{};

    int calculateDepth(String nodeId) {
      if (depths.containsKey(nodeId)) {
        return depths[nodeId]!;
      }

      final parents = getParents(nodeId);
      if (parents.isEmpty) {
        depths[nodeId] = 0;
        return 0;
      }

      int maxParentDepth = 0;
      for (final parent in parents) {
        maxParentDepth = maxParentDepth > calculateDepth(parent) 
            ? maxParentDepth 
            : calculateDepth(parent);
      }

      depths[nodeId] = maxParentDepth + 1;
      return depths[nodeId]!;
    }

    int maxDepth = 0;
    for (final nodeId in nodeIds) {
      final depth = calculateDepth(nodeId);
      if (depth > maxDepth) maxDepth = depth;
    }

    return maxDepth;
  }

  /// Check if the graph is empty
  bool get isEmpty => _nodes.isEmpty;

  /// Get the number of nodes
  int get nodeCount => _nodes.length;

  /// Clear the entire graph
  void clear() {
    _nodes.clear();
    _edges.clear();
    _incomingEdges.clear();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('DirectedGraph with ${_nodes.length} nodes:');
    
    for (final nodeId in nodeIds) {
      final children = getChildren(nodeId);
      buffer.writeln('  $nodeId -> ${children.isEmpty ? '[]' : children.join(', ')}');
    }
    
    return buffer.toString();
  }
}

/// Statistics about a directed graph
class GraphStats {
  final int nodeCount;
  final int edgeCount;
  final int rootNodeCount;
  final int leafNodeCount;
  final bool hasCycles;
  final int maxDepth;

  const GraphStats({
    required this.nodeCount,
    required this.edgeCount,
    required this.rootNodeCount,
    required this.leafNodeCount,
    required this.hasCycles,
    required this.maxDepth,
  });

  @override
  String toString() {
    return '''GraphStats:
  Nodes: $nodeCount
  Edges: $edgeCount
  Root nodes: $rootNodeCount
  Leaf nodes: $leafNodeCount
  Has cycles: $hasCycles
  Max depth: ${maxDepth == -1 ? 'infinite (cycles)' : maxDepth}''';
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeCount': nodeCount,
      'edgeCount': edgeCount,
      'rootNodeCount': rootNodeCount,
      'leafNodeCount': leafNodeCount,
      'hasCycles': hasCycles,
      'maxDepth': maxDepth,
    };
  }
}
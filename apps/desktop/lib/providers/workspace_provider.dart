import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/workspace.dart';
import '../core/services/git_workspace_service.dart';
import '../core/services/workspace_session_manager.dart';

/// Provider for GitWorkspaceService
final gitWorkspaceServiceProvider = Provider<GitWorkspaceService>((ref) {
  return GitWorkspaceService();
});

/// Provider for WorkspaceSessionManager
final workspaceSessionManagerProvider = Provider<WorkspaceSessionManager>((ref) {
  final gitService = ref.watch(gitWorkspaceServiceProvider);
  final manager = WorkspaceSessionManager(gitService: gitService);

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

/// Provider for initializing workspace manager
final workspaceManagerInitProvider = FutureProvider<void>((ref) async {
  final manager = ref.watch(workspaceSessionManagerProvider);
  await manager.initialize();
});

/// Provider for all workspaces list
final workspacesProvider = StateNotifierProvider<WorkspacesNotifier, AsyncValue<List<WorkspaceConfig>>>((ref) {
  final manager = ref.watch(workspaceSessionManagerProvider);
  return WorkspacesNotifier(manager);
});

/// Provider for recent workspaces
final recentWorkspacesProvider = Provider<List<WorkspaceConfig>>((ref) {
  final workspacesAsync = ref.watch(workspacesProvider);
  return workspacesAsync.maybeWhen(
    data: (workspaces) {
      final sorted = List<WorkspaceConfig>.from(workspaces)
        ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
      return sorted.take(5).toList();
    },
    orElse: () => [],
  );
});

/// Provider for currently selected workspace
final selectedWorkspaceIdProvider = StateProvider<String?>((ref) => null);

/// Provider for selected workspace config
final selectedWorkspaceProvider = Provider<WorkspaceConfig?>((ref) {
  final selectedId = ref.watch(selectedWorkspaceIdProvider);
  if (selectedId == null) return null;

  final workspacesAsync = ref.watch(workspacesProvider);
  return workspacesAsync.maybeWhen(
    data: (workspaces) => workspaces.where((w) => w.id == selectedId).firstOrNull,
    orElse: () => null,
  );
});

/// Provider for workspace snapshots
final workspaceSnapshotsProvider = Provider.family<List<WorkspaceSnapshot>, String>((ref, workspaceId) {
  final manager = ref.watch(workspaceSessionManagerProvider);
  return manager.getSnapshots(workspaceId);
});

/// Provider for workspace file tree
final workspaceFileTreeProvider = FutureProvider.family<FileNode, String>((ref, workspaceId) async {
  final manager = ref.watch(workspaceSessionManagerProvider);
  return manager.getFileTree(workspaceId);
});

/// Provider for workspace git diff
final workspaceDiffProvider = FutureProvider.family<List<FileDiff>, String>((ref, workspaceId) async {
  final gitService = ref.watch(gitWorkspaceServiceProvider);
  final manager = ref.watch(workspaceSessionManagerProvider);
  final workspace = manager.getWorkspace(workspaceId);

  if (workspace == null) return [];

  return gitService.getDiff(workspace.workspacePath);
});

/// Provider for disk usage of a workspace
final workspaceDiskUsageProvider = FutureProvider.family<int, String>((ref, workspaceId) async {
  final manager = ref.watch(workspaceSessionManagerProvider);
  return manager.getWorkspaceDiskUsage(workspaceId);
});

/// Provider for creating a new workspace
final createWorkspaceProvider = Provider<CreateWorkspaceFunction>((ref) {
  final manager = ref.watch(workspaceSessionManagerProvider);
  final notifier = ref.read(workspacesProvider.notifier);

  return ({
    required String repoUrl,
    String? name,
    String? branch,
    ResourceLimits limits = const ResourceLimits(),
  }) async {
    final workspace = await manager.createWorkspace(
      repoUrl: repoUrl,
      name: name,
      branch: branch,
      limits: limits,
    );

    notifier.refresh();
    return workspace;
  };
});

/// Function type for creating workspaces
typedef CreateWorkspaceFunction = Future<WorkspaceConfig> Function({
  required String repoUrl,
  String? name,
  String? branch,
  ResourceLimits limits,
});

/// Notifier for managing workspaces list
class WorkspacesNotifier extends StateNotifier<AsyncValue<List<WorkspaceConfig>>> {
  final WorkspaceSessionManager _manager;
  StreamSubscription<WorkspaceConfig>? _subscription;

  WorkspacesNotifier(this._manager) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _manager.initialize();
      _loadWorkspaces();

      // Listen to workspace state changes
      _subscription = _manager.onStateChange.listen((config) {
        _loadWorkspaces();
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _loadWorkspaces() {
    state = AsyncValue.data(_manager.getAllWorkspaces());
  }

  /// Refresh workspaces list
  void refresh() {
    _loadWorkspaces();
  }

  /// Create a new workspace
  Future<WorkspaceConfig> createWorkspace({
    required String repoUrl,
    String? name,
    String? branch,
    ResourceLimits limits = const ResourceLimits(),
  }) async {
    final workspace = await _manager.createWorkspace(
      repoUrl: repoUrl,
      name: name,
      branch: branch,
      limits: limits,
    );
    _loadWorkspaces();
    return workspace;
  }

  /// Delete a workspace
  Future<void> deleteWorkspace(String id) async {
    await _manager.deleteWorkspace(id);
    _loadWorkspaces();
  }

  /// Reset a workspace to clean state
  Future<void> resetWorkspace(String id) async {
    await _manager.resetWorkspace(id);
    _loadWorkspaces();
  }

  /// Create a snapshot
  Future<WorkspaceSnapshot> createSnapshot(String workspaceId, {
    required String name,
    String? description,
  }) async {
    return _manager.createSnapshot(
      workspaceId,
      name: name,
      description: description,
    );
  }

  /// Restore from snapshot
  Future<void> restoreSnapshot(String workspaceId, String snapshotId) async {
    await _manager.restoreSnapshot(workspaceId, snapshotId);
    _loadWorkspaces();
  }

  /// Delete a snapshot
  Future<void> deleteSnapshot(String workspaceId, String snapshotId) async {
    await _manager.deleteSnapshot(workspaceId, snapshotId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for workspace state stream
final workspaceStateStreamProvider = StreamProvider.family<WorkspaceConfig, String>((ref, workspaceId) {
  final manager = ref.watch(workspaceSessionManagerProvider);

  return manager.onStateChange.where((config) => config.id == workspaceId);
});

/// Provider for open file in workspace
final openWorkspaceFileProvider = StateProvider<OpenFileState?>((ref) => null);

/// State for currently open file
class OpenFileState {
  final String workspaceId;
  final String filePath;
  final String content;
  final bool hasUnsavedChanges;

  const OpenFileState({
    required this.workspaceId,
    required this.filePath,
    required this.content,
    this.hasUnsavedChanges = false,
  });

  OpenFileState copyWith({
    String? workspaceId,
    String? filePath,
    String? content,
    bool? hasUnsavedChanges,
  }) => OpenFileState(
    workspaceId: workspaceId ?? this.workspaceId,
    filePath: filePath ?? this.filePath,
    content: content ?? this.content,
    hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
  );
}

/// Provider for reading file content
final readWorkspaceFileProvider = FutureProvider.family<String, (String, String)>((ref, params) async {
  final (workspaceId, filePath) = params;
  final manager = ref.watch(workspaceSessionManagerProvider);
  return manager.readFile(workspaceId, filePath);
});

/// Provider for workspace terminal output
final workspaceTerminalOutputProvider = StateNotifierProvider.family<TerminalOutputNotifier, List<TerminalLine>, String>(
  (ref, workspaceId) => TerminalOutputNotifier(),
);

/// Notifier for terminal output
class TerminalOutputNotifier extends StateNotifier<List<TerminalLine>> {
  TerminalOutputNotifier() : super([]);

  void addLine(String content, {TerminalLineType type = TerminalLineType.stdout}) {
    state = [...state, TerminalLine(content: content, type: type, timestamp: DateTime.now())];
  }

  void addCommand(String command) {
    addLine('\$ $command', type: TerminalLineType.command);
  }

  void addOutput(String output) {
    for (final line in output.split('\n')) {
      if (line.isNotEmpty) {
        addLine(line, type: TerminalLineType.stdout);
      }
    }
  }

  void addError(String error) {
    for (final line in error.split('\n')) {
      if (line.isNotEmpty) {
        addLine(line, type: TerminalLineType.stderr);
      }
    }
  }

  void clear() {
    state = [];
  }
}

/// Terminal line types
enum TerminalLineType {
  command,
  stdout,
  stderr,
}

/// Terminal line model
class TerminalLine {
  final String content;
  final TerminalLineType type;
  final DateTime timestamp;

  const TerminalLine({
    required this.content,
    required this.type,
    required this.timestamp,
  });
}

/// Provider for running commands in workspace
final runWorkspaceCommandProvider = Provider.family<Future<void> Function(String, List<String>), String>((ref, workspaceId) {
  final manager = ref.watch(workspaceSessionManagerProvider);
  final terminal = ref.read(workspaceTerminalOutputProvider(workspaceId).notifier);

  return (String command, List<String> args) async {
    terminal.addCommand('$command ${args.join(' ')}');

    try {
      final result = await manager.runCommand(workspaceId, command, args);

      if (result.stdout.toString().isNotEmpty) {
        terminal.addOutput(result.stdout.toString());
      }

      if (result.stderr.toString().isNotEmpty) {
        terminal.addError(result.stderr.toString());
      }

      if (result.exitCode != 0) {
        terminal.addError('Process exited with code ${result.exitCode}');
      }
    } catch (e) {
      terminal.addError('Error: $e');
    }
  };
});

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/workspace.dart';
import 'git_workspace_service.dart';

/// Manages isolated workspace sessions for IDE prototyping
///
/// Provides:
/// - Workspace creation and cleanup
/// - Snapshot creation and restoration
/// - Resource monitoring and limits
/// - Session isolation and sandboxing
class WorkspaceSessionManager {
  final GitWorkspaceService _gitService;

  /// Base directory for all workspaces
  late final String _workspacesRoot;

  /// Active workspaces by ID
  final Map<String, WorkspaceConfig> _workspaces = {};

  /// Snapshots by workspace ID
  final Map<String, List<WorkspaceSnapshot>> _snapshots = {};

  /// Stream controller for workspace state changes
  final _stateController = StreamController<WorkspaceConfig>.broadcast();

  /// Stream of workspace state changes
  Stream<WorkspaceConfig> get onStateChange => _stateController.stream;

  /// UUID generator
  final _uuid = const Uuid();

  WorkspaceSessionManager({
    GitWorkspaceService? gitService,
  }) : _gitService = gitService ?? GitWorkspaceService();

  /// Initialize the workspace manager
  Future<void> initialize() async {
    // Set up workspaces root directory
    final appSupport = await _getAppSupportDirectory();
    _workspacesRoot = path.join(appSupport, 'workspaces');

    // Create root directory if it doesn't exist
    final rootDir = Directory(_workspacesRoot);
    if (!await rootDir.exists()) {
      await rootDir.create(recursive: true);
    }

    // Load existing workspace configs
    await _loadExistingWorkspaces();

    debugPrint('📁 WorkspaceSessionManager initialized at: $_workspacesRoot');
  }

  /// Get app support directory path
  Future<String> _getAppSupportDirectory() async {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      return path.join(home!, 'Library', 'Application Support', 'Asmbli');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      return path.join(appData!, 'Asmbli');
    } else {
      // Linux
      final home = Platform.environment['HOME'];
      return path.join(home!, '.local', 'share', 'asmbli');
    }
  }

  /// Load existing workspaces from disk
  Future<void> _loadExistingWorkspaces() async {
    final configFile = File(path.join(_workspacesRoot, 'workspaces.json'));
    if (await configFile.exists()) {
      try {
        final contents = await configFile.readAsString();
        final data = jsonDecode(contents) as Map<String, dynamic>;

        // Load workspaces
        final workspacesData = data['workspaces'] as List<dynamic>? ?? [];
        for (final wsData in workspacesData) {
          final config = WorkspaceConfig.fromJson(wsData as Map<String, dynamic>);
          _workspaces[config.id] = config;
        }

        // Load snapshots
        final snapshotsData = data['snapshots'] as Map<String, dynamic>? ?? {};
        for (final entry in snapshotsData.entries) {
          final snapshotList = (entry.value as List<dynamic>)
              .map((s) => WorkspaceSnapshot.fromJson(s as Map<String, dynamic>))
              .toList();
          _snapshots[entry.key] = snapshotList;
        }

        debugPrint('📂 Loaded ${_workspaces.length} existing workspaces');
      } catch (e) {
        debugPrint('⚠️ Error loading workspaces config: $e');
      }
    }
  }

  /// Save workspace configs to disk
  Future<void> _saveWorkspaces() async {
    final configFile = File(path.join(_workspacesRoot, 'workspaces.json'));

    final data = {
      'workspaces': _workspaces.values.map((w) => w.toJson()).toList(),
      'snapshots': _snapshots.map((k, v) => MapEntry(k, v.map((s) => s.toJson()).toList())),
    };

    await configFile.writeAsString(jsonEncode(data));
  }

  /// Create a new workspace by cloning a repository
  ///
  /// [repoUrl] - GitHub/GitLab/etc repository URL
  /// [name] - Display name for the workspace (defaults to repo name)
  /// [branch] - Specific branch to clone (null = default)
  /// [limits] - Resource limits (defaults to standard)
  Future<WorkspaceConfig> createWorkspace({
    required String repoUrl,
    String? name,
    String? branch,
    ResourceLimits limits = const ResourceLimits(),
  }) async {
    // Parse repo info from URL
    final repoInfo = RepoInfo.parseFromUrl(repoUrl);
    if (repoInfo == null) {
      throw WorkspaceException('Invalid repository URL: $repoUrl');
    }

    // Generate unique ID and workspace path
    final id = _uuid.v4();
    final workspacePath = path.join(_workspacesRoot, id);
    final now = DateTime.now();

    // Create initial config
    var config = WorkspaceConfig(
      id: id,
      name: name ?? '${repoInfo.owner}/${repoInfo.name}',
      repoInfo: repoInfo,
      branch: branch,
      limits: limits,
      workspacePath: workspacePath,
      state: WorkspaceState.creating,
      createdAt: now,
      lastAccessedAt: now,
    );

    _workspaces[id] = config;
    _stateController.add(config);

    try {
      // Create workspace directory
      await Directory(workspacePath).create(recursive: true);

      // Update state to cloning
      config = config.copyWith(state: WorkspaceState.cloning);
      _workspaces[id] = config;
      _stateController.add(config);

      // Clone the repository
      final cloneResult = await _gitService.cloneRepository(
        url: repoUrl,
        targetPath: workspacePath,
        branch: branch,
        shallow: config.shallowClone,
      );

      if (!cloneResult.success) {
        throw WorkspaceException('Clone failed: ${cloneResult.error}');
      }

      // Get updated repo info after clone
      final updatedRepoInfo = await _gitService.getRepoInfo(workspacePath);
      if (updatedRepoInfo != null) {
        config = config.copyWith(repoInfo: updatedRepoInfo);
      }

      // Detect project type and optionally install dependencies
      final projectType = updatedRepoInfo?.projectType ?? ProjectType.unknown;
      if (projectType != ProjectType.unknown) {
        config = config.copyWith(state: WorkspaceState.installing);
        _workspaces[id] = config;
        _stateController.add(config);

        await _installDependencies(workspacePath, projectType);
      }

      // Update state to ready
      config = config.copyWith(state: WorkspaceState.ready);
      _workspaces[id] = config;
      _stateController.add(config);

      // Save to disk
      await _saveWorkspaces();

      debugPrint('✅ Workspace created: ${config.name} at $workspacePath');
      return config;

    } catch (e) {
      // Handle error
      config = config.copyWith(
        state: WorkspaceState.error,
        errorMessage: e.toString(),
      );
      _workspaces[id] = config;
      _stateController.add(config);
      await _saveWorkspaces();

      debugPrint('❌ Workspace creation failed: $e');
      rethrow;
    }
  }

  /// Install dependencies based on project type
  Future<void> _installDependencies(String workspacePath, ProjectType projectType) async {
    try {
      switch (projectType) {
        case ProjectType.nodejs:
          // Check for package-lock.json vs yarn.lock
          final hasYarn = await File(path.join(workspacePath, 'yarn.lock')).exists();
          final command = hasYarn ? 'yarn' : 'npm';
          final args = hasYarn ? ['install'] : ['install', '--legacy-peer-deps'];

          final result = await Process.run(
            command,
            args,
            workingDirectory: workspacePath,
          );

          if (result.exitCode != 0) {
            debugPrint('⚠️ npm/yarn install warning: ${result.stderr}');
          }
          break;

        case ProjectType.flutter:
          await Process.run(
            'flutter',
            ['pub', 'get'],
            workingDirectory: workspacePath,
          );
          break;

        case ProjectType.python:
          // Check for various Python dependency files
          final hasPipfile = await File(path.join(workspacePath, 'Pipfile')).exists();
          final hasPoetry = await File(path.join(workspacePath, 'pyproject.toml')).exists();

          if (hasPipfile) {
            await Process.run('pipenv', ['install'], workingDirectory: workspacePath);
          } else if (hasPoetry) {
            await Process.run('poetry', ['install'], workingDirectory: workspacePath);
          } else if (await File(path.join(workspacePath, 'requirements.txt')).exists()) {
            await Process.run(
              'pip',
              ['install', '-r', 'requirements.txt'],
              workingDirectory: workspacePath,
            );
          }
          break;

        case ProjectType.rust:
          await Process.run('cargo', ['fetch'], workingDirectory: workspacePath);
          break;

        case ProjectType.golang:
          await Process.run('go', ['mod', 'download'], workingDirectory: workspacePath);
          break;

        case ProjectType.java:
          final hasGradle = await File(path.join(workspacePath, 'build.gradle')).exists();
          if (hasGradle) {
            await Process.run('./gradlew', ['dependencies'], workingDirectory: workspacePath);
          } else {
            await Process.run('mvn', ['dependency:resolve'], workingDirectory: workspacePath);
          }
          break;

        case ProjectType.unknown:
          break;
      }

      debugPrint('📦 Dependencies installed for $projectType project');
    } catch (e) {
      debugPrint('⚠️ Dependency installation error (non-fatal): $e');
    }
  }

  /// Get a workspace by ID
  WorkspaceConfig? getWorkspace(String id) => _workspaces[id];

  /// Get all workspaces
  List<WorkspaceConfig> getAllWorkspaces() => _workspaces.values.toList();

  /// Get workspaces sorted by last accessed
  List<WorkspaceConfig> getRecentWorkspaces({int limit = 10}) {
    final sorted = _workspaces.values.toList()
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
    return sorted.take(limit).toList();
  }

  /// Update workspace access time
  Future<void> touchWorkspace(String id) async {
    final config = _workspaces[id];
    if (config != null) {
      final updated = config.copyWith(lastAccessedAt: DateTime.now());
      _workspaces[id] = updated;
      await _saveWorkspaces();
    }
  }

  /// Reset workspace to clean state (discard all changes)
  Future<void> resetWorkspace(String id) async {
    final config = _workspaces[id];
    if (config == null) {
      throw WorkspaceException('Workspace not found: $id');
    }

    // Update state
    var updated = config.copyWith(state: WorkspaceState.busy);
    _workspaces[id] = updated;
    _stateController.add(updated);

    try {
      // Reset git state
      final result = await _gitService.resetToOrigin(config.workspacePath);
      if (!result.success) {
        throw WorkspaceException('Reset failed: ${result.error}');
      }

      // Update repo info
      final repoInfo = await _gitService.getRepoInfo(config.workspacePath);

      updated = config.copyWith(
        state: WorkspaceState.ready,
        repoInfo: repoInfo ?? config.repoInfo,
      );
      _workspaces[id] = updated;
      _stateController.add(updated);
      await _saveWorkspaces();

      debugPrint('🔄 Workspace reset: ${config.name}');
    } catch (e) {
      updated = config.copyWith(
        state: WorkspaceState.error,
        errorMessage: e.toString(),
      );
      _workspaces[id] = updated;
      _stateController.add(updated);
      rethrow;
    }
  }

  /// Create a snapshot of the current workspace state
  Future<WorkspaceSnapshot> createSnapshot(String workspaceId, {
    required String name,
    String? description,
  }) async {
    final config = _workspaces[workspaceId];
    if (config == null) {
      throw WorkspaceException('Workspace not found: $workspaceId');
    }

    // Update state
    var updated = config.copyWith(state: WorkspaceState.snapshotting);
    _workspaces[workspaceId] = updated;
    _stateController.add(updated);

    try {
      final snapshotId = _uuid.v4();
      final snapshotsDir = path.join(_workspacesRoot, '_snapshots', workspaceId);
      final archivePath = path.join(snapshotsDir, '$snapshotId.tar.gz');

      // Create snapshots directory
      await Directory(snapshotsDir).create(recursive: true);

      // Get current repo info
      final repoInfo = await _gitService.getRepoInfo(config.workspacePath);

      // Create tarball of workspace
      final result = await Process.run(
        'tar',
        ['-czf', archivePath, '-C', path.dirname(config.workspacePath), path.basename(config.workspacePath)],
      );

      if (result.exitCode != 0) {
        throw WorkspaceException('Snapshot creation failed: ${result.stderr}');
      }

      // Get archive size
      final archiveFile = File(archivePath);
      final sizeBytes = await archiveFile.length();

      // Create snapshot object
      final snapshot = WorkspaceSnapshot(
        id: snapshotId,
        workspaceId: workspaceId,
        name: name,
        description: description,
        createdAt: DateTime.now(),
        archivePath: archivePath,
        sizeBytes: sizeBytes,
        commitHash: repoInfo?.headCommit ?? '',
        branch: repoInfo?.currentBranch ?? 'main',
      );

      // Store snapshot
      _snapshots.putIfAbsent(workspaceId, () => []);
      _snapshots[workspaceId]!.add(snapshot);

      // Update state back to ready
      updated = config.copyWith(state: WorkspaceState.ready);
      _workspaces[workspaceId] = updated;
      _stateController.add(updated);
      await _saveWorkspaces();

      debugPrint('📸 Snapshot created: $name (${snapshot.formattedSize})');
      return snapshot;

    } catch (e) {
      updated = config.copyWith(
        state: WorkspaceState.error,
        errorMessage: e.toString(),
      );
      _workspaces[workspaceId] = updated;
      _stateController.add(updated);
      rethrow;
    }
  }

  /// Get snapshots for a workspace
  List<WorkspaceSnapshot> getSnapshots(String workspaceId) {
    return _snapshots[workspaceId] ?? [];
  }

  /// Restore workspace from a snapshot
  Future<void> restoreSnapshot(String workspaceId, String snapshotId) async {
    final config = _workspaces[workspaceId];
    if (config == null) {
      throw WorkspaceException('Workspace not found: $workspaceId');
    }

    final snapshots = _snapshots[workspaceId] ?? [];
    final snapshot = snapshots.firstWhere(
      (s) => s.id == snapshotId,
      orElse: () => throw WorkspaceException('Snapshot not found: $snapshotId'),
    );

    // Update state
    var updated = config.copyWith(state: WorkspaceState.restoring);
    _workspaces[workspaceId] = updated;
    _stateController.add(updated);

    try {
      // Remove current workspace contents
      final workspaceDir = Directory(config.workspacePath);
      if (await workspaceDir.exists()) {
        await workspaceDir.delete(recursive: true);
      }

      // Extract snapshot
      await Directory(path.dirname(config.workspacePath)).create(recursive: true);

      final result = await Process.run(
        'tar',
        ['-xzf', snapshot.archivePath, '-C', path.dirname(config.workspacePath)],
      );

      if (result.exitCode != 0) {
        throw WorkspaceException('Snapshot restoration failed: ${result.stderr}');
      }

      // Get updated repo info
      final repoInfo = await _gitService.getRepoInfo(config.workspacePath);

      // Update state
      updated = config.copyWith(
        state: WorkspaceState.ready,
        repoInfo: repoInfo ?? config.repoInfo,
      );
      _workspaces[workspaceId] = updated;
      _stateController.add(updated);
      await _saveWorkspaces();

      debugPrint('🔄 Workspace restored from snapshot: ${snapshot.name}');

    } catch (e) {
      updated = config.copyWith(
        state: WorkspaceState.error,
        errorMessage: e.toString(),
      );
      _workspaces[workspaceId] = updated;
      _stateController.add(updated);
      rethrow;
    }
  }

  /// Delete a snapshot
  Future<void> deleteSnapshot(String workspaceId, String snapshotId) async {
    final snapshots = _snapshots[workspaceId];
    if (snapshots == null) return;

    final snapshotIndex = snapshots.indexWhere((s) => s.id == snapshotId);
    if (snapshotIndex < 0) return;

    final snapshot = snapshots[snapshotIndex];

    // Delete archive file
    final archiveFile = File(snapshot.archivePath);
    if (await archiveFile.exists()) {
      await archiveFile.delete();
    }

    // Remove from list
    snapshots.removeAt(snapshotIndex);
    await _saveWorkspaces();

    debugPrint('🗑️ Snapshot deleted: ${snapshot.name}');
  }

  /// Delete a workspace
  Future<void> deleteWorkspace(String id) async {
    final config = _workspaces[id];
    if (config == null) return;

    // Delete workspace directory
    final workspaceDir = Directory(config.workspacePath);
    if (await workspaceDir.exists()) {
      await workspaceDir.delete(recursive: true);
    }

    // Delete snapshots
    final snapshotsDir = Directory(path.join(_workspacesRoot, '_snapshots', id));
    if (await snapshotsDir.exists()) {
      await snapshotsDir.delete(recursive: true);
    }

    // Remove from maps
    _workspaces.remove(id);
    _snapshots.remove(id);

    // Notify and save
    final disposed = config.copyWith(state: WorkspaceState.disposed);
    _stateController.add(disposed);
    await _saveWorkspaces();

    debugPrint('🗑️ Workspace deleted: ${config.name}');
  }

  /// Get disk usage for a workspace
  Future<int> getWorkspaceDiskUsage(String id) async {
    final config = _workspaces[id];
    if (config == null) return 0;

    try {
      final result = await Process.run(
        'du',
        ['-sk', config.workspacePath],
      );

      if (result.exitCode == 0) {
        final parts = result.stdout.toString().split(RegExp(r'\s+'));
        return int.tryParse(parts.first) ?? 0; // Returns KB
      }
    } catch (e) {
      debugPrint('Error getting disk usage: $e');
    }

    return 0;
  }

  /// Check if workspace is within resource limits
  Future<bool> isWithinLimits(String id) async {
    final config = _workspaces[id];
    if (config == null) return false;

    final diskUsageKB = await getWorkspaceDiskUsage(id);
    final diskUsageMB = diskUsageKB ~/ 1024;

    return diskUsageMB <= config.limits.maxDiskMB;
  }

  /// Get file tree for a workspace
  Future<FileNode> getFileTree(String workspaceId) async {
    final config = _workspaces[workspaceId];
    if (config == null) {
      throw WorkspaceException('Workspace not found: $workspaceId');
    }

    // Get list of changed files
    final diffs = await _gitService.getDiff(config.workspacePath);
    final changedPaths = diffs.map((d) => d.path).toSet();

    return _buildFileTree(
      Directory(config.workspacePath),
      config.workspacePath,
      changedPaths,
    );
  }

  /// Build file tree recursively
  Future<FileNode> _buildFileTree(
    Directory dir,
    String rootPath,
    Set<String> changedPaths,
  ) async {
    final relativePath = path.relative(dir.path, from: rootPath);
    final name = path.basename(dir.path);

    final children = <FileNode>[];

    await for (final entity in dir.list()) {
      final entityName = path.basename(entity.path);

      // Skip hidden files and common ignored directories
      if (entityName.startsWith('.') ||
          entityName == 'node_modules' ||
          entityName == 'build' ||
          entityName == '.dart_tool' ||
          entityName == '__pycache__') {
        continue;
      }

      if (entity is Directory) {
        children.add(await _buildFileTree(entity, rootPath, changedPaths));
      } else if (entity is File) {
        final relPath = path.relative(entity.path, from: rootPath);
        final stat = await entity.stat();

        children.add(FileNode(
          name: entityName,
          path: relPath,
          isDirectory: false,
          sizeBytes: stat.size,
          lastModified: stat.modified,
          hasChanges: changedPaths.contains(relPath),
        ));
      }
    }

    // Sort: directories first, then alphabetically
    children.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return FileNode(
      name: name,
      path: relativePath.isEmpty ? '.' : relativePath,
      isDirectory: true,
      children: children,
    );
  }

  /// Read a file from workspace
  Future<String> readFile(String workspaceId, String relativePath) async {
    final config = _workspaces[workspaceId];
    if (config == null) {
      throw WorkspaceException('Workspace not found: $workspaceId');
    }

    final filePath = path.join(config.workspacePath, relativePath);
    final file = File(filePath);

    if (!await file.exists()) {
      throw WorkspaceException('File not found: $relativePath');
    }

    return file.readAsString();
  }

  /// Write a file in workspace
  Future<void> writeFile(String workspaceId, String relativePath, String content) async {
    final config = _workspaces[workspaceId];
    if (config == null) {
      throw WorkspaceException('Workspace not found: $workspaceId');
    }

    final filePath = path.join(config.workspacePath, relativePath);
    final file = File(filePath);

    // Ensure parent directory exists
    await file.parent.create(recursive: true);

    await file.writeAsString(content);

    debugPrint('📝 File written: $relativePath');
  }

  /// Run a command in workspace directory
  Future<ProcessResult> runCommand(
    String workspaceId,
    String command,
    List<String> args, {
    Duration? timeout,
  }) async {
    final config = _workspaces[workspaceId];
    if (config == null) {
      throw WorkspaceException('Workspace not found: $workspaceId');
    }

    // Use configured timeout or limit
    final effectiveTimeout = timeout ?? config.limits.maxCommandRuntime;

    debugPrint('🖥️ Running: $command ${args.join(' ')}');

    return Process.run(
      command,
      args,
      workingDirectory: config.workspacePath,
    ).timeout(
      effectiveTimeout,
      onTimeout: () {
        throw WorkspaceException('Command timed out after ${effectiveTimeout.inSeconds}s');
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}

/// Exception for workspace operations
class WorkspaceException implements Exception {
  final String message;

  WorkspaceException(this.message);

  @override
  String toString() => 'WorkspaceException: $message';
}

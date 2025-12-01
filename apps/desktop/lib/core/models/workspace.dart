// Workspace models for IDE Prototyping Agent
//
// These models support isolated code experimentation environments
// where users can clone repos and experiment without consequences.

import 'package:flutter/foundation.dart';

/// Workspace lifecycle states
enum WorkspaceState {
  /// Initial state - workspace being set up
  creating,

  /// Cloning repository from remote
  cloning,

  /// Installing dependencies (npm install, etc.)
  installing,

  /// Ready for use
  ready,

  /// Command or operation in progress
  busy,

  /// Creating a snapshot
  snapshotting,

  /// Restoring from a snapshot
  restoring,

  /// Error state - needs attention
  error,

  /// Workspace has been disposed/deleted
  disposed,
}

/// Resource limits for workspace isolation
@immutable
class ResourceLimits {
  /// Maximum disk space in MB (default: 500MB)
  final int maxDiskMB;

  /// Maximum concurrent processes (default: 10)
  final int maxProcesses;

  /// Maximum runtime per command (default: 30 minutes)
  final Duration maxCommandRuntime;

  /// Maximum open files (default: 100)
  final int maxOpenFiles;

  /// Maximum memory in MB (default: 1024MB)
  final int maxMemoryMB;

  const ResourceLimits({
    this.maxDiskMB = 500,
    this.maxProcesses = 10,
    this.maxCommandRuntime = const Duration(minutes: 30),
    this.maxOpenFiles = 100,
    this.maxMemoryMB = 1024,
  });

  /// Default resource limits
  static const ResourceLimits standard = ResourceLimits();

  /// Restricted limits for untrusted repos
  static const ResourceLimits restricted = ResourceLimits(
    maxDiskMB: 200,
    maxProcesses: 5,
    maxCommandRuntime: Duration(minutes: 10),
    maxOpenFiles: 50,
    maxMemoryMB: 512,
  );

  /// Generous limits for trusted repos
  static const ResourceLimits generous = ResourceLimits(
    maxDiskMB: 2000,
    maxProcesses: 20,
    maxCommandRuntime: Duration(hours: 1),
    maxOpenFiles: 500,
    maxMemoryMB: 4096,
  );

  Map<String, dynamic> toJson() => {
    'maxDiskMB': maxDiskMB,
    'maxProcesses': maxProcesses,
    'maxCommandRuntimeSeconds': maxCommandRuntime.inSeconds,
    'maxOpenFiles': maxOpenFiles,
    'maxMemoryMB': maxMemoryMB,
  };

  factory ResourceLimits.fromJson(Map<String, dynamic> json) => ResourceLimits(
    maxDiskMB: json['maxDiskMB'] as int? ?? 500,
    maxProcesses: json['maxProcesses'] as int? ?? 10,
    maxCommandRuntime: Duration(seconds: json['maxCommandRuntimeSeconds'] as int? ?? 1800),
    maxOpenFiles: json['maxOpenFiles'] as int? ?? 100,
    maxMemoryMB: json['maxMemoryMB'] as int? ?? 1024,
  );
}

/// Detected project type
enum ProjectType {
  /// Node.js/JavaScript/TypeScript (package.json)
  nodejs,

  /// Flutter/Dart (pubspec.yaml)
  flutter,

  /// Python (requirements.txt, setup.py, pyproject.toml)
  python,

  /// Rust (Cargo.toml)
  rust,

  /// Go (go.mod)
  golang,

  /// Java/Kotlin (pom.xml, build.gradle)
  java,

  /// Generic or unknown
  unknown,
}

/// Repository information
@immutable
class RepoInfo {
  /// Remote URL
  final String url;

  /// Repository name (extracted from URL)
  final String name;

  /// Owner/organization
  final String owner;

  /// Default branch name
  final String defaultBranch;

  /// Currently checked out branch
  final String currentBranch;

  /// Current HEAD commit hash
  final String headCommit;

  /// Short commit hash for display
  String get shortCommit => headCommit.length > 7 ? headCommit.substring(0, 7) : headCommit;

  /// Available branches
  final List<String> branches;

  /// Number of uncommitted changes
  final int uncommittedChanges;

  /// Whether there are merge conflicts
  final bool hasConflicts;

  /// Detected project type
  final ProjectType projectType;

  const RepoInfo({
    required this.url,
    required this.name,
    required this.owner,
    required this.defaultBranch,
    required this.currentBranch,
    required this.headCommit,
    this.branches = const [],
    this.uncommittedChanges = 0,
    this.hasConflicts = false,
    this.projectType = ProjectType.unknown,
  });

  /// Whether there are unsaved changes
  bool get hasChanges => uncommittedChanges > 0;

  /// Whether repo is clean
  bool get isClean => uncommittedChanges == 0 && !hasConflicts;

  RepoInfo copyWith({
    String? url,
    String? name,
    String? owner,
    String? defaultBranch,
    String? currentBranch,
    String? headCommit,
    List<String>? branches,
    int? uncommittedChanges,
    bool? hasConflicts,
    ProjectType? projectType,
  }) => RepoInfo(
    url: url ?? this.url,
    name: name ?? this.name,
    owner: owner ?? this.owner,
    defaultBranch: defaultBranch ?? this.defaultBranch,
    currentBranch: currentBranch ?? this.currentBranch,
    headCommit: headCommit ?? this.headCommit,
    branches: branches ?? this.branches,
    uncommittedChanges: uncommittedChanges ?? this.uncommittedChanges,
    hasConflicts: hasConflicts ?? this.hasConflicts,
    projectType: projectType ?? this.projectType,
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'name': name,
    'owner': owner,
    'defaultBranch': defaultBranch,
    'currentBranch': currentBranch,
    'headCommit': headCommit,
    'branches': branches,
    'uncommittedChanges': uncommittedChanges,
    'hasConflicts': hasConflicts,
    'projectType': projectType.name,
  };

  factory RepoInfo.fromJson(Map<String, dynamic> json) => RepoInfo(
    url: json['url'] as String,
    name: json['name'] as String,
    owner: json['owner'] as String,
    defaultBranch: json['defaultBranch'] as String,
    currentBranch: json['currentBranch'] as String,
    headCommit: json['headCommit'] as String,
    branches: (json['branches'] as List<dynamic>?)?.cast<String>() ?? [],
    uncommittedChanges: json['uncommittedChanges'] as int? ?? 0,
    hasConflicts: json['hasConflicts'] as bool? ?? false,
    projectType: ProjectType.values.firstWhere(
      (e) => e.name == json['projectType'],
      orElse: () => ProjectType.unknown,
    ),
  );

  /// Parse repo info from a GitHub URL
  static RepoInfo? parseFromUrl(String url) {
    // Handle various URL formats:
    // https://github.com/owner/repo
    // https://github.com/owner/repo.git
    // git@github.com:owner/repo.git
    final patterns = [
      RegExp(r'github\.com[/:]([^/]+)/([^/\.]+)'),
      RegExp(r'gitlab\.com[/:]([^/]+)/([^/\.]+)'),
      RegExp(r'bitbucket\.org[/:]([^/]+)/([^/\.]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return RepoInfo(
          url: url,
          owner: match.group(1)!,
          name: match.group(2)!,
          defaultBranch: 'main',
          currentBranch: 'main',
          headCommit: '',
        );
      }
    }
    return null;
  }
}

/// Workspace configuration
@immutable
class WorkspaceConfig {
  /// Unique workspace ID
  final String id;

  /// Display name for the workspace
  final String name;

  /// Repository information
  final RepoInfo repoInfo;

  /// Specific branch to clone (null = default branch)
  final String? branch;

  /// Specific commit to checkout (null = HEAD)
  final String? commitHash;

  /// Whether to do a shallow clone (--depth=1)
  final bool shallowClone;

  /// Resource limits for this workspace
  final ResourceLimits limits;

  /// Path to workspace directory
  final String workspacePath;

  /// Current state
  final WorkspaceState state;

  /// Error message if in error state
  final String? errorMessage;

  /// When the workspace was created
  final DateTime createdAt;

  /// When the workspace was last accessed
  final DateTime lastAccessedAt;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  const WorkspaceConfig({
    required this.id,
    required this.name,
    required this.repoInfo,
    this.branch,
    this.commitHash,
    this.shallowClone = true,
    this.limits = const ResourceLimits(),
    required this.workspacePath,
    this.state = WorkspaceState.creating,
    this.errorMessage,
    required this.createdAt,
    required this.lastAccessedAt,
    this.metadata = const {},
  });

  WorkspaceConfig copyWith({
    String? id,
    String? name,
    RepoInfo? repoInfo,
    String? branch,
    String? commitHash,
    bool? shallowClone,
    ResourceLimits? limits,
    String? workspacePath,
    WorkspaceState? state,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    Map<String, dynamic>? metadata,
  }) => WorkspaceConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    repoInfo: repoInfo ?? this.repoInfo,
    branch: branch ?? this.branch,
    commitHash: commitHash ?? this.commitHash,
    shallowClone: shallowClone ?? this.shallowClone,
    limits: limits ?? this.limits,
    workspacePath: workspacePath ?? this.workspacePath,
    state: state ?? this.state,
    errorMessage: errorMessage,
    createdAt: createdAt ?? this.createdAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    metadata: metadata ?? this.metadata,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'repoInfo': repoInfo.toJson(),
    'branch': branch,
    'commitHash': commitHash,
    'shallowClone': shallowClone,
    'limits': limits.toJson(),
    'workspacePath': workspacePath,
    'state': state.name,
    'errorMessage': errorMessage,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory WorkspaceConfig.fromJson(Map<String, dynamic> json) => WorkspaceConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    repoInfo: RepoInfo.fromJson(json['repoInfo'] as Map<String, dynamic>),
    branch: json['branch'] as String?,
    commitHash: json['commitHash'] as String?,
    shallowClone: json['shallowClone'] as bool? ?? true,
    limits: json['limits'] != null
        ? ResourceLimits.fromJson(json['limits'] as Map<String, dynamic>)
        : const ResourceLimits(),
    workspacePath: json['workspacePath'] as String,
    state: WorkspaceState.values.firstWhere(
      (e) => e.name == json['state'],
      orElse: () => WorkspaceState.creating,
    ),
    errorMessage: json['errorMessage'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}

/// Workspace snapshot for save/restore functionality
@immutable
class WorkspaceSnapshot {
  /// Unique snapshot ID
  final String id;

  /// Workspace this snapshot belongs to
  final String workspaceId;

  /// User-provided name
  final String name;

  /// Optional description
  final String? description;

  /// When the snapshot was created
  final DateTime createdAt;

  /// Path to the snapshot archive
  final String archivePath;

  /// Size of the snapshot in bytes
  final int sizeBytes;

  /// Hash of each file for diff detection
  final Map<String, String> fileHashes;

  /// Git commit hash at time of snapshot
  final String commitHash;

  /// Branch name at time of snapshot
  final String branch;

  const WorkspaceSnapshot({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.archivePath,
    required this.sizeBytes,
    this.fileHashes = const {},
    required this.commitHash,
    required this.branch,
  });

  /// Human-readable size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'archivePath': archivePath,
    'sizeBytes': sizeBytes,
    'fileHashes': fileHashes,
    'commitHash': commitHash,
    'branch': branch,
  };

  factory WorkspaceSnapshot.fromJson(Map<String, dynamic> json) => WorkspaceSnapshot(
    id: json['id'] as String,
    workspaceId: json['workspaceId'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    archivePath: json['archivePath'] as String,
    sizeBytes: json['sizeBytes'] as int,
    fileHashes: (json['fileHashes'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
    commitHash: json['commitHash'] as String,
    branch: json['branch'] as String,
  );
}

/// File node in workspace file tree
@immutable
class FileNode {
  /// File/directory name
  final String name;

  /// Full path relative to workspace root
  final String path;

  /// Whether this is a directory
  final bool isDirectory;

  /// Whether this is expanded (for directories)
  final bool isExpanded;

  /// Children (for directories)
  final List<FileNode> children;

  /// File size in bytes (for files)
  final int? sizeBytes;

  /// Last modified time
  final DateTime? lastModified;

  /// Whether file has uncommitted changes
  final bool hasChanges;

  /// Whether this is a new/untracked file
  final bool isUntracked;

  const FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.isExpanded = false,
    this.children = const [],
    this.sizeBytes,
    this.lastModified,
    this.hasChanges = false,
    this.isUntracked = false,
  });

  FileNode copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    bool? isExpanded,
    List<FileNode>? children,
    int? sizeBytes,
    DateTime? lastModified,
    bool? hasChanges,
    bool? isUntracked,
  }) => FileNode(
    name: name ?? this.name,
    path: path ?? this.path,
    isDirectory: isDirectory ?? this.isDirectory,
    isExpanded: isExpanded ?? this.isExpanded,
    children: children ?? this.children,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    lastModified: lastModified ?? this.lastModified,
    hasChanges: hasChanges ?? this.hasChanges,
    isUntracked: isUntracked ?? this.isUntracked,
  );
}

/// Git operation result
@immutable
class GitResult {
  final bool success;
  final String output;
  final String? error;
  final int exitCode;
  final Duration duration;

  const GitResult({
    required this.success,
    required this.output,
    this.error,
    required this.exitCode,
    required this.duration,
  });

  factory GitResult.success(String output, Duration duration) => GitResult(
    success: true,
    output: output,
    exitCode: 0,
    duration: duration,
  );

  factory GitResult.failure(String error, int exitCode, Duration duration) => GitResult(
    success: false,
    output: '',
    error: error,
    exitCode: exitCode,
    duration: duration,
  );
}

/// File diff information
@immutable
class FileDiff {
  /// File path
  final String path;

  /// Type of change
  final DiffType type;

  /// Number of lines added
  final int linesAdded;

  /// Number of lines removed
  final int linesRemoved;

  /// Full diff content (unified format)
  final String? diffContent;

  const FileDiff({
    required this.path,
    required this.type,
    this.linesAdded = 0,
    this.linesRemoved = 0,
    this.diffContent,
  });
}

/// Type of file change
enum DiffType {
  added,
  modified,
  deleted,
  renamed,
  copied,
}

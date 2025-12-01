# IDE Prototyping Agent Architecture

## Overview

The IDE Prototyping Agent enables users to safely experiment with any GitHub repository within isolated workspace environments. Users can clone repos, make changes, run tests, and prototype without fear of affecting the original codebase or their local system.

## Core Principles

1. **Complete Isolation** - Each workspace is sandboxed with no access to system files
2. **Worry-Free Experimentation** - All changes are disposable; one click to reset
3. **Agent-Assisted Coding** - AI helps navigate, modify, and understand code
4. **Snapshot & Restore** - Save interesting states, restore anytime
5. **Safe Execution** - Run code in controlled environments with resource limits

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         IDE Prototyping Agent UI                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────────────┐  ┌────────────────────────────┐  │
│  │ Workspace   │  │    Code Editor      │  │      Terminal Panel        │  │
│  │ File Tree   │  │  (Monaco/CodeMirror)│  │   (Streaming Output)       │  │
│  │             │  │                     │  │                            │  │
│  │ [repo/]     │  │  // your code here  │  │  $ npm test               │  │
│  │  ├─ src/    │  │                     │  │  PASS: 42 tests           │  │
│  │  ├─ tests/  │  │                     │  │  $ _                       │  │
│  │  └─ ...     │  │                     │  │                            │  │
│  └─────────────┘  └─────────────────────┘  └────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Agent Chat (Contextual)                          │   │
│  │  "Explain this function" → AI analyzes code in current workspace    │   │
│  │  "Add error handling"    → AI modifies files in sandbox            │   │
│  │  "Run the tests"         → Executes in isolated terminal           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Service Layer                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐                      │
│  │ WorkspaceSessionMgr  │◄───│  GitWorkspaceService │                      │
│  │                      │    │                      │                      │
│  │ • Create workspace   │    │ • Clone repos        │                      │
│  │ • Snapshot/restore   │    │ • Branch management  │                      │
│  │ • Cleanup            │    │ • Diff tracking      │                      │
│  │ • Resource limits    │    │ • Reset to origin    │                      │
│  └──────────┬───────────┘    └──────────────────────┘                      │
│             │                                                               │
│             ▼                                                               │
│  ┌──────────────────────┐    ┌──────────────────────┐                      │
│  │ FileSystemAccessCtrl │    │ AgentTerminalManager │  ◄── EXISTING        │
│  │                      │    │                      │                      │
│  │ • Sandbox boundaries │    │ • Command execution  │                      │
│  │ • Path validation    │    │ • Streaming output   │                      │
│  │ • Access logging     │    │ • Process lifecycle  │                      │
│  └──────────────────────┘    └──────────────────────┘                      │
│                                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐                      │
│  │ CommandSecurityValid │    │   SecurityContext    │  ◄── EXISTING        │
│  │                      │    │                      │                      │
│  │ • Command whitelist  │    │ • Resource limits    │                      │
│  │ • Dangerous cmd block│    │ • Network policies   │                      │
│  │ • Approval workflows │    │ • File permissions   │                      │
│  └──────────────────────┘    └──────────────────────┘                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Storage Layer                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ~/Documents/AgentEngine/workspaces/                                       │
│   ├── {workspace_id}/                                                       │
│   │   ├── .workspace/              # Workspace metadata                     │
│   │   │   ├── config.json          # Workspace settings                     │
│   │   │   ├── snapshots/           # Saved states                          │
│   │   │   │   ├── snapshot_001.tar.gz                                      │
│   │   │   │   └── snapshot_002.tar.gz                                      │
│   │   │   └── history.json         # Command/change history                │
│   │   └── repo/                    # Cloned repository (sandbox)           │
│   │       ├── src/                                                          │
│   │       ├── package.json                                                  │
│   │       └── ...                                                           │
│   └── {workspace_id_2}/                                                     │
│       └── ...                                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Core Services

### 1. WorkspaceSessionManager

Manages the lifecycle of isolated workspace sessions.

```dart
/// Workspace session states
enum WorkspaceState {
  creating,      // Cloning repo, setting up environment
  ready,         // Ready for use
  busy,          // Operation in progress
  snapshotting,  // Creating snapshot
  restoring,     // Restoring from snapshot
  disposed,      // Cleaned up
}

/// Workspace configuration
class WorkspaceConfig {
  final String id;
  final String repoUrl;
  final String? branch;
  final String? commitHash;
  final ResourceLimits limits;
  final SecurityContext security;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
}

/// Resource limits for workspace
class ResourceLimits {
  final int maxDiskMB;        // e.g., 500MB
  final int maxProcesses;     // e.g., 10
  final Duration maxRuntime;  // e.g., 30 minutes per command
  final int maxOpenFiles;     // e.g., 100
}

/// Workspace snapshot for save/restore
class WorkspaceSnapshot {
  final String id;
  final String workspaceId;
  final String name;
  final String description;
  final DateTime createdAt;
  final String archivePath;
  final Map<String, String> fileHashes;  // For diff detection
}
```

### 2. GitWorkspaceService

Handles all Git operations within workspaces.

```dart
/// Git operation results
class GitResult {
  final bool success;
  final String output;
  final String? error;
  final int exitCode;
}

/// Repository info
class RepoInfo {
  final String url;
  final String defaultBranch;
  final String currentBranch;
  final String headCommit;
  final List<String> branches;
  final int uncommittedChanges;
  final bool hasConflicts;
}

/// Key operations:
/// - cloneRepo(url, branch?, depth?) → Clone with optional shallow
/// - resetToOrigin() → Discard all changes, reset to remote HEAD
/// - createBranch(name) → Create experiment branch
/// - getDiff() → Get all uncommitted changes
/// - stashChanges() / popStash() → Temporary storage
/// - getFileHistory(path) → Git log for specific file
```

### 3. IDEPrototypingAgent

The AI agent that assists with code exploration and modification.

```dart
/// Agent capabilities specific to IDE prototyping
class IDEPrototypingCapabilities {
  // Code Understanding
  final bool canAnalyzeCode;
  final bool canExplainFunctions;
  final bool canFindReferences;
  final bool canSuggestRefactors;

  // Code Modification
  final bool canEditFiles;
  final bool canCreateFiles;
  final bool canDeleteFiles;
  final bool canRenameFiles;

  // Execution
  final bool canRunCommands;
  final bool canRunTests;
  final bool canInstallDependencies;
  final bool canStartDevServer;

  // Workspace Management
  final bool canCreateSnapshots;
  final bool canRestoreSnapshots;
  final bool canResetWorkspace;
}

/// Agent context for IDE operations
class IDEAgentContext {
  final String workspaceId;
  final String currentFilePath;
  final String? selectedCode;
  final List<String> openFiles;
  final RepoInfo repoInfo;
  final List<String> recentCommands;
}
```

---

## Workspace Lifecycle

### 1. Creation Flow

```
User: "Clone https://github.com/user/repo"
         │
         ▼
┌─────────────────────────────────────────┐
│ 1. Validate URL (GitHub, GitLab, etc.)  │
│ 2. Check disk space availability        │
│ 3. Create workspace directory           │
│ 4. Initialize security context          │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 5. git clone --depth=1 (shallow clone)  │
│ 6. Detect project type (package.json?)  │
│ 7. Auto-install dependencies (optional) │
│ 8. Create initial snapshot              │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 9. Workspace ready for experimentation  │
│ 10. Agent analyzes project structure    │
│ 11. UI shows file tree + initial view   │
└─────────────────────────────────────────┘
```

### 2. Experimentation Flow

```
User: "Add error handling to the login function"
         │
         ▼
┌─────────────────────────────────────────┐
│ Agent Actions:                          │
│ 1. Find login function (search codebase)│
│ 2. Analyze current implementation       │
│ 3. Generate modified code               │
│ 4. Apply changes to file (sandbox)      │
│ 5. Show diff to user                    │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ User can:                               │
│ • Accept changes (keep in workspace)    │
│ • Reject changes (auto-revert)          │
│ • Modify further ("also add logging")   │
│ • Test changes ("run npm test")         │
│ • Snapshot ("save this state")          │
└─────────────────────────────────────────┘
```

### 3. Reset Flow

```
User: "Reset workspace" or clicks [Reset] button
         │
         ▼
┌─────────────────────────────────────────┐
│ Options:                                │
│ • Reset to initial clone state          │
│ • Reset to specific snapshot            │
│ • Reset only specific files             │
│ • Hard reset (delete & re-clone)        │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ git checkout . && git clean -fd         │
│ OR                                      │
│ Restore from snapshot archive           │
└─────────────────────────────────────────┘
         │
         ▼
    Workspace back to clean state
```

---

## Security Model

### Sandbox Boundaries

```dart
/// Security context for IDE workspace
SecurityContext.forIDEWorkspace({
  required String workspaceId,
  required String workspacePath,
}) {
  return SecurityContext(
    // Only allow access within workspace
    allowedPaths: {
      workspacePath: PathPermission.readWrite,
      '$workspacePath/.workspace': PathPermission.readWrite,
    },

    // Block system directories
    blockedPaths: [
      '/', '/etc', '/var', '/usr', '/bin', '/sbin',
      Platform.environment['HOME']!,  // Block home except workspace
    ],

    // Allowed commands (whitelist approach)
    allowedCommands: [
      'git', 'npm', 'yarn', 'pnpm', 'node', 'npx',
      'python', 'pip', 'python3', 'pip3',
      'cargo', 'rustc',
      'go', 'flutter', 'dart',
      'cat', 'ls', 'find', 'grep', 'head', 'tail',
      'mkdir', 'rm', 'cp', 'mv', 'touch',
    ],

    // Blocked dangerous commands
    blockedCommands: [
      'sudo', 'su', 'chmod 777', 'rm -rf /',
      'curl | bash', 'wget | sh',
      'eval', 'exec',
    ],

    // Network restrictions
    networkPolicy: NetworkPolicy(
      allowOutbound: true,  // For npm install, etc.
      allowedHosts: ['*'],  // Or restrict to npm, pypi, etc.
      blockedHosts: [],
    ),

    // Resource limits
    resourceLimits: ResourceLimits(
      maxDiskMB: 500,
      maxProcesses: 10,
      maxRuntime: Duration(minutes: 30),
      maxMemoryMB: 1024,
    ),
  );
}
```

### Command Validation Pipeline

```
User/Agent requests: "npm install && npm run build"
         │
         ▼
┌─────────────────────────────────────────┐
│ 1. Parse command into components        │
│    ["npm install", "npm run build"]     │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 2. Check against whitelist              │
│    npm ✓ (allowed)                      │
│    install ✓ (safe npm subcommand)      │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 3. Validate working directory           │
│    Must be within workspace sandbox     │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 4. Check resource availability          │
│    Disk space? Process slots?           │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ 5. Execute with timeout & monitoring    │
│    Stream output to UI                  │
│    Track resource usage                 │
└─────────────────────────────────────────┘
```

---

## UI Components

### 1. Workspace Browser

```
┌──────────────────────────────────────────────────┐
│ 🔬 IDE Prototyping                    [+ New]   │
├──────────────────────────────────────────────────┤
│ Active Workspaces:                               │
│                                                  │
│ ┌────────────────────────────────────────────┐  │
│ │ 📁 react-todo-app                          │  │
│ │    github.com/example/react-todo           │  │
│ │    Branch: experiment-1  •  3 changes      │  │
│ │    [Open] [Reset] [Delete]                 │  │
│ └────────────────────────────────────────────┘  │
│                                                  │
│ ┌────────────────────────────────────────────┐  │
│ │ 📁 flutter-weather                         │  │
│ │    github.com/example/weather-app          │  │
│ │    Branch: main  •  Clean                  │  │
│ │    [Open] [Reset] [Delete]                 │  │
│ └────────────────────────────────────────────┘  │
│                                                  │
│ ─────────────────────────────────────────────── │
│ Clone New Repository:                            │
│ ┌────────────────────────────────────────────┐  │
│ │ https://github.com/...           [Clone]   │  │
│ └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

### 2. Workspace Editor View

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 📁 react-todo-app                    [Snapshot ▾] [Reset] [⚙️]         │
├────────────┬────────────────────────────────────────────────────────────┤
│ Files      │  src/components/TodoItem.tsx                               │
│            ├────────────────────────────────────────────────────────────┤
│ ▼ src/     │  1│ import React from 'react';                             │
│   ▼ comp/  │  2│ import { Todo } from '../types';                       │
│     □ Todo │  3│                                                        │
│     □ List │  4│ interface Props {                                      │
│     □ Form │  5│   todo: Todo;                                          │
│   □ App.tsx│  6│   onToggle: (id: string) => void;                      │
│   □ index  │  7│ }                                                      │
│ ▼ tests/   │  8│                                                        │
│   □ App.t  │  9│ export const TodoItem: React.FC<Props> = ({            │
│ □ package  │ 10│   todo,                                                │
│            │ 11│   onToggle,                                            │
├────────────┴────────────────────────────────────────────────────────────┤
│ 🤖 Agent                                                                │
│ ┌─────────────────────────────────────────────────────────────────────┐│
│ │ You: Add a delete button to TodoItem                                ││
│ │                                                                     ││
│ │ Agent: I'll add a delete button. Here's what I'll change:           ││
│ │                                                                     ││
│ │ ```diff                                                             ││
│ │ + onDelete: (id: string) => void;                                   ││
│ │ + <button onClick={() => onDelete(todo.id)}>Delete</button>         ││
│ │ ```                                                                 ││
│ │                                                                     ││
│ │ [Apply Changes] [Show Full Diff] [Reject]                           ││
│ └─────────────────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────────────┤
│ Terminal                                                    [+ New Tab] │
│ ┌─────────────────────────────────────────────────────────────────────┐│
│ │ ~/workspace/react-todo-app $ npm test                               ││
│ │ PASS  src/components/TodoItem.test.tsx                              ││
│ │ PASS  src/components/TodoList.test.tsx                              ││
│ │ Tests: 12 passed, 12 total                                          ││
│ │ ~/workspace/react-todo-app $ _                                      ││
│ └─────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

### 3. Snapshot Manager

```
┌──────────────────────────────────────────────────┐
│ 📸 Snapshots - react-todo-app                    │
├──────────────────────────────────────────────────┤
│                                                  │
│ ┌────────────────────────────────────────────┐  │
│ │ 🟢 Current State                           │  │
│ │    5 files changed, 42 insertions          │  │
│ │    [Save as Snapshot]                      │  │
│ └────────────────────────────────────────────┘  │
│                                                  │
│ ┌────────────────────────────────────────────┐  │
│ │ 📸 "Added delete functionality"            │  │
│ │    Created: 2 hours ago                    │  │
│ │    [Restore] [View Diff] [Delete]          │  │
│ └────────────────────────────────────────────┘  │
│                                                  │
│ ┌────────────────────────────────────────────┐  │
│ │ 📸 "Initial clone"                         │  │
│ │    Created: 3 hours ago                    │  │
│ │    [Restore] [View Diff] [Delete]          │  │
│ └────────────────────────────────────────────┘  │
│                                                  │
│ ─────────────────────────────────────────────── │
│ Storage used: 45 MB / 500 MB                    │
└──────────────────────────────────────────────────┘
```

---

## Integration with Existing Services

### Service Dependencies

```dart
// ServiceLocator registration
ServiceLocator.instance
  // New services
  ..registerSingleton<GitWorkspaceService>(GitWorkspaceService())
  ..registerSingleton<WorkspaceSessionManager>(WorkspaceSessionManager(
    fileSystemService: get<DesktopFileSystemService>(),
    accessControl: get<FileSystemAccessControl>(),
    terminalManager: get<AgentTerminalManager>(),
    securityValidator: get<CommandSecurityValidator>(),
  ))
  ..registerLazySingleton<IDEPrototypingAgentService>(() =>
    IDEPrototypingAgentService(
      workspaceManager: get<WorkspaceSessionManager>(),
      gitService: get<GitWorkspaceService>(),
      llmService: get<UnifiedLLMService>(),
    ));
```

### Riverpod Providers

```dart
// Workspace state providers
final activeWorkspaceProvider = StateProvider<String?>((ref) => null);

final workspaceListProvider = FutureProvider<List<WorkspaceConfig>>((ref) {
  final manager = ref.watch(workspaceSessionManagerProvider);
  return manager.listWorkspaces();
});

final workspaceFilesProvider = FutureProvider.family<List<FileNode>, String>(
  (ref, workspaceId) {
    final manager = ref.watch(workspaceSessionManagerProvider);
    return manager.getFileTree(workspaceId);
  },
);

final workspaceTerminalProvider = StreamProvider.family<String, String>(
  (ref, workspaceId) {
    final manager = ref.watch(workspaceSessionManagerProvider);
    return manager.getTerminalOutput(workspaceId);
  },
);
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] GitWorkspaceService - Clone, reset, diff operations
- [ ] WorkspaceSessionManager - Lifecycle management
- [ ] Workspace storage structure
- [ ] Security context for workspaces

### Phase 2: Terminal Integration (Week 2-3)
- [ ] Workspace-scoped terminal instances
- [ ] Command validation for workspace context
- [ ] Streaming output to UI
- [ ] Process monitoring

### Phase 3: File System UI (Week 3-4)
- [ ] File tree component
- [ ] Code editor integration (syntax highlighting)
- [ ] File operations (create, rename, delete)
- [ ] Diff viewer

### Phase 4: Agent Integration (Week 4-5)
- [ ] IDE context injection into agent
- [ ] Code analysis capabilities
- [ ] File modification via agent
- [ ] Test execution

### Phase 5: Snapshots & Polish (Week 5-6)
- [ ] Snapshot creation/restoration
- [ ] Workspace browser UI
- [ ] Performance optimization
- [ ] Error handling & recovery

---

## MCP Server Integration

The IDE Prototyping Agent can leverage MCP servers for enhanced capabilities:

### Recommended MCP Servers

1. **@anthropics/filesystem** - Safe file operations within sandbox
2. **@anthropics/memory** - Remember context across sessions
3. **brave-search** - Search for documentation/examples
4. **github** - PR creation, issue tracking from experiments

### Custom MCP Server Ideas

```typescript
// workspace-mcp-server
{
  "tools": [
    {
      "name": "workspace_clone",
      "description": "Clone a GitHub repository into a new workspace",
      "inputSchema": {
        "type": "object",
        "properties": {
          "url": { "type": "string" },
          "branch": { "type": "string" }
        },
        "required": ["url"]
      }
    },
    {
      "name": "workspace_snapshot",
      "description": "Create a snapshot of current workspace state",
      "inputSchema": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "description": { "type": "string" }
        },
        "required": ["name"]
      }
    },
    {
      "name": "workspace_reset",
      "description": "Reset workspace to clean state or snapshot",
      "inputSchema": {
        "type": "object",
        "properties": {
          "snapshotId": { "type": "string" }
        }
      }
    }
  ]
}
```

---

## Future Enhancements

1. **Collaborative Workspaces** - Share workspace state with team members
2. **Cloud Sync** - Persist workspaces across devices
3. **Template Workspaces** - Pre-configured environments (React, Flutter, etc.)
4. **Language Server Protocol** - Full IDE features (autocomplete, go-to-def)
5. **Container Isolation** - Docker-based sandboxing for complete isolation
6. **Time-Travel Debugging** - Step through code changes over time

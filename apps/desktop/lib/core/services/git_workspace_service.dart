import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/workspace.dart';

/// Service for Git operations within isolated workspaces
///
/// Handles cloning, branching, diffing, and other Git operations
/// while respecting workspace sandbox boundaries.
class GitWorkspaceService {
  /// Clone a repository into a workspace directory
  ///
  /// [url] - Repository URL (GitHub, GitLab, etc.)
  /// [targetPath] - Directory to clone into
  /// [branch] - Specific branch to clone (null = default)
  /// [shallow] - Whether to do shallow clone (--depth=1)
  Future<GitResult> cloneRepository({
    required String url,
    required String targetPath,
    String? branch,
    bool shallow = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Build git clone command
      final args = ['clone'];

      if (shallow) {
        args.addAll(['--depth', '1']);
      }

      if (branch != null) {
        args.addAll(['--branch', branch]);
      }

      args.addAll([url, targetPath]);

      debugPrint('🔄 Cloning repository: git ${args.join(' ')}');

      final result = await Process.run('git', args);

      stopwatch.stop();

      if (result.exitCode == 0) {
        debugPrint('✅ Repository cloned successfully');
        return GitResult.success(result.stdout.toString(), stopwatch.elapsed);
      } else {
        debugPrint('❌ Clone failed: ${result.stderr}');
        return GitResult.failure(
          result.stderr.toString(),
          result.exitCode,
          stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Clone error: $e');
      return GitResult.failure(e.toString(), -1, stopwatch.elapsed);
    }
  }

  /// Get repository information
  Future<RepoInfo?> getRepoInfo(String repoPath) async {
    try {
      // Get remote URL
      final remoteResult = await _runGit(repoPath, ['remote', 'get-url', 'origin']);
      if (!remoteResult.success) return null;
      final url = remoteResult.output.trim();

      // Parse owner/name from URL
      final parsed = RepoInfo.parseFromUrl(url);
      if (parsed == null) return null;

      // Get current branch
      final branchResult = await _runGit(repoPath, ['branch', '--show-current']);
      final currentBranch = branchResult.success ? branchResult.output.trim() : 'main';

      // Get HEAD commit
      final headResult = await _runGit(repoPath, ['rev-parse', 'HEAD']);
      final headCommit = headResult.success ? headResult.output.trim() : '';

      // Get default branch
      final defaultBranchResult = await _runGit(
        repoPath,
        ['symbolic-ref', 'refs/remotes/origin/HEAD', '--short'],
      );
      final defaultBranch = defaultBranchResult.success
          ? defaultBranchResult.output.trim().replaceFirst('origin/', '')
          : 'main';

      // Get list of branches
      final branchesResult = await _runGit(repoPath, ['branch', '-a']);
      final branches = branchesResult.success
          ? branchesResult.output
              .split('\n')
              .map((b) => b.trim().replaceFirst('* ', ''))
              .where((b) => b.isNotEmpty && !b.contains('->'))
              .toList()
          : <String>[];

      // Get status for uncommitted changes
      final statusResult = await _runGit(repoPath, ['status', '--porcelain']);
      final uncommittedChanges = statusResult.success
          ? statusResult.output
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .length
          : 0;

      // Check for conflicts
      final hasConflicts = statusResult.success &&
          statusResult.output.contains('UU ');

      // Detect project type
      final projectType = await _detectProjectType(repoPath);

      return parsed.copyWith(
        defaultBranch: defaultBranch,
        currentBranch: currentBranch,
        headCommit: headCommit,
        branches: branches,
        uncommittedChanges: uncommittedChanges,
        hasConflicts: hasConflicts,
        projectType: projectType,
      );
    } catch (e) {
      debugPrint('❌ Error getting repo info: $e');
      return null;
    }
  }

  /// Detect project type from files
  Future<ProjectType> _detectProjectType(String repoPath) async {
    final dir = Directory(repoPath);

    if (await File('${dir.path}/package.json').exists()) {
      return ProjectType.nodejs;
    }
    if (await File('${dir.path}/pubspec.yaml').exists()) {
      return ProjectType.flutter;
    }
    if (await File('${dir.path}/requirements.txt').exists() ||
        await File('${dir.path}/setup.py').exists() ||
        await File('${dir.path}/pyproject.toml').exists()) {
      return ProjectType.python;
    }
    if (await File('${dir.path}/Cargo.toml').exists()) {
      return ProjectType.rust;
    }
    if (await File('${dir.path}/go.mod').exists()) {
      return ProjectType.golang;
    }
    if (await File('${dir.path}/pom.xml').exists() ||
        await File('${dir.path}/build.gradle').exists()) {
      return ProjectType.java;
    }

    return ProjectType.unknown;
  }

  /// Reset workspace to clean state (discard all changes)
  Future<GitResult> resetToOrigin(String repoPath) async {
    final stopwatch = Stopwatch()..start();

    try {
      // First, reset any staged changes
      var result = await _runGit(repoPath, ['reset', '--hard', 'HEAD']);
      if (!result.success) {
        stopwatch.stop();
        return GitResult.failure(result.error ?? 'Reset failed', result.exitCode, stopwatch.elapsed);
      }

      // Clean untracked files and directories
      result = await _runGit(repoPath, ['clean', '-fd']);
      if (!result.success) {
        stopwatch.stop();
        return GitResult.failure(result.error ?? 'Clean failed', result.exitCode, stopwatch.elapsed);
      }

      stopwatch.stop();
      debugPrint('✅ Workspace reset to clean state');
      return GitResult.success('Workspace reset successfully', stopwatch.elapsed);
    } catch (e) {
      stopwatch.stop();
      return GitResult.failure(e.toString(), -1, stopwatch.elapsed);
    }
  }

  /// Get diff of all uncommitted changes
  Future<List<FileDiff>> getDiff(String repoPath) async {
    try {
      // Get status
      final statusResult = await _runGit(repoPath, ['status', '--porcelain']);
      if (!statusResult.success) return [];

      final diffs = <FileDiff>[];

      for (final line in statusResult.output.split('\n')) {
        if (line.trim().isEmpty) continue;

        final status = line.substring(0, 2);
        final path = line.substring(3).trim();

        DiffType type;
        if (status.contains('A') || status.contains('?')) {
          type = DiffType.added;
        } else if (status.contains('D')) {
          type = DiffType.deleted;
        } else if (status.contains('R')) {
          type = DiffType.renamed;
        } else {
          type = DiffType.modified;
        }

        // Get detailed diff for the file
        String? diffContent;
        int linesAdded = 0;
        int linesRemoved = 0;

        if (type != DiffType.deleted) {
          final diffResult = await _runGit(repoPath, ['diff', '--', path]);
          if (diffResult.success) {
            diffContent = diffResult.output;
            linesAdded = diffContent.split('\n').where((l) => l.startsWith('+')).length;
            linesRemoved = diffContent.split('\n').where((l) => l.startsWith('-')).length;
          }
        }

        diffs.add(FileDiff(
          path: path,
          type: type,
          linesAdded: linesAdded,
          linesRemoved: linesRemoved,
          diffContent: diffContent,
        ));
      }

      return diffs;
    } catch (e) {
      debugPrint('❌ Error getting diff: $e');
      return [];
    }
  }

  /// Create a new branch
  Future<GitResult> createBranch(String repoPath, String branchName) async {
    return _runGit(repoPath, ['checkout', '-b', branchName]);
  }

  /// Switch to a branch
  Future<GitResult> checkoutBranch(String repoPath, String branchName) async {
    return _runGit(repoPath, ['checkout', branchName]);
  }

  /// Stash current changes
  Future<GitResult> stashChanges(String repoPath, {String? message}) async {
    final args = ['stash', 'push'];
    if (message != null) {
      args.addAll(['-m', message]);
    }
    return _runGit(repoPath, args);
  }

  /// Pop stashed changes
  Future<GitResult> popStash(String repoPath) async {
    return _runGit(repoPath, ['stash', 'pop']);
  }

  /// Get file history (git log for specific file)
  Future<List<Map<String, String>>> getFileHistory(
    String repoPath,
    String filePath, {
    int limit = 20,
  }) async {
    try {
      final result = await _runGit(repoPath, [
        'log',
        '--pretty=format:%H|%an|%ae|%ad|%s',
        '--date=iso',
        '-n', '$limit',
        '--', filePath,
      ]);

      if (!result.success) return [];

      return result.output.split('\n').where((line) => line.isNotEmpty).map((line) {
        final parts = line.split('|');
        return {
          'hash': parts[0],
          'author': parts.length > 1 ? parts[1] : '',
          'email': parts.length > 2 ? parts[2] : '',
          'date': parts.length > 3 ? parts[3] : '',
          'message': parts.length > 4 ? parts[4] : '',
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting file history: $e');
      return [];
    }
  }

  /// Pull latest changes from remote
  Future<GitResult> pull(String repoPath) async {
    return _runGit(repoPath, ['pull', '--ff-only']);
  }

  /// Fetch without merging
  Future<GitResult> fetch(String repoPath) async {
    return _runGit(repoPath, ['fetch', '--all']);
  }

  /// Check if git is available on the system
  Future<bool> isGitAvailable() async {
    try {
      final result = await Process.run('git', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Run a git command in the specified directory
  Future<GitResult> _runGit(String workingDirectory, List<String> args) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: workingDirectory,
      );

      stopwatch.stop();

      if (result.exitCode == 0) {
        return GitResult.success(result.stdout.toString(), stopwatch.elapsed);
      } else {
        return GitResult.failure(
          result.stderr.toString(),
          result.exitCode,
          stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return GitResult.failure(e.toString(), -1, stopwatch.elapsed);
    }
  }
}

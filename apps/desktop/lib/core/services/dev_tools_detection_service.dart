import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

/// Service for automatically detecting development tools and configurations
class DevToolsDetectionService {
  
  /// Detects VS Code installation path
  Future<DetectionResult> detectVSCode() async {
    final List<String> vscodeLocations = [];
    
    if (Platform.isWindows) {
      vscodeLocations.addAll([
        // User installation
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\Microsoft VS Code\\Code.exe',
        '${Platform.environment['PROGRAMFILES']}\\Microsoft VS Code\\Code.exe',
        '${Platform.environment['PROGRAMFILES(X86)']}\\Microsoft VS Code\\Code.exe',
        // System installation
        'C:\\Program Files\\Microsoft VS Code\\Code.exe',
        'C:\\Program Files (x86)\\Microsoft VS Code\\Code.exe',
        // Portable version common locations
        'C:\\VSCode\\Code.exe',
        '${Platform.environment['USERPROFILE']}\\VSCode\\Code.exe',
      ]);
    } else if (Platform.isMacOS) {
      vscodeLocations.addAll([
        '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
        '/usr/local/bin/code',
        '${Platform.environment['HOME']}/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
      ]);
    } else if (Platform.isLinux) {
      vscodeLocations.addAll([
        '/usr/bin/code',
        '/usr/local/bin/code',
        '/snap/bin/code',
        '${Platform.environment['HOME']}/.local/bin/code',
      ]);
    }
    
    // Check each location
    for (final location in vscodeLocations) {
      if (location.isNotEmpty && await File(location).exists()) {
        return DetectionResult(
          found: true,
          path: location,
          confidence: DetectionConfidence.high,
          message: 'VS Code found at $location',
        );
      }
    }
    
    // Try to find it via PATH
    final pathResult = await _findInPath('code');
    if (pathResult != null) {
      return DetectionResult(
        found: true,
        path: pathResult,
        confidence: DetectionConfidence.medium,
        message: 'VS Code found in system PATH',
      );
    }
    
    return const DetectionResult(
      found: false,
      confidence: DetectionConfidence.none,
      message: 'VS Code not found. Please install it from https://code.visualstudio.com',
      suggestedAction: 'install_vscode',
    );
  }
  
  /// Detects Git installation and version
  Future<DetectionResult> detectGit() async {
    try {
      // First try to run git command
      final result = await Process.run('git', ['--version']);
      
      if (result.exitCode == 0) {
        final version = result.stdout.toString().trim();
        
        // Get Git executable path
        String? gitPath;
        if (Platform.isWindows) {
          final whereResult = await Process.run('where', ['git']);
          if (whereResult.exitCode == 0) {
            gitPath = whereResult.stdout.toString().split('\n').first.trim();
          }
        } else {
          final whichResult = await Process.run('which', ['git']);
          if (whichResult.exitCode == 0) {
            gitPath = whichResult.stdout.toString().trim();
          }
        }
        
        return DetectionResult(
          found: true,
          path: gitPath ?? 'git',
          confidence: DetectionConfidence.high,
          message: 'Git found: $version',
          metadata: {'version': version},
        );
      }
    } catch (e) {
      // Git command failed, try to find installation
    }
    
    // Try common installation paths
    final List<String> gitLocations = [];
    
    if (Platform.isWindows) {
      gitLocations.addAll([
        'C:\\Program Files\\Git\\bin\\git.exe',
        'C:\\Program Files (x86)\\Git\\bin\\git.exe',
        '${Platform.environment['PROGRAMFILES']}\\Git\\bin\\git.exe',
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\Git\\bin\\git.exe',
      ]);
    } else if (Platform.isMacOS) {
      gitLocations.addAll([
        '/usr/bin/git',
        '/usr/local/bin/git',
        '/opt/homebrew/bin/git',
      ]);
    } else if (Platform.isLinux) {
      gitLocations.addAll([
        '/usr/bin/git',
        '/usr/local/bin/git',
      ]);
    }
    
    for (final location in gitLocations) {
      if (location.isNotEmpty && await File(location).exists()) {
        return DetectionResult(
          found: true,
          path: location,
          confidence: DetectionConfidence.medium,
          message: 'Git found at $location',
        );
      }
    }
    
    return const DetectionResult(
      found: false,
      confidence: DetectionConfidence.none,
      message: 'Git not found. Please install Git from https://git-scm.com',
      suggestedAction: 'install_git',
    );
  }
  
  /// Finds Git repositories in common locations
  Future<List<GitRepository>> detectGitRepositories() async {
    final List<GitRepository> repositories = [];
    final List<String> searchPaths = [];
    
    // Define search paths based on platform
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Default';
      searchPaths.addAll([
        '$userProfile\\Documents',
        '$userProfile\\Documents\\GitHub',
        '$userProfile\\Documents\\Projects',
        '$userProfile\\Desktop',
        '$userProfile\\source',
        '$userProfile\\source\\repos',
        'C:\\Projects',
        'C:\\Dev',
        'C:\\Code',
      ]);
    } else {
      final home = Platform.environment['HOME'] ?? '/home/user';
      searchPaths.addAll([
        '$home/Documents',
        '$home/Documents/GitHub',
        '$home/Documents/Projects',
        '$home/Desktop',
        '$home/Projects',
        '$home/Code',
        '$home/Development',
        '$home/repos',
        '$home/git',
        '$home/workspace',
      ]);
    }
    
    // Search for Git repositories
    for (final searchPath in searchPaths) {
      final dir = Directory(searchPath);
      if (await dir.exists()) {
        try {
          // Search up to 2 levels deep for .git folders
          await _searchForGitRepos(dir, repositories, maxDepth: 2);
        } catch (e) {
          // Skip directories we can't access
          continue;
        }
      }
    }
    
    // Sort by last modified date (most recent first)
    repositories.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    
    return repositories;
  }
  
  /// Detects GitHub CLI installation
  Future<DetectionResult> detectGitHubCLI() async {
    try {
      final result = await Process.run('gh', ['--version']);
      
      if (result.exitCode == 0) {
        final version = result.stdout.toString().trim();
        
        // Check if authenticated
        final authResult = await Process.run('gh', ['auth', 'status']);
        final isAuthenticated = authResult.exitCode == 0;
        
        return DetectionResult(
          found: true,
          path: 'gh',
          confidence: DetectionConfidence.high,
          message: isAuthenticated 
            ? 'GitHub CLI found and authenticated' 
            : 'GitHub CLI found but not authenticated',
          metadata: {
            'version': version,
            'authenticated': isAuthenticated,
          },
        );
      }
    } catch (e) {
      // gh command not found
    }
    
    return const DetectionResult(
      found: false,
      confidence: DetectionConfidence.none,
      message: 'GitHub CLI not found. Install it for better GitHub integration',
      suggestedAction: 'install_gh',
    );
  }
  
  /// Detects the user's preferred workspace directory
  Future<String> detectWorkspaceDirectory() async {
    final candidates = <String, int>{};
    
    // Common workspace locations
    final List<String> workspacePaths;
    
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Default';
      workspacePaths = [
        '$userProfile\\Documents\\Projects',
        '$userProfile\\Documents\\GitHub',
        '$userProfile\\Documents',
        '$userProfile\\Desktop\\Projects',
        '$userProfile\\source\\repos',
        'C:\\Projects',
      ];
    } else {
      final home = Platform.environment['HOME'] ?? '/home/user';
      workspacePaths = [
        '$home/Projects',
        '$home/Documents/Projects',
        '$home/workspace',
        '$home/Development',
        '$home/Code',
        '$home/Documents',
      ];
    }
    
    // Score each path based on existence and content
    for (final wsPath in workspacePaths) {
      final dir = Directory(wsPath);
      if (await dir.exists()) {
        int score = 10; // Base score for existing
        
        try {
          // Higher score if it contains subdirectories
          final contents = await dir.list().toList();
          final subDirs = contents.whereType<Directory>().length;
          score += subDirs * 2;
          
          // Bonus if it contains git repos
          for (final entity in contents) {
            if (entity is Directory) {
              final gitDir = Directory(path.join(entity.path, '.git'));
              if (await gitDir.exists()) score += 5;
            }
          }
          
          candidates[wsPath] = score;
        } catch (e) {
          candidates[wsPath] = score;
        }
      }
    }
    
    // Return the highest scoring path, or create a default
    if (candidates.isEmpty) {
      final defaultPath = Platform.isWindows
        ? '${Platform.environment['USERPROFILE']}\\Documents\\Projects'
        : '${Platform.environment['HOME']}/Projects';
      
      // Create the directory if it doesn't exist
      await Directory(defaultPath).create(recursive: true);
      return defaultPath;
    }
    
    final sorted = candidates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.first.key;
  }
  
  /// Performs complete auto-detection for coder setup
  Future<CoderSetupDetection> detectCoderSetup() async {
    final vscode = await detectVSCode();
    final git = await detectGit();
    final github = await detectGitHubCLI();
    final repos = await detectGitRepositories();
    final workspace = await detectWorkspaceDirectory();
    
    // Calculate overall confidence
    int confidenceScore = 0;
    if (vscode.found) confidenceScore += 30;
    if (git.found) confidenceScore += 30;
    if (github.found) confidenceScore += 20;
    if (repos.isNotEmpty) confidenceScore += 20;
    
    final overallConfidence = confidenceScore >= 80 
      ? DetectionConfidence.high
      : confidenceScore >= 50 
        ? DetectionConfidence.medium 
        : DetectionConfidence.low;
    
    return CoderSetupDetection(
      vscode: vscode,
      git: git,
      github: github,
      repositories: repos,
      workspaceDirectory: workspace,
      overallConfidence: overallConfidence,
      readyToUse: vscode.found && git.found,
    );
  }
  
  // Helper methods
  
  Future<String?> _findInPath(String executable) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('where', [executable]);
        if (result.exitCode == 0) {
          return result.stdout.toString().split('\n').first.trim();
        }
      } else {
        final result = await Process.run('which', [executable]);
        if (result.exitCode == 0) {
          return result.stdout.toString().trim();
        }
      }
    } catch (e) {
      // Command failed
    }
    return null;
  }
  
  Future<void> _searchForGitRepos(
    Directory dir, 
    List<GitRepository> repos,
    {int maxDepth = 2, int currentDepth = 0}
  ) async {
    if (currentDepth > maxDepth) return;
    
    try {
      final gitDir = Directory(path.join(dir.path, '.git'));
      if (await gitDir.exists()) {
        // This is a git repository
        final repo = await _analyzeGitRepo(dir);
        if (repo != null) repos.add(repo);
        return; // Don't search inside git repos
      }
      
      // Search subdirectories
      if (currentDepth < maxDepth) {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is Directory && !path.basename(entity.path).startsWith('.')) {
            await _searchForGitRepos(entity, repos, 
              maxDepth: maxDepth, 
              currentDepth: currentDepth + 1
            );
          }
        }
      }
    } catch (e) {
      // Skip directories we can't access
    }
  }
  
  Future<GitRepository?> _analyzeGitRepo(Directory dir) async {
    try {
      // Get repository info
      final name = path.basename(dir.path);
      
      // Get last commit date
      final logResult = await Process.run(
        'git', 
        ['log', '-1', '--format=%ci'],
        workingDirectory: dir.path,
      );
      
      DateTime lastModified = DateTime.now();
      if (logResult.exitCode == 0) {
        try {
          lastModified = DateTime.parse(logResult.stdout.toString().trim().split(' ').first);
        } catch (e) {
          // Use file modification date as fallback
          final stat = await dir.stat();
          lastModified = stat.modified;
        }
      }
      
      // Get current branch
      final branchResult = await Process.run(
        'git',
        ['branch', '--show-current'],
        workingDirectory: dir.path,
      );
      
      final branch = branchResult.exitCode == 0 
        ? branchResult.stdout.toString().trim() 
        : 'unknown';
      
      // Get remote URL
      final remoteResult = await Process.run(
        'git',
        ['remote', 'get-url', 'origin'],
        workingDirectory: dir.path,
      );
      
      String? remoteUrl;
      if (remoteResult.exitCode == 0) {
        remoteUrl = remoteResult.stdout.toString().trim();
      }
      
      return GitRepository(
        name: name,
        path: dir.path,
        branch: branch,
        remoteUrl: remoteUrl,
        lastModified: lastModified,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Result of a detection attempt
class DetectionResult {
  final bool found;
  final String? path;
  final DetectionConfidence confidence;
  final String message;
  final String? suggestedAction;
  final Map<String, dynamic>? metadata;
  
  const DetectionResult({
    required this.found,
    this.path,
    required this.confidence,
    required this.message,
    this.suggestedAction,
    this.metadata,
  });
}

/// Git repository information
class GitRepository {
  final String name;
  final String path;
  final String branch;
  final String? remoteUrl;
  final DateTime lastModified;
  
  const GitRepository({
    required this.name,
    required this.path,
    required this.branch,
    this.remoteUrl,
    required this.lastModified,
  });
  
  bool get isGitHub => remoteUrl?.contains('github.com') ?? false;
  bool get isLocal => remoteUrl == null;
}

/// Complete coder setup detection results
class CoderSetupDetection {
  final DetectionResult vscode;
  final DetectionResult git;
  final DetectionResult github;
  final List<GitRepository> repositories;
  final String workspaceDirectory;
  final DetectionConfidence overallConfidence;
  final bool readyToUse;
  
  const CoderSetupDetection({
    required this.vscode,
    required this.git,
    required this.github,
    required this.repositories,
    required this.workspaceDirectory,
    required this.overallConfidence,
    required this.readyToUse,
  });
}

/// Detection confidence levels
enum DetectionConfidence {
  none,
  low,
  medium,
  high,
}

/// Provider for the detection service
final devToolsDetectionServiceProvider = Provider<DevToolsDetectionService>((ref) {
  return DevToolsDetectionService();
});
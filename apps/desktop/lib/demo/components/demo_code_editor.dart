import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/design_system/design_system.dart';

/// Demo code editor with simulated MCP git integration
class DemoCodeEditor extends StatefulWidget {
  final String? initialFilePath;
  final VoidCallback? onClose;
  final String? actionContext;

  const DemoCodeEditor({
    super.key,
    this.initialFilePath,
    this.onClose,
    this.actionContext,
  });

  @override
  State<DemoCodeEditor> createState() => _DemoCodeEditorState();
}

class _DemoCodeEditorState extends State<DemoCodeEditor> 
    with TickerProviderStateMixin {
  // File system simulation
  final Map<String, FileNode> _fileTree = {
    'src': FileNode(
      name: 'src',
      isDirectory: true,
      children: {
        'components': FileNode(
          name: 'components',
          isDirectory: true,
          children: {
            'Dashboard.tsx': FileNode(
              name: 'Dashboard.tsx',
              content: _dashboardCode,
              language: 'typescript',
            ),
            'TaskCard.tsx': FileNode(
              name: 'TaskCard.tsx',
              content: _taskCardCode,
              language: 'typescript',
            ),
          },
        ),
        'api': FileNode(
          name: 'api',
          isDirectory: true,
          children: {
            'client.ts': FileNode(
              name: 'client.ts',
              content: _apiClientCode,
              language: 'typescript',
            ),
          },
        ),
        'App.tsx': FileNode(
          name: 'App.tsx',
          content: _appCode,
          language: 'typescript',
        ),
      },
    ),
    'package.json': FileNode(
      name: 'package.json',
      content: _packageJsonCode,
      language: 'json',
    ),
    'README.md': FileNode(
      name: 'README.md',
      content: _readmeCode,
      language: 'markdown',
    ),
  };

  String _currentFilePath = 'src/App.tsx';
  late String _currentContent;
  final TextEditingController _codeController = TextEditingController();
  final List<String> _gitLog = [];
  bool _hasChanges = false;
  bool _showGitPanel = false;
  bool _showCommandPalette = false;
  final List<String> _openFiles = [];
  bool _showPreview = false;
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _previewRefreshController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFile(widget.initialFilePath ?? _currentFilePath);
    _simulateGitStatus();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    
    _previewRefreshController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _previewRefreshController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _loadFile(String path) {
    final file = _getFileAtPath(path);
    if (file != null && !file.isDirectory) {
      setState(() {
        _currentFilePath = path;
        _currentContent = file.content ?? '';
        _codeController.text = _currentContent;
        if (!_openFiles.contains(path)) {
          _openFiles.add(path);
        }
      });
    }
  }

  FileNode? _getFileAtPath(String path) {
    final parts = path.split('/');
    Map<String, FileNode> current = _fileTree;
    FileNode? result;
    
    for (final part in parts) {
      if (current.containsKey(part)) {
        result = current[part];
        if (result!.isDirectory && result.children != null) {
          current = result.children!;
        }
      } else {
        return null;
      }
    }
    
    return result;
  }

  void _simulateGitStatus() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _gitLog.add('[git] Detected changes in 2 files');
          _gitLog.add('[git] src/App.tsx (modified)');
          _gitLog.add('[git] src/components/Dashboard.tsx (modified)');
        });
      }
    });
  }

  void _executeGitCommand(String command) {
    setState(() {
      _gitLog.add('> $command');
      
      switch (command) {
        case 'git status':
          _gitLog.addAll([
            'On branch feature/ai-integration',
            'Changes not staged for commit:',
            '  modified: src/App.tsx',
            '  modified: src/components/Dashboard.tsx',
          ]);
          break;
        case 'git add .':
          _gitLog.add('Added 2 files to staging area');
          break;
        case 'git commit -m "Add AI-powered task management"':
          _gitLog.addAll([
            '[feature/ai-integration abc1234] Add AI-powered task management',
            '2 files changed, 45 insertions(+), 12 deletions(-)',
          ]);
          _hasChanges = false;
          break;
        case 'git push':
          _gitLog.addAll([
            'Counting objects: 100% (12/12), done.',
            'Writing objects: 100% (12/12), 2.34 KiB | 2.34 MiB/s, done.',
            'To github.com:asmbli/project-dashboard.git',
            '   def5678..abc1234  feature/ai-integration -> feature/ai-integration',
          ]);
          break;
        default:
          _gitLog.add('Command not recognized: $command');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        ),
        child: Column(
          children: [
            // Editor header
            _buildEditorHeader(colors),
            
            // Tab bar
            _buildTabBar(colors),
            
            // Main editor area
            Expanded(
              child: Row(
                children: [
                  // File tree sidebar
                  _buildFileTree(colors),
                  
                  // Code editor or preview
                  Expanded(
                    child: _showPreview
                        ? _buildPreview(colors)
                        : _buildCodeEditor(colors),
                  ),
                  
                  // Git panel
                  if (_showGitPanel)
                    _buildGitPanel(colors),
                ],
              ),
            ),
            
            // Status bar
            _buildStatusBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(BorderRadiusTokens.lg),
          topRight: Radius.circular(BorderRadiusTokens.lg),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.code, color: colors.primary, size: 20),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            'AI Code Editor',
            style: TextStyles.bodyLarge.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.actionContext != null) ...[
            const SizedBox(width: SpacingTokens.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(color: colors.accent, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: colors.accent,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    'Selected: ${widget.actionContext}',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          
          // MCP integration indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.sm,
              vertical: SpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: colors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'MCP Git Connected',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.success,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: SpacingTokens.md),
          
          // Preview toggle
          IconButton(
            onPressed: () {
              setState(() => _showPreview = !_showPreview);
              if (_showPreview) {
                _previewRefreshController.forward(from: 0);
              }
            },
            icon: Icon(
              Icons.preview,
              color: _showPreview ? colors.primary : colors.onSurfaceVariant,
              size: 20,
            ),
            tooltip: 'Toggle Preview',
          ),
          
          // Git panel toggle
          IconButton(
            onPressed: () {
              setState(() => _showGitPanel = !_showGitPanel);
            },
            icon: Icon(
              Icons.source,
              color: _showGitPanel ? colors.primary : colors.onSurfaceVariant,
              size: 20,
            ),
            tooltip: 'Toggle Git Panel',
          ),
          
          if (widget.onClose != null) ...[
            IconButton(
              onPressed: widget.onClose,
              icon: Icon(Icons.close, color: colors.onSurfaceVariant, size: 20),
              tooltip: 'Close Editor',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeColors colors) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          ..._openFiles.map((path) {
            final isActive = path == _currentFilePath;
            final fileName = path.split('/').last;
            
            return Container(
              decoration: BoxDecoration(
                color: isActive ? colors.surface : null,
                border: isActive
                    ? Border(
                        bottom: BorderSide(color: colors.primary, width: 2),
                      )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _loadFile(path),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                      vertical: SpacingTokens.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFileIcon(fileName),
                          size: 14,
                          color: isActive ? colors.primary : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: SpacingTokens.xs),
                        Text(
                          fileName,
                          style: TextStyles.bodySmall.copyWith(
                            color: isActive ? colors.onSurface : colors.onSurfaceVariant,
                          ),
                        ),
                        if (_hasChanges && isActive) ...[
                          const SizedBox(width: SpacingTokens.xs),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFileTree(ThemeColors colors) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.3),
        border: Border(right: BorderSide(color: colors.border.withOpacity(0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            child: Text(
              'PROJECT FILES',
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
              children: _buildFileTreeNodes(_fileTree, 0, colors),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFileTreeNodes(
    Map<String, FileNode> nodes,
    int depth,
    ThemeColors colors,
  ) {
    final widgets = <Widget>[];
    
    for (final entry in nodes.entries) {
      final node = entry.value;
      final indent = depth * SpacingTokens.md;
      
      widgets.add(
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: node.isDirectory
                ? null
                : () => _loadFile(_getNodePath(node, nodes)),
            child: Container(
              padding: EdgeInsets.only(
                left: indent + SpacingTokens.sm,
                right: SpacingTokens.sm,
                top: SpacingTokens.xs,
                bottom: SpacingTokens.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    node.isDirectory
                        ? Icons.folder
                        : _getFileIcon(node.name),
                    size: 16,
                    color: node.isDirectory
                        ? colors.warning
                        : colors.primary.withOpacity(0.8),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    node.name,
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      if (node.isDirectory && node.children != null) {
        widgets.addAll(_buildFileTreeNodes(node.children!, depth + 1, colors));
      }
    }
    
    return widgets;
  }

  String _getNodePath(FileNode node, Map<String, FileNode> parent) {
    // Simplified path resolution
    if (parent == _fileTree) {
      return node.name;
    }
    return _currentFilePath; // In real implementation, would traverse tree
  }

  Widget _buildCodeEditor(ThemeColors colors) {
    return Container(
      color: colors.background,
      child: Column(
        children: [
          // Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.3),
              border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                ..._currentFilePath.split('/').map((part) => Row(
                  children: [
                    Text(
                      part,
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (part != _currentFilePath.split('/').last)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
                        child: Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: colors.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                  ],
                )),
              ],
            ),
          ),
          
          // Code area
          Expanded(
            child: Stack(
              children: [
                // Line numbers and code
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line numbers
                    Container(
                      width: 50,
                      padding: const EdgeInsets.only(
                        right: SpacingTokens.sm,
                        top: SpacingTokens.md,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(
                          _codeController.text.split('\n').length,
                          (index) => Container(
                            height: 20,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${index + 1}',
                              style: TextStyles.bodySmall.copyWith(
                                color: colors.onSurfaceVariant.withOpacity(0.5),
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Code editor
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        maxLines: null,
                        style: TextStyles.bodyMedium.copyWith(
                          color: colors.onSurface,
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(SpacingTokens.md),
                        ),
                        onChanged: (value) {
                          if (!_hasChanges && value != _currentContent) {
                            setState(() => _hasChanges = true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                // AI suggestion overlay (demo)
                if (_showAISuggestion)
                  Positioned(
                    top: 100,
                    left: 60,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(SpacingTokens.md),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                        border: Border.all(color: colors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: colors.primary,
                              ),
                              const SizedBox(width: SpacingTokens.xs),
                              Text(
                                'AI Suggestion',
                                style: TextStyles.bodySmall.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Tab to accept',
                                style: TextStyles.bodySmall.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SpacingTokens.sm),
                          Container(
                            padding: const EdgeInsets.all(SpacingTokens.sm),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                            ),
                            child: Text(
                              '// Add error handling for API calls\ntry {\n  const response = await fetchTasks();\n  setTasks(response.data);\n} catch (error) {\n  console.error("Failed to fetch tasks:", error);\n  setError(error.message);\n}',
                              style: TextStyles.bodySmall.copyWith(
                                color: colors.onSurface,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _showAISuggestion => _currentFilePath.endsWith('.tsx') && _hasChanges;

  Widget _buildGitPanel(ThemeColors colors) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Git panel header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Icon(Icons.source, color: colors.primary, size: 20),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'Git Integration',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Quick actions
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            child: Wrap(
              spacing: SpacingTokens.sm,
              children: [
                _buildGitAction('Status', Icons.info_outline, () {
                  _executeGitCommand('git status');
                }, colors),
                _buildGitAction('Add All', Icons.add, () {
                  _executeGitCommand('git add .');
                }, colors),
                _buildGitAction('Commit', Icons.check, () {
                  _executeGitCommand('git commit -m "Add AI-powered task management"');
                }, colors),
                _buildGitAction('Push', Icons.upload, () {
                  _executeGitCommand('git push');
                }, colors),
              ],
            ),
          ),
          
          // Git log
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(SpacingTokens.sm),
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              ),
              child: ListView.builder(
                itemCount: _gitLog.length,
                itemBuilder: (context, index) {
                  final log = _gitLog[index];
                  final isCommand = log.startsWith('>');
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                    child: Text(
                      log,
                      style: TextStyles.bodySmall.copyWith(
                        color: isCommand ? colors.primary : colors.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGitAction(
    String label,
    IconData icon,
    VoidCallback onTap,
    ThemeColors colors,
  ) {
    return Material(
      color: colors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm,
            vertical: SpacingTokens.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.primary),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                label,
                style: TextStyles.bodySmall.copyWith(
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(ThemeColors colors) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.8),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Current branch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree, size: 12, color: colors.onSurfaceVariant),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                'feature/ai-integration',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: SpacingTokens.lg),
          
          // Language mode
          Text(
            'TypeScript React',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          
          const Spacer(),
          
          // AI status
          if (_showAISuggestion)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: colors.primary),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'AI Ready',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.primary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: SpacingTokens.lg),
              ],
            ),
          
          // Cursor position
          Text(
            'Ln 12, Col 24',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.tsx') || fileName.endsWith('.ts')) {
      return Icons.code;
    } else if (fileName.endsWith('.json')) {
      return Icons.settings;
    } else if (fileName.endsWith('.md')) {
      return Icons.description;
    } else if (fileName.endsWith('.css') || fileName.endsWith('.scss')) {
      return Icons.style;
    }
    return Icons.insert_drive_file;
  }

  Widget _buildPreview(ThemeColors colors) {
    return Container(
      color: colors.surface,
      child: Column(
        children: [
          // Browser-like header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                // Browser controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: colors.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(width: SpacingTokens.xs),
                    Icon(Icons.arrow_forward, size: 16, color: colors.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(width: SpacingTokens.sm),
                    AnimatedBuilder(
                      animation: _previewRefreshController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _previewRefreshController.value * 2 * 3.14159,
                          child: Icon(
                            Icons.refresh,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(width: SpacingTokens.md),
                
                // URL bar
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 12, color: colors.onSurfaceVariant),
                        const SizedBox(width: SpacingTokens.xs),
                        Text(
                          'localhost:3000',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: SpacingTokens.md),
                
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        'Live',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.success,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Preview content
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: _buildPreviewContent(colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Text(
                  'AI-Powered Task Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Task grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              _buildTaskPreviewCard('Deploy AI Model', 'In Progress', Colors.blue, 75),
              _buildTaskPreviewCard('Code Review', 'Completed', Colors.green, 100),
              _buildTaskPreviewCard('UI Design', 'In Review', Colors.orange, 90),
              _buildTaskPreviewCard('Database Migration', 'Pending', Colors.grey, 0),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // AI Suggestions section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFE1E8ED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF4ECDC4), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSuggestionItem('Prioritize "Deploy AI Model" - blocking 3 other tasks'),
                _buildSuggestionItem('Schedule code review for tomorrow morning'),
                _buildSuggestionItem('Assign UI design to Sarah - best availability'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPreviewCard(String title, String status, Color color, int progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE1E8ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (progress > 0)
                Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          if (progress > 0)
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE1E8ED),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFF4ECDC4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sample code content
  static const _dashboardCode = '''import React from 'react';
import { TaskCard } from './TaskCard';
import { useAIAssistant } from '../hooks/useAIAssistant';

export const Dashboard: React.FC = () => {
  const [tasks, setTasks] = useState([]);
  const { suggestions, analyze } = useAIAssistant();
  
  useEffect(() => {
    fetchTasks();
  }, []);
  
  const fetchTasks = async () => {
    const response = await fetch('/api/tasks');
    const data = await response.json();
    setTasks(data);
    analyze(data);
  };
  
  return (
    <div className="dashboard">
      <h1>AI-Powered Task Management</h1>
      <div className="task-grid">
        {tasks.map(task => (
          <TaskCard key={task.id} task={task} />
        ))}
      </div>
      {suggestions && (
        <div className="ai-suggestions">
          <h3>AI Recommendations</h3>
          {suggestions.map(s => <p key={s.id}>{s.text}</p>)}
        </div>
      )}
    </div>
  );
};''';

  static const _taskCardCode = '''import React from 'react';

interface TaskCardProps {
  task: {
    id: string;
    title: string;
    status: string;
    priority: number;
  };
}

export const TaskCard: React.FC<TaskCardProps> = ({ task }) => {
  return (
    <div className="task-card">
      <h3>{task.title}</h3>
      <span className={`status \${task.status}`}>\{task.status\}</span>
      <span className="priority">Priority: {task.priority}</span>
    </div>
  );
};''';

  static const _apiClientCode = '''export class ApiClient {
  private baseUrl = process.env.REACT_APP_API_URL;
  
  async fetchTasks() {
    const response = await fetch(`\${this.baseUrl}/tasks`);
    if (!response.ok) {
      throw new Error('Failed to fetch tasks');
    }
    return response.json();
  }
  
  async updateTask(id: string, updates: Partial<Task>) {
    const response = await fetch(`\${this.baseUrl}/tasks/\${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
    return response.json();
  }
}''';

  static const _appCode = '''import React from 'react';
import { Dashboard } from './components/Dashboard';
import './App.css';

function App() {
  return (
    <div className="App">
      <Dashboard />
    </div>
  );
}

export default App;''';

  static const _packageJsonCode = '''{
  "name": "ai-task-manager",
  "version": "1.0.0",
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.0.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test"
  }
}''';

  static const _readmeCode = '''# AI Task Manager

An intelligent task management system powered by AI.

## Features
- Smart task prioritization
- AI-driven insights
- Real-time collaboration
- Automated workflows

## Getting Started
\`\`\`bash
npm install
npm start
\`\`\`
''';
}

class FileNode {
  final String name;
  final bool isDirectory;
  final String? content;
  final String? language;
  final Map<String, FileNode>? children;

  const FileNode({
    required this.name,
    this.isDirectory = false,
    this.content,
    this.language,
    this.children,
  });
}
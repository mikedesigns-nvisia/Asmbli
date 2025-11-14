import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/components/app_navigation_bar.dart';
import '../../../core/constants/routes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/canvas_storage_service.dart';
import '../../agents/presentation/widgets/design_agent_sidebar.dart';
import 'package:agent_engine_core/models/agent.dart';

/// Canvas Library screen for browsing saved canvases and starting new design sessions
class CanvasLibraryScreen extends ConsumerStatefulWidget {
  const CanvasLibraryScreen({super.key});

  @override
  ConsumerState<CanvasLibraryScreen> createState() => _CanvasLibraryScreenState();
}

class _CanvasLibraryScreenState extends ConsumerState<CanvasLibraryScreen> {
  late CanvasStorageService _canvasStorage;
  List<Map<String, dynamic>> _savedCanvases = [];
  List<Map<String, dynamic>> _agentActivities = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'name', 'size'
  bool _isGridView = true;
  String _activeTab = 'recent'; // 'recent', 'chat', 'saved', 'templates'
  late Agent _designAgent;

  @override
  void initState() {
    super.initState();
    _canvasStorage = ServiceLocator.instance.get<CanvasStorageService>();
    _createDesignAgent();
    _loadSavedCanvases();
    _loadAgentActivities();
  }

  Future<void> _loadSavedCanvases() async {
    setState(() => _isLoading = true);
    try {
      final canvases = await _canvasStorage.listSavedCanvases();
      setState(() {
        _savedCanvases = canvases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load canvases: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }
  
  Future<void> _loadAgentActivities() async {
    try {
      final activities = _canvasStorage.getCanvasActivities();
      setState(() {
        _agentActivities = activities;
      });
    } catch (e) {
      debugPrint('Failed to load agent activities: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredCanvases {
    var filtered = _savedCanvases.where((canvas) {
      if (_searchQuery.isEmpty) return true;
      final name = (canvas['name'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort canvases
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
        break;
      case 'date':
      default:
        // Already sorted by date in the storage service
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colors.backgroundGradientStart,
              colors.backgroundGradientMiddle,
              colors.backgroundGradientEnd,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Navigation bar
              const AppNavigationBar(currentRoute: AppRoutes.canvasLibrary),
              
              // Header
              _buildHeader(colors),
              
              // Search and filters
              _buildSearchAndFilters(colors),
              
              // Tabs
              _buildTabSelector(colors),
              
              // Content
              Expanded(
                child: _isLoading 
                  ? _buildLoadingState(colors)
                  : _buildTabContent(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canvas Library',
                  style: TextStyles.pageTitle.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  'Recent agent creations, saved canvases, and design templates',
                  style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          // Quick actions
          Row(
            children: [
              AsmblButton.secondary(
                text: 'Import Canvas',
                icon: Icons.file_upload,
                size: AsmblButtonSize.small,
                onPressed: _importCanvas,
              ),
              const SizedBox(width: SpacingTokens.sm),
              AsmblButton.primary(
                text: 'New Canvas',
                icon: Icons.add,
                size: AsmblButtonSize.small,
                onPressed: _createNewCanvas,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search canvases...',
                prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colors.onSurfaceVariant),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                  borderSide: BorderSide(color: colors.border),
                ),
                filled: true,
                fillColor: colors.surface,
              ),
            ),
          ),
          
          const SizedBox(width: SpacingTokens.md),
          
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(color: colors.border),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              isDense: true,
              underline: const SizedBox(),
              icon: Icon(Icons.sort, size: 16, color: colors.onSurfaceVariant),
              style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
              items: const [
                DropdownMenuItem(value: 'date', child: Text('Date')),
                DropdownMenuItem(value: 'name', child: Text('Name')),
              ],
              onChanged: (value) => setState(() => _sortBy = value!),
            ),
          ),
          
          const SizedBox(width: SpacingTokens.sm),
          
          // View toggle
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: colors.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colors.surface,
              side: BorderSide(color: colors.border),
            ),
          ),
          
          const SizedBox(width: SpacingTokens.sm),
          
          // Refresh button
          IconButton(
            onPressed: _loadSavedCanvases,
            icon: Icon(Icons.refresh, color: colors.primary),
            style: IconButton.styleFrom(
              backgroundColor: colors.surface,
              side: BorderSide(color: colors.border),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Loading canvases...',
            style: TextStyles.bodyLarge.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
            ),
            child: Icon(
              Icons.palette_outlined,
              size: 64,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text(
            'No canvases yet',
            style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Create your first visual design canvas to get started',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.xl),
          AsmblButton.primary(
            text: 'Create First Canvas',
            icon: Icons.add,
            onPressed: _createNewCanvas,
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasGrid(ThemeColors colors) {
    final filtered = _filteredCanvases;
    
    if (_isGridView) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: SpacingTokens.lg,
            mainAxisSpacing: SpacingTokens.lg,
            childAspectRatio: 1.2,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildCanvasCard(filtered[index], colors),
        ),
      );
    } else {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const SizedBox(height: SpacingTokens.md),
        itemBuilder: (context, index) => _buildCanvasListItem(filtered[index], colors),
      );
    }
  }

  Widget _buildCanvasCard(Map<String, dynamic> canvas, ThemeColors colors) {
    final name = canvas['name'] as String? ?? 'Untitled Canvas';
    final savedAt = DateTime.parse(canvas['savedAt'] as String);
    final id = canvas['id'] as String;

    return AsmblCard(
      onTap: () => _openCanvas(id),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Canvas thumbnail/preview
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.border),
                ),
                child: Center(
                  child: Icon(
                    Icons.palette,
                    size: 48,
                    color: colors.primary.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: SpacingTokens.sm),
            
            // Canvas info
            Text(
              name,
              style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              _formatDate(savedAt),
              style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
            
            const SizedBox(height: SpacingTokens.sm),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: AsmblButton.secondary(
                    text: 'Open',
                    size: AsmblButtonSize.small,
                    onPressed: () => _openCanvas(id),
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16, color: colors.onSurfaceVariant),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.content_copy, size: 16, color: colors.onSurfaceVariant),
                          const SizedBox(width: SpacingTokens.sm),
                          const Text('Duplicate'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.file_download, size: 16, color: colors.onSurfaceVariant),
                          const SizedBox(width: SpacingTokens.sm),
                          const Text('Export'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: colors.error),
                          const SizedBox(width: SpacingTokens.sm),
                          Text('Delete', style: TextStyle(color: colors.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (action) => _handleCanvasAction(action, canvas),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasListItem(Map<String, dynamic> canvas, ThemeColors colors) {
    final name = canvas['name'] as String? ?? 'Untitled Canvas';
    final savedAt = DateTime.parse(canvas['savedAt'] as String);
    final id = canvas['id'] as String;

    return AsmblCard(
      onTap: () => _openCanvas(id),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: Icon(
                  Icons.palette,
                  color: colors.primary.withOpacity(0.5),
                ),
              ),
            ),
            
            const SizedBox(width: SpacingTokens.md),
            
            // Canvas info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    'Last modified: ${_formatDate(savedAt)}',
                    style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            
            // Actions
            AsmblButton.secondary(
              text: 'Open',
              size: AsmblButtonSize.small,
              onPressed: () => _openCanvas(id),
            ),
            const SizedBox(width: SpacingTokens.sm),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.content_copy, size: 16, color: colors.onSurfaceVariant),
                      const SizedBox(width: SpacingTokens.sm),
                      const Text('Duplicate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download, size: 16, color: colors.onSurfaceVariant),
                      const SizedBox(width: SpacingTokens.sm),
                      const Text('Export'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: colors.error),
                      const SizedBox(width: SpacingTokens.sm),
                      Text('Delete', style: TextStyle(color: colors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (action) => _handleCanvasAction(action, canvas),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _createNewCanvas() {
    // Navigate to the canvas screen to create a new canvas
    context.go(AppRoutes.canvas);
  }

  void _openCanvas(String canvasId) {
    // Navigate to the canvas screen with the specific canvas ID
    context.go('${AppRoutes.canvas}?id=$canvasId');
  }

  Future<void> _importCanvas() async {
    // TODO: Implement file picker for canvas import
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Canvas import feature coming soon!'),
        backgroundColor: ThemeColors(context).primary,
      ),
    );
  }

  void _handleCanvasAction(String action, Map<String, dynamic> canvas) {
    final id = canvas['id'] as String;
    final name = canvas['name'] as String? ?? 'Untitled Canvas';

    switch (action) {
      case 'duplicate':
        _duplicateCanvas(canvas);
        break;
      case 'export':
        _exportCanvas(canvas);
        break;
      case 'delete':
        _showDeleteConfirmation(id, name);
        break;
    }
  }

  Future<void> _duplicateCanvas(Map<String, dynamic> canvas) async {
    try {
      final originalId = canvas['id'] as String;
      final state = await _canvasStorage.loadCanvasState(originalId);
      
      if (state != null) {
        final newId = DateTime.now().millisecondsSinceEpoch.toString();
        final newName = '${canvas['name'] ?? 'Untitled Canvas'} (Copy)';
        
        final newState = Map<String, dynamic>.from(state);
        newState['name'] = newName;
        
        await _canvasStorage.saveCanvasState(newId, newState);
        await _loadSavedCanvases();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Canvas duplicated: $newName'),
              backgroundColor: ThemeColors(context).success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate canvas: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  Future<void> _exportCanvas(Map<String, dynamic> canvas) async {
    try {
      final id = canvas['id'] as String;
      final state = await _canvasStorage.loadCanvasState(id);
      
      if (state != null) {
        final exportPath = await _canvasStorage.exportCanvas(id, state);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Canvas exported to: ${File(exportPath).parent.path}'),
              backgroundColor: ThemeColors(context).success,
              action: SnackBarAction(
                label: 'Open Folder',
                onPressed: () {
                  // TODO: Open file location
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export canvas: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String canvasId, String canvasName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Canvas'),
        content: Text('Are you sure you want to delete "$canvasName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCanvas(canvasId);
            },
            style: TextButton.styleFrom(foregroundColor: ThemeColors(context).error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCanvas(String canvasId) async {
    try {
      await _canvasStorage.deleteCanvas(canvasId);
      await _loadSavedCanvases();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Canvas deleted successfully'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete canvas: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }
  
  void _createDesignAgent() {
    // Create a canvas-focused design agent
    _designAgent = Agent(
      id: 'canvas_design_agent',
      name: 'Canvas Design Agent',
      description: 'AI agent specialized in creating visual designs and canvas elements',
      instructions: 'You are a design agent that creates visual elements on canvas. You can create shapes, wireframes, templates, and layouts. Always be helpful and creative.',
      configuration: {
        'modelConfiguration': {
          'primaryModelId': 'local_llama3.1_8b',
        },
        'capabilities': ['canvas_design', 'tool_calling', 'visual_creation'],
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  Widget _buildTabSelector(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          _buildTabButton('recent', '🕰️ Recent Items', colors),
          const SizedBox(width: SpacingTokens.sm),
          _buildTabButton('chat', '🤖 Design Agent', colors),
          const SizedBox(width: SpacingTokens.sm),
          _buildTabButton('saved', '💾 Saved Canvases', colors),
          const SizedBox(width: SpacingTokens.sm),
          _buildTabButton('templates', '🎨 Templates', colors),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(String tab, String label, ThemeColors colors) {
    final isActive = _activeTab == tab;
    return Material(
      color: isActive ? colors.primary.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => setState(() => _activeTab = tab),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          child: Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: isActive ? colors.primary : colors.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabContent(ThemeColors colors) {
    switch (_activeTab) {
      case 'recent':
        return _buildRecentAgentItems(colors);
      case 'chat':
        return _buildCanvasAgentChat(colors);
      case 'saved':
        return _savedCanvases.isEmpty ? _buildEmptyState(colors) : _buildCanvasGrid(colors);
      case 'templates':
        return _buildTemplatesGrid(colors);
      default:
        return _buildRecentAgentItems(colors);
    }
  }
  
  Widget _buildRecentAgentItems(ThemeColors colors) {
    if (_agentActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: SpacingTokens.lg),
            Text(
              'No Agent Activities Yet',
              style: TextStyles.sectionTitle.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'Start creating with the design agent to see recent items here',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      itemCount: _agentActivities.length,
      itemBuilder: (context, index) {
        final activity = _agentActivities[index];
        return _buildAgentActivityCard(activity, colors);
      },
    );
  }
  
  Widget _buildAgentActivityCard(Map<String, dynamic> activity, ThemeColors colors) {
    final timestamp = DateTime.tryParse(activity['timestamp'] ?? '') ?? DateTime.now();
    final timeAgo = _formatTimeAgo(timestamp);
    
    return Card(
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getActivityIcon(activity['action']),
                color: colors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['description'] ?? 'Agent Activity',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    timeAgo,
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.open_in_new, size: 20),
              onPressed: () => _openCanvasWithActivity(activity),
              style: IconButton.styleFrom(
                foregroundColor: colors.primary,
              ),
              tooltip: 'Open canvas',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCanvasAgentChat(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              border: Border.all(color: colors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.design_services,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Canvas Design Agent',
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        'Create visual elements with natural language',
                        style: TextStyles.caption.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AsmblButton.primary(
                  text: 'Open Canvas',
                  icon: Icons.open_in_new,
                  size: AsmblButtonSize.small,
                  onPressed: () => context.push(AppRoutes.canvas),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          
          // Embedded design agent sidebar
          Expanded(
            child: DesignAgentSidebar(
              agent: _designAgent,
              onSpecUpdate: (spec) {}, // Canvas library doesn't need spec updates
              onContextUpdate: (context) {}, // Canvas library doesn't need context updates
              onProcessMessage: _processCanvasAgentMessage,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Process canvas agent messages in library context
  Future<String> _processCanvasAgentMessage(String message) async {
    // For library context, provide helpful responses about canvas capabilities
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('canvas') || lowerMessage.contains('open')) {
      return 'I can help you create visual designs! Click "Open Canvas" above to start working on the canvas where I can create actual elements for you.';
    }
    
    if (lowerMessage.contains('create') || lowerMessage.contains('make') || lowerMessage.contains('design')) {
      return 'I\'d love to help you create that! Let\'s go to the canvas where I can use my tool calling abilities to create real visual elements. Click "Open Canvas" to get started.';
    }
    
    if (lowerMessage.contains('help') || lowerMessage.contains('what')) {
      return 'I\'m your Canvas Design Agent! I can:\n\n• Create shapes (circles, rectangles, lines)\n• Add templates (dashboards, wireframes)\n• Design layouts and flowcharts\n\nTo use my full capabilities, open the canvas where I can create actual visual elements!';
    }
    
    return 'I\'m ready to help with visual design! Open the canvas above to start creating, or ask me about my design capabilities.';
  }
  
  Widget _buildTemplatesGrid(ThemeColors colors) {
    // Placeholder for canvas templates
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_customize,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Templates Coming Soon',
            style: TextStyles.sectionTitle.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getActivityIcon(String? action) {
    switch (action) {
      case 'create_element':
        return Icons.add_circle_outline;
      case 'create_template':
        return Icons.dashboard;
      case 'clear_canvas':
        return Icons.clear_all;
      default:
        return Icons.auto_fix_high;
    }
  }
  
  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
  
  void _openCanvasWithActivity(Map<String, dynamic> activity) {
    // Navigate to canvas and potentially restore the specific activity
    context.push(AppRoutes.canvas);
  }
}
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: colors.border.withOpacity(0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canvas Library',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recent agent creations, saved canvases, and design templates.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Quick actions - compact ghost buttons
          _buildGhostButton(
            colors,
            icon: Icons.file_upload,
            label: 'Import Canvas',
            onPressed: _importCanvas,
          ),
          const SizedBox(width: 8),
          _buildPrimaryButton(
            colors,
            icon: Icons.add,
            label: 'New Canvas',
            onPressed: _createNewCanvas,
          ),
        ],
      ),
    );
  }

  // Compact shadcn-style button helpers
  Widget _buildGhostButton(ThemeColors colors, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(ThemeColors colors, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: [
          // Search field - compact shadcn style
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(fontSize: 13, color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search canvases...',
                hintStyle: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, size: 16, color: colors.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 14, color: colors.onSurfaceVariant),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.primary),
                ),
                filled: true,
                fillColor: colors.surface.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Sort dropdown - compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                isDense: true,
                style: TextStyle(fontSize: 13, color: colors.onSurface),
                dropdownColor: colors.surface,
                icon: Icon(Icons.keyboard_arrow_down, size: 16, color: colors.onSurfaceVariant),
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // View toggle - compact
          _buildIconButton(
            colors,
            icon: _isGridView ? Icons.list : Icons.grid_view,
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),

          const SizedBox(width: 8),

          // Refresh button - compact
          _buildIconButton(
            colors,
            icon: Icons.refresh,
            onPressed: _loadSavedCanvases,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(ThemeColors colors, {required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading canvases...',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.palette_outlined,
              size: 28,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No canvases yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first visual design canvas to get started',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildPrimaryButton(colors, icon: Icons.add, label: 'Create First Canvas', onPressed: _createNewCanvas),
        ],
      ),
    );
  }

  Widget _buildCanvasGrid(ThemeColors colors) {
    final filtered = _filteredCanvases;

    if (_isGridView) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85, // Taller cards for rectangular preview
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCanvas(id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Penpot-style rectangular document preview (16:10 aspect ratio)
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    border: Border(
                      bottom: BorderSide(color: colors.border.withOpacity(0.3)),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Grid pattern background (like Penpot canvas)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CanvasGridPainter(colors.border.withOpacity(0.15)),
                        ),
                      ),
                      // Centered canvas icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border.withOpacity(0.3)),
                          ),
                          child: Icon(
                            Icons.crop_landscape_rounded,
                            size: 24,
                            color: colors.primary.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Canvas info section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(savedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                      const Spacer(),

                      // Compact action row
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactOpenButton(colors, () => _openCanvas(id)),
                          ),
                          const SizedBox(width: 4),
                          _buildCompactIconButton(colors, Icons.delete_outline, () => _showDeleteConfirmation(id, name)),
                          const SizedBox(width: 2),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: Icon(Icons.more_horiz, size: 14, color: colors.onSurfaceVariant),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(Icons.content_copy, size: 14, color: colors.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Text('Duplicate', style: TextStyle(fontSize: 13, color: colors.onSurface)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'export',
                                child: Row(
                                  children: [
                                    Icon(Icons.file_download, size: 14, color: colors.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Text('Export', style: TextStyle(fontSize: 13, color: colors.onSurface)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactOpenButton(ThemeColors colors, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_new, size: 12, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Open', style: TextStyle(fontSize: 11, color: colors.onSurface)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIconButton(ThemeColors colors, IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: colors.onSurfaceVariant),
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
            
            // Actions - compact with visible delete
            _buildGhostButton(
              colors,
              icon: Icons.open_in_new,
              label: 'Open',
              onPressed: () => _openCanvas(id),
            ),
            const SizedBox(width: 8),
            _buildIconButton(
              colors,
              icon: Icons.delete_outline,
              onPressed: () => _showDeleteConfirmation(id, name),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_horiz, size: 16, color: colors.onSurfaceVariant),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.content_copy, size: 14, color: colors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('Duplicate', style: TextStyle(fontSize: 13, color: colors.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download, size: 14, color: colors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('Export', style: TextStyle(fontSize: 13, color: colors.onSurface)),
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
      description: 'AI agent specialized in creating visual designs and canvas elements. Creates shapes, wireframes, templates, and layouts.',
      capabilities: ['canvas_design', 'tool_calling', 'visual_creation'],
      configuration: {
        'modelConfiguration': {
          'primaryModelId': 'local_llama3.1_8b',
        },
        'instructions': 'You are a design agent that creates visual elements on canvas. You can create shapes, wireframes, templates, and layouts. Always be helpful and creative.',
      },
      status: AgentStatus.idle,
    );
  }
  
  Widget _buildTabSelector(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton('recent', 'Recent Items', colors),
            _buildTabButton('chat', 'Design Agent', colors),
            _buildTabButton('penpot', 'Penpot Canvas', colors),
            _buildTabButton('saved', 'Saved Canvases', colors),
            _buildTabButton('templates', 'Templates', colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, ThemeColors colors) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [BoxShadow(color: colors.border.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            color: isActive ? colors.onSurface : colors.onSurfaceVariant,
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
      case 'penpot':
        return _buildPenpotCanvasTools(colors);
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
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () => _openCanvasWithActivity(activity),
              style: IconButton.styleFrom(
                foregroundColor: colors.primary,
              ),
              tooltip: 'Open canvas',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _showDeleteActivityConfirmation(activity),
              style: IconButton.styleFrom(
                foregroundColor: colors.error,
              ),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteActivityConfirmation(Map<String, dynamic> activity) {
    final colors = ThemeColors(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Activity',
          style: TextStyle(color: colors.onSurface),
        ),
        content: Text(
          'Are you sure you want to remove this activity from your recent items?',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteActivity(activity);
            },
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  void _deleteActivity(Map<String, dynamic> activity) {
    setState(() {
      _agentActivities.removeWhere((a) =>
        a['timestamp'] == activity['timestamp'] &&
        a['description'] == activity['description']
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Activity removed'),
        backgroundColor: ThemeColors(context).success,
        duration: const Duration(seconds: 2),
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

  /// Penpot Canvas Tools Integration
  /// Provides access to design tokens, export, canvas state, and history
  Widget _buildPenpotCanvasTools(ThemeColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.palette,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penpot Canvas Tools',
                      style: TextStyles.sectionTitle.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      'Design tokens, export controls, and canvas management',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AsmblButton.primary(
                text: 'Open Penpot Canvas',
                icon: Icons.open_in_new,
                size: AsmblButtonSize.small,
                onPressed: () => context.push(AppRoutes.canvas),
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.xxl),

          // Design Tokens Section
          AsmblCard(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.color_lens, color: colors.accent, size: 20),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        'Design Tokens',
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'Define your brand colors, typography, spacing, and effects for consistent designs',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  Wrap(
                    spacing: SpacingTokens.sm,
                    runSpacing: SpacingTokens.sm,
                    children: [
                      _buildToolChip(colors, 'Colors', Icons.palette),
                      _buildToolChip(colors, 'Typography', Icons.text_fields),
                      _buildToolChip(colors, 'Spacing', Icons.space_bar),
                      _buildToolChip(colors, 'Effects', Icons.auto_awesome),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  AsmblButton.secondary(
                    text: 'Manage Design Tokens',
                    icon: Icons.settings,
                    size: AsmblButtonSize.small,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Design tokens are managed through context documents tagged with "design-tokens"'),
                          backgroundColor: colors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: SpacingTokens.lg),

          // Export Controls Section
          AsmblCard(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.file_download, color: colors.accent, size: 20),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        'Export Capabilities',
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'Export your designs in multiple formats for production use',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _buildExportCard(colors, 'PNG', Icons.image,
                          'Raster images (1x-4x scale)'),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      Expanded(
                        child: _buildExportCard(colors, 'SVG', Icons.code,
                          'Vector graphics (scalable)'),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      Expanded(
                        child: _buildExportCard(colors, 'PDF', Icons.picture_as_pdf,
                          'Print-ready documents'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: SpacingTokens.lg),

          // Canvas State & History Section
          Row(
            children: [
              Expanded(
                child: AsmblCard(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.visibility, color: colors.accent, size: 20),
                            const SizedBox(width: SpacingTokens.sm),
                            Text(
                              'Canvas State',
                              style: TextStyles.cardTitle.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SpacingTokens.md),
                        Text(
                          'Real-time visibility into canvas elements, statistics, and queries',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.lg),
                        _buildFeatureRow(colors, 'Element tree view'),
                        _buildFeatureRow(colors, 'Statistics & counts'),
                        _buildFeatureRow(colors, 'Query by type'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.lg),
              Expanded(
                child: AsmblCard(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingTokens.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: colors.accent, size: 20),
                            const SizedBox(width: SpacingTokens.sm),
                            Text(
                              'Design History',
                              style: TextStyles.cardTitle.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SpacingTokens.md),
                        Text(
                          'Undo/redo functionality and action tracking (up to 50 entries)',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.lg),
                        _buildFeatureRow(colors, 'Undo/redo actions'),
                        _buildFeatureRow(colors, 'History summary'),
                        _buildFeatureRow(colors, 'Action tracking'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.lg),

          // MCP Tools Info
          AsmblCard(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.construction, color: colors.accent, size: 20),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        'MCP Tools Available',
                        style: TextStyles.cardTitle.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    '23 MCP tools for AI agents to programmatically control Penpot',
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  Wrap(
                    spacing: SpacingTokens.xs,
                    runSpacing: SpacingTokens.xs,
                    children: [
                      _buildMCPToolBadge(colors, 'Basic: 6 tools'),
                      _buildMCPToolBadge(colors, 'Advanced: 7 tools'),
                      _buildMCPToolBadge(colors, 'Professional: 10 tools'),
                      _buildMCPToolBadge(colors, 'Expert: 7 tools'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolChip(ThemeColors colors, String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: colors.primary),
      label: Text(
        label,
        style: TextStyles.bodySmall.copyWith(
          color: colors.onSurface,
        ),
      ),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.border),
    );
  }

  Widget _buildExportCard(ThemeColors colors, String format, IconData icon, String description) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 32),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            format,
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            description,
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(ThemeColors colors, String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: colors.success),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            feature,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMCPToolBadge(ThemeColors colors, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyles.caption.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Custom painter for canvas grid pattern (Penpot-style)
class _CanvasGridPainter extends CustomPainter {
  final Color gridColor;

  _CanvasGridPainter(this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const gridSize = 16.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
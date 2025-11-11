import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/design_system/components/app_navigation_bar.dart';
import '../../../core/constants/routes.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/canvas_local_server.dart';
import '../providers/canvas_provider.dart';

/// Main canvas screen with embedded WebView
class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSidebarCollapsed = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCanvas();
  }

  Future<void> _initializeCanvas() async {
    try {
      // Start the local server
      final canvasServer = ServiceLocator.instance.get<CanvasLocalServer>();
      await canvasServer.start();
      
      // Initialize WebView
      await _initializeWebView(canvasServer.canvasUrl);
      
      // Update provider state
      ref.read(canvasProvider.notifier).initialize(canvasServer.canvasUrl);
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize canvas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeWebView(String canvasUrl) async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    
    // Set background color only on supported platforms
    if (!Platform.isMacOS) {
      await _webViewController.setBackgroundColor(const Color(0xFFF8F9FA));
    }
    
    await _webViewController.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
            ref.read(canvasProvider.notifier).updateProgress(progress / 100.0);
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            ref.read(canvasProvider.notifier).setReady(true);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'WebView error: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      );
      
    await _webViewController.addJavaScriptChannel(
      'CanvasBridge',
      onMessageReceived: (JavaScriptMessage message) {
        _handleCanvasMessage(message.message);
      },
    );
    
    await _webViewController.addJavaScriptChannel(
      'FlutterBridge',
      onMessageReceived: (JavaScriptMessage message) {
        _handleFlutterMessage(message.message);
      },
    );
    
    await _webViewController.loadRequest(Uri.parse(canvasUrl));
  }

  void _handleCanvasMessage(String message) {
    try {
      // Handle messages from canvas (e.g., element selection, state changes)
      print('📨 Canvas Message: $message');
      ref.read(canvasProvider.notifier).handleCanvasMessage(message);
    } catch (e) {
      print('❌ Failed to handle canvas message: $e');
    }
  }

  void _handleFlutterMessage(String message) {
    try {
      // Handle messages that need Flutter-specific actions
      print('📱 Flutter Message: $message');
      // Could trigger UI updates, navigation, etc.
    } catch (e) {
      print('❌ Failed to handle Flutter message: $e');
    }
  }

  @override
  void dispose() {
    // Stop the local server when screen is disposed
    final canvasServer = ServiceLocator.instance.get<CanvasLocalServer>();
    canvasServer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    final canvasState = ref.watch(canvasProvider);

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
              const AppNavigationBar(currentRoute: AppRoutes.canvas),
              
              // Canvas header
              _buildCanvasHeader(colors, canvasState),
              
              // Main content area with sidebar
              Expanded(
                child: Row(
                  children: [
                    // AI Chat Sidebar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isSidebarCollapsed ? 0 : 280,
                      child: _isSidebarCollapsed ? null : _buildAISidebar(context),
                    ),
                    
                    // Sidebar Toggle (when collapsed)
                    if (_isSidebarCollapsed)
                      Container(
                        width: 48,
                        color: colors.surface.withOpacity(0.7),
                        child: Column(
                          children: [
                            const SizedBox(height: SpacingTokens.md),
                            IconButton(
                              onPressed: () => setState(() => _isSidebarCollapsed = false),
                              icon: const Icon(Icons.chevron_right, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: colors.surface.withOpacity(0.8),
                                foregroundColor: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Main canvas area
                    Expanded(
                      child: _buildCanvasContent(colors),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasHeader(ThemeColors colors, CanvasState canvasState) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Canvas title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.palette,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visual Canvas',
                          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
                        ),
                        Text(
                          canvasState.isReady 
                            ? 'Canvas ready - Create UI elements visually'
                            : _isLoading 
                              ? 'Loading canvas...' 
                              : 'Canvas not ready',
                          style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Canvas controls
          if (canvasState.isReady) ...[
            _buildCanvasControls(colors, canvasState),
          ],
          
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: canvasState.isReady 
                ? colors.success.withOpacity(0.1) 
                : colors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: canvasState.isReady ? colors.success : colors.warning,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  canvasState.isReady ? Icons.check_circle : Icons.hourglass_empty,
                  color: canvasState.isReady ? colors.success : colors.warning,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  canvasState.isReady ? 'Ready' : 'Loading',
                  style: TextStyles.bodySmall.copyWith(
                    color: canvasState.isReady ? colors.success : colors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasControls(ThemeColors colors, CanvasState canvasState) {
    return Row(
      children: [
        // Design system selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.palette, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Design System: ',
                style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
              DropdownButton<String>(
                value: canvasState.selectedDesignSystem,
                isDense: true,
                underline: const SizedBox(),
                style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                items: canvasState.availableDesignSystems.map((ds) => DropdownMenuItem<String>(
                  value: ds['id'] as String,
                  child: Text(ds['name'] as String),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(canvasProvider.notifier).loadDesignSystem(value);
                  }
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(width: SpacingTokens.md),
        
        // Canvas actions
        Row(
          children: [
            IconButton(
              onPressed: () => _exportCode(),
              icon: Icon(Icons.code, color: colors.primary),
              tooltip: 'Export Flutter Code',
            ),
            IconButton(
              onPressed: () => _clearCanvas(),
              icon: Icon(Icons.clear_all, color: colors.onSurfaceVariant),
              tooltip: 'Clear Canvas',
            ),
            IconButton(
              onPressed: () => _saveCanvas(),
              icon: Icon(Icons.save, color: colors.primary),
              tooltip: 'Save Canvas',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCanvasContent(ThemeColors colors) {
    if (_errorMessage != null) {
      return _buildErrorState(colors);
    }
    
    if (_isLoading) {
      return _buildLoadingState(colors);
    }
    
    return Container(
      margin: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _webViewController),
    );
  }

  Widget _buildLoadingState(ThemeColors colors) {
    final canvasState = ref.watch(canvasProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: canvasState.loadingProgress,
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Loading Canvas...',
            style: TextStyles.bodyLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            '${(canvasState.loadingProgress * 100).toInt()}%',
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colors.error,
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text(
            'Canvas Error',
            style: TextStyles.sectionTitle.copyWith(color: colors.error),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            _errorMessage!,
            style: TextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.lg),
          ElevatedButton(
            onPressed: () => _initializeCanvas(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCode() async {
    try {
      await _webViewController.runJavaScript('exportCode()');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
    }
  }

  Future<void> _clearCanvas() async {
    try {
      await _webViewController.runJavaScript('clearCanvas()');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clear failed: $e'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
    }
  }

  Future<void> _saveCanvas() async {
    try {
      await _webViewController.runJavaScript('''
        (async () => {
          try {
            const state = await getCanvasState();
            const response = await fetch('${ref.read(canvasProvider).serverUrl}/api/canvas/state', {
              method: 'PUT',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(state)
            });
            updateStatus('Canvas saved successfully');
          } catch (error) {
            updateStatus('Save failed: ' + error.message);
          }
        })();
      ''');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: ThemeColors(context).error,
        ),
      );
    }
  }

  Widget _buildAISidebar(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.7),
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎨 Design Assistant',
                        style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        'Get AI help with your design',
                        style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isSidebarCollapsed = true),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(colors),
                  
                  const SizedBox(height: SpacingTokens.xl),
                  
                  // Design Suggestions
                  _buildDesignSuggestions(colors),
                  
                  const SizedBox(height: SpacingTokens.xl),
                  
                  // Canvas Context
                  _buildCanvasContext(colors),
                  
                  const SizedBox(height: SpacingTokens.xl),
                  
                  // Chat Input Area
                  _buildChatInput(colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Wrap(
          spacing: SpacingTokens.sm,
          runSpacing: SpacingTokens.sm,
          children: [
            _buildActionChip('Create Button', Icons.smart_button, colors),
            _buildActionChip('Add Text', Icons.text_fields, colors),
            _buildActionChip('Insert Image', Icons.image, colors),
            _buildActionChip('Make Layout', Icons.view_module, colors),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(String label, IconData icon, ThemeColors colors) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: colors.primary),
      label: Text(
        label,
        style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
      ),
      onPressed: () {
        // TODO: Implement action
        print('Action: $label');
      },
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.border),
    );
  }

  Widget _buildDesignSuggestions(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Suggestions',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: colors.accent),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'Try adding a header section',
                      style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.sm),
              Row(
                children: [
                  Icon(Icons.palette_outlined, size: 16, color: colors.accent),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'Consider using consistent spacing',
                      style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCanvasContext(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Canvas Info',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _buildInfoRow('Elements', '0', colors),
              const SizedBox(height: SpacingTokens.sm),
              _buildInfoRow('Design System', 'Material 3', colors),
              const SizedBox(height: SpacingTokens.sm),
              _buildInfoRow('Canvas Size', '800×600', colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }

  Widget _buildChatInput(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask the AI',
          style: TextStyles.cardTitle.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Ask about design, layout, or components...',
                  hintStyle: TextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(SpacingTokens.md),
                ),
                maxLines: 3,
                minLines: 1,
              ),
              Padding(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement AI chat
                        print('Send message to AI');
                      },
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/widgets/excalidraw_canvas.dart';

/// Demo screen to showcase enhanced Excalidraw capabilities
class EnhancedExcalidrawDemo extends StatefulWidget {
  const EnhancedExcalidrawDemo({super.key});

  @override
  State<EnhancedExcalidrawDemo> createState() => _EnhancedExcalidrawDemoState();
}

class _EnhancedExcalidrawDemoState extends State<EnhancedExcalidrawDemo> {
  final GlobalKey<ExcalidrawCanvasState> _canvasKey = GlobalKey<ExcalidrawCanvasState>();
  String _statusMessage = 'Ready to test enhanced features';

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
              // Header
              const AppNavigationBar(currentRoute: '/enhanced-excalidraw-demo'),
              
              // Controls Panel
              Container(
                margin: const EdgeInsets.all(SpacingTokens.lg),
                padding: const EdgeInsets.all(SpacingTokens.lg),
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enhanced Excalidraw Features Test',
                      style: TextStyles.sectionTitle.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    
                    // Element type buttons
                    Text(
                      'New Element Types:',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Wrap(
                      spacing: SpacingTokens.sm,
                      runSpacing: SpacingTokens.sm,
                      children: [
                        _buildElementButton('Arrow', 'arrow', colors),
                        _buildElementButton('Diamond', 'diamond', colors),
                        _buildElementButton('Input Field', 'input', colors),
                        _buildElementButton('Checkbox', 'checkbox', colors),
                        _buildElementButton('Home Icon', 'icon-home', colors),
                        _buildElementButton('User Icon', 'icon-user', colors),
                        _buildElementButton('Settings Icon', 'icon-settings', colors),
                      ],
                    ),
                    
                    const SizedBox(height: SpacingTokens.lg),
                    
                    // Template buttons
                    Text(
                      'Templates:',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AsmblButton.secondary(
                            text: 'Mobile App Template',
                            icon: Icons.smartphone,
                            onPressed: () => _addMobileTemplate(),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.sm),
                        Expanded(
                          child: AsmblButton.secondary(
                            text: 'Web Header Template',
                            icon: Icons.web,
                            onPressed: () => _addWebHeaderTemplate(),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: SpacingTokens.lg),
                    
                    // Code generation
                    Text(
                      'Code Generation:',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    AsmblButton.primary(
                      text: 'Generate Code from Wireframe',
                      icon: Icons.code,
                      onPressed: () => _generateCode(),
                    ),

                    const SizedBox(height: SpacingTokens.lg),
                    
                    // Instructions
                    Container(
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
                                Icons.info,
                                size: 20,
                                color: colors.primary,
                              ),
                              const SizedBox(width: SpacingTokens.xs),
                              Text(
                                'How to Test Context Menus:',
                                style: TextStyles.bodyMedium.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SpacingTokens.sm),
                          Text(
                            '1. Add some elements using the buttons above\n'
                            '2. Right-click on any element in the canvas\n'
                            '3. Try: Duplicate, Delete, Change Color, etc.\n'
                            '4. Use templates to create complete layouts',
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: SpacingTokens.md),
                    
                    // Status
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.sm),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: SpacingTokens.xs),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyles.bodySmall.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Canvas
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    SpacingTokens.lg,
                    0,
                    SpacingTokens.lg,
                    SpacingTokens.lg,
                  ),
                  child: ExcalidrawCanvas(
                    key: _canvasKey,
                    onError: (error) {
                      setState(() {
                        _statusMessage = 'Error: $error';
                      });
                    },
                    sessionId: 'enhanced_demo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElementButton(String label, String elementType, ThemeColors colors) {
    return AsmblButton.outline(
      text: label,
      onPressed: () => _addElement(elementType, label),
      size: AsmblButtonSize.small,
    );
  }

  void _addElement(String elementType, String label) {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addCanvasElement(elementType, 'Add $label');
      setState(() {
        _statusMessage = 'Added $label element';
      });
    } else {
      setState(() {
        _statusMessage = 'Canvas not ready';
      });
    }
  }

  void _addMobileTemplate() {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addMobileAppTemplate();
      setState(() {
        _statusMessage = 'Added mobile app template';
      });
    } else {
      setState(() {
        _statusMessage = 'Canvas not ready';
      });
    }
  }

  void _addWebHeaderTemplate() {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.addWebHeaderTemplate();
      setState(() {
        _statusMessage = 'Added web header template';
      });
    } else {
      setState(() {
        _statusMessage = 'Canvas not ready';
      });
    }
  }

  void _generateCode() {
    final canvas = _canvasKey.currentState;
    if (canvas != null) {
      canvas.generateCodeFromWireframe();
      setState(() {
        _statusMessage = 'Generating code from wireframe...';
      });
    } else {
      setState(() {
        _statusMessage = 'Canvas not ready';
      });
    }
  }
}
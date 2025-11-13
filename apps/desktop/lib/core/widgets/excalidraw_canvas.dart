import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../design_system/design_system.dart';

/// Excalidraw canvas widget that embeds Excalidraw in a WebView
/// Provides drawing, saving, and loading functionality for wireframes and diagrams
class ExcalidrawCanvas extends StatefulWidget {
  final String? initialData;
  final Function(String drawingData)? onDrawingChanged;
  final Function(String drawingData)? onDrawingSaved;
  final Function(String base64PNG)? onPNGExported;
  final Function(String base64Image, int elementsCount)? onVisionCapture;
  final Function(String imageData, int elementsCount, String prompt)? onCodeGeneration;
  final Function(String error)? onError;
  final bool darkMode;
  final String? sessionId; // For saving multiple drawings

  const ExcalidrawCanvas({
    super.key,
    this.initialData,
    this.onDrawingChanged,
    this.onDrawingSaved,
    this.onPNGExported,
    this.onVisionCapture,
    this.onCodeGeneration,
    this.onError,
    this.darkMode = false,
    this.sessionId,
  });

  @override
  ExcalidrawCanvasState createState() => ExcalidrawCanvasState();
}

class ExcalidrawCanvasState extends State<ExcalidrawCanvas> {
  late WebViewController _webViewController;
  bool _isLoaded = false;
  bool _hasContent = false;
  bool _isExcalidrawReady = false;
  String? _lastSavedData;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void didUpdateWidget(ExcalidrawCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update theme if it changed
    if (oldWidget.darkMode != widget.darkMode && _isLoaded) {
      _updateTheme();
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          debugPrint('📱 Excalidraw page started loading: $url');
        },
        onPageFinished: (String url) {
          debugPrint('📱 Excalidraw page finished loading: $url');
          _onPageLoaded();
        },
        onWebResourceError: (WebResourceError error) {
          debugPrint('❌ Excalidraw WebView error: ${error.description}');
          widget.onError?.call('WebView error: ${error.description}');
        },
      ))
      ..addJavaScriptChannel(
        'flutter_inappwebview',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      );

    _loadExcalidrawHTML();
  }

  void _loadExcalidrawHTML() async {
    try {
      // Load the HTML content from assets
      final String htmlContent = await rootBundle.loadString('assets/excalidraw/index.html');
      
      // Convert to data URI for WebView
      final String dataUri = Uri.dataFromString(
        htmlContent,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ).toString();
      
      await _webViewController.loadRequest(Uri.parse(dataUri));
      
    } catch (error) {
      debugPrint('❌ Failed to load Excalidraw HTML: $error');
      widget.onError?.call('Failed to load drawing canvas: $error');
    }
  }

  void _onPageLoaded() {
    debugPrint('📱 WebView page loaded - waiting for JavaScript ready signal');
    
    // Don't set _isLoaded here - wait for JavaScript 'webViewReady' message
    // The JavaScript will send us a message when Excalidraw is fully initialized
    
    // Load initial data if provided (will be handled when JS is ready)
    if (widget.initialData != null) {
      // Store for later when JS is ready
      debugPrint('📱 Initial data will be loaded when JS is ready');
    }
  }

  void _handleJavaScriptMessage(String message) {
    debugPrint('📨 Received JavaScript message: $message');
    
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String type = data['type'] ?? '';
      
      debugPrint('📨 Message type: $type');
      
      switch (type) {
        case 'webViewReady':
          debugPrint('✅ WebView ready message received');
          setState(() {
            _isLoaded = true;
          });
          
          // Set initial theme
          _updateTheme();
          
          // Load initial data if provided
          if (widget.initialData != null) {
            _loadDrawingData(widget.initialData!);
          }
          break;
          
        case 'drawingChanged':
          _hasContent = data['hasContent'] ?? false;
          debugPrint('🎨 Drawing changed - hasContent: $_hasContent');
          if (widget.onDrawingChanged != null) {
            widget.onDrawingChanged!(message);
          }
          break;
          
        case 'console_log':
          final String level = data['level'] ?? 'log';
          final String message = data['message'] ?? '';
          switch (level) {
            case 'error':
              debugPrint('🔴 JS Error: $message');
              break;
            case 'warn':
              debugPrint('🟡 JS Warn: $message');
              break;
            default:
              debugPrint('🔵 JS Log: $message');
              break;
          }
          break;
          
        case 'excalidrawReady':
          debugPrint('✅ Excalidraw API is ready');
          _isExcalidrawReady = true;
          break;
          
        case 'drawingSaved':
          final String drawingData = data['data'] ?? '';
          _lastSavedData = drawingData;
          _saveToFile(drawingData);
          debugPrint('💾 Drawing saved successfully');
          if (widget.onDrawingSaved != null) {
            widget.onDrawingSaved!(drawingData);
          }
          break;
          
        case 'pngExported':
          final String base64PNG = data['data'] ?? '';
          debugPrint('📸 PNG exported successfully');
          if (widget.onPNGExported != null) {
            widget.onPNGExported!(base64PNG);
          }
          break;
          
        case 'drawingCleared':
          setState(() {
            _hasContent = false;
          });
          debugPrint('🗑️ Drawing cleared');
          break;
          
        case 'canvasVisionCapture':
          final String base64Image = data['data'] ?? '';
          final int elementsCount = data['elementsCount'] ?? 0;
          debugPrint('🔍 Canvas vision capture received: $elementsCount elements');
          // Trigger vision analysis callback
          if (widget.onVisionCapture != null) {
            widget.onVisionCapture!(base64Image, elementsCount);
          }
          break;
          
        case 'visionCaptureError':
          final String error = data['message'] ?? 'Vision capture failed';
          debugPrint('❌ Vision capture error: $error');
          if (widget.onError != null) {
            widget.onError!(error);
          }
          break;
          
        case 'generateCodeRequest':
          final String imageData = data['imageData'] ?? '';
          final int elementsCount = data['elementsCount'] ?? 0;
          final String prompt = data['prompt'] ?? '';
          debugPrint('⚙️ Code generation request received: $elementsCount elements');
          // Forward to parent for OpenAI API call
          if (widget.onCodeGeneration != null) {
            widget.onCodeGeneration!(imageData, elementsCount, prompt);
          }
          break;
          
        case 'codeGenerationError':
          final String error = data['message'] ?? 'Code generation failed';
          debugPrint('❌ Code generation error: $error');
          if (widget.onError != null) {
            widget.onError!(error);
          }
          break;
          
        case 'elementCopied':
          final Map<String, dynamic> elementData = data['elementData'] ?? {};
          debugPrint('📄 Element copied: ${elementData['type']}');
          // Could implement clipboard functionality here
          break;
          
        case 'error':
          final String error = data['message'] ?? 'Unknown error';
          debugPrint('❌ Excalidraw error: $error');
          if (widget.onError != null) {
            widget.onError!(error);
          }
          break;
          
        default:
          debugPrint('⚠️ Unknown message type: $type');
      }
    } catch (error) {
      debugPrint('❌ Failed to parse JavaScript message: $error');
      debugPrint('❌ Raw message: $message');
    }
  }

  Future<void> _saveToFile(String drawingData) async {
    try {
      if (widget.sessionId == null) return;
      
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory excalidrawDir = Directory('${appDir.path}/excalidraw');
      
      if (!excalidrawDir.existsSync()) {
        excalidrawDir.createSync(recursive: true);
      }
      
      final File file = File('${excalidrawDir.path}/${widget.sessionId}.json');
      await file.writeAsString(drawingData);
      
      debugPrint('💾 Drawing saved to: ${file.path}');
    } catch (error) {
      debugPrint('❌ Failed to save drawing: $error');
      widget.onError?.call('Failed to save drawing: $error');
    }
  }

  Future<String?> _loadFromFile() async {
    try {
      if (widget.sessionId == null) return null;
      
      final Directory appDir = await getApplicationDocumentsDirectory();
      final File file = File('${appDir.path}/excalidraw/${widget.sessionId}.json');
      
      if (file.existsSync()) {
        final String content = await file.readAsString();
        debugPrint('📁 Drawing loaded from: ${file.path}');
        return content;
      }
    } catch (error) {
      debugPrint('❌ Failed to load drawing: $error');
      widget.onError?.call('Failed to load drawing: $error');
    }
    
    return null;
  }

  void _updateTheme() {
    if (!_isLoaded) return;
    
    final String theme = widget.darkMode ? 'dark' : 'light';
    _executeJavaScript('window.setTheme && window.setTheme("$theme")');
  }

  void _loadDrawingData(String data) {
    if (!_isLoaded) return;
    
    final String escapedData = data.replaceAll('"', '\\"').replaceAll('\n', '\\n');
    _executeJavaScript('window.loadDrawingData && window.loadDrawingData("$escapedData")');
  }

  void _executeJavaScript(String script) {
    debugPrint('📋 Executing JavaScript: $script');
    _webViewController.runJavaScript(script).catchError((error) {
      debugPrint('❌ JavaScript execution failed: $error');
    });
  }

  // Public methods for external control
  void saveDrawing() {
    if (_isLoaded) {
      _executeJavaScript('saveDrawing()');
    }
  }

  void loadDrawing() async {
    if (_isLoaded) {
      final String? data = await _loadFromFile();
      if (data != null) {
        _loadDrawingData(data);
      } else {
        _executeJavaScript('loadDrawing()');
      }
    }
  }

  void clearCanvas() {
    if (_isLoaded) {
      _executeJavaScript('clearCanvas()');
    }
  }

  void exportToPNG() {
    if (_isLoaded) {
      _executeJavaScript('exportPNG()');
    }
  }

  void addWireframeTemplate() {
    debugPrint('🎨 addWireframeTemplate called, _isLoaded: $_isLoaded, _isExcalidrawReady: $_isExcalidrawReady');
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('🎨 Both WebView and ExcalidrawAPI are ready - executing JavaScript');
      _executeJavaScript('window.addWireframeElements && window.addWireframeElements()');
      setState(() {
        _hasContent = true;
      });
    } else if (!_isLoaded) {
      debugPrint('❌ Cannot add wireframe template - WebView not loaded yet');
    } else if (!_isExcalidrawReady) {
      debugPrint('❌ Cannot add wireframe template - ExcalidrawAPI not ready yet, retrying in 1 second...');
      // Retry in 1 second if Excalidraw API isn't ready
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          addWireframeTemplate();
        }
      });
    }
  }

  void addCanvasElement(String elementType, String prompt) {
    debugPrint('🎨 addCanvasElement called: $elementType, prompt: "$prompt"');
    debugPrint('🎨 Canvas state - _isLoaded: $_isLoaded, _isExcalidrawReady: $_isExcalidrawReady');
    
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('🎨 Both WebView and ExcalidrawAPI are ready - executing JavaScript');
      // Escape quotes and newlines in the prompt for JavaScript
      final String escapedPrompt = prompt.replaceAll('"', '\\"').replaceAll('\n', '\\n');
      _executeJavaScript('window.addCanvasElement && window.addCanvasElement("$elementType", "$escapedPrompt")');
      setState(() {
        _hasContent = true;
      });
    } else if (!_isLoaded) {
      debugPrint('❌ Cannot add canvas element - WebView not loaded yet');
    } else if (!_isExcalidrawReady) {
      debugPrint('❌ Cannot add canvas element - ExcalidrawAPI not ready yet, retrying in 1 second...');
      // Retry in 1 second if Excalidraw API isn't ready
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          addCanvasElement(elementType, prompt);
        }
      });
    }
  }

  void captureCanvasForVision() {
    debugPrint('🔍 captureCanvasForVision called');
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('🔍 Capturing canvas for vision analysis');
      _executeJavaScript('window.captureCanvasForVision && window.captureCanvasForVision()');
    } else {
      debugPrint('❌ Cannot capture canvas - WebView or ExcalidrawAPI not ready');
    }
  }

  void addMobileAppTemplate() {
    debugPrint('📱 addMobileAppTemplate called');
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('📱 Adding mobile app template');
      _executeJavaScript('window.addMobileAppTemplate && window.addMobileAppTemplate()');
      setState(() {
        _hasContent = true;
      });
    } else {
      debugPrint('❌ Cannot add mobile template - WebView or ExcalidrawAPI not ready');
    }
  }

  void addWebHeaderTemplate() {
    debugPrint('🌐 addWebHeaderTemplate called');
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('🌐 Adding web header template');
      _executeJavaScript('window.addWebHeaderTemplate && window.addWebHeaderTemplate()');
      setState(() {
        _hasContent = true;
      });
    } else {
      debugPrint('❌ Cannot add web header template - WebView or ExcalidrawAPI not ready');
    }
  }

  void generateCodeFromWireframe() {
    debugPrint('⚙️ generateCodeFromWireframe called');
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('⚙️ Generating code from wireframe');
      _executeJavaScript('window.generateCodeFromWireframe && window.generateCodeFromWireframe()');
    } else {
      debugPrint('❌ Cannot generate code - WebView or ExcalidrawAPI not ready');
    }
  }

  void modifyElement(String elementId, Map<String, dynamic> modifications) {
    debugPrint('🛠️ modifyElement called: $elementId');
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('🛠️ Modifying element with: $modifications');
      final String modificationsJson = jsonEncode(modifications);
      _executeJavaScript('window.modifyElement && window.modifyElement("$elementId", $modificationsJson)');
    } else {
      debugPrint('❌ Cannot modify element - WebView or ExcalidrawAPI not ready');
    }
  }

  void addFlutterComponent(String componentKey, String category) {
    debugPrint('📱 addFlutterComponent called: $componentKey from $category');
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('📱 Adding Flutter component: $componentKey');
      _executeJavaScript('window.addFlutterComponent && window.addFlutterComponent("$componentKey", "$category")');
      setState(() {
        _hasContent = true;
      });
    } else {
      debugPrint('❌ Cannot add Flutter component - WebView or ExcalidrawAPI not ready');
    }
  }

  void addFlutterScreenTemplate(String templateType) {
    debugPrint('📱 addFlutterScreenTemplate called: $templateType');
    if (_isLoaded && _isExcalidrawReady) {
      debugPrint('📱 Adding Flutter screen template: $templateType');
      _executeJavaScript('window.addFlutterScreenTemplate && window.addFlutterScreenTemplate("$templateType")');
      setState(() {
        _hasContent = true;
      });
    } else {
      debugPrint('❌ Cannot add Flutter template - WebView or ExcalidrawAPI not ready');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        child: Stack(
          children: [
            if (_isLoaded) ...[
              WebViewWidget(controller: _webViewController),
            ] else ...[
              _buildLoadingState(colors),
            ],
            
            // Canvas status indicator
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildStatusIndicator(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeColors colors) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'Loading drawing canvas...',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeColors colors) {
    return AnimatedOpacity(
      opacity: _hasContent ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit,
              size: 16,
              color: colors.surface,
            ),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              'Drawing active',
              style: TextStyles.bodySmall.copyWith(
                color: colors.surface,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}

/// Extensions for easier usage
extension ExcalidrawCanvasExtensions on ExcalidrawCanvas {
  /// Creates a canvas specifically for wireframing
  static ExcalidrawCanvas wireframe({
    Key? key,
    Function(String)? onSaved,
    bool darkMode = false,
    String? sessionId,
  }) {
    return ExcalidrawCanvas(
      key: key,
      onDrawingSaved: onSaved,
      darkMode: darkMode,
      sessionId: sessionId ?? 'wireframe_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Creates a canvas for general diagramming
  static ExcalidrawCanvas diagram({
    Key? key,
    Function(String)? onSaved,
    bool darkMode = false,
    String? sessionId,
  }) {
    return ExcalidrawCanvas(
      key: key,
      onDrawingSaved: onSaved,
      darkMode: darkMode,
      sessionId: sessionId ?? 'diagram_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
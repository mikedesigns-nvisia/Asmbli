import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../design_system/design_system.dart';

/// Penpot canvas widget - embeds Penpot web app in Flutter
/// Provides JavaScript bridge for agent communication
class PenpotCanvas extends StatefulWidget {
  const PenpotCanvas({super.key});

  @override
  PenpotCanvasState createState() => PenpotCanvasState();
}

class PenpotCanvasState extends State<PenpotCanvas> {
  late WebViewController _controller;
  bool _isLoaded = false;
  bool _isPluginLoaded = false;
  String? _connectionTimestamp;
  String? _connectionMessage;

  // Stream for plugin responses
  final StreamController<Map<String, dynamic>> _pluginResponseController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get pluginResponses =>
      _pluginResponseController.stream;

  bool get isPluginLoaded => _isPluginLoaded;
  String? get connectionTimestamp => _connectionTimestamp;
  String? get connectionMessage => _connectionMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'asmbli_bridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handlePluginMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => _isLoaded = true);
            debugPrint('✅ Penpot loaded: $url');
            _injectPlugin();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://design.penpot.app'));
  }

  // Inject plugin script into Penpot
  Future<void> _injectPlugin() async {
    try {
      debugPrint('📦 Loading Penpot plugin from assets...');

      // Load plugin JavaScript from assets
      final pluginScript = await rootBundle.loadString(
        'assets/penpot_plugin/dist/plugin.js',
      );

      // Inject plugin into Penpot page
      await _controller.runJavaScript(pluginScript);

      debugPrint('✅ Penpot plugin injected successfully');
    } catch (e) {
      debugPrint('❌ Error injecting plugin: $e');
      debugPrint('⚠️ Plugin not built yet - run: cd apps/desktop/assets/penpot_plugin && npm run bundle');

      // For development: Mark as ready anyway so UI doesn't block
      if (mounted) {
        setState(() => _isPluginLoaded = true);
      }
    }
  }

  // Handle messages from plugin
  void _handlePluginMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;

      if (data['source'] == 'asmbli-plugin') {
        debugPrint('📥 RECEIVED FROM PLUGIN: ${data['type']}');

        if (data['type'] == 'plugin_ready') {
          setState(() => _isPluginLoaded = true);
        }

        // Handle connection status signal from headless plugin
        if (data['type'] == 'connection-status') {
          setState(() {
            _isPluginLoaded = data['connected'] == true;
            _connectionTimestamp = data['timestamp'] as String?;
            _connectionMessage = data['message'] as String?;
          });
          debugPrint('🔌 Plugin connection status: ${data['message']} at ${data['timestamp']}');
        }

        _pluginResponseController.add(data);
      }
    } catch (e) {
      debugPrint('❌ Error parsing plugin message: $e');
    }
  }

  // Send command to plugin
  Future<void> sendCommandToPlugin({
    required String type,
    required Map<String, dynamic> params,
    String? requestId,
  }) async {
    final command = {
      'source': 'asmbli-agent',
      'type': type,
      'params': params,
      'requestId': requestId ?? _generateRequestId(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    final commandJson = jsonEncode(command);

    await _controller.runJavaScript('''
      window.postMessage($commandJson, '*');
    ''');

    debugPrint('📤 SENT TO PLUGIN: $type');
  }

  // Execute command and wait for response
  Future<Map<String, dynamic>> executeCommand({
    required String type,
    required Map<String, dynamic> params,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final requestId = _generateRequestId();

    // Listen for response
    final responseFuture = pluginResponses
        .where((response) => response['requestId'] == requestId)
        .first
        .timeout(timeout);

    // Send command
    await sendCommandToPlugin(
      type: type,
      params: params,
      requestId: requestId,
    );

    // Wait for response
    return await responseFuture;
  }

  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Stack(
      children: [
        // WebView fills entire space - no borders, no decoration
        WebViewWidget(controller: _controller),

        // Minimal loading overlay - fades quickly
        if (!_isLoaded)
          Container(
            color: colors.background.withOpacity(0.95),
            child: Center(
              child: CircularProgressIndicator(color: colors.primary),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _pluginResponseController.close();
    super.dispose();
  }
}

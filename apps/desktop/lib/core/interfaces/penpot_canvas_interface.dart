abstract class PenpotCanvasInterface {
  /// Check if the plugin is loaded and ready
  bool get isPluginLoaded;

  /// Execute a command on the Penpot canvas
  Future<Map<String, dynamic>> executeCommand({
    required String type,
    required Map<String, dynamic> params,
    Duration timeout = const Duration(seconds: 10),
  });
}

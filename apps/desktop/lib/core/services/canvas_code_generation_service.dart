import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../di/service_locator.dart';
import './canvas_local_server.dart';
import './canvas_storage_service.dart';
import './canvas_error_handler.dart';

/// Advanced code generation service for Canvas designs
/// Handles Flutter, React, HTML, and SwiftUI code generation with Asmbli design system integration
class CanvasCodeGenerationService {
  final Map<String, GeneratedCode> _generatedCodeCache = {};
  final Map<String, Timer> _codeGenerationDebounce = {};
  
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const int maxCacheSize = 50;

  /// Generate code from canvas state
  Future<GeneratedCode> generateCode({
    required String canvasId,
    required Map<String, dynamic> canvasState,
    required CodeFormat format,
    CodeGenerationOptions? options,
  }) async {
    try {
      final cacheKey = _getCacheKey(canvasId, format, options);
      
      // Check cache first
      if (_generatedCodeCache.containsKey(cacheKey)) {
        final cached = _generatedCodeCache[cacheKey]!;
        if (DateTime.now().difference(cached.generatedAt).inMinutes < 5) {
          print('📦 Using cached code for $canvasId ($format)');
          return cached;
        }
      }

      print('🛠️ Generating $format code for canvas: $canvasId');
      
      final effectiveOptions = options ?? CodeGenerationOptions.withDefaults();
      
      // Call MCP server to generate code
      final localServer = ServiceLocator.instance.get<CanvasLocalServer>();
      final mcpResponse = await _callMCPCodeGeneration(
        canvasState,
        format,
        effectiveOptions,
      );
      
      final generatedCode = GeneratedCode(
        canvasId: canvasId,
        format: format,
        code: mcpResponse['code'] as String,
        options: effectiveOptions,
        generatedAt: DateTime.now(),
        designSystemUsed: effectiveOptions.useAsmbliDesignSystem,
        componentized: effectiveOptions.componentize,
        responsive: effectiveOptions.responsiveBreakpoints,
        accessible: effectiveOptions.accessibility,
      );
      
      // Cache result
      _cacheGeneratedCode(cacheKey, generatedCode);
      
      print('✅ Code generation completed for $canvasId');
      return generatedCode;
      
    } catch (e, stackTrace) {
      final error = CanvasErrorHandler.handleError(e, 'Code generation for $canvasId', stackTrace: stackTrace);
      throw CodeGenerationException(
        'Failed to generate $format code: ${error.message}',
        canvasId: canvasId,
        format: format,
      );
    }
  }

  /// Generate code with real-time updates (debounced)
  void generateCodeRealTime({
    required String canvasId,
    required Map<String, dynamic> canvasState,
    required CodeFormat format,
    required Function(GeneratedCode) onCodeGenerated,
    required Function(String) onError,
    CodeGenerationOptions? options,
  }) {
    // Cancel existing debounce timer
    _codeGenerationDebounce[canvasId]?.cancel();
    
    // Start new debounced generation
    _codeGenerationDebounce[canvasId] = Timer(debounceDelay, () async {
      try {
        final code = await generateCode(
          canvasId: canvasId,
          canvasState: canvasState,
          format: format,
          options: options,
        );
        onCodeGenerated(code);
      } catch (e) {
        onError(e.toString());
      }
    });
  }

  /// Export generated code to file
  Future<String> exportToFile(GeneratedCode code, {String? customPath}) async {
    try {
      final extension = _getFileExtension(code.format);
      final fileName = '${code.canvasId}_${code.format.name}$extension';
      
      String filePath;
      if (customPath != null) {
        filePath = path.join(customPath, fileName);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(path.join(appDir.path, 'Asmbli', 'Canvas', 'Exports'));
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        filePath = path.join(exportDir.path, fileName);
      }
      
      final file = File(filePath);
      await file.writeAsString(_formatCodeForExport(code));
      
      print('📤 Code exported to: $filePath');
      return filePath;
      
    } catch (e) {
      throw CodeGenerationException(
        'Failed to export code to file: $e',
        canvasId: code.canvasId,
        format: code.format,
      );
    }
  }

  /// Generate multiple formats at once
  Future<Map<CodeFormat, GeneratedCode>> generateMultipleFormats({
    required String canvasId,
    required Map<String, dynamic> canvasState,
    required List<CodeFormat> formats,
    CodeGenerationOptions? options,
  }) async {
    final results = <CodeFormat, GeneratedCode>{};
    
    try {
      // Generate all formats in parallel
      final futures = formats.map((format) => 
        generateCode(
          canvasId: canvasId,
          canvasState: canvasState,
          format: format,
          options: options,
        ).then((code) => MapEntry(format, code))
      );
      
      final results = await Future.wait(futures);
      return Map.fromEntries(results);
      
    } catch (e) {
      throw CodeGenerationException(
        'Failed to generate multiple formats: $e',
        canvasId: canvasId,
      );
    }
  }

  /// Generate code preview (first 50 lines)
  Future<String> generatePreview({
    required String canvasId,
    required Map<String, dynamic> canvasState,
    required CodeFormat format,
    CodeGenerationOptions? options,
  }) async {
    try {
      final code = await generateCode(
        canvasId: canvasId,
        canvasState: canvasState,
        format: format,
        options: options,
      );
      
      final lines = code.code.split('\n');
      final previewLines = lines.take(50).toList();
      
      if (lines.length > 50) {
        previewLines.add('// ... ${lines.length - 50} more lines');
      }
      
      return previewLines.join('\n');
      
    } catch (e) {
      return '// Error generating preview: $e';
    }
  }

  /// Get code generation statistics
  Map<String, dynamic> getGenerationStats() {
    final formatCounts = <String, int>{};
    final designSystemUsage = <bool, int>{};
    final responsiveUsage = <bool, int>{};
    
    for (final code in _generatedCodeCache.values) {
      final format = code.format.name;
      formatCounts[format] = (formatCounts[format] ?? 0) + 1;
      
      designSystemUsage[code.designSystemUsed] = 
          (designSystemUsage[code.designSystemUsed] ?? 0) + 1;
          
      responsiveUsage[code.responsive] = 
          (responsiveUsage[code.responsive] ?? 0) + 1;
    }
    
    return {
      'totalGenerated': _generatedCodeCache.length,
      'formatBreakdown': formatCounts,
      'designSystemUsage': designSystemUsage,
      'responsiveUsage': responsiveUsage,
      'cacheSize': _generatedCodeCache.length,
      'activeDebouncers': _codeGenerationDebounce.length,
    };
  }

  /// Clear code generation cache
  void clearCache() {
    _generatedCodeCache.clear();
    print('🗑️ Code generation cache cleared');
  }

  /// Cancel all pending generations
  void cancelPendingGenerations() {
    for (final timer in _codeGenerationDebounce.values) {
      timer.cancel();
    }
    _codeGenerationDebounce.clear();
    print('🛑 All pending code generations cancelled');
  }

  /// Dispose service
  void dispose() {
    cancelPendingGenerations();
    clearCache();
    print('🛑 Canvas Code Generation Service disposed');
  }

  // Private helper methods

  Future<Map<String, dynamic>> _callMCPCodeGeneration(
    Map<String, dynamic> canvasState,
    CodeFormat format,
    CodeGenerationOptions options,
  ) async {
    // This would call the actual MCP server's export_code tool
    final mcpArgs = {
      'format': format.name,
      'includeTokens': options.includeTokens,
      'componentize': options.componentize,
      'useAsmbliDesignSystem': options.useAsmbliDesignSystem,
      'targetFramework': options.targetFramework?.name,
      'responsiveBreakpoints': options.responsiveBreakpoints,
      'accessibility': options.accessibility,
      'darkModeSupport': options.darkModeSupport,
      'state': canvasState,
    };
    
    // Simulate MCP call - in reality this would go through the MCP bridge
    await Future.delayed(Duration(milliseconds: 100 + (canvasState['elements']?.length ?? 0) * 50));
    
    return {
      'code': _generateMockCode(format, options),
      'success': true,
    };
  }

  String _generateMockCode(CodeFormat format, CodeGenerationOptions options) {
    switch (format) {
      case CodeFormat.flutter:
        return _generateMockFlutterCode(options);
      case CodeFormat.react:
        return _generateMockReactCode(options);
      case CodeFormat.html:
        return _generateMockHtmlCode(options);
      case CodeFormat.swiftui:
        return _generateMockSwiftUICode(options);
    }
  }

  String _generateMockFlutterCode(CodeGenerationOptions options) {
    final imports = options.useAsmbliDesignSystem
        ? "import 'package:flutter/material.dart';\nimport 'core/design_system/design_system.dart';"
        : "import 'package:flutter/material.dart';";
        
    return '''$imports

/// Generated canvas screen
/// Created with Asmbli Canvas - https://asmbli.ai
class GeneratedScreen extends StatelessWidget {
  const GeneratedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ${options.useAsmbliDesignSystem ? 'final colors = ThemeColors(context);' : ''}
    
    return Scaffold(
      ${options.useAsmbliDesignSystem ? '''body: Container(
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
          child: Stack(
            children: [
              // Generated elements would be here
            ],
          ),
        ),
      ),''' : '''backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Generated elements would be here
          ],
        ),
      ),'''}
    );
  }
}''';
  }

  String _generateMockReactCode(CodeGenerationOptions options) {
    return '''import React from 'react';
import styled from 'styled-components';

const Container = styled.div\`
  width: 100%;
  height: 100vh;
  background: #f8f9fa;
  position: relative;
\`;

export const GeneratedComponent = () => {
  return (
    <Container>
      {/* Generated elements would be here */}
    </Container>
  );
};''';
  }

  String _generateMockHtmlCode(CodeGenerationOptions options) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Generated Canvas</title>
  <style>
    .canvas-container {
      width: 100%;
      height: 100vh;
      background: #f8f9fa;
      position: relative;
    }
  </style>
</head>
<body>
  <div class="canvas-container">
    <!-- Generated elements would be here -->
  </div>
</body>
</html>''';
  }

  String _generateMockSwiftUICode(CodeGenerationOptions options) {
    return '''import SwiftUI

struct GeneratedView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            
            // Generated elements would be here
        }
    }
}

#Preview {
    GeneratedView()
}''';
  }

  String _getCacheKey(String canvasId, CodeFormat format, CodeGenerationOptions? options) {
    final optionsHash = options?.hashCode ?? 0;
    return '${canvasId}_${format.name}_$optionsHash';
  }

  void _cacheGeneratedCode(String cacheKey, GeneratedCode code) {
    // Remove oldest entries if cache is full
    if (_generatedCodeCache.length >= maxCacheSize) {
      final oldestKey = _generatedCodeCache.entries
          .reduce((a, b) => a.value.generatedAt.isBefore(b.value.generatedAt) ? a : b)
          .key;
      _generatedCodeCache.remove(oldestKey);
    }
    
    _generatedCodeCache[cacheKey] = code;
  }

  String _getFileExtension(CodeFormat format) {
    switch (format) {
      case CodeFormat.flutter:
        return '.dart';
      case CodeFormat.react:
        return '.tsx';
      case CodeFormat.html:
        return '.html';
      case CodeFormat.swiftui:
        return '.swift';
    }
  }

  String _formatCodeForExport(GeneratedCode code) {
    final header = '''//
// Generated with Asmbli Canvas
// Canvas ID: ${code.canvasId}
// Format: ${code.format.name}
// Generated: ${code.generatedAt.toIso8601String()}
// Design System: ${code.designSystemUsed ? 'Asmbli' : 'Custom'}
// Responsive: ${code.responsive}
// Accessible: ${code.accessible}
//

''';
    
    return header + code.code;
  }
}

/// Generated code representation
class GeneratedCode {
  final String canvasId;
  final CodeFormat format;
  final String code;
  final CodeGenerationOptions options;
  final DateTime generatedAt;
  final bool designSystemUsed;
  final bool componentized;
  final bool responsive;
  final bool accessible;

  GeneratedCode({
    required this.canvasId,
    required this.format,
    required this.code,
    required this.options,
    required this.generatedAt,
    required this.designSystemUsed,
    required this.componentized,
    required this.responsive,
    required this.accessible,
  });

  /// Get code statistics
  Map<String, dynamic> get stats {
    final lines = code.split('\n').length;
    final characters = code.length;
    final words = code.split(RegExp(r'\s+')).length;
    
    return {
      'lines': lines,
      'characters': characters,
      'words': words,
      'format': format.name,
      'size': '${(characters / 1024).toStringAsFixed(1)} KB',
    };
  }
}

/// Code generation options
class CodeGenerationOptions {
  final bool includeTokens;
  final bool componentize;
  final bool useAsmbliDesignSystem;
  final TargetFramework? targetFramework;
  final bool responsiveBreakpoints;
  final bool accessibility;
  final bool darkModeSupport;

  const CodeGenerationOptions({
    required this.includeTokens,
    required this.componentize,
    required this.useAsmbliDesignSystem,
    this.targetFramework,
    required this.responsiveBreakpoints,
    required this.accessibility,
    required this.darkModeSupport,
  });

  factory CodeGenerationOptions.withDefaults() {
    return const CodeGenerationOptions(
      includeTokens: true,
      componentize: true,
      useAsmbliDesignSystem: true,
      targetFramework: TargetFramework.material3,
      responsiveBreakpoints: false,
      accessibility: true,
      darkModeSupport: false,
    );
  }

  factory CodeGenerationOptions.responsive() {
    return const CodeGenerationOptions(
      includeTokens: true,
      componentize: true,
      useAsmbliDesignSystem: true,
      targetFramework: TargetFramework.material3,
      responsiveBreakpoints: true,
      accessibility: true,
      darkModeSupport: false,
    );
  }

  factory CodeGenerationOptions.production() {
    return const CodeGenerationOptions(
      includeTokens: true,
      componentize: true,
      useAsmbliDesignSystem: true,
      targetFramework: TargetFramework.material3,
      responsiveBreakpoints: true,
      accessibility: true,
      darkModeSupport: true,
    );
  }

  @override
  int get hashCode {
    return Object.hash(
      includeTokens,
      componentize,
      useAsmbliDesignSystem,
      targetFramework,
      responsiveBreakpoints,
      accessibility,
      darkModeSupport,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CodeGenerationOptions &&
        other.includeTokens == includeTokens &&
        other.componentize == componentize &&
        other.useAsmbliDesignSystem == useAsmbliDesignSystem &&
        other.targetFramework == targetFramework &&
        other.responsiveBreakpoints == responsiveBreakpoints &&
        other.accessibility == accessibility &&
        other.darkModeSupport == darkModeSupport;
  }
}

/// Supported code formats
enum CodeFormat {
  flutter,
  react,
  html,
  swiftui,
}

/// Target frameworks for code generation
enum TargetFramework {
  material3,
  cupertino,
  custom,
}

/// Code generation exception
class CodeGenerationException implements Exception {
  final String message;
  final String? canvasId;
  final CodeFormat? format;

  CodeGenerationException(this.message, {this.canvasId, this.format});

  @override
  String toString() {
    return 'CodeGenerationException: $message${canvasId != null ? ' (canvas: $canvasId)' : ''}${format != null ? ' (format: ${format!.name})' : ''}';
  }
}
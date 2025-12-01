import 'package:flutter/foundation.dart';
import '../models/artifact.dart';

/// Result of parsing a message for artifacts
class ParsedMessageContent {
  /// The message text with artifact tags removed
  final String cleanedText;

  /// List of artifacts extracted from the message
  final List<Artifact> artifacts;

  const ParsedMessageContent({
    required this.cleanedText,
    required this.artifacts,
  });
}

/// Service for parsing artifacts from LLM responses
///
/// Artifacts are denoted by XML-style tags in the LLM response:
/// ```
/// <artifact type="code" language="dart" title="Hello World">
/// void main() {
///   print('Hello, World!');
/// }
/// </artifact>
/// ```
class ArtifactParserService {
  /// Parse a message and extract any artifacts
  ///
  /// Returns the cleaned message text and list of extracted artifacts
  ParsedMessageContent parseMessage({
    required String messageContent,
    required String conversationId,
    required String messageId,
  }) {
    final artifacts = <Artifact>[];
    var cleanedText = messageContent;

    // Regular expression to match artifact tags
    // Matches: <artifact type="..." language="..." title="...">content</artifact>
    final artifactRegex = RegExp(
      r'<artifact\s+([^>]+)>(.*?)</artifact>',
      multiLine: true,
      dotAll: true,
    );

    final matches = artifactRegex.allMatches(messageContent);

    for (final match in matches) {
      try {
        final attributesStr = match.group(1)!;
        final content = match.group(2)!.trim();

        // Parse attributes
        final attributes = _parseAttributes(attributesStr);

        // Determine artifact type
        final typeStr = attributes['type'] ?? 'code';
        final type = _parseArtifactType(typeStr);

        // Extract other attributes
        final title = attributes['title'] ?? _getDefaultTitle(type);
        final language = attributes['language'];
        final id = attributes['id'] ?? _generateArtifactId(conversationId, messageId, artifacts.length);

        // Create artifact
        final artifact = Artifact(
          id: id,
          conversationId: conversationId,
          messageId: messageId,
          type: type,
          title: title,
          content: content,
          language: language,
          metadata: attributes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        artifacts.add(artifact);

        // Remove artifact tag from cleaned text, leave a placeholder
        cleanedText = cleanedText.replaceFirst(
          match.group(0)!,
          '\n[${type.icon} ${type.displayName}: $title]\n',
        );

        debugPrint('📦 Parsed artifact: ${artifact.title} (${artifact.type.name})');
      } catch (e) {
        debugPrint('❌ Failed to parse artifact: $e');
      }
    }

    return ParsedMessageContent(
      cleanedText: cleanedText.trim(),
      artifacts: artifacts,
    );
  }

  /// Parse attribute string like: type="code" language="dart" title="Example"
  Map<String, String> _parseAttributes(String attributesStr) {
    final attributes = <String, String>{};

    // Match attribute="value" or attribute='value'
    final attrRegex = RegExp(r'(\w+)=["\047](.*?)["\047]');
    final matches = attrRegex.allMatches(attributesStr);

    for (final match in matches) {
      final key = match.group(1)!;
      final value = match.group(2)!;
      attributes[key] = value;
    }

    return attributes;
  }

  /// Parse artifact type from string
  ArtifactType _parseArtifactType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'code':
        return ArtifactType.code;
      case 'diagram':
      case 'mermaid':
        return ArtifactType.diagram;
      case 'widget':
      case 'interactive':
        return ArtifactType.widget;
      case 'document':
      case 'doc':
      case 'markdown':
      case 'md':
        return ArtifactType.document;
      case 'visualization':
      case 'chart':
      case 'graph':
        return ArtifactType.visualization;
      case 'image':
      case 'img':
        return ArtifactType.image;
      case 'web':
      case 'html':
        return ArtifactType.webPreview;
      default:
        return ArtifactType.code;
    }
  }

  /// Get default title for artifact type
  String _getDefaultTitle(ArtifactType type) {
    return '${type.displayName} ${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate unique artifact ID
  String _generateArtifactId(String conversationId, String messageId, int index) {
    return 'artifact_${conversationId}_${messageId}_$index';
  }

  /// Generate system prompt to teach LLM how to create artifacts
  ///
  /// This should be included in the system prompt when artifacts are enabled
  static String get systemPromptAddition => '''

# Artifact System

You can create interactive artifacts that appear as separate windows in the workspace. Use artifact tags to generate structured content:

## Supported Artifact Types

1. **Code**: Interactive code editor with syntax highlighting
   ```xml
   <artifact type="code" language="dart" title="Hello World Example">
   void main() {
     print('Hello, World!');
   }
   </artifact>
   ```

2. **Diagram**: Mermaid diagrams and flowcharts
   ```xml
   <artifact type="diagram" title="System Architecture">
   graph TD
     A[Client] --> B[Server]
     B --> C[Database]
   </artifact>
   ```

3. **Document**: Rich text markdown documents
   ```xml
   <artifact type="document" title="Project Plan">
   # Project Overview

   This is a markdown document...
   </artifact>
   ```

4. **Widget**: Interactive mini-applications
   ```xml
   <artifact type="widget" title="Calculator">
   <!-- Widget code here -->
   </artifact>
   ```

5. **Visualization**: Charts and data visualizations
   ```xml
   <artifact type="visualization" title="Sales Chart">
   <!-- Chart data/config here -->
   </artifact>
   ```

## When to Use Artifacts

Use artifacts when:
- Creating code examples that users might want to edit or run
- Generating diagrams or visual representations
- Building interactive tools or calculators
- Creating documents that should be separately viewable
- Showing data visualizations

## When NOT to Use Artifacts

Don't use artifacts for:
- Simple code snippets in conversation (use markdown code blocks instead)
- Short examples that don't benefit from interaction
- Content that's integral to understanding the conversation flow

Artifacts appear as separate windows that can be moved, resized, and minimized, creating an OS-like workspace experience.
''';
}

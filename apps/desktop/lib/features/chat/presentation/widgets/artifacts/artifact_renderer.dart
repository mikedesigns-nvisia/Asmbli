import 'package:flutter/material.dart';
import '../../../../../core/models/artifact.dart';
import 'code_editor_artifact.dart';
import 'artifact_window.dart';

/// Factory for rendering artifacts based on their type
class ArtifactRenderer {
  /// Build the appropriate widget for an artifact
  static Widget build(Artifact artifact) {
    final content = _buildArtifactContent(artifact);

    return ArtifactWindow(
      artifact: artifact,
      child: content,
    );
  }

  /// Build the artifact content based on type
  static Widget _buildArtifactContent(Artifact artifact) {
    switch (artifact.type) {
      case ArtifactType.code:
        return CodeEditorArtifact(artifact: artifact);

      case ArtifactType.diagram:
        return _DiagramArtifactPlaceholder(artifact: artifact);

      case ArtifactType.widget:
        return _WidgetArtifactPlaceholder(artifact: artifact);

      case ArtifactType.document:
        return _DocumentArtifactPlaceholder(artifact: artifact);

      case ArtifactType.visualization:
        return _VisualizationArtifactPlaceholder(artifact: artifact);

      case ArtifactType.image:
        return _ImageArtifactPlaceholder(artifact: artifact);

      case ArtifactType.webPreview:
        return _WebPreviewArtifactPlaceholder(artifact: artifact);
    }
  }
}

// Placeholder widgets for artifact types not yet implemented
class _DiagramArtifactPlaceholder extends StatelessWidget {
  final Artifact artifact;

  const _DiagramArtifactPlaceholder({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderWidget(
      icon: artifact.type.icon,
      title: 'Diagram Artifact',
      description: 'Mermaid diagram rendering coming soon',
    );
  }
}

class _WidgetArtifactPlaceholder extends StatelessWidget {
  final Artifact artifact;

  const _WidgetArtifactPlaceholder({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderWidget(
      icon: artifact.type.icon,
      title: 'Interactive Widget',
      description: 'Interactive widget rendering coming soon',
    );
  }
}

class _DocumentArtifactPlaceholder extends StatelessWidget {
  final Artifact artifact;

  const _DocumentArtifactPlaceholder({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderWidget(
      icon: artifact.type.icon,
      title: 'Document',
      description: 'Markdown document rendering coming soon',
    );
  }
}

class _VisualizationArtifactPlaceholder extends StatelessWidget {
  final Artifact artifact;

  const _VisualizationArtifactPlaceholder({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderWidget(
      icon: artifact.type.icon,
      title: 'Visualization',
      description: 'Data visualization rendering coming soon',
    );
  }
}

class _ImageArtifactPlaceholder extends StatelessWidget {
  final Artifact artifact;

  const _ImageArtifactPlaceholder({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderWidget(
      icon: artifact.type.icon,
      title: 'Image',
      description: 'Image rendering coming soon',
    );
  }
}

class _WebPreviewArtifactPlaceholder extends StatelessWidget {
  final Artifact artifact;

  const _WebPreviewArtifactPlaceholder({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderWidget(
      icon: artifact.type.icon,
      title: 'Web Preview',
      description: 'HTML/Web preview coming soon',
    );
  }
}

class _PlaceholderWidget extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _PlaceholderWidget({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

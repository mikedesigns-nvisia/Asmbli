import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../providers/artifact_provider.dart';
import '../../../../../providers/conversation_provider.dart';
import 'artifact_renderer.dart';

/// OS-style workspace overlay that displays artifact windows
class ArtifactWorkspace extends ConsumerWidget {
  const ArtifactWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConversationId = ref.watch(selectedConversationIdProvider);

    if (selectedConversationId == null) {
      return const SizedBox.shrink();
    }

    final visibleArtifacts = ref.watch(
      visibleConversationArtifactsProvider(selectedConversationId),
    );

    if (visibleArtifacts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: visibleArtifacts.map((artifact) {
        return ArtifactRenderer.build(artifact);
      }).toList(),
    );
  }
}

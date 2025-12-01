import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/artifact.dart';

/// State notifier for managing artifacts in a conversation
class ArtifactNotifier extends StateNotifier<Map<String, Artifact>> {
  ArtifactNotifier() : super({});

  /// Add a new artifact
  void addArtifact(Artifact artifact) {
    state = {
      ...state,
      artifact.id: artifact,
    };
    debugPrint('📦 Added artifact: ${artifact.title} (${artifact.id})');
  }

  /// Add multiple artifacts
  void addArtifacts(List<Artifact> artifacts) {
    final newState = Map<String, Artifact>.from(state);
    for (final artifact in artifacts) {
      newState[artifact.id] = artifact;
      debugPrint('📦 Added artifact: ${artifact.title} (${artifact.id})');
    }
    state = newState;
  }

  /// Update an existing artifact
  void updateArtifact(String id, Artifact updatedArtifact) {
    if (state.containsKey(id)) {
      state = {
        ...state,
        id: updatedArtifact.copyWith(updatedAt: DateTime.now()),
      };
      debugPrint('📝 Updated artifact: ${updatedArtifact.title}');
    }
  }

  /// Update artifact content
  void updateArtifactContent(String id, String newContent) {
    final artifact = state[id];
    if (artifact != null) {
      state = {
        ...state,
        id: artifact.copyWith(
          content: newContent,
          updatedAt: DateTime.now(),
        ),
      };
      debugPrint('📝 Updated artifact content: ${artifact.title}');
    }
  }

  /// Update artifact geometry (position, size)
  void updateArtifactGeometry(String id, ArtifactWindowGeometry geometry) {
    final artifact = state[id];
    if (artifact != null) {
      state = {
        ...state,
        id: artifact.copyWith(geometry: geometry),
      };
    }
  }

  /// Toggle artifact visibility
  void toggleArtifactVisibility(String id) {
    final artifact = state[id];
    if (artifact != null) {
      state = {
        ...state,
        id: artifact.copyWith(isVisible: !artifact.isVisible),
      };
      debugPrint('👁️ Toggled artifact visibility: ${artifact.title} -> ${!artifact.isVisible}');
    }
  }

  /// Show artifact
  void showArtifact(String id) {
    final artifact = state[id];
    if (artifact != null && !artifact.isVisible) {
      state = {
        ...state,
        id: artifact.copyWith(isVisible: true),
      };
      debugPrint('👁️ Showed artifact: ${artifact.title}');
    }
  }

  /// Hide artifact
  void hideArtifact(String id) {
    final artifact = state[id];
    if (artifact != null && artifact.isVisible) {
      state = {
        ...state,
        id: artifact.copyWith(isVisible: false),
      };
      debugPrint('👁️ Hid artifact: ${artifact.title}');
    }
  }

  /// Minimize artifact
  void minimizeArtifact(String id) {
    final artifact = state[id];
    if (artifact != null) {
      final newGeometry = artifact.geometry.copyWith(isMinimized: true, isMaximized: false);
      state = {
        ...state,
        id: artifact.copyWith(geometry: newGeometry),
      };
      debugPrint('🗕 Minimized artifact: ${artifact.title}');
    }
  }

  /// Maximize artifact
  void maximizeArtifact(String id) {
    final artifact = state[id];
    if (artifact != null) {
      final newGeometry = artifact.geometry.copyWith(isMaximized: true, isMinimized: false);
      state = {
        ...state,
        id: artifact.copyWith(geometry: newGeometry),
      };
      debugPrint('🗖 Maximized artifact: ${artifact.title}');
    }
  }

  /// Restore artifact (un-minimize/un-maximize)
  void restoreArtifact(String id) {
    final artifact = state[id];
    if (artifact != null) {
      final newGeometry = artifact.geometry.copyWith(isMinimized: false, isMaximized: false);
      state = {
        ...state,
        id: artifact.copyWith(geometry: newGeometry),
      };
      debugPrint('🗗 Restored artifact: ${artifact.title}');
    }
  }

  /// Remove an artifact
  void removeArtifact(String id) {
    final artifact = state[id];
    if (artifact != null) {
      state = Map.from(state)..remove(id);
      debugPrint('🗑️ Removed artifact: ${artifact.title}');
    }
  }

  /// Clear all artifacts
  void clearArtifacts() {
    state = {};
    debugPrint('🗑️ Cleared all artifacts');
  }

  /// Get artifacts for a specific conversation
  List<Artifact> getArtifactsForConversation(String conversationId) {
    return state.values
        .where((artifact) => artifact.conversationId == conversationId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  /// Get visible artifacts for a specific conversation
  List<Artifact> getVisibleArtifactsForConversation(String conversationId) {
    return state.values
        .where((artifact) =>
          artifact.conversationId == conversationId &&
          artifact.isVisible
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

/// Provider for artifact management
final artifactProvider = StateNotifierProvider<ArtifactNotifier, Map<String, Artifact>>((ref) {
  return ArtifactNotifier();
});

/// Provider to get all artifacts for a specific conversation
final conversationArtifactsProvider = Provider.family<List<Artifact>, String>((ref, conversationId) {
  final artifacts = ref.watch(artifactProvider);
  return artifacts.values
      .where((artifact) => artifact.conversationId == conversationId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Provider to get visible artifacts for a specific conversation
final visibleConversationArtifactsProvider = Provider.family<List<Artifact>, String>((ref, conversationId) {
  final artifacts = ref.watch(artifactProvider);
  return artifacts.values
      .where((artifact) =>
        artifact.conversationId == conversationId &&
        artifact.isVisible &&
        !artifact.geometry.isMinimized
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Provider to get minimized artifacts for a specific conversation
final minimizedConversationArtifactsProvider = Provider.family<List<Artifact>, String>((ref, conversationId) {
  final artifacts = ref.watch(artifactProvider);
  return artifacts.values
      .where((artifact) =>
        artifact.conversationId == conversationId &&
        artifact.isVisible &&
        artifact.geometry.isMinimized
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

/// Provider to get a specific artifact by ID
final artifactByIdProvider = Provider.family<Artifact?, String>((ref, artifactId) {
  final artifacts = ref.watch(artifactProvider);
  return artifacts[artifactId];
});

/// Provider to check if there are any artifacts in a conversation
final hasArtifactsProvider = Provider.family<bool, String>((ref, conversationId) {
  final artifacts = ref.watch(conversationArtifactsProvider(conversationId));
  return artifacts.isNotEmpty;
});

/// Provider to count artifacts by type for a conversation
final artifactCountByTypeProvider = Provider.family<Map<ArtifactType, int>, String>((ref, conversationId) {
  final artifacts = ref.watch(conversationArtifactsProvider(conversationId));
  final counts = <ArtifactType, int>{};

  for (final artifact in artifacts) {
    counts[artifact.type] = (counts[artifact.type] ?? 0) + 1;
  }

  return counts;
});

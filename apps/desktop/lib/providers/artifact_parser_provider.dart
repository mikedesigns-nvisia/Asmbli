import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/artifact_parser_service.dart';
import '../providers/conversation_provider.dart';
import '../providers/artifact_provider.dart';

/// Provider for artifact parser service
final artifactParserServiceProvider = Provider<ArtifactParserService>((ref) {
  return ArtifactParserService();
});

/// Auto-parses artifacts from messages when they're added to conversations
/// This provider watches for new messages and extracts artifacts automatically
final artifactParseListenerProvider = Provider.family<void, String>((ref, conversationId) {
  final messages = ref.watch(messagesProvider(conversationId));
  final artifactNotifier = ref.watch(artifactProvider.notifier);
  final parserService = ref.watch(artifactParserServiceProvider);

  messages.whenData((messageList) {
    // Parse artifacts from assistant messages
    for (final message in messageList) {
      if (message.role.toString() == 'MessageRole.assistant' &&
          message.content.contains('<artifact')) {
        // Parse the message for artifacts
        final parsed = parserService.parseMessage(
          messageContent: message.content,
          conversationId: conversationId,
          messageId: message.id,
        );

        // Add any new artifacts to the state
        if (parsed.artifacts.isNotEmpty) {
          artifactNotifier.addArtifacts(parsed.artifacts);
        }
      }
    }
  });

  return null;
});

import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required String title,
    required List<Message> messages,
    required DateTime createdAt,
    DateTime? lastModified,
    @Default(ConversationStatus.active) ConversationStatus status,
    Map<String, dynamic>? metadata,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) => 
      _$ConversationFromJson(json);
}

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String content,
    required MessageRole role,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}

enum MessageRole {
  user,
  assistant,
  system
}

enum ConversationStatus {
  active,
  archived,
  deleted
}

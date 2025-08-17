import 'package:chatmcp/dao/chat.dart';
import 'package:chatmcp/dao/chat_message.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/repository/chat_repository.dart';
import 'package:chatmcp/config/pagination_config.dart';

class LocalChatRepository implements ChatRepository {
  final ChatDao _chatDao = ChatDao();
  final ChatMessageDao _chatMessageDao = ChatMessageDao();

  @override
  Future<ChatListResult> getChats({
    int page = 1, // 页码从 1 开始
    int pageSize = PaginationConfig.defaultPageSize,
    String? searchKeyword,
  }) async {
    // 转换为从 0 开始的 offset 计算
    final offset = (page - 1) * pageSize;

    // Build where clause for search
    String? whereClause;
    List<Object?>? whereArgs;

    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      whereClause = 'title LIKE ?';
      whereArgs = ['%$searchKeyword%'];
    }

    // Get total count
    final allChats = await _chatDao.query(where: whereClause, whereArgs: whereArgs);
    final total = allChats.length;

    // Get paginated results
    final chats = await _chatDao.query(where: whereClause, whereArgs: whereArgs, orderBy: 'updatedAt DESC', limit: pageSize, offset: offset);

    final hasMore = offset + pageSize < total;

    return ChatListResult(chats: chats, total: total, hasMore: hasMore);
  }

  @override
  Future<List<Chat>> getAllChats() async {
    return await _chatDao.query(orderBy: 'updatedAt DESC');
  }

  @override
  Future<Chat?> getChatById(int id) async {
    return await _chatDao.queryById(id.toString());
  }

  @override
  Future<Chat> createChat(Chat chat, List<ChatMessage> messages) async {
    final chatId = await _chatDao.insert(chat);
    final newChat = Chat(id: chatId, title: chat.title, createdAt: chat.createdAt, updatedAt: chat.updatedAt);

    if (messages.isNotEmpty) {
      await addChatMessage(chatId, messages);
    }

    return newChat;
  }

  @override
  Future<void> updateChat(Chat chat) async {
    if (chat.id != null) {
      await _chatDao.update(chat, chat.id.toString());
    }
  }

  @override
  Future<void> deleteChat(int id) async {
    await _chatMessageDao.deleteMessages(id);
    await _chatDao.delete(id.toString());
  }

  @override
  Future<void> addChatMessage(int chatId, List<ChatMessage> messages) async {
    for (final message in messages) {
      if (message.role == MessageRole.error) {
        continue;
      }
      final existingMessages = await _chatMessageDao.query(where: 'messageId = ?', whereArgs: [message.messageId]);
      if (existingMessages.isNotEmpty) {
        continue;
      }
      await _chatMessageDao.insert(message.toDb(chatId));
    }
  }

  @override
  Future<List<ChatMessage>> getChatMessages(int chatId) async {
    final chatMessages = await _chatMessageDao.query(where: 'chatId = ?', whereArgs: [chatId], orderBy: 'createdAt ASC');
    return chatMessages.map((e) => ChatMessage.fromDb(e)).toList();
  }
}

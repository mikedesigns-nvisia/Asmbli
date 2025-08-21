import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:agent_engine_core/models/conversation.dart';
import 'package:agent_engine_core/services/conversation_service.dart';

class TestSqliteConversationService implements ConversationService {
  late Database _db;
  final String dbPath;

  TestSqliteConversationService(this.dbPath);

  Future<void> initialize() async {
    final dbDir = Directory(path.dirname(dbPath));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    _db = sqlite3.open(dbPath);
    _db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<Conversation> createConversation(Conversation conversation) async {
    final existingStmt = _db.prepare(
      'SELECT COUNT(*) as count FROM conversations WHERE id = ?',
    );
    final count = existingStmt.select([conversation.id]).first['count'] as int;
    existingStmt.dispose();

    if (count > 0) {
      throw Exception('Conversation with id ${conversation.id} already exists');
    }

    final stmt = _db.prepare(
      'INSERT INTO conversations (id, data) VALUES (?, ?)',
    );
    stmt.execute([
      conversation.id,
      jsonEncode(conversation.toJson()),
    ]);
    stmt.dispose();
    return conversation;
  }

  @override
  Future<Conversation> getConversation(String id) async {
    final stmt = _db.prepare(
      'SELECT data FROM conversations WHERE id = ? LIMIT 1',
    );
    final result = stmt.select([id]);
    stmt.dispose();

    if (result.isEmpty) {
      throw Exception('Conversation not found');
    }

    return Conversation.fromJson(
      jsonDecode(result.first['data'] as String) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<Conversation>> listConversations() async {
    final stmt = _db.prepare('SELECT data FROM conversations');
    final results = stmt.select();
    stmt.dispose();

    return results.map((row) => 
      Conversation.fromJson(
        jsonDecode(row['data'] as String) as Map<String, dynamic>,
      )
    ).toList();
  }

  @override
  Future<Conversation> updateConversation(Conversation conversation) async {
    final checkStmt = _db.prepare(
      'SELECT COUNT(*) as count FROM conversations WHERE id = ?',
    );
    final count = checkStmt.select([conversation.id]).first['count'] as int;
    checkStmt.dispose();

    if (count == 0) {
      throw Exception('Conversation with id ${conversation.id} not found');
    }

    final updateStmt = _db.prepare(
      'UPDATE conversations SET data = ? WHERE id = ?',
    );
    updateStmt.execute([jsonEncode(conversation.toJson()), conversation.id]);
    updateStmt.dispose();

    return conversation;
  }

  @override
  Future<void> deleteConversation(String id) async {
    final stmt = _db.prepare('DELETE FROM conversations WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }

  @override
  Future<Message> addMessage(String conversationId, Message message) async {
    final conversation = await getConversation(conversationId);
    final updatedConversation = conversation.copyWith(
      messages: [...conversation.messages, message],
      lastModified: DateTime.now(),
    );
    await updateConversation(updatedConversation);
    return message;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final conversation = await getConversation(conversationId);
    return conversation.messages;
  }

  @override
  Future<void> setConversationStatus(
    String id, 
    ConversationStatus status,
  ) async {
    final conversation = await getConversation(id);
    final updatedConversation = conversation.copyWith(
      status: status,
      lastModified: DateTime.now(),
    );
    await updateConversation(updatedConversation);
  }

  Future<void> close() async {
    _db.dispose();
  }
}
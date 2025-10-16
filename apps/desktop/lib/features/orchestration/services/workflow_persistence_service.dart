import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../core/di/service_locator.dart';
import '../models/reasoning_workflow.dart';
import '../models/logic_block.dart';

/// Service for persisting reasoning workflows to local database
class WorkflowPersistenceService {
  static WorkflowPersistenceService? _instance;
  Database? _database;
  
  WorkflowPersistenceService._();
  
  static WorkflowPersistenceService get instance {
    _instance ??= WorkflowPersistenceService._();
    return _instance!;
  }

  /// Initialize the database
  Future<void> initialize() async {
    if (_database != null) return;

    // Initialize sqflite for desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Get app documents directory for database storage
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDir.path, 'Asmbli', 'workflows.db');
    
    // Ensure the directory exists
    final dbDir = Directory(path.dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Create workflows table
        await db.execute('''
          CREATE TABLE workflows (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            tags TEXT,
            blocks TEXT NOT NULL,
            connections TEXT NOT NULL,
            metadata TEXT,
            is_template INTEGER DEFAULT 0,
            is_shared INTEGER DEFAULT 0,
            created_by TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            version INTEGER DEFAULT 1
          )
        ''');

        // Create workflow_history table for versioning
        await db.execute('''
          CREATE TABLE workflow_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workflow_id TEXT NOT NULL,
            version INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            blocks TEXT NOT NULL,
            connections TEXT NOT NULL,
            metadata TEXT,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (workflow_id) REFERENCES workflows (id)
          )
        ''');

        // Create workflow_tags table for searchability
        await db.execute('''
          CREATE TABLE workflow_tags (
            workflow_id TEXT NOT NULL,
            tag TEXT NOT NULL,
            PRIMARY KEY (workflow_id, tag),
            FOREIGN KEY (workflow_id) REFERENCES workflows (id)
          )
        ''');

        // Create indices
        await db.execute('CREATE INDEX idx_workflows_created_at ON workflows (created_at DESC)');
        await db.execute('CREATE INDEX idx_workflows_updated_at ON workflows (updated_at DESC)');
        await db.execute('CREATE INDEX idx_workflows_is_template ON workflows (is_template)');
        await db.execute('CREATE INDEX idx_workflows_is_shared ON workflows (is_shared)');
        await db.execute('CREATE INDEX idx_workflow_tags_tag ON workflow_tags (tag)');
      },
    );
  }

  /// Save a workflow to the database
  Future<void> saveWorkflow(ReasoningWorkflow workflow, {String? createdBy}) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Serialize blocks and connections
    final blocksJson = workflow.blocks.map((block) => block.toJson()).toList();
    final connectionsJson = workflow.connections.map((conn) => conn.toJson()).toList();
    
    // Prepare workflow data
    final workflowData = {
      'id': workflow.id,
      'name': workflow.name,
      'description': workflow.description,
      'tags': workflow.tags.join(','),
      'blocks': jsonEncode(blocksJson),
      'connections': jsonEncode(connectionsJson),
      'metadata': jsonEncode(workflow.metadata ?? {}),
      'is_template': workflow.isTemplate ? 1 : 0,
      'is_shared': 0,
      'created_by': createdBy,
      'created_at': workflow.createdAt.millisecondsSinceEpoch,
      'updated_at': now,
      'version': 1,
    };

    await _database!.transaction((txn) async {
      // Check if workflow exists
      final existing = await txn.query(
        'workflows',
        where: 'id = ?',
        whereArgs: [workflow.id],
      );

      if (existing.isNotEmpty) {
        // Update existing workflow
        final currentVersion = existing.first['version'] as int;
        workflowData['version'] = currentVersion + 1;
        workflowData['created_at'] = existing.first['created_at'];
        
        // Save to history
        await txn.insert('workflow_history', {
          'workflow_id': workflow.id,
          'version': currentVersion,
          'name': existing.first['name'],
          'description': existing.first['description'],
          'blocks': existing.first['blocks'],
          'connections': existing.first['connections'],
          'metadata': existing.first['metadata'],
          'created_at': now,
        });

        // Update workflow
        await txn.update(
          'workflows',
          workflowData,
          where: 'id = ?',
          whereArgs: [workflow.id],
        );
      } else {
        // Insert new workflow
        await txn.insert('workflows', workflowData);
      }

      // Update tags
      await txn.delete(
        'workflow_tags',
        where: 'workflow_id = ?',
        whereArgs: [workflow.id],
      );

      for (final tag in workflow.tags) {
        await txn.insert('workflow_tags', {
          'workflow_id': workflow.id,
          'tag': tag,
        });
      }
    });
  }

  /// Load a workflow by ID
  Future<ReasoningWorkflow?> loadWorkflow(String workflowId) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }

    final results = await _database!.query(
      'workflows',
      where: 'id = ?',
      whereArgs: [workflowId],
    );

    if (results.isEmpty) {
      return null;
    }

    return _workflowFromMap(results.first);
  }

  /// Load all workflows
  Future<List<ReasoningWorkflow>> loadAllWorkflows({
    bool includeTemplates = true,
    bool includeShared = false,
    String? createdBy,
    List<String>? tags,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }

    String query = 'SELECT DISTINCT w.* FROM workflows w';
    List<String> conditions = [];
    List<dynamic> args = [];

    // Join with tags if filtering by tags
    if (tags != null && tags.isNotEmpty) {
      query += ' INNER JOIN workflow_tags t ON w.id = t.workflow_id';
      conditions.add('t.tag IN (${tags.map((_) => '?').join(',')})');
      args.addAll(tags);
    }

    // Add conditions
    if (!includeTemplates) {
      conditions.add('w.is_template = 0');
    }
    
    if (!includeShared) {
      conditions.add('w.is_shared = 0');
    }

    if (createdBy != null) {
      conditions.add('w.created_by = ?');
      args.add(createdBy);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(w.name LIKE ? OR w.description LIKE ?)');
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
    }

    // Build WHERE clause
    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }

    // Add ordering
    query += ' ORDER BY w.updated_at DESC';

    // Add pagination
    if (limit != null) {
      query += ' LIMIT $limit';
      if (offset != null) {
        query += ' OFFSET $offset';
      }
    }

    final results = await _database!.rawQuery(query, args);
    
    final workflows = <ReasoningWorkflow>[];
    for (final row in results) {
      final workflow = await _workflowFromMap(row);
      if (workflow != null) {
        workflows.add(workflow);
      }
    }

    return workflows;
  }

  /// Delete a workflow
  Future<void> deleteWorkflow(String workflowId) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }

    await _database!.transaction((txn) async {
      // Delete tags
      await txn.delete(
        'workflow_tags',
        where: 'workflow_id = ?',
        whereArgs: [workflowId],
      );

      // Delete history
      await txn.delete(
        'workflow_history',
        where: 'workflow_id = ?',
        whereArgs: [workflowId],
      );

      // Delete workflow
      await txn.delete(
        'workflows',
        where: 'id = ?',
        whereArgs: [workflowId],
      );
    });
  }

  /// Duplicate a workflow
  Future<ReasoningWorkflow> duplicateWorkflow(String workflowId, {String? newName}) async {
    final original = await loadWorkflow(workflowId);
    if (original == null) {
      throw Exception('Workflow not found');
    }

    final duplicate = ReasoningWorkflow(
      id: 'workflow_${DateTime.now().millisecondsSinceEpoch}',
      name: newName ?? '${original.name} (Copy)',
      description: original.description,
      blocks: original.blocks.map((block) => LogicBlock(
        id: '${block.id}_copy',
        type: block.type,
        label: block.label,
        position: Position(x: block.position.x + 20, y: block.position.y + 20),
        properties: Map.from(block.properties),
        mcpToolIds: List.from(block.mcpToolIds),
      )).toList(),
      connections: original.connections.map((conn) => BlockConnection(
        id: '${conn.id}_copy',
        sourceBlockId: '${conn.sourceBlockId}_copy',
        targetBlockId: '${conn.targetBlockId}_copy',
        sourcePin: conn.sourcePin,
        targetPin: conn.targetPin,
        type: conn.type,
      )).toList(),
      tags: List.from(original.tags),
      isTemplate: false,
      metadata: Map.from(original.metadata ?? {}),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveWorkflow(duplicate);
    return duplicate;
  }

  /// Get workflow history
  Future<List<Map<String, dynamic>>> getWorkflowHistory(String workflowId) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }

    final results = await _database!.query(
      'workflow_history',
      where: 'workflow_id = ?',
      whereArgs: [workflowId],
      orderBy: 'version DESC',
    );

    return results.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Export workflow as JSON
  Future<String> exportWorkflowAsJson(String workflowId) async {
    final workflow = await loadWorkflow(workflowId);
    if (workflow == null) {
      throw Exception('Workflow not found');
    }

    final exportData = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'workflow': workflow.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Import workflow from JSON
  Future<ReasoningWorkflow> importWorkflowFromJson(String jsonData) async {
    final data = jsonDecode(jsonData);
    final workflowData = data['workflow'];
    
    // Generate new ID to avoid conflicts
    workflowData['id'] = 'workflow_${DateTime.now().millisecondsSinceEpoch}';
    workflowData['createdAt'] = DateTime.now().toIso8601String();
    workflowData['updatedAt'] = DateTime.now().toIso8601String();

    final workflow = ReasoningWorkflow.fromJson(workflowData);
    await saveWorkflow(workflow);

    return workflow;
  }

  /// Convert database row to workflow
  Future<ReasoningWorkflow?> _workflowFromMap(Map<String, dynamic> map) async {
    try {
      final blocksJson = jsonDecode(map['blocks'] as String) as List;
      final connectionsJson = jsonDecode(map['connections'] as String) as List;
      
      final blocks = blocksJson.map((json) => LogicBlock.fromJson(json)).toList();
      final connections = connectionsJson.map((json) => BlockConnection.fromJson(json)).toList();
      
      final tags = (map['tags'] as String? ?? '').split(',').where((tag) => tag.isNotEmpty).toList();
      
      Map<String, dynamic>? metadata;
      if (map['metadata'] != null) {
        metadata = jsonDecode(map['metadata'] as String);
      }

      return ReasoningWorkflow(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        blocks: blocks,
        connections: connections,
        tags: tags,
        isTemplate: (map['is_template'] as int) == 1,
        metadata: metadata,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
    } catch (e) {
      print('Error parsing workflow from database: $e');
      return null;
    }
  }

  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
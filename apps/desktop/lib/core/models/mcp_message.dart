import 'dart:convert';
import 'package:equatable/equatable.dart';

/// MCP JSON-RPC 2.0 message model
class MCPMessage extends Equatable {
  final String jsonrpc;
  final dynamic id;
  final String? method;
  final Map<String, dynamic>? params;
  final Map<String, dynamic>? result;
  final MCPError? error;

  const MCPMessage({
    this.jsonrpc = '2.0',
    this.id,
    this.method,
    this.params,
    this.result,
    this.error,
  });

  /// Create request message
  factory MCPMessage.request({
    required dynamic id,
    required String method,
    Map<String, dynamic>? params,
  }) {
    return MCPMessage(
      id: id,
      method: method,
      params: params,
    );
  }

  /// Create notification message
  factory MCPMessage.notification({
    required String method,
    Map<String, dynamic>? params,
  }) {
    return MCPMessage(
      method: method,
      params: params,
    );
  }

  /// Create response message
  factory MCPMessage.response({
    required dynamic id,
    Map<String, dynamic>? result,
  }) {
    return MCPMessage(
      id: id,
      result: result,
    );
  }

  /// Create error response message
  factory MCPMessage.error({
    required dynamic id,
    required int code,
    required String message,
    dynamic data,
  }) {
    return MCPMessage(
      id: id,
      error: MCPError(
        code: code,
        message: message,
        data: data,
      ),
    );
  }

  /// Create from JSON
  factory MCPMessage.fromJson(Map<String, dynamic> json) {
    return MCPMessage(
      jsonrpc: json['jsonrpc'] ?? '2.0',
      id: json['id'],
      method: json['method'],
      params: json['params'] != null 
          ? Map<String, dynamic>.from(json['params']) 
          : null,
      result: json['result'] != null 
          ? Map<String, dynamic>.from(json['result']) 
          : null,
      error: json['error'] != null 
          ? MCPError.fromJson(json['error']) 
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'jsonrpc': jsonrpc,
    };

    if (id != null) json['id'] = id;
    if (method != null) json['method'] = method;
    if (params != null) json['params'] = params;
    if (result != null) json['result'] = result;
    if (error != null) json['error'] = error!.toJson();

    return json;
  }

  /// Check if this is a request
  bool get isRequest => method != null && id != null;

  /// Check if this is a notification
  bool get isNotification => method != null && id == null;

  /// Check if this is a response
  bool get isResponse => method == null && id != null && (result != null || error != null);

  /// Check if this is an error response
  bool get isError => error != null;

  /// Get JSON string representation
  String toJsonString() {
    return json.encode(toJson());
  }

  @override
  List<Object?> get props => [jsonrpc, id, method, params, result, error];
}

/// MCP JSON-RPC error
class MCPError extends Equatable {
  final int code;
  final String message;
  final dynamic data;

  const MCPError({
    required this.code,
    required this.message,
    this.data,
  });

  factory MCPError.fromJson(Map<String, dynamic> json) {
    return MCPError(
      code: json['code'],
      message: json['message'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'code': code,
      'message': message,
    };
    if (data != null) json['data'] = data;
    return json;
  }

  @override
  List<Object?> get props => [code, message, data];
}

/// MCP Tool definition
class MCPTool extends Equatable {
  final String name;
  final String? description;
  final Map<String, dynamic>? inputSchema;

  const MCPTool({
    required this.name,
    this.description,
    this.inputSchema,
  });

  factory MCPTool.fromJson(Map<String, dynamic> json) {
    return MCPTool(
      name: json['name'],
      description: json['description'],
      inputSchema: json['inputSchema'] != null 
          ? Map<String, dynamic>.from(json['inputSchema'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (description != null) json['description'] = description;
    if (inputSchema != null) json['inputSchema'] = inputSchema;
    return json;
  }

  @override
  List<Object?> get props => [name, description, inputSchema];
}

/// MCP Tool call result
class MCPToolResult extends Equatable {
  final List<MCPContent> content;
  final bool? isError;

  const MCPToolResult({
    required this.content,
    this.isError,
  });

  factory MCPToolResult.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List? ?? [];
    return MCPToolResult(
      content: contentList.map((item) => MCPContent.fromJson(item)).toList(),
      isError: json['isError'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'content': content.map((c) => c.toJson()).toList(),
    };
    if (isError != null) json['isError'] = isError;
    return json;
  }

  @override
  List<Object?> get props => [content, isError];
}

/// MCP Resource definition
class MCPResource extends Equatable {
  final String uri;
  final String name;
  final String? description;
  final String? mimeType;

  const MCPResource({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType,
  });

  factory MCPResource.fromJson(Map<String, dynamic> json) {
    return MCPResource(
      uri: json['uri'],
      name: json['name'],
      description: json['description'],
      mimeType: json['mimeType'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'uri': uri,
      'name': name,
    };
    if (description != null) json['description'] = description;
    if (mimeType != null) json['mimeType'] = mimeType;
    return json;
  }

  @override
  List<Object?> get props => [uri, name, description, mimeType];
}

/// MCP Resource content
class MCPResourceContent extends Equatable {
  final List<MCPContent> contents;

  const MCPResourceContent({
    required this.contents,
  });

  factory MCPResourceContent.fromJson(Map<String, dynamic> json) {
    final contentList = json['contents'] as List? ?? [];
    return MCPResourceContent(
      contents: contentList.map((item) => MCPContent.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contents': contents.map((c) => c.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [contents];
}

/// MCP Prompt definition
class MCPPrompt extends Equatable {
  final String name;
  final String? description;
  final List<MCPPromptArgument>? arguments;

  const MCPPrompt({
    required this.name,
    this.description,
    this.arguments,
  });

  factory MCPPrompt.fromJson(Map<String, dynamic> json) {
    final argsList = json['arguments'] as List? ?? [];
    return MCPPrompt(
      name: json['name'],
      description: json['description'],
      arguments: argsList.map((arg) => MCPPromptArgument.fromJson(arg)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (description != null) json['description'] = description;
    if (arguments != null) json['arguments'] = arguments!.map((a) => a.toJson()).toList();
    return json;
  }

  @override
  List<Object?> get props => [name, description, arguments];
}

/// MCP Prompt argument
class MCPPromptArgument extends Equatable {
  final String name;
  final String? description;
  final bool required;

  const MCPPromptArgument({
    required this.name,
    this.description,
    this.required = false,
  });

  factory MCPPromptArgument.fromJson(Map<String, dynamic> json) {
    return MCPPromptArgument(
      name: json['name'],
      description: json['description'],
      required: json['required'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'required': required,
    };
    if (description != null) json['description'] = description;
    return json;
  }

  @override
  List<Object?> get props => [name, description, required];
}

/// MCP Prompt result
class MCPPromptResult extends Equatable {
  final String? description;
  final List<MCPPromptMessage> messages;

  const MCPPromptResult({
    this.description,
    required this.messages,
  });

  factory MCPPromptResult.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List? ?? [];
    return MCPPromptResult(
      description: json['description'],
      messages: messagesList.map((msg) => MCPPromptMessage.fromJson(msg)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'messages': messages.map((m) => m.toJson()).toList(),
    };
    if (description != null) json['description'] = description;
    return json;
  }

  @override
  List<Object?> get props => [description, messages];
}

/// MCP Prompt message
class MCPPromptMessage extends Equatable {
  final String role;
  final MCPContent content;

  const MCPPromptMessage({
    required this.role,
    required this.content,
  });

  factory MCPPromptMessage.fromJson(Map<String, dynamic> json) {
    return MCPPromptMessage(
      role: json['role'],
      content: MCPContent.fromJson(json['content']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content.toJson(),
    };
  }

  @override
  List<Object?> get props => [role, content];
}

/// MCP Content (text, image, resource, etc.)
class MCPContent extends Equatable {
  final String type;
  final String? text;
  final String? data;
  final String? mimeType;

  const MCPContent({
    required this.type,
    this.text,
    this.data,
    this.mimeType,
  });

  /// Create text content
  factory MCPContent.text(String text) {
    return MCPContent(type: 'text', text: text);
  }

  /// Create image content
  factory MCPContent.image(String data, String mimeType) {
    return MCPContent(type: 'image', data: data, mimeType: mimeType);
  }

  factory MCPContent.fromJson(Map<String, dynamic> json) {
    return MCPContent(
      type: json['type'],
      text: json['text'],
      data: json['data'],
      mimeType: json['mimeType'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
    };
    if (text != null) json['text'] = text;
    if (data != null) json['data'] = data;
    if (mimeType != null) json['mimeType'] = mimeType;
    return json;
  }

  @override
  List<Object?> get props => [type, text, data, mimeType];
}
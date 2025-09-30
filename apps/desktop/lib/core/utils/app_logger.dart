import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Production-ready logging system to replace debug prints
class AppLogger {
  static const String _name = 'AgentEngine';

  /// Log debug information (only in debug mode)
  static void debug(String message, {String? component}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: component != null ? '$_name.$component' : _name,
        level: 500, // Debug level
      );
    }
  }

  /// Log informational messages
  static void info(String message, {String? component}) {
    developer.log(
      message,
      name: component != null ? '$_name.$component' : _name,
      level: 800, // Info level
    );
  }

  /// Log warning messages
  static void warning(String message, {String? component, Object? error}) {
    developer.log(
      message,
      name: component != null ? '$_name.$component' : _name,
      error: error,
      level: 900, // Warning level
    );
  }

  /// Log error messages
  static void error(String message, {String? component, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: component != null ? '$_name.$component' : _name,
      error: error,
      stackTrace: stackTrace,
      level: 1000, // Error level
    );
  }

  /// Log critical errors that require immediate attention
  static void critical(String message, {String? component, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: component != null ? '$_name.$component' : _name,
      error: error,
      stackTrace: stackTrace,
      level: 1200, // Critical level
    );
  }

  /// Log MCP-specific operations
  static void mcp(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_name.MCP',
      error: error,
      stackTrace: stackTrace,
      level: error != null ? 1000 : 800,
    );
  }

  /// Log agent operations
  static void agent(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_name.Agent',
      error: error,
      stackTrace: stackTrace,
      level: error != null ? 1000 : 800,
    );
  }

  /// Log storage operations
  static void storage(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_name.Storage',
      error: error,
      stackTrace: stackTrace,
      level: error != null ? 1000 : 800,
    );
  }

  /// Log chat/conversation operations
  static void chat(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_name.Chat',
      error: error,
      stackTrace: stackTrace,
      level: error != null ? 1000 : 800,
    );
  }
}
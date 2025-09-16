import 'package:test/test.dart';
import '../../../lib/core/models/core_models.dart';

void main() {
  group('Core Models Tests', () {
    test('AgentTerminalConfig validation works correctly', () {
      // Valid config
      final validConfig = AgentTerminalConfig(
        agentId: 'test-agent',
        workingDirectory: '/tmp/test',
        securityContext: SecurityContext(
          agentId: 'test-agent',
          resourceLimits: const ResourceLimits(),
          terminalPermissions: const TerminalPermissions(),
        ),
        resourceLimits: const ResourceLimits(),
      );
      
      final validation = validConfig.validate();
      expect(validation.isValid, isTrue);
      expect(validation.errors, isEmpty);
    });

    test('AgentTerminalConfig serialization works correctly', () {
      final config = AgentTerminalConfig(
        agentId: 'test-agent',
        workingDirectory: '/tmp/test',
        environment: const {'TEST': 'value'},
        securityContext: SecurityContext(
          agentId: 'test-agent',
          resourceLimits: const ResourceLimits(),
          terminalPermissions: const TerminalPermissions(),
        ),
        resourceLimits: const ResourceLimits(),
      );
      
      final json = config.toJson();
      final restored = AgentTerminalConfig.fromJson(json);
      
      expect(restored.agentId, equals(config.agentId));
      expect(restored.workingDirectory, equals(config.workingDirectory));
      expect(restored.environment, equals(config.environment));
    });

    test('MCPServerConfig validation works correctly', () {
      const config = MCPServerConfig(
        id: 'test-server',
        name: 'Test Server',
        url: 'stdio://localhost',
        command: 'uvx',
        args: ['test-server'],
      );
      
      final validation = config.validate();
      expect(validation.isValid, isTrue);
      expect(validation.errors, isEmpty);
    });

    test('MCPServerConfig serialization works correctly', () {
      const config = MCPServerConfig(
        id: 'test-server',
        name: 'Test Server',
        url: 'stdio://localhost',
        command: 'uvx',
        args: ['test-server'],
        environment: {'TEST': 'value'},
      );
      
      final json = config.toJson();
      final restored = MCPServerConfig.fromJson(json);
      
      expect(restored.id, equals(config.id));
      expect(restored.name, equals(config.name));
      expect(restored.url, equals(config.url));
      expect(restored.environment, equals(config.environment));
    });

    test('MCPCatalogEntry serialization works correctly', () {
      const entry = MCPCatalogEntry(
        id: 'filesystem',
        name: 'Filesystem MCP Server',
        description: 'Provides file system access capabilities',
        command: 'uvx',
        args: ['mcp-server-filesystem'],
        transport: MCPTransportType.stdio,
        capabilities: ['read_file', 'write_file'],
        tags: ['filesystem', 'files'],
      );
      
      final json = entry.toJson();
      final restored = MCPCatalogEntry.fromJson(json);
      
      expect(restored.id, equals(entry.id));
      expect(restored.name, equals(entry.name));
      expect(restored.transport, equals(entry.transport));
      expect(restored.capabilities, equals(entry.capabilities));
    });

    test('CommandResult serialization works correctly', () {
      final result = CommandResult(
        command: 'ls -la',
        exitCode: 0,
        stdout: 'file1.txt\nfile2.txt',
        stderr: '',
        executionTime: const Duration(milliseconds: 100),
        timestamp: DateTime.now(),
        metadata: const {'test': 'value'},
      );
      
      final json = result.toJson();
      final restored = CommandResult.fromJson(json);
      
      expect(restored.command, equals(result.command));
      expect(restored.exitCode, equals(result.exitCode));
      expect(restored.stdout, equals(result.stdout));
      expect(restored.isSuccess, isTrue);
    });

    test('ValidationResult works correctly', () {
      const validResult = ValidationResult(isValid: true);
      expect(validResult.isValid, isTrue);
      expect(validResult.errors, isEmpty);
      
      const invalidResult = ValidationResult(
        isValid: false,
        errors: ['Error 1', 'Error 2'],
      );
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors, hasLength(2));
    });

    test('SecurityValidationResult serialization works correctly', () {
      const result = SecurityValidationResult(
        isAllowed: false,
        reason: 'Command not allowed',
        violations: ['dangerous_command'],
        recommendedAction: SecurityAction.deny,
      );
      
      final json = result.toJson();
      final restored = SecurityValidationResult.fromJson(json);
      
      expect(restored.isAllowed, equals(result.isAllowed));
      expect(restored.reason, equals(result.reason));
      expect(restored.violations, equals(result.violations));
      expect(restored.recommendedAction, equals(result.recommendedAction));
    });
  });
}
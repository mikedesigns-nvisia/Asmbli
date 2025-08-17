import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/agent_config.dart';
import '../models/extension.dart';
import 'extension_service.dart';

class AgentBuilderService {
  static const String _configsFileName = 'agent_configs.json';
  
  /// Save an agent configuration to local storage
  static Future<void> saveAgentConfig(AgentConfig config) async {
    final configs = await loadAllAgentConfigs();
    
    // Update existing or add new
    final existingIndex = configs.indexWhere((c) => c.agentName == config.agentName);
    if (existingIndex != -1) {
      configs[existingIndex] = config.copyWith(updatedAt: DateTime.now());
    } else {
      configs.add(config);
    }
    
    await _saveConfigsToFile(configs);
  }

  /// Load all saved agent configurations
  static Future<List<AgentConfig>> loadAllAgentConfigs() async {
    try {
      final file = await _getConfigsFile();
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => AgentConfig.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load agent configurations: $e');
    }
  }

  /// Delete an agent configuration
  static Future<void> deleteAgentConfig(String agentName) async {
    final configs = await loadAllAgentConfigs();
    configs.removeWhere((config) => config.agentName == agentName);
    await _saveConfigsToFile(configs);
  }

  /// Generate a complete ChatMCP package for an agent
  static Future<ChatMCPPackage> generateChatMCPPackage(AgentConfig config) async {
    final selectedExtensions = config.extensions.where((ext) => ext.enabled).toList();
    final chatmcpConfig = ExtensionService.generateChatMCPConfig(selectedExtensions, config);
    
    // Generate setup documentation
    final setupGuide = _generateSetupGuide(config, selectedExtensions);
    final environmentSetup = _generateEnvironmentSetup(selectedExtensions);
    final installScript = _generateInstallScript(selectedExtensions);
    
    return ChatMCPPackage(
      config: chatmcpConfig,
      setupGuide: setupGuide,
      environmentSetup: environmentSetup,
      installScript: installScript,
      agentConfig: config,
    );
  }

  /// Export ChatMCP package as files
  static Future<Map<String, String>> exportChatMCPPackage(ChatMCPPackage package) async {
    final files = <String, String>{};
    
    files['chatmcp-config.json'] = package.config.toJsonString();
    files['chatmcp-setup.md'] = package.setupGuide;
    files['environment-setup.md'] = package.environmentSetup;
    files['install-chatmcp.sh'] = package.installScript;
    files['install-chatmcp.bat'] = _generateWindowsInstallScript(package);
    
    return files;
  }

  /// Create a default agent configuration
  static AgentConfig createDefaultConfig() {
    return AgentConfig(
      agentName: '',
      agentDescription: '',
      primaryPurpose: '',
      role: AgentRole.assistant,
      targetEnvironment: TargetEnvironment.development,
      deploymentTargets: ['claude-desktop'],
      extensions: [],
      security: const SecurityConfig(
        permissions: [],
        vaultIntegration: 'none',
        auditLogging: false,
        rateLimiting: true,
        sessionTimeout: 3600,
      ),
      responseLength: 500,
      constraints: [],
      constraintDocs: {},
      deploymentFormat: DeploymentFormat.json,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Validate agent configuration
  static List<String> validateConfig(AgentConfig config) {
    final List<String> errors = [];
    
    if (config.agentName.isEmpty) {
      errors.add('Agent name is required');
    }
    
    if (config.agentDescription.isEmpty) {
      errors.add('Agent description is required');
    }
    
    if (config.primaryPurpose.isEmpty) {
      errors.add('Primary purpose is required');
    }
    
    if (config.extensions.where((ext) => ext.enabled).isEmpty) {
      errors.add('At least one extension must be selected');
    }
    
    // Validate extension configurations
    for (final extension in config.extensions.where((ext) => ext.enabled)) {
      final validationErrors = _validateExtensionConfig(extension);
      errors.addAll(validationErrors);
    }
    
    return errors;
  }

  /// Get file reference for configurations
  static Future<File> _getConfigsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_configsFileName');
  }

  /// Save configurations to file
  static Future<void> _saveConfigsToFile(List<AgentConfig> configs) async {
    final file = await _getConfigsFile();
    final jsonString = json.encode(configs.map((config) => config.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  /// Generate setup guide markdown
  static String _generateSetupGuide(AgentConfig config, List<Extension> extensions) {
    final buffer = StringBuffer();
    
    buffer.writeln('# ${config.agentName} - ChatMCP Setup Guide');
    buffer.writeln();
    buffer.writeln('## Overview');
    buffer.writeln(config.agentDescription);
    buffer.writeln('This agent uses ChatMCP with ${extensions.length} MCP servers.');
    buffer.writeln();
    
    buffer.writeln('## MCP Servers Included');
    for (final extension in extensions) {
      buffer.writeln('- **${extension.id.replaceAll('-mcp', '')}**: ${extension.description}');
    }
    buffer.writeln();
    
    buffer.writeln('## Quick Setup');
    buffer.writeln();
    buffer.writeln('### 1. Install ChatMCP');
    buffer.writeln('Download ChatMCP for your platform:');
    buffer.writeln('- **Windows**: [Download .exe](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-windows.exe)');
    buffer.writeln('- **macOS**: [Download .dmg](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-macos.dmg)');
    buffer.writeln('- **Linux**: [Download .AppImage](https://github.com/daodao97/chatmcp/releases/latest/download/chatmcp-linux.AppImage)');
    buffer.writeln();
    
    buffer.writeln('### 2. Install Dependencies');
    buffer.writeln('Run the provided installer script:');
    buffer.writeln('- **Unix/macOS**: `bash install-chatmcp.sh`');
    buffer.writeln('- **Windows**: `install-chatmcp.bat`');
    buffer.writeln();
    
    // Add environment variables if needed
    final envVars = extensions.where((ext) => ext.authMethod != 'none').map((ext) => ext.id).toList();
    if (envVars.isNotEmpty) {
      buffer.writeln('### 3. Configure Environment Variables');
      buffer.writeln('Set up the following API keys and environment variables:');
      for (final extension in extensions) {
        if (extension.authMethod == 'token') {
          buffer.writeln('- GITHUB_PERSONAL_ACCESS_TOKEN');
        } else if (extension.authMethod == 'credentials') {
          buffer.writeln('- POSTGRES_CONNECTION_STRING');
        }
      }
      buffer.writeln();
      buffer.writeln('See `environment-setup.md` for detailed instructions.');
      buffer.writeln();
    }
    
    buffer.writeln('### 4. Launch ChatMCP');
    buffer.writeln('1. Open ChatMCP application');
    buffer.writeln('2. Go to Settings and load the `chatmcp-config.json` file');
    buffer.writeln('3. Configure your LLM API keys (OpenAI, Anthropic, etc.)');
    buffer.writeln('4. Start chatting with your configured agent!');
    buffer.writeln();
    
    buffer.writeln('## Features');
    buffer.writeln('- Native MCP protocol support');
    buffer.writeln('- Cross-platform compatibility');
    buffer.writeln('- Local data synchronization');
    buffer.writeln('- Support for multiple LLM providers');
    buffer.writeln();
    
    buffer.writeln('## Support');
    buffer.writeln('- ChatMCP Documentation: https://github.com/daodao97/chatmcp');
    buffer.writeln('- MCP Protocol: https://modelcontextprotocol.io/');
    buffer.writeln('- AgentEngine: Your agent configuration system');
    buffer.writeln();
    
    buffer.writeln('Generated on ${DateTime.now().toString().split(' ')[0]} by AgentEngine ChatMCP');
    
    return buffer.toString();
  }

  /// Generate environment setup guide
  static String _generateEnvironmentSetup(List<Extension> extensions) {
    final buffer = StringBuffer();
    
    buffer.writeln('# Environment Setup Guide');
    buffer.writeln();
    
    for (final extension in extensions) {
      if (extension.authMethod != 'none') {
        buffer.writeln('## ${extension.name}');
        buffer.writeln(ExtensionService.getSetupInstructions(extension));
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }

  /// Generate install script
  static String _generateInstallScript(List<Extension> extensions) {
    final buffer = StringBuffer();
    
    buffer.writeln('#!/bin/bash');
    buffer.writeln('# ChatMCP Installation Script');
    buffer.writeln('# Generated by AgentEngine');
    buffer.writeln();
    buffer.writeln('echo "Installing ChatMCP dependencies..."');
    buffer.writeln();
    buffer.writeln('# Install uv (required for MCP servers)');
    buffer.writeln('curl -LsSf https://astral.sh/uv/install.sh | sh');
    buffer.writeln();
    buffer.writeln('# Install MCP servers');
    for (final extension in extensions.where((ext) => ext.connectionType == ConnectionType.mcp)) {
      final mapping = ExtensionService.generateMCPServerConfig(extension);
      buffer.writeln('echo "Installing ${extension.name}..."');
      buffer.writeln('uv tool install ${mapping.args.first}');
    }
    buffer.writeln();
    buffer.writeln('echo "Installation complete!"');
    buffer.writeln('echo "Please configure environment variables as described in environment-setup.md"');
    
    return buffer.toString();
  }

  /// Generate Windows install script
  static String _generateWindowsInstallScript(ChatMCPPackage package) {
    final buffer = StringBuffer();
    
    buffer.writeln('@echo off');
    buffer.writeln('REM ChatMCP Installation Script for Windows');
    buffer.writeln('REM Generated by AgentEngine');
    buffer.writeln();
    buffer.writeln('echo Installing ChatMCP dependencies...');
    buffer.writeln();
    buffer.writeln('REM Install uv (required for MCP servers)');
    buffer.writeln('powershell -c "irm https://astral.sh/uv/install.ps1 | iex"');
    buffer.writeln();
    buffer.writeln('REM Install MCP servers');
    
    for (final extension in package.agentConfig.extensions.where((ext) => ext.enabled && ext.connectionType == ConnectionType.mcp)) {
      final mapping = ExtensionService.generateMCPServerConfig(extension);
      buffer.writeln('echo Installing ${extension.name}...');
      buffer.writeln('uv tool install ${mapping.args.first}');
    }
    
    buffer.writeln();
    buffer.writeln('echo Installation complete!');
    buffer.writeln('echo Please configure environment variables as described in environment-setup.md');
    buffer.writeln('pause');
    
    return buffer.toString();
  }

  /// Validate extension configuration
  static List<String> _validateExtensionConfig(Extension extension) {
    final List<String> errors = [];
    
    if (extension.authMethod == 'token' && extension.id == 'github-mcp') {
      // Could add validation for token format, etc.
    }
    
    if (extension.authMethod == 'credentials' && extension.id == 'postgres-mcp') {
      // Could add validation for connection string format
    }
    
    return errors;
  }
}

class ChatMCPPackage {
  final ChatMCPConfig config;
  final String setupGuide;
  final String environmentSetup;
  final String installScript;
  final AgentConfig agentConfig;

  const ChatMCPPackage({
    required this.config,
    required this.setupGuide,
    required this.environmentSetup,
    required this.installScript,
    required this.agentConfig,
  });
}
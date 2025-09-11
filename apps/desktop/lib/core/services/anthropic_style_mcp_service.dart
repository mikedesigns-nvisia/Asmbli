import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcp_catalog_entry.dart';

/// Anthropic-style MCP service focused on safety, simplicity, and user value
class AnthropicStyleMCPService {
  
  /// Curated list of high-value, safety-vetted MCP servers
  /// Based on real MCP ecosystem research - only production-ready servers
  static final List<CuratedMCPServer> essentialServers = [
    // Tier 1: Official Anthropic Reference Servers (Highest Trust)
    CuratedMCPServer(
      id: 'filesystem',
      name: 'File System',
      description: 'Secure file operations with configurable access controls',
      category: MCPCategory.development,
      trustLevel: MCPTrustLevel.anthropicOfficial,
      valueProposition: 'Let AI read and write files in your project safely',
      setupComplexity: MCPSetupComplexity.oneClick,
      dataAccess: ['Local files in specified directories only'],
      capabilities: [
        'Read and write files',
        'Directory navigation',
        'File search within bounds',
      ],
      permissions: MCPPermissions.filesystemRestricted(),
      installCommand: 'npx -y @modelcontextprotocol/server-filesystem',
      npmPackage: '@modelcontextprotocol/server-filesystem',
      authRequired: false,
      isStdio: true,
    ),
    
    CuratedMCPServer(
      id: 'git',
      name: 'Git Repository',
      description: 'Tools to read, search, and manipulate Git repositories',
      category: MCPCategory.development,
      trustLevel: MCPTrustLevel.anthropicOfficial,
      valueProposition: 'Understand your Git history and make smart commits',
      setupComplexity: MCPSetupComplexity.oneClick,
      dataAccess: ['Git repository metadata', 'Commit history', 'Branch information'],
      capabilities: [
        'Read commit history',
        'Search repository',
        'Branch analysis',
      ],
      permissions: MCPPermissions.readOnly(),
      installCommand: 'uvx mcp-server-git',
      uvxPackage: 'mcp-server-git',
      authRequired: false,
      isStdio: true,
    ),

    CuratedMCPServer(
      id: 'fetch',
      name: 'Web Fetch',
      description: 'Web content fetching and conversion for efficient LLM usage',
      category: MCPCategory.information,
      trustLevel: MCPTrustLevel.anthropicOfficial,
      valueProposition: 'Browse the web and get current information',
      setupComplexity: MCPSetupComplexity.oneClick,
      dataAccess: ['Web page contents', 'HTTP responses'],
      capabilities: [
        'Fetch web pages',
        'Parse HTML content',
        'Get real-time information',
      ],
      permissions: MCPPermissions.networkOnly(),
      installCommand: 'npx -y @modelcontextprotocol/server-fetch',
      npmPackage: '@modelcontextprotocol/server-fetch',
      authRequired: false,
      isStdio: true,
    ),

    // Tier 2: Enterprise Production Servers (High Trust)
    CuratedMCPServer(
      id: 'github-official',
      name: 'GitHub',
      description: 'GitHub\'s official MCP Server with OAuth 2.1 + PKCE',
      category: MCPCategory.development,
      trustLevel: MCPTrustLevel.enterpriseVerified,
      valueProposition: 'Full GitHub integration with enterprise security',
      setupComplexity: MCPSetupComplexity.oauth,
      dataAccess: ['Repository access per OAuth scopes', 'Issues and PRs', 'Code scanning alerts'],
      capabilities: [
        'Repository management',
        'Issue and PR operations',
        'Code analysis with security scanning',
        'OAuth 2.1 + PKCE authentication',
      ],
      permissions: MCPPermissions.oauthScoped(),
      installCommand: 'Contact GitHub for enterprise setup',
      authRequired: true,
      isRemote: true,
      documentationUrl: 'https://github.blog/changelog/2025-09-04-remote-github-mcp-server-is-now-generally-available/',
    ),

    CuratedMCPServer(
      id: 'slack-enterprise',
      name: 'Slack',
      description: 'Enterprise Slack integration with workspace controls',
      category: MCPCategory.communication,
      trustLevel: MCPTrustLevel.enterpriseVerified,
      valueProposition: 'Send messages and read channels without leaving chat',
      setupComplexity: MCPSetupComplexity.oauth,
      dataAccess: ['Workspace messages per bot permissions', 'Channel metadata'],
      capabilities: [
        'Send messages to channels',
        'Read channel history',
        'File operations',
        'No workspace admin approval required',
      ],
      permissions: MCPPermissions.slackBot(),
      installCommand: 'Configure via Slack Bot OAuth',
      authRequired: true,
      isRemote: true,
      documentationUrl: 'https://github.com/wong2/awesome-mcp-servers',
    ),

    // Tier 3: Community Verified (Medium Trust)
    CuratedMCPServer(
      id: 'memory',
      name: 'Memory System',
      description: 'Knowledge graph-based persistent memory system',
      category: MCPCategory.productivity,
      trustLevel: MCPTrustLevel.anthropicOfficial,
      valueProposition: 'Remember important details across conversations',
      setupComplexity: MCPSetupComplexity.oneClick,
      dataAccess: ['Conversation memories', 'Knowledge graph data'],
      capabilities: [
        'Store conversation context',
        'Retrieve relevant memories',
        'Build knowledge graphs',
      ],
      permissions: MCPPermissions.memoryStorage(),
      installCommand: 'npx -y @modelcontextprotocol/server-memory',
      npmPackage: '@modelcontextprotocol/server-memory',
      authRequired: false,
      isStdio: true,
    ),

    CuratedMCPServer(
      id: 'sequential-thinking',
      name: 'Sequential Thinking',
      description: 'Dynamic and reflective problem-solving through thought sequences',
      category: MCPCategory.reasoning,
      trustLevel: MCPTrustLevel.anthropicOfficial,
      valueProposition: 'Enhanced reasoning for complex problems',
      setupComplexity: MCPSetupComplexity.oneClick,
      dataAccess: ['Thought sequences', 'Problem-solving steps'],
      capabilities: [
        'Multi-step reasoning',
        'Reflective thinking',
        'Problem decomposition',
      ],
      permissions: MCPPermissions.computation(),
      installCommand: 'npx -y @modelcontextprotocol/server-sequential-thinking',
      npmPackage: '@modelcontextprotocol/server-sequential-thinking',
      authRequired: false,
      isStdio: true,
    ),

    CuratedMCPServer(
      id: 'time',
      name: 'Time & Timezone',
      description: 'Time and timezone conversion capabilities',
      category: MCPCategory.utility,
      trustLevel: MCPTrustLevel.anthropicOfficial,
      valueProposition: 'Handle time zones and scheduling across locations',
      setupComplexity: MCPSetupComplexity.oneClick,
      dataAccess: ['System time', 'Timezone data'],
      capabilities: [
        'Timezone conversions',
        'Time calculations',
        'Scheduling assistance',
      ],
      permissions: MCPPermissions.timeAccess(),
      installCommand: 'uvx mcp-server-time',
      uvxPackage: 'mcp-server-time',
      authRequired: false,
      isStdio: true,
    ),
  ];

  /// Get servers appropriate for user's skill level
  static List<CuratedMCPServer> getRecommendedServers(UserExpertiseLevel level) {
    switch (level) {
      case UserExpertiseLevel.beginner:
        return essentialServers
            .where((s) => s.setupComplexity == MCPSetupComplexity.oneClick)
            .toList();
      
      case UserExpertiseLevel.intermediate:
        return essentialServers
            .where((s) => s.setupComplexity == MCPSetupComplexity.oneClick || 
                         s.setupComplexity == MCPSetupComplexity.minimal ||
                         s.setupComplexity == MCPSetupComplexity.guided)
            .toList();
            
      case UserExpertiseLevel.advanced:
        return essentialServers;
    }
  }

  /// Anthropic's safety-first connection process
  static Future<MCPConnectionResult> connectSafely(CuratedMCPServer server) async {
    // 1. Pre-connection safety check
    final safetyCheck = await _performSafetyAssessment(server);
    if (!safetyCheck.isSafe) {
      return MCPConnectionResult.blocked(reason: safetyCheck.reason);
    }

    // 2. Minimal permission request (start restrictive)
    final permissions = server.permissions.minimal();
    
    // 3. Clear user consent with specific capabilities
    final userConsent = await _requestUserConsent(server, permissions);
    if (!userConsent) {
      return MCPConnectionResult.cancelled();
    }

    // 4. Sandboxed connection attempt
    try {
      final connection = await _createSandboxedConnection(server, permissions);
      return MCPConnectionResult.success(connection);
    } catch (e) {
      return MCPConnectionResult.failed(error: e.toString());
    }
  }

  /// Anthropic would emphasize clear, immediate value
  static String getValueProposition(CuratedMCPServer server) {
    return "${server.valueProposition}\n\n"
           "This will help you: ${server.capabilities.take(2).join(', ')}";
  }

  // Private safety methods
  static Future<SafetyAssessment> _performSafetyAssessment(CuratedMCPServer server) async {
    // Check against Anthropic's safety guidelines
    return SafetyAssessment(
      isSafe: server.trustLevel == MCPTrustLevel.anthropicOfficial ||
              server.trustLevel == MCPTrustLevel.enterpriseVerified,
      reason: server.trustLevel == MCPTrustLevel.unknown 
          ? 'This server has not been verified by Anthropic' 
          : null,
    );
  }

  static Future<bool> _requestUserConsent(CuratedMCPServer server, MCPPermissions permissions) async {
    // Show clear, non-technical consent dialog
    // Focus on benefits and data usage
    return true; // Simplified for example
  }

  static Future<MCPConnection> _createSandboxedConnection(
    CuratedMCPServer server, 
    MCPPermissions permissions
  ) async {
    // Create restricted connection with only necessary permissions
    throw UnimplementedError('Sandbox implementation needed');
  }
}

/// Anthropic's approach to MCP server metadata
class CuratedMCPServer {
  final String id;
  final String name;
  final String description;
  final MCPCategory category;
  final MCPTrustLevel trustLevel;
  final String valueProposition; // Clear benefit statement
  final MCPSetupComplexity setupComplexity;
  final List<String> dataAccess; // What data it can see
  final List<String> capabilities; // What it can do
  final MCPPermissions permissions;
  final String installCommand; // Real installation command
  final String? npmPackage; // NPM package name if applicable
  final String? uvxPackage; // UVX package name if applicable
  final String? documentationUrl; // Official documentation
  final bool authRequired;
  final bool isStdio; // Whether uses stdio transport
  final bool isRemote; // Whether remote server

  const CuratedMCPServer({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.trustLevel,
    required this.valueProposition,
    required this.setupComplexity,
    required this.dataAccess,
    required this.capabilities,
    required this.permissions,
    required this.installCommand,
    this.npmPackage,
    this.uvxPackage,
    this.documentationUrl,
    this.authRequired = false,
    this.isStdio = false,
    this.isRemote = false,
  });
}

/// Anthropic's trust-based classification (based on real ecosystem)
enum MCPTrustLevel {
  anthropicOfficial,     // Built by Anthropic team (reference servers)
  enterpriseVerified,    // Major companies (GitHub, Slack, etc.)
  communityVerified,     // Community-vetted, safe
  experimental,          // Use with caution
  unknown,              // Not vetted
}

enum MCPCategory {
  development,
  productivity, 
  information,
  communication,
  reasoning,      // New: AI reasoning tools
  utility,        // New: System utilities
  creative,
}

enum MCPSetupComplexity {
  oneClick,      // npx/uvx command only
  oauth,         // OAuth authentication required  
  minimal,       // Simple API key
  guided,        // Wizard-driven setup
  advanced,      // Technical setup required
}

enum UserExpertiseLevel {
  beginner,
  intermediate,
  advanced,
}

/// Safety-focused permission system (based on real MCP capabilities)
class MCPPermissions {
  final Set<MCPPermission> allowed;
  final Set<MCPPermission> required;

  const MCPPermissions({
    required this.allowed,
    required this.required,
  });

  static MCPPermissions readOnly() => const MCPPermissions(
    allowed: {MCPPermission.read},
    required: {MCPPermission.read},
  );

  static MCPPermissions networkOnly() => const MCPPermissions(
    allowed: {MCPPermission.network},
    required: {MCPPermission.network},
  );

  static MCPPermissions filesystemRestricted() => const MCPPermissions(
    allowed: {MCPPermission.filesystem, MCPPermission.read, MCPPermission.write},
    required: {MCPPermission.filesystem},
  );

  static MCPPermissions memoryStorage() => const MCPPermissions(
    allowed: {MCPPermission.memory, MCPPermission.write},
    required: {MCPPermission.memory},
  );

  static MCPPermissions computation() => const MCPPermissions(
    allowed: {MCPPermission.computation},
    required: {MCPPermission.computation},
  );

  static MCPPermissions timeAccess() => const MCPPermissions(
    allowed: {MCPPermission.system},
    required: {MCPPermission.system},
  );

  static MCPPermissions oauthScoped() => const MCPPermissions(
    allowed: {MCPPermission.oauth, MCPPermission.network, MCPPermission.read, MCPPermission.write},
    required: {MCPPermission.oauth},
  );

  static MCPPermissions slackBot() => const MCPPermissions(
    allowed: {MCPPermission.oauth, MCPPermission.network, MCPPermission.write},
    required: {MCPPermission.oauth},
  );

  MCPPermissions minimal() => MCPPermissions(
    allowed: required,
    required: required,
  );
}

enum MCPPermission {
  read,
  write,
  network,
  filesystem,
  memory,
  computation,
  system,
  oauth,
}

// Result types
class MCPConnectionResult {
  final bool success;
  final MCPConnection? connection;
  final String? error;
  final String? reason;

  MCPConnectionResult.success(this.connection) 
    : success = true, error = null, reason = null;
  
  MCPConnectionResult.failed({required this.error}) 
    : success = false, connection = null, reason = null;
    
  MCPConnectionResult.blocked({required this.reason}) 
    : success = false, connection = null, error = null;
    
  MCPConnectionResult.cancelled() 
    : success = false, connection = null, error = null, reason = 'User cancelled';
}

class SafetyAssessment {
  final bool isSafe;
  final String? reason;

  SafetyAssessment({required this.isSafe, this.reason});
}

class MCPConnection {
  // Simplified connection interface
}

// Provider
final anthropicMCPServiceProvider = Provider<AnthropicStyleMCPService>((ref) {
  return AnthropicStyleMCPService();
});
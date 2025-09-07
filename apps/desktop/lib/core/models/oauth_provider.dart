import 'package:equatable/equatable.dart';

/// Supported OAuth 2.0 providers for secure authentication
enum OAuthProvider {
  github('GitHub', 'github.com'),
  slack('Slack', 'slack.com'),
  linear('Linear', 'linear.app'),
  microsoft('Microsoft', 'microsoft.com');

  const OAuthProvider(this.displayName, this.domain);

  final String displayName;
  final String domain;

  /// Get OAuth provider configuration
  OAuthProviderInfo get info => _providerInfoMap[this]!;
}

/// OAuth provider information and metadata
class OAuthProviderInfo extends Equatable {
  final OAuthProvider provider;
  final String name;
  final String description;
  final String iconPath;
  final List<String> capabilities;
  final bool requiresApproval;
  final String documentationUrl;

  const OAuthProviderInfo({
    required this.provider,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.capabilities,
    this.requiresApproval = false,
    required this.documentationUrl,
  });

  @override
  List<Object?> get props => [
    provider,
    name,
    description,
    iconPath,
    capabilities,
    requiresApproval,
    documentationUrl,
  ];
}

/// OAuth provider information mapping
const Map<OAuthProvider, OAuthProviderInfo> _providerInfoMap = {
  OAuthProvider.github: OAuthProviderInfo(
    provider: OAuthProvider.github,
    name: 'GitHub',
    description: 'Connect to GitHub for repository access, issue management, and code operations',
    iconPath: 'assets/icons/github.png',
    capabilities: [
      'Repository access',
      'Issue management',
      'Pull request operations',
      'File system operations',
      'Organization data',
    ],
    requiresApproval: false,
    documentationUrl: 'https://docs.github.com/en/apps/oauth-apps',
  ),
  
  OAuthProvider.slack: OAuthProviderInfo(
    provider: OAuthProvider.slack,
    name: 'Slack',
    description: 'Connect to Slack for team communication, channel management, and message operations',
    iconPath: 'assets/icons/slack.png',
    capabilities: [
      'Channel access',
      'Message sending',
      'File sharing',
      'User information',
      'Team management',
    ],
    requiresApproval: true,
    documentationUrl: 'https://api.slack.com/authentication/oauth-v2',
  ),
  
  OAuthProvider.linear: OAuthProviderInfo(
    provider: OAuthProvider.linear,
    name: 'Linear',
    description: 'Connect to Linear for project management, issue tracking, and team workflows',
    iconPath: 'assets/icons/linear.png',
    capabilities: [
      'Issue management',
      'Project tracking',
      'Team workflows',
      'Comment operations',
      'Label management',
    ],
    requiresApproval: false,
    documentationUrl: 'https://developers.linear.app/docs/oauth',
  ),
  
  OAuthProvider.microsoft: OAuthProviderInfo(
    provider: OAuthProvider.microsoft,
    name: 'Microsoft',
    description: 'Connect to Microsoft services for email, calendar, and Office 365 operations',
    iconPath: 'assets/icons/microsoft.png',
    capabilities: [
      'Email access',
      'Calendar operations',
      'Office 365 integration',
      'OneDrive access',
      'Team collaboration',
    ],
    requiresApproval: true,
    documentationUrl: 'https://docs.microsoft.com/en-us/graph/auth-v2-user',
  ),
};

/// OAuth connection status
enum OAuthConnectionStatus {
  disconnected('Disconnected', 'Not connected to this service'),
  connecting('Connecting', 'Authentication in progress'),
  connected('Connected', 'Successfully authenticated'),
  expired('Expired', 'Token has expired, needs refresh'),
  error('Error', 'Authentication failed');

  const OAuthConnectionStatus(this.displayName, this.description);

  final String displayName;
  final String description;

  bool get isActive => this == OAuthConnectionStatus.connected;
  bool get needsAction => this == OAuthConnectionStatus.expired || 
                         this == OAuthConnectionStatus.error ||
                         this == OAuthConnectionStatus.disconnected;
}

/// OAuth provider connection state
class OAuthProviderState extends Equatable {
  final OAuthProvider provider;
  final OAuthConnectionStatus status;
  final DateTime? connectedAt;
  final DateTime? lastUsed;
  final String? errorMessage;

  const OAuthProviderState({
    required this.provider,
    required this.status,
    this.connectedAt,
    this.lastUsed,
    this.errorMessage,
  });

  /// Create a copy with updated values
  OAuthProviderState copyWith({
    OAuthProvider? provider,
    OAuthConnectionStatus? status,
    DateTime? connectedAt,
    DateTime? lastUsed,
    String? errorMessage,
  }) {
    return OAuthProviderState(
      provider: provider ?? this.provider,
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
      lastUsed: lastUsed ?? this.lastUsed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    provider,
    status,
    connectedAt,
    lastUsed,
    errorMessage,
  ];
}
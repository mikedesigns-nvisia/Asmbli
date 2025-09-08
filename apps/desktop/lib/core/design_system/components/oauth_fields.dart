import 'package:flutter/material.dart';
import '../design_system.dart';
import 'mcp_field_types.dart';
import '../../constants/app_constants.dart';

/// OAuth integration fields for cloud services
/// Supports: Google, Microsoft, GitHub, Figma, Slack, Notion, etc.

/// OAuth flow field with integrated authentication
class OAuthField extends MCPField {
  final OAuthProvider provider;
  final List<String> scopes;
  final bool showScopeSelector;
  final VoidCallback? onAuthenticate;
  final VoidCallback? onRevoke;
  final OAuthStatus status;

  const OAuthField({
    super.key,
    required super.label,
    super.description,
    super.required,
    super.value,
    super.onChanged,
    required this.provider,
    this.scopes = const [],
    this.showScopeSelector = false,
    this.onAuthenticate,
    this.onRevoke,
    this.status = OAuthStatus.notAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context),
        const SizedBox(height: SpacingTokens.componentSpacing),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getStatusColor(context).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildProviderIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: _getStatusColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(context),
                ],
              ),
              if (status == OAuthStatus.authenticated && value != null) ...[
                const SizedBox(height: 12),
                _buildAccountInfo(context),
              ],
              if (showScopeSelector) ...[
                const SizedBox(height: 16),
                _buildScopeSelector(context),
              ],
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (this.required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: SemanticColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProviderIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: provider.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        provider.icon,
        color: provider.brandColor,
        size: 20,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (status) {
      case OAuthStatus.notAuthenticated:
        return AsmblButton.primary(
          text: 'Connect',
          icon: Icons.login,
          onPressed: onAuthenticate,
        );
      case OAuthStatus.authenticating:
        return AsmblButton.secondary(
          text: 'Connecting...',
          icon: Icons.hourglass_empty,
          onPressed: null,
        );
      case OAuthStatus.authenticated:
        return AsmblButton.secondary(
          text: 'Connected',
          icon: Icons.check_circle,
          onPressed: onRevoke,
        );
      case OAuthStatus.error:
        return AsmblButton.secondary(
          text: 'Retry',
          icon: Icons.refresh,
          onPressed: onAuthenticate,
        );
    }
  }

  Widget _buildAccountInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: provider.brandColor,
            child: Text(
              _getAccountInitials(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getAccountName(),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getAccountEmail(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onRevoke != null)
            TextButton(
              onPressed: onRevoke,
              child: Text(
                'Disconnect',
                style: TextStyle(
                  color: SemanticColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScopeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissions',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.availableScopes.map((scope) {
            final isSelected = scopes.contains(scope.id);
            return FilterChip(
              selected: isSelected,
              label: Text(
                scope.displayName,
                style: TextStyles.bodySmall,
              ),
              onSelected: (selected) {
                // Handle scope selection
              },
              selectedColor: provider.brandColor.withValues(alpha: 0.2),
              checkmarkColor: provider.brandColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (status) {
      case OAuthStatus.notAuthenticated:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case OAuthStatus.authenticating:
        return SemanticColors.primary;
      case OAuthStatus.authenticated:
        return SemanticColors.success;
      case OAuthStatus.error:
        return SemanticColors.error;
    }
  }

  String _getStatusText() {
    switch (status) {
      case OAuthStatus.notAuthenticated:
        return 'Not connected';
      case OAuthStatus.authenticating:
        return 'Connecting...';
      case OAuthStatus.authenticated:
        return 'Connected successfully';
      case OAuthStatus.error:
        return 'Connection failed';
    }
  }

  String _getAccountInitials() {
    // This would parse actual account data from value
    return provider.displayName.substring(0, 2).toUpperCase();
  }

  String _getAccountName() {
    // This would parse actual account data from value
    return 'John Doe'; // Placeholder
  }

  String _getAccountEmail() {
    // This would parse actual account data from value
    return 'john.doe@example.com'; // Placeholder
  }
}

/// Permission scope selector for OAuth integrations
class PermissionScopeField extends StatefulWidget {
  final String label;
  final String? description;
  final OAuthProvider provider;
  final List<String> selectedScopes;
  final ValueChanged<List<String>>? onScopesChanged;

  const PermissionScopeField({
    super.key,
    required this.label,
    this.description,
    required this.provider,
    this.selectedScopes = const [],
    this.onScopesChanged,
  });

  @override
  State<PermissionScopeField> createState() => _PermissionScopeFieldState();
}

class _PermissionScopeFieldState extends State<PermissionScopeField> {
  late List<String> _selectedScopes;

  @override
  void initState() {
    super.initState();
    _selectedScopes = List.from(widget.selectedScopes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (widget.description != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.description!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: SpacingTokens.componentSpacing),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: widget.provider.availableScopes.map((scope) {
              final isSelected = _selectedScopes.contains(scope.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _toggleScope(scope.id),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? widget.provider.brandColor.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected 
                            ? widget.provider.brandColor.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelected 
                              ? widget.provider.brandColor 
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scope.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isSelected 
                                      ? widget.provider.brandColor 
                                      : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  scope.description,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (scope.isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: SemanticColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: TextStyle(
                                  color: SemanticColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _toggleScope(String scopeId) {
    setState(() {
      if (_selectedScopes.contains(scopeId)) {
        _selectedScopes.remove(scopeId);
      } else {
        _selectedScopes.add(scopeId);
      }
    });
    widget.onScopesChanged?.call(_selectedScopes);
  }
}

// Data models and enums
enum OAuthStatus {
  notAuthenticated,
  authenticating,
  authenticated,
  error,
}

class OAuthProvider {
  final String id;
  final String displayName;
  final IconData icon;
  final Color brandColor;
  final List<OAuthScope> availableScopes;

  const OAuthProvider({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.brandColor,
    this.availableScopes = const [],
  });

  // Predefined OAuth providers
  static const google = OAuthProvider(
    id: 'google',
    displayName: 'Google',
    icon: Icons.account_circle,
    brandColor: Color(BrandColors.google),
    availableScopes: [
      OAuthScope(
        id: 'drive.readonly',
        displayName: 'Google Drive (Read)',
        description: 'View your Google Drive files',
      ),
      OAuthScope(
        id: 'drive',
        displayName: 'Google Drive (Full)',
        description: 'Manage your Google Drive files',
      ),
      OAuthScope(
        id: 'gmail.readonly',
        displayName: 'Gmail (Read)',
        description: 'View your email messages',
      ),
    ],
  );

  static const microsoft = OAuthProvider(
    id: 'microsoft',
    displayName: 'Microsoft',
    icon: Icons.business,
    brandColor: Color(BrandColors.microsoft),
    availableScopes: [
      OAuthScope(
        id: 'files.read',
        displayName: 'OneDrive (Read)',
        description: 'View your OneDrive files',
        isRequired: true,
      ),
      OAuthScope(
        id: 'mail.read',
        displayName: 'Outlook (Read)',
        description: 'View your email messages',
      ),
    ],
  );

  static const github = OAuthProvider(
    id: 'github',
    displayName: 'GitHub',
    icon: Icons.code,
    brandColor: Color(BrandColors.github),
    availableScopes: [
      OAuthScope(
        id: 'repo',
        displayName: 'Repository Access',
        description: 'Access to your repositories',
        isRequired: true,
      ),
      OAuthScope(
        id: 'read:org',
        displayName: 'Organization Info',
        description: 'Read organization information',
      ),
    ],
  );

  static const figma = OAuthProvider(
    id: 'figma',
    displayName: 'Figma',
    icon: Icons.design_services,
    brandColor: Color(BrandColors.figma),
    availableScopes: [
      OAuthScope(
        id: 'file_read',
        displayName: 'File Access',
        description: 'View your Figma files',
        isRequired: true,
      ),
    ],
  );
}

class OAuthScope {
  final String id;
  final String displayName;
  final String description;
  final bool isRequired;

  const OAuthScope({
    required this.id,
    required this.displayName,
    required this.description,
    this.isRequired = false,
  });
}
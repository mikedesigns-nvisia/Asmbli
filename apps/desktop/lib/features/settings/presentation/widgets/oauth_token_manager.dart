import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_integration_service.dart';
import '../../../../core/services/oauth_extensions.dart';

class OAuthTokenManager extends ConsumerStatefulWidget {
  final OAuthProvider provider;

  const OAuthTokenManager({
    super.key,
    required this.provider,
  });

  @override
  ConsumerState<OAuthTokenManager> createState() => _OAuthTokenManagerState();
}

class _OAuthTokenManagerState extends ConsumerState<OAuthTokenManager> {
  OAuthTokenInfo? _tokenInfo;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _showTokens = false;

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      final tokenInfo = await oauthService.getTokenInfo(widget.provider);
      
      if (mounted) {
        setState(() {
          _tokenInfo = tokenInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _isRefreshing = true);
    
    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      final result = await oauthService.refreshToken(widget.provider);
      
      if (result.isSuccess) {
        await _loadTokenInfo();
        if (mounted) {
          _showSnackBar('Token refreshed successfully', isError: false);
        }
      } else {
        if (mounted) {
          _showSnackBar(result.error ?? 'Failed to refresh token');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error refreshing token: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _revokeTokens() async {
    final confirmed = await _showConfirmationDialog(
      'Revoke Access',
      'This will remove all stored tokens for ${widget.provider.displayName}. '
      'You will need to re-authenticate to use this integration.',
    );

    if (!confirmed) return;

    try {
      final oauthService = ref.read(oauthIntegrationServiceProvider);
      await oauthService.revokeCredentials(widget.provider);
      
      if (mounted) {
        setState(() => _tokenInfo = null);
        _showSnackBar('Tokens revoked successfully', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error revoking tokens: $e');
      }
    }
  }

  Future<void> _copyToken(String token, String tokenType) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) {
      _showSnackBar('$tokenType copied to clipboard', isError: false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_tokenInfo == null) {
      return _buildNoTokenState(colors);
    }

    return _buildTokenInfo(colors);
  }

  Widget _buildNoTokenState(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: SpacingTokens.lg),
            Text(
              'No Active Connection',
              style: TextStyles.bodyLarge.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: SpacingTokens.md),
            Text(
              'Connect to ${widget.provider.displayName} to manage tokens',
              style: TextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenInfo(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTokenOverview(colors),
        SizedBox(height: SpacingTokens.lg),
        _buildTokenDetails(colors),
        SizedBox(height: SpacingTokens.lg),
        _buildActions(colors),
      ],
    );
  }

  Widget _buildTokenOverview(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Token Overview',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            _buildTokenStatusRow(colors),
            SizedBox(height: SpacingTokens.md),
            _buildExpirationRow(colors),
            if (_tokenInfo!.scopes.isNotEmpty) ...[
              SizedBox(height: SpacingTokens.md),
              _buildScopesRow(colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTokenStatusRow(ThemeColors colors) {
    final isExpired = _tokenInfo!.isExpired;
    final isExpiringSoon = _tokenInfo!.isExpiringSoon;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.error;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = 'Expiring Soon';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'Active';
      statusIcon = Icons.check_circle;
    }

    return Row(
      children: [
        Text(
          'Status:',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Icon(
          statusIcon,
          size: 16,
          color: statusColor,
        ),
        SizedBox(width: SpacingTokens.xs),
        Text(
          statusText,
          style: TextStyles.bodyMedium.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationRow(ThemeColors colors) {
    final expiresAt = _tokenInfo!.expiresAt;
    
    return Row(
      children: [
        Text(
          'Expires:',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Text(
          expiresAt != null 
              ? _formatDateTime(expiresAt)
              : 'Never',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildScopesRow(ThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scopes:',
          style: TextStyles.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Wrap(
            spacing: SpacingTokens.xs,
            runSpacing: SpacingTokens.xs,
            children: _tokenInfo!.scopes.take(3).map((scope) => 
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  scope,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ).toList()
              ..addAll(_tokenInfo!.scopes.length > 3 ? [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm,
                    vertical: SpacingTokens.xs,
                  ),
                  child: Text(
                    '+${_tokenInfo!.scopes.length - 3} more',
                    style: TextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ] : []),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenDetails(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.key,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Token Details',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showTokens,
                  onChanged: (value) {
                    setState(() => _showTokens = value);
                  },
                  activeColor: colors.primary,
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            _buildTokenField(
              'Access Token',
              _tokenInfo!.accessToken,
              colors,
            ),
            if (_tokenInfo!.refreshToken != null) ...[
              SizedBox(height: SpacingTokens.md),
              _buildTokenField(
                'Refresh Token',
                _tokenInfo!.refreshToken!,
                colors,
              ),
            ],
            SizedBox(height: SpacingTokens.md),
            _buildTokenField(
              'Token Type',
              _tokenInfo!.tokenType,
              colors,
              isSensitive: false,
            ),
            if (_tokenInfo!.issuedAt != null) ...[
              SizedBox(height: SpacingTokens.md),
              _buildTokenField(
                'Issued At',
                _formatDateTime(_tokenInfo!.issuedAt!),
                colors,
                isSensitive: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTokenField(String label, String value, ThemeColors colors, {bool isSensitive = true}) {
    final displayValue = isSensitive && !_showTokens
        ? '••••••••••••••••'
        : value;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayValue,
                    style: TextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSensitive) ...[
                  SizedBox(width: SpacingTokens.sm),
                  IconButton(
                    onPressed: () => _copyToken(value, label),
                    icon: Icon(
                      Icons.copy,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeColors colors) {
    return Row(
      children: [
        if (_tokenInfo!.refreshToken != null)
          AsmblButton.secondary(
            text: _isRefreshing ? 'Refreshing...' : 'Refresh Token',
            icon: _isRefreshing ? null : Icons.refresh,
            onPressed: _isRefreshing ? null : _refreshToken,
            isLoading: _isRefreshing,
          ),
        if (_tokenInfo!.refreshToken != null)
          SizedBox(width: SpacingTokens.md),
        AsmblButton.destructive(
          text: 'Revoke Access',
          icon: Icons.block,
          onPressed: _revokeTokens,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
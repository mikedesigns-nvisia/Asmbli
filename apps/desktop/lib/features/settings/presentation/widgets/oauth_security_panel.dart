import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_integration_service.dart';
import '../../../../core/services/oauth_extensions.dart';

class OAuthSecurityPanel extends ConsumerStatefulWidget {
  const OAuthSecurityPanel({super.key});

  @override
  ConsumerState<OAuthSecurityPanel> createState() => _OAuthSecurityPanelState();
}

class _OAuthSecurityPanelState extends ConsumerState<OAuthSecurityPanel> {
  final Map<OAuthProvider, OAuthConnectionTest?> _connectionTests = {};
  bool _isTestingAll = false;

  @override
  void initState() {
    super.initState();
    _runSecurityCheck();
  }

  Future<void> _runSecurityCheck() async {
    setState(() => _isTestingAll = true);
    
    final oauthService = ref.read(oauthIntegrationServiceProvider);
    
    for (final provider in OAuthProvider.values) {
      if (await oauthService.hasValidToken(provider)) {
        try {
          final testResult = await oauthService.testConnection(provider);
          if (mounted) {
            setState(() {
              _connectionTests[provider] = testResult;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _connectionTests[provider] = OAuthConnectionTest(
                success: false,
                duration: Duration.zero,
                error: e.toString(),
              );
            });
          }
        }
      }
    }
    
    if (mounted) {
      setState(() => _isTestingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSecurityOverview(colors),
        SizedBox(height: SpacingTokens.xl),
        _buildConnectionStatus(colors),
        SizedBox(height: SpacingTokens.xl),
        _buildSecuritySettings(colors),
        SizedBox(height: SpacingTokens.xl),
        _buildAuditLog(colors),
      ],
    );
  }

  Widget _buildSecurityOverview(ThemeColors colors) {
    final connectedProviders = _connectionTests.keys.length;
    final healthyConnections = _connectionTests.values
        .where((test) => test?.success == true)
        .length;
    final failedConnections = _connectionTests.values
        .where((test) => test?.success == false)
        .length;

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
                  size: 24,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Security Overview',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isTestingAll)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                else
                  IconButton(
                    onPressed: _runSecurityCheck,
                    icon: Icon(
                      Icons.refresh,
                      color: colors.primary,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            Row(
              children: [
                Expanded(
                  child: _buildSecurityMetric(
                    'Connected',
                    connectedProviders.toString(),
                    Colors.blue,
                    Icons.link,
                    colors,
                  ),
                ),
                SizedBox(width: SpacingTokens.lg),
                Expanded(
                  child: _buildSecurityMetric(
                    'Healthy',
                    healthyConnections.toString(),
                    Colors.green,
                    Icons.check_circle,
                    colors,
                  ),
                ),
                SizedBox(width: SpacingTokens.lg),
                Expanded(
                  child: _buildSecurityMetric(
                    'Failed',
                    failedConnections.toString(),
                    failedConnections > 0 ? Colors.red : Colors.grey,
                    Icons.error,
                    colors,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityMetric(
    String label,
    String value,
    Color color,
    IconData icon,
    ThemeColors colors,
  ) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(height: SpacingTokens.sm),
          Text(
            value,
            style: TextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Connection Health',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            if (_connectionTests.isEmpty)
              Center(
                child: Text(
                  'No active connections to test',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              Column(
                children: _connectionTests.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: SpacingTokens.md),
                    child: _buildConnectionTestResult(entry.key, entry.value, colors),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTestResult(
    OAuthProvider provider,
    OAuthConnectionTest? test,
    ThemeColors colors,
  ) {
    if (test == null) {
      return _buildConnectionRow(
        provider,
        'Testing...',
        Colors.orange,
        Icons.hourglass_empty,
        null,
        colors,
      );
    }

    final status = test.success ? 'Healthy' : 'Failed';
    final color = test.success ? Colors.green : Colors.red;
    final icon = test.success ? Icons.check_circle : Icons.error;
    final duration = '${test.duration.inMilliseconds}ms';

    return _buildConnectionRow(
      provider,
      status,
      color,
      icon,
      duration,
      colors,
      error: test.error,
    );
  }

  Widget _buildConnectionRow(
    OAuthProvider provider,
    String status,
    Color statusColor,
    IconData statusIcon,
    String? duration,
    ThemeColors colors, {
    String? error,
  }) {
    return Container(
      padding: EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                provider.icon,
                size: 20,
                color: colors.primary,
              ),
              SizedBox(width: SpacingTokens.md),
              Text(
                provider.displayName,
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                statusIcon,
                size: 16,
                color: statusColor,
              ),
              SizedBox(width: SpacingTokens.xs),
              Text(
                status,
                style: TextStyles.bodySmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (duration != null) ...[
                SizedBox(width: SpacingTokens.md),
                Text(
                  duration,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (error != null) ...[
            SizedBox(height: SpacingTokens.sm),
            Text(
              'Error: $error',
              style: TextStyles.bodySmall.copyWith(
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecuritySettings(ThemeColors colors) {
    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_shield,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Security Settings',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            _buildSecuritySetting(
              'Auto-refresh tokens',
              'Automatically refresh tokens before they expire',
              true,
              colors,
              onChanged: (value) {
                // Handle setting change
              },
            ),
            _buildSecuritySetting(
              'Secure token storage',
              'Use encrypted storage for OAuth tokens',
              true,
              colors,
              onChanged: (value) {
                // Handle setting change
              },
            ),
            _buildSecuritySetting(
              'Connection monitoring',
              'Periodically test OAuth connections',
              true,
              colors,
              onChanged: (value) {
                // Handle setting change
              },
            ),
            _buildSecuritySetting(
              'Audit logging',
              'Log OAuth activities for security monitoring',
              false,
              colors,
              onChanged: (value) {
                // Handle setting change
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySetting(
    String title,
    String description,
    bool value,
    ThemeColors colors, {
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: SpacingTokens.xs),
                Text(
                  description,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: SpacingTokens.lg),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLog(ThemeColors colors) {
    final mockEvents = [
      _AuditEvent(
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        event: 'Token refreshed',
        provider: 'GitHub',
        status: 'Success',
      ),
      _AuditEvent(
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        event: 'Connection tested',
        provider: 'Slack',
        status: 'Success',
      ),
      _AuditEvent(
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        event: 'Token refresh failed',
        provider: 'Linear',
        status: 'Failed',
      ),
    ];

    return AsmblCard(
      child: Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: colors.primary,
                ),
                SizedBox(width: SpacingTokens.md),
                Text(
                  'Recent Activity',
                  style: TextStyles.bodyLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: SpacingTokens.lg),
            Column(
              children: mockEvents.map((event) => 
                Padding(
                  padding: EdgeInsets.symmetric(vertical: SpacingTokens.sm),
                  child: _buildAuditEventRow(event, colors),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditEventRow(_AuditEvent event, ThemeColors colors) {
    final statusColor = event.status == 'Success' ? Colors.green : Colors.red;
    final timeAgo = _formatTimeAgo(event.timestamp);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: SpacingTokens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${event.event} - ${event.provider}',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              Text(
                timeAgo,
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          event.status,
          style: TextStyles.bodySmall.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _AuditEvent {
  final DateTime timestamp;
  final String event;
  final String provider;
  final String status;

  _AuditEvent({
    required this.timestamp,
    required this.event,
    required this.provider,
    required this.status,
  });
}
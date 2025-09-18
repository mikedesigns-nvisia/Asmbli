import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/security_context.dart';
import '../../../../core/services/integrated_security_service.dart';
import '../../../../core/services/api_access_control.dart';
import '../../../../core/di/service_locator.dart';
import 'dart:async';

/// Widget for managing agent permissions and API access
class AgentPermissionsWidget extends ConsumerStatefulWidget {
  final String agentId;
  final bool showInlineControls;

  const AgentPermissionsWidget({
    super.key,
    required this.agentId,
    this.showInlineControls = true,
  });

  @override
  ConsumerState<AgentPermissionsWidget> createState() => _AgentPermissionsWidgetState();
}

class _AgentPermissionsWidgetState extends ConsumerState<AgentPermissionsWidget>
    with TickerProviderStateMixin {

  late TabController _tabController;
  SecurityContext? _securityContext;
  List<APIEndpoint> _availableAPIs = [];
  Map<String, List<AgentPermissionEvent>> _permissionHistory = {};
  bool _isLoading = false;

  IntegratedSecurityService? _securityService;
  APIAccessControl? _apiControl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
    _loadData();
  }

  void _initializeServices() {
    try {
      _securityService = ServiceLocator.instance.get<IntegratedSecurityService>();
      _apiControl = ServiceLocator.instance.get<APIAccessControl>();
    } catch (e) {
      debugPrint('Failed to initialize permission services: $e');
    }
  }

  void _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadSecurityContext(),
        _loadAvailableAPIs(),
        _loadPermissionHistory(),
      ]);
    } catch (e) {
      debugPrint('Failed to load permission data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSecurityContext() async {
    _securityContext = await _securityService?.getAgentSecurityContext(widget.agentId);
  }

  Future<void> _loadAvailableAPIs() async {
    if (_apiControl == null) return;

    try {
      _availableAPIs = await _apiControl!.getAvailableAPIs();
    } catch (e) {
      debugPrint('Failed to load available APIs: $e');
    }
  }

  Future<void> _loadPermissionHistory() async {
    if (_securityService == null) return;

    try {
      final events = await _securityService!.getAgentPermissionHistory(widget.agentId, limit: 50);
      setState(() {
        _permissionHistory = _groupEventsByDate(events);
      });
    } catch (e) {
      debugPrint('Failed to load permission history: $e');
    }
  }

  Map<String, List<AgentPermissionEvent>> _groupEventsByDate(List<AgentPermissionEvent> events) {
    final grouped = <String, List<AgentPermissionEvent>>{};

    for (final event in events) {
      final dateKey = _formatDateKey(event.timestamp);
      grouped[dateKey] ??= [];
      grouped[dateKey]!.add(event);
    }

    return grouped;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) return 'Today';
    if (eventDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _updateAPIPermission(String apiName, APIAccessLevel level) async {
    if (_securityContext == null || _securityService == null) return;

    final updatedPermissions = Map<String, APIPermission>.from(_securityContext!.apiPermissions);

    if (level == APIAccessLevel.none) {
      updatedPermissions.remove(apiName);
    } else {
      updatedPermissions[apiName] = APIPermission(
        accessLevel: level,
        allowedMethods: _getDefaultMethodsForLevel(level),
        rateLimit: _getDefaultRateLimitForLevel(level),
        lastUsed: null,
        grantedAt: DateTime.now(),
      );
    }

    final updatedContext = SecurityContext(
      agentId: _securityContext!.agentId,
      allowedCommands: _securityContext!.allowedCommands,
      blockedCommands: _securityContext!.blockedCommands,
      allowedPaths: _securityContext!.allowedPaths,
      allowedNetworkHosts: _securityContext!.allowedNetworkHosts,
      apiPermissions: updatedPermissions,
      resourceLimits: _securityContext!.resourceLimits,
      auditLogging: _securityContext!.auditLogging,
      terminalPermissions: _securityContext!.terminalPermissions,
      createdAt: _securityContext!.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _securityService!.updateAgentSecurityContext(widget.agentId, updatedContext);
      setState(() {
        _securityContext = updatedContext;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated $apiName permission to ${level.name}'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update permission: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  List<String> _getDefaultMethodsForLevel(APIAccessLevel level) {
    switch (level) {
      case APIAccessLevel.read:
        return ['GET'];
      case APIAccessLevel.write:
        return ['GET', 'POST', 'PUT', 'PATCH'];
      case APIAccessLevel.admin:
        return ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
      case APIAccessLevel.none:
        return [];
    }
  }

  int _getDefaultRateLimitForLevel(APIAccessLevel level) {
    switch (level) {
      case APIAccessLevel.read:
        return 100; // 100 requests per hour
      case APIAccessLevel.write:
        return 50;  // 50 requests per hour
      case APIAccessLevel.admin:
        return 25;  // 25 requests per hour
      case APIAccessLevel.none:
        return 0;
    }
  }

  Future<void> _revokeAllPermissions() async {
    final confirmed = await _showConfirmDialog(
      'Revoke All Permissions',
      'This will remove all API permissions for this agent. Are you sure?',
    );

    if (confirmed && _securityContext != null && _securityService != null) {
      final updatedContext = SecurityContext(
        agentId: _securityContext!.agentId,
        allowedCommands: _securityContext!.allowedCommands,
        blockedCommands: _securityContext!.blockedCommands,
        allowedPaths: _securityContext!.allowedPaths,
        allowedNetworkHosts: _securityContext!.allowedNetworkHosts,
        apiPermissions: const {},
        resourceLimits: _securityContext!.resourceLimits,
        auditLogging: _securityContext!.auditLogging,
        terminalPermissions: _securityContext!.terminalPermissions,
        createdAt: _securityContext!.createdAt,
        updatedAt: DateTime.now(),
      );

      try {
        await _securityService!.updateAgentSecurityContext(widget.agentId, updatedContext);
        setState(() {
          _securityContext = updatedContext;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('All permissions revoked'),
              backgroundColor: ThemeColors(context).success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to revoke permissions: $e'),
              backgroundColor: ThemeColors(context).error,
            ),
          );
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BorderRadiusTokens.md),
                topRight: Radius.circular(BorderRadiusTokens.md),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: SpacingTokens.xs),
                Text(
                  'Agent Permissions',
                  style: TextStyles.labelLarge.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.showInlineControls) ...[
                  AsmblButton.outline(
                    text: 'Revoke All',
                    onPressed: _revokeAllPermissions,
                    icon: Icons.block,
                    size: AsmblButtonSize.small,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  IconButton(
                    onPressed: _loadData,
                    icon: Icon(
                      Icons.refresh,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    tooltip: 'Refresh',
                  ),
                ],
              ],
            ),
          ),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.api), text: 'API Access'),
                Tab(icon: Icon(Icons.timeline), text: 'Activity'),
                Tab(icon: Icon(Icons.settings), text: 'Settings'),
              ],
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: colors.primary,
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAPIAccessTab(),
                _buildActivityTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIAccessTab() {
    final colors = ThemeColors(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'API Permissions',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_securityContext?.apiPermissions.length ?? 0} active',
                  style: TextStyles.caption.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),

          Text(
            'Configure which APIs this agent can access and at what level.',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),

          Expanded(
            child: _availableAPIs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.api,
                          size: 32,
                          color: colors.onSurfaceVariant.withOpacity( 0.5),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(
                          'No APIs available',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _availableAPIs.length,
                    itemBuilder: (context, index) {
                      final api = _availableAPIs[index];
                      return _buildAPIPermissionCard(api);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIPermissionCard(APIEndpoint api) {
    final colors = ThemeColors(context);
    final currentPermission = _securityContext?.apiPermissions[api.name];
    final currentLevel = currentPermission?.accessLevel ?? APIAccessLevel.none;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity( 0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.xs),
                decoration: BoxDecoration(
                  color: _getAPITypeColor(api.type, colors).withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                ),
                child: Icon(
                  _getAPITypeIcon(api.type),
                  size: 16,
                  color: _getAPITypeColor(api.type, colors),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      api.name,
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      api.description,
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                  border: Border.all(color: colors.border),
                ),
                child: DropdownButton<APIAccessLevel>(
                  value: currentLevel,
                  onChanged: (level) {
                    if (level != null) {
                      _updateAPIPermission(api.name, level);
                    }
                  },
                  underline: const SizedBox(),
                  style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                  items: APIAccessLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAccessLevelIcon(level),
                            size: 12,
                            color: _getAccessLevelColor(level, colors),
                          ),
                          const SizedBox(width: 4),
                          Text(level.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          if (currentPermission != null) ...[
            const SizedBox(height: SpacingTokens.sm),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.xs),
              decoration: BoxDecoration(
                color: colors.surface.withOpacity( 0.5),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Granted: ${_formatDateTime(currentPermission.grantedAt)}',
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (currentPermission.lastUsed != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last used: ${_formatDateTime(currentPermission.lastUsed!)}',
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ] else
                    Text(
                      'Never used',
                      style: TextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final colors = ThemeColors(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Activity',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),

          Text(
            'Recent permission events and API usage for this agent.',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),

          Expanded(
            child: _permissionHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 32,
                          color: colors.onSurfaceVariant.withOpacity( 0.5),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(
                          'No activity recorded',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _permissionHistory.length,
                    itemBuilder: (context, index) {
                      final dateKey = _permissionHistory.keys.elementAt(index);
                      final events = _permissionHistory[dateKey]!;
                      return _buildActivitySection(dateKey, events);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(String dateKey, List<AgentPermissionEvent> events) {
    final colors = ThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
          child: Text(
            dateKey,
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...events.map((event) => _buildActivityItem(event)),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }

  Widget _buildActivityItem(AgentPermissionEvent event) {
    final colors = ThemeColors(context);

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.xs),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity( 0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
        border: Border.all(color: colors.border.withOpacity( 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getEventTypeColor(event.type, colors),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                if (event.metadata.isNotEmpty)
                  Text(
                    event.metadata.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(', '),
                    style: TextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(event.timestamp),
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    final colors = ThemeColors(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Settings',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),

          // Permission defaults
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity( 0.3),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Permission Settings',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),

                _buildSettingItem(
                  'Auto-approve read access',
                  'Automatically grant read-only access to safe APIs',
                  _securityContext?.terminalPermissions.allowNetworkAccess ?? false,
                  (value) {
                    // TODO: Implement setting update
                  },
                ),

                _buildSettingItem(
                  'Audit all API calls',
                  'Log detailed information about all API usage',
                  _securityContext?.auditLogging ?? true,
                  (value) {
                    // TODO: Implement setting update
                  },
                ),

                _buildSettingItem(
                  'Rate limiting',
                  'Enforce rate limits on API usage',
                  true,
                  (value) {
                    // TODO: Implement setting update
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: SpacingTokens.lg),

          // Danger zone
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.error.withOpacity( 0.05),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: Border.all(color: colors.error.withOpacity( 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: colors.error,
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Text(
                      'Danger Zone',
                      style: TextStyles.bodyMedium.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.sm),

                Text(
                  'These actions cannot be undone.',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: SpacingTokens.md),

                AsmblButton.outline(
                  text: 'Reset All Permissions',
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                      'Reset Permissions',
                      'This will reset all permissions to defaults. Continue?',
                    );
                    if (confirmed) {
                      // TODO: Implement reset
                    }
                  },
                  icon: Icons.restore,
                  size: AsmblButtonSize.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colors = ThemeColors(context);

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }

  Color _getAPITypeColor(APIType type, ThemeColors colors) {
    switch (type) {
      case APIType.rest:
        return colors.primary;
      case APIType.graphql:
        return colors.secondary;
      case APIType.websocket:
        return colors.accent;
      case APIType.grpc:
        return colors.warning;
    }
  }

  IconData _getAPITypeIcon(APIType type) {
    switch (type) {
      case APIType.rest:
        return Icons.api;
      case APIType.graphql:
        return Icons.schema;
      case APIType.websocket:
        return Icons.swap_horiz;
      case APIType.grpc:
        return Icons.settings_ethernet;
    }
  }

  Color _getAccessLevelColor(APIAccessLevel level, ThemeColors colors) {
    switch (level) {
      case APIAccessLevel.none:
        return colors.onSurfaceVariant;
      case APIAccessLevel.read:
        return colors.success;
      case APIAccessLevel.write:
        return colors.warning;
      case APIAccessLevel.admin:
        return colors.error;
    }
  }

  IconData _getAccessLevelIcon(APIAccessLevel level) {
    switch (level) {
      case APIAccessLevel.none:
        return Icons.block;
      case APIAccessLevel.read:
        return Icons.visibility;
      case APIAccessLevel.write:
        return Icons.edit;
      case APIAccessLevel.admin:
        return Icons.admin_panel_settings;
    }
  }

  Color _getEventTypeColor(PermissionEventType type, ThemeColors colors) {
    switch (type) {
      case PermissionEventType.granted:
        return colors.success;
      case PermissionEventType.revoked:
        return colors.error;
      case PermissionEventType.used:
        return colors.primary;
      case PermissionEventType.denied:
        return colors.error;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// API endpoint information
class APIEndpoint {
  final String name;
  final String description;
  final APIType type;
  final String baseUrl;
  final List<String> availableMethods;
  final bool requiresAuth;

  const APIEndpoint({
    required this.name,
    required this.description,
    required this.type,
    required this.baseUrl,
    required this.availableMethods,
    this.requiresAuth = true,
  });
}

/// API types
enum APIType {
  rest,
  graphql,
  websocket,
  grpc,
}

/// API access levels
enum APIAccessLevel {
  none('None'),
  read('Read'),
  write('Write'),
  admin('Admin');

  const APIAccessLevel(this.displayName);
  final String displayName;
}

/// Permission event types
enum PermissionEventType {
  granted,
  revoked,
  used,
  denied,
}

/// Agent permission event
class AgentPermissionEvent {
  final String agentId;
  final PermissionEventType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AgentPermissionEvent({
    required this.agentId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
  });
}

/// Extension for IntegratedSecurityService to support permission management
extension IntegratedSecurityServiceExtension on IntegratedSecurityService {
  Future<List<AgentPermissionEvent>> getAgentPermissionHistory(String agentId, {int limit = 50}) async {
    // Mock implementation - replace with actual service calls
    return [
      AgentPermissionEvent(
        agentId: agentId,
        type: PermissionEventType.granted,
        description: 'API access granted for GitHub API',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        metadata: {'api': 'github', 'level': 'read'},
      ),
      AgentPermissionEvent(
        agentId: agentId,
        type: PermissionEventType.used,
        description: 'Made API call to GitHub repositories',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        metadata: {'api': 'github', 'endpoint': '/user/repos'},
      ),
    ];
  }
}

/// Extension for APIAccessControl to support UI operations
extension APIAccessControlExtension on APIAccessControl {
  Future<List<APIEndpoint>> getAvailableAPIs() async {
    // Mock implementation - replace with actual service calls
    return [
      const APIEndpoint(
        name: 'GitHub API',
        description: 'Access GitHub repositories and user data',
        type: APIType.rest,
        baseUrl: 'https://api.github.com',
        availableMethods: ['GET', 'POST', 'PUT', 'DELETE'],
      ),
      const APIEndpoint(
        name: 'OpenAI API',
        description: 'Access OpenAI language models and tools',
        type: APIType.rest,
        baseUrl: 'https://api.openai.com',
        availableMethods: ['GET', 'POST'],
      ),
      const APIEndpoint(
        name: 'File System API',
        description: 'Local file system operations',
        type: APIType.rest,
        baseUrl: 'file://',
        availableMethods: ['GET', 'POST', 'PUT', 'DELETE'],
        requiresAuth: false,
      ),
    ];
  }
}
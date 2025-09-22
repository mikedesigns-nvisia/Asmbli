import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/security_context.dart';
import '../../../../core/services/security_policy_engine.dart';
import '../../../../core/services/integrated_security_service.dart';
import '../../../../core/di/service_locator.dart';
import 'dart:async';

/// Widget for configuring security policies and permissions
class SecurityPolicyWidget extends ConsumerStatefulWidget {
  final String? agentId;
  final bool showGlobalSettings;

  const SecurityPolicyWidget({
    super.key,
    this.agentId,
    this.showGlobalSettings = false,
  });

  @override
  ConsumerState<SecurityPolicyWidget> createState() => _SecurityPolicyWidgetState();
}

class _SecurityPolicyWidgetState extends ConsumerState<SecurityPolicyWidget>
    with TickerProviderStateMixin {

  late TabController _tabController;
  SecurityContext? _securityContext;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Form controllers
  final _allowedCommandsController = TextEditingController();
  final _blockedCommandsController = TextEditingController();
  final _networkHostsController = TextEditingController();

  // UI state
  Map<String, String> _pathPermissions = {};
  Map<String, APIPermission> _apiPermissions = {};
  ResourceLimits _resourceLimits = ResourceLimits.defaultLimits();
  TerminalPermissions _terminalPermissions = TerminalPermissions.defaultPermissions();
  bool _auditLogging = true;
  SecurityTemplateType _selectedTemplate = SecurityTemplateType.balanced;

  SecurityPolicyEngine? _policyEngine;
  IntegratedSecurityService? _securityService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
    _loadSecurityContext();
  }

  void _initializeServices() {
    try {
      _policyEngine = ServiceLocator.instance.get<SecurityPolicyEngine>();
      _securityService = ServiceLocator.instance.get<IntegratedSecurityService>();
    } catch (e) {
      debugPrint('Failed to initialize security services: $e');
    }
  }

  void _loadSecurityContext() async {
    if (widget.agentId == null && !widget.showGlobalSettings) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.agentId != null) {
        // Load agent-specific security context
        _securityContext = await _securityService?.getAgentSecurityContext(widget.agentId!);
      } else {
        // Load global security settings
        _securityContext = await _securityService?.getGlobalSecurityContext();
      }

      if (_securityContext != null) {
        _populateFormFromContext(_securityContext!);
      } else {
        // Create default context
        _securityContext = widget.agentId != null
            ? SecurityContext.defaultForAgent(widget.agentId!)
            : SecurityContext.defaultGlobal();
        _populateFormFromContext(_securityContext!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to load security context: $e');
    }
  }

  void _populateFormFromContext(SecurityContext context) {
    _allowedCommandsController.text = context.allowedCommands.join('\\n');
    _blockedCommandsController.text = context.blockedCommands.join('\\n');
    _networkHostsController.text = context.allowedNetworkHosts.join('\\n');
    _pathPermissions = Map.from(context.allowedPaths);
    _apiPermissions = Map.from(context.apiPermissions);
    _resourceLimits = context.resourceLimits;
    _terminalPermissions = context.terminalPermissions;
    _auditLogging = context.auditLogging;
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _applyTemplate(SecurityTemplateType template) {
    setState(() {
      _selectedTemplate = template;
      _hasChanges = true;

      switch (template) {
        case SecurityTemplateType.permissive:
          _allowedCommandsController.text = '';
          _blockedCommandsController.text = _getPermissiveBlockedCommands().join('\\n');
          _resourceLimits = ResourceLimits.permissiveLimits();
          _terminalPermissions = TerminalPermissions.permissivePermissions();
          break;
        case SecurityTemplateType.balanced:
          _allowedCommandsController.text = _getBalancedAllowedCommands().join('\\n');
          _blockedCommandsController.text = _getBalancedBlockedCommands().join('\\n');
          _resourceLimits = ResourceLimits.defaultLimits();
          _terminalPermissions = TerminalPermissions.defaultPermissions();
          break;
        case SecurityTemplateType.restricted:
          _allowedCommandsController.text = _getRestrictedAllowedCommands().join('\\n');
          _blockedCommandsController.text = _getRestrictedBlockedCommands().join('\\n');
          _resourceLimits = ResourceLimits.restrictedLimits();
          _terminalPermissions = TerminalPermissions.restrictedPermissions();
          break;
      }
    });
  }

  Future<void> _saveConfiguration() async {
    if (_securityContext == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedContext = SecurityContext(
        agentId: _securityContext!.agentId,
        allowedCommands: _allowedCommandsController.text
            .split('\\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        blockedCommands: _blockedCommandsController.text
            .split('\\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        allowedPaths: _pathPermissions,
        allowedNetworkHosts: _networkHostsController.text
            .split('\\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        apiPermissions: _apiPermissions,
        resourceLimits: _resourceLimits,
        auditLogging: _auditLogging,
        terminalPermissions: _terminalPermissions,
        createdAt: _securityContext!.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.agentId != null) {
        await _securityService?.updateAgentSecurityContext(widget.agentId!, updatedContext);
      } else {
        await _securityService?.updateGlobalSecurityContext(updatedContext);
      }

      setState(() {
        _securityContext = updatedContext;
        _hasChanges = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Security configuration saved successfully'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save configuration: $e'),
            backgroundColor: ThemeColors(context).error,
          ),
        );
      }
    }
  }

  void _resetToDefaults() {
    setState(() {
      final defaultContext = widget.agentId != null
          ? SecurityContext.defaultForAgent(widget.agentId!)
          : SecurityContext.defaultGlobal();
      _populateFormFromContext(defaultContext);
      _selectedTemplate = SecurityTemplateType.balanced;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    if (_isLoading && _securityContext == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Header with template selector and save button
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(BorderRadiusTokens.md),
              topRight: Radius.circular(BorderRadiusTokens.md),
            ),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    widget.agentId != null
                        ? 'Agent Security Policies'
                        : 'Global Security Settings',
                    style: TextStyles.labelLarge.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_hasChanges) ...[
                    AsmblButton.secondary(
                      text: 'Reset',
                      onPressed: _resetToDefaults,
                      size: AsmblButtonSize.small,
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                  ],
                  AsmblButton.primary(
                    text: _isLoading ? 'Saving...' : 'Save',
                    onPressed: _isLoading ? null : _saveConfiguration,
                    icon: _isLoading ? null : Icons.save,
                    size: AsmblButtonSize.small,
                  ),
                ],
              ),

              const SizedBox(height: SpacingTokens.md),

              // Security template selector
              Container(
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Template',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Row(
                      children: SecurityTemplateType.values.map((template) {
                        final isSelected = _selectedTemplate == template;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: SpacingTokens.xs),
                            child: GestureDetector(
                              onTap: () => _applyTemplate(template),
                              child: Container(
                                padding: const EdgeInsets.all(SpacingTokens.xs),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.primary.withOpacity(0.1)
                                      : colors.surfaceVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                                  border: Border.all(
                                    color: isSelected ? colors.primary : colors.border,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _getTemplateIcon(template),
                                      size: 16,
                                      color: isSelected ? colors.primary : colors.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getTemplateName(template),
                                      style: TextStyles.caption.copyWith(
                                        color: isSelected ? colors.primary : colors.onSurface,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.symmetric(
              horizontal: BorderSide(color: colors.border),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.terminal), text: 'Commands'),
              Tab(icon: Icon(Icons.folder), text: 'Paths'),
              Tab(icon: Icon(Icons.network_check), text: 'Network'),
              Tab(icon: Icon(Icons.tune), text: 'Resources'),
            ],
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
          ),
        ),

        // Tab content
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(BorderRadiusTokens.md),
                bottomRight: Radius.circular(BorderRadiusTokens.md),
              ),
              border: Border.all(color: colors.border),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommandsTab(),
                _buildPathsTab(),
                _buildNetworkTab(),
                _buildResourcesTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommandsTab() {
    final colors = ThemeColors(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Command Permissions',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),

          Expanded(
            child: Row(
              children: [
                // Allowed commands
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allowed Commands',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        'One command per line. Leave empty to allow all non-blocked commands.',
                        style: TextStyles.caption.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Expanded(
                        child: TextField(
                          controller: _allowedCommandsController,
                          onChanged: (_) => _onFieldChanged(),
                          maxLines: null,
                          expands: true,
                          style: TextStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: 'ls\\ncd\\ngrep\\n...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                            ),
                            contentPadding: const EdgeInsets.all(SpacingTokens.sm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: SpacingTokens.md),

                // Blocked commands
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blocked Commands',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        'Commands that are explicitly forbidden.',
                        style: TextStyles.caption.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Expanded(
                        child: TextField(
                          controller: _blockedCommandsController,
                          onChanged: (_) => _onFieldChanged(),
                          maxLines: null,
                          expands: true,
                          style: TextStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: 'rm\\nsudo\\nchmod\\n...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                            ),
                            contentPadding: const EdgeInsets.all(SpacingTokens.sm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathsTab() {
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
                'File System Permissions',
                style: TextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AsmblButton.outline(
                text: 'Add Path',
                icon: Icons.add,
                onPressed: _showAddPathDialog,
                size: AsmblButtonSize.small,
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),

          Text(
            'Configure which directories and files agents can access.',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),

          Expanded(
            child: _pathPermissions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off,
                          size: 32,
                          color: colors.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(
                          'No path permissions configured',
                          style: TextStyles.bodyMedium.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          'Add paths to restrict file system access',
                          style: TextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _pathPermissions.length,
                    itemBuilder: (context, index) {
                      final entry = _pathPermissions.entries.elementAt(index);
                      return _buildPathPermissionItem(entry.key, entry.value);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    final colors = ThemeColors(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Network Permissions',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),

          // Allowed hosts
          Text(
            'Allowed Network Hosts',
            style: TextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Hostnames or IP addresses that agents can connect to. One per line.',
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),

          Expanded(
            child: TextField(
              controller: _networkHostsController,
              onChanged: (_) => _onFieldChanged(),
              maxLines: null,
              expands: true,
              style: TextStyles.bodySmall.copyWith(
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'example.com\\n192.168.1.100\\n*.github.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                contentPadding: const EdgeInsets.all(SpacingTokens.sm),
              ),
            ),
          ),

          const SizedBox(height: SpacingTokens.md),

          // API permissions section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'API Permissions',
                style: TextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AsmblButton.outline(
                text: 'Add API',
                icon: Icons.add,
                onPressed: _showAddAPIPermissionDialog,
                size: AsmblButtonSize.small,
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),

          if (_apiPermissions.isEmpty)
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: Text(
                  'No API permissions configured',
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...(_apiPermissions.entries.map((entry) =>
                _buildAPIPermissionItem(entry.key, entry.value))),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    final colors = ThemeColors(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resource Limits',
            style: TextStyles.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),

          // CPU limit
          _buildResourceSlider(
            'CPU Limit (%)',
            _resourceLimits.maxCpuPercent.toDouble(),
            0,
            100,
            (value) {
              setState(() {
                _resourceLimits = _resourceLimits.copyWith(
                  maxCpuPercent: value.toInt(),
                );
                _onFieldChanged();
              });
            },
            divisions: 20,
            suffix: '%',
          ),

          const SizedBox(height: SpacingTokens.md),

          // Memory limit
          _buildResourceSlider(
            'Memory Limit (MB)',
            _resourceLimits.maxMemoryMb.toDouble(),
            64,
            8192,
            (value) {
              setState(() {
                _resourceLimits = _resourceLimits.copyWith(
                  maxMemoryMb: value.toInt(),
                );
                _onFieldChanged();
              });
            },
            divisions: 32,
            suffix: 'MB',
          ),

          const SizedBox(height: SpacingTokens.md),

          // Process limit
          _buildResourceSlider(
            'Max Processes',
            _resourceLimits.maxProcesses.toDouble(),
            1,
            50,
            (value) {
              setState(() {
                _resourceLimits = _resourceLimits.copyWith(
                  maxProcesses: value.toInt(),
                );
                _onFieldChanged();
              });
            },
            divisions: 49,
          ),

          const SizedBox(height: SpacingTokens.md),

          // Execution timeout
          _buildResourceSlider(
            'Command Timeout (seconds)',
            _resourceLimits.executionTimeoutSeconds.toDouble(),
            5,
            300,
            (value) {
              setState(() {
                _resourceLimits = _resourceLimits.copyWith(
                  executionTimeoutSeconds: value.toInt(),
                );
                _onFieldChanged();
              });
            },
            divisions: 59,
            suffix: 's',
          ),

          const SizedBox(height: SpacingTokens.lg),

          // Terminal permissions
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terminal Permissions',
                  style: TextStyles.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),

                _buildPermissionToggle(
                  'Allow Shell Access',
                  'Permit agents to access shell commands',
                  _terminalPermissions.allowShellAccess,
                  (value) {
                    setState(() {
                      _terminalPermissions = _terminalPermissions.copyWith(
                        allowShellAccess: value,
                      );
                      _onFieldChanged();
                    });
                  },
                ),

                _buildPermissionToggle(
                  'Allow File Operations',
                  'Permit reading and writing files',
                  _terminalPermissions.allowFileOperations,
                  (value) {
                    setState(() {
                      _terminalPermissions = _terminalPermissions.copyWith(
                        allowFileOperations: value,
                      );
                      _onFieldChanged();
                    });
                  },
                ),

                _buildPermissionToggle(
                  'Allow Network Access',
                  'Permit network connections and requests',
                  _terminalPermissions.allowNetworkAccess,
                  (value) {
                    setState(() {
                      _terminalPermissions = _terminalPermissions.copyWith(
                        allowNetworkAccess: value,
                      );
                      _onFieldChanged();
                    });
                  },
                ),

                _buildPermissionToggle(
                  'Audit Logging',
                  'Log all security-related events',
                  _auditLogging,
                  (value) {
                    setState(() {
                      _auditLogging = value;
                      _onFieldChanged();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    int? divisions,
    String? suffix,
  }) {
    final colors = ThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${value.toInt()}${suffix ?? ''}',
                style: TextStyles.caption.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: colors.primary,
          inactiveColor: colors.border,
        ),
      ],
    );
  }

  Widget _buildPermissionToggle(
    String title,
    String subtitle,
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
                  subtitle,
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

  Widget _buildPathPermissionItem(String path, String permissions) {
    final colors = ThemeColors(context);

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Permissions: $permissions',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _pathPermissions.remove(path);
                _onFieldChanged();
              });
            },
            icon: Icon(
              Icons.delete,
              size: 16,
              color: colors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIPermissionItem(String apiName, APIPermission permission) {
    final colors = ThemeColors(context);

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.api,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apiName,
                  style: TextStyles.bodySmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Access: ${permission.accessLevel.name}',
                  style: TextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _apiPermissions.remove(apiName);
                _onFieldChanged();
              });
            },
            icon: Icon(
              Icons.delete,
              size: 16,
              color: colors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPathDialog() {
    // TODO: Implement path addition dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Path addition dialog coming soon')),
    );
  }

  void _showAddAPIPermissionDialog() {
    // TODO: Implement API permission addition dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API permission dialog coming soon')),
    );
  }

  IconData _getTemplateIcon(SecurityTemplateType template) {
    switch (template) {
      case SecurityTemplateType.permissive:
        return Icons.lock_open;
      case SecurityTemplateType.balanced:
        return Icons.balance;
      case SecurityTemplateType.restricted:
        return Icons.lock;
    }
  }

  String _getTemplateName(SecurityTemplateType template) {
    switch (template) {
      case SecurityTemplateType.permissive:
        return 'Permissive';
      case SecurityTemplateType.balanced:
        return 'Balanced';
      case SecurityTemplateType.restricted:
        return 'Restricted';
    }
  }

  List<String> _getPermissiveBlockedCommands() => [
    'rm', 'sudo', 'su', 'passwd', 'chmod', 'chown', 'dd'
  ];

  List<String> _getBalancedAllowedCommands() => [
    'ls', 'cd', 'pwd', 'cat', 'grep', 'find', 'head', 'tail',
    'git', 'npm', 'node', 'python', 'pip', 'curl', 'wget'
  ];

  List<String> _getBalancedBlockedCommands() => [
    'rm', 'sudo', 'su', 'passwd', 'chmod', 'chown', 'dd',
    'mkfs', 'fdisk', 'mount', 'umount', 'kill', 'killall'
  ];

  List<String> _getRestrictedAllowedCommands() => [
    'ls', 'cd', 'pwd', 'cat', 'grep', 'head', 'tail'
  ];

  List<String> _getRestrictedBlockedCommands() => [
    'rm', 'sudo', 'su', 'passwd', 'chmod', 'chown', 'dd',
    'mkfs', 'fdisk', 'mount', 'umount', 'kill', 'killall',
    'curl', 'wget', 'ssh', 'scp', 'rsync', 'git'
  ];

  @override
  void dispose() {
    _tabController.dispose();
    _allowedCommandsController.dispose();
    _blockedCommandsController.dispose();
    _networkHostsController.dispose();
    super.dispose();
  }
}

/// Security template types
enum SecurityTemplateType {
  permissive,
  balanced,
  restricted,
}

/// Extension for SecurityContext to handle global contexts
extension SecurityContextExtension on SecurityContext {
  static SecurityContext defaultGlobal() {
    return SecurityContext(
      agentId: 'global',
      allowedCommands: const ['ls', 'cd', 'pwd', 'cat', 'grep', 'head', 'tail'],
      blockedCommands: const ['rm', 'sudo', 'su', 'passwd', 'chmod', 'chown'],
      allowedPaths: const {'/tmp': 'rw', '/home': 'r'},
      allowedNetworkHosts: const [],
      apiPermissions: const {},
      resourceLimits: ResourceLimits.defaultLimits(),
      auditLogging: true,
      terminalPermissions: TerminalPermissions.defaultPermissions(),
      createdAt: DateTime.now(),
    );
  }
}
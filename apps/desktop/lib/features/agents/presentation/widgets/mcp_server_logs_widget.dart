import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/mcp_server_process.dart';
import '../../../../core/services/agent_mcp_integration_service.dart';
import '../../../../core/services/mcp_process_manager.dart';
import '../../../../core/di/service_locator.dart';
import 'dart:async';

/// Widget for viewing MCP server logs and debugging information
class MCPServerLogsWidget extends ConsumerStatefulWidget {
  final String agentId;
  final String? serverId;
  final double height;

  const MCPServerLogsWidget({
    super.key,
    required this.agentId,
    this.serverId,
    this.height = 400,
  });

  @override
  ConsumerState<MCPServerLogsWidget> createState() => _MCPServerLogsWidgetState();
}

class _MCPServerLogsWidgetState extends ConsumerState<MCPServerLogsWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<MCPLogEntry> _logs = [];
  final List<String> _allServerIds = [];

  String _selectedServerId = '';
  LogLevel _selectedLogLevel = LogLevel.all;
  bool _autoScroll = true;
  bool _isLoading = false;
  Timer? _refreshTimer;

  MCPProcessManager? _processManager;
  StreamSubscription<MCPLogEntry>? _logSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadServers();
    _startAutoRefresh();
    _setupScrollListener();
  }

  void _initializeServices() {
    try {
      _processManager = ServiceLocator.instance.get<MCPProcessManager>();
    } catch (e) {
      debugPrint('Failed to initialize MCP process manager: $e');
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isAtBottom = _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50;
        if (_autoScroll != isAtBottom) {
          setState(() {
            _autoScroll = isAtBottom;
          });
        }
      }
    });
  }

  void _loadServers() async {
    if (_processManager == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final integrationService = ServiceLocator.instance.get<AgentMCPIntegrationService>();
      final servers = integrationService.getAgentMCPServers(widget.agentId);

      setState(() {
        _allServerIds.clear();
        _allServerIds.addAll(servers.map((s) => s.serverId));

        if (_allServerIds.isNotEmpty && _selectedServerId.isEmpty) {
          _selectedServerId = widget.serverId ?? _allServerIds.first;
          _loadLogs();
        }
        _isLoading = false;
      });

      _listenToLogs();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to load MCP servers: $e');
    }
  }

  void _loadLogs() async {
    if (_selectedServerId.isEmpty || _processManager == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get recent logs for the selected server
      final logs = await _processManager!.getServerLogs(_selectedServerId, limit: 100);

      setState(() {
        _logs.clear();
        _logs.addAll(_filterLogs(logs));
        _isLoading = false;
      });

      if (_autoScroll) {
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to load logs: $e');
    }
  }

  void _listenToLogs() {
    if (_selectedServerId.isEmpty || _processManager == null) return;

    _logSubscription?.cancel();

    try {
      _logSubscription = _processManager!.streamServerLogs(_selectedServerId).listen(
        (logEntry) {
          if (mounted && _shouldShowLog(logEntry)) {
            setState(() {
              _logs.add(logEntry);

              // Keep logs manageable
              if (_logs.length > 1000) {
                _logs.removeRange(0, _logs.length - 1000);
              }
            });

            if (_autoScroll) {
              _scrollToBottom();
            }
          }
        },
        onError: (error) {
          debugPrint('Log stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to listen to logs: $e');
    }
  }

  List<MCPLogEntry> _filterLogs(List<MCPLogEntry> logs) {
    return logs.where(_shouldShowLog).toList();
  }

  bool _shouldShowLog(MCPLogEntry log) {
    if (_selectedLogLevel == LogLevel.all) return true;
    return log.level.index >= _selectedLogLevel.index;
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isLoading) {
        _loadLogs();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _exportLogs() {
    // TODO: Implement log export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log export feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors(context);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Header with controls
          Container(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BorderRadiusTokens.md),
                topRight: Radius.circular(BorderRadiusTokens.md),
              ),
            ),
            child: Column(
              children: [
                // Title and main controls
                Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Text(
                      'MCP Server Logs',
                      style: TextStyles.labelMedium.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_autoScroll)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _autoScroll = true;
                                });
                                _scrollToBottom();
                              },
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: colors.primary,
                              ),
                              tooltip: 'Scroll to bottom',
                            ),
                          IconButton(
                            onPressed: _exportLogs,
                            icon: Icon(
                              Icons.download,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            tooltip: 'Export logs',
                          ),
                          IconButton(
                            onPressed: _clearLogs,
                            icon: Icon(
                              Icons.clear_all,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            tooltip: 'Clear logs',
                          ),
                          IconButton(
                            onPressed: _loadLogs,
                            icon: Icon(
                              Icons.refresh,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: SpacingTokens.sm),

                // Filters row
                Row(
                  children: [
                    // Server selector
                    if (_allServerIds.isNotEmpty) ...[
                      Text(
                        'Server:',
                        style: TextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                          border: Border.all(color: colors.border),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedServerId.isEmpty ? null : _selectedServerId,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _selectedServerId = value;
                              });
                              _loadLogs();
                              _listenToLogs();
                            }
                          },
                          underline: const SizedBox(),
                          style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                          items: _allServerIds.map((serverId) {
                            return DropdownMenuItem(
                              value: serverId,
                              child: Text(serverId),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                    ],

                    // Log level filter
                    Text(
                      'Level:',
                      style: TextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
                        border: Border.all(color: colors.border),
                      ),
                      child: DropdownButton<LogLevel>(
                        value: _selectedLogLevel,
                        onChanged: (LogLevel? value) {
                          if (value != null) {
                            setState(() {
                              _selectedLogLevel = value;
                            });
                            _loadLogs();
                          }
                        },
                        underline: const SizedBox(),
                        style: TextStyles.bodySmall.copyWith(color: colors.onSurface),
                        items: LogLevel.values.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level.displayName),
                          );
                        }).toList(),
                      ),
                    ),

                    const Spacer(),

                    // Log count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_logs.length} logs',
                        style: TextStyles.caption.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logs content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.sm),
              child: _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 32,
                            color: colors.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: SpacingTokens.sm),
                          Text(
                            _allServerIds.isEmpty
                                ? 'No MCP servers available'
                                : 'No logs available',
                            style: TextStyles.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: SpacingTokens.xs),
                          Text(
                            _allServerIds.isEmpty
                                ? 'Install MCP servers to see logs'
                                : 'Server logs will appear here when available',
                            style: TextStyles.bodySmall.copyWith(
                              color: colors.onSurfaceVariant.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return _buildLogEntry(log, colors);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(MCPLogEntry log, ThemeColors colors) {
    final levelColor = _getLogLevelColor(log.level, colors);
    final levelIcon = _getLogLevelIcon(log.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: log.level == LogLevel.error
            ? colors.error.withOpacity(0.05)
            : log.level == LogLevel.warning
                ? colors.warning.withOpacity(0.05)
                : null,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xs),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            _formatTimestamp(log.timestamp),
            style: TextStyles.caption.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),

          // Level indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: levelColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              levelIcon,
              size: 8,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),

          // Log content
          Expanded(
            child: SelectableText(
              log.message,
              style: TextStyles.bodySmall.copyWith(
                color: log.level == LogLevel.error ? colors.error : colors.onSurface,
                fontFamily: 'monospace',
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(LogLevel level, ThemeColors colors) {
    switch (level) {
      case LogLevel.error:
        return colors.error;
      case LogLevel.warning:
        return colors.warning;
      case LogLevel.info:
        return colors.primary;
      case LogLevel.debug:
        return colors.onSurfaceVariant;
      case LogLevel.trace:
        return colors.onSurfaceVariant.withOpacity(0.7);
      default:
        return colors.onSurface;
    }
  }

  IconData _getLogLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.trace:
        return Icons.visibility;
      default:
        return Icons.circle;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Log levels for filtering
enum LogLevel {
  all('All'),
  trace('Trace'),
  debug('Debug'),
  info('Info'),
  warning('Warning'),
  error('Error');

  const LogLevel(this.displayName);
  final String displayName;
}

/// MCP server log entry
class MCPLogEntry {
  final String serverId;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? metadata;

  const MCPLogEntry({
    required this.serverId,
    required this.timestamp,
    required this.level,
    required this.message,
    this.metadata,
  });

  factory MCPLogEntry.fromJson(Map<String, dynamic> json) {
    return MCPLogEntry(
      serverId: json['serverId'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      level: LogLevel.values.firstWhere(
        (l) => l.name.toLowerCase() == (json['level'] ?? '').toLowerCase(),
        orElse: () => LogLevel.info,
      ),
      message: json['message'] ?? '',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverId': serverId,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'metadata': metadata,
    };
  }
}
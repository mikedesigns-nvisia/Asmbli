import 'dart:async';
import 'package:flutter/material.dart';
import '../design_system.dart';
import '../../services/enhanced_mcp_testing_service.dart';
import '../../models/enhanced_mcp_template.dart';

/// Visual widgets for MCP server testing with real-time feedback
/// Shows progress, results, diagnostics, and troubleshooting guidance

/// Real-time connection testing widget
class MCPConnectionTester extends StatefulWidget {
  final String serverId;
  final EnhancedMCPTemplate template;
  final Map<String, dynamic> config;
  final VoidCallback? onTestComplete;
  final bool autoStart;

  const MCPConnectionTester({
    super.key,
    required this.serverId,
    required this.template,
    required this.config,
    this.onTestComplete,
    this.autoStart = false,
  });

  @override
  State<MCPConnectionTester> createState() => _MCPConnectionTesterState();
}

class _MCPConnectionTesterState extends State<MCPConnectionTester> with TickerProviderStateMixin {
  final _testingService = EnhancedMCPTestingService();
  TestResult? _currentResult;
  bool _isTesting = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTest();
      });
    }

    // Listen to test results
    _testingService.getTestStream(widget.serverId).listen((result) {
      if (mounted) {
        setState(() {
          _currentResult = result;
          _isTesting = result.isLoading;
        });

        if (!result.isLoading && widget.onTestComplete != null) {
          widget.onTestComplete!();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Test',
                      style: TextStyle(
                                                fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      widget.template.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isTesting) ...[
                AsmblButton.secondary(
                  text: 'Test Connection',
                  icon: Icons.play_arrow,
                  onPressed: _startTest,
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Test content
          _buildTestContent(context),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isTesting) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SemanticColors.primary.withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(SemanticColors.primary),
                ),
              ),
            ),
          );
        },
      );
    }

    if (_currentResult != null) {
      final color = _getStatusColor(_currentResult!.status);
      final icon = _getStatusIcon(_currentResult!.status);
      
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.cable,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  Widget _buildTestContent(BuildContext context) {
    if (_isTesting && _currentResult != null) {
      return _buildLoadingContent(context);
    }

    if (_currentResult != null) {
      return _buildResultContent(context);
    }

    return _buildInitialContent(context);
  }

  Widget _buildInitialContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to test connection',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Click "Test Connection" to verify your configuration',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _buildTestChecklist(context),
      ],
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentResult!.message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: SemanticColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          valueColor: const AlwaysStoppedAnimation(SemanticColors.primary),
          backgroundColor: SemanticColors.primary.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 8),
        Text(
          'This may take a few moments...',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildResultContent(BuildContext context) {
    final result = _currentResult!;
    final statusColor = _getStatusColor(result.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status message
        Row(
          children: [
            Icon(
              _getStatusIcon(result.status),
              color: statusColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),

        // Details
        if (result.details != null && result.details!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              result.details!,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'JetBrains Mono',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],

        // Metadata (for successful connections)
        if (result.isSuccess && result.metadata.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildMetadataDisplay(context, result.metadata),
        ],

        // Suggestions for errors/warnings
        if (result.suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSuggestions(context, result.suggestions, result.status),
        ],

        // Error details
        if (result.error != null && result.error!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text(
              'Technical Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.error!,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'JetBrains Mono',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTestChecklist(BuildContext context) {
    final requiredFields = widget.template.fields.where((f) => f.required).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Checklist:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...requiredFields.map((field) {
          final hasValue = widget.config[field.id] != null && 
                          widget.config[field.id].toString().isNotEmpty;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  hasValue ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 14,
                  color: hasValue ? SemanticColors.success : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.wifi_find,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Network connectivity',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetadataDisplay(BuildContext context, Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SemanticColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: SemanticColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connection Details:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: SemanticColors.success,
            ),
          ),
          const SizedBox(height: 6),
          ...metadata.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${_formatMetadataKey(entry.key)}: ${_formatMetadataValue(entry.value)}',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'JetBrains Mono',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, List<String> suggestions, TestStatus status) {
    final color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                'Suggestions:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(TestStatus status) {
    switch (status) {
      case TestStatus.loading:
        return SemanticColors.primary;
      case TestStatus.success:
        return SemanticColors.success;
      case TestStatus.warning:
        return Colors.orange;
      case TestStatus.error:
        return SemanticColors.error;
    }
  }

  IconData _getStatusIcon(TestStatus status) {
    switch (status) {
      case TestStatus.loading:
        return Icons.hourglass_empty;
      case TestStatus.success:
        return Icons.check_circle;
      case TestStatus.warning:
        return Icons.warning;
      case TestStatus.error:
        return Icons.error;
    }
  }

  String _formatMetadataKey(String key) {
    // Convert camelCase to readable format
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)!.toLowerCase()}')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatMetadataValue(dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is int && value > 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}MB';
    }
    return value.toString();
  }

  Future<void> _startTest() async {
    if (_isTesting) return;
    
    setState(() {
      _isTesting = true;
      _currentResult = null;
    });

    await _testingService.testConnection(
      widget.serverId,
      widget.template,
      widget.config,
    );
  }
}

/// Compact connection status indicator
class MCPConnectionStatus extends StatelessWidget {
  final TestResult? testResult;
  final VoidCallback? onTap;

  const MCPConnectionStatus({
    super.key,
    this.testResult,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (testResult == null) {
      return _buildUntestedStatus(context);
    }

    final color = _getStatusColor(testResult!.status);
    final icon = _getStatusIcon(testResult!.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                _getStatusText(testResult!.status),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUntestedStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Untested',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TestStatus status) {
    switch (status) {
      case TestStatus.loading:
        return Colors.blue;
      case TestStatus.success:
        return SemanticColors.success;
      case TestStatus.warning:
        return Colors.orange;
      case TestStatus.error:
        return SemanticColors.error;
    }
  }

  IconData _getStatusIcon(TestStatus status) {
    switch (status) {
      case TestStatus.loading:
        return Icons.hourglass_empty;
      case TestStatus.success:
        return Icons.check_circle;
      case TestStatus.warning:
        return Icons.warning;
      case TestStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(TestStatus status) {
    switch (status) {
      case TestStatus.loading:
        return 'Testing';
      case TestStatus.success:
        return 'Connected';
      case TestStatus.warning:
        return 'Warning';
      case TestStatus.error:
        return 'Error';
    }
  }
}

/// Health monitoring dashboard for multiple servers
class MCPHealthDashboard extends StatefulWidget {
  final List<String> serverIds;
  final Duration refreshInterval;

  const MCPHealthDashboard({
    super.key,
    required this.serverIds,
    this.refreshInterval = const Duration(minutes: 5),
  });

  @override
  State<MCPHealthDashboard> createState() => _MCPHealthDashboardState();
}

class _MCPHealthDashboardState extends State<MCPHealthDashboard> {
  final Map<String, TestResult?> _healthResults = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startHealthMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalServers = widget.serverIds.length;
    final connectedServers = _healthResults.values
        .where((result) => result?.isSuccess ?? false)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety,
                size: 20,
                color: SemanticColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Integration Health',
                style: TextStyle(
                                    fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '$connectedServers/$totalServers',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: connectedServers == totalServers
                      ? SemanticColors.success
                      : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: totalServers > 0 ? connectedServers / totalServers : 0,
            valueColor: AlwaysStoppedAnimation(
              connectedServers == totalServers
                  ? SemanticColors.success
                  : Colors.orange,
            ),
            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateTime.now().toString().substring(11, 16)}',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _startHealthMonitoring() {
    // Initial health check would be implemented here
    // _refreshTimer = Timer.periodic(widget.refreshInterval, (_) => _performHealthCheck());
  }
}
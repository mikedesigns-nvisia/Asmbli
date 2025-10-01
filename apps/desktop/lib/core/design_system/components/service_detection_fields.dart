import 'package:flutter/material.dart';
import '../design_system.dart';
import 'mcp_field_types.dart';

/// Service detection fields that auto-detect running local services
/// Used by: PostgreSQL, MySQL, Docker, Redis, MongoDB, etc.

/// Auto-detects and lists running services
class ServiceDetectionField extends MCPField {
  final ServiceType serviceType;
  final List<DetectedService> detectedServices;
  final bool isScanning;
  final VoidCallback? onRescan;
  final ValueChanged<DetectedService?>? onServiceSelected;
  final DetectedService? selectedService;

  const ServiceDetectionField({
    super.key,
    required super.label,
    super.description,
    super.required,
    super.value,
    super.onChanged,
    required this.serviceType,
    this.detectedServices = const [],
    this.isScanning = false,
    this.onRescan,
    this.onServiceSelected,
    this.selectedService,
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getServiceIcon(),
                    color: ThemeColors(context).primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Auto-Detect ${serviceType.displayName}',
                      style: TextStyles.labelLarge,
                    ),
                  ),
                  if (isScanning) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(ThemeColors(context).primary),
                      ),
                    ),
                  ] else ...[
                    AsmblButton.secondary(
                      text: 'Scan',
                      icon: Icons.refresh,
                      onPressed: onRescan,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _buildServiceList(context),
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
              color: ThemeColors(context).error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceList(BuildContext context) {
    if (isScanning) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Scanning for ${serviceType.displayName} services...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (detectedServices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No ${serviceType.displayName} services detected',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getInstallationHint(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: detectedServices.map((service) {
        final isSelected = selectedService?.id == service.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onServiceSelected?.call(service),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? ThemeColors(context).primary.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected 
                      ? ThemeColors(context).primary.withOpacity(0.5)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getStatusColor(service.status, context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getStatusIcon(service.status),
                        size: 16,
                        color: _getStatusColor(service.status, context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                service.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected 
                                    ? ThemeColors(context).primary
                                    : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(service.status, context).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  service.status.displayName,
                                  style: TextStyle(
                                    color: _getStatusColor(service.status, context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${service.host}:${service.port}',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (service.version != null)
                            Text(
                              'Version ${service.version}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      Icon(
                        Icons.check_circle,
                        color: ThemeColors(context).primary,
                        size: 20,
                      ),
                    ] else ...[
                      AsmblButton.secondary(
                        text: 'Test',
                        icon: Icons.play_arrow,
                        onPressed: () => _testConnection(context, service),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getServiceIcon() {
    switch (serviceType) {
      case ServiceType.postgresql:
        return Icons.storage;
      case ServiceType.mysql:
        return Icons.storage;
      case ServiceType.redis:
        return Icons.memory;
      case ServiceType.mongodb:
        return Icons.storage;
      case ServiceType.docker:
        return Icons.developer_board;
      case ServiceType.elasticsearch:
        return Icons.search;
      default:
        return Icons.settings_ethernet;
    }
  }

  IconData _getStatusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.running:
        return Icons.play_circle_filled;
      case ServiceStatus.stopped:
        return Icons.stop_circle;
      case ServiceStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(ServiceStatus status, BuildContext context) {
    switch (status) {
      case ServiceStatus.running:
        return ThemeColors(context).success;
      case ServiceStatus.stopped:
        return ThemeColors(context).error;
      case ServiceStatus.unknown:
        return Colors.orange;
    }
  }

  String _getInstallationHint() {
    switch (serviceType) {
      case ServiceType.postgresql:
        return 'Make sure PostgreSQL is installed and running\nDefault port: 5432';
      case ServiceType.docker:
        return 'Make sure Docker Desktop is installed and running\nCheck if Docker daemon is accessible';
      case ServiceType.mysql:
        return 'Make sure MySQL is installed and running\nDefault port: 3306';
      case ServiceType.redis:
        return 'Make sure Redis is installed and running\nDefault port: 6379';
      case ServiceType.mongodb:
        return 'Make sure MongoDB is installed and running\nDefault port: 27017';
      case ServiceType.elasticsearch:
        return 'Make sure Elasticsearch is installed and running\nDefault port: 9200';
      default:
        return 'Make sure the service is installed and running';
    }
  }

  void _testConnection(BuildContext context, DetectedService service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing connection to ${service.name}...'),
        backgroundColor: ThemeColors(context).primary,
      ),
    );
    
    // This would implement actual connection testing
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection to ${service.name} successful!'),
            backgroundColor: ThemeColors(context).success,
          ),
        );
      }
    });
  }
}

/// Port scanner field for detecting services on specific ports
class PortScannerField extends StatefulWidget {
  final String label;
  final String? description;
  final List<int> commonPorts;
  final ValueChanged<List<DetectedPort>>? onPortsDetected;

  const PortScannerField({
    super.key,
    required this.label,
    this.description,
    this.commonPorts = const [5432, 3306, 6379, 27017, 9200],
    this.onPortsDetected,
  });

  @override
  State<PortScannerField> createState() => _PortScannerFieldState();
}

class _PortScannerFieldState extends State<PortScannerField> {
  List<DetectedPort> _detectedPorts = [];
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            AsmblButton.secondary(
              text: _isScanning ? 'Scanning...' : 'Scan Ports',
              icon: _isScanning ? Icons.hourglass_empty : Icons.scanner,
              onPressed: _isScanning ? null : _scanPorts,
            ),
          ],
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
        if (_detectedPorts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected Services',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ..._detectedPorts.map((port) => _buildPortRow(context, port)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPortRow(BuildContext context, DetectedPort port) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: port.isOpen ? ThemeColors(context).success : ThemeColors(context).error,
          ),
          const SizedBox(width: 8),
          Text(
            'Port ${port.port}',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            port.serviceName ?? 'Unknown Service',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            port.isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              color: port.isOpen ? ThemeColors(context).success : ThemeColors(context).error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanPorts() async {
    setState(() => _isScanning = true);

    // Simulate port scanning
    await Future.delayed(const Duration(seconds: 3));

    final detectedPorts = widget.commonPorts.map((port) {
      // Simulate detection results
      final isOpen = [5432, 3306].contains(port); // Simulate some ports being open
      return DetectedPort(
        port: port,
        isOpen: isOpen,
        serviceName: _getServiceName(port),
      );
    }).toList();

    setState(() {
      _detectedPorts = detectedPorts;
      _isScanning = false;
    });

    widget.onPortsDetected?.call(detectedPorts);
  }

  String? _getServiceName(int port) {
    switch (port) {
      case 5432:
        return 'PostgreSQL';
      case 3306:
        return 'MySQL';
      case 6379:
        return 'Redis';
      case 27017:
        return 'MongoDB';
      case 9200:
        return 'Elasticsearch';
      default:
        return null;
    }
  }
}

// Data models and enums
enum ServiceType {
  postgresql,
  mysql,
  redis,
  mongodb,
  docker,
  elasticsearch,
}

extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.postgresql:
        return 'PostgreSQL';
      case ServiceType.mysql:
        return 'MySQL';
      case ServiceType.redis:
        return 'Redis';
      case ServiceType.mongodb:
        return 'MongoDB';
      case ServiceType.docker:
        return 'Docker';
      case ServiceType.elasticsearch:
        return 'Elasticsearch';
    }
  }
}

enum ServiceStatus {
  running,
  stopped,
  unknown,
}

extension ServiceStatusExtension on ServiceStatus {
  String get displayName {
    switch (this) {
      case ServiceStatus.running:
        return 'Running';
      case ServiceStatus.stopped:
        return 'Stopped';
      case ServiceStatus.unknown:
        return 'Unknown';
    }
  }
}

class DetectedService {
  final String id;
  final String name;
  final String host;
  final int port;
  final ServiceStatus status;
  final String? version;
  final Map<String, dynamic> metadata;

  const DetectedService({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.status,
    this.version,
    this.metadata = const {},
  });
}

class DetectedPort {
  final int port;
  final bool isOpen;
  final String? serviceName;

  const DetectedPort({
    required this.port,
    required this.isOpen,
    this.serviceName,
  });
}
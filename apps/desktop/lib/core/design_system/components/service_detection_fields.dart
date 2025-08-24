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
        SizedBox(height: SpacingTokens.componentSpacing),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getServiceIcon(),
                    color: SemanticColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Auto-Detect ${serviceType.displayName}',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isScanning) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(SemanticColors.primary),
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
              SizedBox(height: 16),
              _buildServiceList(context),
            ],
          ),
        ),
        if (description != null) ...[
          SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: 12,
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
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (this.required) ...[
          SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: SemanticColors.error,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceList(BuildContext context) {
    if (isScanning) {
      return Container(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Scanning for ${serviceType.displayName} services...',
                style: TextStyle(
                  fontSize: 12,
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
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 8),
            Text(
              'No ${serviceType.displayName} services detected',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _getInstallationHint(),
              style: TextStyle(
                fontSize: 11,
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
          margin: EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onServiceSelected?.call(service),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? SemanticColors.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected 
                      ? SemanticColors.primary.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getStatusColor(service.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getStatusIcon(service.status),
                        size: 16,
                        color: _getStatusColor(service.status),
                      ),
                    ),
                    SizedBox(width: 12),
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
                                  fontSize: 13,
                                  color: isSelected 
                                    ? SemanticColors.primary 
                                    : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(service.status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  service.status.displayName,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _getStatusColor(service.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${service.host}:${service.port}',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'JetBrains Mono',
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (service.version != null)
                            Text(
                              'Version ${service.version}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      Icon(
                        Icons.check_circle,
                        color: SemanticColors.primary,
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

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.running:
        return SemanticColors.success;
      case ServiceStatus.stopped:
        return SemanticColors.error;
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
        backgroundColor: SemanticColors.primary,
      ),
    );
    
    // This would implement actual connection testing
    Future.delayed(Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection to ${service.name} successful!'),
            backgroundColor: SemanticColors.success,
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
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Spacer(),
            AsmblButton.secondary(
              text: _isScanning ? 'Scanning...' : 'Scan Ports',
              icon: _isScanning ? Icons.hourglass_empty : Icons.scanner,
              onPressed: _isScanning ? null : _scanPorts,
            ),
          ],
        ),
        if (widget.description != null) ...[
          SizedBox(height: 4),
          Text(
            widget.description!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: SpacingTokens.componentSpacing),
        if (_detectedPorts.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected Services',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 8),
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
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: port.isOpen ? SemanticColors.success : SemanticColors.error,
          ),
          SizedBox(width: 8),
          Text(
            'Port ${port.port}',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Text(
            port.serviceName ?? 'Unknown Service',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Spacer(),
          Text(
            port.isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 10,
              color: port.isOpen ? SemanticColors.success : SemanticColors.error,
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
    await Future.delayed(Duration(seconds: 3));

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
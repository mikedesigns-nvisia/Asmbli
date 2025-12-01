class MCPToolInfo {
  final String serverId;
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const MCPToolInfo({
    required this.serverId,
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'serverId': serverId,
    'name': name,
    'description': description,
    'parameters': parameters,
  };

  factory MCPToolInfo.fromJson(Map<String, dynamic> json) => MCPToolInfo(
    serverId: json['serverId'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    parameters: json['parameters'] as Map<String, dynamic>,
  );
}

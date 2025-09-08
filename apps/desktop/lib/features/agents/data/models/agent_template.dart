class AgentTemplate {
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final bool mcpStack;
  final List<String> mcpServers;
  final String exampleUse;
  final int popularity;
  final bool isComingSoon;

  AgentTemplate({
    required this.name,
    required this.description,
    required this.category,
    required this.tags,
    required this.mcpStack,
    required this.mcpServers,
    required this.exampleUse,
    required this.popularity,
    this.isComingSoon = false,
  });
}
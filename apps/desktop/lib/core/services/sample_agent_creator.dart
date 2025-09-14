import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import '../di/service_locator.dart';

class SampleAgentCreator {
  static Future<void> createSampleAgents() async {
    try {
      final agentService = ServiceLocator.instance.get<AgentService>();
      
      // Check if we already have agents
      final existingAgents = await agentService.listAgents();
      if (existingAgents.isNotEmpty) {
        print('✅ Sample agents already exist, skipping creation');
        return;
      }

      final sampleAgents = [
        {
          'name': 'Research Assistant',
          'description': 'Academic research agent with citation management and fact-checking capabilities',
          'capabilities': ['research', 'analysis', 'citation', 'fact-checking'],
          'modelId': '',
          'mcpServers': ['brave-search', 'memory', 'filesystem'],
          'category': 'Research',
        },
        {
          'name': 'Code Reviewer', 
          'description': 'Automated code review with best practices and security checks',
          'capabilities': ['coding', 'debugging', 'code-review', 'testing'],
          'modelId': '',
          'mcpServers': ['github', 'git', 'filesystem', 'memory'],
          'category': 'Development',
        },
        {
          'name': 'Data Analyst',
          'description': 'Statistical analysis and visualization for business insights',
          'capabilities': ['data-analysis', 'visualization', 'statistics', 'reporting'],
          'modelId': '', 
          'mcpServers': ['postgres', 'python', 'jupyter', 'memory'],
          'category': 'Data Analysis',
        },
        {
          'name': 'Content Writer',
          'description': 'SEO-optimized content generation with tone customization',
          'capabilities': ['content-creation', 'editing', 'seo', 'copywriting'],
          'modelId': '',
          'mcpServers': ['brave-search', 'web-fetch', 'memory'],
          'category': 'Writing',
        },
      ];

      for (final agentData in sampleAgents) {
        try {
          final agent = Agent(
            id: 'agent_${DateTime.now().millisecondsSinceEpoch}_${agentData['name'].toString().replaceAll(' ', '_').toLowerCase()}',
            name: agentData['name'] as String,
            description: agentData['description'] as String,
            capabilities: List<String>.from(agentData['capabilities'] as List),
            status: AgentStatus.idle,
            configuration: {
              'category': agentData['category'],
              'modelId': 'gemma3:4b',
              'mcpServers': agentData['mcpServers'],
              'createdAt': DateTime.now().toIso8601String(),
              'lastUsed': _getRandomLastUsed(),
              'version': '1.0',
              'creator': 'sample_agent_creator',
            },
          );
          
          final createdAgent = await agentService.createAgent(agent);
          print('✅ Created sample agent: ${agentData['name']}');
        } catch (e) {
          print('❌ Error creating sample agent ${agentData['name']}: $e');
        }
      }
      
      print('✅ Sample agent creation completed');
    } catch (e) {
      print('❌ Sample agent creation failed: $e');
    }
  }

  static String _getRandomLastUsed() {
    final now = DateTime.now();
    final random = [
      now.subtract(const Duration(hours: 2)),
      now.subtract(const Duration(days: 1)),
      now.subtract(const Duration(days: 3)),
      now.subtract(const Duration(days: 7)),
    ];
    return random[DateTime.now().millisecond % random.length].toIso8601String();
  }
}
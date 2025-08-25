import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agent_engine_core/models/agent.dart';
import 'package:agent_engine_core/services/agent_service.dart';
import 'package:agent_engine_core/services/implementations/memory_agent_service.dart';

/// Provider for the agent service
final agentServiceProvider = Provider<AgentService>((ref) {
  return InMemoryAgentService();
});

/// Provider for the list of all agents
final agentsProvider = FutureProvider<List<Agent>>((ref) async {
  final agentService = ref.watch(agentServiceProvider);
  return await agentService.listAgents();
});

/// Provider for the currently active/selected agent
final activeAgentProvider = StateProvider<Agent?>((ref) => null);

/// Provider for a specific agent by ID
final agentProvider = FutureProvider.family<Agent, String>((ref, id) async {
  final agentService = ref.watch(agentServiceProvider);
  return await agentService.getAgent(id);
});

/// Provider for creating sample agents for demo purposes
final _sampleAgentsProvider = FutureProvider<List<Agent>>((ref) async {
  final agentService = ref.watch(agentServiceProvider);
  
  // Check if we already have agents
  final existingAgents = await agentService.listAgents();
  if (existingAgents.isNotEmpty) {
    return existingAgents;
  }
  
  // Create sample agents
  final sampleAgents = [
    Agent(
      id: 'research-assistant',
      name: 'Research Assistant',
      description: 'Academic research agent with citation management',
      capabilities: ['web-search', 'file-access', 'memory'],
      configuration: {
        'model': 'claude-3-5-sonnet',
        'temperature': 0.7,
        'maxTokens': 2048,
        'systemPrompt': 'You are a helpful research assistant specialized in academic research and citation management.',
        'mcpServers': ['brave-search', 'memory', 'files'],
      },
      status: AgentStatus.idle,
    ),
    Agent(
      id: 'code-helper',
      name: 'Code Helper',
      description: 'Development assistant for coding and debugging',
      capabilities: ['code-execution', 'git', 'github'],
      configuration: {
        'model': 'claude-3-5-sonnet',
        'temperature': 0.3,
        'maxTokens': 4096,
        'systemPrompt': 'You are an expert programming assistant that helps with coding, debugging, and development tasks.',
        'mcpServers': ['git', 'github', 'files'],
      },
      status: AgentStatus.idle,
    ),
    Agent(
      id: 'data-analyst',
      name: 'Data Analyst',
      description: 'Data analysis and visualization specialist',
      capabilities: ['data-analysis', 'postgres', 'python'],
      configuration: {
        'model': 'claude-3-5-sonnet',
        'temperature': 0.5,
        'maxTokens': 3072,
        'systemPrompt': 'You are a data analysis expert who helps with data processing, analysis, and visualization.',
        'mcpServers': ['postgres', 'files', 'python'],
      },
      status: AgentStatus.idle,
    ),
  ];
  
  // Create the agents
  for (final agent in sampleAgents) {
    await agentService.createAgent(agent);
  }
  
  return sampleAgents;
});

/// Notifier class for managing agent operations
class AgentNotifier extends StateNotifier<AsyncValue<List<Agent>>> {
  final AgentService _agentService;
  final Ref _ref;

  AgentNotifier(this._agentService, this._ref) : super(const AsyncValue.loading()) {
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      // Load sample agents first to ensure we have some
      await _ref.read(_sampleAgentsProvider.future);
      
      // Then load all agents
      final agents = await _agentService.listAgents();
      state = AsyncValue.data(agents);
      
      // Set first agent as active if none selected
      if (agents.isNotEmpty && _ref.read(activeAgentProvider) == null) {
        _ref.read(activeAgentProvider.notifier).state = agents.first;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createAgent(Agent agent) async {
    try {
      await _agentService.createAgent(agent);
      await _loadAgents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAgent(Agent agent) async {
    try {
      await _agentService.updateAgent(agent);
      await _loadAgents();
      
      // Update active agent if it was the one being updated
      final activeAgent = _ref.read(activeAgentProvider);
      if (activeAgent?.id == agent.id) {
        _ref.read(activeAgentProvider.notifier).state = agent;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAgent(String id) async {
    try {
      await _agentService.deleteAgent(id);
      await _loadAgents();
      
      // Clear active agent if it was deleted
      final activeAgent = _ref.read(activeAgentProvider);
      if (activeAgent?.id == id) {
        final agents = state.value ?? [];
        _ref.read(activeAgentProvider.notifier).state = 
            agents.isNotEmpty ? agents.first : null;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setAgentStatus(String id, AgentStatus status) async {
    try {
      await _agentService.setAgentStatus(id, status);
      await _loadAgents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void setActiveAgent(Agent? agent) {
    _ref.read(activeAgentProvider.notifier).state = agent;
  }
}

/// Provider for the agent notifier
final agentNotifierProvider = StateNotifierProvider<AgentNotifier, AsyncValue<List<Agent>>>((ref) {
  final agentService = ref.watch(agentServiceProvider);
  return AgentNotifier(agentService, ref);
});
/// DSPy Integration for Asmbli
///
/// This module provides the complete DSPy integration, replacing 50+ fragmented
/// services with a clean, unified API.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:asmbli/core/services/dspy/dspy.dart';
///
/// // In a ConsumerWidget:
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final dspy = ref.watch(dspyServiceProvider);
///     final isConnected = ref.watch(dspyIsConnectedProvider);
///
///     if (!isConnected) {
///       return Text('Connecting to DSPy backend...');
///     }
///
///     return ElevatedButton(
///       onPressed: () async {
///         // Simple chat
///         final chat = await dspy.chat('Hello!');
///         print(chat.response);
///
///         // Agent execution
///         final agent = ref.read(dspyAgentServiceProvider);
///         final result = await agent.execute(
///           agentId: 'my-agent',
///           task: 'Calculate compound interest',
///           mode: AgentExecutionMode.react,
///         );
///         print(result.answer);
///
///         // RAG query
///         final rag = ref.read(dspyRagServiceProvider);
///         final ragResult = await rag.query('What does the doc say?');
///         print(ragResult.answer);
///       },
///       child: Text('Execute'),
///     );
///   }
/// }
/// ```
///
/// ## Services Replaced
///
/// This module replaces these services with DSPy backend calls:
///
/// ### AI/LLM Services (→ DspyService)
/// - UnifiedLLMService
/// - ClaudeApiService
/// - OpenAIApiService
/// - OllamaService
/// - ReasoningLLMService
///
/// ### Agent Services (→ DspyAgentService)
/// - AgentBusinessService
/// - SmartAgentOrchestratorService
/// - AgentMCPIntegrationService
/// - StatefulAgentExecutor
/// - AgentTerminalManager
/// - AgentContextPromptService
/// - + 10 more
///
/// ### RAG/Vector Services (→ DspyRagService)
/// - RAGPipeline
/// - VectorContextRetrievalService
/// - VectorDatabaseService
/// - ContextVectorIngestionService
/// - StreamlinedVectorContextService
///
/// ### Conversation Services (→ DspyConversationService)
/// - ConversationBusinessService
/// - EnhancedConversationService
///
/// ## Architecture
///
/// ```
/// Flutter App (UI Layer)
///     │
///     ├── DspyService (connection, health, chat)
///     ├── DspyAgentService (agent CRUD, execution)
///     ├── DspyRagService (documents, queries)
///     └── DspyConversationService (messages, history)
///           │
///           ▼
/// DSPy Python Backend (AI Layer)
///     │
///     ├── /chat - Simple conversations
///     ├── /reasoning - CoT, ToT
///     ├── /agent/execute - ReAct agents
///     ├── /rag/query - Document Q&A
///     └── /documents - Document management
/// ```

library dspy;

// Core client and service
export 'dspy_client.dart';
export 'dspy_service.dart';

// High-level services
export 'dspy_agent_service.dart';
export 'dspy_rag_service.dart';
export 'dspy_conversation_service.dart';

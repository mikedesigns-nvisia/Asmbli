# DSPy Migration Guide

This guide explains how to migrate Asmbli from fragmented theoretical services to a unified DSPy-powered architecture.

## The Problem

Asmbli had **100+ services**, many of which were:
- Theoretical implementations that never ran in production
- Overlapping functionality (46 MCP services alone)
- Complex interdependencies that made testing impossible
- Local AI processing that was slow and unreliable

## The Solution

**DSPy backend** handles ALL AI operations:
- Proven framework (Stanford, ICLR 2024)
- Actually works out of the box
- Automatic prompt optimization
- Clean separation: Flutter = UI, Python = AI

## New Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Asmbli Flutter App                        │
│                     (UI Layer Only)                          │
├─────────────────────────────────────────────────────────────┤
│  DspyService          │ Connection, health, simple chat     │
│  DspyAgentService     │ Agent CRUD, task execution          │
│  DspyRagService       │ Document management, Q&A            │
│  DspyConversationService │ Message handling                 │
└───────────────────────┬─────────────────────────────────────┘
                        │ HTTP
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   DSPy Python Backend                        │
│                     (AI Layer)                               │
├─────────────────────────────────────────────────────────────┤
│  /chat               │ Simple conversations                 │
│  /reasoning          │ Chain-of-thought, Tree-of-thought    │
│  /agent/execute      │ ReAct agent with tools               │
│  /rag/query          │ Document retrieval + generation      │
│  /documents          │ Upload, list, delete                 │
│  /code/generate      │ Code generation                      │
└─────────────────────────────────────────────────────────────┘
```

## Services to Deprecate

### ❌ AI/LLM Services (replaced by DspyService)

| Old Service | Status | Replacement |
|-------------|--------|-------------|
| `UnifiedLLMService` | DEPRECATE | `DspyService.chat()` |
| `ClaudeApiService` | DEPRECATE | DSPy handles model routing |
| `OpenAIApiService` | DEPRECATE | DSPy handles model routing |
| `GoogleApiService` | DEPRECATE | DSPy handles model routing |
| `KimiApiService` | DEPRECATE | DSPy handles model routing |
| `OllamaService` | DEPRECATE | DSPy handles model routing |
| `ReasoningLLMService` | DEPRECATE | `DspyService.reason()` |
| `ApiLLMProvider` | DEPRECATE | DSPy backend |
| `LocalLLMProvider` | DEPRECATE | DSPy backend |

### ❌ Agent Services (replaced by DspyAgentService)

| Old Service | Status | Replacement |
|-------------|--------|-------------|
| `AgentBusinessService` | DEPRECATE | `DspyAgentService` |
| `SmartAgentOrchestratorService` | DEPRECATE | `DspyAgentService.executeAuto()` |
| `AgentMCPIntegrationService` | DEPRECATE | DSPy tools |
| `AgentMCPService` | DEPRECATE | DSPy tools |
| `AgentTerminalManager` | DELETE | Not needed |
| `AgentTerminalProvisioningService` | DELETE | Not needed |
| `StatefulAgentExecutor` | DEPRECATE | `DspyAgentService.execute()` |
| `AgentContextPromptService` | DEPRECATE | DSPy handles prompts |
| `AgentSystemPromptService` | DEPRECATE | DSPy handles prompts |
| `AgentStateManagementService` | SIMPLIFY | Just local state |
| `AgentToolRecommendationService` | DEPRECATE | DSPy auto-selects |
| `AgentModelRecommendationService` | DEPRECATE | DSPy auto-selects |

### ❌ RAG/Vector Services (replaced by DspyRagService)

| Old Service | Status | Replacement |
|-------------|--------|-------------|
| `RAGPipeline` | DEPRECATE | `DspyRagService.query()` |
| `VectorDatabaseService` | DEPRECATE | DSPy ChromaDB |
| `VectorContextRetrievalService` | DEPRECATE | `DspyRagService` |
| `StreamlinedVectorContextService` | DEPRECATE | `DspyRagService` |
| `ContextVectorIngestionService` | DEPRECATE | `DspyRagService.uploadDocument()` |
| `VectorIntegrationService` | DELETE | Not needed |
| `MacOSVectorDatabaseService` | DELETE | DSPy handles this |

### ❌ Conversation Services (replaced by DspyConversationService)

| Old Service | Status | Replacement |
|-------------|--------|-------------|
| `ConversationBusinessService` | DEPRECATE | `DspyConversationService` |
| `EnhancedConversationService` | DEPRECATE | `DspyConversationService` |

### ✅ Services to KEEP

These services handle UI/local concerns and should remain:

| Service | Reason |
|---------|--------|
| `ThemeService` | UI theming |
| `StorageService` | Local storage |
| `DesktopStorageService` | Platform storage |
| `SecureCredentialsService` | API keys |
| `FeatureFlagService` | Feature flags |
| `ModelConfigService` | Model config UI |
| `DesktopAgentService` | Local agent CRUD |
| `DesktopConversationService` | Local message storage |
| `DesignTokensService` | Design system |

## Migration Steps

### Step 1: Start DSPy Backend

```bash
cd dspy-backend
cp .env.example .env
# Edit .env with your OPENAI_API_KEY

pip install -e .
python tests/test_quick.py --basic  # Verify it works
python main.py  # Start server
```

### Step 2: Update Provider Setup

In your app initialization, configure the DSPy providers:

```dart
// In main.dart or your provider setup
final container = ProviderContainer(
  overrides: [
    // Configure DSPy URL
    dspyConfigProvider.overrideWithValue(
      DspyConfig(backendUrl: 'http://localhost:8000'),
    ),

    // Provide repositories
    conversationRepositoryProvider.overrideWithValue(
      DesktopConversationService(),
    ),
    agentRepositoryProvider.overrideWithValue(
      DesktopAgentService(),
    ),
  ],
);
```

### Step 3: Replace Service Calls

**Before (old way):**
```dart
final llmService = ref.watch(unifiedLLMServiceProvider);
final response = await llmService.chat(
  message: 'Hello',
  modelId: 'claude-3-sonnet',
);
print(response.content);
```

**After (DSPy way):**
```dart
final dspy = ref.watch(dspyServiceProvider);
final response = await dspy.chat('Hello');
print(response.response);
```

**Before (agent execution):**
```dart
final agentService = ref.watch(agentBusinessServiceProvider);
final result = await agentService.processMessage(
  conversationId: convId,
  content: 'Calculate 25 * 4',
  modelId: 'claude-3-sonnet',
  agentId: agentId,
);
```

**After (DSPy way):**
```dart
final agent = ref.watch(dspyAgentServiceProvider);
final result = await agent.execute(
  agentId: agentId,
  task: 'Calculate 25 * 4',
  mode: AgentExecutionMode.react,
);
print(result.answer);  // "100"
print(result.steps);   // See reasoning steps
```

**Before (RAG):**
```dart
final ragPipeline = RAGPipeline(...);
final response = await ragPipeline.generateWithContext(
  'What does the doc say?',
  documentIds: [docId],
);
```

**After (DSPy way):**
```dart
final rag = ref.watch(dspyRagServiceProvider);
final result = await rag.query(
  'What does the doc say?',
  documentIds: [docId],
);
print(result.answer);
print(result.sources);
```

### Step 4: Update UI Components

Chat screen example:

```dart
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dspy = ref.watch(dspyServiceProvider);
    final state = ref.watch(dspyStateProvider);
    final conversation = ref.watch(dspyConversationServiceProvider);

    return state.when(
      data: (dspyState) {
        if (!dspyState.isConnected) {
          return _buildConnecting();
        }
        return _buildChat(conversation);
      },
      loading: () => _buildLoading(),
      error: (e, _) => _buildError(e),
    );
  }

  Widget _buildChat(DspyConversationService conversation) {
    return Column(
      children: [
        // Message list
        Expanded(child: MessageList()),

        // Input
        ChatInput(
          onSend: (message) async {
            final response = await conversation.processMessage(
              conversationId: currentConversationId,
              content: message,
            );
            // UI updates automatically via providers
          },
        ),
      ],
    );
  }
}
```

### Step 5: Remove Deprecated Services

Once migration is complete, you can safely delete:

```bash
# These can be deleted entirely
rm lib/core/services/agent_terminal_manager.dart
rm lib/core/services/agent_terminal_provisioning_service.dart
rm lib/core/services/mcp_bridge_service.dart
rm lib/core/services/mcp_conversation_bridge_service.dart
rm lib/core/services/mcp_health_monitor.dart
rm lib/core/services/mcp_orchestrator.dart
rm lib/core/services/direct_mcp_agent_service.dart
rm lib/core/services/agent_mcp_communication_bridge.dart
rm lib/core/services/agent_mcp_configuration_service.dart

# These can be deprecated (keep for reference but don't use)
# Add @Deprecated annotation to their classes
```

## Testing the Migration

### 1. Test DSPy Backend

```bash
cd dspy-backend
python tests/test_quick.py --all
```

### 2. Test Dart Client

```bash
cd apps/desktop
flutter test test/integration/dspy_integration_test.dart
```

### 3. Test Full Flow

```dart
// In your app
void testDspyIntegration() async {
  final dspy = DspyService();
  await dspy.connect();

  // Chat
  final chat = await dspy.chat('What is 2+2?');
  assert(chat.response.contains('4'));

  // Agent
  final agent = DspyAgentService(dspy: dspy, repository: repo);
  final result = await agent.execute(
    agentId: 'test',
    task: 'Calculate 25 * 4',
  );
  assert(result.answer.contains('100'));

  // RAG
  final rag = DspyRagService(dspy: dspy);
  await rag.uploadDocument(title: 'Test', content: 'Flutter is great');
  final ragResult = await rag.query('What is great?');
  assert(ragResult.answer.toLowerCase().contains('flutter'));

  print('✅ All tests passed!');
}
```

## Benefits After Migration

| Metric | Before | After |
|--------|--------|-------|
| Services | 110+ | ~30 |
| Lines of AI code | 10,000+ | ~500 (client only) |
| Test coverage | 9% | Can reach 80%+ |
| Time to first working agent | Never achieved | 5 minutes |
| Prompt optimization | Manual | Automatic (DSPy) |
| Model switching | Requires code changes | Config change |

## FAQ

### Q: Do I need Python running all the time?
Yes, the DSPy backend needs to run. In production, deploy it as a service.

### Q: Can I still use local models (Ollama)?
Yes! Configure DSPy to use Ollama models. The Flutter app doesn't care which model is used.

### Q: What about MCP servers?
MCP is for tool integration. DSPy's ReAct agent can use tools defined in the backend. You can add MCP tool wrappers in the Python code.

### Q: Is this slower than local processing?
Network latency adds ~10-50ms. But DSPy's optimized prompts often make total response time faster.

### Q: Can I use this offline?
No, you need the backend. For offline, consider packaging DSPy backend with the app or using a local-only mode.

# Asmbli DSPy Backend

Production-ready AI agent infrastructure powered by [DSPy](https://dspy.ai/).

## Why DSPy?

DSPy is a framework for **programming—not prompting—language models**. Instead of writing brittle prompt strings, you define structured modules that DSPy can automatically optimize.

Key advantages:
- **Actually works** - battle-tested, peer-reviewed (ICLR 2024)
- **Automatic optimization** - prompts improve automatically based on examples
- **Structured I/O** - typed signatures prevent parsing errors
- **Modular** - compose modules like building blocks

## Quick Start

### 1. Install Dependencies

```bash
cd dspy-backend
pip install -e ".[dev]"
```

Or with uv (faster):
```bash
uv pip install -e ".[dev]"
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your API key(s)
```

Minimum required:
```
OPENAI_API_KEY=sk-your-key-here
# OR
ANTHROPIC_API_KEY=sk-ant-your-key-here
```

### 3. Test It Works

```bash
python tests/test_quick.py --basic
```

Expected output:
```
🧪 Testing DSPy Basic Functionality
✅ Using model: openai/gpt-4o-mini
✅ DSPy configured

📝 Test 1: Simple Prediction
   Question: What is 2 + 2?
   Answer: 4
   ✅ PASSED
...
🎉 All basic tests passed!
```

### 4. Start the Server

```bash
python main.py
```

Server runs at `http://localhost:8000`

- API Docs: http://localhost:8000/docs
- Health Check: http://localhost:8000/health

## API Endpoints

### Chat
Simple conversation:
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the capital of France?"}'
```

### RAG (Retrieval-Augmented Generation)
Query documents with context:
```bash
# First, upload a document
curl -X POST http://localhost:8000/documents/upload \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Auth Guide",
    "content": "Our authentication system uses JWT tokens..."
  }'

# Then query it
curl -X POST http://localhost:8000/rag/query \
  -H "Content-Type: application/json" \
  -d '{"question": "How does authentication work?"}'
```

### Agent Execution
Run a ReAct agent:
```bash
curl -X POST http://localhost:8000/agent/execute \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Calculate 25 * 4 + 100",
    "max_iterations": 5
  }'
```

### Reasoning
Apply structured reasoning:
```bash
curl -X POST http://localhost:8000/reasoning \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Should we use microservices or monolith?",
    "pattern": "tree_of_thought"
  }'
```

## Architecture

```
dspy-backend/
├── src/
│   ├── api/           # FastAPI endpoints
│   │   ├── server.py  # Main server
│   │   └── models.py  # Request/response schemas
│   ├── modules/       # DSPy modules
│   │   ├── rag.py     # RAG implementations
│   │   ├── agents.py  # ReAct agent
│   │   └── reasoning.py # CoT, ToT modules
│   └── config.py      # Configuration
├── tests/
│   └── test_quick.py  # Quick validation tests
├── main.py            # Entry point
└── pyproject.toml     # Dependencies
```

## Available Modules

### RAG Modules
- `SimpleRAG` - Basic retrieve + generate
- `RAGModule` - With citations and confidence
- `MultiHopRAG` - Multi-step retrieval for complex questions

### Agent Modules
- `ReActAgent` - Reason + Act loop with tools
- `CodeAgent` - Code generation with optional execution

### Reasoning Modules
- `ChainOfThoughtModule` - Step-by-step reasoning
- `TreeOfThoughtModule` - Explore multiple approaches
- `DecisionModule` - Decision making with confidence

## Calling from Flutter

The Asmbli Flutter app calls this backend via HTTP. Example Dart code:

```dart
class DspyService {
  final String baseUrl;
  final http.Client _client;

  Future<String> chat(String message) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    final data = jsonDecode(response.body);
    return data['response'];
  }

  Future<AgentResponse> executeAgent(String task) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/agent/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'task': task}),
    );
    return AgentResponse.fromJson(jsonDecode(response.body));
  }
}
```

## Development

### Run Tests
```bash
# Basic DSPy tests
python tests/test_quick.py --basic

# Module tests
python tests/test_quick.py --modules

# API tests (requires server running)
python tests/test_quick.py --api

# All tests
python tests/test_quick.py --all
```

### Code Formatting
```bash
black src/ tests/
ruff check src/ tests/ --fix
```

## Production Deployment

For production, consider:

1. **Use a proper vector database**: Replace ChromaDB with Pinecone, Weaviate, or Qdrant
2. **Add authentication**: API keys or OAuth
3. **Configure CORS properly**: Don't use `allow_origins=["*"]`
4. **Use a process manager**: gunicorn + uvicorn workers
5. **Add monitoring**: Prometheus metrics, structured logging

Example production start:
```bash
gunicorn src.api.server:app \
  -w 4 \
  -k uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000
```

## Troubleshooting

### "No API key found"
Set `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` in your `.env` file.

### "Module not found"
Run `pip install -e .` from the `dspy-backend` directory.

### "Could not connect to server"
Make sure the server is running with `python main.py`.

### Slow responses
- Try a faster model (gpt-4o-mini instead of gpt-4o)
- Reduce `max_iterations` for agents
- Use `num_passages=3` instead of 5 for RAG

## License

MIT License - see LICENSE file.

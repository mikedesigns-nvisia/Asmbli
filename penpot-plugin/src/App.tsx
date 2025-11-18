import { useState, useEffect, useRef } from 'react'

interface Message {
  id: string;
  type: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
  suggestions?: DesignSuggestion[];
  toolCalls?: ToolCall[];
}

interface DesignSuggestion {
  type: string;
  description: string;
  confidence: number;
  actions?: string[];
  tokensUsed?: string[];
}

interface ToolCall {
  tool: string;
  parameters: any;
  rationale?: string;
}

interface OllamaStatus {
  available: boolean;
  checking: boolean;
  error?: string;
}

function App() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [ollamaStatus, setOllamaStatus] = useState<OllamaStatus>({ available: false, checking: true });
  const [canvasInfo, setCanvasInfo] = useState({ elements: 0, selected: 0 });
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Listen for messages from the plugin
    const handleMessage = (event: MessageEvent) => {
      const message = event.data;

      if (message.type === 'ollama-status') {
        setOllamaStatus({
          available: message.available,
          checking: false,
          error: message.error,
        });
      }

      if (message.type === 'ai-design-response') {
        setIsProcessing(false);

        if (message.success) {
          const assistantMessage: Message = {
            id: Date.now().toString(),
            type: 'assistant',
            content: message.data.reasoning || 'Design updated successfully!',
            timestamp: new Date(),
            suggestions: message.data.suggestions,
            toolCalls: message.data.toolCalls,
          };
          setMessages((prev) => [...prev, assistantMessage]);

          // Show system message for tool execution
          if (message.data.toolCalls && message.data.toolCalls.length > 0) {
            const toolMessage: Message = {
              id: (Date.now() + 1).toString(),
              type: 'system',
              content: `Executed ${message.data.toolCalls.length} tool(s): ${message.data.toolCalls.map((t: ToolCall) => t.tool).join(', ')}`,
              timestamp: new Date(),
            };
            setMessages((prev) => [...prev, toolMessage]);
          }
        } else {
          const errorMessage: Message = {
            id: Date.now().toString(),
            type: 'system',
            content: `Error: ${message.error}`,
            timestamp: new Date(),
          };
          setMessages((prev) => [...prev, errorMessage]);
        }
      }

      if (message.type === 'canvas-state-update') {
        setCanvasInfo({
          elements: message.elementsCount || 0,
          selected: message.selectedCount || 0,
        });
      }
    };

    window.addEventListener('message', handleMessage);

    // Check Ollama status on mount
    parent.postMessage({ type: 'check-ollama-status' }, '*');

    return () => window.removeEventListener('message', handleMessage);
  }, []);

  useEffect(() => {
    // Auto-scroll to bottom when new messages arrive
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = () => {
    if (!inputValue.trim() || isProcessing) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      type: 'user',
      content: inputValue,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInputValue('');
    setIsProcessing(true);

    // Send AI request to plugin
    parent.postMessage({
      type: 'ai-design-request',
      prompt: inputValue,
    }, '*');
  };

  const handleQuickAction = (prompt: string) => {
    setInputValue(prompt);
    setTimeout(() => handleSendMessage(), 100);
  };

  const quickActions = [
    { label: '🎨 Create Hero Section', prompt: 'Create a hero section with heading, subheading, and CTA button' },
    { label: '📐 Add Grid Layout', prompt: 'Create a 3-column grid layout with cards' },
    { label: '🎯 Navigation Bar', prompt: 'Design a navigation bar with logo and menu items' },
    { label: '✨ Improve Spacing', prompt: 'Analyze and improve spacing consistency across elements' },
  ];

  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      height: '100vh',
      fontFamily: 'Space Grotesk, sans-serif',
      backgroundColor: '#F8F9FA',
    }}>
      {/* Header */}
      <div style={{
        padding: '16px',
        backgroundColor: '#FFFFFF',
        borderBottom: '1px solid #E5E7EB',
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ fontSize: '18px', margin: 0, fontWeight: 600 }}>Asmbli Design Agent</h2>
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            {/* Ollama Status */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '4px 8px',
              borderRadius: '4px',
              backgroundColor: ollamaStatus.available ? '#F0FDF4' : ollamaStatus.checking ? '#FEF3C7' : '#FEF2F2',
              fontSize: '11px',
              fontWeight: 500,
            }}>
              <span style={{
                width: '6px',
                height: '6px',
                borderRadius: '50%',
                backgroundColor: ollamaStatus.available ? '#10B981' : ollamaStatus.checking ? '#F59E0B' : '#EF4444',
              }}></span>
              {ollamaStatus.checking ? 'Checking...' : ollamaStatus.available ? 'AI Ready' : 'AI Offline'}
            </div>
            {/* Canvas Info */}
            <div style={{
              fontSize: '11px',
              color: '#6B7280',
              padding: '4px 8px',
              backgroundColor: '#F3F4F6',
              borderRadius: '4px',
            }}>
              {canvasInfo.elements} elements
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div style={{
        padding: '12px',
        backgroundColor: '#FFFFFF',
        borderBottom: '1px solid #E5E7EB',
        overflowX: 'auto',
      }}>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'nowrap' }}>
          {quickActions.map((action, index) => (
            <button
              key={index}
              onClick={() => handleQuickAction(action.prompt)}
              disabled={!ollamaStatus.available || isProcessing}
              style={{
                padding: '6px 12px',
                fontSize: '12px',
                fontWeight: 500,
                backgroundColor: '#FFFFFF',
                color: '#2D3E50',
                border: '1px solid #E5E7EB',
                borderRadius: '6px',
                cursor: ollamaStatus.available && !isProcessing ? 'pointer' : 'not-allowed',
                whiteSpace: 'nowrap',
                opacity: ollamaStatus.available && !isProcessing ? 1 : 0.5,
              }}
            >
              {action.label}
            </button>
          ))}
        </div>
      </div>

      {/* Messages */}
      <div style={{
        flex: 1,
        overflowY: 'auto',
        padding: '16px',
        display: 'flex',
        flexDirection: 'column',
        gap: '12px',
      }}>
        {messages.length === 0 && (
          <div style={{
            textAlign: 'center',
            color: '#6B7280',
            padding: '40px 20px',
          }}>
            <div style={{ fontSize: '32px', marginBottom: '12px' }}>🎨</div>
            <h3 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '8px', color: '#2D3E50' }}>
              Welcome to Asmbli Design Agent
            </h3>
            <p style={{ fontSize: '13px', lineHeight: '1.6', margin: 0 }}>
              Ask me to create designs, improve layouts, or apply your brand tokens.<br />
              Try a quick action above or type your own request below!
            </p>
          </div>
        )}

        {messages.map((msg) => (
          <div key={msg.id} style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: msg.type === 'user' ? 'flex-end' : 'flex-start',
          }}>
            <div style={{
              maxWidth: '85%',
              padding: '12px',
              borderRadius: '8px',
              backgroundColor: msg.type === 'user' ? '#4ECDC4' : msg.type === 'system' ? '#FEF3C7' : '#FFFFFF',
              color: msg.type === 'user' ? '#FFFFFF' : '#2D3E50',
              border: msg.type === 'assistant' ? '1px solid #E5E7EB' : 'none',
              fontSize: '13px',
              lineHeight: '1.6',
            }}>
              <div>{msg.content}</div>

              {/* Suggestions */}
              {msg.suggestions && msg.suggestions.length > 0 && (
                <div style={{ marginTop: '12px', paddingTop: '12px', borderTop: '1px solid #E5E7EB' }}>
                  <div style={{ fontSize: '11px', fontWeight: 600, marginBottom: '8px', color: '#6B7280' }}>
                    SUGGESTIONS
                  </div>
                  {msg.suggestions.map((suggestion, idx) => (
                    <div key={idx} style={{
                      padding: '8px',
                      backgroundColor: '#F9FAFB',
                      borderRadius: '4px',
                      marginBottom: '6px',
                      fontSize: '12px',
                    }}>
                      <div style={{ fontWeight: 600, marginBottom: '4px' }}>
                        {suggestion.type.toUpperCase()} ({Math.round(suggestion.confidence * 100)}%)
                      </div>
                      <div style={{ color: '#6B7280' }}>{suggestion.description}</div>
                      {suggestion.tokensUsed && suggestion.tokensUsed.length > 0 && (
                        <div style={{ marginTop: '4px', fontSize: '11px', color: '#10B981' }}>
                          🎨 {suggestion.tokensUsed.join(', ')}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}

              {/* Tool Calls */}
              {msg.toolCalls && msg.toolCalls.length > 0 && (
                <div style={{ marginTop: '12px', paddingTop: '12px', borderTop: '1px solid #E5E7EB' }}>
                  <div style={{ fontSize: '11px', fontWeight: 600, marginBottom: '8px', color: '#6B7280' }}>
                    EXECUTED TOOLS
                  </div>
                  {msg.toolCalls.map((tool, idx) => (
                    <div key={idx} style={{
                      padding: '8px',
                      backgroundColor: '#F0FDF4',
                      borderRadius: '4px',
                      marginBottom: '6px',
                      fontSize: '12px',
                    }}>
                      <div style={{ fontWeight: 600, color: '#10B981' }}>{tool.tool}</div>
                      {tool.rationale && (
                        <div style={{ color: '#6B7280', marginTop: '4px' }}>{tool.rationale}</div>
                      )}
                    </div>
                  ))}
                </div>
              )}

              <div style={{
                fontSize: '10px',
                color: msg.type === 'user' ? 'rgba(255,255,255,0.7)' : '#9CA3AF',
                marginTop: '6px',
              }}>
                {msg.timestamp.toLocaleTimeString()}
              </div>
            </div>
          </div>
        ))}

        {isProcessing && (
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '12px',
            backgroundColor: '#F3F4F6',
            borderRadius: '8px',
            fontSize: '13px',
            color: '#6B7280',
          }}>
            <div style={{
              width: '16px',
              height: '16px',
              border: '2px solid #E5E7EB',
              borderTopColor: '#4ECDC4',
              borderRadius: '50%',
              animation: 'spin 1s linear infinite',
            }}></div>
            Thinking...
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div style={{
        padding: '16px',
        backgroundColor: '#FFFFFF',
        borderTop: '1px solid #E5E7EB',
      }}>
        <div style={{ display: 'flex', gap: '8px' }}>
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
            placeholder={ollamaStatus.available ? "Ask me to design something..." : "AI is offline..."}
            disabled={!ollamaStatus.available || isProcessing}
            style={{
              flex: 1,
              padding: '12px',
              fontSize: '13px',
              border: '1px solid #E5E7EB',
              borderRadius: '6px',
              fontFamily: 'Space Grotesk, sans-serif',
              outline: 'none',
            }}
          />
          <button
            onClick={handleSendMessage}
            disabled={!inputValue.trim() || !ollamaStatus.available || isProcessing}
            style={{
              padding: '12px 20px',
              fontSize: '13px',
              fontWeight: 600,
              backgroundColor: inputValue.trim() && ollamaStatus.available && !isProcessing ? '#4ECDC4' : '#E5E7EB',
              color: inputValue.trim() && ollamaStatus.available && !isProcessing ? '#FFFFFF' : '#9CA3AF',
              border: 'none',
              borderRadius: '6px',
              cursor: inputValue.trim() && ollamaStatus.available && !isProcessing ? 'pointer' : 'not-allowed',
            }}
          >
            Send
          </button>
        </div>
      </div>

      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  )
}

export default App

# Asmbli Agent Builder - UI/UX Design Specification

## Overview
Integrate a streamlined agent builder directly into Asmbli (ChatMCP), transforming the complex external package generation into a seamless 3-step in-app experience.

## Design Philosophy
- **Simplicity First**: Reduce complexity from 6-step external process to 3-step in-app flow
- **Live Preview**: Show agent capabilities in real-time as user builds
- **Native Integration**: Feels like a natural ChatMCP feature, not an add-on
- **Instant Deployment**: From idea to working agent in under 30 seconds

---

## 🎯 User Flow Diagram

```
Current Asmbli Flow:
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Sidebar   │ ──▶│   New Chat   │ ──▶│  Chat Page  │
└─────────────┘    └──────────────┘    └─────────────┘

Enhanced Flow with Agent Builder:
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Sidebar   │ ──▶│   New Chat   │ ──▶│  Chat Page  │
│             │    └──────────────┘    └─────────────┘
│             │    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│             │ ──▶│Agent Builder │ ──▶│Agent Preview│ ──▶│Agent Chat    │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
```

---

## 📱 UI Layout Integration

### 1. Enhanced Sidebar Navigation

```
┌─ Asmbli Sidebar ─────────────────┐
│ ┌─────────────────────────────┐  │
│ │ 🏠 Home                     │  │ ← Existing
│ │ ➕ New Chat                 │  │ ← Existing
│ │ ⚡ Agent Builder    [NEW]   │  │ ← NEW FEATURE
│ │ ⚙️  Settings                │  │ ← Existing
│ └─────────────────────────────┘  │
│                                  │
│ Recent Chats:                    │
│ ┌─────────────────────────────┐  │
│ │ 💬 General Chat             │  │
│ │ 🤖 Developer Agent          │  │ ← Shows agent type
│ │ 🎨 Creator Agent            │  │ ← Shows agent type
│ │ 🔬 Research Agent           │  │ ← Shows agent type
│ └─────────────────────────────┘  │
└──────────────────────────────────┘
```

### 2. Agent Builder Main Interface

```
┌─ Agent Builder Page ─────────────────────────────────────────────────┐
│                                                                      │
│ ⚡ Agent Builder                                    [X] Close         │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                      │
│ ┌─ Step 1: Choose Your Role ──────────────┐ ┌─ Live Preview ───────┐ │
│ │                                         │ │                      │ │
│ │ 👨‍💻 Developer                             │ │ 🤖 Agent Name:       │ │
│ │ • Git & GitHub integration              │ │    Developer Agent   │ │
│ │ • Database tools                        │ │                      │ │
│ │ • File system access                    │ │ 🔧 Tools: 5          │ │
│ │ • Web APIs                              │ │ • Git                │ │
│ │ [●] Selected                            │ │ • GitHub             │ │
│ │                                         │ │ • Filesystem         │ │
│ │ 🎨 Creator                              │ │ • Database           │ │
│ │ • Design tools (Figma)                  │ │ • Web Fetch          │ │
│ │ • Content creation                      │ │                      │ │
│ │ • Media processing                      │ │ 🎯 Ready to deploy   │ │
│ │ [ ] Select                              │ │                      │ │
│ │                                         │ │ [Start Agent Chat]   │ │
│ │ 🔬 Researcher                           │ │                      │ │
│ │ • Web search & research                 │ │                      │ │
│ │ • Academic tools                        │ │                      │ │
│ │ • Data analysis                         │ │                      │ │
│ │ [ ] Select                              │ │                      │ │
│ └─────────────────────────────────────────┘ └──────────────────────┘ │
│                                                                      │
│ ┌─ Step 2: Customize Tools (Optional) ───────────────────────────────┐ │
│ │                                                                    │ │
│ │ Default tools for Developer selected. Add more:                    │ │
│ │                                                                    │ │
│ │ Available MCP Servers:                                             │ │
│ │ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                          │ │
│ │ │ 📝  │ │ 🔍  │ │ 💾  │ │ 🌐  │ │ 📊  │                          │ │
│ │ │Note │ │Srch │ │Memo │ │HTTP │ │Data │                          │ │
│ │ │ ✓   │ │  +  │ │  +  │ │  ✓  │ │  +  │                          │ │
│ │ └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                          │ │
│ └────────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ ┌─ Step 3: Communication Style ──────────────────────────────────────┐ │
│ │                                                                    │ │
│ │ Tone: [Technical ▼] Response Length: [Detailed ▼]                 │ │
│ │                                                                    │ │
│ │ Special Instructions (Optional):                                   │ │
│ │ ┌────────────────────────────────────────────────────────────────┐ │ │
│ │ │ Always include code examples when relevant                     │ │ │
│ │ │ Use TypeScript for complex examples                            │ │ │
│ │ │ Follow security best practices                                 │ │ │
│ │ └────────────────────────────────────────────────────────────────┘ │ │
│ └────────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│ ┌──────────────────────────────────────────────────────────────────────┐ │
│ │ [← Back]          [Save as Template]          [Start Agent Chat] │ │
│ └──────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Interaction Flow

### Flow 1: Quick Agent Creation (Power User)
```
1. Click "Agent Builder" in sidebar
2. Select "Developer" role (auto-selects optimal tools)
3. Click "Start Agent Chat"
   └─ Total time: ~10 seconds
```

### Flow 2: Custom Agent Creation  
```
1. Click "Agent Builder" in sidebar
2. Select "Developer" role
3. Customize tools (add/remove MCP servers)
4. Adjust communication style
5. Click "Start Agent Chat"
   └─ Total time: ~30 seconds
```

### Flow 3: Template Workflow
```
1. Create custom agent (Flow 2)
2. Click "Save as Template"
3. Future: Select template from dropdown
   └─ Reuse time: ~5 seconds
```

---

## 🎨 Visual Design Specifications

### Color Scheme (ChatMCP Native)
```css
/* Agent Builder specific colors */
--agent-builder-primary: #6366f1    /* Indigo for agent actions */
--agent-builder-success: #10b981    /* Green for ready states */
--agent-builder-accent: #f59e0b     /* Amber for highlights */

/* Role-specific colors */
--role-developer: #3b82f6          /* Blue */
--role-creator: #ec4899            /* Pink */  
--role-researcher: #8b5cf6         /* Purple */
```

### Typography
- **Headers**: ChatMCP native font (likely system font)
- **Body**: Consistent with ChatMCP UI
- **Code/Technical**: Monospace font for tool names

### Icons
- **Agent Builder**: ⚡ (Lightning bolt - suggests speed/power)
- **Developer**: 👨‍💻 or 🔧
- **Creator**: 🎨 or ✨  
- **Researcher**: 🔬 or 📚
- **Tools**: Native MCP server icons where available

---

## 📱 Responsive Behavior

### Desktop (Primary)
- **Full Layout**: Sidebar + Builder + Preview
- **Width**: Minimum 1024px for optimal experience
- **Preview Panel**: Always visible on right side

### Tablet 
- **Collapsed Sidebar**: Overlay behavior
- **Single Column**: Builder steps stack vertically
- **Preview**: Collapsible panel at bottom

### Mobile (Secondary)
- **Full Screen**: Agent builder takes full screen
- **Step Navigation**: Bottom navigation tabs
- **Preview**: Modal overlay when requested

---

## 🔧 Technical Integration Points

### 1. Navigation Integration
```dart
// lib/page/layout/sidebar.dart - Add Agent Builder option
Widget _buildAgentBuilderTile() {
  return ListTile(
    leading: Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
    title: Text(AppLocalizations.of(context)!.agentBuilder),
    onTap: () => Navigator.pushNamed(context, '/agent-builder'),
  );
}
```

### 2. Page Structure
```
lib/page/agent_builder/
├── agent_builder_page.dart        # Main page with stepper
├── widgets/
│   ├── role_selection_card.dart   # Role selection UI
│   ├── tool_selector.dart         # MCP server selection
│   ├── style_configurator.dart    # Communication style
│   └── agent_preview_panel.dart   # Live preview
└── models/
    └── agent_configuration.dart   # Data model
```

### 3. State Management
```dart
// lib/provider/agent_builder_provider.dart
class AgentBuilderProvider extends ChangeNotifier {
  AgentRole selectedRole = AgentRole.none;
  List<String> selectedTools = [];
  AgentStyle style = AgentStyle.balanced;
  
  void selectRole(AgentRole role) { /* ... */ }
  void toggleTool(String toolId) { /* ... */ }
  AgentConfiguration get configuration { /* ... */ }
}
```

---

## 🚀 Deployment Integration

### Chat Creation Enhancement
```dart
// Enhanced chat creation with agent support
Future<void> createAgentChat(AgentConfiguration config) async {
  // 1. Configure MCP servers based on agent config
  await mcpServerProvider.configureAgentServers(config.tools);
  
  // 2. Create new chat with agent metadata
  final chat = await chatProvider.createChat(
    title: "${config.role.name} Agent",
    agentConfig: config,
  );
  
  // 3. Navigate to chat page
  Navigator.pushReplacementNamed(context, '/chat/${chat.id}');
}
```

### Agent-Aware Chat Interface
```
┌─ Asmbli Chat with Agent ────────────────────────┐
│ 🤖 Developer Agent                    [⚙️ Config] │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                │
│ Agent: I'm your development assistant with     │
│ access to Git, GitHub, filesystem, database,   │
│ and web APIs. How can I help you code today?   │
│                                                │
│ You: Help me set up a new React project        │
│                                                │
│ Agent: I'll help you set up a React project.   │
│ Let me start by checking your current          │
│ directory and then create the project structure│
│                                                │
│ [Tool: filesystem] Checking current directory  │
│ [Tool: git] Initializing repository           │
│                                                │
│ ┌─────────────────────────────────────────────┐ │
│ │ 💬 How can I help you today?               │ │
│ └─────────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘
```

---

## 📊 Success Metrics

### User Experience Goals
- **Time to Agent**: < 30 seconds from idea to working agent
- **Complexity Reduction**: 6-step external → 3-step internal process  
- **Discoverability**: Agent builder visible in main navigation
- **Retention**: Users create multiple agent configurations

### Technical Goals
- **Performance**: Agent creation < 2 seconds
- **Reliability**: 99.9% successful agent deployments
- **Compatibility**: Works across all ChatMCP platforms
- **Maintainability**: Leverages existing ChatMCP architecture

---

## 🎯 Implementation Phases

### Phase 1: Core Builder (Week 1)
- [ ] Agent builder page structure
- [ ] Role selection interface  
- [ ] Basic tool selection
- [ ] Navigation integration

### Phase 2: Advanced Features (Week 2)
- [ ] Live preview panel
- [ ] Communication style configuration
- [ ] Template save/load system
- [ ] Agent deployment to chat

### Phase 3: Polish & Launch (Week 3)
- [ ] Responsive design optimization
- [ ] Error handling & validation
- [ ] Performance optimization
- [ ] Documentation & testing

---

This design creates a **seamless, native experience** that transforms Asmbli from just a chat client into a **complete AI agent development platform**. Users will be able to create custom agents faster than ever before, directly within the app they're already using.

**Ready to proceed with implementation?** 🚀
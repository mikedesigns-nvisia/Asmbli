# Asmbli - Agentic AI Coding & Design Experiment

An experimental Flutter desktop application exploring agentic AI patterns, conversational UX design, and product design for AI-powered tools.

## Project Overview

Asmbli is a research and design experiment that explores:

- **Agentic AI Patterns**: How can we create AI agents that feel like collaborative partners?
- **Conversational UX**: What makes AI chat interfaces intuitive and powerful?
- **Tool Integration**: How do we seamlessly connect AI agents to external tools?
- **Design Systems**: Building cohesive, themeable interfaces for AI applications

This is not a production application, but rather a playground for experimenting with AI UX patterns and agentic behaviors.

## Design Philosophy

### 🎨 UX Experiments

- **Multi-theme system**: 5 color schemes to explore visual preferences
- **Conversational flows**: Testing different chat paradigms
- **Agent personality**: How visual design affects perceived agent behavior
- **Information density**: Balancing power-user features with clarity

### 🤖 Agentic Patterns Explored

- **Agent templates**: Pre-configured personalities and capabilities
- **Tool integration**: MCP protocol for extending agent abilities
- **Context awareness**: Document integration and memory patterns
- **Multi-model switching**: How users think about different AI models

### 🛠️ Technical Experiments

- **Service architecture**: Exploring modular design (perhaps too modular!)
- **State management**: Reactive patterns with Riverpod
- **Local-first design**: Privacy-preserving AI interactions
- **Cross-platform Flutter**: Desktop-specific UI patterns

## Key Learnings

### What Worked Well

1. **Visual Design System**
   - Dynamic theming creates personalization
   - Component-based design scales well
   - Golden ratio spacing feels natural

2. **Agent Builder UX**
   - Templates lower barrier to entry
   - Visual configuration > text configs
   - Preview-as-you-build pattern effective

3. **Chat Interface**
   - Streaming responses feel more natural
   - Model switching mid-conversation useful
   - Context sidebar improves transparency

### Areas for Improvement

1. **Over-Architecture**
   - 110 services is too granular
   - Simpler patterns would suffice
   - Abstraction can hinder understanding

2. **Information Architecture**
   - Settings screen too dense (3000+ lines)
   - Need progressive disclosure
   - Cognitive load in configuration

3. **Agentic Behaviors**
   - Agents still feel like tools, not partners
   - Need more personality/memory
   - Tool use could be more intuitive

## Running the Experiment

```bash
# Prerequisites: Flutter 3.0+

# Clone and run
git clone https://github.com/your-org/Asmbli.git
cd Asmbli/apps/desktop
flutter pub get
flutter run
```

## Experiment Structure

```
lib/
├── core/
│   ├── design_system/   # Comprehensive theming experiment
│   └── services/        # Over-architected service layer (learning: too complex)
├── features/            # Feature-based organization (worked well)
│   ├── chat/           # Conversational UX experiments
│   ├── agents/         # Agent builder patterns
│   └── tools/          # MCP integration attempts
```

## Design Artifacts

### Screens & Flows
- **Home Dashboard**: Information hierarchy experiment
- **Chat Interface**: Conversational UX patterns
- **Agent Builder**: Visual configuration design
- **Settings**: Complex configuration UX (needs work)

### Design Tokens
- **Colors**: 5 complete color systems
- **Typography**: Fustat font family throughout
- **Spacing**: Golden ratio-based system
- **Components**: 50+ custom Flutter widgets

## Technical Patterns Explored

### Successful Patterns
- Feature-based module organization
- Reactive state with Riverpod
- Design system abstraction
- Protocol-based tool integration

### Failed Experiments
- 110-service architecture (too complex)
- Some MCP integration attempts
- Over-abstraction in places

## Insights for Future Projects

### Product Design
1. **Progressive disclosure** essential for complex tools
2. **Visual configuration** > text-based for non-developers
3. **Personality matters** in AI interactions
4. **Context visibility** builds trust

### Technical Architecture
1. **Start simple** - can always add abstraction
2. **Service boundaries** should match mental models
3. **Test early** - retroactive testing is painful
4. **Documentation** as you experiment saves time

### Agentic AI Patterns
1. **Templates accelerate** user onboarding
2. **Tool integration** needs dead-simple UX
3. **Conversation memory** creates relationship
4. **Model transparency** reduces confusion

## Future Exploration Areas

### Possible Future Features

**Agent Chaining**: Multi-agent workflows where specialized agents collaborate in sequences or parallel to complete complex tasks. Visual pipeline builders for creating agent workflows with handoff mechanics and shared context.

**Live Task Control**: Real-time visibility into agent actions with user controls to pause, modify, or redirect agent behavior. Progress indicators showing what agents are doing and estimated completion times.

**Headless + Modal Architecture**: Core agent engine running in background with just-in-time UI spawning. System tray integration for minimal presence while agents work across applications, with contextual interfaces appearing only when human input is needed.

**Additional Areas**:
- Voice interfaces for agents
- Emotional design in AI interactions
- Cross-application agent workflows

See [FUTURE_VISION.md](FUTURE_VISION.md) for detailed exploration of these concepts.

## Contributing to the Experiment

This is an open experiment! Feel free to:
- Try new UX patterns
- Experiment with agent behaviors
- Explore different architectures
- Share your learnings

## Not Production Ready

This is an experimental project for learning and exploration. It's not intended for production use but rather as:
- A testbed for AI UX patterns
- A reference for design decisions
- A playground for agentic behaviors
- A learning experience in Flutter desktop

## License

MIT - Use these experiments and learnings freely!

---

**An experiment in making AI feel more like a creative partner than a tool.**
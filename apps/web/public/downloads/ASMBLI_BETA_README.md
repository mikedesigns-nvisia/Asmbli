# Asmbli Beta v0.9.0 - macOS Installation Guide

Welcome to **Asmbli Beta** - Your powerful AI workspace for building intelligent agents with the Model Context Protocol (MCP).

## 📋 System Requirements

### Hardware Requirements
- **RAM**:
  - **Minimum**: 8GB
  - **Recommended**: 16GB or more (for optimal performance with local AI models)
- **Storage**: 10GB free space (additional space needed for AI models)
- **Processor**: 64-bit processor with 4+ cores recommended

### Software Requirements
- **macOS**: 10.15 (Catalina) or later
- **Apple Silicon (M1/M2/M3)** or **Intel** processors supported

## 🚀 Installation Instructions

### Step 1: Extract the Application
1. Locate the `Asmbli-Beta-0.9.0-macOS-unsigned.zip` file
2. Double-click to extract it
3. You should see `Asmbli.app` in the extracted folder

### Step 2: Install to Applications
1. Drag `Asmbli.app` to your **Applications** folder
2. This makes it accessible from Launchpad and Spotlight

### Step 3: First Launch (Important!)
Since this is an unsigned beta build, you'll need to bypass macOS Gatekeeper:

1. **Right-click** on `Asmbli.app` in Applications
2. Select **"Open"** from the context menu
3. Click **"Open"** in the security dialog that appears
4. The app will launch and remember this permission for future launches

**Alternative method if right-click doesn't work:**
1. Try to open Asmbli normally (it will be blocked)
2. Go to **System Preferences → Security & Privacy**
3. Click **"Open Anyway"** next to the Asmbli message

## ✨ What's New in Beta v0.9.0

- **Updated Welcome Experience**: Now shows "Asmbli Beta" branding
- **Fixed Local LLM Chat**: Improved Ollama integration for macOS
- **Theme-Aware UI**: Beautiful pulsing indicators that adapt to your chosen color scheme
- **Better Message Handling**: User messages now stay visible during AI responses
- **Enhanced System Requirements**: Clear RAM requirements for optimal performance

## 🎯 Key Features

- **🖥️ Professional Desktop Application**: Native macOS experience
- **🔧 60+ MCP Server Integrations**: GitHub, Microsoft 365, AWS, Google Cloud, Slack, and more
- **🎨 Multi-Color Scheme Support**: Choose from Mint Green, Cool Blue, Forest Green, or Sunset Orange
- **💬 Real-time Chat Interface**: Streaming conversations with context-aware responses
- **🔐 Enterprise Security**: OAuth 2.0, API key management, and secure credential storage
- **🎯 Agent Templates**: Pre-configured templates for common use cases
- **📊 Vector Knowledge Base**: Advanced context management and retrieval

## 💡 Getting Started

1. **Launch Asmbli** from Applications or Launchpad
2. **Complete the onboarding** - Configure your first AI model
3. **Add integrations** - Connect to your favorite services via MCP servers
4. **Create your first agent** - Use templates or build from scratch
5. **Start chatting** - Test your agent in real-time

## 🔧 Local AI Models (Ollama)

For the best experience with local AI models:

1. **Install Ollama** from [ollama.ai](https://ollama.ai)
2. **Download models**: `ollama pull llama2` or `ollama pull mistral`
3. **Configure in Asmbli**: Go to Settings → Models → Local Models
4. **Recommended models**: Llama 2 (7B), Mistral (7B), or Code Llama for coding tasks

## ⚠️ Beta Notes

- This is a **beta release** for testing and feedback
- **Unsigned build**: Requires the security bypass steps above
- **Report issues**: Send feedback to help improve the final release
- **Data backup**: Consider backing up your agents and conversations

## 🆘 Troubleshooting

### App won't open
- Make sure you followed the "First Launch" instructions above
- Check System Preferences → Security & Privacy for blocked app notifications

### Performance issues
- Ensure you have at least 8GB RAM (16GB recommended)
- Close other memory-intensive applications
- For local AI models, ensure Ollama is properly installed

### Can't connect to services
- Check your internet connection
- Verify API keys in Settings → Integrations
- Some MCP servers may require additional configuration

## 📞 Support & Feedback

This is a beta release - your feedback is valuable!

- **GitHub Issues**: Report bugs and feature requests
- **Documentation**: Check the built-in help system
- **Community**: Join discussions about MCP and AI agents

---

**Thank you for testing Asmbli Beta!** 🚀

Your feedback helps us build the future of AI agent development.
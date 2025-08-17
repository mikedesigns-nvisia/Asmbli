import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/agent_config.dart';
import '../services/agent_builder_service.dart';

class DeploymentPage extends StatefulWidget {
  final AgentConfig config;
  final Function(AgentConfig) onConfigChanged;

  const DeploymentPage({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<DeploymentPage> createState() => _DeploymentPageState();
}

class _DeploymentPageState extends State<DeploymentPage> {
  bool _isGenerating = false;
  bool _isGenerated = false;
  ChatMCPPackage? _package;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePackage();
  }

  Future<void> _generatePackage() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final package = await AgentBuilderService.generateChatMCPPackage(widget.config);
      await AgentBuilderService.saveAgentConfig(widget.config);
      
      setState(() {
        _package = package;
        _isGenerated = true;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  Future<void> _copyToClipboard(String content, String name) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating your agent configuration...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generatePackage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isGenerated || _package == null) {
      return const Center(child: Text('No package generated'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.rocket_launch, size: 32, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent Ready to Deploy!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                    Text(
                      '${widget.config.agentName} has been configured successfully',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Agent Name', widget.config.agentName),
                  _buildSummaryRow('Role', widget.config.role.name.toUpperCase()),
                  _buildSummaryRow('Extensions', '${widget.config.extensions.where((ext) => ext.enabled).length} selected'),
                  _buildSummaryRow('Environment', widget.config.targetEnvironment.name.toUpperCase()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Files section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generated Files',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _buildFileCard(
                        'chatmcp-config.json',
                        'Main configuration file for ChatMCP',
                        _package!.config.toJsonString(),
                        Icons.settings,
                        Colors.blue,
                      ),
                      _buildFileCard(
                        'chatmcp-setup.md',
                        'Complete setup guide and instructions',
                        _package!.setupGuide,
                        Icons.description,
                        Colors.green,
                      ),
                      _buildFileCard(
                        'environment-setup.md',
                        'Environment variables and configuration',
                        _package!.environmentSetup,
                        Icons.settings,
                        Colors.orange,
                      ),
                      _buildFileCard(
                        'install-chatmcp.sh',
                        'Unix/macOS installation script',
                        _package!.installScript,
                        Icons.terminal,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showChatMCPConfig(),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Configuration'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSetupGuide(),
                        icon: const Icon(Icons.help),
                        label: const Text('Setup Guide'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchChatMCP(),
                    icon: const Icon(Icons.launch),
                    label: const Text('Launch ChatMCP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(String filename, String description, String content, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(filename),
        subtitle: Text(description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _copyToClipboard(content, filename),
              icon: const Icon(Icons.copy),
              tooltip: 'Copy to clipboard',
            ),
            IconButton(
              onPressed: () => _showFileContent(filename, content),
              icon: const Icon(Icons.visibility),
              tooltip: 'View content',
            ),
          ],
        ),
      ),
    );
  }

  void _showFileContent(String filename, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    filename,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _copyToClipboard(content, filename),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to clipboard',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatMCPConfig() {
    _showFileContent('chatmcp-config.json', _package!.config.toJsonString());
  }

  void _showSetupGuide() {
    _showFileContent('chatmcp-setup.md', _package!.setupGuide);
  }

  void _launchChatMCP() {
    // This would integrate with the existing ChatMCP interface
    // For now, show instructions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Launch ChatMCP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To use your agent:'),
            const SizedBox(height: 8),
            const Text('1. Copy the configuration to your clipboard'),
            const Text('2. Open ChatMCP settings'),
            const Text('3. Import the configuration'),
            const Text('4. Start chatting with your agent!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _copyToClipboard(_package!.config.toJsonString(), 'Configuration');
                Navigator.pop(context);
              },
              child: const Text('Copy Configuration'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
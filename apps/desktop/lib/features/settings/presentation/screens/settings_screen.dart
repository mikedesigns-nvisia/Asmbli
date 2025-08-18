import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedTheme = 'System';
  bool enableNotifications = true;
  bool autoSync = true;
  bool enableAnalytics = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Settings
          _SectionHeader(title: 'General'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  subtitle: Text(selectedTheme),
                  trailing: DropdownButton<String>(
                    value: selectedTheme,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'System', child: Text('System')),
                      DropdownMenuItem(value: 'Light', child: Text('Light')),
                      DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedTheme = value!;
                      });
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive notifications for agent updates'),
                  value: enableNotifications,
                  onChanged: (value) {
                    setState(() {
                      enableNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.sync),
                  title: const Text('Auto Sync'),
                  subtitle: const Text('Automatically sync with cloud'),
                  value: autoSync,
                  onChanged: (value) {
                    setState(() {
                      autoSync = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // MCP Servers
          _SectionHeader(title: 'MCP Servers'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Filesystem Access'),
                  subtitle: const Text('Local file operations'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: const Text('Git Integration'),
                  subtitle: const Text('Git repository operations'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.api),
                  title: const Text('GitHub API'),
                  subtitle: const Text('GitHub repository access'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Configure'),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  onTap: () {
                    // Configure GitHub API
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.design_services),
                  title: const Text('Figma Integration'),
                  subtitle: const Text('Design file access'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Configure'),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  onTap: () {
                    // Configure Figma integration
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // API Keys
          _SectionHeader(title: 'API Keys'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('OpenAI'),
                  subtitle: const Text('GPT models'),
                  trailing: const Chip(
                    label: Text('Configured'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // Configure OpenAI API key
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Anthropic'),
                  subtitle: const Text('Claude models'),
                  trailing: const Chip(
                    label: Text('Not configured'),
                    backgroundColor: Colors.grey,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // Configure Anthropic API key
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Google'),
                  subtitle: const Text('Gemini models'),
                  trailing: const Chip(
                    label: Text('Not configured'),
                    backgroundColor: Colors.grey,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // Configure Google API key
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Privacy & Data
          _SectionHeader(title: 'Privacy & Data'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.analytics),
                  title: const Text('Usage Analytics'),
                  subtitle: const Text('Help improve AgentEngine'),
                  value: enableAnalytics,
                  onChanged: (value) {
                    setState(() {
                      enableAnalytics = value;
                    });
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download all your data'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Export user data
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Remove all local data'),
                  onTap: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Data'),
                        content: const Text(
                          'This will remove all your agents, settings, and cached data. This action cannot be undone.'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Clear all data
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About
          _SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Open help
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Open privacy policy
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A small, local presentation-only SettingsSection used by the extracted tab.
class SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const SettingsSection({Key? key, required this.title, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Extracted API Configuration tab.
///
/// This is intentionally presentation-only. The parent screen should pass
/// the list of configs and the callbacks for add/edit/delete/set-default.
class APIConfigurationTab extends ConsumerWidget {
  final List<Map<String, dynamic>> apiConfigs;
  final VoidCallback onAddApiKey;
  final void Function(String id) onDeleteApiKey;
  final void Function(Map<String, dynamic> apiConfig) onEditApiKey;
  final void Function(String id) onSetAsDefault;

  const APIConfigurationTab({
    Key? key,
    required this.apiConfigs,
    required this.onAddApiKey,
    required this.onDeleteApiKey,
    required this.onEditApiKey,
    required this.onSetAsDefault,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSection(
                title: 'Saved API Keys',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Manage your API keys for different providers and models.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    if (apiConfigs.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.api_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text('No API Keys Configured', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            Text('Add your first API key to start using the app with real AI models.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: onAddApiKey, child: const Text('Add API Key')),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      for (final cfg in apiConfigs) ...[
                        _buildApiConfigRow(context, cfg),
                        const SizedBox(height: 10),
                      ],
                    ],
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: ElevatedButton(onPressed: onAddApiKey, child: const Text('Add API Key'))),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SettingsSection(
                title: 'Security',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your API keys are stored locally and encrypted. They are never transmitted to our servers.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiConfigRow(BuildContext context, Map<String, dynamic> cfg) {
    final id = cfg['id']?.toString() ?? '';
    final name = cfg['name']?.toString() ?? 'API Key';
    final provider = cfg['provider']?.toString() ?? '';
    final model = cfg['model']?.toString() ?? '';
    final isDefault = cfg['isDefault'] == true;
    final isConfigured = cfg['isConfigured'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDefault ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isConfigured ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isConfigured ? Icons.check_circle : Icons.error, color: isConfigured ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: Text('DEFAULT', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$provider ${model.isNotEmpty ? '- $model' : ''}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),

          Wrap(spacing: 8, children: [
            if (!isDefault)
              OutlinedButton(onPressed: () => onSetAsDefault(id), child: const Text('Set Default')),
            OutlinedButton(onPressed: () => onEditApiKey(cfg), child: const Text('Edit')),
            TextButton(onPressed: () => onDeleteApiKey(id), child: const Text('Delete')),
          ]),
        ],
      ),
    );
  }
}

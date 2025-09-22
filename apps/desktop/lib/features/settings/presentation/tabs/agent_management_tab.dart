import 'package:flutter/material.dart';

// Presentation-only Agent Management tab. Parent should pass data and callbacks.
class AgentManagementTab extends StatelessWidget {
  final List<dynamic> agents; // AgentItem type exists in parent; keep dynamic to avoid import coupling
  final String selectedAgent;
  final String selectedTemplate;
  final String systemPrompt;
  final void Function(String) onSelectAgent;
  final void Function(String) onSelectTemplate;
  final VoidCallback onShowApiSelection;
  final VoidCallback onSavePrompt;
  final void Function(String) onUpdateSystemPrompt;
  final Widget apiAssignmentWidget;

  const AgentManagementTab({
    super.key,
    required this.agents,
    required this.selectedAgent,
    required this.selectedTemplate,
    required this.systemPrompt,
    required this.onSelectAgent,
    required this.onSelectTemplate,
    required this.onShowApiSelection,
    required this.onSavePrompt,
    required this.onUpdateSystemPrompt,
    required this.apiAssignmentWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Agent Selection Section
              Container(
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
                    Text('Agent Configuration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedAgent,
                            items: agents.map((a) => DropdownMenuItem(value: a.name.toString(), child: Text(a.name.toString()))).toList(),
                            onChanged: (v) => onSelectAgent(v ?? selectedAgent),
                            decoration: const InputDecoration(labelText: 'Select Agent'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedTemplate,
                            items: (agents.firstWhere((a) => a.name == selectedAgent).templates as List<dynamic>).map((t) => DropdownMenuItem(value: t.toString(), child: Text(t.toString()))).toList(),
                            onChanged: (v) => onSelectTemplate(v ?? selectedTemplate),
                            decoration: const InputDecoration(labelText: 'Template Variation'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Agent Info & API assignment
                    Text(agents.firstWhere((a) => a.name == selectedAgent).description.toString(), style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.api, size: 16),
                        const SizedBox(width: 8),
                        const Text('API:'),
                        const SizedBox(width: 8),
                        Expanded(child: apiAssignmentWidget),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onShowApiSelection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Change'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // System Prompt Editor
              Container(
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
                    Text('System Prompt', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: systemPrompt),
                      maxLines: 6,
                      onChanged: onUpdateSystemPrompt,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(onPressed: onSavePrompt, child: const Text('Save Prompt')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

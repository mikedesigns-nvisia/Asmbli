import 'package:flutter/material.dart';
import '../models/agent_config.dart';

class RoleSelectionPage extends StatefulWidget {
  final AgentConfig initialConfig;
  final Function(AgentConfig) onConfigChanged;

  const RoleSelectionPage({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  late AgentConfig _currentConfig;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.initialConfig;
  }

  void _updateRole(AgentRole role) {
    final updatedConfig = _currentConfig.copyWith(role: role);
    setState(() {
      _currentConfig = updatedConfig;
    });
    widget.onConfigChanged(updatedConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Agent\'s Role',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the primary role that best describes your agent\'s purpose',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              children: [
                _buildRoleCard(
                  role: AgentRole.developer,
                  title: 'Developer',
                  description: 'Code generation, debugging, and software development assistance',
                  icon: Icons.code,
                  color: Colors.blue,
                  features: [
                    'Code generation and review',
                    'Debugging assistance',
                    'Git and GitHub integration',
                    'Database management',
                    'API development',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  role: AgentRole.analyst,
                  title: 'Analyst',
                  description: 'Data analysis, research, and business intelligence',
                  icon: Icons.analytics,
                  color: Colors.green,
                  features: [
                    'Data analysis and visualization',
                    'Research and fact-checking',
                    'Report generation',
                    'Market research',
                    'Statistical analysis',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  role: AgentRole.assistant,
                  title: 'Assistant',
                  description: 'General purpose helper for various tasks',
                  icon: Icons.assistant,
                  color: Colors.purple,
                  features: [
                    'Task management',
                    'Email and communication',
                    'Scheduling and planning',
                    'Information lookup',
                    'General productivity',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  role: AgentRole.creative,
                  title: 'Creative',
                  description: 'Content creation, writing, and design assistance',
                  icon: Icons.palette,
                  color: Colors.pink,
                  features: [
                    'Content writing and editing',
                    'Creative brainstorming',
                    'Design assistance',
                    'Marketing copy',
                    'Social media content',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  role: AgentRole.specialist,
                  title: 'Specialist',
                  description: 'Domain-specific expertise and specialized knowledge',
                  icon: Icons.psychology,
                  color: Colors.orange,
                  features: [
                    'Domain expertise',
                    'Specialized knowledge',
                    'Technical consulting',
                    'Industry-specific tasks',
                    'Expert guidance',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  role: AgentRole.custom,
                  title: 'Custom',
                  description: 'Build a custom agent with specific capabilities',
                  icon: Icons.build,
                  color: Colors.grey,
                  features: [
                    'Flexible configuration',
                    'Custom capabilities',
                    'Tailored responses',
                    'Specific use cases',
                    'Unique combinations',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required AgentRole role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final isSelected = _currentConfig.role == role;
    
    return Card(
      elevation: isSelected ? 8 : 2,
      shadowColor: isSelected ? color.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _updateRole(role),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? color : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Key Features:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
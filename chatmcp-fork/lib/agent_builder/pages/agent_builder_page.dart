import 'package:flutter/material.dart';
import '../models/agent_config.dart';
import '../services/agent_builder_service.dart';
import 'extensions_selection_page.dart';
import 'role_selection_page.dart';
import 'deployment_page.dart';

class AgentBuilderPage extends StatefulWidget {
  const AgentBuilderPage({super.key});

  @override
  State<AgentBuilderPage> createState() => _AgentBuilderPageState();
}

class _AgentBuilderPageState extends State<AgentBuilderPage> {
  late PageController _pageController;
  int _currentStep = 0;
  late AgentConfig _config;
  final List<String> _stepTitles = [
    'Agent Profile',
    'Select Role', 
    'Choose Extensions',
    'Configuration',
    'Deploy'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _config = AgentBuilderService.createDefaultConfig();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateConfig(AgentConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Agent Profile
        return _config.agentName.isNotEmpty && 
               _config.agentDescription.isNotEmpty &&
               _config.primaryPurpose.isNotEmpty;
      case 1: // Role Selection
        return true; // Role has default value
      case 2: // Extensions
        return _config.extensions.any((ext) => ext.enabled);
      case 3: // Configuration
        return true; // Optional step
      case 4: // Deploy
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitles[_currentStep]),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _stepTitles.length,
            backgroundColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _stepTitles.asMap().entries.map((entry) {
                final index = entry.key;
                final title = entry.value;
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? Colors.green
                                    : isActive
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.withValues(alpha: 0.3),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isActive ? Colors.white : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isActive || isCompleted
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (index < _stepTitles.length - 1)
                        Container(
                          width: 20,
                          height: 2,
                          color: isCompleted
                              ? Colors.green
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildAgentProfileStep(),
                RoleSelectionPage(
                  initialConfig: _config,
                  onConfigChanged: _updateConfig,
                ),
                ExtensionsSelectionPage(
                  initialConfig: _config,
                  onConfigChanged: _updateConfig,
                ),
                _buildConfigurationStep(),
                DeploymentPage(
                  config: _config,
                  onConfigChanged: _updateConfig,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              child: Text(_currentStep == _stepTitles.length - 1 ? 'Complete' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentProfileStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Your Agent',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define the basic information for your AI agent',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Agent Name',
              hintText: 'e.g., Developer Assistant',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (value) {
              _updateConfig(_config.copyWith(agentName: value));
            },
          ),
          const SizedBox(height: 16),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of what your agent does',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            onChanged: (value) {
              _updateConfig(_config.copyWith(agentDescription: value));
            },
          ),
          const SizedBox(height: 16),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Primary Purpose',
              hintText: 'What is the main goal of this agent?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.track_changes),
            ),
            maxLines: 2,
            onChanged: (value) {
              _updateConfig(_config.copyWith(primaryPurpose: value));
            },
          ),
          const SizedBox(height: 24),
          
          // Environment selection
          Text(
            'Target Environment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TargetEnvironment>(
            segments: const [
              ButtonSegment(
                value: TargetEnvironment.development,
                label: Text('Development'),
                icon: Icon(Icons.code),
              ),
              ButtonSegment(
                value: TargetEnvironment.staging,
                label: Text('Staging'),
                icon: Icon(Icons.preview),
              ),
              ButtonSegment(
                value: TargetEnvironment.production,
                label: Text('Production'),
                icon: Icon(Icons.rocket_launch),
              ),
            ],
            selected: {_config.targetEnvironment},
            onSelectionChanged: (Set<TargetEnvironment> selection) {
              _updateConfig(_config.copyWith(targetEnvironment: selection.first));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fine-tune your agent\'s behavior and constraints',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          
          // Response length
          Text(
            'Response Length',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _config.responseLength.toDouble(),
            min: 100,
            max: 2000,
            divisions: 19,
            label: '${_config.responseLength} words',
            onChanged: (value) {
              _updateConfig(_config.copyWith(responseLength: value.round()));
            },
          ),
          const SizedBox(height: 24),
          
          // Security settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Rate Limiting'),
                    subtitle: const Text('Prevent abuse by limiting requests'),
                    value: _config.security.rateLimiting,
                    onChanged: (value) {
                      _updateConfig(_config.copyWith(
                        security: _config.security.copyWith(rateLimiting: value),
                      ));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Audit Logging'),
                    subtitle: const Text('Log all interactions for review'),
                    value: _config.security.auditLogging,
                    onChanged: (value) {
                      _updateConfig(_config.copyWith(
                        security: _config.security.copyWith(auditLogging: value),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
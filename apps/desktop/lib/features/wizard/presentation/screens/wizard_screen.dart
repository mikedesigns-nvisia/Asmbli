import 'package:flutter/material.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  int currentStep = 0;
  final PageController _pageController = PageController();

  final List<String> stepTitles = [
    'Agent Profile',
    'MCP Servers',
    'Security & Access',
    'Behavior & Style',
    'Test & Validate',
    'Deploy'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Configuration Wizard'),
        bottom: PreferredSize(
          preferredSize: const Size.double.infinity, 60,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < stepTitles.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= currentStep
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i <= currentStep ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stepTitles[i],
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (currentStep + 1) / stepTitles.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          
          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentStep = index;
                });
              },
              children: [
                _buildAgentProfileStep(),
                _buildMCPServersStep(),
                _buildSecurityStep(),
                _buildBehaviorStep(),
                _buildTestStep(),
                _buildDeployStep(),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                    ),
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox(),
                
                ElevatedButton(
                  onPressed: () {
                    if (currentStep < stepTitles.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Deploy agent
                      _deployAgent();
                    }
                  },
                  child: Text(
                    currentStep == stepTitles.length - 1 ? 'Deploy Agent' : 'Next'
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentProfileStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Agent Profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Define your agent\'s basic information and primary purpose',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Agent Name',
              hintText: 'e.g., Research Assistant',
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of what this agent does',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Primary Purpose',
            ),
            items: const [
              DropdownMenuItem(value: 'research', child: Text('Research & Analysis')),
              DropdownMenuItem(value: 'writing', child: Text('Content Writing')),
              DropdownMenuItem(value: 'development', child: Text('Software Development')),
              DropdownMenuItem(value: 'support', child: Text('Customer Support')),
              DropdownMenuItem(value: 'general', child: Text('General Assistant')),
            ],
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildMCPServersStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: MCP Servers',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Select which Model Context Protocol servers your agent should connect to',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          // This would show available MCP servers with checkboxes
          const Text('Available MCP servers will be listed here with configuration options.'),
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text('Security configuration step placeholder'),
    );
  }

  Widget _buildBehaviorStep() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text('Behavior and style configuration step placeholder'),
    );
  }

  Widget _buildTestStep() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text('Test and validation step placeholder'),
    );
  }

  Widget _buildDeployStep() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text('Deployment configuration step placeholder'),
    );
  }

  void _deployAgent() {
    // Show deployment success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agent Deployed Successfully'),
        content: const Text('Your agent has been configured and is ready to use.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to home
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
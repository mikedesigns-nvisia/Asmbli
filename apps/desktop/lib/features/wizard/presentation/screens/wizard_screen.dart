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
 title: Text('Agent Configuration Wizard'),
 bottom: PreferredSize(
 preferredSize: const Size.fromHeight(60),
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
 SizedBox(height: 4),
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
 duration: Duration(milliseconds: 300),
 curve: Curves.easeInOut,
 );
 },
 style: ElevatedButton.styleFrom(
 backgroundColor: Colors.grey.shade200,
 foregroundColor: Colors.grey.shade800,
 ),
 child: Text('Previous'),
 )
 else
 const SizedBox(),
 
 ElevatedButton(
 onPressed: () {
 if (currentStep < stepTitles.length - 1) {
 _pageController.nextPage(
 duration: Duration(milliseconds: 300),
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
 SizedBox(height: 8),
 Text(
				"Define your agent's basic information and primary purpose",
 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
 color: Colors.grey.shade600,
 ),
 ),
 SizedBox(height: 32),
 
 TextField(
 decoration: InputDecoration(
 labelText: 'Agent Name',
 hintText: 'e.g., Research Assistant',
 ),
 ),
 SizedBox(height: 16),
 
 TextField(
 decoration: const InputDecoration(
 labelText: 'Description',
 hintText: 'Brief description of what this agent does',
 ),
 maxLines: 3,
 ),
 SizedBox(height: 16),
 
 DropdownButtonFormField<String>(
 decoration: const InputDecoration(
 labelText: 'Primary Purpose',
 ),
 items: const [
 DropdownMenuItem(value: 'research', child: const Text('Research & Analysis')),
 DropdownMenuItem(value: 'writing', child: const Text('Content Writing')),
 DropdownMenuItem(value: 'development', child: const Text('Software Development')),
 DropdownMenuItem(value: 'support', child: const Text('Customer Support')),
 DropdownMenuItem(value: 'general', child: const Text('General Assistant')),
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
 SizedBox(height: 8),
 Text(
 'Select which Model Context Protocol servers your agent should connect to',
 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
 color: Colors.grey.shade600,
 ),
 ),
 SizedBox(height: 32),
 
 // This would show available MCP servers with checkboxes
 const Text('Available MCP servers will be listed here with configuration options.'),
 ],
 ),
 );
 }

 Widget _buildSecurityStep() {
 return Padding(
 padding: const EdgeInsets.all(24),
 child: const Text('Security configuration step placeholder'),
 );
 }

 Widget _buildBehaviorStep() {
 return Padding(
 padding: const EdgeInsets.all(24),
 child: const Text('Behavior and style configuration step placeholder'),
 );
 }

 Widget _buildTestStep() {
 return Padding(
 padding: const EdgeInsets.all(24),
 child: const Text('Test and validation step placeholder'),
 );
 }

 Widget _buildDeployStep() {
 return Padding(
 padding: const EdgeInsets.all(24),
 child: const Text('Deployment configuration step placeholder'),
 );
 }

 void _deployAgent() {
 // Show deployment success dialog
 showDialog(
 context: context,
 builder: (context) => AlertDialog(
 title: Text('Agent Deployed Successfully'),
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
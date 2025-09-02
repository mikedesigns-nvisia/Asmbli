import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

class WizardScreen extends StatefulWidget {
 const WizardScreen({super.key});

 @override
 State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
 int currentStep = 0;
 final PageController _pageController = PageController();
 
 // Security settings
 bool _requireApiKeyEncryption = true;
 String _authenticationLevel = 'standard';
 bool _enableAuditLogging = false;
 String _privacyLevel = 'balanced';
 
 // Behavior settings
 String _personality = 'professional';
 String _responseStyle = 'detailed';
 double _creativityLevel = 0.7;
 bool _enableEmojis = false;
 
 // Test settings
 final List<String> _testQueries = [];
 bool _connectivityTestPassed = false;
 final TextEditingController _testQueryController = TextEditingController();

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
				"Define your agent's basic information and primary purpose",
 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
 color: Colors.grey.shade600,
 ),
 ),
 const SizedBox(height: 32),
 
 const TextField(
 decoration: InputDecoration(
 labelText: 'Agent Name',
 hintText: 'e.g., Research Assistant',
 ),
 ),
 const SizedBox(height: 16),
 
 const TextField(
 decoration: InputDecoration(
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
 final colors = ThemeColors(context);
 
 return SingleChildScrollView(
 padding: const EdgeInsets.all(SpacingTokens.xxl),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Step 3: Security & Access',
 style: TextStyles.pageTitle,
 ),
 const SizedBox(height: SpacingTokens.sm),
 Text(
 'Configure security settings and access controls for your agent',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: SpacingTokens.xxl),

 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'API Security',
 style: TextStyles.headingMedium,
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 CheckboxListTile(
 title: const Text('Require API Key Encryption'),
 subtitle: const Text('Encrypt API keys in storage'),
 value: _requireApiKeyEncryption,
 onChanged: (value) {
 setState(() {
 _requireApiKeyEncryption = value ?? true;
 });
 },
 ),
 
 const SizedBox(height: SpacingTokens.md),
 
 Text(
 'Authentication Level',
 style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
 ),
 const SizedBox(height: SpacingTokens.sm),
 
 DropdownButtonFormField<String>(
 initialValue: _authenticationLevel,
 decoration: const InputDecoration(
 labelText: 'Authentication Level',
 ),
 items: const [
 DropdownMenuItem(value: 'basic', child: Text('Basic')),
 DropdownMenuItem(value: 'standard', child: Text('Standard')),
 DropdownMenuItem(value: 'enhanced', child: Text('Enhanced')),
 ],
 onChanged: (value) {
 if (value != null) {
 setState(() {
 _authenticationLevel = value;
 });
 }
 },
 ),
 ],
 ),
 ),
 ),
 
 const SizedBox(height: SpacingTokens.lg),
 
 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Privacy & Compliance',
 style: TextStyles.headingMedium,
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 CheckboxListTile(
 title: const Text('Enable Audit Logging'),
 subtitle: const Text('Log all agent interactions for compliance'),
 value: _enableAuditLogging,
 onChanged: (value) {
 setState(() {
 _enableAuditLogging = value ?? false;
 });
 },
 ),
 
 const SizedBox(height: SpacingTokens.md),
 
 Text(
 'Privacy Level',
 style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
 ),
 const SizedBox(height: SpacingTokens.sm),
 
 DropdownButtonFormField<String>(
 initialValue: _privacyLevel,
 decoration: const InputDecoration(
 labelText: 'Privacy Level',
 ),
 items: const [
 DropdownMenuItem(value: 'minimal', child: Text('Minimal - Basic privacy')),
 DropdownMenuItem(value: 'balanced', child: Text('Balanced - Standard privacy')),
 DropdownMenuItem(value: 'strict', child: Text('Strict - Maximum privacy')),
 ],
 onChanged: (value) {
 if (value != null) {
 setState(() {
 _privacyLevel = value;
 });
 }
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

 Widget _buildBehaviorStep() {
 final colors = ThemeColors(context);
 
 return SingleChildScrollView(
 padding: const EdgeInsets.all(SpacingTokens.xxl),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Step 4: Behavior & Style',
 style: TextStyles.pageTitle,
 ),
 const SizedBox(height: SpacingTokens.sm),
 Text(
 'Define how your agent communicates and behaves in conversations',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: SpacingTokens.xxl),

 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Communication Style',
 style: TextStyles.headingMedium,
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 Text(
 'Personality',
 style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
 ),
 const SizedBox(height: SpacingTokens.sm),
 
 DropdownButtonFormField<String>(
 initialValue: _personality,
 decoration: const InputDecoration(
 labelText: 'Agent Personality',
 ),
 items: const [
 DropdownMenuItem(value: 'professional', child: Text('Professional')),
 DropdownMenuItem(value: 'friendly', child: Text('Friendly')),
 DropdownMenuItem(value: 'casual', child: Text('Casual')),
 DropdownMenuItem(value: 'formal', child: Text('Formal')),
 DropdownMenuItem(value: 'enthusiastic', child: Text('Enthusiastic')),
 ],
 onChanged: (value) {
 if (value != null) {
 setState(() {
 _personality = value;
 });
 }
 },
 ),
 
 const SizedBox(height: SpacingTokens.lg),
 
 Text(
 'Response Style',
 style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
 ),
 const SizedBox(height: SpacingTokens.sm),
 
 DropdownButtonFormField<String>(
 initialValue: _responseStyle,
 decoration: const InputDecoration(
 labelText: 'Response Length',
 ),
 items: const [
 DropdownMenuItem(value: 'concise', child: Text('Concise - Brief responses')),
 DropdownMenuItem(value: 'detailed', child: Text('Detailed - Comprehensive responses')),
 DropdownMenuItem(value: 'adaptive', child: Text('Adaptive - Matches user style')),
 ],
 onChanged: (value) {
 if (value != null) {
 setState(() {
 _responseStyle = value;
 });
 }
 },
 ),
 ],
 ),
 ),
 ),
 
 const SizedBox(height: SpacingTokens.lg),
 
 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Creative Settings',
 style: TextStyles.headingMedium,
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 Text(
 'Creativity Level: ${(_creativityLevel * 100).round()}%',
 style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
 ),
 const SizedBox(height: SpacingTokens.sm),
 
 Slider(
 value: _creativityLevel,
 min: 0.0,
 max: 1.0,
 divisions: 10,
 onChanged: (value) {
 setState(() {
 _creativityLevel = value;
 });
 },
 ),
 
 Text(
 _creativityLevel < 0.3 ? 'Conservative - Factual and predictable' :
 _creativityLevel < 0.7 ? 'Balanced - Mix of creativity and accuracy' :
 'Creative - Original and inventive',
 style: TextStyles.bodySmall.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 
 const SizedBox(height: SpacingTokens.lg),
 
 CheckboxListTile(
 title: const Text('Enable Emojis'),
 subtitle: const Text('Use emojis to enhance communication'),
 value: _enableEmojis,
 onChanged: (value) {
 setState(() {
 _enableEmojis = value ?? false;
 });
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

 Widget _buildTestStep() {
 final colors = ThemeColors(context);
 
 return SingleChildScrollView(
 padding: const EdgeInsets.all(SpacingTokens.xxl),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Step 5: Test & Validate',
 style: TextStyles.pageTitle,
 ),
 const SizedBox(height: SpacingTokens.sm),
 Text(
 'Test your agent configuration and validate it works as expected',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: SpacingTokens.xxl),

 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Test Queries',
 style: TextStyles.headingMedium,
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 TextField(
 controller: _testQueryController,
 decoration: InputDecoration(
 labelText: 'Add Test Query',
 hintText: 'Enter a question to test your agent with',
 suffixIcon: IconButton(
 icon: const Icon(Icons.add),
 onPressed: () {
 if (_testQueryController.text.isNotEmpty) {
 setState(() {
 _testQueries.add(_testQueryController.text);
 _testQueryController.clear();
 });
 }
 },
 ),
 ),
 ),
 
 const SizedBox(height: SpacingTokens.md),
 
 if (_testQueries.isNotEmpty) ...[
 Text(
 'Test Queries (${_testQueries.length})',
 style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
 ),
 const SizedBox(height: SpacingTokens.sm),
 
 Container(
 constraints: const BoxConstraints(maxHeight: 200),
 child: ListView.builder(
 itemCount: _testQueries.length,
 itemBuilder: (context, index) {
 return ListTile(
 title: Text(_testQueries[index]),
 trailing: IconButton(
 icon: const Icon(Icons.delete_outline),
 onPressed: () {
 setState(() {
 _testQueries.removeAt(index);
 });
 },
 ),
 );
 },
 ),
 ),
 ],
 ],
 ),
 ),
 ),
 
 const SizedBox(height: SpacingTokens.lg),
 
 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Connectivity Test',
 style: TextStyles.headingMedium,
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 Row(
 children: [
 Icon(
 _connectivityTestPassed ? Icons.check_circle : Icons.pending,
 color: _connectivityTestPassed ? Colors.green : colors.onSurfaceVariant,
 ),
 const SizedBox(width: SpacingTokens.sm),
 Expanded(
 child: Text(
 _connectivityTestPassed 
 ? 'MCP servers connectivity verified'
 : 'Test MCP server connections',
 style: TextStyles.bodyMedium,
 ),
 ),
 ],
 ),
 
 const SizedBox(height: SpacingTokens.md),
 
 AsmblButton.secondary(
 text: 'Run Connectivity Test',
 onPressed: _runConnectivityTest,
 ),
 ],
 ),
 ),
 ),
 
 const SizedBox(height: SpacingTokens.lg),
 
 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Configuration Summary',
 style: TextStyles.headingMedium,
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 Text('Security: $_authenticationLevel authentication'),
 Text('Privacy: $_privacyLevel level'),
 Text('Personality: $_personality'),
 Text('Response Style: $_responseStyle'),
 Text('Creativity: ${(_creativityLevel * 100).round()}%'),
 Text('Emojis: ${_enableEmojis ? 'Enabled' : 'Disabled'}'),
 Text('Test Queries: ${_testQueries.length} added'),
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildDeployStep() {
 final colors = ThemeColors(context);
 
 return SingleChildScrollView(
 padding: const EdgeInsets.all(SpacingTokens.xxl),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Step 6: Deploy',
 style: TextStyles.pageTitle,
 ),
 const SizedBox(height: SpacingTokens.sm),
 Text(
 'Review your configuration and deploy your agent',
 style: TextStyles.bodyMedium.copyWith(
 color: colors.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: SpacingTokens.xxl),

 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(Icons.check_circle, color: colors.primary),
 const SizedBox(width: SpacingTokens.sm),
 Text(
 'Configuration Complete',
 style: TextStyles.headingMedium,
 ),
 ],
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 Text(
 'Your agent is ready to be deployed with the following configuration:',
 style: TextStyles.bodyMedium,
 ),
 const SizedBox(height: SpacingTokens.md),
 
 _buildConfigurationOverview(colors),
 ],
 ),
 ),
 ),
 
 const SizedBox(height: SpacingTokens.lg),
 
 AsmblCard(
 child: Padding(
 padding: const EdgeInsets.all(SpacingTokens.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Deployment Options',
 style: TextStyles.headingMedium,
 ),
 const SizedBox(height: SpacingTokens.lg),
 
 ListTile(
 leading: Icon(Icons.rocket_launch, color: colors.primary),
 title: const Text('Deploy Immediately'),
 subtitle: const Text('Start your agent right away'),
 ),
 
 const SizedBox(height: SpacingTokens.sm),
 
 ListTile(
 leading: Icon(Icons.schedule, color: colors.primary),
 title: const Text('Schedule Deployment'),
 subtitle: const Text('Deploy at a specific time'),
 ),
 
 const SizedBox(height: SpacingTokens.sm),
 
 ListTile(
 leading: Icon(Icons.save, color: colors.primary),
 title: const Text('Save as Draft'),
 subtitle: const Text('Save configuration for later'),
 ),
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }

 void _runConnectivityTest() async {
 setState(() {
 _connectivityTestPassed = false;
 });
 
 // Simulate connectivity test
 await Future.delayed(const Duration(seconds: 2));
 
 setState(() {
 _connectivityTestPassed = true;
 });
 }

 Widget _buildConfigurationOverview(ThemeColors colors) {
 return Container(
 padding: const EdgeInsets.all(SpacingTokens.md),
 decoration: BoxDecoration(
 color: colors.surface.withOpacity(0.5),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: colors.border),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 _buildOverviewItem('Security Level', _authenticationLevel),
 _buildOverviewItem('Privacy Level', _privacyLevel),
 _buildOverviewItem('Personality', _personality),
 _buildOverviewItem('Response Style', _responseStyle),
 _buildOverviewItem('Creativity', '${(_creativityLevel * 100).round()}%'),
 _buildOverviewItem('Emojis', _enableEmojis ? 'Enabled' : 'Disabled'),
 _buildOverviewItem('Test Queries', '${_testQueries.length} configured'),
 _buildOverviewItem('Connectivity', _connectivityTestPassed ? 'Verified' : 'Pending'),
 ],
 ),
 );
 }

 Widget _buildOverviewItem(String label, String value) {
 return Padding(
 padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
 child: Row(
 children: [
 SizedBox(
 width: 120,
 child: Text(
 '$label:',
 style: TextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
 ),
 ),
 Expanded(
 child: Text(
 value,
 style: TextStyles.bodyMedium,
 ),
 ),
 ],
 ),
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
 _testQueryController.dispose();
 super.dispose();
 }
}
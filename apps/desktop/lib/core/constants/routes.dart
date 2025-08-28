/// Centralized route constants for the AgentEngine desktop app
class AppRoutes {
 // Private constructor to prevent instantiation
 AppRoutes._();
 
 // Main routes
 static const String home = '/';
 static const String chat = '/chat';
 static const String settings = '/settings';
 static const String agents = '/agents';
 static const String context = '/context';
 static const String wizard = '/wizard';
 static const String agentWizard = '/agent-wizard';
 static const String integrations = '/integrations';
 static const String integrationHub = '/integration-hub';
 
 // Demo route (remove after video recording)
 static const String demoChat = '/demo-chat';
 
 // Route names for easier identification
 static const Map<String, String> routeNames = {
 home: 'Home',
 chat: 'Chat',
 settings: 'Settings',
 agents: 'My Agents',
 context: 'Context',
 wizard: 'Wizard',
 agentWizard: 'Create Agent',
 integrations: 'Add Integrations',
 integrationHub: 'Integration Hub',
 demoChat: 'Demo Chat', // Remove after video
 };
 
 // Helper method to get route name
 static String getRouteName(String route) {
 return routeNames[route] ?? 'Unknown';
 }
 
 // All valid routes list
 static const List<String> allRoutes = [
 home,
 chat,
 settings,
 agents,
 context,
 wizard,
 agentWizard,
 integrations,
 integrationHub,
 demoChat, // Remove after video
 ];
}
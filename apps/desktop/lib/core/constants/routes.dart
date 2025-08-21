/// Centralized route constants for the AgentEngine desktop app
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();
  
  // Main routes
  static const String home = '/';
  static const String chat = '/chat';
  static const String templates = '/templates';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String agents = '/agents';
  static const String wizard = '/wizard';
  
  // Route names for easier identification
  static const Map<String, String> routeNames = {
    home: 'Home',
    chat: 'Chat',
    templates: 'Templates',
    dashboard: 'Dashboard',
    settings: 'Settings',
    agents: 'My Agents',
    wizard: 'Wizard',
  };
  
  // Helper method to get route name
  static String getRouteName(String route) {
    return routeNames[route] ?? 'Unknown';
  }
  
  // All valid routes list
  static const List<String> allRoutes = [
    home,
    chat,
    templates,
    dashboard,
    settings,
    agents,
    wizard,
  ];
}
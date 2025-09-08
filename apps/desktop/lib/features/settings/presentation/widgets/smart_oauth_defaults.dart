import 'package:flutter/material.dart';
import '../../../../core/models/oauth_provider.dart';
import '../../../../core/services/oauth_extensions.dart';

/// Smart defaults for OAuth configuration with minimal user input
class SmartOAuthDefaults {
  
  /// Get recommended scopes based on common use cases
  static List<String> getRecommendedScopes(OAuthProvider provider, {String? useCase}) {
    switch (provider) {
      case OAuthProvider.github:
        return _getGitHubDefaults(useCase);
      case OAuthProvider.slack:
        return _getSlackDefaults(useCase);
      case OAuthProvider.linear:
        return _getLinearDefaults(useCase);
      case OAuthProvider.microsoft:
        return _getMicrosoftDefaults(useCase);
      default:
        return [];
    }
  }

  static List<String> _getGitHubDefaults(String? useCase) {
    switch (useCase) {
      case 'code_assistant':
        return ['user', 'repo', 'public_repo'];
      case 'basic':
        return ['user', 'public_repo'];
      case 'full_access':
        return ['user', 'repo', 'user:email', 'repo:status'];
      default:
        return ['user', 'public_repo']; // Safe default
    }
  }

  static List<String> _getSlackDefaults(String? useCase) {
    switch (useCase) {
      case 'notifications':
        return ['users:read', 'channels:read', 'chat:write'];
      case 'basic':
        return ['users:read', 'channels:read'];
      case 'full_access':
        return ['users:read', 'channels:read', 'chat:write', 'files:read'];
      default:
        return ['users:read', 'channels:read']; // Safe default
    }
  }

  static List<String> _getLinearDefaults(String? useCase) {
    switch (useCase) {
      case 'task_management':
        return ['read', 'write'];
      case 'basic':
        return ['read'];
      default:
        return ['read']; // Safe default
    }
  }

  static List<String> _getMicrosoftDefaults(String? useCase) {
    switch (useCase) {
      case 'productivity':
        return ['User.Read', 'Files.ReadWrite', 'Calendars.ReadWrite'];
      case 'basic':
        return ['User.Read'];
      case 'email':
        return ['User.Read', 'Mail.Read'];
      default:
        return ['User.Read']; // Safe default
    }
  }

  /// Get user-friendly use case descriptions
  static List<UseCaseOption> getUseCases(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return [
          UseCaseOption(
            id: 'basic',
            title: 'Basic Profile Access',
            description: 'View public profile and repositories',
            icon: Icons.person,
            isRecommended: true,
          ),
          UseCaseOption(
            id: 'code_assistant',
            title: 'Code Assistant',
            description: 'Help with code, access private repos',
            icon: Icons.code,
            isRecommended: false,
          ),
          UseCaseOption(
            id: 'full_access',
            title: 'Full Integration',
            description: 'Complete access for advanced features',
            icon: Icons.admin_panel_settings,
            isRecommended: false,
          ),
        ];
      case OAuthProvider.slack:
        return [
          UseCaseOption(
            id: 'basic',
            title: 'View Workspace',
            description: 'See channels and team members',
            icon: Icons.visibility,
            isRecommended: true,
          ),
          UseCaseOption(
            id: 'notifications',
            title: 'Send Notifications',
            description: 'Send messages and notifications',
            icon: Icons.notifications,
            isRecommended: false,
          ),
        ];
      case OAuthProvider.linear:
        return [
          UseCaseOption(
            id: 'basic',
            title: 'View Issues',
            description: 'Read-only access to issues and projects',
            icon: Icons.visibility,
            isRecommended: true,
          ),
          UseCaseOption(
            id: 'task_management',
            title: 'Manage Tasks',
            description: 'Create and update issues',
            icon: Icons.edit,
            isRecommended: false,
          ),
        ];
      case OAuthProvider.microsoft:
        return [
          UseCaseOption(
            id: 'basic',
            title: 'Basic Profile',
            description: 'Sign in and view profile',
            icon: Icons.person,
            isRecommended: true,
          ),
          UseCaseOption(
            id: 'email',
            title: 'Email Access',
            description: 'Read and manage email',
            icon: Icons.email,
            isRecommended: false,
          ),
          UseCaseOption(
            id: 'productivity',
            title: 'Full Productivity',
            description: 'Files, calendar, and email access',
            icon: Icons.work,
            isRecommended: false,
          ),
        ];
      default:
        return [];
    }
  }

  /// Get smart settings based on provider and user context
  static OAuthProviderSettings getSmartSettings(OAuthProvider provider) {
    return OAuthProviderSettings(
      autoRefresh: true,
      refreshThresholdMinutes: _getOptimalRefreshThreshold(provider),
      timeoutSeconds: _getOptimalTimeout(provider),
      maxRetryAttempts: 3,
      enableMonitoring: true,
    );
  }

  static int _getOptimalRefreshThreshold(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return 60; // 1 hour before expiry
      case OAuthProvider.slack:
        return 30; // 30 minutes before expiry
      case OAuthProvider.linear:
        return 60; // 1 hour before expiry
      case OAuthProvider.microsoft:
        return 30; // 30 minutes before expiry
      default:
        return 60;
    }
  }

  static int _getOptimalTimeout(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.github:
        return 30; // GitHub is generally fast
      case OAuthProvider.slack:
        return 45; // Slack can be slower
      case OAuthProvider.linear:
        return 30; // Linear is fast
      case OAuthProvider.microsoft:
        return 60; // Microsoft can be slower
      default:
        return 30;
    }
  }

  /// Analyze existing connections and suggest optimizations
  static List<SmartSuggestion> analyzePlatformUsage(List<OAuthProvider> connectedProviders) {
    final suggestions = <SmartSuggestion>[];

    // Suggest complementary integrations
    if (connectedProviders.contains(OAuthProvider.github) && 
        !connectedProviders.contains(OAuthProvider.linear)) {
      suggestions.add(SmartSuggestion(
        type: SuggestionType.integration,
        title: 'Add Linear for Issue Tracking',
        description: 'Since you use GitHub, Linear can help track issues and project management.',
        provider: OAuthProvider.linear,
        priority: SuggestionPriority.medium,
      ));
    }

    if (connectedProviders.contains(OAuthProvider.slack) && 
        connectedProviders.contains(OAuthProvider.github)) {
      suggestions.add(SmartSuggestion(
        type: SuggestionType.optimization,
        title: 'Enable GitHub-Slack Integration',
        description: 'Get GitHub notifications in Slack channels for better team coordination.',
        priority: SuggestionPriority.high,
      ));
    }

    // Security suggestions
    if (connectedProviders.length >= 2) {
      suggestions.add(SmartSuggestion(
        type: SuggestionType.security,
        title: 'Review Permissions Regularly',
        description: 'With multiple integrations, consider reviewing permissions monthly.',
        priority: SuggestionPriority.low,
      ));
    }

    return suggestions;
  }

  /// Get onboarding flow for new users
  static List<OnboardingStep> getOnboardingSteps() {
    return [
      OnboardingStep(
        id: 'welcome',
        title: 'Connect Your Accounts',
        description: 'Link your favorite services to expand what you can do.',
        icon: Icons.link,
      ),
      OnboardingStep(
        id: 'choose_integration',
        title: 'Start with One Service',
        description: 'Pick the service you use most often to begin.',
        icon: Icons.star,
      ),
      OnboardingStep(
        id: 'permissions',
        title: 'Simple Permissions',
        description: 'We\'ll ask for only what\'s needed. You can change this later.',
        icon: Icons.security,
      ),
      OnboardingStep(
        id: 'ready',
        title: 'You\'re All Set!',
        description: 'Your account is connected. Add more services anytime.',
        icon: Icons.check_circle,
      ),
    ];
  }
}

class UseCaseOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isRecommended;

  UseCaseOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isRecommended = false,
  });
}

class OAuthProviderSettings {
  final bool autoRefresh;
  final int refreshThresholdMinutes;
  final int timeoutSeconds;
  final int maxRetryAttempts;
  final bool enableMonitoring;

  OAuthProviderSettings({
    required this.autoRefresh,
    required this.refreshThresholdMinutes,
    required this.timeoutSeconds,
    required this.maxRetryAttempts,
    required this.enableMonitoring,
  });
}

class SmartSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final OAuthProvider? provider;
  final SuggestionPriority priority;
  final String? actionText;
  final VoidCallback? onAction;

  SmartSuggestion({
    required this.type,
    required this.title,
    required this.description,
    this.provider,
    required this.priority,
    this.actionText,
    this.onAction,
  });
}

enum SuggestionType {
  integration,
  optimization,
  security,
}

enum SuggestionPriority {
  high,
  medium,
  low,
}

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
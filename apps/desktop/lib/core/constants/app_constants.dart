// Application-wide constants to eliminate magic numbers and hardcoded values

/// Timeout constants (in milliseconds)
class TimeoutConstants {
  // Workflow and execution timeouts
  static const int defaultWorkflowTimeout = 300000; // 5 minutes
  static const int defaultRetryDelay = 1000; // 1 second
  static const int longRunningTaskTimeout = 1800000; // 30 minutes
  
  // Network timeouts
  static const int httpRequestTimeout = 30000; // 30 seconds
  static const int websocketTimeout = 60000; // 1 minute
  static const int connectionTimeout = 15000; // 15 seconds
  
  // UI interaction timeouts
  static const int animationDuration = 150; // milliseconds
  static const int debounceDelay = 300; // milliseconds
  static const int loadingIndicatorDelay = 500; // milliseconds
}

/// Cache and memory constants
class CacheConstants {
  static const int maxTokensToCache = 4000;
  static const int highTokenThreshold = 2000;
  static const int defaultMaxTokens = 4000;
  static const int compactMaxTokens = 3000;
  static const int expandedMaxTokens = 6000;
  
  static const int maxCacheEntries = 100;
  static const Duration cacheExpiry = Duration(minutes: 5);
}

/// UI dimension constants
class DimensionConstants {
  static const double defaultCardWidth = 320.0;
  static const double defaultCardHeight = 200.0;
  static const double maxDialogWidth = 600.0;
  static const double sidebarWidth = 280.0;
  static const double headerHeight = 64.0;
}

/// Brand color constants for integrations
class BrandColors {
  static const int defaultBrand = 0xFF0066CC;
  static const int google = 0xFF4285F4;
  static const int microsoft = 0xFF0078D4;
  static const int github = 0xFF333333;
  static const int figma = 0xFFF24E1E;
  static const int database = 0xFF336791;
  static const int api = 0xFF4CAF50;
  static const int storage = 0xFF9C27B0;
  static const int notification = 0xFFFF7A00;
}

/// Random ID generation constants
class IdConstants {
  static const int maxRandomId = 999999;
  static const int maxTestId = 10000;
  static const int maxSessionId = 1000;
}

/// Performance thresholds
class PerformanceConstants {
  static const int slowQueryThreshold = 1000; // milliseconds
  static const int memoryWarningThreshold = 500; // MB
  static const int maxConcurrentOperations = 10;
}
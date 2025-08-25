import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

/// Service for detecting and configuring browser integrations
class BrowserDetectionService {
  
  /// Detects all installed browsers
  Future<List<BrowserInfo>> detectBrowsers() async {
    final browsers = <BrowserInfo>[];
    
    // Detect Brave
    final brave = await detectBrave();
    if (brave.found) browsers.add(_toBrowserInfo(brave, BrowserType.brave));
    
    // Detect Chrome
    final chrome = await detectChrome();
    if (chrome.found) browsers.add(_toBrowserInfo(chrome, BrowserType.chrome));
    
    // Detect Edge
    final edge = await detectEdge();
    if (edge.found) browsers.add(_toBrowserInfo(edge, BrowserType.edge));
    
    // Detect Firefox
    final firefox = await detectFirefox();
    if (firefox.found) browsers.add(_toBrowserInfo(firefox, BrowserType.firefox));
    
    // Detect Safari (macOS only)
    if (Platform.isMacOS) {
      final safari = await detectSafari();
      if (safari.found) browsers.add(_toBrowserInfo(safari, BrowserType.safari));
    }
    
    return browsers;
  }
  
  /// Detect Brave browser specifically
  Future<BrowserDetectionResult> detectBrave() async {
    final List<String> braveLocations = [];
    
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      final programFiles = Platform.environment['PROGRAMFILES'] ?? 'C:\\Program Files';
      final programFilesX86 = Platform.environment['PROGRAMFILES(X86)'] ?? 'C:\\Program Files (x86)';
      
      braveLocations.addAll([
        '$localAppData\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
        '$programFiles\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
        '$programFilesX86\\BraveSoftware\\Brave-Browser\\Application\\brave.exe',
      ]);
      
      // Also check for user data directory (for profile detection)
      final userDataPath = '$localAppData\\BraveSoftware\\Brave-Browser\\User Data';
      if (await Directory(userDataPath).exists()) {
        final profiles = await _detectBraveProfiles(userDataPath);
        
        for (final location in braveLocations) {
          if (await File(location).exists()) {
            return BrowserDetectionResult(
              found: true,
              executablePath: location,
              userDataPath: userDataPath,
              profiles: profiles,
              version: await _getBraveVersion(location),
              name: 'Brave',
              confidence: DetectionConfidence.high,
            );
          }
        }
      }
    } else if (Platform.isMacOS) {
      braveLocations.addAll([
        '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
        '${Platform.environment['HOME']}/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
      ]);
      
      final userDataPath = '${Platform.environment['HOME']}/Library/Application Support/BraveSoftware/Brave-Browser';
      
      for (final location in braveLocations) {
        if (await File(location).exists()) {
          final profiles = await _detectBraveProfiles(userDataPath);
          
          return BrowserDetectionResult(
            found: true,
            executablePath: location,
            userDataPath: userDataPath,
            profiles: profiles,
            version: await _getBraveVersion(location),
            name: 'Brave',
            confidence: DetectionConfidence.high,
          );
        }
      }
    } else if (Platform.isLinux) {
      braveLocations.addAll([
        '/usr/bin/brave-browser',
        '/usr/local/bin/brave-browser',
        '/opt/brave.com/brave/brave',
        '/snap/bin/brave',
      ]);
      
      final userDataPath = '${Platform.environment['HOME']}/.config/BraveSoftware/Brave-Browser';
      
      for (final location in braveLocations) {
        if (await File(location).exists()) {
          final profiles = await _detectBraveProfiles(userDataPath);
          
          return BrowserDetectionResult(
            found: true,
            executablePath: location,
            userDataPath: userDataPath,
            profiles: profiles,
            version: await _getBraveVersion(location),
            name: 'Brave',
            confidence: DetectionConfidence.high,
          );
        }
      }
    }
    
    return BrowserDetectionResult(
      found: false,
      name: 'Brave',
      confidence: DetectionConfidence.none,
      message: 'Brave browser not found',
    );
  }
  
  /// Detect Chrome browser
  Future<BrowserDetectionResult> detectChrome() async {
    final List<String> chromeLocations = [];
    
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      final programFiles = Platform.environment['PROGRAMFILES'] ?? 'C:\\Program Files';
      final programFilesX86 = Platform.environment['PROGRAMFILES(X86)'] ?? 'C:\\Program Files (x86)';
      
      chromeLocations.addAll([
        '$localAppData\\Google\\Chrome\\Application\\chrome.exe',
        '$programFiles\\Google\\Chrome\\Application\\chrome.exe',
        '$programFilesX86\\Google\\Chrome\\Application\\chrome.exe',
      ]);
      
      final userDataPath = '$localAppData\\Google\\Chrome\\User Data';
      
      for (final location in chromeLocations) {
        if (await File(location).exists()) {
          return BrowserDetectionResult(
            found: true,
            executablePath: location,
            userDataPath: userDataPath,
            profiles: await _detectChromeProfiles(userDataPath),
            version: await _getChromeVersion(location),
            name: 'Google Chrome',
            confidence: DetectionConfidence.high,
          );
        }
      }
    } else if (Platform.isMacOS) {
      chromeLocations.addAll([
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '${Platform.environment['HOME']}/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      ]);
      
      final userDataPath = '${Platform.environment['HOME']}/Library/Application Support/Google/Chrome';
      
      for (final location in chromeLocations) {
        if (await File(location).exists()) {
          return BrowserDetectionResult(
            found: true,
            executablePath: location,
            userDataPath: userDataPath,
            profiles: await _detectChromeProfiles(userDataPath),
            version: await _getChromeVersion(location),
            name: 'Google Chrome',
            confidence: DetectionConfidence.high,
          );
        }
      }
    }
    
    return BrowserDetectionResult(
      found: false,
      name: 'Google Chrome',
      confidence: DetectionConfidence.none,
      message: 'Chrome browser not found',
    );
  }
  
  /// Detect Microsoft Edge
  Future<BrowserDetectionResult> detectEdge() async {
    if (!Platform.isWindows) {
      return BrowserDetectionResult(
        found: false,
        name: 'Microsoft Edge',
        confidence: DetectionConfidence.none,
        message: 'Edge detection only supported on Windows',
      );
    }
    
    final programFiles = Platform.environment['PROGRAMFILES(X86)'] ?? 'C:\\Program Files (x86)';
    final edgePath = '$programFiles\\Microsoft\\Edge\\Application\\msedge.exe';
    
    if (await File(edgePath).exists()) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      final userDataPath = '$localAppData\\Microsoft\\Edge\\User Data';
      
      return BrowserDetectionResult(
        found: true,
        executablePath: edgePath,
        userDataPath: userDataPath,
        profiles: await _detectChromeProfiles(userDataPath), // Edge uses Chrome profile format
        name: 'Microsoft Edge',
        confidence: DetectionConfidence.high,
      );
    }
    
    return BrowserDetectionResult(
      found: false,
      name: 'Microsoft Edge',
      confidence: DetectionConfidence.none,
      message: 'Edge browser not found',
    );
  }
  
  /// Detect Firefox
  Future<BrowserDetectionResult> detectFirefox() async {
    final List<String> firefoxLocations = [];
    
    if (Platform.isWindows) {
      final programFiles = Platform.environment['PROGRAMFILES'] ?? 'C:\\Program Files';
      final programFilesX86 = Platform.environment['PROGRAMFILES(X86)'] ?? 'C:\\Program Files (x86)';
      
      firefoxLocations.addAll([
        '$programFiles\\Mozilla Firefox\\firefox.exe',
        '$programFilesX86\\Mozilla Firefox\\firefox.exe',
      ]);
      
      for (final location in firefoxLocations) {
        if (await File(location).exists()) {
          final appData = Platform.environment['APPDATA'] ?? '';
          final profilesPath = '$appData\\Mozilla\\Firefox\\Profiles';
          
          return BrowserDetectionResult(
            found: true,
            executablePath: location,
            userDataPath: profilesPath,
            profiles: await _detectFirefoxProfiles(profilesPath),
            name: 'Mozilla Firefox',
            confidence: DetectionConfidence.high,
          );
        }
      }
    } else if (Platform.isMacOS) {
      firefoxLocations.addAll([
        '/Applications/Firefox.app/Contents/MacOS/firefox',
        '${Platform.environment['HOME']}/Applications/Firefox.app/Contents/MacOS/firefox',
      ]);
      
      for (final location in firefoxLocations) {
        if (await File(location).exists()) {
          final profilesPath = '${Platform.environment['HOME']}/Library/Application Support/Firefox/Profiles';
          
          return BrowserDetectionResult(
            found: true,
            executablePath: location,
            userDataPath: profilesPath,
            profiles: await _detectFirefoxProfiles(profilesPath),
            name: 'Mozilla Firefox',
            confidence: DetectionConfidence.high,
          );
        }
      }
    }
    
    return BrowserDetectionResult(
      found: false,
      name: 'Mozilla Firefox',
      confidence: DetectionConfidence.none,
      message: 'Firefox browser not found',
    );
  }
  
  /// Detect Safari (macOS only)
  Future<BrowserDetectionResult> detectSafari() async {
    if (!Platform.isMacOS) {
      return BrowserDetectionResult(
        found: false,
        name: 'Safari',
        confidence: DetectionConfidence.none,
        message: 'Safari only available on macOS',
      );
    }
    
    const safariPath = '/Applications/Safari.app/Contents/MacOS/Safari';
    
    if (await File(safariPath).exists()) {
      return BrowserDetectionResult(
        found: true,
        executablePath: safariPath,
        name: 'Safari',
        confidence: DetectionConfidence.high,
        profiles: [BrowserProfile(name: 'Default', path: '', isDefault: true)],
      );
    }
    
    return BrowserDetectionResult(
      found: false,
      name: 'Safari',
      confidence: DetectionConfidence.none,
      message: 'Safari not found',
    );
  }
  
  /// Get bookmarks and history paths for easier integration
  Future<BrowserDataPaths?> getBrowserDataPaths(BrowserInfo browser) async {
    switch (browser.type) {
      case BrowserType.brave:
      case BrowserType.chrome:
      case BrowserType.edge:
        // Chromium-based browsers have similar structure
        final profile = browser.defaultProfile ?? browser.profiles.first;
        final profilePath = path.join(browser.userDataPath ?? '', profile.path);
        
        return BrowserDataPaths(
          bookmarks: path.join(profilePath, 'Bookmarks'),
          history: path.join(profilePath, 'History'),
          cookies: path.join(profilePath, 'Cookies'),
          extensions: path.join(profilePath, 'Extensions'),
        );
        
      case BrowserType.firefox:
        final profile = browser.defaultProfile ?? browser.profiles.first;
        final profilePath = profile.path;
        
        return BrowserDataPaths(
          bookmarks: path.join(profilePath, 'places.sqlite'),
          history: path.join(profilePath, 'places.sqlite'),
          cookies: path.join(profilePath, 'cookies.sqlite'),
          extensions: path.join(profilePath, 'extensions.json'),
        );
        
      case BrowserType.safari:
        final home = Platform.environment['HOME'] ?? '';
        
        return BrowserDataPaths(
          bookmarks: '$home/Library/Safari/Bookmarks.plist',
          history: '$home/Library/Safari/History.db',
          cookies: '$home/Library/Cookies/Cookies.binarycookies',
        );
        
      default:
        return null;
    }
  }
  
  // Helper methods for profile detection
  
  Future<List<BrowserProfile>> _detectBraveProfiles(String userDataPath) async {
    return _detectChromiumProfiles(userDataPath);
  }
  
  Future<List<BrowserProfile>> _detectChromeProfiles(String userDataPath) async {
    return _detectChromiumProfiles(userDataPath);
  }
  
  Future<List<BrowserProfile>> _detectChromiumProfiles(String userDataPath) async {
    final profiles = <BrowserProfile>[];
    final userDataDir = Directory(userDataPath);
    
    if (!await userDataDir.exists()) return profiles;
    
    // Check for Default profile
    final defaultProfile = Directory(path.join(userDataPath, 'Default'));
    if (await defaultProfile.exists()) {
      profiles.add(BrowserProfile(
        name: 'Default',
        path: 'Default',
        isDefault: true,
      ));
    }
    
    // Check for additional profiles (Profile 1, Profile 2, etc.)
    try {
      await for (final entity in userDataDir.list()) {
        if (entity is Directory) {
          final profileName = path.basename(entity.path);
          if (profileName.startsWith('Profile ')) {
            // Try to get actual profile name from Preferences file
            final prefsFile = File(path.join(entity.path, 'Preferences'));
            String displayName = profileName;
            
            if (await prefsFile.exists()) {
              try {
                final prefs = await prefsFile.readAsString();
                // Basic extraction of profile name from JSON (avoiding heavy dependencies)
                final nameMatch = RegExp(r'"name":"([^"]+)"').firstMatch(prefs);
                if (nameMatch != null) {
                  displayName = nameMatch.group(1) ?? profileName;
                }
              } catch (e) {
                // Use default name if parsing fails
              }
            }
            
            profiles.add(BrowserProfile(
              name: displayName,
              path: profileName,
              isDefault: false,
            ));
          }
        }
      }
    } catch (e) {
      // Return what we found so far
    }
    
    return profiles;
  }
  
  Future<List<BrowserProfile>> _detectFirefoxProfiles(String profilesPath) async {
    final profiles = <BrowserProfile>[];
    final profilesDir = Directory(profilesPath);
    
    if (!await profilesDir.exists()) return profiles;
    
    try {
      await for (final entity in profilesDir.list()) {
        if (entity is Directory) {
          final profileName = path.basename(entity.path);
          // Firefox profiles usually have format: xxxxx.ProfileName
          final parts = profileName.split('.');
          final displayName = parts.length > 1 ? parts.sublist(1).join('.') : profileName;
          
          profiles.add(BrowserProfile(
            name: displayName,
            path: entity.path,
            isDefault: displayName.toLowerCase().contains('default'),
          ));
        }
      }
    } catch (e) {
      // Return what we found
    }
    
    return profiles;
  }
  
  Future<String?> _getBraveVersion(String executablePath) async {
    return _getChromiumVersion(executablePath);
  }
  
  Future<String?> _getChromeVersion(String executablePath) async {
    return _getChromiumVersion(executablePath);
  }
  
  Future<String?> _getChromiumVersion(String executablePath) async {
    try {
      final result = await Process.run(executablePath, ['--version']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      // Failed to get version
    }
    return null;
  }
  
  BrowserInfo _toBrowserInfo(BrowserDetectionResult result, BrowserType type) {
    return BrowserInfo(
      type: type,
      name: result.name,
      executablePath: result.executablePath!,
      userDataPath: result.userDataPath,
      profiles: result.profiles,
      defaultProfile: result.profiles.firstWhere(
        (p) => p.isDefault,
        orElse: () => result.profiles.isNotEmpty ? result.profiles.first : BrowserProfile(name: 'Default', path: '', isDefault: true),
      ),
      version: result.version,
    );
  }
  
  /// Get simplified browser setup for non-technical users
  Future<SimplifiedBrowserSetup> getSimplifiedSetup(BrowserType browserType) async {
    final browsers = await detectBrowsers();
    final browser = browsers.firstWhere(
      (b) => b.type == browserType,
      orElse: () => throw Exception('${browserType.displayName} not found'),
    );
    
    final dataPaths = await getBrowserDataPaths(browser);
    
    return SimplifiedBrowserSetup(
      browserName: browser.name,
      isInstalled: true,
      profileName: browser.defaultProfile?.name ?? 'Default',
      bookmarksAvailable: dataPaths?.bookmarks != null && await File(dataPaths!.bookmarks).exists(),
      historyAvailable: dataPaths?.history != null && await File(dataPaths!.history).exists(),
      suggestedActions: _getSuggestedActions(browser),
      quickSetupCommand: _getQuickSetupCommand(browser),
    );
  }
  
  List<String> _getSuggestedActions(BrowserInfo browser) {
    final actions = <String>[];
    
    switch (browser.type) {
      case BrowserType.brave:
        actions.add('Enable Brave Shields for privacy');
        actions.add('Install Bitwarden or 1Password extension');
        actions.add('Set DuckDuckGo as default search engine');
        break;
      case BrowserType.chrome:
        actions.add('Sign in to sync bookmarks');
        actions.add('Install uBlock Origin extension');
        actions.add('Enable Enhanced Safe Browsing');
        break;
      case BrowserType.firefox:
        actions.add('Enable Enhanced Tracking Protection');
        actions.add('Install Privacy Badger extension');
        actions.add('Configure DNS-over-HTTPS');
        break;
      default:
        break;
    }
    
    return actions;
  }
  
  String _getQuickSetupCommand(BrowserInfo browser) {
    // Return a simple command to open browser with specific settings
    if (Platform.isWindows) {
      return '"${browser.executablePath}" --new-window';
    } else if (Platform.isMacOS) {
      return 'open -a "${browser.name}"';
    } else {
      return browser.executablePath;
    }
  }
}

/// Browser detection result
class BrowserDetectionResult {
  final bool found;
  final String name;
  final String? executablePath;
  final String? userDataPath;
  final List<BrowserProfile> profiles;
  final String? version;
  final DetectionConfidence confidence;
  final String? message;
  
  BrowserDetectionResult({
    required this.found,
    required this.name,
    this.executablePath,
    this.userDataPath,
    this.profiles = const [],
    this.version,
    required this.confidence,
    this.message,
  });
}

/// Browser profile information
class BrowserProfile {
  final String name;
  final String path;
  final bool isDefault;
  
  const BrowserProfile({
    required this.name,
    required this.path,
    required this.isDefault,
  });
}

/// Browser information
class BrowserInfo {
  final BrowserType type;
  final String name;
  final String executablePath;
  final String? userDataPath;
  final List<BrowserProfile> profiles;
  final BrowserProfile? defaultProfile;
  final String? version;
  
  const BrowserInfo({
    required this.type,
    required this.name,
    required this.executablePath,
    this.userDataPath,
    required this.profiles,
    this.defaultProfile,
    this.version,
  });
}

/// Browser data paths
class BrowserDataPaths {
  final String bookmarks;
  final String history;
  final String? cookies;
  final String? extensions;
  
  const BrowserDataPaths({
    required this.bookmarks,
    required this.history,
    this.cookies,
    this.extensions,
  });
}

/// Simplified browser setup for non-technical users
class SimplifiedBrowserSetup {
  final String browserName;
  final bool isInstalled;
  final String profileName;
  final bool bookmarksAvailable;
  final bool historyAvailable;
  final List<String> suggestedActions;
  final String quickSetupCommand;
  
  const SimplifiedBrowserSetup({
    required this.browserName,
    required this.isInstalled,
    required this.profileName,
    required this.bookmarksAvailable,
    required this.historyAvailable,
    required this.suggestedActions,
    required this.quickSetupCommand,
  });
}

/// Browser types
enum BrowserType {
  brave,
  chrome,
  edge,
  firefox,
  safari,
  other;
  
  String get displayName {
    switch (this) {
      case BrowserType.brave:
        return 'Brave';
      case BrowserType.chrome:
        return 'Google Chrome';
      case BrowserType.edge:
        return 'Microsoft Edge';
      case BrowserType.firefox:
        return 'Mozilla Firefox';
      case BrowserType.safari:
        return 'Safari';
      case BrowserType.other:
        return 'Other';
    }
  }
}

/// Detection confidence levels
enum DetectionConfidence {
  none,
  low,
  medium,
  high,
}

/// Provider for the browser detection service
final browserDetectionServiceProvider = Provider<BrowserDetectionService>((ref) {
  return BrowserDetectionService();
});
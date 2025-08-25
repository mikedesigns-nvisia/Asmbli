import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'dev_tools_detection_service.dart';
import 'browser_detection_service.dart';

/// Status of an integration
enum IntegrationStatus {
  ready,
  needsAuth,
  needsStart,
  notFound,
}

/// Individual integration instance
class IntegrationInstance {
  final String name;
  final IntegrationStatus status;
  final String? path;
  final int confidence;
  final Map<String, dynamic>? metadata;

  const IntegrationInstance({
    required this.name,
    required this.status,
    this.path,
    required this.confidence,
    this.metadata,
  });
}

/// Integration configuration for setup
class IntegrationConfig {
  final String name;
  final String? executablePath;
  final Map<String, String> envVars;
  final List<String> setupCommands;

  const IntegrationConfig({
    required this.name,
    this.executablePath,
    required this.envVars,
    required this.setupCommands,
  });
}

/// Universal detection service for ALL integrations
/// This is our key differentiator - everything "just works"
class UniversalDetectionService {
  final DevToolsDetectionService _devTools;
  final BrowserDetectionService _browsers;
  
  UniversalDetectionService(this._devTools, this._browsers);
  
  /// Detect specific integration category
  Future<UniversalDetectionResult> detectSpecificIntegration(String category) async {
    final results = <String, IntegrationDetection>{};
    
    switch (category.toLowerCase()) {
      case 'development tools':
        results['development'] = await _detectDevelopmentTools();
        break;
      case 'browsers':
        final browsers = await _browsers.detectBrowsers();
        results['browsers'] = IntegrationDetection(
          category: 'Browsers',
          found: browsers.isNotEmpty,
          integrations: browsers.map((b) => IntegrationInstance(
            name: b.name,
            status: IntegrationStatus.ready,
            path: b.executablePath,
            confidence: 90,
            metadata: {'profiles': b.profiles.length},
          )).toList(),
        );
        break;
      case 'databases':
        results['databases'] = await _detectDatabases();
        break;
      case 'cloud services':
        results['cloud'] = await _detectCloudServices();
        break;
      case 'communication':
        results['communication'] = await _detectCommunicationTools();
        break;
      case 'design tools':
        results['design'] = await _detectDesignTools();
        break;
      case 'productivity':
        results['productivity'] = await _detectProductivityTools();
        break;
      case 'ai & ml':
        results['ai'] = await _detectAITools();
        break;
      case 'file storage':
        results['storage'] = await _detectFileStorage();
        break;
      default:
        return await detectEverything();
    }
    
    // Calculate summary stats
    int totalFound = 0;
    int totalReady = 0;
    for (final detection in results.values) {
      totalFound += detection.integrations.length;
      totalReady += detection.integrations.where((i) => i.status == IntegrationStatus.ready).length;
    }
    
    final readinessScore = totalFound > 0 ? ((totalReady / totalFound) * 100).round() : 0;
    
    return UniversalDetectionResult(
      detections: results,
      totalIntegrationsFound: totalFound,
      totalReady: totalReady,
      readinessScore: readinessScore,
    );
  }

  /// Master detection function - detects EVERYTHING
  Future<UniversalDetectionResult> detectEverything() async {
    final results = <String, IntegrationDetection>{};
    
    // Run all detections in parallel for speed
    final futures = <Future>[];
    
    // Development Tools
    futures.add(_detectDevelopmentTools().then((r) => results['development'] = r));
    
    // Databases
    futures.add(_detectDatabases().then((r) => results['databases'] = r));
    
    // Cloud Services
    futures.add(_detectCloudServices().then((r) => results['cloud'] = r));
    
    // Communication Tools
    futures.add(_detectCommunicationTools().then((r) => results['communication'] = r));
    
    // Design Tools
    futures.add(_detectDesignTools().then((r) => results['design'] = r));
    
    // Productivity Tools
    futures.add(_detectProductivityTools().then((r) => results['productivity'] = r));
    
    // AI/ML Tools
    futures.add(_detectAITools().then((r) => results['ai'] = r));
    
    // File Storage
    futures.add(_detectFileStorage().then((r) => results['storage'] = r));
    
    // Browsers
    futures.add(_browsers.detectBrowsers().then((browsers) {
      results['browsers'] = IntegrationDetection(
        category: 'Browsers',
        found: browsers.isNotEmpty,
        integrations: browsers.map((b) => IntegrationConfig(
          id: b.type.name,
          name: b.name,
          status: DetectionStatus.ready,
          configuration: {
            'executable': b.executablePath,
            'profile': b.defaultProfile?.name ?? 'Default',
            'version': b.version ?? 'Unknown',
          },
          message: 'Ready to use',
        )).toList(),
      );
    }));
    
    await Future.wait(futures);
    
    // Calculate overall readiness
    int totalFound = 0;
    int totalReady = 0;
    
    for (final detection in results.values) {
      totalFound += detection.integrations.length;
      totalReady += detection.integrations.where((i) => i.status == DetectionStatus.ready).length;
    }
    
    return UniversalDetectionResult(
      detections: results,
      totalIntegrationsFound: totalFound,
      totalReady: totalReady,
      readinessScore: totalFound > 0 ? (totalReady / totalFound * 100).round() : 0,
    );
  }
  
  /// Detect specific integration by ID
  Future<IntegrationConfig?> detectIntegration(String integrationId) async {
    switch (integrationId) {
      // Development
      case 'vscode':
        final result = await _devTools.detectVSCode();
        return IntegrationConfig(
          id: 'vscode',
          name: 'Visual Studio Code',
          status: result.found ? DetectionStatus.ready : DetectionStatus.notFound,
          configuration: result.found ? {'path': result.path!} : {},
          message: result.message,
        );
        
      case 'github':
        final git = await _devTools.detectGit();
        final gh = await _devTools.detectGitHubCLI();
        return IntegrationConfig(
          id: 'github',
          name: 'GitHub',
          status: git.found ? 
            (gh.metadata?['authenticated'] == true ? DetectionStatus.ready : DetectionStatus.needsAuth) : 
            DetectionStatus.notFound,
          configuration: {
            'git': git.path ?? 'not found',
            'cli': gh.found ? 'installed' : 'not installed',
            'authenticated': gh.metadata?['authenticated'] ?? false,
          },
          message: gh.metadata?['authenticated'] == true 
            ? 'Ready to use' 
            : 'GitHub CLI needs authentication',
          setupCommand: gh.found && gh.metadata?['authenticated'] != true 
            ? 'gh auth login' 
            : null,
        );
        
      // Databases
      case 'postgresql':
        return await _detectPostgreSQL();
      case 'mysql':
        return await _detectMySQL();
      case 'sqlite':
        return await _detectSQLite();
      case 'mongodb':
        return await _detectMongoDB();
      case 'redis':
        return await _detectRedis();
        
      // Cloud
      case 'aws':
        return await _detectAWS();
      case 'gcp':
        return await _detectGCP();
      case 'azure':
        return await _detectAzure();
        
      // Communication
      case 'slack':
        return await _detectSlack();
      case 'discord':
        return await _detectDiscord();
      case 'teams':
        return await _detectTeams();
        
      // Design
      case 'figma':
        return await _detectFigma();
      case 'sketch':
        return await _detectSketch();
      case 'adobe':
        return await _detectAdobeCC();
        
      // Productivity
      case 'notion':
        return await _detectNotion();
      case 'obsidian':
        return await _detectObsidian();
      case 'jira':
        return await _detectJira();
      case 'linear':
        return await _detectLinear();
        
      // File Storage
      case 'dropbox':
        return await _detectDropbox();
      case 'googledrive':
        return await _detectGoogleDrive();
      case 'onedrive':
        return await _detectOneDrive();
        
      default:
        return null;
    }
  }
  
  // DEVELOPMENT TOOLS DETECTION
  
  Future<IntegrationDetection> _detectDevelopmentTools() async {
    final integrations = <IntegrationConfig>[];
    
    // VS Code
    final vscode = await _devTools.detectVSCode();
    if (vscode.found) {
      integrations.add(IntegrationConfig(
        id: 'vscode',
        name: 'Visual Studio Code',
        status: DetectionStatus.ready,
        configuration: {'path': vscode.path!},
        message: 'Ready to use',
      ));
    }
    
    // Git
    final git = await _devTools.detectGit();
    if (git.found) {
      integrations.add(IntegrationConfig(
        id: 'git',
        name: 'Git',
        status: DetectionStatus.ready,
        configuration: {
          'path': git.path!,
          'version': git.metadata?['version'] ?? 'unknown',
        },
        message: git.message,
      ));
    }
    
    // Docker
    final docker = await _detectDocker();
    if (docker != null) integrations.add(docker);
    
    // Node.js
    final nodejs = await _detectNodeJS();
    if (nodejs != null) integrations.add(nodejs);
    
    // Python
    final python = await _detectPython();
    if (python != null) integrations.add(python);
    
    return IntegrationDetection(
      category: 'Development Tools',
      found: integrations.isNotEmpty,
      integrations: integrations,
    );
  }
  
  // DATABASE DETECTION
  
  Future<IntegrationDetection> _detectDatabases() async {
    final integrations = <IntegrationConfig>[];
    
    final detectors = [
      _detectPostgreSQL(),
      _detectMySQL(),
      _detectSQLite(),
      _detectMongoDB(),
      _detectRedis(),
    ];
    
    final results = await Future.wait(detectors);
    integrations.addAll(results.whereType<IntegrationConfig>());
    
    return IntegrationDetection(
      category: 'Databases',
      found: integrations.isNotEmpty,
      integrations: integrations,
    );
  }
  
  Future<IntegrationConfig?> _detectPostgreSQL() async {
    final paths = Platform.isWindows
      ? [
          'C:\\Program Files\\PostgreSQL\\15\\bin\\psql.exe',
          'C:\\Program Files\\PostgreSQL\\14\\bin\\psql.exe',
          'C:\\Program Files\\PostgreSQL\\13\\bin\\psql.exe',
        ]
      : Platform.isMacOS
        ? [
            '/Applications/Postgres.app/Contents/Versions/latest/bin/psql',
            '/usr/local/bin/psql',
            '/opt/homebrew/bin/psql',
          ]
        : ['/usr/bin/psql', '/usr/local/bin/psql'];
    
    for (final psqlPath in paths) {
      if (await File(psqlPath).exists()) {
        try {
          final result = await Process.run(psqlPath, ['--version']);
          final version = result.stdout.toString().trim();
          
          return IntegrationConfig(
            id: 'postgresql',
            name: 'PostgreSQL',
            status: DetectionStatus.needsAuth,
            configuration: {
              'path': psqlPath,
              'version': version,
              'defaultPort': '5432',
              'defaultDatabase': 'postgres',
            },
            message: 'PostgreSQL found. Configure connection settings.',
            setupCommand: 'createdb myapp_development',
          );
        } catch (e) {
          // Continue checking other paths
        }
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectMySQL() async {
    final paths = Platform.isWindows
      ? [
          'C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin\\mysql.exe',
          'C:\\Program Files\\MySQL\\MySQL Server 5.7\\bin\\mysql.exe',
        ]
      : ['/usr/bin/mysql', '/usr/local/bin/mysql', '/opt/homebrew/bin/mysql'];
    
    for (final mysqlPath in paths) {
      if (await File(mysqlPath).exists()) {
        try {
          final result = await Process.run(mysqlPath, ['--version']);
          final version = result.stdout.toString().trim();
          
          return IntegrationConfig(
            id: 'mysql',
            name: 'MySQL',
            status: DetectionStatus.needsAuth,
            configuration: {
              'path': mysqlPath,
              'version': version,
              'defaultPort': '3306',
            },
            message: 'MySQL found. Configure connection settings.',
          );
        } catch (e) {
          // Continue
        }
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectSQLite() async {
    final paths = Platform.isWindows
      ? ['sqlite3.exe', 'C:\\Tools\\sqlite\\sqlite3.exe']
      : ['/usr/bin/sqlite3', '/usr/local/bin/sqlite3'];
    
    for (final sqlitePath in paths) {
      try {
        final result = await Process.run(sqlitePath, ['--version']);
        if (result.exitCode == 0) {
          return IntegrationConfig(
            id: 'sqlite',
            name: 'SQLite',
            status: DetectionStatus.ready,
            configuration: {
              'path': sqlitePath,
              'version': result.stdout.toString().trim(),
            },
            message: 'SQLite ready to use',
          );
        }
      } catch (e) {
        // Continue
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectMongoDB() async {
    final paths = Platform.isWindows
      ? ['C:\\Program Files\\MongoDB\\Server\\6.0\\bin\\mongo.exe']
      : ['/usr/bin/mongo', '/usr/local/bin/mongo'];
    
    for (final mongoPath in paths) {
      if (await File(mongoPath).exists()) {
        return IntegrationConfig(
          id: 'mongodb',
          name: 'MongoDB',
          status: DetectionStatus.needsAuth,
          configuration: {
            'path': mongoPath,
            'defaultPort': '27017',
          },
          message: 'MongoDB found. Configure connection.',
        );
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectRedis() async {
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', ['redis-cli']);
      if (result.exitCode == 0) {
        return IntegrationConfig(
          id: 'redis',
          name: 'Redis',
          status: DetectionStatus.needsAuth,
          configuration: {
            'path': result.stdout.toString().trim(),
            'defaultPort': '6379',
          },
          message: 'Redis CLI found',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
  
  // CLOUD SERVICES DETECTION
  
  Future<IntegrationDetection> _detectCloudServices() async {
    final integrations = <IntegrationConfig>[];
    
    // AWS CLI
    final aws = await _detectAWS();
    if (aws != null) integrations.add(aws);
    
    // Google Cloud SDK
    final gcp = await _detectGCP();
    if (gcp != null) integrations.add(gcp);
    
    // Azure CLI
    final azure = await _detectAzure();
    if (azure != null) integrations.add(azure);
    
    // Vercel CLI
    final vercel = await _detectVercel();
    if (vercel != null) integrations.add(vercel);
    
    // Netlify CLI
    final netlify = await _detectNetlify();
    if (netlify != null) integrations.add(netlify);
    
    return IntegrationDetection(
      category: 'Cloud Services',
      found: integrations.isNotEmpty,
      integrations: integrations,
    );
  }
  
  Future<IntegrationConfig?> _detectAWS() async {
    try {
      final result = await Process.run('aws', ['--version']);
      if (result.exitCode == 0) {
        // Check for credentials
        final credsFile = Platform.isWindows
          ? '${Platform.environment['USERPROFILE']}\\.aws\\credentials'
          : '${Platform.environment['HOME']}/.aws/credentials';
        
        final hasCredentials = await File(credsFile).exists();
        
        return IntegrationConfig(
          id: 'aws',
          name: 'AWS CLI',
          status: hasCredentials ? DetectionStatus.ready : DetectionStatus.needsAuth,
          configuration: {
            'version': result.stdout.toString().trim(),
            'credentialsConfigured': hasCredentials,
          },
          message: hasCredentials 
            ? 'AWS CLI ready' 
            : 'AWS CLI found but needs configuration',
          setupCommand: hasCredentials ? null : 'aws configure',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectGCP() async {
    try {
      final result = await Process.run('gcloud', ['--version']);
      if (result.exitCode == 0) {
        // Check if authenticated
        final authResult = await Process.run('gcloud', ['auth', 'list']);
        final isAuthenticated = authResult.stdout.toString().contains('*');
        
        return IntegrationConfig(
          id: 'gcp',
          name: 'Google Cloud SDK',
          status: isAuthenticated ? DetectionStatus.ready : DetectionStatus.needsAuth,
          configuration: {
            'version': result.stdout.toString().split('\n').first,
            'authenticated': isAuthenticated,
          },
          message: isAuthenticated 
            ? 'GCP SDK ready' 
            : 'GCP SDK needs authentication',
          setupCommand: isAuthenticated ? null : 'gcloud auth login',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectAzure() async {
    try {
      final result = await Process.run('az', ['--version']);
      if (result.exitCode == 0) {
        // Check if logged in
        final loginResult = await Process.run('az', ['account', 'show']);
        final isLoggedIn = loginResult.exitCode == 0;
        
        return IntegrationConfig(
          id: 'azure',
          name: 'Azure CLI',
          status: isLoggedIn ? DetectionStatus.ready : DetectionStatus.needsAuth,
          configuration: {
            'version': result.stdout.toString().split('\n').first,
            'loggedIn': isLoggedIn,
          },
          message: isLoggedIn ? 'Azure CLI ready' : 'Azure CLI needs login',
          setupCommand: isLoggedIn ? null : 'az login',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectVercel() async {
    try {
      final result = await Process.run('vercel', ['--version']);
      if (result.exitCode == 0) {
        return IntegrationConfig(
          id: 'vercel',
          name: 'Vercel',
          status: DetectionStatus.needsAuth,
          configuration: {
            'version': result.stdout.toString().trim(),
          },
          message: 'Vercel CLI found',
          setupCommand: 'vercel login',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectNetlify() async {
    try {
      final result = await Process.run('netlify', ['--version']);
      if (result.exitCode == 0) {
        return IntegrationConfig(
          id: 'netlify',
          name: 'Netlify',
          status: DetectionStatus.needsAuth,
          configuration: {
            'version': result.stdout.toString().trim(),
          },
          message: 'Netlify CLI found',
          setupCommand: 'netlify login',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
  
  // COMMUNICATION TOOLS DETECTION
  
  Future<IntegrationDetection> _detectCommunicationTools() async {
    final integrations = <IntegrationConfig>[];
    
    final slack = await _detectSlack();
    if (slack != null) integrations.add(slack);
    
    final discord = await _detectDiscord();
    if (discord != null) integrations.add(discord);
    
    final teams = await _detectTeams();
    if (teams != null) integrations.add(teams);
    
    return IntegrationDetection(
      category: 'Communication',
      found: integrations.isNotEmpty,
      integrations: integrations,
    );
  }
  
  Future<IntegrationConfig?> _detectSlack() async {
    final slackPaths = Platform.isWindows
      ? [
          '${Platform.environment['LOCALAPPDATA']}\\slack\\slack.exe',
          'C:\\Program Files\\Slack\\slack.exe',
        ]
      : Platform.isMacOS
        ? ['/Applications/Slack.app/Contents/MacOS/Slack']
        : ['/usr/bin/slack', '/snap/bin/slack'];
    
    for (final slackPath in slackPaths) {
      if (await File(slackPath).exists()) {
        return IntegrationConfig(
          id: 'slack',
          name: 'Slack',
          status: DetectionStatus.needsAuth,
          configuration: {'path': slackPath},
          message: 'Slack found. Add workspace token to connect.',
        );
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectDiscord() async {
    final discordPaths = Platform.isWindows
      ? [
          '${Platform.environment['LOCALAPPDATA']}\\Discord\\app-*\\Discord.exe',
          '${Platform.environment['APPDATA']}\\discord\\*\\Discord.exe',
        ]
      : Platform.isMacOS
        ? ['/Applications/Discord.app/Contents/MacOS/Discord']
        : [];
    
    for (final pattern in discordPaths) {
      // Handle wildcards in paths
      if (pattern.contains('*')) {
        final dir = Directory(path.dirname(pattern));
        if (await dir.exists()) {
          await for (final entity in dir.list()) {
            if (entity is File && entity.path.endsWith('Discord.exe')) {
              return IntegrationConfig(
                id: 'discord',
                name: 'Discord',
                status: DetectionStatus.needsAuth,
                configuration: {'path': entity.path},
                message: 'Discord found. Add bot token to connect.',
              );
            }
          }
        }
      } else if (await File(pattern).exists()) {
        return IntegrationConfig(
          id: 'discord',
          name: 'Discord',
          status: DetectionStatus.needsAuth,
          configuration: {'path': pattern},
          message: 'Discord found. Add bot token to connect.',
        );
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectTeams() async {
    if (Platform.isWindows) {
      final teamsPath = '${Platform.environment['LOCALAPPDATA']}\\Microsoft\\Teams\\current\\Teams.exe';
      if (await File(teamsPath).exists()) {
        return IntegrationConfig(
          id: 'teams',
          name: 'Microsoft Teams',
          status: DetectionStatus.needsAuth,
          configuration: {'path': teamsPath},
          message: 'Teams found. Configure app registration.',
        );
      }
    }
    return null;
  }
  
  // DESIGN TOOLS DETECTION
  
  Future<IntegrationDetection> _detectDesignTools() async {
    final integrations = <IntegrationConfig>[];
    
    final figma = await _detectFigma();
    if (figma != null) integrations.add(figma);
    
    final sketch = await _detectSketch();
    if (sketch != null) integrations.add(sketch);
    
    final adobe = await _detectAdobeCC();
    if (adobe != null) integrations.add(adobe);
    
    return IntegrationDetection(
      category: 'Design Tools',
      found: integrations.isNotEmpty,
      integrations: integrations,
    );
  }
  
  Future<IntegrationConfig?> _detectFigma() async {
    if (Platform.isWindows) {
      final figmaPath = '${Platform.environment['LOCALAPPDATA']}\\Figma\\Figma.exe';
      if (await File(figmaPath).exists()) {
        return IntegrationConfig(
          id: 'figma',
          name: 'Figma',
          status: DetectionStatus.needsAuth,
          configuration: {'path': figmaPath},
          message: 'Figma desktop found. Add API token for access.',
        );
      }
    } else if (Platform.isMacOS) {
      const figmaPath = '/Applications/Figma.app/Contents/MacOS/Figma';
      if (await File(figmaPath).exists()) {
        return IntegrationConfig(
          id: 'figma',
          name: 'Figma',
          status: DetectionStatus.needsAuth,
          configuration: {'path': figmaPath},
          message: 'Figma found. Add API token for access.',
        );
      }
    }
    
    // Even if desktop app not found, Figma can work via API
    return IntegrationConfig(
      id: 'figma',
      name: 'Figma (Web)',
      status: DetectionStatus.needsAuth,
      configuration: {'type': 'web'},
      message: 'Figma available via web API. Add token to connect.',
    );
  }
  
  Future<IntegrationConfig?> _detectSketch() async {
    if (Platform.isMacOS) {
      const sketchPath = '/Applications/Sketch.app/Contents/MacOS/Sketch';
      if (await File(sketchPath).exists()) {
        return IntegrationConfig(
          id: 'sketch',
          name: 'Sketch',
          status: DetectionStatus.ready,
          configuration: {'path': sketchPath},
          message: 'Sketch found',
        );
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectAdobeCC() async {
    final adobePaths = Platform.isWindows
      ? ['C:\\Program Files\\Adobe\\']
      : Platform.isMacOS
        ? ['/Applications/Adobe Photoshop*/Adobe Photoshop*.app']
        : [];
    
    for (final adobePath in adobePaths) {
      final dir = Directory(adobePath);
      if (await dir.exists()) {
        return IntegrationConfig(
          id: 'adobe',
          name: 'Adobe Creative Cloud',
          status: DetectionStatus.ready,
          configuration: {'path': adobePath},
          message: 'Adobe CC apps found',
        );
      }
    }
    return null;
  }
  
  // PRODUCTIVITY TOOLS DETECTION
  
  Future<IntegrationDetection> _detectProductivityTools() async {
    final integrations = <IntegrationConfig>[];
    
    final notion = await _detectNotion();
    if (notion != null) integrations.add(notion);
    
    final obsidian = await _detectObsidian();
    if (obsidian != null) integrations.add(obsidian);
    
    final jira = await _detectJira();
    if (jira != null) integrations.add(jira);
    
    final linear = await _detectLinear();
    if (linear != null) integrations.add(linear);
    
    return IntegrationDetection(
      category: 'Productivity',
      found: integrations.isNotEmpty,
      integrations: integrations,
    );
  }
  
  Future<IntegrationConfig?> _detectNotion() async {
    final notionPaths = Platform.isWindows
      ? ['${Platform.environment['LOCALAPPDATA']}\\Programs\\Notion\\Notion.exe']
      : Platform.isMacOS
        ? ['/Applications/Notion.app/Contents/MacOS/Notion']
        : [];
    
    for (final notionPath in notionPaths) {
      if (await File(notionPath).exists()) {
        return IntegrationConfig(
          id: 'notion',
          name: 'Notion',
          status: DetectionStatus.needsAuth,
          configuration: {'path': notionPath},
          message: 'Notion found. Add API key to connect.',
        );
      }
    }
    
    // Notion primarily works via API
    return IntegrationConfig(
      id: 'notion',
      name: 'Notion (API)',
      status: DetectionStatus.needsAuth,
      configuration: {'type': 'api'},
      message: 'Connect via Notion API. Add integration token.',
    );
  }
  
  Future<IntegrationConfig?> _detectObsidian() async {
    final obsidianPaths = Platform.isWindows
      ? [
          '${Platform.environment['LOCALAPPDATA']}\\Obsidian\\Obsidian.exe',
          '${Platform.environment['USERPROFILE']}\\Documents\\Obsidian',
        ]
      : Platform.isMacOS
        ? [
            '/Applications/Obsidian.app/Contents/MacOS/Obsidian',
            '${Platform.environment['HOME']}/Documents/Obsidian',
          ]
        : [];
    
    for (final obsidianPath in obsidianPaths) {
      if (obsidianPath.endsWith('.exe') || obsidianPath.endsWith('Obsidian')) {
        if (await File(obsidianPath).exists()) {
          // Look for vaults
          final vaultsPath = Platform.isWindows
            ? '${Platform.environment['USERPROFILE']}\\Documents\\Obsidian'
            : '${Platform.environment['HOME']}/Documents/Obsidian';
          
          final vaults = await _findObsidianVaults(vaultsPath);
          
          return IntegrationConfig(
            id: 'obsidian',
            name: 'Obsidian',
            status: DetectionStatus.ready,
            configuration: {
              'path': obsidianPath,
              'vaults': vaults,
            },
            message: 'Obsidian found with ${vaults.length} vault(s)',
          );
        }
      } else if (await Directory(obsidianPath).exists()) {
        final vaults = await _findObsidianVaults(obsidianPath);
        if (vaults.isNotEmpty) {
          return IntegrationConfig(
            id: 'obsidian',
            name: 'Obsidian',
            status: DetectionStatus.ready,
            configuration: {
              'vaultsPath': obsidianPath,
              'vaults': vaults,
            },
            message: 'Found ${vaults.length} Obsidian vault(s)',
          );
        }
      }
    }
    return null;
  }
  
  Future<List<String>> _findObsidianVaults(String searchPath) async {
    final vaults = <String>[];
    final dir = Directory(searchPath);
    
    if (!await dir.exists()) return vaults;
    
    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final obsidianConfig = Directory(path.join(entity.path, '.obsidian'));
          if (await obsidianConfig.exists()) {
            vaults.add(entity.path);
          }
        }
      }
    } catch (e) {
      // Error searching
    }
    
    return vaults;
  }
  
  Future<IntegrationConfig?> _detectJira() async {
    // Jira is web-based, check for CLI tool
    try {
      final result = await Process.run('jira', ['version']);
      if (result.exitCode == 0) {
        return IntegrationConfig(
          id: 'jira',
          name: 'Jira CLI',
          status: DetectionStatus.needsAuth,
          configuration: {
            'cli': true,
            'version': result.stdout.toString().trim(),
          },
          message: 'Jira CLI found. Configure API token.',
        );
      }
    } catch (e) {
      // CLI not found
    }
    
    // Return API-based config
    return IntegrationConfig(
      id: 'jira',
      name: 'Jira (API)',
      status: DetectionStatus.needsAuth,
      configuration: {'type': 'api'},
      message: 'Connect via Jira API. Add domain and token.',
    );
  }
  
  Future<IntegrationConfig?> _detectLinear() async {
    // Linear is primarily API-based
    return IntegrationConfig(
      id: 'linear',
      name: 'Linear',
      status: DetectionStatus.needsAuth,
      configuration: {'type': 'api'},
      message: 'Connect via Linear API. Add API key.',
    );
  }
  
  // AI/ML TOOLS DETECTION
  
  Future<IntegrationDetection> _detectAITools() async {
    final integrations = <IntegrationConfig>[];
    
    // OpenAI
    final openaiKey = Platform.environment['OPENAI_API_KEY'];
    if (openaiKey != null && openaiKey.isNotEmpty) {
      integrations.add(IntegrationConfig(
        id: 'openai',
        name: 'OpenAI',
        status: DetectionStatus.ready,
        configuration: {'keyConfigured': true},
        message: 'OpenAI API key found in environment',
      ));
    }
    
    // Anthropic
    final anthropicKey = Platform.environment['ANTHROPIC_API_KEY'];
    if (anthropicKey != null && anthropicKey.isNotEmpty) {
      integrations.add(IntegrationConfig(
        id: 'anthropic',
        name: 'Anthropic',
        status: DetectionStatus.ready,
        configuration: {'keyConfigured': true},
        message: 'Anthropic API key found in environment',
      ));
    }
    
    // Hugging Face
    final hfToken = Platform.environment['HF_TOKEN'] ?? Platform.environment['HUGGING_FACE_HUB_TOKEN'];
    if (hfToken != null && hfToken.isNotEmpty) {
      integrations.add(IntegrationConfig(
        id: 'huggingface',
        name: 'Hugging Face',
        status: DetectionStatus.ready,
        configuration: {'tokenConfigured': true},
        message: 'Hugging Face token found',
      ));
    }
    
    // Ollama (local)
    try {
      final result = await Process.run('ollama', ['version']);
      if (result.exitCode == 0) {
        integrations.add(IntegrationConfig(
          id: 'ollama',
          name: 'Ollama',
          status: DetectionStatus.ready,
          configuration: {
            'version': result.stdout.toString().trim(),
            'apiUrl': 'http://localhost:11434',
          },
          message: 'Ollama local LLM server found',
        ));
      }
    } catch (e) {
      // Not found
    }
    
    return IntegrationDetection(
      category: 'AI/ML',
      found: integrations.isNotEmpty,
      integrations: integrations,
    );
  }
  
  // FILE STORAGE DETECTION
  
  Future<IntegrationDetection> _detectFileStorage() async {
    final integrations = <IntegrationConfig>[];
    
    final dropbox = await _detectDropbox();
    if (dropbox != null) integrations.add(dropbox);
    
    final googleDrive = await _detectGoogleDrive();
    if (googleDrive != null) integrations.add(googleDrive);
    
    final oneDrive = await _detectOneDrive();
    if (oneDrive != null) integrations.add(oneDrive);
    
    return IntegrationDetection(
      category: 'File Storage',
      found: integrations.isNotEmpty,
      integrations: integrations,
    );
  }
  
  Future<IntegrationConfig?> _detectDropbox() async {
    final dropboxPaths = Platform.isWindows
      ? [
          '${Platform.environment['LOCALAPPDATA']}\\Dropbox',
          '${Platform.environment['USERPROFILE']}\\Dropbox',
        ]
      : [
          '${Platform.environment['HOME']}/Dropbox',
          '${Platform.environment['HOME']}/.dropbox',
        ];
    
    for (final dropboxPath in dropboxPaths) {
      if (await Directory(dropboxPath).exists()) {
        return IntegrationConfig(
          id: 'dropbox',
          name: 'Dropbox',
          status: DetectionStatus.ready,
          configuration: {'path': dropboxPath},
          message: 'Dropbox folder found',
        );
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectGoogleDrive() async {
    if (Platform.isWindows) {
      final drivePath = '${Platform.environment['USERPROFILE']}\\Google Drive';
      if (await Directory(drivePath).exists()) {
        return IntegrationConfig(
          id: 'googledrive',
          name: 'Google Drive',
          status: DetectionStatus.ready,
          configuration: {'path': drivePath},
          message: 'Google Drive folder found',
        );
      }
    } else if (Platform.isMacOS) {
      final drivePath = '${Platform.environment['HOME']}/Google Drive';
      if (await Directory(drivePath).exists()) {
        return IntegrationConfig(
          id: 'googledrive',
          name: 'Google Drive',
          status: DetectionStatus.ready,
          configuration: {'path': drivePath},
          message: 'Google Drive folder found',
        );
      }
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectOneDrive() async {
    if (Platform.isWindows) {
      final oneDrivePath = '${Platform.environment['USERPROFILE']}\\OneDrive';
      if (await Directory(oneDrivePath).exists()) {
        return IntegrationConfig(
          id: 'onedrive',
          name: 'OneDrive',
          status: DetectionStatus.ready,
          configuration: {'path': oneDrivePath},
          message: 'OneDrive folder found',
        );
      }
    }
    return null;
  }
  
  // ADDITIONAL DEVELOPMENT TOOLS
  
  Future<IntegrationConfig?> _detectDocker() async {
    try {
      final result = await Process.run('docker', ['--version']);
      if (result.exitCode == 0) {
        // Check if Docker daemon is running
        final psResult = await Process.run('docker', ['ps']);
        final isRunning = psResult.exitCode == 0;
        
        return IntegrationConfig(
          id: 'docker',
          name: 'Docker',
          status: isRunning ? DetectionStatus.ready : DetectionStatus.needsStart,
          configuration: {
            'version': result.stdout.toString().trim(),
            'daemonRunning': isRunning,
          },
          message: isRunning ? 'Docker is ready' : 'Docker installed but daemon not running',
          setupCommand: isRunning ? null : 'docker start',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectNodeJS() async {
    try {
      final result = await Process.run('node', ['--version']);
      if (result.exitCode == 0) {
        final npmResult = await Process.run('npm', ['--version']);
        
        return IntegrationConfig(
          id: 'nodejs',
          name: 'Node.js',
          status: DetectionStatus.ready,
          configuration: {
            'nodeVersion': result.stdout.toString().trim(),
            'npmVersion': npmResult.exitCode == 0 ? npmResult.stdout.toString().trim() : 'not found',
          },
          message: 'Node.js ready',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
  
  Future<IntegrationConfig?> _detectPython() async {
    try {
      // Try python3 first, then python
      ProcessResult result;
      try {
        result = await Process.run('python3', ['--version']);
      } catch (e) {
        result = await Process.run('python', ['--version']);
      }
      
      if (result.exitCode == 0) {
        // Check for pip
        ProcessResult? pipResult;
        try {
          pipResult = await Process.run('pip3', ['--version']);
        } catch (e) {
          pipResult = await Process.run('pip', ['--version']);
        }
        
        return IntegrationConfig(
          id: 'python',
          name: 'Python',
          status: DetectionStatus.ready,
          configuration: {
            'version': result.stdout.toString().trim(),
            'pipVersion': pipResult.exitCode == 0 ? pipResult.stdout.toString().trim() : 'not found',
          },
          message: 'Python ready',
        );
      }
    } catch (e) {
      // Not found
    }
    return null;
  }
}

/// Universal detection result containing everything we found
class UniversalDetectionResult {
  final Map<String, IntegrationDetection> detections;
  final int totalIntegrationsFound;
  final int totalReady;
  final int readinessScore; // 0-100
  
  const UniversalDetectionResult({
    required this.detections,
    required this.totalIntegrationsFound,
    required this.totalReady,
    required this.readinessScore,
  });
  
  String get summary {
    if (readinessScore >= 80) {
      return 'Your system is well-configured! Found $totalIntegrationsFound integrations, $totalReady ready to use.';
    } else if (readinessScore >= 50) {
      return 'Good start! Found $totalIntegrationsFound integrations, $totalReady are ready. Some need configuration.';
    } else {
      return 'Let\'s get you set up! Found $totalIntegrationsFound integrations. Most need configuration.';
    }
  }
}

/// Detection result for a category of integrations
class IntegrationDetection {
  final String category;
  final bool found;
  final List<IntegrationConfig> integrations;
  
  const IntegrationDetection({
    required this.category,
    required this.found,
    required this.integrations,
  });
}

/// Individual integration configuration
class IntegrationConfig {
  final String id;
  final String name;
  final DetectionStatus status;
  final Map<String, dynamic> configuration;
  final String message;
  final String? setupCommand;
  
  const IntegrationConfig({
    required this.id,
    required this.name,
    required this.status,
    required this.configuration,
    required this.message,
    this.setupCommand,
  });
}

/// Detection status for an integration
enum DetectionStatus {
  ready,       // Ready to use
  needsAuth,   // Found but needs authentication
  needsStart,  // Found but service not running
  notFound,    // Not installed
}

/// Provider for universal detection service
final universalDetectionServiceProvider = Provider<UniversalDetectionService>((ref) {
  final devTools = ref.watch(devToolsDetectionServiceProvider);
  final browsers = ref.watch(browserDetectionServiceProvider);
  return UniversalDetectionService(devTools, browsers);
});
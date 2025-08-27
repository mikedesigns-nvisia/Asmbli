/// Deterministic mapping from auto-detected tool names (or common
/// synonyms) to integration IDs used by the marketplace/installer.
///
/// This mapping is intentionally conservative: it maps common, well-known
/// tool names to the integration id we expect. When a mapping is not found
/// we still fall back to a registry text search.
final Map<String, String> detectionToIntegrationId = {
  // Editors / IDEs
  'VS Code': 'vscode',
  'Visual Studio Code': 'vscode',
  'vscode': 'vscode',
  'code': 'vscode',
  'intellij': 'intellij',
  'pycharm': 'intellij',
  'webstorm': 'intellij',
  'clion': 'intellij',
  'goland': 'intellij',
  'sublime': 'sublime',
  'atom': 'atom',

  // Version control / hosting
  'git': 'git',
  'git-lfs': 'git',
  'github': 'github',
  'github-cli': 'github',
  'gh': 'github',
  'gitlab': 'gitlab',
  'bitbucket': 'bitbucket',

  // Runtimes / package managers / build tools
  'node': 'terminal',
  'nodejs': 'terminal',
  'npm': 'terminal',
  'npx': 'terminal',
  'yarn': 'terminal',
  'pnpm': 'terminal',
  'python': 'terminal',
  'python3': 'terminal',
  'pip': 'terminal',
  'pipenv': 'terminal',
  'poetry': 'terminal',
  'go': 'terminal',
  'golang': 'terminal',
  'rust': 'terminal',
  'cargo': 'terminal',
  'java': 'terminal',
  'maven': 'terminal',
  'gradle': 'terminal',

  // Containers / orchestration
  'docker': 'docker',
  'docker desktop': 'docker',
  'docker-compose': 'docker',
  'podman': 'docker',
  'kubectl': 'kubernetes',
  'kubernetes': 'kubernetes',

  // Browsers
  'chrome': 'browser',
  'google chrome': 'browser',
  'chromium': 'browser',
  'brave': 'browser',
  'firefox': 'browser',
  'edge': 'browser',

  // Databases
  'postgres': 'postgres',
  'postgresql': 'postgres',
  'mysql': 'mysql',
  'sqlite': 'sqlite',
  'redis': 'redis',
  'mongodb': 'mongodb',

  // Cloud CLIs / tooling
  'aws': 'aws',
  'aws cli': 'aws',
  'gcloud': 'gcloud',
  'azure': 'azure',
  'az': 'azure',
  'heroku': 'heroku',
};

String _normalize(String s) {
  return s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9 ]"), '').trim();
}

String? mapDetectionToIntegrationId(String detectedName) {
  if (detectedName.trim().isEmpty) return null;

  final norm = _normalize(detectedName);

  // Exact normalized match
  for (final entry in detectionToIntegrationId.entries) {
    if (_normalize(entry.key) == norm) return entry.value;
  }

  // Substring / heuristic matches: prefer mapping where the key contains the
  // detected string or vice-versa.
  for (final entry in detectionToIntegrationId.entries) {
    final keyNorm = _normalize(entry.key);
    if (keyNorm.contains(norm) || norm.contains(keyNorm)) return entry.value;
  }

  // No deterministic mapping found
  return null;
}

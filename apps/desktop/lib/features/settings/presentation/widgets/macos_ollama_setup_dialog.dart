import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/desktop/macos_ollama_service.dart';
import '../../../../core/services/desktop/macos_service_provider.dart';

/// Enhanced macOS-specific Ollama setup dialog with native features
class MacOSOllamaSetupDialog extends ConsumerStatefulWidget {
  const MacOSOllamaSetupDialog({super.key});

  @override
  ConsumerState<MacOSOllamaSetupDialog> createState() => _MacOSOllamaSetupDialogState();

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MacOSOllamaSetupDialog(),
    );
  }
}

class _MacOSOllamaSetupDialogState extends ConsumerState<MacOSOllamaSetupDialog> {
  bool _isCheckingInstallation = false;
  Map<String, dynamic>? _installationStatus;
  String? _selectedInstallMethod;
  bool _showSystemInfo = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    await _checkOllamaInstallation();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ThemeColors(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.laptop_mac,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: SpacingTokens.componentSpacing),
          Text(
            'macOS Local AI Setup',
            style: GoogleFonts.fustat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSection(theme, colors),
            const SizedBox(height: SpacingTokens.sectionSpacing),
            _buildInstallationOptions(theme, colors),
            if (_showSystemInfo) ...[
              const SizedBox(height: SpacingTokens.sectionSpacing),
              _buildSystemInfo(theme, colors),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showSystemInfo = !_showSystemInfo),
          child: Text(
            _showSystemInfo ? 'Hide Details' : 'System Info',
            style: GoogleFonts.fustat(
              color: colors.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.fustat(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme, ThemeColors colors) {
    if (_installationStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final status = _installationStatus!;
    final isInstalled = status['ollama_app_installed'] == true ||
                       status['homebrew_installed'] == true ||
                       status['system_available'] == true;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: isInstalled
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: isInstalled
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isInstalled ? Icons.check_circle : Icons.warning,
                color: isInstalled ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: SpacingTokens.componentSpacing),
              Text(
                isInstalled ? 'Ollama Detected' : 'Ollama Not Found',
                style: GoogleFonts.fustat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isInstalled ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.componentSpacing),

          // Installation details
          if (status['ollama_app_installed'] == true)
            _buildStatusItem(
              '✅ Ollama.app installed',
              '/Applications/Ollama.app',
              theme,
              Colors.green,
            ),

          if (status['homebrew_installed'] == true)
            _buildStatusItem(
              '🍺 Homebrew Ollama installed',
              status['homebrew_path'] ?? 'Homebrew path',
              theme,
              Colors.green,
            ),

          if (status['system_available'] == true)
            _buildStatusItem(
              '⚙️ System Ollama available',
              status['system_path'] ?? 'System PATH',
              theme,
              Colors.green,
            ),

          // Action buttons
          const SizedBox(height: SpacingTokens.componentSpacing),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AsmblButton.primary(
                text: _isCheckingInstallation ? 'Checking...' : 'Refresh Status',
                icon: _isCheckingInstallation ? Icons.hourglass_empty : Icons.refresh,
                onPressed: _isCheckingInstallation ? null : _checkOllamaInstallation,
              ),

              if (!isInstalled)
                AsmblButton.secondary(
                  text: 'Open Terminal',
                  icon: Icons.terminal,
                  onPressed: _openTerminal,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String path, ThemeData theme, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.fustat(
                fontSize: 13,
                color: color.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            path,
            style: GoogleFonts.fustat(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationOptions(ThemeData theme, ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Installation Options',
          style: GoogleFonts.fustat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: SpacingTokens.componentSpacing),

        // Option 1: Official Installer (Recommended)
        _buildInstallOption(
          title: 'Official Installer',
          subtitle: 'Recommended • Easy setup with GUI',
          description: 'Download the official macOS installer from ollama.ai',
          icon: Icons.download,
          isRecommended: true,
          onTap: () => _selectInstallMethod('official'),
          theme: theme,
          colors: colors,
        ),

        const SizedBox(height: SpacingTokens.componentSpacing),

        // Option 2: Homebrew
        _buildInstallOption(
          title: 'Homebrew',
          subtitle: 'Command line • For developers',
          description: 'Install via Homebrew package manager',
          icon: Icons.terminal,
          onTap: () => _selectInstallMethod('homebrew'),
          theme: theme,
          colors: colors,
        ),

        if (_selectedInstallMethod != null) ...[
          const SizedBox(height: SpacingTokens.componentSpacing),
          _buildInstallInstructions(theme, colors),
        ],
      ],
    );
  }

  Widget _buildInstallOption({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    bool isRecommended = false,
    required VoidCallback onTap,
    required ThemeData theme,
    required ThemeColors colors,
  }) {
    final isSelected = _selectedInstallMethod == title.toLowerCase().replaceAll(' ', '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.cardPadding),
        decoration: BoxDecoration(
          color: isSelected
            ? colors.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          border: Border.all(
            color: isSelected
              ? colors.primary.withValues(alpha: 0.5)
              : colors.border.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRecommended
                  ? Colors.green.withValues(alpha: 0.2)
                  : colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isRecommended ? Colors.green : colors.primary,
                size: 20,
              ),
            ),

            const SizedBox(width: SpacingTokens.componentSpacing),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.fustat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: GoogleFonts.fustat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.fustat(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.fustat(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? colors.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallInstructions(ThemeData theme, ThemeColors colors) {
    if (_selectedInstallMethod == 'official') {
      return _buildOfficialInstructions(theme, colors);
    } else if (_selectedInstallMethod == 'homebrew') {
      return _buildHomebrewInstructions(theme, colors);
    }
    return const SizedBox.shrink();
  }

  Widget _buildOfficialInstructions(ThemeData theme, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Official Installer Steps',
            style: GoogleFonts.fustat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),

          const SizedBox(height: SpacingTokens.componentSpacing),

          _buildStep('1', 'Visit ollama.ai and download the macOS installer'),
          _buildStep('2', 'Open the downloaded .dmg file'),
          _buildStep('3', 'Drag Ollama.app to your Applications folder'),
          _buildStep('4', 'Launch Ollama.app from Applications'),
          _buildStep('5', 'Complete the setup and model installation'),

          const SizedBox(height: SpacingTokens.componentSpacing),

          AsmblButton.primary(
            text: 'Open ollama.ai',
            icon: Icons.open_in_browser,
            onPressed: () => _launchURL('https://ollama.ai/download'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomebrewInstructions(ThemeData theme, ThemeColors colors) {
    const commands = [
      'brew install ollama',
      'ollama serve &',
      'ollama pull llama2',
    ];

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Homebrew Installation',
            style: GoogleFonts.fustat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: SpacingTokens.componentSpacing),

          _buildStep('1', 'Install Homebrew if not already installed'),
          _buildStep('2', 'Open Terminal and run the commands below'),
          _buildStep('3', 'Wait for installation and model download to complete'),

          const SizedBox(height: SpacingTokens.componentSpacing),

          ...commands.map((command) => _buildCommandBlock(command, theme, colors)),

          const SizedBox(height: SpacingTokens.componentSpacing),

          Row(
            children: [
              AsmblButton.secondary(
                text: 'Open Terminal',
                icon: Icons.terminal,
                onPressed: _openTerminal,
              ),
              const SizedBox(width: 8),
              AsmblButton.primary(
                text: 'Copy All Commands',
                icon: Icons.copy,
                onPressed: () => _copyAllCommands(commands),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ThemeColors(context).primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.fustat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.fustat(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandBlock(String command, ThemeData theme, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                command,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _copyToClipboard(command),
              icon: Icon(Icons.copy, color: Colors.grey.shade300, size: 16),
              tooltip: 'Copy command',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfo(ThemeData theme, ThemeColors colors) {
    return Consumer(
      builder: (context, ref, child) {
        final systemInfoAsync = ref.watch(macOSOllamaSystemInfoProvider);

        return systemInfoAsync.when(
          data: (systemInfo) => Container(
            padding: const EdgeInsets.all(SpacingTokens.cardPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Information',
                  style: GoogleFonts.fustat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: SpacingTokens.componentSpacing),
                ...systemInfo.entries.map((entry) =>
                  _buildInfoRow(entry.key, entry.value.toString(), theme)
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.fustat(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.fustat(
                fontSize: 12,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectInstallMethod(String method) {
    setState(() {
      _selectedInstallMethod = _selectedInstallMethod == method ? null : method;
    });
  }

  Future<void> _checkOllamaInstallation() async {
    setState(() {
      _isCheckingInstallation = true;
      _installationStatus = null;
    });

    try {
      final service = ref.read(macOSOllamaServiceProvider);

      // Check various installation methods
      final status = <String, dynamic>{};

      // Check Ollama.app
      status['ollama_app_installed'] = await service.isOllamaAppInstalled;

      // Check Homebrew
      status['homebrew_installed'] = await service.isHomebrewOllamaInstalled;

      // Check system PATH
      try {
        final result = await Process.run('which', ['ollama']);
        if (result.exitCode == 0) {
          status['system_available'] = true;
          status['system_path'] = result.stdout.toString().trim();
        } else {
          status['system_available'] = false;
        }
      } catch (e) {
        status['system_available'] = false;
      }

      // Check if service is running
      status['service_running'] = await service.isAvailable;

      setState(() {
        _installationStatus = status;
      });

    } catch (e) {
      setState(() {
        _installationStatus = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isCheckingInstallation = false;
      });
    }
  }

  Future<void> _openTerminal() async {
    try {
      await Process.start('open', ['-a', 'Terminal']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terminal opened',
              style: GoogleFonts.fustat(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open Terminal: $e',
              style: GoogleFonts.fustat(),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied to clipboard',
            style: GoogleFonts.fustat(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyAllCommands(List<String> commands) async {
    final allCommands = commands.join('\n');
    await _copyToClipboard(allCommands);
  }
}
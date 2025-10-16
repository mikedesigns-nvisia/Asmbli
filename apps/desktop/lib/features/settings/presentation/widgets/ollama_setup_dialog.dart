import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/desktop/desktop_service_provider.dart';

/// Dialog to help users set up Ollama for local LLM functionality
class OllamaSetupDialog extends StatefulWidget {
  const OllamaSetupDialog({super.key});

  @override
  State<OllamaSetupDialog> createState() => _OllamaSetupDialogState();

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OllamaSetupDialog(),
    );
  }
}

class _OllamaSetupDialogState extends State<OllamaSetupDialog> {
  bool _isCheckingInstallation = false;
  String? _installationStatus;
  bool _showTerminalInstructions = false;

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
              Icons.download,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: SpacingTokens.componentSpacing),
          Text(
            'Set Up Local Models',
            style: GoogleFonts.fustat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To use local AI models, you need to install Ollama first.',
              style: GoogleFonts.fustat(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: SpacingTokens.sectionSpacing),
            
            // Step 1
            _buildStep(
              number: '1',
              title: 'Download Ollama',
              description: 'Visit ollama.ai and download the installer for your platform.',
              actionText: 'Open ollama.ai',
              onAction: () => _launchURL('https://ollama.ai'),
              theme: theme,
              colors: colors,
            ),
            
            const SizedBox(height: SpacingTokens.elementSpacing),
            
            // Step 2
            _buildStep(
              number: '2',
              title: 'Install Ollama',
              description: 'Run the installer and follow the setup instructions.',
              theme: theme,
              colors: colors,
            ),
            
            const SizedBox(height: SpacingTokens.elementSpacing),
            
            // Step 3 - Enhanced for non-technical users
            _buildVerificationStep(theme, colors),
            
            const SizedBox(height: SpacingTokens.sectionSpacing),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(SpacingTokens.cardPadding),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingTokens.componentSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'After Installation',
                          style: GoogleFonts.fustat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Restart Asmbli and visit Settings > Local Models to download AI models.',
                          style: GoogleFonts.fustat(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Maybe Later',
            style: GoogleFonts.fustat(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        AsmblButton.primary(
          text: 'Got It',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Build the enhanced verification step
  Widget _buildVerificationStep(ThemeData theme, ThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _installationStatus == 'success' ? Colors.green : colors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _installationStatus == 'success' 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '3',
                  style: GoogleFonts.fustat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
        
        const SizedBox(width: SpacingTokens.componentSpacing),
        
        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Installation',
                style: GoogleFonts.fustat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              
              if (_installationStatus == 'success') ...[
                // Success state
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Ollama is installed and ready!',
                        style: GoogleFonts.fustat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_installationStatus == 'not_found') ...[
                // Not found state
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ollama not found',
                            style: GoogleFonts.fustat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please complete the installation steps above, then check again.',
                        style: GoogleFonts.fustat(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Initial state
                Text(
                  "Let's check if Ollama installed correctly.",
                  style: GoogleFonts.fustat(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              
              const SizedBox(height: SpacingTokens.componentSpacing),
              
              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Auto-check button
                  AsmblButton.primary(
                    text: _isCheckingInstallation ? 'Checking...' : 'Check Installation',
                    icon: _isCheckingInstallation ? Icons.hourglass_empty : Icons.refresh,
                    onPressed: _isCheckingInstallation ? null : _checkOllamaInstallation,
                  ),
                  
                  // Manual verification options
                  if (_installationStatus != 'success') ...[
                    AsmblButton.secondary(
                      text: 'Open Terminal',
                      icon: Icons.terminal,
                      onPressed: _openTerminal,
                    ),
                    
                    TextButton(
                      onPressed: () => setState(() => _showTerminalInstructions = !_showTerminalInstructions),
                      child: Text(
                        _showTerminalInstructions ? 'Hide Instructions' : 'Manual Steps',
                        style: GoogleFonts.fustat(
                          fontSize: 12,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Manual terminal instructions (expandable)
              if (_showTerminalInstructions) ...[
                const SizedBox(height: SpacingTokens.componentSpacing),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Verification:',
                        style: GoogleFonts.fustat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTerminalInstructions(theme, colors),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalInstructions(ThemeData theme, ThemeColors colors) {
    final desktopService = DesktopServiceProvider.instance;
    
    String instructions;
    String command = 'ollama --version';
    
    if (desktopService.isWindows) {
      instructions = '1. Press Win + R\n2. Type "cmd" and press Enter\n3. Type the command below:';
    } else if (desktopService.isMacOS) {
      instructions = '1. Press Cmd + Space\n2. Type "Terminal" and press Enter\n3. Type the command below:';
    } else {
      instructions = '1. Press Ctrl + Alt + T\n2. Type the command below:';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          instructions,
          style: GoogleFonts.fustat(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.green.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, command),
                icon: Icon(Icons.copy, color: Colors.grey.shade300, size: 16),
                tooltip: 'Copy command',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    String? actionText,
    VoidCallback? onAction,
    required ThemeData theme,
    required ThemeColors colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.fustat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: SpacingTokens.componentSpacing),
        
        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.fustat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.fustat(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: SpacingTokens.componentSpacing),
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionText,
                    style: GoogleFonts.fustat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Check if Ollama is installed
  Future<void> _checkOllamaInstallation() async {
    setState(() {
      _isCheckingInstallation = true;
      _installationStatus = null;
    });

    try {
      final result = await Process.run('ollama', ['--version']);
      if (result.exitCode == 0) {
        setState(() {
          _installationStatus = 'success';
        });
      } else {
        setState(() {
          _installationStatus = 'not_found';
        });
      }
    } catch (e) {
      setState(() {
        _installationStatus = 'not_found';
      });
    } finally {
      setState(() {
        _isCheckingInstallation = false;
      });
    }
  }

  /// Open terminal/command prompt for the user
  Future<void> _openTerminal() async {
    try {
      final desktopService = DesktopServiceProvider.instance;
      
      if (desktopService.isWindows) {
        // Open Command Prompt on Windows
        await Process.start('cmd', [], runInShell: true);
      } else if (desktopService.isMacOS) {
        // Open Terminal on macOS
        await Process.start('open', ['-a', 'Terminal']);
      } else if (desktopService.isLinux) {
        // Try common terminal emulators on Linux
        try {
          await Process.start('gnome-terminal', []);
        } catch (e) {
          try {
            await Process.start('konsole', []);
          } catch (e) {
            await Process.start('xterm', []);
          }
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terminal opened! Type: ollama --version',
              style: GoogleFonts.fustat(),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showTerminalInstructions = true;
        });
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Command copied to clipboard',
            style: GoogleFonts.fustat(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
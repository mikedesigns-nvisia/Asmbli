import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/theme_service.dart';

class GeneralSettingsTab extends StatelessWidget {
  final ThemeService themeService;

  const GeneralSettingsTab({Key? key, required this.themeService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Application Settings
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Application Settings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // Theme selector
                    Consumer(
                      builder: (context, ref, child) {
                        final currentThemeMode = ref.watch(themeServiceProvider);
                        final currentThemeName = currentThemeMode == ThemeMode.light ? 'Mint' : 'Forest';

                        return DropdownButtonFormField<String>(
                          value: currentThemeName,
                          items: const [DropdownMenuItem(value: 'Mint', child: Text('Mint')), DropdownMenuItem(value: 'Forest', child: Text('Forest'))],
                          onChanged: (value) {
                            if (value == 'Mint') {
                              themeService.setTheme(ThemeMode.light);
                            } else if (value == 'Forest') {
                              themeService.setTheme(ThemeMode.dark);
                            }
                          },
                          decoration: const InputDecoration(labelText: 'Theme'),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.notifications, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Enable notifications', style: Theme.of(context).textTheme.bodyMedium)),
                        Switch(value: true, onChanged: (value) {}, activeColor: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // About Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text('Version 1.0.0', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

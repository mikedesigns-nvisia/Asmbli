import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService extends StateNotifier<ThemeMode> {
 static const String _themeKey = 'theme_mode';
 Box? _box;

 ThemeService() : super(ThemeMode.light) {
 _initializeTheme();
 }

 Future<void> _initializeTheme() async {
 try {
 _box = await Hive.openBox('app_settings');
 final savedTheme = _box?.get(_themeKey, defaultValue: 'light') ?? 'light';
 state = _themeModeFromString(savedTheme);
 } catch (e) {
 // If Hive fails to initialize, just use light theme (Banana Pudding)
 print('Failed to initialize theme storage: $e');
 state = ThemeMode.light;
 _box = null; // Ensure box is null so setTheme won't try to save
 }
 }

 void setTheme(ThemeMode mode) {
 state = mode;
 try {
 _box?.put(_themeKey, _themeModeToString(mode));
 } catch (e) {
 print('Failed to save theme preference: $e');
 // Theme will still work in memory, just won't persist
 }
 }

 void toggleTheme() {
 switch (state) {
 case ThemeMode.light:
 setTheme(ThemeMode.dark);
 break;
 case ThemeMode.dark:
 setTheme(ThemeMode.light);
 break;
 case ThemeMode.system:
 setTheme(ThemeMode.light);
 break;
 }
 }

 String getThemeName() {
 switch (state) {
 case ThemeMode.light:
 return 'Mint';
 case ThemeMode.dark:
 return 'Forest';
 case ThemeMode.system:
 return 'Forest'; // Default to dark if somehow system is selected
 }
 }

 IconData getThemeIcon() {
 switch (state) {
 case ThemeMode.light:
 return Icons.wb_sunny;
 case ThemeMode.dark:
 return Icons.nightlight_round;
 case ThemeMode.system:
 return Icons.nightlight_round; // Default to dark icon
 }
 }

 String _themeModeToString(ThemeMode mode) {
 switch (mode) {
 case ThemeMode.light:
 return 'light';
 case ThemeMode.dark:
 return 'dark';
 case ThemeMode.system:
 return 'system';
 }
 }

 ThemeMode _themeModeFromString(String mode) {
 switch (mode) {
 case 'light':
 return ThemeMode.light;
 case 'dark':
 return ThemeMode.dark;
 case 'system':
 default:
 return ThemeMode.dark;
 }
 }
}

final themeServiceProvider = StateNotifierProvider<ThemeService, ThemeMode>(
 (ref) => ThemeService(),
);
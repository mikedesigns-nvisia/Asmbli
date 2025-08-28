import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/color_schemes.dart';

class ThemeState {
 final ThemeMode mode;
 final String colorScheme;

 const ThemeState({
 this.mode = ThemeMode.light,
 this.colorScheme = AppColorSchemes.warmNeutral,
 });

 ThemeState copyWith({ThemeMode? mode, String? colorScheme}) {
 return ThemeState(
 mode: mode ?? this.mode,
 colorScheme: colorScheme ?? this.colorScheme,
 );
 }
}

class ThemeService extends StateNotifier<ThemeState> {
 static const String _themeKey = 'theme_mode';
 static const String _colorSchemeKey = 'color_scheme';
 Box? _box;

 ThemeService() : super(const ThemeState()) {
 _initializeTheme();
 }

 Future<void> _initializeTheme() async {
 try {
 _box = await Hive.openBox('app_settings');
 final savedTheme = _box?.get(_themeKey, defaultValue: 'light') ?? 'light';
 final savedColorScheme = _box?.get(_colorSchemeKey, defaultValue: AppColorSchemes.warmNeutral) ?? AppColorSchemes.warmNeutral;
 state = ThemeState(
 mode: _themeModeFromString(savedTheme),
 colorScheme: savedColorScheme,
 );
 } catch (e) {
 print('Failed to initialize theme storage: $e');
 state = const ThemeState();
 _box = null;
 }
 }

 void setTheme(ThemeMode mode) {
 state = state.copyWith(mode: mode);
 try {
 _box?.put(_themeKey, _themeModeToString(mode));
 } catch (e) {
 print('Failed to save theme preference: $e');
 }
 }

 void setColorScheme(String colorScheme) {
 state = state.copyWith(colorScheme: colorScheme);
 try {
 _box?.put(_colorSchemeKey, colorScheme);
 } catch (e) {
 print('Failed to save color scheme preference: $e');
 }
 }

 void toggleTheme() {
 switch (state.mode) {
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
 final schemeName = AppColorSchemes.all
 .firstWhere((s) => s.id == state.colorScheme, orElse: () => AppColorSchemes.all.first)
 .name;
 switch (state.mode) {
 case ThemeMode.light:
 return '$schemeName Light';
 case ThemeMode.dark:
 return '$schemeName Dark';
 case ThemeMode.system:
 return '$schemeName System';
 }
 }

 IconData getThemeIcon() {
 switch (state.mode) {
 case ThemeMode.light:
 return Icons.wb_sunny;
 case ThemeMode.dark:
 return Icons.nightlight_round;
 case ThemeMode.system:
 return Icons.auto_mode;
 }
 }

 /// Get the current theme data based on mode and color scheme
 ThemeData getLightTheme() {
 return AppColorSchemes.getTheme(state.colorScheme, false);
 }

 ThemeData getDarkTheme() {
 return AppColorSchemes.getTheme(state.colorScheme, true);
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

final themeServiceProvider = StateNotifierProvider<ThemeService, ThemeState>(
 (ref) => ThemeService(),
);
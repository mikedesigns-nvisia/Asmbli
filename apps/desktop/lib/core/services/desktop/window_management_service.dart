import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

enum WindowState {
 normal,
 minimized,
 maximized,
 fullScreen,
 hidden,
}

class DesktopWindowOptions {
 final Size? size;
 final Size? minimumSize;
 final Size? maximumSize;
 final Offset? position;
 final bool center;
 final String? title;
 final bool alwaysOnTop;
 final bool skipTaskbar;
 final bool resizable;
 final bool minimizable;
 final bool maximizable;
 final bool closable;
 final TitleBarStyle titleBarStyle;
 final Color? backgroundColor;

 const DesktopWindowOptions({
 this.size,
 this.minimumSize,
 this.maximumSize,
 this.position,
 this.center = true,
 this.title,
 this.alwaysOnTop = false,
 this.skipTaskbar = false,
 this.resizable = true,
 this.minimizable = true,
 this.maximizable = true,
 this.closable = true,
 this.titleBarStyle = TitleBarStyle.normal,
 this.backgroundColor,
 });
}

class DesktopWindowManagementService {
 static DesktopWindowManagementService? _instance;
 
 DesktopWindowManagementService._();
 
 static DesktopWindowManagementService get instance {
 _instance ??= DesktopWindowManagementService._();
 return _instance!;
 }

 bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

 Future<void> initialize() async {
 if (!isDesktop) return;

 await windowManager.ensureInitialized();
 }

 Future<void> configureWindow(DesktopWindowOptions options) async {
 if (!isDesktop) return;

 final windowOptions = WindowOptions(
 size: options.size ?? const Size(1400, 900),
 minimumSize: options.minimumSize ?? const Size(1000, 700),
 maximumSize: options.maximumSize,
 center: options.center,
 backgroundColor: options.backgroundColor ?? Colors.transparent,
 skipTaskbar: options.skipTaskbar,
 titleBarStyle: options.titleBarStyle,
 title: options.title ?? 'Asmbli Desktop',
 );

 windowManager.waitUntilReadyToShow(windowOptions, () async {
 await windowManager.show();
 await windowManager.focus();
 
 if (options.position != null) {
 await windowManager.setPosition(options.position!);
 }
 
 if (options.alwaysOnTop) {
 await windowManager.setAlwaysOnTop(true);
 }
 
 if (!options.resizable) {
 await windowManager.setResizable(false);
 }
 
 if (!options.minimizable) {
 await windowManager.setMinimizable(false);
 }
 
 if (!options.maximizable) {
 await windowManager.setMaximizable(false);
 }
 
 if (!options.closable) {
 await windowManager.setClosable(false);
 }
 });
 }

 Future<void> show() async {
 if (!isDesktop) return;
 await windowManager.show();
 }

 Future<void> hide() async {
 if (!isDesktop) return;
 await windowManager.hide();
 }

 Future<void> close() async {
 if (!isDesktop) return;
 await windowManager.close();
 }

 Future<void> minimize() async {
 if (!isDesktop) return;
 await windowManager.minimize();
 }

 Future<void> maximize() async {
 if (!isDesktop) return;
 await windowManager.maximize();
 }

 Future<void> unmaximize() async {
 if (!isDesktop) return;
 await windowManager.unmaximize();
 }

 Future<void> restore() async {
 if (!isDesktop) return;
 await windowManager.restore();
 }

 Future<void> focus() async {
 if (!isDesktop) return;
 await windowManager.focus();
 }

 Future<void> blur() async {
 if (!isDesktop) return;
 await windowManager.blur();
 }

 Future<void> setTitle(String title) async {
 if (!isDesktop) return;
 await windowManager.setTitle(title);
 }

 Future<String> getTitle() async {
 if (!isDesktop) return 'Asmbli Desktop';
 return await windowManager.getTitle();
 }

 Future<void> setSize(Size size) async {
 if (!isDesktop) return;
 await windowManager.setSize(size);
 }

 Future<Size> getSize() async {
 if (!isDesktop) return const Size(1400, 900);
 return await windowManager.getSize();
 }

 Future<void> setMinimumSize(Size size) async {
 if (!isDesktop) return;
 await windowManager.setMinimumSize(size);
 }

 Future<void> setMaximumSize(Size size) async {
 if (!isDesktop) return;
 await windowManager.setMaximumSize(size);
 }

 Future<void> setPosition(Offset position) async {
 if (!isDesktop) return;
 await windowManager.setPosition(position);
 }

 Future<Offset> getPosition() async {
 if (!isDesktop) return Offset.zero;
 return await windowManager.getPosition();
 }

 Future<void> center() async {
 if (!isDesktop) return;
 await windowManager.center();
 }

 Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
 if (!isDesktop) return;
 await windowManager.setAlwaysOnTop(alwaysOnTop);
 }

 Future<bool> isAlwaysOnTop() async {
 if (!isDesktop) return false;
 return await windowManager.isAlwaysOnTop();
 }

 Future<void> setFullScreen(bool fullScreen) async {
 if (!isDesktop) return;
 await windowManager.setFullScreen(fullScreen);
 }

 Future<bool> isFullScreen() async {
 if (!isDesktop) return false;
 return await windowManager.isFullScreen();
 }

 Future<void> setSkipTaskbar(bool skipTaskbar) async {
 if (!isDesktop) return;
 await windowManager.setSkipTaskbar(skipTaskbar);
 }

 Future<bool> isSkipTaskbar() async {
 if (!isDesktop) return false;
 return await windowManager.isSkipTaskbar();
 }

 Future<void> setResizable(bool resizable) async {
 if (!isDesktop) return;
 await windowManager.setResizable(resizable);
 }

 Future<bool> isResizable() async {
 if (!isDesktop) return true;
 return await windowManager.isResizable();
 }

 Future<void> setMinimizable(bool minimizable) async {
 if (!isDesktop) return;
 await windowManager.setMinimizable(minimizable);
 }

 Future<bool> isMinimizable() async {
 if (!isDesktop) return true;
 return await windowManager.isMinimizable();
 }

 Future<void> setMaximizable(bool maximizable) async {
 if (!isDesktop) return;
 await windowManager.setMaximizable(maximizable);
 }

 Future<bool> isMaximizable() async {
 if (!isDesktop) return true;
 return await windowManager.isMaximizable();
 }

 Future<void> setClosable(bool closable) async {
 if (!isDesktop) return;
 await windowManager.setClosable(closable);
 }

 Future<bool> isClosable() async {
 if (!isDesktop) return true;
 return await windowManager.isClosable();
 }

 Future<WindowState> getWindowState() async {
 if (!isDesktop) return WindowState.normal;
 
 if (await windowManager.isFullScreen()) {
 return WindowState.fullScreen;
 } else if (await windowManager.isMaximized()) {
 return WindowState.maximized;
 } else if (await windowManager.isMinimized()) {
 return WindowState.minimized;
 } else if (!await windowManager.isVisible()) {
 return WindowState.hidden;
 } else {
 return WindowState.normal;
 }
 }

 Future<bool> isVisible() async {
 if (!isDesktop) return true;
 return await windowManager.isVisible();
 }

 Future<bool> isMaximized() async {
 if (!isDesktop) return false;
 return await windowManager.isMaximized();
 }

 Future<bool> isMinimized() async {
 if (!isDesktop) return false;
 return await windowManager.isMinimized();
 }

 Future<bool> isFocused() async {
 if (!isDesktop) return true;
 return await windowManager.isFocused();
 }

 Future<void> setTitleBarStyle(TitleBarStyle titleBarStyle) async {
 if (!isDesktop) return;
 await windowManager.setTitleBarStyle(titleBarStyle);
 }

 Future<void> setBackgroundColor(Color color) async {
 if (!isDesktop) return;
 await windowManager.setBackgroundColor(color);
 }

 Future<void> setOpacity(double opacity) async {
 if (!isDesktop) return;
 
 if (Platform.isWindows || Platform.isLinux) {
 await windowManager.setOpacity(opacity);
 }
 }

 Future<double> getOpacity() async {
 if (!isDesktop) return 1.0;
 
 if (Platform.isWindows || Platform.isLinux) {
 return await windowManager.getOpacity();
 }
 
 return 1.0;
 }

 Future<void> setIcon(String iconPath) async {
 if (!isDesktop) return;
 
 if (Platform.isWindows || Platform.isLinux) {
 await windowManager.setIcon(iconPath);
 }
 }

 Future<void> startDragging() async {
 if (!isDesktop) return;
 await windowManager.startDragging();
 }

 Future<void> startResizing(ResizeEdge resizeEdge) async {
 if (!isDesktop) return;
 await windowManager.startResizing(resizeEdge);
 }

 void setPreventClose(bool preventClose) {
 if (!isDesktop) return;
 windowManager.setPreventClose(preventClose);
 }

 Future<void> destroy() async {
 if (!isDesktop) return;
 await windowManager.destroy();
 }

 void addListener(WindowListener listener) {
 if (!isDesktop) return;
 windowManager.addListener(listener);
 }

 void removeListener(WindowListener listener) {
 if (!isDesktop) return;
 windowManager.removeListener(listener);
 }

 Future<void> saveWindowState() async {
 if (!isDesktop) return;
 
 // Store window state in preferences - placeholder implementation
 print('Saving window state (placeholder)');
 }

 Future<void> restoreWindowState() async {
 if (!isDesktop) return;
 
 // Restore window state from preferences - placeholder implementation
 print('Restoring window state (placeholder)');
 }

 Future<Rect> getWindowBounds() async {
 if (!isDesktop) return Rect.zero;
 
 final position = await getPosition();
 final size = await getSize();
 
 return Rect.fromLTWH(
 position.dx,
 position.dy,
 size.width,
 size.height,
 );
 }

 Future<void> setWindowBounds(Rect bounds) async {
 if (!isDesktop) return;
 
 await setPosition(bounds.topLeft);
 await setSize(bounds.size);
 }

 String get platformName {
 if (Platform.isWindows) return 'Windows';
 if (Platform.isMacOS) return 'macOS';
 if (Platform.isLinux) return 'Linux';
 return 'Unknown';
 }

 bool get supportsTransparency {
 return Platform.isWindows || Platform.isLinux;
 }

 bool get supportsAlwaysOnTop {
 return true;
 }

 bool get supportsMinimizeToTray {
 return Platform.isWindows || Platform.isLinux;
 }

 bool get supportsGlobalHotkeys {
 return true;
 }

 bool get supportsSystemTray {
 return Platform.isWindows || Platform.isLinux;
 }
}
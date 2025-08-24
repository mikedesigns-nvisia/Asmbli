import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as provider;
import 'package:file_picker/file_picker.dart';

class DesktopFileSystemService {
 static DesktopFileSystemService? _instance;
 
 DesktopFileSystemService._();
 
 static DesktopFileSystemService get instance {
 _instance ??= DesktopFileSystemService._();
 return _instance!;
 }

 Future<Directory> getApplicationDocumentsDirectory() async {
 return await provider.getApplicationDocumentsDirectory();
 }

 Future<Directory> getApplicationSupportDirectory() async {
 return await provider.getApplicationSupportDirectory();
 }

 Future<Directory> getDownloadsDirectory() async {
 final directory = await provider.getDownloadsDirectory();
 if (directory == null) {
 throw Exception('Downloads directory not available on this platform');
 }
 return directory;
 }

 Future<Directory> getTemporaryDirectory() async {
 return await provider.getTemporaryDirectory();
 }

 Future<Directory> getAgentEngineDirectory() async {
 final appDir = await getApplicationSupportDirectory();
 final agentEngineDir = Directory(path.join(appDir.path, 'AgentEngine'));
 
 if (!await agentEngineDir.exists()) {
 await agentEngineDir.create(recursive: true);
 }
 
 return agentEngineDir;
 }

 Future<Directory> getAgentsDirectory() async {
 final baseDir = await getAgentEngineDirectory();
 final agentsDir = Directory(path.join(baseDir.path, 'agents'));
 
 if (!await agentsDir.exists()) {
 await agentsDir.create(recursive: true);
 }
 
 return agentsDir;
 }

 Future<Directory> getTemplatesDirectory() async {
 final baseDir = await getAgentEngineDirectory();
 final templatesDir = Directory(path.join(baseDir.path, 'templates'));
 
 if (!await templatesDir.exists()) {
 await templatesDir.create(recursive: true);
 }
 
 return templatesDir;
 }

 Future<Directory> getLogsDirectory() async {
 final baseDir = await getAgentEngineDirectory();
 final logsDir = Directory(path.join(baseDir.path, 'logs'));
 
 if (!await logsDir.exists()) {
 await logsDir.create(recursive: true);
 }
 
 return logsDir;
 }

 Future<Directory> getMCPServersDirectory() async {
 final baseDir = await getAgentEngineDirectory();
 final mcpDir = Directory(path.join(baseDir.path, 'mcp_servers'));
 
 if (!await mcpDir.exists()) {
 await mcpDir.create(recursive: true);
 }
 
 return mcpDir;
 }

 Future<File> createFile(String directoryPath, String fileName, String content) async {
 final file = File(path.join(directoryPath, fileName));
 await file.writeAsString(content);
 return file;
 }

 Future<String> readFile(String filePath) async {
 final file = File(filePath);
 
 if (!await file.exists()) {
 throw FileSystemException('File not found', filePath);
 }
 
 return await file.readAsString();
 }

 Future<List<int>> readFileAsBytes(String filePath) async {
 final file = File(filePath);
 
 if (!await file.exists()) {
 throw FileSystemException('File not found', filePath);
 }
 
 return await file.readAsBytes();
 }

 Future<void> writeFile(String filePath, String content) async {
 final file = File(filePath);
 await file.writeAsString(content);
 }

 Future<void> writeFileAsBytes(String filePath, List<int> bytes) async {
 final file = File(filePath);
 await file.writeAsBytes(bytes);
 }

 Future<void> deleteFile(String filePath) async {
 final file = File(filePath);
 
 if (await file.exists()) {
 await file.delete();
 }
 }

 Future<void> deleteDirectory(String directoryPath, {bool recursive = false}) async {
 final directory = Directory(directoryPath);
 
 if (await directory.exists()) {
 await directory.delete(recursive: recursive);
 }
 }

 Future<bool> fileExists(String filePath) async {
 return await File(filePath).exists();
 }

 Future<bool> directoryExists(String directoryPath) async {
 return await Directory(directoryPath).exists();
 }

 Future<List<FileSystemEntity>> listDirectory(String directoryPath, {bool recursive = false}) async {
 final directory = Directory(directoryPath);
 
 if (!await directory.exists()) {
 throw FileSystemException('Directory not found', directoryPath);
 }
 
 return await directory.list(recursive: recursive).toList();
 }

 Future<void> copyFile(String sourcePath, String destinationPath) async {
 final sourceFile = File(sourcePath);
 
 if (!await sourceFile.exists()) {
 throw FileSystemException('Source file not found', sourcePath);
 }
 
 await sourceFile.copy(destinationPath);
 }

 Future<void> moveFile(String sourcePath, String destinationPath) async {
 final sourceFile = File(sourcePath);
 
 if (!await sourceFile.exists()) {
 throw FileSystemException('Source file not found', sourcePath);
 }
 
 await sourceFile.rename(destinationPath);
 }

 Future<FileStat> getFileStats(String filePath) async {
 final file = File(filePath);
 
 if (!await file.exists()) {
 throw FileSystemException('File not found', filePath);
 }
 
 return await file.stat();
 }

 String getFileName(String filePath) {
 return path.basename(filePath);
 }

 String getFileExtension(String filePath) {
 return path.extension(filePath);
 }

 String getDirectoryName(String filePath) {
 return path.dirname(filePath);
 }

 String joinPath(String path1, String path2, [String? path3, String? path4]) {
 if (path3 != null && path4 != null) {
 return path.join(path1, path2, path3, path4);
 } else if (path3 != null) {
 return path.join(path1, path2, path3);
 }
 return path.join(path1, path2);
 }

 String normalizePath(String filePath) {
 return path.normalize(filePath);
 }

 String getAbsolutePath(String filePath) {
 return path.absolute(filePath);
 }

 Future<String?> pickFile({
 List<String>? allowedExtensions,
 String? dialogTitle,
 }) async {
 final result = await FilePicker.platform.pickFiles(
 type: allowedExtensions != null ? FileType.custom : FileType.any,
 allowedExtensions: allowedExtensions,
 dialogTitle: dialogTitle,
 );
 
 return result?.files.single.path;
 }

 Future<List<String>?> pickMultipleFiles({
 List<String>? allowedExtensions,
 String? dialogTitle,
 }) async {
 final result = await FilePicker.platform.pickFiles(
 type: allowedExtensions != null ? FileType.custom : FileType.any,
 allowedExtensions: allowedExtensions,
 dialogTitle: dialogTitle,
 allowMultiple: true,
 );
 
 return result?.paths.where((path) => path != null).cast<String>().toList();
 }

 Future<String?> pickDirectory({String? dialogTitle}) async {
 final result = await FilePicker.platform.getDirectoryPath(
 dialogTitle: dialogTitle,
 );
 
 return result;
 }

 Future<String?> saveFile({
 String? dialogTitle,
 String? fileName,
 List<String>? allowedExtensions,
 }) async {
 final result = await FilePicker.platform.saveFile(
 dialogTitle: dialogTitle,
 fileName: fileName,
 type: allowedExtensions != null ? FileType.custom : FileType.any,
 allowedExtensions: allowedExtensions,
 );
 
 return result;
 }

 Future<void> openFileInExplorer(String filePath) async {
 if (Platform.isWindows) {
 await Process.run('explorer', ['/select,', filePath]);
 } else if (Platform.isMacOS) {
 await Process.run('open', ['-R', filePath]);
 } else if (Platform.isLinux) {
 final directory = path.dirname(filePath);
 await Process.run('xdg-open', [directory]);
 }
 }

 Future<void> openDirectoryInExplorer(String directoryPath) async {
 if (Platform.isWindows) {
 await Process.run('explorer', [directoryPath]);
 } else if (Platform.isMacOS) {
 await Process.run('open', [directoryPath]);
 } else if (Platform.isLinux) {
 await Process.run('xdg-open', [directoryPath]);
 }
 }

 Future<int> getFileSize(String filePath) async {
 final file = File(filePath);
 
 if (!await file.exists()) {
 throw FileSystemException('File not found', filePath);
 }
 
 return await file.length();
 }

 String formatFileSize(int bytes) {
 if (bytes < 1024) {
 return '$bytes B';
 } else if (bytes < 1024 * 1024) {
 return '${(bytes / 1024).toStringAsFixed(2)} KB';
 } else if (bytes < 1024 * 1024 * 1024) {
 return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
 } else {
 return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
 }
 }

 Future<void> ensureDirectoryExists(String directoryPath) async {
 final directory = Directory(directoryPath);
 
 if (!await directory.exists()) {
 await directory.create(recursive: true);
 }
 }

 Future<void> clearDirectory(String directoryPath) async {
 final directory = Directory(directoryPath);
 
 if (await directory.exists()) {
 await for (final entity in directory.list()) {
 await entity.delete(recursive: true);
 }
 }
 }

 bool isAbsolutePath(String filePath) {
 return path.isAbsolute(filePath);
 }

 bool isRelativePath(String filePath) {
 return path.isRelative(filePath);
 }

 String getRelativePath(String filePath, {String? from}) {
 return path.relative(filePath, from: from);
 }
}
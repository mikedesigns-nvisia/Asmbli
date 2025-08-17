import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:chatmcp/services/network_sync_service.dart';
import 'package:chatmcp/utils/toast.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/utils/platform.dart';

class NetworkSyncSetting extends StatefulWidget {
  const NetworkSyncSetting({super.key});

  @override
  State<NetworkSyncSetting> createState() => _NetworkSyncSettingState();
}

class _NetworkSyncSettingState extends State<NetworkSyncSetting> {
  final NetworkSyncService _syncService = NetworkSyncService();
  final TextEditingController _serverUrlController = TextEditingController();

  bool _isServerRunning = false;
  String? _serverAddress;
  int _serverPort = 8080;

  // 同步状态
  bool _isSyncing = false;
  String _syncStatus = '';
  bool _syncSuccess = false;
  String? _syncError;

  // 连接历史
  List<SyncServerHistory> _connectionHistory = [];

  @override
  void initState() {
    super.initState();
    _isServerRunning = _syncService.isServerRunning;
    _serverAddress = _syncService.serverAddress;
    _serverPort = _syncService.serverPort;

    // 加载连接历史
    _loadConnectionHistory();

    // 监听服务器状态变化
    _syncService.onServerStateChanged = (isRunning, address, port) {
      if (mounted) {
        setState(() {
          _isServerRunning = isRunning;
          _serverAddress = address;
          _serverPort = port;
        });
      }
    };

    // 监听同步状态变化
    _syncService.onSyncStateChanged = (status, {bool? isLoading, bool? isSuccess, String? error}) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final localizedStatus = _getLocalizedStatus(status, l10n);

        setState(() {
          _syncStatus = localizedStatus;
          _isSyncing = isLoading ?? false;
          _syncSuccess = isSuccess ?? false;
          _syncError = error;
        });

        // 显示Toast消息
        if (isSuccess == true) {
          ToastUtils.success(localizedStatus);
        } else if (error != null) {
          ToastUtils.error(localizedStatus);
        }
      }
    };
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  /// 加载连接历史
  Future<void> _loadConnectionHistory() async {
    final histories = await SyncHistoryManager.getHistories();
    if (mounted) {
      setState(() {
        _connectionHistory = histories;
      });
    }
  }

  /// 保存连接历史
  Future<void> _saveConnectionHistory(String url, Map<String, dynamic>? serverInfo) async {
    final l10n = AppLocalizations.of(context)!;
    final history = SyncServerHistory(
      url: url,
      deviceName: serverInfo?['deviceName'] ?? l10n.unknownDevice,
      platform: serverInfo?['platform'] ?? l10n.unknownPlatform,
      lastConnected: DateTime.now(),
      displayName: serverInfo?['displayName'] ?? url,
    );

    await SyncHistoryManager.saveHistory(history);
    await _loadConnectionHistory();
  }

  /// 获取本地化状态消息
  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status) {
      case 'connectingToServer':
        return l10n.connectingToServer;
      case 'downloadingData':
        return l10n.downloadingData;
      case 'importingData':
        return l10n.importingData;
      case 'reinitializingData':
        return l10n.reinitializingData;
      case 'dataSyncSuccess':
        return l10n.dataSyncSuccess;
      case 'preparingData':
        return l10n.preparingData;
      case 'uploadingData':
        return l10n.uploadingData;
      case 'dataPushSuccess':
        return l10n.dataPushSuccess;
      default:
        // 处理错误消息
        if (status.startsWith('syncFailed:')) {
          return '${l10n.syncFailed}: ${status.substring(11)}';
        } else if (status.startsWith('pushFailed:')) {
          return '${l10n.pushFailed}: ${status.substring(11)}';
        }
        return status; // 如果没有匹配的，返回原始状态
    }
  }

  /// 格式化时间显示
  String _formatTime(DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// 连接到历史记录中的服务器
  Future<void> _connectToHistory(SyncServerHistory history) async {
    final l10n = AppLocalizations.of(context)!;
    _serverUrlController.text = history.url;
    ToastUtils.success(l10n.serverSelected(history.displayName));
  }

  /// 删除连接历史
  Future<void> _removeHistory(String url) async {
    final l10n = AppLocalizations.of(context)!;
    await SyncHistoryManager.removeHistory(url);
    await _loadConnectionHistory();
    ToastUtils.success(l10n.connectionRecordDeleted);
  }

  /// 显示所有连接历史
  void _showAllHistory() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.connectionHistory.replaceAll('：', '')),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _connectionHistory.length,
            itemBuilder: (context, index) {
              final history = _connectionHistory[index];
              return ListTile(
                leading: Icon(
                  history.platform.toLowerCase().contains('windows')
                      ? Icons.computer
                      : history.platform.toLowerCase().contains('android')
                      ? Icons.phone_android
                      : history.platform.toLowerCase().contains('ios')
                      ? Icons.phone_iphone
                      : Icons.devices,
                  color: Colors.blue,
                ),
                title: Text(history.displayName),
                subtitle: Text('${history.url}\n${_formatTime(history.lastConnected)}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.connect_without_contact),
                      onPressed: () {
                        Navigator.pop(context);
                        _connectToHistory(history);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _removeHistory(history.url);
                        Navigator.pop(context);
                        _showAllHistory();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await SyncHistoryManager.clearHistory();
              await _loadConnectionHistory();
              Navigator.pop(context);
              ToastUtils.success(l10n.clearAllConnectionHistory);
            },
            child: Text(l10n.clearAllHistory),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 服务器状态卡片
            _buildServerStatusCard(l10n),

            const SizedBox(height: 16),

            // 连接远程服务器
            _buildConnectCard(l10n),

            const SizedBox(height: 16),

            // 使用说明
            _buildInstructionsCard(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatusCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isServerRunning ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: _isServerRunning ? AppColors.green : AppColors.getInactiveTextColor(context),
                ),
                const SizedBox(width: 8),
                Text(
                  _isServerRunning ? l10n.syncServerRunning : l10n.syncServerStopped,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            if (_isServerRunning && _serverAddress != null) ...[
              const SizedBox(height: 16),
              Text('📱 ${l10n.scanQRToConnect}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              // 服务器地址和二维码
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getThemeBackgroundColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getCodePreviewBorderColor(context)),
                ),
                child: Column(
                  children: [
                    // 服务器地址
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.getCodePreviewBorderColor(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('http://$_serverAddress:$_serverPort', style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: 'http://$_serverAddress:$_serverPort'));
                              ToastUtils.success(l10n.addressCopied);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 二维码
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white, // 二维码背景始终为白色以确保可读性
                        borderRadius: BorderRadius.circular(12),
                        border: Theme.of(context).brightness == Brightness.dark
                            ? Border.all(color: AppColors.getCodePreviewBorderColor(context), width: 1)
                            : null,
                      ),
                      child: QrImageView(
                        data: 'http://$_serverAddress:$_serverPort',
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.black, // 确保二维码为黑色
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      '🔄 ${l10n.otherDevicesCanScan}',
                      style: TextStyle(fontSize: 12, color: AppColors.getInactiveTextColor(context), fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 服务器控制按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isServerRunning ? _stopServer : _startServer,
                icon: Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
                label: Text(_isServerRunning ? l10n.stopServer : l10n.startServer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isServerRunning ? AppColors.red : AppColors.green,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📲 ${l10n.connectToOtherDevices}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 扫码按钮 - 仅在移动平台显示
            if (kIsMobile) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openQRScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l10n.scanQRCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 连接历史
            if (_connectionHistory.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text('📋 ${l10n.connectionHistory}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...(_connectionHistory
                  .take(3)
                  .map(
                    (history) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppColors.getCodePreviewBorderColor(context)),
                        ),
                        leading: Icon(
                          history.platform.toLowerCase().contains('windows')
                              ? Icons.computer
                              : history.platform.toLowerCase().contains('android')
                              ? Icons.phone_android
                              : history.platform.toLowerCase().contains('ios')
                              ? Icons.phone_iphone
                              : Icons.devices,
                          size: 20,
                          color: AppColors.blue,
                        ),
                        title: Text(history.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          '${history.url} • ${_formatTime(history.lastConnected)}',
                          style: TextStyle(fontSize: 11, color: AppColors.getInactiveTextColor(context)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.connect_without_contact, size: 16),
                              onPressed: () => _connectToHistory(history),
                              tooltip: l10n.connect,
                            ),
                            IconButton(icon: const Icon(Icons.delete, size: 16), onPressed: () => _removeHistory(history.url), tooltip: l10n.delete),
                          ],
                        ),
                      ),
                    ),
                  )),
              if (_connectionHistory.length > 3)
                TextButton(onPressed: _showAllHistory, child: Text(l10n.viewAllConnections(_connectionHistory.length))),
              const SizedBox(height: 8),
            ],

            if (_connectionHistory.isNotEmpty) const Divider(),
            const SizedBox(height: 8),

            Text(l10n.manualInputAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: l10n.serverAddress,
                hintText: 'http://192.168.1.100:8080',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
              ),
            ),

            const SizedBox(height: 12),

            // 同步状态显示
            if (_isSyncing || _syncStatus.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _syncSuccess
                      ? AppColors.getThemeColor(context, lightColor: AppColors.green[50], darkColor: AppColors.green[900])
                      : _syncError != null
                      ? AppColors.getThemeColor(context, lightColor: AppColors.red[50], darkColor: AppColors.red[900])
                      : AppColors.getThemeColor(context, lightColor: AppColors.blue[50], darkColor: AppColors.blue[900]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _syncSuccess
                        ? AppColors.getThemeColor(context, lightColor: AppColors.green[200], darkColor: AppColors.green[700])
                        : _syncError != null
                        ? AppColors.getThemeColor(context, lightColor: AppColors.red[200], darkColor: AppColors.red[700])
                        : AppColors.getThemeColor(context, lightColor: AppColors.blue[200], darkColor: AppColors.blue[700]),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isSyncing)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Icon(
                        _syncSuccess
                            ? Icons.check_circle
                            : _syncError != null
                            ? Icons.error
                            : Icons.info,
                        color: _syncSuccess
                            ? AppColors.green
                            : _syncError != null
                            ? AppColors.red
                            : AppColors.blue,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _syncStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color: _syncSuccess
                              ? AppColors.getThemeColor(context, lightColor: AppColors.green[800], darkColor: AppColors.green[200])
                              : _syncError != null
                              ? AppColors.getThemeColor(context, lightColor: AppColors.red[800], darkColor: AppColors.red[200])
                              : AppColors.getThemeColor(context, lightColor: AppColors.blue[800], darkColor: AppColors.blue[200]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _syncFromRemote,
                    icon: const Icon(Icons.download),
                    label: Text(l10n.syncFromServer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _pushToRemote,
                    icon: const Icon(Icons.upload),
                    label: Text(l10n.pushToServer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📖 ${l10n.usageInstructions}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              '🖥️ ${l10n.desktopAsServer}\n'
              '${l10n.desktopStep1}\n'
              '${l10n.desktopStep2}\n'
              '${l10n.desktopStep3}\n\n'
              '📱 ${l10n.mobileConnect}\n'
              '${l10n.mobileStep1}\n'
              '${l10n.mobileStep2}\n'
              '${l10n.mobileStep3}\n\n'
              '🔄 ${l10n.dataSync}\n'
              '${l10n.uploadDescription}\n'
              '${l10n.downloadDescription}\n'
              '${l10n.syncContent}',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startServer() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _syncService.startServer();
      ToastUtils.success(l10n.syncServerStarted);
    } catch (e) {
      ToastUtils.error('${l10n.syncServerStartFailed}: $e');
    }
  }

  Future<void> _stopServer() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _syncService.stopServer();
      ToastUtils.success(l10n.syncServerStopped);
    } catch (e) {
      ToastUtils.error('${l10n.syncServerStopFailed}: $e');
    }
  }

  Future<void> _openQRScanner() async {
    try {
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerPage()));

      if (result != null && result is String && mounted) {
        _serverUrlController.text = result;

        // 尝试获取服务器信息并显示设备名称
        final l10n = AppLocalizations.of(context)!;
        try {
          final serverInfo = await _syncService.getServerInfo(result);
          if (serverInfo != null) {
            ToastUtils.success(l10n.scanSuccessConnectTo(serverInfo['displayName']));
          } else {
            ToastUtils.success(l10n.scanSuccessAddressFilled);
          }
        } catch (e) {
          ToastUtils.success(l10n.scanSuccessAddressFilled);
        }
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ToastUtils.error('${l10n.scannerOpenFailed}: $e');
    }
  }

  Future<void> _syncFromRemote() async {
    final l10n = AppLocalizations.of(context)!;
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) {
      ToastUtils.warn(l10n.pleaseInputServerAddress);
      return;
    }

    try {
      // Get server info
      final serverInfo = await _syncService.getServerInfo(url);

      // Sync from remote
      await _syncService.syncFromRemote(url);

      // Save connection history
      await _saveConnectionHistory(url, serverInfo);

      // Success message displayed by status callback
    } catch (e) {
      // Error message displayed by status callback
    }
  }

  Future<void> _pushToRemote() async {
    final l10n = AppLocalizations.of(context)!;
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) {
      ToastUtils.warn(l10n.pleaseInputServerAddress);
      return;
    }

    try {
      // 先获取服务器信息
      final serverInfo = await _syncService.getServerInfo(url);

      // 执行推送
      await _syncService.pushToRemote(url);

      // 保存连接历史
      await _saveConnectionHistory(url, serverInfo);

      // 成功消息通过状态回调显示
    } catch (e) {
      // 错误消息通过状态回调显示
    }
  }
}

// 二维码扫描页面
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isFlashOn = false;
  bool _hasScanned = false; // 防止重复扫描

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getThemeBackgroundColor(context),
      appBar: AppBar(
        title: Text(l10n.scanQRCodeTitle),
        backgroundColor: AppColors.getToolbarBackgroundColor(context),
        foregroundColor: AppColors.getThemeTextColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_off : Icons.flash_on, color: AppColors.getThemeTextColor(context)),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.getToolbarBackgroundColor(context), AppColors.getThemeBackgroundColor(context)],
          ),
        ),
        child: Column(
          children: [
            // 扫描区域
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.black.withAlpha(30), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MobileScanner(
                    controller: controller,
                    onDetect: _onDetect,
                    overlayBuilder: (context, constraints) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.blue, width: 6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 提示信息区域
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 扫描提示
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.getMessageBubbleBackgroundColor(context, false),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.getCodePreviewBorderColor(context), width: 1),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_scanner, size: 32, color: AppColors.blue),
                          const SizedBox(height: 12),
                          Text(
                            l10n.aimQRCode,
                            style: TextStyle(color: AppColors.getThemeTextColor(context), fontSize: 16, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.scanSyncQRCode,
                            style: TextStyle(color: AppColors.getInactiveTextColor(context), fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 闪光灯控制按钮
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: AppColors.getThemeColor(context, lightColor: AppColors.grey[100], darkColor: AppColors.grey[800]),
                      ),
                      child: IconButton(
                        onPressed: _toggleFlash,
                        icon: Icon(_isFlashOn ? Icons.flash_off : Icons.flash_on, size: 28),
                        color: _isFlashOn ? Colors.yellow[600] : AppColors.getInactiveTextColor(context),
                        tooltip: _isFlashOn ? l10n.flashOff : l10n.flashOn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null && !_hasScanned && mounted) {
        final code = barcode.rawValue!;

        // 标记已扫描，防止重复
        _hasScanned = true;

        // 立即停止扫描
        controller.stop();

        // 验证是否是有效的URL
        if (code.startsWith('http://') || code.startsWith('https://')) {
          // 扫描成功，立即退出并返回结果
          Navigator.of(context).pop(code);
        } else {
          // 无效URL，显示错误并重置扫描状态
          ToastUtils.warn('Invalid URL');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _hasScanned = false;
              });
              controller.start();
            }
          });
        }
        break;
      }
    }
  }

  Future<void> _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }
}

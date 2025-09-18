import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrustService extends StateNotifier<bool> {
  TrustService() : super(false);

  static const String _trustKey = 'app_trusted';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('🔒 Initializing trust service...');
      final prefs = await SharedPreferences.getInstance();
      final trusted = prefs.getBool(_trustKey) ?? false;
      print('🔒 Trust status loaded: $trusted');
      state = trusted;
      _initialized = true;
    } catch (e) {
      print('❌ Error loading trust status: $e');
      state = false;
      _initialized = true;
    }
  }

  Future<void> _loadTrustStatus() async {
    await initialize();
  }

  Future<void> setTrusted(bool trusted) async {
    try {
      print('🔒 Setting trust status to: $trusted');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_trustKey, trusted);
      state = trusted;
      print('🔒 Trust status saved successfully');
    } catch (e) {
      print('❌ Error saving trust status: $e');
    }
  }

  Future<void> clearTrust() async {
    await setTrusted(false);
  }
}

final trustServiceProvider = StateNotifierProvider<TrustService, bool>((ref) {
  return TrustService();
});
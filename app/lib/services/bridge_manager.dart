import '../bridge/api.dart';
import '../bridge/frb_generated.dart';

/// Singleton manager for P2P Bridge initialization
class BridgeManager {
  static BridgeManager? _instance;
  static bool _initialized = false;
  static bool _isInitializing = false;

  BridgeManager._();

  static BridgeManager get instance {
    _instance ??= BridgeManager._();
    return _instance!;
  }

  Future<bool> initialize() async {
    if (_initialized) return true;
    if (_isInitializing) {
      // Wait for ongoing initialization
      while (_isInitializing) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _initialized;
    }

    _isInitializing = true;
    try {
      await P2PBridge.init();
      _initialized = true;
      print('Bridge successfully initialized');
      return true;
    } catch (e) {
      print('Failed to initialize bridge: $e');
      _initialized = false;
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  bool get isInitialized => _initialized;
}
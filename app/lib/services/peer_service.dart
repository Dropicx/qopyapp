import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/peer.dart';
import '../bridge/api.dart';
import '../bridge/frb_generated.dart';
import 'bridge_manager.dart';
import 'websocket_discovery.dart';

class PeerService extends ChangeNotifier {
  final List<Peer> _discoveredPeers = [];
  bool _isDiscovering = false;
  Timer? _refreshTimer;
  bool _bridgeInitialized = false;
  WebSocketDiscovery? _wsDiscovery;
  bool _useWebSocketFallback = false;

  List<Peer> get discoveredPeers => List.unmodifiable(_discoveredPeers);
  bool get isDiscovering => _isDiscovering;

  PeerService() {
    _initializeBridge();
  }

  Future<void> _initializeBridge() async {
    if (_bridgeInitialized) return; // Prevent double initialization

    final success = await BridgeManager.instance.initialize();
    if (success) {
      try {
        final version = await initP2PEngine();
        print('P2P Engine initialized with version: $version');
        _bridgeInitialized = true;
      } catch (e) {
        print('Failed to initialize P2P Engine: $e');
        _bridgeInitialized = false;
      }
    } else {
      print('Bridge initialization failed - P2P discovery not available');
      _bridgeInitialized = false;
    }
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    if (!_bridgeInitialized) {
      await _initializeBridge();
      if (!_bridgeInitialized) {
        print('P2P Discovery not available: Native library not found for this platform');
        print('To enable P2P discovery on Android:');
        print('1. Install Android NDK');
        print('2. Run: ./build_android.sh');
        print('3. Rebuild the Flutter app');
        print('\nFalling back to WebSocket discovery...');
        _useWebSocketFallback = true;
      }
    }

    _isDiscovering = true;
    _discoveredPeers.clear();
    notifyListeners();

    try {
      // Get device info
      final deviceName = Platform.isAndroid ? 'Android-Device' : Platform.localHostname;
      final deviceType = _getDeviceType();

      print('Starting P2P discovery...');
      print('Device name: $deviceName');
      print('Device type: $deviceType');

      if (_useWebSocketFallback || Platform.isAndroid) {
        // Use WebSocket discovery for Android or as fallback
        await _startWebSocketDiscovery(deviceName, deviceType);
      } else {
        // Start Rust mDNS discovery
        await startPeerDiscovery(
          deviceName: deviceName,
          deviceType: deviceType,
        );

        print('P2P discovery started successfully');

        // Start polling for peers
        _startPeerPolling();
      }

      // For Android emulator testing, also try the host directly
      if (Platform.isAndroid) {
        _addManualHostPeer();
      }
    } catch (e) {
      print('Failed to start discovery: $e');

      // Try WebSocket as fallback
      if (!_useWebSocketFallback) {
        print('Falling back to WebSocket discovery...');
        _useWebSocketFallback = true;
        final deviceName = Platform.isAndroid ? 'Android-Device' : Platform.localHostname;
        final deviceType = _getDeviceType();
        await _startWebSocketDiscovery(deviceName, deviceType);
      } else {
        _isDiscovering = false;
        notifyListeners();
      }
    }
  }

  void _startPeerPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _refreshPeers();
    });

    // Initial fetch
    _refreshPeers();
  }

  Future<void> _refreshPeers() async {
    if (!_bridgeInitialized || !_isDiscovering) return;

    try {
      final flutterPeers = await getDiscoveredPeers();

      print('Discovered ${flutterPeers.length} peers from Rust');
      for (final peer in flutterPeers) {
        print('  - ${peer.name} at ${peer.ip}:${peer.port}');
      }

      // Convert Flutter peers to our Peer model
      _discoveredPeers.clear();
      for (final flutterPeer in flutterPeers) {
        // Skip self (but log it)
        if (flutterPeer.name == Platform.localHostname ||
            flutterPeer.name.contains('Android-Emulator')) {
          print('Skipping self: ${flutterPeer.name}');
          continue;
        }

        final peer = Peer(
          id: flutterPeer.id,
          name: flutterPeer.name,
          ipAddress: flutterPeer.ip,
          port: flutterPeer.port,
          deviceType: flutterPeer.deviceType,
          properties: flutterPeer.properties,
          discoveredAt: DateTime.now(),
        );
        _discoveredPeers.add(peer);
        print('Added peer: ${peer.name}');
      }

      if (_discoveredPeers.isNotEmpty) {
        print('Total peers in UI: ${_discoveredPeers.length}');
      }

      notifyListeners();
    } catch (e) {
      print('Failed to refresh peers: $e');
    }
  }

  Future<void> _startWebSocketDiscovery(String deviceName, String deviceType) async {
    print('Starting WebSocket discovery...');

    _wsDiscovery = WebSocketDiscovery();

    // Listen for discovered peers
    _wsDiscovery!.peerStream.listen((peer) {
      if (!_discoveredPeers.any((p) => p.id == peer.id)) {
        _discoveredPeers.add(peer);
        print('WebSocket discovered peer: ${peer.name}');
        notifyListeners();
      }
    });

    // Try to connect to local signaling server
    String serverUrl;
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to reach host
      serverUrl = 'ws://10.0.2.2:8081/ws';
    } else {
      serverUrl = 'ws://localhost:8081/ws';
    }

    final connected = await _wsDiscovery!.connect(
      serverUrl: serverUrl,
      deviceName: deviceName,
      deviceType: deviceType,
      port: 8080,
    );

    if (connected) {
      print('Connected to WebSocket discovery server');

      // Periodically request peer list
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _wsDiscovery?.requestPeers();
      });
    } else {
      print('Failed to connect to WebSocket discovery server');
      print('Make sure the signaling server is running (go run signaling-server/main.go)');
    }
  }

  void _addManualHostPeer() {
    // Add a manual peer for testing with Android emulator
    // 10.0.2.2 is the host machine from Android emulator's perspective
    final hostPeer = Peer(
      id: 'manual-host',
      name: 'Host Machine (Manual)',
      ipAddress: '10.0.2.2',
      port: 8080,
      deviceType: 'desktop',
      properties: {'version': '1.0.0', 'manual': 'true'},
      discoveredAt: DateTime.now(),
    );

    if (!_discoveredPeers.any((p) => p.id == hostPeer.id)) {
      _discoveredPeers.add(hostPeer);
      print('Added manual host peer for emulator testing: ${hostPeer.ipAddress}');
      notifyListeners();
    }
  }

  void addManualPeer(String ipAddress, {int port = 8080, String? name}) {
    final peer = Peer(
      id: 'manual-$ipAddress',
      name: name ?? 'Manual Peer ($ipAddress)',
      ipAddress: ipAddress,
      port: port,
      deviceType: 'unknown',
      properties: {'manual': 'true'},
      discoveredAt: DateTime.now(),
    );

    if (!_discoveredPeers.any((p) => p.id == peer.id)) {
      _discoveredPeers.add(peer);
      print('Added manual peer: $ipAddress:$port');
      notifyListeners();
    }
  }

  String _getDeviceType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    _refreshTimer?.cancel();

    if (_bridgeInitialized && !_useWebSocketFallback) {
      try {
        await stopPeerDiscovery();
      } catch (e) {
        print('Failed to stop discovery: $e');
      }
    }

    if (_wsDiscovery != null) {
      _wsDiscovery!.disconnect();
      _wsDiscovery = null;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (_bridgeInitialized) {
      stopPeerDiscovery();
    }
    _wsDiscovery?.dispose();
    super.dispose();
  }
}
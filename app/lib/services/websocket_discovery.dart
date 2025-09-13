import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/peer.dart';

class WebSocketDiscovery {
  WebSocketChannel? _channel;
  final StreamController<Peer> _peerController = StreamController<Peer>.broadcast();
  final List<Peer> _discoveredPeers = [];
  String? _myPeerId;
  bool _isConnected = false;

  Stream<Peer> get peerStream => _peerController.stream;
  List<Peer> get discoveredPeers => List.unmodifiable(_discoveredPeers);
  bool get isConnected => _isConnected;

  Future<bool> connect({
    required String serverUrl,
    required String deviceName,
    required String deviceType,
    int port = 8080,
  }) async {
    try {
      print('Connecting to WebSocket discovery server at $serverUrl');

      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _isConnected = true;

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
        },
      );

      // Wait a bit for welcome message
      await Future.delayed(Duration(milliseconds: 500));

      // Register ourselves
      final registerMsg = {
        'type': 'register',
        'name': deviceName,
        'device_type': deviceType,
        'port': port,
      };
      _channel!.sink.add(jsonEncode(registerMsg));
      print('Sent registration: $registerMsg');

      // Request peer list
      await Future.delayed(Duration(milliseconds: 500));
      requestPeers();

      return true;
    } catch (e) {
      print('Failed to connect to WebSocket discovery: $e');
      _isConnected = false;
      return false;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      print('WebSocket message: $data');

      switch (data['type']) {
        case 'welcome':
          _myPeerId = data['peer_id'];
          print('Received peer ID: $_myPeerId');
          break;

        case 'peer_joined':
          if (data['name'] != null && data['name'] != '') {
            final peer = Peer(
              id: data['peer_id'] ?? 'ws-${data['name']}',
              name: data['name'],
              ipAddress: _extractIP(data['ip'] ?? ''),
              port: data['port'] ?? 8080,
              deviceType: data['device_type'] ?? 'unknown',
              properties: {'source': 'websocket'},
              discoveredAt: DateTime.now(),
            );

            // Don't add if already exists
            if (!_discoveredPeers.any((p) => p.id == peer.id)) {
              _discoveredPeers.add(peer);
              _peerController.add(peer);
              print('New peer discovered via WebSocket: ${peer.name} at ${peer.ipAddress}');
            }
          }
          break;

        case 'peers_list':
          final peers = data['peers'] as List<dynamic>?;
          if (peers != null) {
            print('Received ${peers.length} peers from server');
            for (final peerData in peers) {
              final peer = Peer(
                id: peerData['id'] ?? 'ws-${peerData['name']}',
                name: peerData['name'] ?? 'Unknown',
                ipAddress: _extractIP(peerData['ip'] ?? ''),
                port: peerData['port'] ?? 8080,
                deviceType: peerData['device_type'] ?? 'unknown',
                properties: {'source': 'websocket'},
                discoveredAt: DateTime.now(),
              );

              if (!_discoveredPeers.any((p) => p.id == peer.id)) {
                _discoveredPeers.add(peer);
                _peerController.add(peer);
                print('Peer from list: ${peer.name} at ${peer.ipAddress}');
              }
            }
          }
          break;

        case 'peer_left':
          final peerId = data['peer_id'];
          _discoveredPeers.removeWhere((p) => p.id == peerId);
          print('Peer left: $peerId');
          break;
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  String _extractIP(String address) {
    // Extract IP from address like "192.168.1.100:12345"
    if (address.contains(':')) {
      final parts = address.split(':');
      // Handle IPv6 addresses
      if (parts.length > 2) {
        // IPv6
        return address.substring(0, address.lastIndexOf(':'));
      }
      return parts[0];
    }
    return address;
  }

  void requestPeers() {
    if (_channel != null && _isConnected) {
      final msg = {'type': 'get_peers'};
      _channel!.sink.add(jsonEncode(msg));
      print('Requested peer list');
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _discoveredPeers.clear();
  }

  void dispose() {
    disconnect();
    _peerController.close();
  }
}
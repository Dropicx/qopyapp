# API Documentation

This document provides comprehensive API documentation for QopyApp's components.

## 📚 Table of Contents

- [P2P Core (Rust)](#p2p-core-rust)
- [Signaling Server (Go)](#signaling-server-go)
- [Flutter App (Dart)](#flutter-app-dart)
- [WebSocket API](#websocket-api)
- [Error Handling](#error-handling)

## 🔧 P2P Core (Rust)

The P2P core provides mDNS-based peer discovery and secure file transfer capabilities.

### PeerDiscovery

Main service for discovering and managing peers on the local network.

#### Methods

##### `new(config: DiscoveryConfig) -> Result<Self, PeerDiscoveryError>`

Creates a new peer discovery instance.

**Parameters:**
- `config: DiscoveryConfig` - Configuration for the discovery service

**Returns:**
- `Result<Self, PeerDiscoveryError>` - New PeerDiscovery instance or error

**Example:**
```rust
use p2p_core::{PeerDiscovery, DiscoveryConfig};

let config = DiscoveryConfig::default();
let discovery = PeerDiscovery::new(config)?;
```

##### `start() -> Result<(), PeerDiscoveryError>`

Starts the peer discovery service.

**Returns:**
- `Result<(), PeerDiscoveryError>` - Success or error

**Example:**
```rust
discovery.start().await?;
```

##### `stop() -> Result<(), PeerDiscoveryError>`

Stops the peer discovery service.

**Returns:**
- `Result<(), PeerDiscoveryError>` - Success or error

**Example:**
```rust
discovery.stop().await?;
```

##### `subscribe() -> broadcast::Receiver<PeerEvent>`

Gets a receiver for peer events.

**Returns:**
- `broadcast::Receiver<PeerEvent>` - Event receiver

**Example:**
```rust
let mut receiver = discovery.subscribe();
while let Ok(event) = receiver.recv().await {
    match event {
        PeerEvent::PeerDiscovered(peer) => {
            println!("New peer: {}", peer.name);
        }
        PeerEvent::PeerLost(peer) => {
            println!("Peer lost: {}", peer.name);
        }
        _ => {}
    }
}
```

##### `get_peers() -> Vec<Peer>`

Gets all currently discovered peers.

**Returns:**
- `Vec<Peer>` - List of discovered peers

**Example:**
```rust
let peers = discovery.get_peers().await;
for peer in peers {
    println!("Peer: {} at {}:{}", peer.name, peer.ip, peer.port);
}
```

##### `discover_peers(timeout: Option<Duration>) -> Result<Vec<Peer>, PeerDiscoveryError>`

Discovers peers with optional timeout.

**Parameters:**
- `timeout: Option<Duration>` - Optional discovery timeout

**Returns:**
- `Result<Vec<Peer>, PeerDiscoveryError>` - List of discovered peers or error

**Example:**
```rust
use std::time::Duration;

let peers = discovery.discover_peers(Some(Duration::from_secs(10))).await?;
```

### DiscoveryConfig

Configuration for the peer discovery service.

#### Fields

- `service_type: String` - mDNS service type (default: "_qopyapp._tcp.local.")
- `service_name: String` - Device name for advertising
- `port: u16` - Port to advertise
- `properties: HashMap<String, String>` - Additional properties
- `discovery_timeout: Duration` - Discovery timeout
- `announce_interval: Duration` - Announcement interval

#### Example

```rust
use std::collections::HashMap;
use std::time::Duration;

let mut properties = HashMap::new();
properties.insert("version".to_string(), "1.0.0".to_string());
properties.insert("device_type".to_string(), "laptop".to_string());

let config = DiscoveryConfig {
    service_type: "_qopyapp._tcp.local.".to_string(),
    service_name: "my-device".to_string(),
    port: 8080,
    properties,
    discovery_timeout: Duration::from_secs(10),
    announce_interval: Duration::from_secs(30),
};
```

### Peer

Represents a discovered peer device.

#### Fields

- `name: String` - Peer name
- `ip: IpAddr` - IP address
- `port: u16` - Port number
- `service_type: String` - Service type
- `properties: HashMap<String, String>` - Additional properties

#### Example

```rust
let peer = Peer {
    name: "device-123".to_string(),
    ip: "192.168.1.100".parse().unwrap(),
    port: 8080,
    service_type: "_qopyapp._tcp.local.".to_string(),
    properties: HashMap::new(),
};
```

### PeerEvent

Events emitted by the discovery service.

#### Variants

- `PeerDiscovered(Peer)` - New peer found
- `PeerLost(Peer)` - Peer went offline
- `ServiceStarted` - Discovery service started
- `ServiceStopped` - Discovery service stopped
- `Error(PeerDiscoveryError)` - Error occurred

#### Example

```rust
match event {
    PeerEvent::PeerDiscovered(peer) => {
        println!("New peer discovered: {}", peer.name);
    }
    PeerEvent::PeerLost(peer) => {
        println!("Peer lost: {}", peer.name);
    }
    PeerEvent::ServiceStarted => {
        println!("Discovery service started");
    }
    PeerEvent::ServiceStopped => {
        println!("Discovery service stopped");
    }
    PeerEvent::Error(err) => {
        eprintln!("Error: {}", err);
    }
}
```

## 🌐 Signaling Server (Go)

The signaling server facilitates WebRTC connection establishment between peers.

### WebSocket Endpoints

#### `/ws`

WebSocket endpoint for signaling.

**Connection:**
```javascript
const ws = new WebSocket('ws://localhost:8080/ws');
```

### Message Types

#### Join Room

```json
{
  "type": "join",
  "room": "room_id",
  "peer_id": "peer_123"
}
```

#### Offer

```json
{
  "type": "offer",
  "room": "room_id",
  "from": "peer_123",
  "to": "peer_456",
  "sdp": "offer_sdp_string"
}
```

#### Answer

```json
{
  "type": "answer",
  "room": "room_id",
  "from": "peer_456",
  "to": "peer_123",
  "sdp": "answer_sdp_string"
}
```

#### ICE Candidate

```json
{
  "type": "ice_candidate",
  "room": "room_id",
  "from": "peer_123",
  "to": "peer_456",
  "candidate": {
    "candidate": "candidate_string",
    "sdpMLineIndex": 0,
    "sdpMid": "0"
  }
}
```

#### Heartbeat

```json
{
  "type": "heartbeat",
  "peer_id": "peer_123"
}
```

### Example Usage

```javascript
const ws = new WebSocket('ws://localhost:8080/ws');

ws.onopen = () => {
  // Join a room
  ws.send(JSON.stringify({
    type: 'join',
    room: 'room_123',
    peer_id: 'peer_456'
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  
  switch (message.type) {
    case 'offer':
      // Handle WebRTC offer
      break;
    case 'answer':
      // Handle WebRTC answer
      break;
    case 'ice_candidate':
      // Handle ICE candidate
      break;
  }
};
```

## 📱 Flutter App (Dart)

The Flutter app provides the user interface and integrates with the Rust backend.

### P2P Core Integration

#### Import

```dart
import 'package:p2p_core/p2p_core.dart';
```

#### Initialize Discovery

```dart
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PeerDiscovery discovery;
  List<Peer> peers = [];

  @override
  void initState() {
    super.initState();
    _initializeDiscovery();
  }

  Future<void> _initializeDiscovery() async {
    final config = DiscoveryConfig();
    discovery = PeerDiscovery(config);
    await discovery.start();
    
    // Listen for peer events
    discovery.subscribe().listen((event) {
      setState(() {
        if (event is PeerDiscovered) {
          peers.add(event.peer);
        } else if (event is PeerLost) {
          peers.removeWhere((p) => p.name == event.peer.name);
        }
      });
    });
  }
}
```

#### File Transfer

```dart
class FileTransferService {
  Future<void> sendFile(String filePath, Peer peer) async {
    // Implementation for sending file to peer
  }
  
  Future<void> receiveFile(String savePath) async {
    // Implementation for receiving file
  }
}
```

### UI Components

#### Peer List Widget

```dart
class PeerListWidget extends StatelessWidget {
  final List<Peer> peers;
  final Function(Peer) onPeerSelected;

  const PeerListWidget({
    Key? key,
    required this.peers,
    required this.onPeerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: peers.length,
      itemBuilder: (context, index) {
        final peer = peers[index];
        return ListTile(
          title: Text(peer.name),
          subtitle: Text('${peer.ip}:${peer.port}'),
          onTap: () => onPeerSelected(peer),
        );
      },
    );
  }
}
```

#### File Picker Widget

```dart
import 'package:file_picker/file_picker.dart';

class FilePickerWidget extends StatelessWidget {
  final Function(String) onFileSelected;

  const FilePickerWidget({
    Key? key,
    required this.onFileSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          onFileSelected(result.files.single.path!);
        }
      },
      child: Text('Select File'),
    );
  }
}
```

## 🔌 WebSocket API

### Connection

```javascript
const ws = new WebSocket('ws://localhost:8080/ws');
```

### Authentication

```javascript
ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'auth',
    token: 'your_auth_token'
  }));
};
```

### Room Management

#### Create Room

```javascript
ws.send(JSON.stringify({
  type: 'create_room',
  room_id: 'unique_room_id'
}));
```

#### Join Room

```javascript
ws.send(JSON.stringify({
  type: 'join_room',
  room_id: 'room_id',
  peer_id: 'your_peer_id'
}));
```

#### Leave Room

```javascript
ws.send(JSON.stringify({
  type: 'leave_room',
  room_id: 'room_id'
}));
```

### File Transfer

#### Start Transfer

```javascript
ws.send(JSON.stringify({
  type: 'start_transfer',
  room_id: 'room_id',
  file_name: 'example.txt',
  file_size: 1024,
  file_hash: 'sha256_hash'
}));
```

#### Transfer Chunk

```javascript
ws.send(JSON.stringify({
  type: 'transfer_chunk',
  room_id: 'room_id',
  chunk_id: 0,
  data: 'base64_encoded_data'
}));
```

#### Complete Transfer

```javascript
ws.send(JSON.stringify({
  type: 'complete_transfer',
  room_id: 'room_id',
  file_hash: 'sha256_hash'
}));
```

## ❌ Error Handling

### Rust Errors

#### PeerDiscoveryError

```rust
pub enum PeerDiscoveryError {
    MdnsError(String),
    NetworkInterfaceError(String),
    ServiceRegistrationFailed(String),
    ServiceDiscoveryFailed(String),
    InvalidServiceType(String),
    DiscoveryTimeout(String),
    IoError(String),
}
```

#### Usage

```rust
match discovery.start().await {
    Ok(()) => println!("Discovery started"),
    Err(PeerDiscoveryError::MdnsError(msg)) => {
        eprintln!("mDNS error: {}", msg);
    }
    Err(PeerDiscoveryError::NetworkInterfaceError(msg)) => {
        eprintln!("Network error: {}", msg);
    }
    Err(e) => eprintln!("Other error: {}", e),
}
```

### Go Errors

#### Custom Error Types

```go
type SignalingError struct {
    Code    int    `json:"code"`
    Message string `json:"message"`
}

func (e *SignalingError) Error() string {
    return e.Message
}
```

#### Usage

```go
if err != nil {
    if signalingErr, ok := err.(*SignalingError); ok {
        log.Printf("Signaling error %d: %s", signalingErr.Code, signalingErr.Message)
    } else {
        log.Printf("Unexpected error: %v", err)
    }
}
```

### Dart Errors

#### Exception Handling

```dart
try {
  await discovery.start();
} on PeerDiscoveryException catch (e) {
  print('Discovery error: ${e.message}');
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## 📊 Performance Considerations

### Rust

- Use `tokio` for async operations
- Implement connection pooling for WebSocket connections
- Use `Arc<RwLock<T>>` for shared state
- Profile with `cargo flamegraph`

### Go

- Use connection pooling for database connections
- Implement proper context cancellation
- Use `sync.Pool` for object reuse
- Profile with `go tool pprof`

### Flutter

- Use `ListView.builder` for large lists
- Implement proper state management
- Use `const` constructors where possible
- Profile with Flutter DevTools

## 🔒 Security Considerations

### Encryption

- All file transfers use ChaCha20-Poly1305 encryption
- Peer authentication uses Ed25519 signatures
- WebSocket connections use WSS in production

### Validation

- Validate all incoming WebSocket messages
- Sanitize file names and paths
- Implement rate limiting for API endpoints

### Best Practices

- Never log sensitive data
- Use secure random number generation
- Implement proper error handling
- Regular security audits

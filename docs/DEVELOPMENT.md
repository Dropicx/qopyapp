# Development Guide

This guide covers the development workflow, coding standards, and best practices for QopyApp.

## 📋 Table of Contents

- [Development Environment](#development-environment)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Debugging](#debugging)
- [Performance Optimization](#performance-optimization)
- [Contributing](#contributing)

## 🛠️ Development Environment

### Required Tools

- **IDE**: VS Code, Android Studio, or IntelliJ IDEA
- **Version Control**: Git
- **Package Managers**: Cargo (Rust), pub (Dart), go mod (Go)
- **Build Tools**: Flutter, Cargo, Go compiler

### Recommended Extensions

#### VS Code

```json
{
  "recommendations": [
    "dart-code.dart-code",
    "dart-code.flutter",
    "rust-lang.rust-analyzer",
    "golang.go",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss"
  ]
}
```

#### Android Studio

- Flutter Plugin
- Dart Plugin
- Rust Plugin (if available)

### Environment Setup

#### 1. Clone Repository

```bash
git clone https://github.com/yourusername/qopyapp.git
cd qopyapp
```

#### 2. Install Dependencies

```bash
# Flutter dependencies
cd app
flutter pub get

# Rust dependencies
cd ../p2p-core
cargo build

# Go dependencies
cd ../signaling-server
go mod tidy
```

#### 3. Configure IDE

**VS Code Settings:**

```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "rust-analyzer.cargo.buildScripts.enable": true,
  "go.gopath": "/path/to/go",
  "go.goroot": "/path/to/go/root"
}
```

## 📁 Project Structure

```
qopyapp/
├── app/                    # Flutter application
│   ├── lib/
│   │   ├── main.dart      # Entry point
│   │   ├── models/        # Data models
│   │   ├── services/      # Business logic
│   │   ├── widgets/       # UI components
│   │   └── screens/       # Screen implementations
│   ├── android/           # Android-specific code
│   ├── ios/               # iOS-specific code
│   ├── web/               # Web-specific code
│   └── pubspec.yaml       # Flutter dependencies
├── p2p-core/              # Rust P2P core
│   ├── src/
│   │   ├── lib.rs         # Library entry point
│   │   ├── peer_discovery.rs  # mDNS discovery
│   │   ├── file_transfer.rs   # File transfer logic
│   │   └── error.rs       # Error types
│   └── Cargo.toml         # Rust dependencies
├── signaling-server/      # Go signaling server
│   ├── main.go           # Server entry point
│   ├── handlers/         # HTTP/WebSocket handlers
│   ├── models/           # Data models
│   └── go.mod            # Go dependencies
├── docs/                 # Documentation
├── examples/             # Example code
└── tests/               # Integration tests
```

## 📝 Coding Standards

### Rust

#### Code Style

```rust
// Use rustfmt for formatting
cargo fmt

// Use clippy for linting
cargo clippy -- -D warnings
```

#### Naming Conventions

```rust
// Functions and variables: snake_case
fn discover_peers() -> Vec<Peer> {
    let peer_list = Vec::new();
    peer_list
}

// Types and traits: PascalCase
struct PeerDiscovery {
    config: DiscoveryConfig,
}

// Constants: SCREAMING_SNAKE_CASE
const MAX_PEERS: usize = 100;
```

#### Documentation

```rust
/// Discovers peers on the local network using mDNS.
///
/// # Arguments
///
/// * `timeout` - Optional timeout for discovery
///
/// # Returns
///
/// * `Result<Vec<Peer>, PeerDiscoveryError>` - List of discovered peers
///
/// # Examples
///
/// ```
/// let peers = discovery.discover_peers(Some(Duration::from_secs(10))).await?;
/// ```
pub async fn discover_peers(
    &self,
    timeout: Option<Duration>
) -> Result<Vec<Peer>, PeerDiscoveryError> {
    // Implementation
}
```

### Go

#### Code Style

```bash
# Use gofmt for formatting
gofmt -w .

# Use golint for linting
golint ./...
```

#### Naming Conventions

```go
// Exported functions: PascalCase
func HandleWebSocket(w http.ResponseWriter, r *http.Request) {
    // Implementation
}

// Unexported functions: camelCase
func handleMessage(msg Message) error {
    // Implementation
}

// Constants: PascalCase
const MaxConnections = 100
```

#### Documentation

```go
// HandleWebSocket handles WebSocket connections for signaling.
//
// It upgrades HTTP connections to WebSocket and manages
// peer-to-peer communication for file transfer.
//
// Parameters:
//   - w: HTTP response writer
//   - r: HTTP request
func HandleWebSocket(w http.ResponseWriter, r *http.Request) {
    // Implementation
}
```

### Dart/Flutter

#### Code Style

```bash
# Use dart format for formatting
dart format .

# Use dart analyze for linting
dart analyze
```

#### Naming Conventions

```dart
// Classes: PascalCase
class PeerDiscovery {
  // Fields: camelCase
  final String serviceName;
  final int port;
  
  // Methods: camelCase
  Future<void> start() async {
    // Implementation
  }
}

// Constants: camelCase
const int maxPeers = 100;
```

#### Documentation

```dart
/// Discovers peers on the local network using mDNS.
///
/// This class provides functionality to discover other
/// QopyApp instances on the same network.
///
/// Example:
/// ```dart
/// final discovery = PeerDiscovery();
/// await discovery.start();
/// ```
class PeerDiscovery {
  /// Starts the peer discovery service.
  ///
  /// Returns a [Future] that completes when the service
  /// has been started successfully.
  Future<void> start() async {
    // Implementation
  }
}
```

## 🧪 Testing

### Rust Testing

#### Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use tokio_test;

    #[tokio::test]
    async fn test_peer_discovery_creation() {
        let config = DiscoveryConfig::default();
        let discovery = PeerDiscovery::new(config);
        assert!(discovery.is_ok());
    }

    #[tokio::test]
    async fn test_peer_discovery_start_stop() {
        let config = DiscoveryConfig::default();
        let discovery = PeerDiscovery::new(config).unwrap();
        
        assert!(discovery.start().await.is_ok());
        assert!(discovery.stop().await.is_ok());
    }
}
```

#### Integration Tests

```rust
// tests/integration_test.rs
use p2p_core::{PeerDiscovery, DiscoveryConfig};
use std::time::Duration;

#[tokio::test]
async fn test_full_discovery_workflow() {
    let config = DiscoveryConfig::default();
    let discovery = PeerDiscovery::new(config).unwrap();
    
    discovery.start().await.unwrap();
    
    let peers = discovery.discover_peers(Some(Duration::from_secs(5))).await.unwrap();
    assert!(peers.len() >= 0);
    
    discovery.stop().await.unwrap();
}
```

#### Running Tests

```bash
# Run all tests
cargo test

# Run specific test
cargo test test_peer_discovery_creation

# Run with output
cargo test -- --nocapture
```

### Go Testing

#### Unit Tests

```go
package main

import (
    "testing"
    "time"
)

func TestHandleWebSocket(t *testing.T) {
    // Test implementation
}

func TestRoomManagement(t *testing.T) {
    // Test implementation
}
```

#### Integration Tests

```go
func TestWebSocketConnection(t *testing.T) {
    // Test WebSocket connection
}

func TestFileTransfer(t *testing.T) {
    // Test file transfer functionality
}
```

#### Running Tests

```bash
# Run all tests
go test ./...

# Run specific test
go test -run TestHandleWebSocket

# Run with verbose output
go test -v ./...
```

### Flutter Testing

#### Unit Tests

```dart
// test/peer_discovery_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_core/p2p_core.dart';

void main() {
  group('PeerDiscovery', () {
    test('should create instance with default config', () {
      final config = DiscoveryConfig();
      final discovery = PeerDiscovery(config);
      expect(discovery, isNotNull);
    });
  });
}
```

#### Widget Tests

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qopyapp/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
```

#### Running Tests

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/peer_discovery_test.dart

# Run with coverage
flutter test --coverage
```

## 🐛 Debugging

### Rust Debugging

#### Using `dbg!` Macro

```rust
let peers = discovery.discover_peers(None).await?;
dbg!(&peers);
```

#### Using `tracing`

```rust
use tracing::{info, debug, error};

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    
    info!("Starting peer discovery");
    debug!("Configuration: {:?}", config);
    
    if let Err(e) = discovery.start().await {
        error!("Failed to start discovery: {}", e);
    }
}
```

#### Using Debugger

```bash
# Install debugger
cargo install cargo-gdb

# Run with debugger
cargo gdb --bin p2p_core
```

### Go Debugging

#### Using `log` Package

```go
import "log"

func main() {
    log.SetFlags(log.LstdFlags | log.Lshortfile)
    
    log.Println("Starting signaling server")
    log.Printf("Configuration: %+v", config)
    
    if err := startServer(); err != nil {
        log.Fatalf("Failed to start server: %v", err)
    }
}
```

#### Using Delve Debugger

```bash
# Install delve
go install github.com/go-delve/delve/cmd/dlv@latest

# Run with debugger
dlv debug ./main.go
```

### Flutter Debugging

#### Using `print` and `debugPrint`

```dart
void main() {
  debugPrint('Starting Flutter app');
  
  runApp(MyApp());
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    print('HomePage initialized');
  }
}
```

#### Using Flutter DevTools

```bash
# Start DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Run app with DevTools
flutter run --debug
```

## ⚡ Performance Optimization

### Rust Optimization

#### Release Builds

```bash
# Build optimized version
cargo build --release

# Profile with flamegraph
cargo install flamegraph
cargo flamegraph --bin p2p_core
```

#### Memory Optimization

```rust
// Use Box for large structs
let large_data = Box::new(LargeStruct::new());

// Use Arc for shared ownership
let shared_data = Arc::new(SharedData::new());

// Use Vec::with_capacity for known sizes
let mut peers = Vec::with_capacity(100);
```

### Go Optimization

#### Profiling

```go
import _ "net/http/pprof"

func main() {
    go func() {
        log.Println(http.ListenAndServe("localhost:6060", nil))
    }()
    
    // Your application code
}
```

#### Memory Optimization

```go
// Use sync.Pool for object reuse
var peerPool = sync.Pool{
    New: func() interface{} {
        return &Peer{}
    },
}

// Use strings.Builder for string concatenation
var builder strings.Builder
builder.WriteString("peer_")
builder.WriteString(peerID)
```

### Flutter Optimization

#### Widget Optimization

```dart
// Use const constructors
const Text('Hello World')

// Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// Use RepaintBoundary for expensive widgets
RepaintBoundary(
  child: ExpensiveWidget(),
)
```

#### State Management

```dart
// Use Provider for state management
class PeerProvider extends ChangeNotifier {
  List<Peer> _peers = [];
  
  List<Peer> get peers => _peers;
  
  void addPeer(Peer peer) {
    _peers.add(peer);
    notifyListeners();
  }
}
```

## 🤝 Contributing

### Git Workflow

#### Branch Naming

```bash
# Feature branches
feature/peer-discovery
feature/file-transfer

# Bug fix branches
bugfix/memory-leak
bugfix/connection-timeout

# Hotfix branches
hotfix/security-patch
```

#### Commit Messages

```bash
# Format: type(scope): description
feat(discovery): add mDNS peer discovery
fix(transfer): resolve memory leak in file transfer
docs(api): update WebSocket API documentation
test(discovery): add unit tests for peer discovery
```

#### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit a pull request

### Code Review

#### Checklist

- [ ] Code follows style guidelines
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] No breaking changes (or properly documented)
- [ ] Performance impact is considered
- [ ] Security implications are reviewed

#### Review Guidelines

- Be constructive and helpful
- Focus on the code, not the person
- Suggest improvements, don't just criticize
- Ask questions if something is unclear
- Approve when ready, don't rush

### Release Process

#### Version Numbering

- **Major**: Breaking changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, backward compatible

#### Release Steps

1. Update version numbers
2. Update CHANGELOG.md
3. Create release branch
4. Run full test suite
5. Create release tag
6. Deploy to production
7. Announce release

## 📚 Additional Resources

### Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Rust Book](https://doc.rust-lang.org/book/)
- [Go Documentation](https://golang.org/doc/)
- [WebRTC Documentation](https://webrtc.org/getting-started/overview/)

### Tools

- [Flutter DevTools](https://docs.flutter.dev/development/tools/devtools)
- [Rust Analyzer](https://rust-analyzer.github.io/)
- [Go Tools](https://golang.org/cmd/go/)
- [VS Code](https://code.visualstudio.com/)

### Community

- [Flutter Community](https://flutter.dev/community)
- [Rust Community](https://www.rust-lang.org/community)
- [Go Community](https://golang.org/community)
- [QopyApp Discord](https://discord.gg/qopyapp)

# QopyApp Documentation

A comprehensive P2P file transfer application with end-to-end encryption, built with Flutter, Rust, and Go.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [API Documentation](#api-documentation)
- [Deployment](#deployment)
- [Contributing](#contributing)

## 🌟 Overview

QopyApp is a modern peer-to-peer file transfer application that enables secure file sharing between devices on the same network. The application features:

- **Cross-platform support**: Flutter app for mobile and desktop
- **High-performance backend**: Rust-based P2P core with mDNS discovery
- **Real-time signaling**: Go-based WebSocket signaling server
- **End-to-end encryption**: Secure file transfer with encryption
- **Automatic peer discovery**: mDNS-based device discovery
- **Modern UI**: Beautiful Flutter interface with animations

## 🏗️ Architecture

### Technology Stack

- **Frontend**: Flutter (Dart)
- **P2P Core**: Rust with Tokio async runtime
- **Signaling Server**: Go with WebSocket support
- **Discovery**: mDNS (multicast DNS)
- **Encryption**: ChaCha20-Poly1305, Ed25519 signatures

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Flutter App   │    │   Flutter App   │
│   (Device A)    │    │   (Device B)    │    │   (Device C)    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │     Signaling Server      │
                    │         (Go)              │
                    └───────────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │      P2P Core (Rust)      │
                    │    mDNS Discovery         │
                    └───────────────────────────┘
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.9.0 or higher)
- **Rust** (1.70 or higher)
- **Go** (1.21 or higher)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/qopyapp.git
   cd qopyapp
   ```

2. **Install dependencies**
   ```bash
   # Install Flutter dependencies
   cd app
   flutter pub get
   
   # Install Rust dependencies
   cd ../p2p-core
   cargo build
   
   # Install Go dependencies
   cd ../signaling-server
   go mod tidy
   ```

3. **Run the application**
   ```bash
   # Start signaling server
   cd signaling-server
   go run main.go
   
   # Start P2P core
   cd ../p2p-core
   cargo run
   
   # Start Flutter app
   cd ../app
   flutter run
   ```

## 🛠️ Development Setup

### Flutter Setup

1. **Install Flutter SDK**
   ```bash
   # macOS with Homebrew
   brew install --cask flutter
   
   # Or download from https://flutter.dev/docs/get-started/install
   ```

2. **Verify installation**
   ```bash
   flutter doctor
   ```

3. **Configure for your platform**
   ```bash
   # For Android
   flutter config --android-sdk /path/to/android/sdk
   
   # For iOS (macOS only)
   flutter config --ios-sdk /path/to/ios/sdk
   ```

### Rust Setup

1. **Install Rust**
   ```bash
   curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
   source ~/.cargo/env
   ```

2. **Verify installation**
   ```bash
   rustc --version
   cargo --version
   ```

3. **Install additional tools**
   ```bash
   # For Flutter integration
   cargo install flutter_rust_bridge_codegen
   ```

### Go Setup

1. **Install Go**
   ```bash
   # macOS with Homebrew
   brew install go
   
   # Or download from https://golang.org/dl/
   ```

2. **Verify installation**
   ```bash
   go version
   ```

3. **Set up workspace**
   ```bash
   export GOPATH=$HOME/go
   export PATH=$PATH:$GOPATH/bin
   ```

## 📚 API Documentation

### P2P Core (Rust)

The P2P core provides mDNS-based peer discovery and secure file transfer capabilities.

#### Key Components

- **PeerDiscovery**: Main service for discovering and managing peers
- **Peer**: Represents a discovered peer device
- **DiscoveryConfig**: Configuration for the discovery service

#### Example Usage

```rust
use p2p_core::{PeerDiscovery, DiscoveryConfig};
use std::time::Duration;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = DiscoveryConfig::default();
    let discovery = PeerDiscovery::new(config)?;
    
    // Start discovery
    discovery.start().await?;
    
    // Discover peers
    let peers = discovery.discover_peers(Some(Duration::from_secs(10))).await?;
    println!("Found {} peers", peers.len());
    
    // Cleanup
    discovery.stop().await?;
    Ok(())
}
```

### Signaling Server (Go)

The signaling server facilitates WebRTC connection establishment between peers.

#### Key Features

- WebSocket-based signaling
- Room management
- Connection negotiation
- Heartbeat monitoring

#### Example Usage

```go
package main

import (
    "log"
    "net/http"
    "github.com/gorilla/websocket"
)

func main() {
    http.HandleFunc("/ws", handleWebSocket)
    log.Println("Signaling server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### Flutter App (Dart)

The Flutter app provides the user interface and integrates with the Rust backend.

#### Key Features

- Modern Material Design UI
- File picker integration
- Real-time peer discovery
- Secure file transfer
- Progress tracking

#### Example Usage

```dart
import 'package:flutter/material.dart';
import 'package:p2p_core/p2p_core.dart';

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
        }
      });
    });
  }
}
```

## 🚀 Deployment

### Android

1. **Build APK**
   ```bash
   cd app
   flutter build apk --release
   ```

2. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

### iOS

1. **Build for iOS**
   ```bash
   cd app
   flutter build ios --release
   ```

2. **Archive in Xcode**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select "Any iOS Device" as target
   - Product → Archive

### Desktop

1. **Build for macOS**
   ```bash
   cd app
   flutter build macos --release
   ```

2. **Build for Windows**
   ```bash
   cd app
   flutter build windows --release
   ```

3. **Build for Linux**
   ```bash
   cd app
   flutter build linux --release
   ```

### Server Deployment

1. **Build Rust binary**
   ```bash
   cd p2p-core
   cargo build --release
   ```

2. **Build Go binary**
   ```bash
   cd signaling-server
   go build -o signaling-server main.go
   ```

3. **Deploy with Docker**
   ```bash
   docker build -t qopyapp-signaling .
   docker run -p 8080:8080 qopyapp-signaling
   ```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### Code Style

- **Rust**: Follow `rustfmt` and `clippy` recommendations
- **Go**: Follow `gofmt` and `golint` recommendations
- **Dart**: Follow `dart format` and `dart analyze` recommendations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/qopyapp/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/qopyapp/discussions)

## 🔗 Links

- [Flutter Documentation](https://docs.flutter.dev/)
- [Rust Book](https://doc.rust-lang.org/book/)
- [Go Documentation](https://golang.org/doc/)
- [WebRTC Documentation](https://webrtc.org/getting-started/overview/)

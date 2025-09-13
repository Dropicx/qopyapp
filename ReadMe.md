# Qopy - P2P File Transfer Application

A cross-platform P2P file transfer application with end-to-end encryption, supporting Windows, macOS, Linux, Android, and iOS.

## Features

- 🔍 **Automatic peer discovery** via mDNS
- 🔐 **End-to-end encryption** with ChaCha20-Poly1305
- 🚀 **High-speed transfers** up to 100GB files
- 📱 **Cross-platform** support for all major platforms
- 🌐 **NAT traversal** via WebRTC and signaling server
- 📊 **Real-time progress** tracking

## Architecture

```
qopyapp/
├── src/                    # Rust mDNS discovery service
├── p2p-core/              # Rust core library for P2P transfers
├── app/                   # Flutter application
├── signaling-server/      # Go WebSocket signaling server
└── docs/                  # Documentation
```

## Quick Start

### Prerequisites

- Rust (latest stable)
- Flutter (3.9+)
- Go (1.21+)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/qopyapp.git
cd qopyapp
```

2. Make the run script executable:
```bash
chmod +x run.sh
```

### Running the Application

#### Run everything:
```bash
./run.sh all
```

#### Run individual components:
```bash
# Run Rust mDNS discovery
./run.sh rust

# Run Flutter app
./run.sh flutter

# Run signaling server
./run.sh signaling
```

#### Run tests:
```bash
./run.sh test
```

## Development

### Flutter Development

```bash
cd app
flutter pub get
flutter run
```

### Rust Development

```bash
# Run mDNS discovery
cargo run

# Run tests
cargo test

# Build release
cargo build --release
```

### Signaling Server

```bash
cd signaling-server
go mod download
go run main.go
```

## Testing

### Test mDNS Discovery

1. Run the Rust service on multiple devices in the same network:
```bash
cargo run
```

2. Devices should automatically discover each other and appear in the logs.

### Test File Transfer

1. Start the Flutter app on two devices:
```bash
cd app
flutter run
```

2. Select a peer from the discovered devices list
3. Choose a file to transfer
4. Monitor the progress

## Building for Production

### Flutter Apps

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

### Rust Library

```bash
cargo build --release
```

## Security

- **Content Encryption**: ChaCha20-Poly1305 AEAD
- **Transport Security**: TLS 1.3 / Noise Protocol
- **Key Exchange**: SPAKE2 for human-readable codes
- **No persistent data**: All transfers are ephemeral

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- LocalSend for inspiration
- libp2p for P2P networking
- Flutter for cross-platform UI
- Rust for performance and safety

# Getting Started with QopyApp

This guide will help you get up and running with QopyApp quickly.

## 🚀 Quick Start

### Prerequisites

Before you begin, make sure you have the following installed:

- **Flutter SDK** (3.9.0+)
- **Rust** (1.70+)
- **Go** (1.21+)
- **Git**

### Installation

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
   # Terminal 1: Start signaling server
   cd signaling-server
   go run main.go
   
   # Terminal 2: Start P2P core
   cd p2p-core
   cargo run
   
   # Terminal 3: Start Flutter app
   cd app
   flutter run
   ```

## 📱 First Run

### 1. Launch the App

When you first run the Flutter app, you'll see the main screen with:

- **Device Discovery**: Automatically finds other QopyApp devices
- **File Picker**: Select files to share
- **Peer List**: Shows discovered devices
- **Transfer History**: Previous file transfers

### 2. Discover Peers

The app automatically discovers other QopyApp instances on your network:

1. Make sure all devices are on the same Wi-Fi network
2. Launch QopyApp on multiple devices
3. Wait a few seconds for discovery to complete
4. You should see other devices appear in the peer list

### 3. Send a File

To send a file to another device:

1. Tap the **"Select File"** button
2. Choose a file from your device
3. Select a peer from the list
4. Tap **"Send"**
5. The recipient will see a notification to accept the file

### 4. Receive a File

When someone sends you a file:

1. You'll see a notification
2. Tap to open QopyApp
3. Review the file details
4. Tap **"Accept"** to receive or **"Decline"** to reject

## 🔧 Configuration

### Basic Settings

Access settings by tapping the gear icon in the app:

- **Device Name**: Change how your device appears to others
- **Auto-Accept**: Automatically accept files from trusted devices
- **Download Location**: Choose where received files are saved
- **Notifications**: Enable/disable transfer notifications

### Advanced Settings

For advanced users, you can modify:

- **Discovery Timeout**: How long to search for peers
- **Transfer Chunk Size**: Size of file transfer chunks
- **Encryption**: Enable/disable end-to-end encryption
- **Port Settings**: Customize network ports

## 🌐 Network Requirements

### Local Network

QopyApp works on local networks where devices can communicate directly:

- **Wi-Fi Networks**: Home, office, or public Wi-Fi
- **Ethernet**: Wired connections on the same network
- **Mobile Hotspot**: Using a phone as a hotspot

### Firewall Settings

Make sure your firewall allows:

- **mDNS**: Port 5353 (UDP)
- **WebSocket**: Port 8080 (TCP)
- **File Transfer**: Port 8081 (TCP)

### Troubleshooting Network Issues

If devices aren't discovering each other:

1. **Check Network**: Ensure all devices are on the same network
2. **Restart Discovery**: Pull down to refresh the peer list
3. **Check Firewall**: Temporarily disable firewall to test
4. **Restart App**: Close and reopen QopyApp
5. **Check Logs**: Look for error messages in the app

## 📁 File Types

### Supported Formats

QopyApp supports all file types:

- **Documents**: PDF, DOC, DOCX, TXT, RTF
- **Images**: JPG, PNG, GIF, BMP, SVG
- **Videos**: MP4, AVI, MOV, MKV, WMV
- **Audio**: MP3, WAV, FLAC, AAC, OGG
- **Archives**: ZIP, RAR, 7Z, TAR, GZ
- **Code**: Any text-based files
- **Any File**: QopyApp can transfer any file type

### File Size Limits

- **No Hard Limit**: QopyApp can transfer files of any size
- **Network Dependent**: Transfer speed depends on network quality
- **Memory Usage**: Large files use more device memory during transfer

## 🔒 Security Features

### End-to-End Encryption

All file transfers are encrypted:

- **ChaCha20-Poly1305**: Modern encryption algorithm
- **Ed25519 Signatures**: Cryptographic signatures for authentication
- **Perfect Forward Secrecy**: Each transfer uses unique keys

### Privacy

QopyApp respects your privacy:

- **No Cloud Storage**: Files never leave your local network
- **No Data Collection**: We don't collect personal information
- **Local Only**: All communication stays on your network

### Trusted Devices

You can mark devices as trusted:

1. Tap on a device in the peer list
2. Select **"Mark as Trusted"**
3. Trusted devices can send files without confirmation

## 🚨 Troubleshooting

### Common Issues

#### App Won't Start

**Symptoms**: App crashes on startup or shows error

**Solutions**:
1. Restart your device
2. Clear app data and reinstall
3. Check if you have enough storage space
4. Update to the latest version

#### Can't Find Other Devices

**Symptoms**: No peers appear in the list

**Solutions**:
1. Ensure all devices are on the same Wi-Fi
2. Check firewall settings
3. Restart the discovery service
4. Try connecting to a different network

#### File Transfer Fails

**Symptoms**: Transfer starts but doesn't complete

**Solutions**:
1. Check network stability
2. Ensure both devices have enough storage
3. Try transferring a smaller file first
4. Restart both devices

#### Slow Transfer Speed

**Symptoms**: Files transfer but very slowly

**Solutions**:
1. Move closer to the Wi-Fi router
2. Close other network-intensive apps
3. Check if other devices are using the network
4. Try transferring during off-peak hours

### Getting Help

If you're still having issues:

1. **Check Documentation**: Look through the [API Documentation](API.md)
2. **Search Issues**: Check [GitHub Issues](https://github.com/yourusername/qopyapp/issues)
3. **Ask Community**: Join our [Discord](https://discord.gg/qopyapp)
4. **Report Bug**: Create a new issue with details

## 📚 Next Steps

Now that you have QopyApp running, you can:

### Learn More

- Read the [API Documentation](API.md) for technical details
- Check out the [Development Guide](DEVELOPMENT.md) to contribute
- Explore [examples](examples/) for code samples

### Customize

- Modify the UI to match your preferences
- Add custom file type handlers
- Integrate with other applications

### Contribute

- Report bugs and suggest features
- Submit pull requests
- Help improve documentation
- Join the community

## 🎯 Use Cases

### Personal Use

- **Photo Sharing**: Quickly share photos with family and friends
- **Document Transfer**: Send files between your devices
- **Backup**: Create local backups of important files

### Professional Use

- **Team Collaboration**: Share files with colleagues
- **Presentation**: Send files to meeting participants
- **Development**: Share code and assets between developers

### Educational Use

- **Student Projects**: Share files between students
- **Teacher Resources**: Distribute materials to students
- **Research**: Share data and papers with colleagues

## 🔄 Updates

### Automatic Updates

QopyApp checks for updates automatically:

- **Flutter App**: Updates through app store
- **Rust Core**: Updates through package manager
- **Go Server**: Updates through package manager

### Manual Updates

To update manually:

1. **Flutter App**: Update through app store
2. **Rust Core**: Run `cargo update`
3. **Go Server**: Run `go get -u`

### Version Compatibility

- **Major Versions**: May have breaking changes
- **Minor Versions**: Add new features, backward compatible
- **Patch Versions**: Bug fixes, fully compatible

## 📞 Support

### Community Support

- **Discord**: [Join our Discord](https://discord.gg/qopyapp)
- **GitHub**: [GitHub Discussions](https://github.com/yourusername/qopyapp/discussions)
- **Reddit**: [r/QopyApp](https://reddit.com/r/QopyApp)

### Professional Support

For enterprise or professional support:

- **Email**: support@qopyapp.com
- **Phone**: +1 (555) 123-4567
- **Website**: [qopyapp.com/support](https://qopyapp.com/support)

## 🎉 Congratulations!

You've successfully set up QopyApp! You can now:

- ✅ Discover and connect to other devices
- ✅ Send and receive files securely
- ✅ Customize settings to your preferences
- ✅ Troubleshoot common issues

Enjoy using QopyApp for your file transfer needs!

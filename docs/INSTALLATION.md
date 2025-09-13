# Installation Guide

This guide will help you install and set up QopyApp on your development machine.

## 📋 Prerequisites

### System Requirements

- **Operating System**: macOS 10.14+, Windows 10+, or Linux (Ubuntu 18.04+)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space
- **Network**: Internet connection for downloading dependencies

### Required Software

- **Flutter SDK** (3.9.0 or higher)
- **Rust** (1.70 or higher) 
- **Go** (1.21 or higher)
- **Git** (2.0 or higher)

## 🍎 macOS Installation

### 1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

### 2. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Install Flutter

```bash
# Using Homebrew
brew install --cask flutter

# Or download from https://flutter.dev/docs/get-started/install/macos
```

### 4. Install Rust

```bash
# Using Homebrew
brew install rust

# Or using rustup (recommended)
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
source ~/.cargo/env
```

### 5. Install Go

```bash
# Using Homebrew
brew install go

# Or download from https://golang.org/dl/
```

### 6. Install Android Studio

```bash
# Using Homebrew
brew install --cask android-studio

# Or download from https://developer.android.com/studio
```

### 7. Configure Android SDK

1. Open Android Studio
2. Go to **Tools** → **SDK Manager**
3. Install **Android SDK Platform 33** and **Android SDK Build-Tools 33.0.0**
4. Set environment variables:

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

## 🪟 Windows Installation

### 1. Install Chocolatey (if not already installed)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2. Install Flutter

```powershell
# Using Chocolatey
choco install flutter

# Or download from https://flutter.dev/docs/get-started/install/windows
```

### 3. Install Rust

```powershell
# Using Chocolatey
choco install rust

# Or using rustup (recommended)
# Download from https://rustup.rs/
```

### 4. Install Go

```powershell
# Using Chocolatey
choco install golang

# Or download from https://golang.org/dl/
```

### 5. Install Android Studio

```powershell
# Using Chocolatey
choco install androidstudio

# Or download from https://developer.android.com/studio
```

### 6. Configure Environment Variables

1. Open **System Properties** → **Environment Variables**
2. Add to **PATH**:
   - `C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools`
   - `C:\Users\%USERNAME%\AppData\Local\Android\Sdk\tools`
   - `C:\Users\%USERNAME%\AppData\Local\Android\Sdk\tools\bin`
3. Set **ANDROID_HOME**:
   - `C:\Users\%USERNAME%\AppData\Local\Android\Sdk`

## 🐧 Linux Installation

### 1. Update System Packages

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

### 2. Install Flutter

```bash
# Download Flutter
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz

# Add to PATH
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Install Rust

```bash
# Using rustup (recommended)
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
source ~/.cargo/env
```

### 4. Install Go

```bash
# Download Go
cd ~
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Add to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### 5. Install Android Studio

```bash
# Download Android Studio
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.28/android-studio-2023.1.1.28-linux.tar.gz
tar -xzf android-studio-2023.1.1.28-linux.tar.gz
sudo mv android-studio /opt/
sudo ln -s /opt/android-studio/bin/studio.sh /usr/local/bin/android-studio
```

### 6. Install Required Dependencies

```bash
# Ubuntu/Debian
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa

# CentOS/RHEL
sudo yum install -y curl git unzip xz zip mesa-libGLU
```

## ✅ Verification

### 1. Verify Flutter Installation

```bash
flutter doctor
```

Expected output should show:
- ✅ Flutter (Channel stable, 3.16.0)
- ✅ Android toolchain
- ✅ Android Studio
- ✅ Connected device (if any)

### 2. Verify Rust Installation

```bash
rustc --version
cargo --version
```

Expected output:
```
rustc 1.70.0 (90c541806 2023-05-31)
cargo 1.70.0 (ec8a8a0c6 2023-04-26)
```

### 3. Verify Go Installation

```bash
go version
```

Expected output:
```
go version go1.21.5 linux/amd64
```

## 🔧 Post-Installation Setup

### 1. Clone QopyApp Repository

```bash
git clone https://github.com/yourusername/qopyapp.git
cd qopyapp
```

### 2. Install Flutter Dependencies

```bash
cd app
flutter pub get
```

### 3. Install Rust Dependencies

```bash
cd ../p2p-core
cargo build
```

### 4. Install Go Dependencies

```bash
cd ../signaling-server
go mod tidy
```

### 5. Run Tests

```bash
# Test Flutter app
cd ../app
flutter test

# Test Rust code
cd ../p2p-core
cargo test

# Test Go code
cd ../signaling-server
go test ./...
```

## 🚨 Troubleshooting

### Common Issues

#### Flutter Doctor Issues

**Issue**: Android toolchain not found
```bash
# Solution: Install Android SDK
flutter doctor --android-licenses
```

**Issue**: No connected devices
```bash
# Solution: Start Android emulator
flutter emulators --launch <emulator_id>
```

#### Rust Issues

**Issue**: Linker not found
```bash
# macOS
xcode-select --install

# Ubuntu/Debian
sudo apt install build-essential

# CentOS/RHEL
sudo yum groupinstall "Development Tools"
```

#### Go Issues

**Issue**: Go modules not working
```bash
# Enable Go modules
go env -w GO111MODULE=on
```

### Platform-Specific Issues

#### macOS

**Issue**: CocoaPods not installed
```bash
sudo gem install cocoapods
```

**Issue**: Xcode command line tools
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

#### Windows

**Issue**: PowerShell execution policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Issue**: Long path names
```powershell
git config --system core.longpaths true
```

#### Linux

**Issue**: 32-bit libraries missing
```bash
# Ubuntu/Debian
sudo apt install lib32z1 lib32ncurses5 lib32stdc++6

# CentOS/RHEL
sudo yum install glibc.i686 libstdc++.i686
```

## 📞 Getting Help

If you encounter issues during installation:

1. Check the [Troubleshooting](#-troubleshooting) section above
2. Search [GitHub Issues](https://github.com/yourusername/qopyapp/issues)
3. Join our [Discord Community](https://discord.gg/qopyapp)
4. Create a new issue with:
   - Operating system and version
   - Error messages
   - Steps to reproduce

## 🎉 Next Steps

Once installation is complete, you can:

1. Read the [Getting Started Guide](GETTING_STARTED.md)
2. Explore the [API Documentation](API.md)
3. Check out the [Development Guide](DEVELOPMENT.md)
4. Start building with QopyApp!

#!/bin/bash

echo "🔨 Building Qopy P2P Library"
echo "============================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
OS="unknown"
LIBRARY_NAME=""
LIBRARY_EXT=""

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    LIBRARY_NAME="libp2p_core"
    LIBRARY_EXT="dylib"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    LIBRARY_NAME="libp2p_core"
    LIBRARY_EXT="so"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
    LIBRARY_NAME="p2p_core"
    LIBRARY_EXT="dll"
fi

echo -e "${YELLOW}Detected OS: $OS${NC}"
echo ""

# Build Rust library
echo -e "${YELLOW}Building Rust library...${NC}"
cd p2p-core
if cargo build --release; then
    echo -e "${GREEN}✅ Rust build successful${NC}"
else
    echo -e "${RED}❌ Rust build failed${NC}"
    exit 1
fi

# Find the built library
RUST_LIB="target/release/${LIBRARY_NAME}.${LIBRARY_EXT}"
if [ -f "$RUST_LIB" ]; then
    echo -e "${GREEN}✅ Found library: $RUST_LIB${NC}"
    ls -lh "$RUST_LIB"
else
    echo -e "${RED}❌ Library not found at: $RUST_LIB${NC}"
    exit 1
fi

# Create Flutter library directories if they don't exist
echo ""
echo -e "${YELLOW}Setting up Flutter directories...${NC}"

FLUTTER_LIB_DIR="../app/lib/native"
mkdir -p "$FLUTTER_LIB_DIR"

# Platform-specific library location
case "$OS" in
    macos)
        FLUTTER_PLATFORM_DIR="../app/macos/Runner"
        mkdir -p "$FLUTTER_PLATFORM_DIR"
        cp "$RUST_LIB" "$FLUTTER_PLATFORM_DIR/"
        echo -e "${GREEN}✅ Copied library to macOS app bundle${NC}"
        
        # Also copy to project root for development
        cp "$RUST_LIB" "../app/"
        echo -e "${GREEN}✅ Copied library to app root for development${NC}"
        ;;
    linux)
        FLUTTER_PLATFORM_DIR="../app/linux"
        mkdir -p "$FLUTTER_PLATFORM_DIR"
        cp "$RUST_LIB" "$FLUTTER_PLATFORM_DIR/"
        echo -e "${GREEN}✅ Copied library to Linux directory${NC}"
        ;;
    windows)
        FLUTTER_PLATFORM_DIR="../app/windows/runner"
        mkdir -p "$FLUTTER_PLATFORM_DIR"
        cp "$RUST_LIB" "$FLUTTER_PLATFORM_DIR/"
        echo -e "${GREEN}✅ Copied library to Windows directory${NC}"
        ;;
esac

# Create a simple FFI wrapper if it doesn't exist
echo ""
echo -e "${YELLOW}Creating FFI wrapper...${NC}"

cat > "$FLUTTER_LIB_DIR/p2p_ffi.dart" << 'EOF'
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

// FFI function signatures
typedef InitEngineC = Pointer<Utf8> Function();
typedef InitEngineDart = Pointer<Utf8> Function();

typedef GetVersionC = Pointer<Utf8> Function();
typedef GetVersionDart = Pointer<Utf8> Function();

typedef StartDiscoveryC = Int32 Function(Pointer<Utf8> deviceName, Pointer<Utf8> deviceType);
typedef StartDiscoveryDart = int Function(Pointer<Utf8> deviceName, Pointer<Utf8> deviceType);

typedef StopDiscoveryC = Int32 Function();
typedef StopDiscoveryDart = int Function();

typedef GetPeersC = Pointer<Utf8> Function();
typedef GetPeersDart = Pointer<Utf8> Function();

typedef FreeStringC = Void Function(Pointer<Utf8>);
typedef FreeStringDart = void Function(Pointer<Utf8>);

class P2PFFI {
  static DynamicLibrary? _lib;
  static P2PFFI? _instance;
  
  // Function pointers
  late final InitEngineDart _initEngine;
  late final GetVersionDart _getVersion;
  late final StartDiscoveryDart _startDiscovery;
  late final StopDiscoveryDart _stopDiscovery;
  late final GetPeersDart _getPeers;
  late final FreeStringDart _freeString;
  
  P2PFFI._() {
    _lib = _loadLibrary();
    _initFunctions();
  }
  
  static P2PFFI get instance {
    _instance ??= P2PFFI._();
    return _instance!;
  }
  
  static DynamicLibrary _loadLibrary() {
    if (Platform.isMacOS) {
      try {
        // Try app bundle first
        return DynamicLibrary.open('libp2p_core.dylib');
      } catch (e) {
        // Try development paths
        try {
          return DynamicLibrary.open('../p2p-core/target/release/libp2p_core.dylib');
        } catch (e) {
          return DynamicLibrary.open('p2p-core/target/release/libp2p_core.dylib');
        }
      }
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libp2p_core.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('p2p_core.dll');
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libp2p_core.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    }
    throw UnsupportedError('Platform not supported');
  }
  
  void _initFunctions() {
    // For now, these are mock implementations
    // Real FFI functions would be loaded like:
    // _initEngine = _lib!.lookupFunction<InitEngineC, InitEngineDart>('init_p2p_engine');
  }
  
  String getVersion() {
    // Mock implementation
    return "1.0.0";
  }
  
  Future<void> startDiscovery(String deviceName, String deviceType) async {
    print('FFI: Starting discovery - $deviceName ($deviceType)');
    // Mock implementation
  }
  
  Future<void> stopDiscovery() async {
    print('FFI: Stopping discovery');
    // Mock implementation
  }
  
  List<Map<String, dynamic>> getPeers() {
    // Mock implementation
    return [];
  }
}
EOF

echo -e "${GREEN}✅ FFI wrapper created${NC}"

echo ""
echo "============================"
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "Library locations:"
echo "  - Rust: p2p-core/$RUST_LIB"
if [ -n "$FLUTTER_PLATFORM_DIR" ]; then
    echo "  - Flutter: ${FLUTTER_PLATFORM_DIR}/${LIBRARY_NAME}.${LIBRARY_EXT}"
fi
echo ""
echo "Next steps:"
echo "  1. Run 'cd app && flutter run' to test the app"
echo "  2. Check console for FFI initialization messages"

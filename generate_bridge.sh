#!/bin/bash

# Generate Flutter Rust Bridge bindings
echo "Generating Flutter Rust Bridge bindings..."

cd "$(dirname "$0")"

# Install flutter_rust_bridge_codegen if not installed
if ! command -v flutter_rust_bridge_codegen &> /dev/null; then
    echo "Installing flutter_rust_bridge_codegen..."
    cargo install flutter_rust_bridge_codegen
fi

# Generate the bridge
flutter_rust_bridge_codegen generate \
    --rust-input crate::api \
    --rust-root p2p-core/ \
    --dart-output app/lib/bridge/ \
    --c-output p2p-core/src/bridge_generated.h \
    --rust-output p2p-core/src/bridge_generated.rs \
    --dart-entrypoint-class-name P2PBridge

echo "Bridge generation complete!"

# Build the Rust library for current platform
echo "Building Rust library..."
cd p2p-core
cargo build --release

# Copy the library to Flutter app
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    cp target/release/libp2p_core.dylib ../app/macos/
    echo "Copied library for macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    cp target/release/libp2p_core.so ../app/linux/
    echo "Copied library for Linux"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    cp target/release/p2p_core.dll ../app/windows/
    echo "Copied library for Windows"
fi

echo "Done!"

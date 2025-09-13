#!/bin/bash

echo "Building Rust library for Android (ARM64)..."

# Set up Android NDK path
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.0.12077973
NDK_BIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin

# Set environment variables for all targets
export PATH=$NDK_BIN:$PATH

# ARM64 (most common for modern devices and emulators)
export CC_aarch64_linux_android=$NDK_BIN/aarch64-linux-android35-clang
export CXX_aarch64_linux_android=$NDK_BIN/aarch64-linux-android35-clang++
export AR_aarch64_linux_android=$NDK_BIN/llvm-ar
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$NDK_BIN/aarch64-linux-android35-clang

# x86_64 (for emulators on Intel Macs)
export CC_x86_64_linux_android=$NDK_BIN/x86_64-linux-android35-clang
export CXX_x86_64_linux_android=$NDK_BIN/x86_64-linux-android35-clang++
export AR_x86_64_linux_android=$NDK_BIN/llvm-ar
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER=$NDK_BIN/x86_64-linux-android35-clang

cd p2p-core

# Build only for ARM64 and x86_64 (covers most devices and emulators)
echo "Building for ARM64 (arm64-v8a)..."
cargo build --target aarch64-linux-android --release 2>&1 | tail -5

echo "Building for x86_64 (for Intel emulators)..."
cargo build --target x86_64-linux-android --release 2>&1 | tail -5

# Create jniLibs directory structure
echo "Creating Android jniLibs directories..."
mkdir -p ../app/android/app/src/main/jniLibs/arm64-v8a
mkdir -p ../app/android/app/src/main/jniLibs/x86_64

# Copy the libraries (from workspace root target directory)
echo "Copying libraries to Android project..."
if [ -f ../target/aarch64-linux-android/release/libp2p_core.so ]; then
    cp ../target/aarch64-linux-android/release/libp2p_core.so ../app/android/app/src/main/jniLibs/arm64-v8a/
    echo "✅ ARM64 library copied"
else
    echo "❌ ARM64 library not found"
fi

if [ -f ../target/x86_64-linux-android/release/libp2p_core.so ]; then
    cp ../target/x86_64-linux-android/release/libp2p_core.so ../app/android/app/src/main/jniLibs/x86_64/
    echo "✅ x86_64 library copied"
else
    echo "❌ x86_64 library not found"
fi

echo ""
echo "Android build complete!"
echo "Libraries in jniLibs:"
ls -la ../app/android/app/src/main/jniLibs/*/libp2p_core.so 2>/dev/null || echo "No libraries found"
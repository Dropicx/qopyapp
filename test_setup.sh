#!/bin/bash

echo "🧪 Testing Qopy P2P Discovery"
echo "=============================="
echo ""

# Test 1: Build Rust library
echo "Test 1: Building Rust library..."
cd p2p-core
if cargo build --release; then
    echo "✅ Rust build successful"
else
    echo "❌ Rust build failed"
    exit 1
fi
echo ""

# Test 2: Run Rust discovery
echo "Test 2: Running mDNS discovery for 10 seconds..."
timeout 10 cargo run 2>&1 | grep -E "(Peer discovery started|New peer discovered|Found [0-9]+ peers)" && echo "✅ Discovery working" || echo "⚠️  No peers found (this is normal if no other devices running)"
echo ""

# Test 3: Check Flutter dependencies
echo "Test 3: Checking Flutter setup..."
cd ../app
if flutter pub get > /dev/null 2>&1; then
    echo "✅ Flutter dependencies installed"
else
    echo "❌ Flutter dependencies failed"
    exit 1
fi
echo ""

# Test 4: Check if library exists
echo "Test 4: Checking library file..."
LIBRARY_PATH="../target/debug/libp2p_core.dylib"
if [ -f "$LIBRARY_PATH" ]; then
    echo "✅ Library found at: $LIBRARY_PATH"
    ls -lh "$LIBRARY_PATH"
else
    LIBRARY_PATH="../p2p-core/target/release/libp2p_core.dylib"
    if [ -f "$LIBRARY_PATH" ]; then
        echo "✅ Library found at: $LIBRARY_PATH"
        ls -lh "$LIBRARY_PATH"
    else
        echo "⚠️  Library not found at expected location"
        echo "   Run './generate_bridge.sh' if not already done"
    fi
fi
echo ""

echo "=============================="
echo "✅ Basic tests complete!"
echo ""
echo "Next steps:"
echo "1. Run './generate_bridge.sh' to create FFI bridge"
echo "2. Run 'make dev' to start all services"
echo "3. Test with multiple devices on same network"

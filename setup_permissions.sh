#!/bin/bash

# Make all scripts executable
chmod +x qopy.sh
chmod +x test_setup.sh
chmod +x test_discovery.sh
chmod +x build_library.sh
chmod +x run.sh
chmod +x generate_bridge.sh

echo "✅ All scripts are now executable!"
echo ""
echo "Quick Start:"
echo "  ./qopy.sh         - Main menu system"
echo "  ./test_discovery.sh - Test mDNS with multiple instances"
echo "  ./build_library.sh  - Build Rust library for Flutter"
echo ""
echo "Try: ./qopy.sh"

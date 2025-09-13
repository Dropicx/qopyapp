#!/bin/bash

clear
echo "╔══════════════════════════════════════════════════════╗"
echo "║          🚀 Qopy P2P File Transfer System 🚀         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Menu
echo -e "${CYAN}What would you like to do?${NC}"
echo ""
echo "  1) 🔨 Build everything"
echo "  2) 🧪 Test mDNS discovery (multiple instances)"
echo "  3) 📱 Run Flutter app"
echo "  4) 🌐 Run signaling server"
echo "  5) 🚀 Run everything (Flutter + Signaling)"
echo "  6) 🔍 Run single discovery instance"
echo "  7) 📊 Show project status"
echo "  8) 🧹 Clean all build artifacts"
echo "  9) ❌ Exit"
echo ""
echo -n "Enter your choice [1-9]: "
read choice

case $choice in
    1)
        echo -e "\n${YELLOW}Building everything...${NC}\n"
        # Build Rust
        echo -e "${BLUE}Building Rust library...${NC}"
        cd p2p-core && cargo build --release
        cd ..
        
        # Build Flutter
        echo -e "${BLUE}Building Flutter app...${NC}"
        cd app && flutter pub get
        cd ..
        
        # Build signaling server
        echo -e "${BLUE}Building signaling server...${NC}"
        cd signaling-server && go mod download
        cd ..
        
        echo -e "\n${GREEN}✅ Build complete!${NC}"
        ;;
        
    2)
        echo -e "\n${YELLOW}Starting multiple discovery instances...${NC}\n"
        chmod +x test_discovery.sh
        ./test_discovery.sh
        ;;
        
    3)
        echo -e "\n${YELLOW}Starting Flutter app...${NC}\n"
        cd app
        flutter run
        ;;
        
    4)
        echo -e "\n${YELLOW}Starting signaling server...${NC}\n"
        cd signaling-server
        go run main.go
        ;;
        
    5)
        echo -e "\n${YELLOW}Starting full system...${NC}\n"
        
        # Start signaling server in background
        echo -e "${BLUE}Starting signaling server...${NC}"
        cd signaling-server
        go run main.go &
        SIGNALING_PID=$!
        cd ..
        
        sleep 2
        
        # Start Flutter app
        echo -e "${BLUE}Starting Flutter app...${NC}"
        cd app
        flutter run
        
        # Cleanup on exit
        echo -e "\n${YELLOW}Stopping services...${NC}"
        kill $SIGNALING_PID 2>/dev/null
        ;;
        
    6)
        echo -e "\n${YELLOW}Starting single discovery instance...${NC}\n"
        cd p2p-core
        cargo run --release
        ;;
        
    7)
        echo -e "\n${CYAN}Project Status:${NC}\n"
        
        # Check Rust
        if [ -f "p2p-core/target/release/libp2p_core.dylib" ] || [ -f "p2p-core/target/release/libp2p_core.so" ]; then
            echo -e "  ${GREEN}✅${NC} Rust library built"
        else
            echo -e "  ${RED}❌${NC} Rust library not built"
        fi
        
        # Check Flutter
        if [ -d "app/.dart_tool" ]; then
            echo -e "  ${GREEN}✅${NC} Flutter dependencies installed"
        else
            echo -e "  ${RED}❌${NC} Flutter dependencies not installed"
        fi
        
        # Check Go
        if [ -f "signaling-server/go.mod" ]; then
            echo -e "  ${GREEN}✅${NC} Signaling server ready"
        else
            echo -e "  ${RED}❌${NC} Signaling server not configured"
        fi
        
        echo ""
        echo -e "${CYAN}Network Information:${NC}"
        if command -v ifconfig &> /dev/null; then
            IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
            echo -e "  Local IP: ${GREEN}$IP${NC}"
        fi
        
        echo ""
        echo -e "${CYAN}Project Structure:${NC}"
        echo "  📁 p2p-core/     - Rust P2P library"
        echo "  📁 app/          - Flutter application"
        echo "  📁 signaling-server/ - WebSocket signaling"
        echo "  📁 examples/     - Usage examples"
        echo "  📁 docs/         - Documentation"
        ;;
        
    8)
        echo -e "\n${YELLOW}Cleaning all build artifacts...${NC}\n"
        cd p2p-core && cargo clean
        cd ../app && flutter clean
        cd ..
        echo -e "${GREEN}✅ Clean complete!${NC}"
        ;;
        
    9)
        echo -e "\n${GREEN}Goodbye! 👋${NC}\n"
        exit 0
        ;;
        
    *)
        echo -e "\n${RED}Invalid choice. Please run the script again.${NC}\n"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}Press Enter to exit...${NC}"
read

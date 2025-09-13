#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Qopy Development Environment${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists cargo; then
    echo -e "${RED}❌ Rust/Cargo not found. Please install Rust first.${NC}"
    exit 1
fi

if ! command_exists flutter; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

if ! command_exists go; then
    echo -e "${RED}❌ Go not found. Please install Go first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites found${NC}"
echo ""

# Start services based on argument
case "$1" in
    rust)
        echo -e "${YELLOW}Starting Rust mDNS discovery...${NC}"
        cd "$(dirname "$0")"
        cargo run
        ;;
    
    flutter)
        echo -e "${YELLOW}Starting Flutter app...${NC}"
        cd "$(dirname "$0")/app"
        flutter pub get
        flutter run
        ;;
    
    signaling)
        echo -e "${YELLOW}Starting signaling server...${NC}"
        cd "$(dirname "$0")/signaling-server"
        go mod download
        go run main.go
        ;;
    
    all)
        echo -e "${YELLOW}Starting all services...${NC}"
        
        # Start signaling server in background
        cd "$(dirname "$0")/signaling-server"
        go mod download
        go run main.go &
        SIGNALING_PID=$!
        echo -e "${GREEN}✅ Signaling server started (PID: $SIGNALING_PID)${NC}"
        
        # Start Rust service in background
        cd "$(dirname "$0")"
        cargo run &
        RUST_PID=$!
        echo -e "${GREEN}✅ Rust mDNS service started (PID: $RUST_PID)${NC}"
        
        # Give services time to start
        sleep 2
        
        # Start Flutter app (foreground)
        cd "$(dirname "$0")/app"
        flutter pub get
        flutter run
        
        # Cleanup on exit
        echo -e "${YELLOW}Stopping services...${NC}"
        kill $SIGNALING_PID 2>/dev/null
        kill $RUST_PID 2>/dev/null
        ;;
    
    test)
        echo -e "${YELLOW}Running tests...${NC}"
        
        # Rust tests
        echo -e "${YELLOW}Running Rust tests...${NC}"
        cd "$(dirname "$0")"
        cargo test
        
        # Flutter tests
        echo -e "${YELLOW}Running Flutter tests...${NC}"
        cd "$(dirname "$0")/app"
        flutter test
        ;;
    
    clean)
        echo -e "${YELLOW}Cleaning build artifacts...${NC}"
        cd "$(dirname "$0")"
        cargo clean
        cd app
        flutter clean
        echo -e "${GREEN}✅ Clean complete${NC}"
        ;;
    
    *)
        echo "Qopy Development Runner"
        echo ""
        echo "Usage: $0 {rust|flutter|signaling|all|test|clean}"
        echo ""
        echo "Commands:"
        echo "  rust      - Run Rust mDNS discovery service"
        echo "  flutter   - Run Flutter app"
        echo "  signaling - Run signaling server"
        echo "  all       - Run all services"
        echo "  test      - Run all tests"
        echo "  clean     - Clean build artifacts"
        exit 1
        ;;
esac

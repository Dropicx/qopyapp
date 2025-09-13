#!/bin/bash

echo "🔍 Testing P2P Discovery with Multiple Instances"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Build first
echo -e "${YELLOW}Building p2p_core...${NC}"
cd p2p-core
cargo build --release 2>/dev/null || cargo build --release
cd ..

# Start multiple instances
echo -e "${YELLOW}Starting 3 discovery instances...${NC}"
echo ""

# Instance 1
echo -e "${BLUE}Instance 1: Desktop Simulator${NC}"
cd p2p-core
RUST_LOG=info cargo run --release -- --name "Desktop-$(hostname)" --type "desktop" &
PID1=$!
cd ..

sleep 2

# Instance 2  
echo -e "${BLUE}Instance 2: Mobile Simulator${NC}"
cd p2p-core
RUST_LOG=info cargo run --release -- --name "Mobile-Simulator" --type "mobile" &
PID2=$!
cd ..

sleep 2

# Instance 3
echo -e "${BLUE}Instance 3: Tablet Simulator${NC}"
cd p2p-core
RUST_LOG=info cargo run --release -- --name "Tablet-Simulator" --type "tablet" &
PID3=$!
cd ..

echo ""
echo -e "${GREEN}All instances started!${NC}"
echo "They should discover each other within 5-10 seconds..."
echo ""
echo "Press Ctrl+C to stop all instances"
echo ""

# Wait for user interrupt
trap "echo ''; echo 'Stopping all instances...'; kill $PID1 $PID2 $PID3 2>/dev/null; exit" INT

# Keep script running
while true; do
    sleep 1
done

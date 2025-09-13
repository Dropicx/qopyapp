.PHONY: all build test run clean bridge

# Default target
all: build

# Build everything
build: build-rust build-flutter

# Build Rust library
build-rust:
	@echo "Building Rust library..."
	cd p2p-core && cargo build --release

# Build Flutter app
build-flutter:
	@echo "Building Flutter app..."
	cd app && flutter pub get && flutter build

# Generate FFI bridge
bridge:
	@echo "Generating Flutter-Rust bridge..."
	chmod +x generate_bridge.sh
	./generate_bridge.sh

# Run tests
test: test-rust test-flutter

test-rust:
	@echo "Running Rust tests..."
	cd p2p-core && cargo test

test-flutter:
	@echo "Running Flutter tests..."
	cd app && flutter test

# Run services
run-rust:
	@echo "Running Rust mDNS discovery..."
	cd p2p-core && cargo run

run-flutter:
	@echo "Running Flutter app..."
	cd app && flutter run

run-signaling:
	@echo "Running signaling server..."
	cd signaling-server && go run main.go

# Development mode - run all services
dev:
	@echo "Starting development environment..."
	make -j3 run-rust run-flutter run-signaling

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cd p2p-core && cargo clean
	cd app && flutter clean
	rm -rf target/

# Platform-specific builds
build-macos:
	@echo "Building for macOS..."
	cd p2p-core && cargo build --release
	cd app && flutter build macos

build-ios:
	@echo "Building for iOS..."
	cd p2p-core && cargo lipo --release
	cd app && flutter build ios

build-android:
	@echo "Building for Android..."
	cd p2p-core && cargo ndk -t armeabi-v7a -t arm64-v8a -o ../app/android/app/src/main/jniLibs build --release
	cd app && flutter build apk

build-windows:
	@echo "Building for Windows..."
	cd p2p-core && cargo build --release --target x86_64-pc-windows-msvc
	cd app && flutter build windows

build-linux:
	@echo "Building for Linux..."
	cd p2p-core && cargo build --release
	cd app && flutter build linux

# Help target
help:
	@echo "Qopy Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  make build       - Build Rust library and Flutter app"
	@echo "  make bridge      - Generate Flutter-Rust FFI bridge"
	@echo "  make test        - Run all tests"
	@echo "  make run-rust    - Run Rust mDNS discovery"
	@echo "  make run-flutter - Run Flutter app"
	@echo "  make dev         - Run all services in development mode"
	@echo "  make clean       - Clean build artifacts"
	@echo ""
	@echo "Platform builds:"
	@echo "  make build-macos   - Build for macOS"
	@echo "  make build-ios     - Build for iOS"
	@echo "  make build-android - Build for Android"
	@echo "  make build-windows - Build for Windows"
	@echo "  make build-linux   - Build for Linux"

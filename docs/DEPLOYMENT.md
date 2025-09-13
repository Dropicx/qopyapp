# Deployment Guide

This guide covers deploying QopyApp to various platforms and environments.

## 📋 Table of Contents

- [Overview](#overview)
- [Mobile Deployment](#mobile-deployment)
- [Desktop Deployment](#desktop-deployment)
- [Server Deployment](#server-deployment)
- [Docker Deployment](#docker-deployment)
- [Cloud Deployment](#cloud-deployment)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## 🌟 Overview

QopyApp consists of three main components:

1. **Flutter App**: Cross-platform mobile and desktop application
2. **P2P Core (Rust)**: mDNS discovery and file transfer engine
3. **Signaling Server (Go)**: WebSocket signaling for WebRTC connections

## 📱 Mobile Deployment

### Android

#### 1. Prepare for Release

```bash
cd app
flutter build apk --release
```

#### 2. Generate App Bundle (Recommended)

```bash
flutter build appbundle --release
```

#### 3. Sign the App

Create a keystore file:

```bash
keytool -genkey -v -keystore ~/qopyapp-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias qopyapp
```

Configure signing in `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 4. Upload to Google Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app
3. Upload the AAB file
4. Fill in store listing details
5. Submit for review

### iOS

#### 1. Prepare for Release

```bash
cd app
flutter build ios --release
```

#### 2. Open in Xcode

```bash
open ios/Runner.xcworkspace
```

#### 3. Configure Signing

1. Select your team in Xcode
2. Set bundle identifier
3. Configure provisioning profiles

#### 4. Archive and Upload

1. Select "Any iOS Device" as target
2. Product → Archive
3. Distribute App → App Store Connect
4. Upload to App Store

#### 5. Submit for Review

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Create new version
4. Submit for review

## 🖥️ Desktop Deployment

### macOS

#### 1. Build for macOS

```bash
cd app
flutter build macos --release
```

#### 2. Create DMG

```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
  --volname "QopyApp" \
  --volicon "assets/icon.icns" \
  --window-pos 200 120 \
  --window-size 600 300 \
  --icon-size 100 \
  --icon "QopyApp.app" 175 120 \
  --hide-extension "QopyApp.app" \
  --app-drop-link 425 120 \
  "QopyApp.dmg" \
  "build/macos/Build/Products/Release/"
```

#### 3. Notarize for Distribution

```bash
# Create notarization request
xcrun altool --notarize-app \
  --primary-bundle-id "com.qopyapp.app" \
  --username "your-email@example.com" \
  --password "@keychain:AC_PASSWORD" \
  --file "QopyApp.dmg"

# Staple notarization
xcrun stapler staple "QopyApp.dmg"
```

### Windows

#### 1. Build for Windows

```bash
cd app
flutter build windows --release
```

#### 2. Create Installer

Using NSIS:

```nsis
!define APPNAME "QopyApp"
!define COMPANYNAME "QopyApp"
!define DESCRIPTION "P2P File Transfer Application"
!define VERSIONMAJOR 1
!define VERSIONMINOR 0
!define VERSIONBUILD 0

!include "MUI2.nsh"

Name "${APPNAME}"
OutFile "QopyAppInstaller.exe"
InstallDir "$PROGRAMFILES\${APPNAME}"

Section "install"
    SetOutPath $INSTDIR
    File /r "build\windows\runner\Release\*"
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "uninstall"
    Delete "$INSTDIR\uninstall.exe"
    RMDir /r "$INSTDIR"
SectionEnd
```

### Linux

#### 1. Build for Linux

```bash
cd app
flutter build linux --release
```

#### 2. Create AppImage

```bash
# Install appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Create AppImage
./appimagetool-x86_64.AppImage build/linux/x64/release/bundle/ QopyApp.AppImage
```

#### 3. Create DEB Package

```bash
# Install fpm
gem install fpm

# Create DEB package
fpm -s dir -t deb -n qopyapp -v 1.0.0 \
  --description "P2P File Transfer Application" \
  --depends "libgtk-3-0" \
  --depends "libxss1" \
  --depends "libgconf-2-4" \
  -C build/linux/x64/release/bundle/ \
  --prefix /opt/qopyapp \
  .
```

## 🖥️ Server Deployment

### P2P Core (Rust)

#### 1. Build Release Binary

```bash
cd p2p-core
cargo build --release
```

#### 2. Create Systemd Service

```ini
# /etc/systemd/system/qopyapp-p2p.service
[Unit]
Description=QopyApp P2P Core
After=network.target

[Service]
Type=simple
User=qopyapp
WorkingDirectory=/opt/qopyapp
ExecStart=/opt/qopyapp/p2p-core
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

#### 3. Install and Start

```bash
# Copy binary
sudo cp target/release/p2p-core /opt/qopyapp/
sudo chmod +x /opt/qopyapp/p2p-core

# Create user
sudo useradd -r -s /bin/false qopyapp

# Enable and start service
sudo systemctl enable qopyapp-p2p
sudo systemctl start qopyapp-p2p
```

### Signaling Server (Go)

#### 1. Build Release Binary

```bash
cd signaling-server
go build -o signaling-server main.go
```

#### 2. Create Systemd Service

```ini
# /etc/systemd/system/qopyapp-signaling.service
[Unit]
Description=QopyApp Signaling Server
After=network.target

[Service]
Type=simple
User=qopyapp
WorkingDirectory=/opt/qopyapp
ExecStart=/opt/qopyapp/signaling-server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

#### 3. Install and Start

```bash
# Copy binary
sudo cp signaling-server /opt/qopyapp/
sudo chmod +x /opt/qopyapp/signaling-server

# Enable and start service
sudo systemctl enable qopyapp-signaling
sudo systemctl start qopyapp-signaling
```

## 🐳 Docker Deployment

### Create Dockerfile

#### P2P Core

```dockerfile
# Dockerfile.p2p
FROM rust:1.70 as builder

WORKDIR /app
COPY p2p-core/ .
RUN cargo build --release

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/p2p-core /usr/local/bin/
EXPOSE 8080

CMD ["p2p-core"]
```

#### Signaling Server

```dockerfile
# Dockerfile.signaling
FROM golang:1.21 as builder

WORKDIR /app
COPY signaling-server/ .
RUN go build -o signaling-server main.go

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/signaling-server /usr/local/bin/
EXPOSE 8080

CMD ["signaling-server"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  signaling:
    build:
      context: .
      dockerfile: Dockerfile.signaling
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
    restart: unless-stopped

  p2p-core:
    build:
      context: .
      dockerfile: Dockerfile.p2p
    ports:
      - "8081:8081"
    environment:
      - PORT=8081
    restart: unless-stopped
    depends_on:
      - signaling
```

### Deploy with Docker

```bash
# Build and start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## ☁️ Cloud Deployment

### AWS

#### 1. Deploy with ECS

```yaml
# task-definition.json
{
  "family": "qopyapp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "signaling",
      "image": "qopyapp/signaling:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/qopyapp",
          "awslogs-region": "us-west-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

#### 2. Deploy with Lambda

```yaml
# serverless.yml
service: qopyapp

provider:
  name: aws
  runtime: go1.x
  region: us-west-2

functions:
  signaling:
    handler: signaling-server
    events:
      - http:
          path: /ws
          method: GET
```

### Google Cloud

#### 1. Deploy with Cloud Run

```yaml
# cloudbuild.yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/qopyapp-signaling', './signaling-server']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/qopyapp-signaling']
  - name: 'gcr.io/cloud-builders/gcloud'
    args: ['run', 'deploy', 'qopyapp-signaling', '--image', 'gcr.io/$PROJECT_ID/qopyapp-signaling', '--platform', 'managed', '--region', 'us-central1']
```

#### 2. Deploy with App Engine

```yaml
# app.yaml
runtime: go
env: standard

handlers:
  - url: /.*
    script: auto
    secure: always
```

### Azure

#### 1. Deploy with Container Instances

```yaml
# azure-deploy.yml
apiVersion: 2018-10-01
location: eastus
name: qopyapp
properties:
  containers:
  - name: signaling
    properties:
      image: qopyapp/signaling:latest
      ports:
      - port: 8080
      resources:
        requests:
          cpu: 0.5
          memoryInGb: 1
  osType: Linux
  ipAddress:
    type: Public
    ports:
    - protocol: tcp
      port: 8080
```

## 📊 Monitoring

### Health Checks

#### P2P Core Health Check

```rust
// health_check.rs
use axum::{response::Json, routing::get, Router};
use serde_json::{json, Value};

async fn health_check() -> Json<Value> {
    Json(json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now(),
        "version": env!("CARGO_PKG_VERSION")
    }))
}

pub fn create_router() -> Router {
    Router::new()
        .route("/health", get(health_check))
}
```

#### Signaling Server Health Check

```go
// health.go
package main

import (
    "encoding/json"
    "net/http"
    "time"
)

type HealthResponse struct {
    Status    string    `json:"status"`
    Timestamp time.Time `json:"timestamp"`
    Version   string    `json:"version"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    response := HealthResponse{
        Status:    "healthy",
        Timestamp: time.Now(),
        Version:   "1.0.0",
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
```

### Logging

#### Structured Logging

```rust
// logging.rs
use tracing::{info, error, warn};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

pub fn init_logging() {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "qopyapp=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();
}
```

#### Log Aggregation

```yaml
# fluentd.conf
<source>
  @type tail
  path /var/log/qopyapp/*.log
  pos_file /var/log/fluentd/qopyapp.log.pos
  tag qopyapp.*
  format json
</source>

<match qopyapp.**>
  @type elasticsearch
  host elasticsearch
  port 9200
  index_name qopyapp
  type_name _doc
</match>
```

### Metrics

#### Prometheus Metrics

```rust
// metrics.rs
use prometheus::{Counter, Histogram, Registry};

lazy_static! {
    static ref PEERS_DISCOVERED: Counter = Counter::new(
        "peers_discovered_total",
        "Total number of peers discovered"
    ).unwrap();
    
    static ref FILE_TRANSFER_DURATION: Histogram = Histogram::new(
        "file_transfer_duration_seconds",
        "Duration of file transfers"
    ).unwrap();
}

pub fn register_metrics(registry: &Registry) {
    registry.register(Box::new(PEERS_DISCOVERED.clone())).unwrap();
    registry.register(Box::new(FILE_TRANSFER_DURATION.clone())).unwrap();
}
```

## 🚨 Troubleshooting

### Common Issues

#### Service Won't Start

**Check logs:**
```bash
# Systemd services
sudo journalctl -u qopyapp-p2p -f
sudo journalctl -u qopyapp-signaling -f

# Docker services
docker-compose logs -f
```

**Check configuration:**
```bash
# Verify configuration files
sudo systemctl status qopyapp-p2p
sudo systemctl status qopyapp-signaling
```

#### Port Conflicts

**Check port usage:**
```bash
# Check what's using the port
sudo netstat -tlnp | grep :8080
sudo lsof -i :8080
```

**Change ports:**
```bash
# Update configuration
sudo systemctl edit qopyapp-signaling
# Add:
# [Service]
# Environment="PORT=8081"
```

#### Memory Issues

**Check memory usage:**
```bash
# Check system memory
free -h
htop

# Check service memory
sudo systemctl status qopyapp-p2p
sudo systemctl status qopyapp-signaling
```

**Optimize memory:**
```bash
# Reduce memory usage
sudo systemctl edit qopyapp-p2p
# Add:
# [Service]
# Environment="RUST_LOG=warn"
# Environment="MAX_PEERS=50"
```

### Performance Issues

#### Slow File Transfers

**Check network:**
```bash
# Test network speed
iperf3 -s  # On one device
iperf3 -c <server_ip>  # On another device
```

**Optimize settings:**
```bash
# Increase chunk size
sudo systemctl edit qopyapp-p2p
# Add:
# [Service]
# Environment="CHUNK_SIZE=65536"
```

#### High CPU Usage

**Check processes:**
```bash
# Check CPU usage
top
htop

# Check specific process
ps aux | grep qopyapp
```

**Optimize configuration:**
```bash
# Reduce discovery frequency
sudo systemctl edit qopyapp-p2p
# Add:
# [Service]
# Environment="DISCOVERY_INTERVAL=60"
```

### Security Issues

#### Firewall Configuration

**Check firewall:**
```bash
# Check firewall status
sudo ufw status
sudo firewall-cmd --list-all
```

**Configure firewall:**
```bash
# UFW
sudo ufw allow 8080/tcp
sudo ufw allow 8081/tcp

# Firewalld
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload
```

#### SSL/TLS Issues

**Check certificates:**
```bash
# Check certificate validity
openssl x509 -in certificate.crt -text -noout

# Test SSL connection
openssl s_client -connect example.com:443
```

**Update certificates:**
```bash
# Renew Let's Encrypt certificate
sudo certbot renew
sudo systemctl reload nginx
```

## 📞 Support

### Getting Help

1. **Check Logs**: Look for error messages in logs
2. **Search Issues**: Check GitHub issues for similar problems
3. **Ask Community**: Post in Discord or GitHub Discussions
4. **Contact Support**: Email support@qopyapp.com

### Reporting Issues

When reporting issues, include:

- Operating system and version
- QopyApp version
- Error messages from logs
- Steps to reproduce
- Expected vs actual behavior

### Emergency Contacts

- **Security Issues**: security@qopyapp.com
- **Critical Bugs**: critical@qopyapp.com
- **General Support**: support@qopyapp.com

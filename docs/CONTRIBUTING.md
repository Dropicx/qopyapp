# Contributing to QopyApp

Thank you for your interest in contributing to QopyApp! This guide will help you get started with contributing to our project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Release Process](#release-process)

## 🤝 Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

### Our Pledge

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what's best for the community
- Show empathy towards other community members

## 🚀 Getting Started

### Prerequisites

Before contributing, make sure you have:

- **Git** installed and configured
- **Flutter SDK** (3.9.0+)
- **Rust** (1.70+)
- **Go** (1.21+)
- A **GitHub account**
- Basic knowledge of the technologies used

### Fork and Clone

1. **Fork the repository**
   - Go to [QopyApp on GitHub](https://github.com/yourusername/qopyapp)
   - Click the "Fork" button in the top-right corner

2. **Clone your fork**
   ```bash
   git clone https://github.com/yourusername/qopyapp.git
   cd qopyapp
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/original/qopyapp.git
   ```

### Development Setup

1. **Install dependencies**
   ```bash
   # Flutter dependencies
   cd app
   flutter pub get
   
   # Rust dependencies
   cd ../p2p-core
   cargo build
   
   # Go dependencies
   cd ../signaling-server
   go mod tidy
   ```

2. **Run tests**
   ```bash
   # Flutter tests
   cd app
   flutter test
   
   # Rust tests
   cd ../p2p-core
   cargo test
   
   # Go tests
   cd ../signaling-server
   go test ./...
   ```

## 🔄 Development Process

### 1. Choose an Issue

- Look for issues labeled `good first issue` for beginners
- Check `help wanted` for more complex tasks
- Create a new issue if you have an idea

### 2. Create a Branch

```bash
# Create and switch to a new branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b bugfix/issue-number
```

### 3. Make Changes

- Write your code following our [coding standards](#coding-standards)
- Add tests for new functionality
- Update documentation as needed

### 4. Test Your Changes

```bash
# Run all tests
make test

# Or run individually
flutter test
cargo test
go test ./...
```

### 5. Commit Your Changes

```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "feat(discovery): add mDNS peer discovery"
```

### 6. Push and Create PR

```bash
# Push your branch
git push origin feature/your-feature-name

# Create a pull request on GitHub
```

## 📝 Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] No breaking changes (or properly documented)
- [ ] Performance impact is considered
- [ ] Security implications are reviewed

### PR Template

When creating a pull request, please include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs tests
2. **Code Review**: Maintainers review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, your PR will be merged

## 📏 Coding Standards

### Rust

#### Code Style

```bash
# Format code
cargo fmt

# Lint code
cargo clippy -- -D warnings
```

#### Naming Conventions

```rust
// Functions and variables: snake_case
fn discover_peers() -> Vec<Peer> {
    let peer_list = Vec::new();
    peer_list
}

// Types and traits: PascalCase
struct PeerDiscovery {
    config: DiscoveryConfig,
}

// Constants: SCREAMING_SNAKE_CASE
const MAX_PEERS: usize = 100;
```

#### Documentation

```rust
/// Discovers peers on the local network using mDNS.
///
/// # Arguments
///
/// * `timeout` - Optional timeout for discovery
///
/// # Returns
///
/// * `Result<Vec<Peer>, PeerDiscoveryError>` - List of discovered peers
///
/// # Examples
///
/// ```
/// let peers = discovery.discover_peers(Some(Duration::from_secs(10))).await?;
/// ```
pub async fn discover_peers(
    &self,
    timeout: Option<Duration>
) -> Result<Vec<Peer>, PeerDiscoveryError> {
    // Implementation
}
```

### Go

#### Code Style

```bash
# Format code
gofmt -w .

# Lint code
golint ./...
```

#### Naming Conventions

```go
// Exported functions: PascalCase
func HandleWebSocket(w http.ResponseWriter, r *http.Request) {
    // Implementation
}

// Unexported functions: camelCase
func handleMessage(msg Message) error {
    // Implementation
}

// Constants: PascalCase
const MaxConnections = 100
```

### Dart/Flutter

#### Code Style

```bash
# Format code
dart format .

# Analyze code
dart analyze
```

#### Naming Conventions

```dart
// Classes: PascalCase
class PeerDiscovery {
  // Fields: camelCase
  final String serviceName;
  final int port;
  
  // Methods: camelCase
  Future<void> start() async {
    // Implementation
  }
}

// Constants: camelCase
const int maxPeers = 100;
```

## 🧪 Testing Guidelines

### Test Coverage

We aim for high test coverage:

- **Unit Tests**: Test individual functions and methods
- **Integration Tests**: Test component interactions
- **Widget Tests**: Test Flutter UI components
- **End-to-End Tests**: Test complete user workflows

### Writing Tests

#### Rust Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use tokio_test;

    #[tokio::test]
    async fn test_peer_discovery_creation() {
        let config = DiscoveryConfig::default();
        let discovery = PeerDiscovery::new(config);
        assert!(discovery.is_ok());
    }

    #[tokio::test]
    async fn test_peer_discovery_start_stop() {
        let config = DiscoveryConfig::default();
        let discovery = PeerDiscovery::new(config).unwrap();
        
        assert!(discovery.start().await.is_ok());
        assert!(discovery.stop().await.is_ok());
    }
}
```

#### Go Tests

```go
func TestHandleWebSocket(t *testing.T) {
    // Test implementation
}

func TestRoomManagement(t *testing.T) {
    // Test implementation
}
```

#### Flutter Tests

```dart
// test/peer_discovery_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_core/p2p_core.dart';

void main() {
  group('PeerDiscovery', () {
    test('should create instance with default config', () {
      final config = DiscoveryConfig();
      final discovery = PeerDiscovery(config);
      expect(discovery, isNotNull);
    });
  });
}
```

### Running Tests

```bash
# Run all tests
make test

# Run specific test suites
flutter test
cargo test
go test ./...

# Run with coverage
flutter test --coverage
cargo tarpaulin
go test -cover ./...
```

## 📚 Documentation

### Code Documentation

- **Functions**: Document parameters, return values, and examples
- **Classes**: Document purpose and usage
- **Complex Logic**: Add inline comments explaining the reasoning

### API Documentation

- **Public APIs**: Must be documented
- **Examples**: Include usage examples
- **Error Cases**: Document possible errors and how to handle them

### User Documentation

- **README**: Keep up to date with setup instructions
- **Getting Started**: Guide for new users
- **API Reference**: Complete API documentation
- **Troubleshooting**: Common issues and solutions

### Documentation Standards

```rust
/// Discovers peers on the local network using mDNS.
///
/// This function searches for other QopyApp instances on the same
/// network using multicast DNS (mDNS) protocol.
///
/// # Arguments
///
/// * `timeout` - Optional timeout for discovery. If None, uses default timeout.
///
/// # Returns
///
/// * `Result<Vec<Peer>, PeerDiscoveryError>` - List of discovered peers or error
///
/// # Examples
///
/// ```
/// use std::time::Duration;
/// 
/// let peers = discovery.discover_peers(Some(Duration::from_secs(10))).await?;
/// for peer in peers {
///     println!("Found peer: {}", peer.name);
/// }
/// ```
///
/// # Errors
///
/// This function will return an error if:
/// - mDNS service is not available
/// - Network interface is not accessible
/// - Discovery timeout is reached
pub async fn discover_peers(
    &self,
    timeout: Option<Duration>
) -> Result<Vec<Peer>, PeerDiscoveryError> {
    // Implementation
}
```

## 🚀 Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Release Steps

1. **Update Version Numbers**
   ```bash
   # Update Cargo.toml
   # Update pubspec.yaml
   # Update go.mod
   ```

2. **Update CHANGELOG.md**
   ```markdown
   ## [1.2.0] - 2024-01-15
   
   ### Added
   - New peer discovery algorithm
   - File transfer progress indicators
   
   ### Changed
   - Improved error handling
   - Updated UI design
   
   ### Fixed
   - Memory leak in file transfer
   - Connection timeout issues
   ```

3. **Create Release Branch**
   ```bash
   git checkout -b release/v1.2.0
   git push origin release/v1.2.0
   ```

4. **Run Full Test Suite**
   ```bash
   make test
   make lint
   make security-scan
   ```

5. **Create Release Tag**
   ```bash
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin v1.2.0
   ```

6. **Deploy to Production**
   - Update staging environment
   - Run integration tests
   - Deploy to production
   - Monitor for issues

7. **Announce Release**
   - Update GitHub releases
   - Post on social media
   - Send email to users
   - Update documentation

## 🏷️ Issue Labels

We use labels to categorize issues:

- **bug**: Something isn't working
- **enhancement**: New feature or request
- **documentation**: Improvements or additions to documentation
- **good first issue**: Good for newcomers
- **help wanted**: Extra attention is needed
- **priority:high**: High priority
- **priority:low**: Low priority
- **priority:medium**: Medium priority
- **question**: Further information is requested
- **wontfix**: This will not be worked on

## 💬 Communication

### GitHub Discussions

- **General**: General questions and discussions
- **Ideas**: Feature requests and ideas
- **Q&A**: Questions and answers
- **Show and Tell**: Share your work

### Discord

- **#general**: General chat
- **#development**: Development discussions
- **#help**: Get help with issues
- **#showcase**: Show off your contributions

### Email

- **Security**: security@qopyapp.com
- **General**: contact@qopyapp.com
- **Support**: support@qopyapp.com

## 🎯 Contribution Ideas

### For Beginners

- Fix typos in documentation
- Add unit tests for existing code
- Improve error messages
- Add examples to documentation
- Fix minor bugs

### For Intermediate Developers

- Implement new features
- Optimize performance
- Add integration tests
- Improve UI/UX
- Add new file type support

### For Advanced Developers

- Design new architectures
- Implement security features
- Optimize algorithms
- Add cross-platform support
- Mentor other contributors

## 🏆 Recognition

### Contributors

We recognize contributors in several ways:

- **Contributors List**: Listed in README.md
- **Release Notes**: Mentioned in release notes
- **Hall of Fame**: Featured on our website
- **Swag**: QopyApp merchandise for significant contributions

### Maintainers

Maintainers are contributors who:

- Have made significant contributions
- Help review pull requests
- Guide new contributors
- Make architectural decisions

## 📞 Getting Help

If you need help contributing:

1. **Check Documentation**: Read through our docs
2. **Search Issues**: Look for similar issues
3. **Ask Questions**: Use GitHub Discussions or Discord
4. **Contact Maintainers**: Reach out directly

## 🎉 Thank You!

Thank you for contributing to QopyApp! Your contributions help make the project better for everyone.

Remember:
- Every contribution matters, no matter how small
- We're here to help you succeed
- Don't be afraid to ask questions
- Have fun and learn something new!

Happy coding! 🚀

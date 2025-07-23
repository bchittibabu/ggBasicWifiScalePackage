# Changelog
All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-07-23
### Added
- Initial release of **ggWifiScalePackage**.
- Support for multiple WiFi configuration protocols:
  - ESPTouch protocol for ESP32-based smart scales
  - SmartConfig protocol for ESP8266/ESP32 devices
  - AP Mode for devices that create their own WiFi network
- Modern async/await API for seamless integration with SwiftUI and UIKit apps.
- Comprehensive error handling with typed error enum (`WifiScaleError`).
- Configurable timeout management for each connection mode.
- Binary framework integration with ESPTouch and SmartConfig libraries.
- Support for user authentication tokens and user number configuration.
- Hex string decoding utilities for token data processing.
- TCP socket delegate integration for connection status monitoring.
- Swift Package Manager support with iOS 16.0+ platform requirement.

### Changed
- Removed singleton pattern from `BasicWifiScale` - now allows direct instantiation for better flexibility and testability.

### Features
- **WifiScaleConfig**: Structured configuration object for WiFi credentials and device settings.
- **WifiScaleMode**: Enumeration of supported connection protocols.
- **BasicWifiScale**: Main class providing singleton access to WiFi scale operations.
- **GGEsptouchDelegate**: Protocol implementation for ESPTouch callbacks.
- **GCDAsyncSocketDelegate**: Protocol implementation for TCP connection monitoring.
- **Timeout Management**: Automatic cleanup and error handling for connection timeouts.
- **State Management**: Proper lifecycle management for ongoing operations.
- **Logging Integration**: Built-in logging for debugging and monitoring connection attempts.

### Technical Details
- Built with Swift 6.1 and requires iOS 16.0+
- Integrates with `ggEsptouchFramework.xcframework` and `smartConfig.xcframework`
- Uses Apple's unified logging system (`os.Logger`) for debugging
- Implements proper memory management with weak references and cleanup methods
- Supports concurrent operations with thread-safe design patterns 

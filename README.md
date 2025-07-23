# ggWifiScalePackage

A Swift package that enables WiFi configuration for smart scales using multiple connection protocols including ESPTouch, SmartConfig, and AP Mode. Provides an easy-to-use async/await API for modern Swift applications.

---

## Requirements

- iOS 16.0+ / iPadOS 16.0+
- Swift 6.1+
- Xcode 15.0+

> **Note**: WiFi access permissions must be enabled in your application's *Info.plist* (`NSLocalNetworkUsageDescription` and `NSLocationWhenInUseUsageDescription` for WiFi scanning).

---

## Installation

### Swift Package Manager

Add the package in **Package.swift**:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/ggWifiScalePackage.git", from: "1.0.0")
]
```

Or in Xcode:

1. File → Add Packages…
2. Enter the repository URL: `https://github.com/your-org/ggWifiScalePackage.git`
3. Select the version you want to use

---

## Usage

### 1. Configure WiFi Scale Connection

Create a `WifiScaleConfig` with your network details:

```swift
import ggWifiScalePackage

let config = WifiScaleConfig(
    ssid: "YourWiFiNetwork",
    bssid: "AA:BB:CC:DD:EE:FF", // Optional: WiFi BSSID
    password: "YourWiFiPassword",
    token: "YourDeviceToken",   // Optional: Device authentication token
    userNumber: 1               // User identifier
)
```

### 2. Connect Using Different Modes

Choose from three connection modes based on your scale's capabilities:

#### ESPTouch Mode
```swift
let wifiScale = BasicWifiScale()

do {
    try await wifiScale.connect(
        config: config,
        mode: .esptouch,
        timeout: 60.0
    )
    print("Scale connected successfully via ESPTouch!")
} catch {
    print("Connection failed: \(error)")
}
```

#### SmartConfig Mode
```swift
let wifiScale = BasicWifiScale()

do {
    try await wifiScale.connect(
        config: config,
        mode: .smartConfig,
        timeout: 120.0
    )
    print("Scale connected successfully via SmartConfig!")
} catch {
    print("Connection failed: \(error)")
}
```

#### AP Mode
```swift
let wifiScale = BasicWifiScale()

do {
    try await wifiScale.connect(
        config: config,
        mode: .apMode,
        timeout: 90.0
    )
    print("Scale connected successfully via AP Mode!")
} catch {
    print("Connection failed: \(error)")
}
```

### 3. Handle Connection Errors

The package provides detailed error handling:

```swift
let wifiScale = BasicWifiScale()

do {
    try await wifiScale.connect(config: config, mode: .esptouch)
} catch WifiScaleError.timeout {
    print("Connection timed out - please try again")
} catch WifiScaleError.invalidConfiguration {
    print("Invalid WiFi configuration provided")
} catch WifiScaleError.operationFailed(let code, let message) {
    print("Operation failed with code \(code): \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

### 4. Cancel Ongoing Operations

```swift
// Cancel any ongoing connection attempts
wifiScale.cancel()
```

---

## Features

- **Multiple Connection Protocols**: Support for ESPTouch, SmartConfig, and AP Mode
- **Async/Await API**: Modern Swift concurrency for responsive UI
- **Comprehensive Error Handling**: Detailed error types and messages
- **Timeout Management**: Configurable timeouts for each connection mode
- **Thread-Safe Operations**: Proper queue management and state handling
- **Binary Framework Integration**: Seamless integration with ESPTouch and SmartConfig frameworks
- **Logging Support**: Built-in logging for debugging and monitoring

---

## Connection Modes

### ESPTouch
- **Use Case**: Most common for ESP32-based scales
- **Process**: Device broadcasts WiFi credentials via UDP packets
- **Timeout**: Recommended 60-120 seconds

### SmartConfig
- **Use Case**: Alternative protocol for ESP8266/ESP32 devices
- **Process**: Uses UDP broadcast with specific packet format
- **Timeout**: Recommended 90-180 seconds

### AP Mode
- **Use Case**: When device creates its own WiFi network
- **Process**: App connects to device's AP, then configures device
- **Timeout**: Recommended 60-120 seconds

---

## Error Types

- `WifiScaleError.helperUnavailable`: Framework helper not available
- `WifiScaleError.operationFailed`: Operation failed with specific error code
- `WifiScaleError.timeout`: Connection attempt timed out
- `WifiScaleError.cancelled`: Operation was cancelled by user
- `WifiScaleError.invalidConfiguration`: Invalid WiFi configuration provided

---

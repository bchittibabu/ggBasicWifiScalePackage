import Foundation
import ggEsptouchFramework
import smartConfig
import SystemConfiguration.CaptiveNetwork
import os

extension String {
    func hexDecodedData() -> Data? {
        let hexString = self.replacingOccurrences(of: " ", with: "")
        var data = Data()

        var index = hexString.startIndex
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2, limitedBy: hexString.endIndex) ?? hexString.endIndex
            let byteString = String(hexString[index..<nextIndex])

            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return nil
            }

            index = nextIndex
        }

        return data
    }
}

public struct WifiScaleConfig : Sendable{
    public let ssid: String
    public let bssid: String
    public let password: String
    public let token: String
    public let userNumber: Int
    public init(ssid: String, bssid: String, password: String, token: String, userNumber: Int) {
        self.ssid = ssid
        self.bssid = bssid
        self.password = password
        self.token = token
        self.userNumber = userNumber
    }
}

public enum WifiScaleMode {
    case esptouch
    case smartConfig
    case apMode
}

public enum WifiScaleError: Error, LocalizedError {
    case helperUnavailable
    case operationFailed(code: Int, message: String)
    case timeout
    case cancelled
    case invalidConfiguration

    public var errorDescription: String? {
        switch self {
        case .helperUnavailable:
            return "WiFi scale helper is unavailable"
        case .operationFailed(let code, let message):
            return "Operation failed with code \(code): \(message)"
        case .timeout:
            return "Operation timed out"
        case .cancelled:
            return "Operation was cancelled"
        case .invalidConfiguration:
            return "Invalid configuration provided"
        }
    }
}

public class BasicWifiScale: NSObject, GGEsptouchDelegate, GCDAsyncSocketDelegate {
    @MainActor public static let shared = BasicWifiScale()

    // Logger
    private let logger = Logger(subsystem: "com.ggBasicWifiScalePackage", category: "BasicWifiScale")

    // Configuration
    private let defaultTimeout: TimeInterval = 120.0 // 120 seconds timeout

    // State management
    private var esptouchContinuation: CheckedContinuation<Void, Error>? = nil
    private var smartConfigContinuation: CheckedContinuation<Void, Error>? = nil
    private var apModeContinuation: CheckedContinuation<Void, Error>? = nil
    private var smartConfigInstance: smartConfig?
    private var configByAPInstance: ConfigByAP?

    // Timeout management
    private var timeoutTasks: [DispatchWorkItem] = []

    private override init() {
        super.init()
    }

    deinit {
        cleanup()
    }

    // MARK: - Public API

    /// Connect to WiFi scale using the specified configuration and mode
    /// - Parameters:
    ///   - config: WiFi configuration including SSID, password, token, etc.
    ///   - mode: Connection mode (esptouch, smartConfig, or apMode)
    ///   - timeout: Optional timeout in seconds (default: 60 seconds)
    /// - Throws: WifiScaleError for various failure scenarios
    public func connect(config: WifiScaleConfig, mode: WifiScaleMode, timeout: TimeInterval? = nil) async throws {
        // Validate configuration
        guard !config.ssid.isEmpty, !config.password.isEmpty else {
            throw WifiScaleError.invalidConfiguration
        }

        let timeoutValue = timeout ?? defaultTimeout

        switch mode {
        case .esptouch:
            try await startEsptouch(config: config, timeout: timeoutValue)
        case .smartConfig:
            try await startSmartConfig(config: config, timeout: timeoutValue)
        case .apMode:
            try await startAPMode(config: config, timeout: timeoutValue)
        }
    }

    /// Cancel any ongoing connection attempts
    public func cancel() {
        logger.info("Cancelling smartConfig operations")
        smartConfigInstance?.stop()
        cleanup()
    }

    // MARK: - Private Helpers

    private func startEsptouch(config: WifiScaleConfig, timeout: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let helper = GGEsptouchHelper.getInstance() else {
                continuation.resume(throwing: WifiScaleError.helperUnavailable)
                return
            }

            let scaleData = GGScaleData()
            scaleData.ssid = config.ssid
            scaleData.bssid = config.bssid
            scaleData.userToken = config.token
            scaleData.password = config.password
            scaleData.userNumber = String(format: "0%d", config.userNumber)

            // Store continuation for delegate callbacks
            self.esptouchContinuation = continuation

            // Setup timeout
            let timeoutTask = DispatchWorkItem { [weak self] in
                self?.handleTimeout(for: .esptouch)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutTask)
            self.timeoutTasks.append(timeoutTask)

            let started = helper.beginSmartConnect(scaleData, delegate: self)
            if !started {
                self.cleanupEsptouch()
                continuation.resume(throwing: WifiScaleError.operationFailed(code: 0, message: "Failed to start Esptouch task"))
            }
            self.logger.info("Esptouch started")
        }
    }

    private func startSmartConfig(config: WifiScaleConfig, timeout: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                self.smartConfigInstance = smartConfig()
                self.smartConfigContinuation = continuation

                let userNumberByte: UInt8 = UInt8(config.userNumber)
                let tokenData: Data? = config.token.isEmpty ? nil : config.token.hexDecodedData()

                // Setup timeout
                let timeoutTask = DispatchWorkItem { [weak self] in
                    self?.handleTimeout(for: .smartConfig)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutTask)
                self.timeoutTasks.append(timeoutTask)

                let result = self.smartConfigInstance!.startSetSSID(config.ssid, andSetPassWord: config.password, andNumber: userNumberByte, andTokenData: tokenData)

                if result != 0 {
                    self.cancel()
                    continuation.resume(throwing: WifiScaleError.operationFailed(code: Int(result), message: "smartConfig error code: \(result)"))
                }
                self.logger.info("smartConfig started")
                // Don't resume here - wait for TCP connection success
            }
        }
    }

    private func startAPMode(config: WifiScaleConfig, timeout: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                self.configByAPInstance = ConfigByAP()
                self.apModeContinuation = continuation

                let userNumberValue = config.userNumber
                let userNumberByte: UInt8 = UInt8(userNumberValue)
                                let tokenString = config.token
                let tokenData: Data? = tokenString.isEmpty ? nil : tokenString.hexDecodedData()

                self.logger.info("AP Mode - SSID: \(config.ssid)")
                self.logger.info("AP Mode - User Number: \(userNumberValue)")
                self.logger.info("AP Mode - Token: \(tokenString)")

                // Setup timeout
                let timeoutTask = DispatchWorkItem { [weak self] in
                    self?.handleTimeout(for: .apMode)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutTask)
                self.timeoutTasks.append(timeoutTask)

                // Start AP mode configuration
                let result = self.configByAPInstance!.startSmartConfigByAp(withSSID: config.ssid, andSetPassWord: config.password, andNumber: userNumberByte, andTokenData: tokenData)

                if result != 0 {
                    self.cleanupAPMode()
                    continuation.resume(throwing: WifiScaleError.operationFailed(code: Int(result), message: "AP mode error code: \(result)"))
                }
                self.logger.info("AP mode started")
                // Don't resume here - wait for TCP connection success
            }
        }
    }

    // MARK: - Timeout and Cleanup

    private func handleTimeout(for mode: WifiScaleMode) {
        switch mode {
        case .esptouch:
            esptouchContinuation?.resume(throwing: WifiScaleError.timeout)
            cleanupEsptouch()
        case .smartConfig:
            smartConfigContinuation?.resume(throwing: WifiScaleError.timeout)
            cleanupSmartConfig()
        case .apMode:
            apModeContinuation?.resume(throwing: WifiScaleError.timeout)
            cleanupAPMode()
        }
    }

    private func cleanupEsptouch() {
        esptouchContinuation = nil
        GGEsptouchHelper.getInstance()?.clearTask()
        cancelTimeouts()
    }

    private func cleanupSmartConfig() {
        smartConfigContinuation = nil
        smartConfigInstance = nil
        cancelTimeouts()
    }

    private func cleanupAPMode() {
        apModeContinuation = nil
        configByAPInstance = nil
        cancelTimeouts()
    }

    private func cancelTimeouts() {
        timeoutTasks.forEach { $0.cancel() }
        timeoutTasks.removeAll()
    }

    private func cleanup() {
        cleanupEsptouch()
        cleanupSmartConfig()
        cleanupAPMode()
    }

    // MARK: - GGEsptouchDelegate

    @objc func onSuccess(ssid: String, bssid: String, token: String) {
        logger.info("Esptouch success - SSID: \(ssid), BSSID: \(bssid)")
        esptouchContinuation?.resume()
        cleanupEsptouch()
    }

    @objc func onFailure(_ error: Int, message errorMessage: String) {
        logger.error("Esptouch failure - Error: \(error), Message: \(errorMessage)")
        esptouchContinuation?.resume(throwing: WifiScaleError.operationFailed(code: error, message: errorMessage))
        cleanupEsptouch()
    }

    // MARK: - GCDAsyncSocketDelegate

    @objc public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        logger.info("TCP connection accepted")

        // TCP connection established successfully
        smartConfigContinuation?.resume()
        cleanupSmartConfig()

        apModeContinuation?.resume()
        cleanupAPMode()
    }

    @objc public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        logger.info("TCP connection disconnected")
        if let error = err {
            logger.error("TCP connection error: \(error.localizedDescription)")
        }
        smartConfigContinuation?.resume()
        cleanupSmartConfig()

        apModeContinuation?.resume()
        cleanupAPMode()
    }
}





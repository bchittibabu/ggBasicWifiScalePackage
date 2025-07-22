import Foundation
import ggEsptouchFramework
import smartConfig
import SystemConfiguration.CaptiveNetwork

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

public enum WifiScaleError: Error {
    case helperUnavailable
    case operationFailed(code: Int, message: String)
}

public class BasicWifiScale: NSObject, GGEsptouchDelegate, GCDAsyncSocketDelegate {
    @MainActor public static let shared = BasicWifiScale()
    private override init() {}

    private var esptouchContinuation: CheckedContinuation<Void, Error>? = nil
    private var smartConfigContinuation: CheckedContinuation<Void, Error>? = nil
    private var apModeContinuation: CheckedContinuation<Void, Error>? = nil
    private var smartConfigInstance: smartConfig?
    private var configByAPInstance: ConfigByAP?

    // MARK: - Public API
    public func connect(config: WifiScaleConfig, mode: WifiScaleMode) async throws {
        switch mode {
        case .esptouch:
            try await startEsptouch(config: config)
        case .smartConfig:
            try await startSmartConfig(config: config)
        case .apMode:
            try await startAPMode(config: config)
        }
    }

    // MARK: - Private Helpers (async)
    private func startEsptouch(config: WifiScaleConfig) async throws {
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
            let started = helper.beginSmartConnect(scaleData, delegate: self)
            if !started {
                self.esptouchContinuation = nil
                continuation.resume(throwing: WifiScaleError.operationFailed(code: 0, message: "Failed to start Esptouch task"))
            }
        }
    }

    private func startSmartConfig(config: WifiScaleConfig) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                self.smartConfigInstance = smartConfig()
                self.smartConfigContinuation = continuation

                let userNumberByte: UInt8 = UInt8(config.userNumber)
                let tokenData: Data? = config.token.isEmpty ? nil : config.token.hexDecodedData()
                let result = self.smartConfigInstance!.startSetSSID(config.ssid, andSetPassWord: config.password, andNumber: userNumberByte, andTokenData: tokenData)

                if result != 0 {
                    self.smartConfigContinuation = nil
                    self.smartConfigInstance = nil
                    continuation.resume(throwing: WifiScaleError.operationFailed(code: Int(result), message: "smartConfig error code: \(result)"))
                }
                // Don't resume here - wait for TCP connection success
            }
        }
    }

    private func startAPMode(config: WifiScaleConfig) async throws {

        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                self.configByAPInstance = ConfigByAP()
                self.apModeContinuation = continuation

                let userNumberValue = config.userNumber
                let userNumberByte: UInt8 = UInt8(userNumberValue)
                let tokenString = config.token
                let tokenData: Data? = tokenString.isEmpty ? nil : tokenString.hexDecodedData()
                print("config.ssid: \(config.ssid)")
                print("config.password: \(config.password)")
                print("config.userNumber: \(userNumberValue)")
                print("config.token: \(tokenString)")

                // Start AP mode configuration - this returns immediately like in iOS
                let result = self.configByAPInstance!.startSmartConfigByAp(withSSID: config.ssid, andSetPassWord: config.password, andNumber: userNumberByte, andTokenData: tokenData)

                if result != 0 {
                    self.apModeContinuation = nil
                    self.configByAPInstance = nil
                    continuation.resume(throwing: WifiScaleError.operationFailed(code: Int(result), message: "AP mode error code: \(result)"))
                }
                // Don't resume here - wait for TCP connection success
            }
        }
    }

    // MARK: - GGEsptouchDelegate
    @objc func onSuccess(ssid: String, bssid: String, token: String) {
        esptouchContinuation?.resume()
        esptouchContinuation = nil
        GGEsptouchHelper.getInstance()?.clearTask()
    }

    @objc func onFailure(_ error: Int, message errorMessage: String) {
        esptouchContinuation?.resume(throwing: WifiScaleError.operationFailed(code: error, message: errorMessage))
        esptouchContinuation = nil
        GGEsptouchHelper.getInstance()?.clearTask()
    }

        // MARK: - GCDAsyncSocketDelegate
    @objc public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("TCP connection accepted")
        // TCP connection established successfully
        smartConfigContinuation?.resume()
        smartConfigContinuation = nil
        smartConfigInstance = nil

        apModeContinuation?.resume()
        apModeContinuation = nil
        configByAPInstance = nil
    }

    @objc public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("TCP connection disconnected")
        if let error = err {
            smartConfigContinuation?.resume(throwing: WifiScaleError.operationFailed(code: -1, message: error.localizedDescription))
            smartConfigContinuation = nil
            smartConfigInstance = nil

            apModeContinuation?.resume(throwing: WifiScaleError.operationFailed(code: -1, message: error.localizedDescription))
            apModeContinuation = nil
            configByAPInstance = nil
        }
    }
}





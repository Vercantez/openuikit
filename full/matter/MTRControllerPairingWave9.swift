import Foundation

// Wave 9: legacy MTRDeviceController pairing/commissioning spellings and the
// synchronous XPC params/response dictionary codecs.
//
// There is no Matter fabric, BLE/IP rendezvous, DNS-SD browser, or XPC
// controller daemon on Linux, so every radio/daemon path below fails closed:
// throwing methods raise MTRError.invalidState (cancel-shaped suspension
// aside), lookups return nil, browse/start calls return false, and delegate
// setters accept-and-ignore (no daemon will invoke them). The XPC
// encode/decode helpers are pure dictionary transforms and round-trip
// without a daemon. Anything that needs NSXPCConnection or a live XPC
// peer (sharedController, xpcInterfaceFor*Protocol) stays declared.

extension MTRDeviceController {
    // MARK: - Legacy pairing / commissioning (fail-closed)

    public func pairDevice(_ deviceID: UInt64, discriminator: UInt16, setupPINCode: UInt32) throws {
        _ = (deviceID, discriminator, setupPINCode)
        throw MTRFailClosed(.invalidState)
    }

    public func pairDevice(_ deviceID: UInt64, address: String, port: UInt16, setupPINCode: UInt32) throws {
        _ = (deviceID, address, port, setupPINCode)
        throw MTRFailClosed(.invalidState)
    }

    public func pairDevice(_ deviceID: UInt64, onboardingPayload: String) throws {
        _ = (deviceID, onboardingPayload)
        throw MTRFailClosed(.invalidState)
    }

    public func commissionDevice(_ deviceId: UInt64, commissioningParams: MTRCommissioningParameters) throws {
        _ = (deviceId, commissioningParams)
        throw MTRFailClosed(.invalidState)
    }

    public func continueCommissioningDevice(
        _ opaqueDeviceHandle: UnsafeMutableRawPointer,
        ignoreAttestationFailure: Bool
    ) throws {
        _ = (opaqueDeviceHandle, ignoreAttestationFailure)
        throw MTRFailClosed(.invalidState)
    }

    public func deviceBeingCommissioned(withNodeID nodeID: NSNumber) throws -> MTRBaseDevice {
        _ = nodeID
        throw MTRFailClosed(.notFound)
    }

    public func stopDevicePairing(_ deviceID: UInt64) throws {
        _ = deviceID
        throw MTRFailClosed(.invalidState)
    }

    public func openPairingWindow(_ deviceID: UInt64, duration: Int) throws {
        _ = (deviceID, duration)
        throw MTRFailClosed(.invalidState)
    }

    public func openPairingWindow(
        withPIN deviceID: UInt64,
        duration: Int,
        discriminator: Int,
        setupPIN: Int
    ) throws -> String {
        _ = (deviceID, duration, discriminator, setupPIN)
        throw MTRFailClosed(.invalidState)
    }

    // MARK: - PASE verifier / attestation lookups (fail-closed)

    /// SPAKE2+ verifier derivation needs the Matter crypto stack; Linux has
    /// no fabric to bind it to, so this returns nil instead of a verifier.
    public func computePaseVerifier(_ setupPincode: UInt32, iterations: UInt32, salt: Data) -> Data? {
        _ = (setupPincode, iterations, salt)
        return nil
    }

    public class func computePASEVerifier(
        forSetupPasscode setupPasscode: NSNumber,
        iterations: NSNumber,
        salt: Data
    ) throws -> Data {
        _ = (setupPasscode, iterations, salt)
        throw MTRFailClosed(.invalidState)
    }

    public func attestationChallenge(forDeviceID deviceID: NSNumber) -> Data? {
        _ = deviceID
        return nil
    }

    public func fetchAttestationChallenge(forDeviceId deviceId: UInt64) -> Data? {
        _ = deviceId
        return nil
    }

    /// Nothing is stored without a daemon, so forgetting is trivially complete.
    public func forgetDevice(withNodeID nodeID: NSNumber) {
        _ = nodeID
    }

    // MARK: - Connection / delegate plumbing (fail-closed)

    public func getBaseDevice(
        _ deviceID: UInt64,
        queue: dispatch_queue_t,
        completionHandler: @escaping MTRDeviceConnectionCallback
    ) -> Bool {
        _ = (deviceID, queue)
        completionHandler(nil, MTRFailClosed(.invalidState))
        return false
    }

    /// Accepted and ignored: no daemon exists to invoke the delegate.
    public func setDeviceControllerDelegate(
        _ delegate: any MTRDeviceControllerDelegate,
        queue: dispatch_queue_t
    ) {
        _ = (delegate, queue)
    }

    /// Accepted and ignored: no daemon exists to invoke the delegate.
    public func setPairingDelegate(
        _ delegate: any MTRDevicePairingDelegate,
        queue: dispatch_queue_t
    ) {
        _ = (delegate, queue)
    }

    /// Accepted and ignored: no daemon exists to request NOC issuance.
    public func setNocChainIssuer(
        _ nocChainIssuer: any MTRNOCChainIssuer,
        queue: dispatch_queue_t
    ) {
        _ = (nocChainIssuer, queue)
    }

    /// Discovery needs BLE/DNS-SD; always reports that browsing did not start.
    public func startBrowse(
        forCommissionables delegate: any MTRCommissionableBrowserDelegate,
        queue: dispatch_queue_t
    ) -> Bool {
        _ = (delegate, queue)
        return false
    }

    public func stopBrowseForCommissionables() -> Bool {
        return false
    }

    /// The controller never suspends on Linux, so resume is a no-op.
    public func resume() {}

    // MARK: - Legacy property spellings (fail-closed)

    /// Never suspended: start(_:) always throws, so isRunning stays false.
    public var isSuspended: Bool { false }

    /// No storage delegate persists node data without a daemon.
    public var nodesWithStoredData: [NSNumber] { [] }

    /// Lowercase-`d` legacy spelling of controllerNodeID.
    public var controllerNodeId: NSNumber? {
        get { controllerNodeID }
        set { controllerNodeID = newValue }
    }

    // MARK: - Synchronous XPC params/response codecs

    /// Pure dictionary transform; needs no daemon.
    public class func encodeXPCResponseValues(_ values: [[String: Any]]?) -> [[String: Any]]? {
        values
    }

    /// Pure dictionary transform; needs no daemon.
    public class func decodeXPCResponseValues(_ values: [[String: Any]]?) -> [[String: Any]]? {
        values
    }

    /// Pure dictionary transform; needs no daemon.
    public class func encodeXPCReadParams(_ params: MTRReadParams) -> [String: Any]? {
        var dict: [String: Any] = [
            "shouldAssumeUnknownAttributesReportable": params.shouldAssumeUnknownAttributesReportable,
            "shouldFilterByFabric": params.shouldFilterByFabric,
        ]
        if let fabricFiltered = params.fabricFiltered {
            dict["fabricFiltered"] = fabricFiltered
        }
        if let minEventNumber = params.minEventNumber {
            dict["minEventNumber"] = minEventNumber
        }
        return dict
    }

    /// Pure dictionary transform; needs no daemon. Nil decodes to nil.
    public class func decodeXPCReadParams(_ params: [String: Any]?) -> MTRReadParams? {
        guard let params else { return nil }
        let out = MTRReadParams()
        if let v = params["shouldAssumeUnknownAttributesReportable"] as? Bool {
            out.shouldAssumeUnknownAttributesReportable = v
        }
        if let v = params["shouldFilterByFabric"] as? Bool {
            out.shouldFilterByFabric = v
        }
        if let v = params["fabricFiltered"] as? NSNumber {
            out.fabricFiltered = v
        }
        if let v = params["minEventNumber"] as? NSNumber {
            out.minEventNumber = v
        }
        return out
    }

    /// Pure dictionary transform; needs no daemon. Nil encodes to nil.
    public class func encodeXPCSubscribeParams(_ params: MTRSubscribeParams?) -> [String: Any]? {
        guard let params else { return nil }
        var dict = encodeXPCReadParams(params) ?? [:]
        dict["minInterval"] = params.minInterval
        dict["maxInterval"] = params.maxInterval
        dict["shouldResubscribeAutomatically"] = params.shouldResubscribeAutomatically
        dict["shouldReplaceExistingSubscriptions"] = params.shouldReplaceExistingSubscriptions
        dict["shouldReportEventsUrgently"] = params.shouldReportEventsUrgently
        if let v = params.autoResubscribe {
            dict["autoResubscribe"] = v
        }
        if let v = params.keepPreviousSubscriptions {
            dict["keepPreviousSubscriptions"] = v
        }
        return dict
    }

    /// Pure dictionary transform; needs no daemon. Nil decodes to nil.
    public class func decodeXPCSubscribeParams(_ params: [String: Any]?) -> MTRSubscribeParams? {
        guard let params else { return nil }
        let minInterval = (params["minInterval"] as? NSNumber) ?? NSNumber(value: 0)
        let maxInterval = (params["maxInterval"] as? NSNumber) ?? NSNumber(value: 1)
        let out = MTRSubscribeParams(minInterval: minInterval, maxInterval: maxInterval)
        if let v = params["shouldAssumeUnknownAttributesReportable"] as? Bool {
            out.shouldAssumeUnknownAttributesReportable = v
        }
        if let v = params["shouldFilterByFabric"] as? Bool {
            out.shouldFilterByFabric = v
        }
        if let v = params["fabricFiltered"] as? NSNumber {
            out.fabricFiltered = v
        }
        if let v = params["minEventNumber"] as? NSNumber {
            out.minEventNumber = v
        }
        if let v = params["shouldResubscribeAutomatically"] as? Bool {
            out.shouldResubscribeAutomatically = v
        }
        if let v = params["shouldReplaceExistingSubscriptions"] as? Bool {
            out.shouldReplaceExistingSubscriptions = v
        }
        if let v = params["shouldReportEventsUrgently"] as? Bool {
            out.shouldReportEventsUrgently = v
        }
        if let v = params["autoResubscribe"] as? NSNumber {
            out.autoResubscribe = v
        }
        if let v = params["keepPreviousSubscriptions"] as? NSNumber {
            out.keepPreviousSubscriptions = v
        }
        return out
    }
}

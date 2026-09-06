import Foundation

/// Optional emergency-response delegate. Apple marks
/// `emergencyResponseManager(_:didUpdateVoiceCallStatus:)` optional; Linux
/// supplies an empty default so adopting types need not implement it.
public protocol SAEmergencyResponseDelegate: NSObjectProtocol {
    func emergencyResponseManager(
        _ emergencyResponseManager: SAEmergencyResponseManager,
        didUpdateVoiceCallStatus voiceCallStatus: SAEmergencyResponseManager.VoiceCallStatus
    )
}

extension SAEmergencyResponseDelegate {
    public func emergencyResponseManager(
        _ emergencyResponseManager: SAEmergencyResponseManager,
        didUpdateVoiceCallStatus voiceCallStatus: SAEmergencyResponseManager.VoiceCallStatus
    ) {
        _ = (emergencyResponseManager, voiceCallStatus)
    }
}

/// Emergency voice-call request surface. Linux has no telephony daemon or
/// Emergency SOS service.
open class SAEmergencyResponseManager: NSObject {
    /// Voice-call lifecycle. Raw values follow the pinned `dotnet/macios`
    /// `SAEmergencyResponseManagerVoiceCallStatus` enumeration
    /// (`dialing = 0` through `failed = 3`).
    public enum VoiceCallStatus: Int, Hashable, Sendable {
        case dialing = 0
        case active = 1
        case disconnected = 2
        case failed = 3
    }

    open weak var delegate: (any SAEmergencyResponseDelegate)?

    public override init() {
        super.init()
    }

    /// ObjC completion-handler overlay of `dialVoiceCallToPhoneNumber:completionHandler:`.
    /// Completes once, synchronously, with `(false, SAError.notAllowed)` and
    /// does not notify the delegate of a call-status change.
    open func dialVoiceCall(
        toPhoneNumber phoneNumber: String,
        completionHandler handler: @escaping (Bool, (any Error)?) -> Void
    ) {
        _ = phoneNumber
        handler(false, SAError(.notAllowed))
    }

    /// Swift async overlay of the same ObjC selector. Always throws
    /// `SAError.notAllowed`.
    open func dialVoiceCall(toPhoneNumber phoneNumber: String) async throws -> Bool {
        _ = phoneNumber
        throw SAError(.notAllowed)
    }

    /// Isolated-host SPI to exercise delegate wiring. Linux never calls this
    /// from a telephony path.
    public func host_deliverVoiceCallStatus(_ status: VoiceCallStatus) {
        delegate?.emergencyResponseManager(self, didUpdateVoiceCallStatus: status)
    }
}
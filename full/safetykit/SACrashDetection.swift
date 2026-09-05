import Foundation

/// Optional Crash Detection event delegate. Apple marks
/// `crashDetectionManager(_:didDetect:)` optional; Linux supplies an empty
/// default so adopting types need not implement it.
public protocol SACrashDetectionDelegate: NSObjectProtocol {
    func crashDetectionManager(
        _ crashDetectionManager: SACrashDetectionManager,
        didDetect event: SACrashDetectionEvent
    )
}

extension SACrashDetectionDelegate {
    public func crashDetectionManager(
        _ crashDetectionManager: SACrashDetectionManager,
        didDetect event: SACrashDetectionEvent
    ) {
        _ = (crashDetectionManager, event)
    }
}

/// A Crash Detection event delivered by Apple hardware. Linux never produces
/// these from sensors; tests construct instances through `host_makeEvent`.
open class SACrashDetectionEvent: NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    /// Response taken after a detected crash. Raw values follow the pinned
    /// `dotnet/macios` `SACrashDetectionEventResponse` enumeration
    /// (`attempted = 0`, `disabled = 1`).
    public enum Response: Int, Hashable, Sendable {
        case attempted = 0
        case disabled = 1
    }

    public let date: Date
    public let response: Response
    public let location: CLLocation?

    @available(*, unavailable, message: "SACrashDetectionEvent has no public designated initializer on Apple; events come from Crash Detection hardware.")
    public override init() {
        fatalError("SACrashDetectionEvent.init is unavailable")
    }

    /// Isolated-host constructor. Not part of Apple's public surface.
    public static func host_makeEvent(
        date: Date,
        response: Response,
        location: CLLocation? = nil
    ) -> SACrashDetectionEvent {
        SACrashDetectionEvent(date: date, response: response, location: location)
    }

    fileprivate init(date: Date, response: Response, location: CLLocation?) {
        self.date = date
        self.response = response
        self.location = location
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let date = coder.decodeObject(of: NSDate.self, forKey: "date") as Date? else {
            return nil
        }
        let rawResponse = coder.decodeInteger(forKey: "response")
        guard let response = Response(rawValue: rawResponse) else {
            return nil
        }
        self.date = date
        self.response = response
        if coder.containsValue(forKey: "location") {
            self.location = coder.decodeObject(of: CLLocation.self, forKey: "location")
        } else {
            self.location = nil
        }
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(date as NSDate, forKey: "date")
        coder.encode(response.rawValue, forKey: "response")
        if let location {
            coder.encode(location, forKey: "location")
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return SACrashDetectionEvent(date: date, response: response, location: location)
    }
}

/// Crash Detection session. Linux has no Crash Detection sensor or
/// `com.apple.developer.safetykit.crash-detection` entitlement.
open class SACrashDetectionManager: NSObject {
    /// Always `false` on Linux. Apple reports `true` only on supported
    /// iPhone hardware with Crash Detection.
    open class var isAvailable: Bool { false }

    /// Linux never presents an authorization prompt, so status stays
    /// `.notDetermined`.
    open private(set) var authorizationStatus: SAAuthorizationStatus = .notDetermined

    open weak var delegate: (any SACrashDetectionDelegate)?

    public override init() {
        super.init()
    }

    /// Completes once, synchronously, with `.notDetermined` and
    /// `SAError.notAllowed`. Does not mutate `authorizationStatus` and never
    /// delivers a crash event.
    open func requestAuthorization(
        completionHandler handler: @escaping (SAAuthorizationStatus, (any Error)?) -> Void
    ) {
        handler(.notDetermined, SAError(.notAllowed))
    }

    /// Async overlay of the same ObjC selector. Throws `SAError.notAllowed`.
    open func requestAuthorization() async throws -> SAAuthorizationStatus {
        throw SAError(.notAllowed)
    }

    /// Isolated-host SPI to exercise delegate wiring. Linux never calls this
    /// from a sensor path.
    public func host_deliverDetectedEvent(_ event: SACrashDetectionEvent) {
        delegate?.crashDetectionManager(self, didDetect: event)
    }
}
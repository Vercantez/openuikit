import Foundation

/// eSIM / plan capability recorded on `CTCellularPlanProperties`.
public enum CTCellularPlanCapability: Int, Sendable {
    case dataOnly = 0
    case dataAndVoice = 1
}

/// Result of an add-plan request. Linux always reports `.fail`.
public enum CTCellularPlanProvisioningAddPlanResult: UInt, Sendable {
    case unknown = 0
    case fail = 1
    case success = 2
    case cancel = 3
}

/// Mutable plan properties. Encoding keys are Linux-local, not Apple archive
/// compatible, until an Apple NSCoder dump is observed.
open class CTCellularPlanProperties: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var associatedIccid: String?
    open var simCapability: CTCellularPlanCapability
    open var supportedRegionCodes: [Locale.Region]

    public override init() {
        associatedIccid = nil
        simCapability = .dataOnly
        supportedRegionCodes = []
        super.init()
    }

    public required init?(coder: NSCoder) {
        associatedIccid = coder.decodeObject(of: NSString.self, forKey: "associatedIccid") as String?
        let raw = Int(coder.decodeInt64(forKey: "simCapability"))
        guard let capability = CTCellularPlanCapability(rawValue: raw) else {
            return nil
        }
        simCapability = capability
        let identifiers =
            coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "supportedRegionCodes")
            as? [String] ?? []
        supportedRegionCodes = identifiers.map { Locale.Region($0) }
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(associatedIccid as NSString?, forKey: "associatedIccid")
        coder.encode(Int64(simCapability.rawValue), forKey: "simCapability")
        let identifiers = supportedRegionCodes.map(\.identifier) as NSArray
        coder.encode(identifiers, forKey: "supportedRegionCodes")
    }
}

/// Carrier-plan install request. Property names match the Swift overlay
/// (`eid`, `iccid`, `oid`). Archive keys are Linux-local.
open class CTCellularPlanProvisioningRequest: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var address: String
    open var matchingID: String?
    open var oid: String?
    open var confirmationCode: String?
    open var iccid: String?
    open var eid: String?

    public override init() {
        address = ""
        super.init()
    }

    public required init?(coder: NSCoder) {
        address = (coder.decodeObject(of: NSString.self, forKey: "address") as String?) ?? ""
        matchingID = coder.decodeObject(of: NSString.self, forKey: "matchingID") as String?
        oid = coder.decodeObject(of: NSString.self, forKey: "OID") as String?
        confirmationCode = coder.decodeObject(of: NSString.self, forKey: "confirmationCode") as String?
        iccid = coder.decodeObject(of: NSString.self, forKey: "ICCID") as String?
        eid = coder.decodeObject(of: NSString.self, forKey: "EID") as String?
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(address as NSString, forKey: "address")
        coder.encode(matchingID as NSString?, forKey: "matchingID")
        coder.encode(oid as NSString?, forKey: "OID")
        coder.encode(confirmationCode as NSString?, forKey: "confirmationCode")
        coder.encode(iccid as NSString?, forKey: "ICCID")
        coder.encode(eid as NSString?, forKey: "EID")
    }
}

/// eSIM / carrier-plan provisioning. Linux reports no plan support and every
/// add/update call fails closed.
open class CTCellularPlanProvisioning: NSObject {
    public override init() {
        super.init()
    }

    open var supportsEmbeddedSIM: Bool { false }

    open func supportsCellularPlan() -> Bool { false }

    open func addPlan(
        with request: CTCellularPlanProvisioningRequest,
        completionHandler: @escaping (CTCellularPlanProvisioningAddPlanResult) -> Void
    ) {
        _ = request
        completionHandler(.fail)
    }

    open func addPlan(
        with request: CTCellularPlanProvisioningRequest
    ) async -> CTCellularPlanProvisioningAddPlanResult {
        await withCheckedContinuation { continuation in
            addPlan(with: request) { result in
                continuation.resume(returning: result)
            }
        }
    }

    open func addPlan(
        request: CTCellularPlanProvisioningRequest,
        properties: CTCellularPlanProperties?,
        completionHandler: @escaping (CTCellularPlanProvisioningAddPlanResult) -> Void
    ) {
        _ = (request, properties)
        completionHandler(.fail)
    }

    open func addPlan(
        request: CTCellularPlanProvisioningRequest,
        properties: CTCellularPlanProperties?
    ) async -> CTCellularPlanProvisioningAddPlanResult {
        await withCheckedContinuation { continuation in
            addPlan(request: request, properties: properties) { result in
                continuation.resume(returning: result)
            }
        }
    }

    open func update(
        _ properties: CTCellularPlanProperties,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = properties
        completionHandler(CoreTelephonyUnsupportedError())
    }

    open func update(_ properties: CTCellularPlanProperties) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            update(properties) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

/// Plan-status token APIs. Linux cannot mint or validate Apple plan tokens.
open class CTCellularPlanStatus: NSObject {
    public override init() {
        super.init()
    }

    open class func getTokenWithCompletion(
        _ completionHandler: @escaping (String?, (any Error)?) -> Void
    ) {
        completionHandler(nil, CoreTelephonyUnsupportedError())
    }

    open class func token() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            getTokenWithCompletion { token, error in
                if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: error ?? CoreTelephonyUnsupportedError())
                }
            }
        }
    }

    open class func checkValidity(
        ofToken token: String,
        completionHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        _ = token
        completionHandler(false, CoreTelephonyUnsupportedError())
    }

    open class func checkValidity(ofToken token: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            checkValidity(ofToken: token) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: CoreTelephonyUnsupportedError())
                }
            }
        }
    }
}

import Foundation

/// Plan property bag. `init(coder:)` is fail-closed (`nil`): Apple archive
/// keys are unobserved. Local mutable fields are otherwise ordinary storage.
open class CTCellularPlanProperties: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var associatedIccid: String?
    open var simCapability: CTCellularPlanCapability = .dataOnly
    open var supportedRegionCodes: [Locale.Region] = []

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }
}

/// eSIM add-plan request. `address` defaults to `""`. Coding is fail-closed.
open class CTCellularPlanProvisioningRequest: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var address: String = ""
    open var matchingID: String?
    open var oid: String?
    open var confirmationCode: String?
    open var iccid: String?
    open var eid: String?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }
}

/// Linux has no eSIM / embedded-SIM host. Support flags are `false`. Add-plan
/// completes asynchronously with `.fail`; `update` fails closed with an
/// `NSError`. Success is never fabricated.
open class CTCellularPlanProvisioning: NSObject {
    public override init() {
        super.init()
    }

    open var supportsEmbeddedSIM: Bool { false }

    open func supportsCellularPlan() -> Bool {
        false
    }

    open func addPlan(
        with request: CTCellularPlanProvisioningRequest,
        completionHandler: @escaping (CTCellularPlanProvisioningAddPlanResult) -> Void
    ) {
        _ = request
        coreTelephonyHop {
            completionHandler(.fail)
        }
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
        _ = properties
        addPlan(with: request, completionHandler: completionHandler)
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
        coreTelephonyHop {
            completionHandler(
                coreTelephonyUnavailableError(
                    "CTCellularPlanProvisioning.update is unavailable without an eSIM host"
                )
            )
        }
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

/// Plan-status token APIs fail closed. Linux never invents a carrier token.
open class CTCellularPlanStatus: NSObject {
    public override init() {
        super.init()
    }

    open class func getTokenWithCompletion(
        _ completionHandler: @escaping (String?, (any Error)?) -> Void
    ) {
        coreTelephonyHop {
            completionHandler(
                nil,
                coreTelephonyUnavailableError(
                    "CTCellularPlanStatus.getToken is unavailable without cellular plan status"
                )
            )
        }
    }

    open class func checkValidity(ofToken token: String) async throws -> Bool {
        _ = token
        throw coreTelephonyUnavailableError(
            "CTCellularPlanStatus.checkValidity is unavailable without cellular plan status"
        )
    }
}

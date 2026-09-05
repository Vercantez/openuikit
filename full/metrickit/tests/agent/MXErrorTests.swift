@_spi(OpenUIKitHost) import MetricKit
import Foundation

private struct MXErrorCodeMapping {
    let code: MXError.Code
    let rawValue: Int
    let staticAlias: MXError.Code
    let name: String
}

/// Table-driven copy of the pinned Apple iOS 26.1 oracle mapping
/// (`metric.error=4,0,3,5,1,2`).
private let mxErrorCodeMappings: [MXErrorCodeMapping] = [
    MXErrorCodeMapping(
        code: .launchTaskUnknown,
        rawValue: 4,
        staticAlias: MXError.launchTaskUnknown,
        name: "launchTaskUnknown"
    ),
    MXErrorCodeMapping(
        code: .launchTaskInvalidID,
        rawValue: 0,
        staticAlias: MXError.launchTaskInvalidID,
        name: "launchTaskInvalidID"
    ),
    MXErrorCodeMapping(
        code: .launchTaskDuplicated,
        rawValue: 3,
        staticAlias: MXError.launchTaskDuplicated,
        name: "launchTaskDuplicated"
    ),
    MXErrorCodeMapping(
        code: .launchTaskInternalFailure,
        rawValue: 5,
        staticAlias: MXError.launchTaskInternalFailure,
        name: "launchTaskInternalFailure"
    ),
    MXErrorCodeMapping(
        code: .launchTaskMaxCount,
        rawValue: 1,
        staticAlias: MXError.launchTaskMaxCount,
        name: "launchTaskMaxCount"
    ),
    MXErrorCodeMapping(
        code: .launchTaskPastDeadline,
        rawValue: 2,
        staticAlias: MXError.launchTaskPastDeadline,
        name: "launchTaskPastDeadline"
    ),
]

func testMXErrorCodeRawValues() {
    mxRequire(mxErrorCodeMappings.count == 6, "testMXErrorCodeRawValues: every mapping")
    var seenRaw = Set<Int>()
    for mapping in mxErrorCodeMappings {
        mxRequire(
            mapping.code.rawValue == mapping.rawValue,
            "testMXErrorCodeRawValues: \(mapping.name) rawValue"
        )
        mxRequire(
            MXError.Code(rawValue: mapping.rawValue) == mapping.code,
            "testMXErrorCodeRawValues: \(mapping.name) init(rawValue:)"
        )
        mxRequire(
            mapping.staticAlias == mapping.code,
            "testMXErrorCodeRawValues: \(mapping.name) static alias"
        )
        mxRequire(
            MXError(mapping.code).errorCode == mapping.rawValue,
            "testMXErrorCodeRawValues: \(mapping.name) errorCode"
        )
        mxRequire(
            seenRaw.insert(mapping.rawValue).inserted,
            "testMXErrorCodeRawValues: \(mapping.name) unique raw"
        )
        mxRequire(
            MXError.Code.launchTaskInternalFailure ~= MXError(mapping.code)
                || mapping.code != .launchTaskInternalFailure,
            "testMXErrorCodeRawValues: \(mapping.name) pattern"
        )
        var hasher = Hasher()
        mapping.code.hash(into: &hasher)
        mxRequire(
            mapping.code.hashValue == mapping.code.hashValue,
            "testMXErrorCodeRawValues: \(mapping.name) hashValue"
        )
    }
    mxRequire(MXError.Code(rawValue: 99) == nil, "testMXErrorCodeRawValues: invalid rawValue")
    mxRequire(
        MXError.Code.launchTaskInternalFailure ~= MXError(.launchTaskInternalFailure),
        "testMXErrorCodeRawValues: ~= match"
    )
    mxRequire(
        !(MXError.Code.launchTaskUnknown ~= MXError(.launchTaskInternalFailure)),
        "testMXErrorCodeRawValues: ~= mismatch"
    )
}

func testMXErrorDomainAndBridging() {
    mxRequire(MXErrorDomain == "MXErrorDomain", "testMXErrorDomainAndBridging: MXErrorDomain")
    mxRequire(MXError.errorDomain == MXErrorDomain, "testMXErrorDomainAndBridging: errorDomain")
    let error = MXError(.launchTaskInternalFailure, userInfo: ["reason": "linux"])
    mxRequire(error.code == .launchTaskInternalFailure, "testMXErrorDomainAndBridging: code")
    mxRequire(error.errorCode == 5, "testMXErrorDomainAndBridging: errorCode 5")
    mxRequire((error.userInfo["reason"] as? String) == "linux", "testMXErrorDomainAndBridging: userInfo")
    mxRequire((error.errorUserInfo["reason"] as? String) == "linux", "testMXErrorDomainAndBridging: errorUserInfo")
    mxRequire(!error.localizedDescription.isEmpty, "testMXErrorDomainAndBridging: localizedDescription")
    mxRequire(
        error == MXError(.launchTaskInternalFailure, userInfo: ["reason": "linux"]),
        "testMXErrorDomainAndBridging: =="
    )
    mxRequire(error != MXError(.launchTaskUnknown), "testMXErrorDomainAndBridging: !=")
    mxRequire(
        error.hashValue == MXError(.launchTaskInternalFailure).hashValue,
        "testMXErrorDomainAndBridging: hashValue"
    )
    var hasher = Hasher()
    error.hash(into: &hasher)
    let cocoa = error as NSError
    mxRequire(cocoa.domain == MXErrorDomain, "testMXErrorDomainAndBridging: NSError.domain")
    mxRequire(cocoa.code == 5, "testMXErrorDomainAndBridging: NSError.code")
}

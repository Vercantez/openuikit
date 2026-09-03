@_spi(OpenUIKitHost) import MetricKit
import Foundation

/// Future clean-EC2 probe: MetricKit must consume the guest Foundation types
/// (`NSObject`, `NSError`, `Date`, `Data`, `Measurement`, `Unit`, `NSNumber`,
/// `NSCoder`, and collections) rather than a module-local Foundation universe.
/// Compile and load against `libMetricKit.dylib`; this file is not part of the
/// isolated host-gate runtime binary.

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private final class DummyCoder: NSCoder {}

private func sameTypeUniverse(_ lhs: Any.Type, _ rhs: Any.Type, _ message: String) {
    require(ObjectIdentifier(lhs) == ObjectIdentifier(rhs), message)
}

private func proveFoundationIdentity() {
    require(MXMetricManager.shared.isKind(of: NSObject.self), "MXMetricManager is guest Foundation.NSObject")
    require((MXMetricManager.shared as NSObject) === MXMetricManager.shared, "NSObject identity")
    require(MXUnitAveragePixelLuminance.apl.isKind(of: Dimension.self), "apl is guest Foundation.Dimension")
    require(MXUnitAveragePixelLuminance.apl.isKind(of: Unit.self), "apl is guest Foundation.Unit")
    require(MXUnitSignalBars.bars.isKind(of: Dimension.self), "bars is guest Foundation.Dimension")
    require(MXUnitSignalBars.bars.isKind(of: Unit.self), "bars is guest Foundation.Unit")

    let error = MXError(.launchTaskInternalFailure, userInfo: ["k": "v"])
    let cocoa = error as NSError
    sameTypeUniverse(type(of: cocoa), NSError.self, "MXError bridges to guest Foundation.NSError")
    require(cocoa.domain == MXErrorDomain, "NSError.domain is guest MXErrorDomain")
    require(cocoa.code == 5, "NSError.code uses oracle raw value 5")
    require((cocoa.userInfo["k"] as? String) == "v", "NSError.userInfo is Foundation collection")

    let date = Date(timeIntervalSince1970: 123)
    sameTypeUniverse(type(of: date), Date.self, "Date is guest Foundation.Date")
    let payload = MXMetricPayload(timeStampBegin: date, timeStampEnd: date)
    require(payload.timeStampBegin == date, "payload Date identity")
    require(payload.timeStampEnd == date, "payload Date end identity")

    let tree = MXCallStackTree()
    let data: Data = tree.jsonRepresentation()
    sameTypeUniverse(type(of: data), Data.self, "jsonRepresentation returns guest Foundation.Data")
    _ = data.count

    let duration = UnitDuration.seconds
    require(duration.isKind(of: Dimension.self), "UnitDuration is guest Dimension")
    require(duration.isKind(of: Unit.self), "UnitDuration is guest Unit")
    let measurement = Measurement(value: 1.5, unit: duration)
    let cpu = MXCPUMetric(cumulativeCPUTime: measurement)
    require(cpu.cumulativeCPUTime == measurement, "Measurement is guest Foundation.Measurement")
    require(cpu.cumulativeCPUTime.unit === duration, "Unit identity through MetricKit")

    let number = NSNumber(value: 11)
    sameTypeUniverse(type(of: number), NSNumber.self, "NSNumber is guest Foundation.NSNumber")
    let crash = MXCrashDiagnostic(signal: number)
    require(crash.signal == number, "NSNumber identity through MXCrashDiagnostic")

    let coder: NSCoder = DummyCoder()
    require(MXMetaData(coder: coder) == nil, "NSCoder is guest Foundation.NSCoder")
    require(MXMetric(coder: coder) == nil, "MXMetric init(coder:) uses guest NSCoder")

    let arguments = ["a", "b"]
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(arguments: arguments)
    require(reason.arguments == arguments, "Array<String> is guest collection")
    let dictionary: [AnyHashable: Any] = reason.dictionaryRepresentation()
    require(dictionary["arguments"] as? [String] == arguments, "[AnyHashable: Any] collection")

    let records: [MXSignpostRecord] = [
        MXSignpostRecord(beginTimeStamp: date)
    ]
    let diagnostic = MXDiagnostic(signpostData: records)
    require(diagnostic.signpostData?.count == 1, "Array through MXDiagnostic")
}

proveFoundationIdentity()
print("METRICKIT_DEPENDENCY_IDENTITY_OK")

@_spi(OpenUIKitHost) import MetricKit
import Foundation
import Dispatch

/// Sealed-gate runtime probe. The isolated host gate compiles this file alone,
/// so it concatenates the focused `*Tests.swift` suite and invokes every
/// top-level `test*` function before printing the success marker.
// --- MXCodingTests.swift ---
func testSupportInitWithCoder() {
    let coder = MXDummyCoder()
    mxRequire(MXAverage<UnitDuration>(coder: coder) == nil, "testSupportInitWithCoder: MXAverage")
    mxRequire(MXHistogram<UnitDuration>(coder: coder) == nil, "testSupportInitWithCoder: MXHistogram")
    mxRequire(
        MXHistogramBucket<UnitDuration>(coder: coder) == nil,
        "testSupportInitWithCoder: MXHistogramBucket"
    )
    let average = MXAverage(
        averageMeasurement: Measurement(value: 1, unit: UnitDuration.seconds)
    )
    average.encode(with: coder)
    MXHistogram<UnitDuration>().encode(with: coder)
}

func testMetricInitWithCoder() {
    let coder = MXDummyCoder()
    mxRequire(MXMetric(coder: coder) == nil, "testMetricInitWithCoder: MXMetric")
    mxRequire(MXBackgroundExitData(coder: coder) == nil, "testMetricInitWithCoder: MXBackgroundExitData")
    mxRequire(MXForegroundExitData(coder: coder) == nil, "testMetricInitWithCoder: MXForegroundExitData")
    mxRequire(MXSignpostIntervalData(coder: coder) == nil, "testMetricInitWithCoder: MXSignpostIntervalData")
    MXMetric().encode(with: coder)
    MXBackgroundExitData().encode(with: coder)
    MXForegroundExitData().encode(with: coder)
    MXSignpostIntervalData().encode(with: coder)
}

func testDiagnosticInitWithCoder() {
    let coder = MXDummyCoder()
    mxRequire(MXCallStackTree(coder: coder) == nil, "testDiagnosticInitWithCoder: MXCallStackTree")
    mxRequire(
        MXCrashDiagnosticObjectiveCExceptionReason(coder: coder) == nil,
        "testDiagnosticInitWithCoder: exception reason"
    )
    mxRequire(MXDiagnostic(coder: coder) == nil, "testDiagnosticInitWithCoder: MXDiagnostic")
    mxRequire(MXMetaData(coder: coder) == nil, "testDiagnosticInitWithCoder: MXMetaData")
    mxRequire(MXSignpostRecord(coder: coder) == nil, "testDiagnosticInitWithCoder: MXSignpostRecord")
    MXCallStackTree().encode(with: coder)
    MXCrashDiagnosticObjectiveCExceptionReason().encode(with: coder)
    MXDiagnostic().encode(with: coder)
    MXMetaData().encode(with: coder)
    MXSignpostRecord().encode(with: coder)
}

func testPayloadInitWithCoder() {
    let coder = MXDummyCoder()
    mxRequire(MXMetricPayload(coder: coder) == nil, "testPayloadInitWithCoder: MXMetricPayload")
    mxRequire(MXDiagnosticPayload(coder: coder) == nil, "testPayloadInitWithCoder: MXDiagnosticPayload")
    MXMetricPayload().encode(with: coder)
    MXDiagnosticPayload().encode(with: coder)
}

// --- MXDiagnosticGetterTests.swift ---
func testMetaDataGetters() {
    let meta = MXMetaData(
        regionFormat: "US",
        osVersion: "Linux",
        deviceType: "test",
        applicationBuildVersion: "1",
        platformArchitecture: "x86_64",
        lowPowerModeEnabled: true,
        isTestFlightApp: false,
        pid: 42,
        bundleIdentifier: "example.app"
    )
    mxRequire(meta.regionFormat == "US", "testMetaDataGetters: region")
    mxRequire(meta.osVersion == "Linux", "testMetaDataGetters: os")
    mxRequire(meta.deviceType == "test", "testMetaDataGetters: device")
    mxRequire(meta.applicationBuildVersion == "1", "testMetaDataGetters: build")
    mxRequire(meta.platformArchitecture == "x86_64", "testMetaDataGetters: arch")
    mxRequire(meta.lowPowerModeEnabled, "testMetaDataGetters: low power")
    mxRequire(!meta.isTestFlightApp, "testMetaDataGetters: testflight")
    mxRequire(meta.pid == 42, "testMetaDataGetters: pid")
    mxRequire(meta.bundleIdentifier == "example.app", "testMetaDataGetters: bundle")
}

func testSignpostRecordGetters() {
    let record = MXSignpostRecord(
        subsystem: "app",
        category: "ui",
        name: "frame",
        beginTimeStamp: Date(timeIntervalSince1970: 10),
        endTimeStamp: Date(timeIntervalSince1970: 11),
        duration: Measurement(value: 1, unit: .seconds),
        isInterval: true
    )
    mxRequire(record.subsystem == "app", "testSignpostRecordGetters: subsystem")
    mxRequire(record.category == "ui", "testSignpostRecordGetters: category")
    mxRequire(record.name == "frame", "testSignpostRecordGetters: name")
    mxRequire(record.beginTimeStamp.timeIntervalSince1970 == 10, "testSignpostRecordGetters: begin")
    mxRequire(record.endTimeStamp?.timeIntervalSince1970 == 11, "testSignpostRecordGetters: end")
    mxRequire(record.duration?.value == 1, "testSignpostRecordGetters: duration")
    mxRequire(record.isInterval, "testSignpostRecordGetters: interval")
}

func testExceptionReasonGetters() {
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(
        composedMessage: "boom",
        formatString: "%@",
        arguments: ["x"],
        exceptionType: "NSException",
        className: "Thing",
        exceptionName: "Test"
    )
    mxRequire(reason.composedMessage == "boom", "testExceptionReasonGetters: composed")
    mxRequire(reason.formatString == "%@", "testExceptionReasonGetters: format")
    mxRequire(reason.arguments == ["x"], "testExceptionReasonGetters: args")
    mxRequire(reason.exceptionType == "NSException", "testExceptionReasonGetters: exc type")
    mxRequire(reason.exceptionName == "Test", "testExceptionReasonGetters: name")
}

func testMXCrashDiagnosticObjectiveCExceptionReasonClassName() {
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(
        composedMessage: "boom",
        formatString: "%@",
        arguments: ["x"],
        exceptionType: "NSException",
        className: "Thing",
        exceptionName: "Test"
    )
    let observed: String = reason.className
    mxRequire(
        observed == "Thing",
        "testMXCrashDiagnosticObjectiveCExceptionReasonClassName: stored className"
    )
#if canImport(ObjectiveC)
    let asObject: NSObject = reason
    mxRequire(
        asObject.className == "Thing",
        "testMXCrashDiagnosticObjectiveCExceptionReasonClassName: NSObject override"
    )
#endif
}

func testDiagnosticGetters() {
    let meta = MXMetaData(pid: 42, bundleIdentifier: "example.app")
    let tree = MXCallStackTree()
    let record = MXSignpostRecord(name: "frame")
    let diagnostic = MXDiagnostic(applicationVersion: "1.0", metaData: meta, signpostData: [record])
    mxRequire(diagnostic.applicationVersion == "1.0", "testDiagnosticGetters: version")
    mxRequire(diagnostic.metaData.pid == 42, "testDiagnosticGetters: meta")
    mxRequire(diagnostic.signpostData?.count == 1, "testDiagnosticGetters: signposts")
    _ = tree
}

func testAppLaunchDiagnosticGetters() {
    let tree = MXCallStackTree()
    let launch = MXAppLaunchDiagnostic(
        callStackTree: tree,
        launchDuration: Measurement(value: 2, unit: .seconds)
    )
    mxRequire(launch.launchDuration.value == 2, "testAppLaunchDiagnosticGetters: duration")
    mxRequire(launch.callStackTree === tree, "testAppLaunchDiagnosticGetters: tree")
}

func testCPUExceptionDiagnosticGetters() {
    let tree = MXCallStackTree()
    let cpuExc = MXCPUExceptionDiagnostic(
        totalCPUTime: Measurement(value: 3, unit: .seconds),
        totalSampledTime: Measurement(value: 4, unit: .seconds)
    )
    mxRequire(cpuExc.totalCPUTime.value == 3, "testCPUExceptionDiagnosticGetters: cpu time")
    mxRequire(cpuExc.totalSampledTime.value == 4, "testCPUExceptionDiagnosticGetters: sampled")
    mxRequire(cpuExc.callStackTree !== tree, "testCPUExceptionDiagnosticGetters: distinct tree")
}

func testCrashDiagnosticGetters() {
    let tree = MXCallStackTree()
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(exceptionName: "Test")
    let crash = MXCrashDiagnostic(
        callStackTree: tree,
        terminationReason: "signal",
        virtualMemoryRegionInfo: "stack",
        exceptionType: NSNumber(value: 1),
        exceptionCode: NSNumber(value: 2),
        signal: NSNumber(value: 11),
        exceptionReason: reason
    )
    mxRequire(crash.callStackTree === tree, "testCrashDiagnosticGetters: tree")
    mxRequire(crash.terminationReason == "signal", "testCrashDiagnosticGetters: term")
    mxRequire(crash.virtualMemoryRegionInfo == "stack", "testCrashDiagnosticGetters: vm")
    mxRequire(crash.exceptionType == NSNumber(value: 1), "testCrashDiagnosticGetters: type")
    mxRequire(crash.exceptionCode == NSNumber(value: 2), "testCrashDiagnosticGetters: code")
    mxRequire(crash.signal == NSNumber(value: 11), "testCrashDiagnosticGetters: signal")
    mxRequire(crash.exceptionReason?.exceptionName == "Test", "testCrashDiagnosticGetters: reason")
}

func testDiskWriteExceptionDiagnosticGetters() {
    let tree = MXCallStackTree()
    let disk = MXDiskWriteExceptionDiagnostic(totalWritesCaused: Measurement(value: 9, unit: .bytes))
    mxRequire(disk.totalWritesCaused.value == 9, "testDiskWriteExceptionDiagnosticGetters: writes")
    mxRequire(disk.callStackTree !== tree, "testDiskWriteExceptionDiagnosticGetters: distinct tree")
}

func testHangDiagnosticGetters() {
    let tree = MXCallStackTree()
    let hang = MXHangDiagnostic(hangDuration: Measurement(value: 5, unit: .seconds))
    mxRequire(hang.hangDuration.value == 5, "testHangDiagnosticGetters: hang")
    mxRequire(hang.callStackTree !== tree, "testHangDiagnosticGetters: distinct tree")
}

func testCallStackTreeType() {
    let tree = MXCallStackTree()
    mxRequire(tree.isKind(of: NSObject.self), "testCallStackTreeType: NSObject")
}

// --- MXErrorTests.swift ---
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

// --- MXHistogramTests.swift ---
func testUnitSymbols() {
    mxRequire(MXUnitAveragePixelLuminance.apl.symbol == "apl", "testUnitSymbols: apl")
    mxRequire(MXUnitSignalBars.bars.symbol == "bars", "testUnitSymbols: bars")
    mxRequire(
        MXUnitAveragePixelLuminance.apl === MXUnitAveragePixelLuminance.baseUnit(),
        "testUnitSymbols: apl baseUnit"
    )
    mxRequire(MXUnitSignalBars.bars === MXUnitSignalBars.baseUnit(), "testUnitSymbols: bars baseUnit")
}

func testHistogramAndAverageGetters() {
    let average = MXAverage(
        averageMeasurement: Measurement(value: 12.5, unit: MXUnitAveragePixelLuminance.apl),
        sampleCount: 4,
        standardDeviation: 1.25
    )
    mxRequire(average.averageMeasurement.value == 12.5, "testHistogramAndAverageGetters: averageMeasurement")
    mxRequire(average.sampleCount == 4, "testHistogramAndAverageGetters: sampleCount")
    mxRequire(average.standardDeviation == 1.25, "testHistogramAndAverageGetters: standardDeviation")

    let start = Measurement(value: 0, unit: UnitDuration.seconds)
    let end = Measurement(value: 1, unit: UnitDuration.seconds)
    let bucket = MXHistogramBucket(bucketStart: start, bucketEnd: end, bucketCount: 7)
    mxRequire(bucket.bucketStart.value == 0, "testHistogramAndAverageGetters: bucketStart")
    mxRequire(bucket.bucketEnd.value == 1, "testHistogramAndAverageGetters: bucketEnd")
    mxRequire(bucket.bucketCount == 7, "testHistogramAndAverageGetters: bucketCount")

    let histogram = MXHistogram(buckets: [bucket])
    mxRequire(histogram.totalBucketCount == 1, "testHistogramAndAverageGetters: totalBucketCount")
    var collected = 0
    let enumerator = histogram.bucketEnumerator
    while let object = enumerator.nextObject() {
        let item = object as? MXHistogramBucket<UnitDuration>
        mxRequire(item?.bucketCount == 7, "testHistogramAndAverageGetters: enumerated bucket")
        collected += 1
    }
    mxRequire(collected == 1, "testHistogramAndAverageGetters: bucketEnumerator")
}

// --- MXJSONTests.swift ---
func testMetricJSONRepresentation() {
    let empty = MXMetric()
    mxRequire(empty.dictionaryRepresentation().isEmpty, "testMetricJSONRepresentation: empty dict")
    let emptyJSON = mxJSONObject(empty.jsonRepresentation(), "testMetricJSONRepresentation: empty json")
    mxRequire(emptyJSON.isEmpty, "testMetricJSONRepresentation: empty json object")

    let cpu = MXCPUMetric(
        cumulativeCPUTime: Measurement(value: 5, unit: .seconds),
        cumulativeCPUInstructions: Measurement(value: 6, unit: Unit(symbol: "instr"))
    )
    let dict = cpu.dictionaryRepresentation()
    let cpuTime = mxMeasurementDict(dict["cumulativeCPUTime"])
    mxRequire(mxJSONNumber(cpuTime?["value"], equals: 5), "testMetricJSONRepresentation: cpu time")
    mxRequire((cpuTime?["unit"] as? String) == "s", "testMetricJSONRepresentation: cpu unit")
    let parsed = mxJSONObject(cpu.jsonRepresentation(), "testMetricJSONRepresentation: cpu json")
    let parsedTime = mxMeasurementDict(parsed["cumulativeCPUTime"])
    mxRequire(mxJSONNumber(parsedTime?["value"], equals: 5), "testMetricJSONRepresentation: json cpu time")
}

func testMetricPayloadJSONRepresentation() {
    let begin = Date(timeIntervalSince1970: 10)
    let end = Date(timeIntervalSince1970: 20)
    let payload = MXMetricPayload(
        latestApplicationVersion: "9",
        includesMultipleApplicationVersions: true,
        timeStampBegin: begin,
        timeStampEnd: end,
        cpuMetrics: MXCPUMetric(cumulativeCPUTime: Measurement(value: 1, unit: .seconds)),
        metaData: MXMetaData(bundleIdentifier: "payload.app")
    )
    let dict = payload.dictionaryRepresentation()
    mxRequire((dict["latestApplicationVersion"] as? String) == "9", "testMetricPayloadJSONRepresentation: version")
    mxRequire(
        mxJSONBool(dict["includesMultipleApplicationVersions"], equals: true),
        "testMetricPayloadJSONRepresentation: multi"
    )
    mxRequire(mxJSONNumber(dict["timeStampBegin"], equals: 10), "testMetricPayloadJSONRepresentation: begin")
    mxRequire(mxJSONNumber(dict["timeStampEnd"], equals: 20), "testMetricPayloadJSONRepresentation: end")
    let cpu = dict["cpuMetrics"] as? [AnyHashable: Any]
    mxRequire(cpu != nil, "testMetricPayloadJSONRepresentation: cpu nested")
    let meta = dict["metaData"] as? [AnyHashable: Any]
    mxRequire((meta?["bundleIdentifier"] as? String) == "payload.app", "testMetricPayloadJSONRepresentation: meta")

    let parsed = mxJSONObject(payload.jsonRepresentation(), "testMetricPayloadJSONRepresentation: json")
    mxRequire((parsed["latestApplicationVersion"] as? String) == "9", "testMetricPayloadJSONRepresentation: json version")
    mxRequire(mxJSONNumber(parsed["timeStampBegin"], equals: 10), "testMetricPayloadJSONRepresentation: json begin")
}

func testDiagnosticPayloadJSONRepresentation() {
    let payload = MXDiagnosticPayload(
        hangDiagnostics: [MXHangDiagnostic(hangDuration: Measurement(value: 5, unit: .seconds))],
        timeStampBegin: Date(timeIntervalSince1970: 3),
        timeStampEnd: Date(timeIntervalSince1970: 4)
    )
    let dict = payload.dictionaryRepresentation()
    mxRequire(mxJSONNumber(dict["timeStampBegin"], equals: 3), "testDiagnosticPayloadJSONRepresentation: begin")
    mxRequire(mxJSONNumber(dict["timeStampEnd"], equals: 4), "testDiagnosticPayloadJSONRepresentation: end")
    let hangs = dict["hangDiagnostics"] as? [[AnyHashable: Any]]
    mxRequire(hangs?.count == 1, "testDiagnosticPayloadJSONRepresentation: hang count")
    let hangDuration = mxMeasurementDict(hangs?.first?["hangDuration"])
    mxRequire(mxJSONNumber(hangDuration?["value"], equals: 5), "testDiagnosticPayloadJSONRepresentation: hang value")

    let parsed = mxJSONObject(payload.jsonRepresentation(), "testDiagnosticPayloadJSONRepresentation: json")
    mxRequire(mxJSONNumber(parsed["timeStampEnd"], equals: 4), "testDiagnosticPayloadJSONRepresentation: json end")
}

func testDiagnosticJSONRepresentation() {
    let meta = MXMetaData(bundleIdentifier: "diag.app", pid: 7)
    let record = MXSignpostRecord(name: "frame", isInterval: false)
    let diagnostic = MXDiagnostic(
        applicationVersion: "1.0",
        metaData: meta,
        signpostData: [record]
    )
    let dict = diagnostic.dictionaryRepresentation()
    mxRequire((dict["applicationVersion"] as? String) == "1.0", "testDiagnosticJSONRepresentation: version")
    let nestedMeta = dict["metaData"] as? [AnyHashable: Any]
    mxRequire((nestedMeta?["bundleIdentifier"] as? String) == "diag.app", "testDiagnosticJSONRepresentation: meta")
    let signposts = dict["signpostData"] as? [[AnyHashable: Any]]
    mxRequire((signposts?.first?["name"] as? String) == "frame", "testDiagnosticJSONRepresentation: signpost")

    let parsed = mxJSONObject(diagnostic.jsonRepresentation(), "testDiagnosticJSONRepresentation: json")
    mxRequire((parsed["applicationVersion"] as? String) == "1.0", "testDiagnosticJSONRepresentation: json version")
}

func testMetaDataJSONRepresentation() {
    let meta = MXMetaData(
        regionFormat: "US",
        osVersion: "Linux",
        deviceType: "test",
        applicationBuildVersion: "1",
        platformArchitecture: "x86_64",
        lowPowerModeEnabled: true,
        isTestFlightApp: false,
        pid: 42,
        bundleIdentifier: "example.app"
    )
    let dict = meta.dictionaryRepresentation()
    mxRequire((dict["regionFormat"] as? String) == "US", "testMetaDataJSONRepresentation: region")
    mxRequire((dict["osVersion"] as? String) == "Linux", "testMetaDataJSONRepresentation: os")
    mxRequire((dict["deviceType"] as? String) == "test", "testMetaDataJSONRepresentation: device")
    mxRequire((dict["applicationBuildVersion"] as? String) == "1", "testMetaDataJSONRepresentation: build")
    mxRequire((dict["platformArchitecture"] as? String) == "x86_64", "testMetaDataJSONRepresentation: arch")
    mxRequire(mxJSONBool(dict["lowPowerModeEnabled"], equals: true), "testMetaDataJSONRepresentation: low power")
    mxRequire(mxJSONBool(dict["isTestFlightApp"], equals: false), "testMetaDataJSONRepresentation: testflight")
    mxRequire(mxJSONInt(dict["pid"], equals: 42), "testMetaDataJSONRepresentation: pid")
    mxRequire((dict["bundleIdentifier"] as? String) == "example.app", "testMetaDataJSONRepresentation: bundle")

    let parsed = mxJSONObject(meta.jsonRepresentation(), "testMetaDataJSONRepresentation: json")
    mxRequire(mxJSONInt(parsed["pid"], equals: 42), "testMetaDataJSONRepresentation: json pid")
    mxRequire((parsed["bundleIdentifier"] as? String) == "example.app", "testMetaDataJSONRepresentation: json bundle")
}

func testCallStackTreeJSONRepresentation() {
    let tree = MXCallStackTree()
    let data = tree.jsonRepresentation()
    mxRequire(data == Data("{}".utf8), "testCallStackTreeJSONRepresentation: empty object bytes")
    let parsed = mxJSONObject(data, "testCallStackTreeJSONRepresentation: json")
    mxRequire(parsed.isEmpty, "testCallStackTreeJSONRepresentation: empty keys")
}

func testSignpostRecordJSONRepresentation() {
    let record = MXSignpostRecord(
        subsystem: "app",
        category: "ui",
        name: "frame",
        beginTimeStamp: Date(timeIntervalSince1970: 10),
        endTimeStamp: Date(timeIntervalSince1970: 11),
        duration: Measurement(value: 1, unit: .seconds),
        isInterval: true
    )
    let dict = record.dictionaryRepresentation()
    mxRequire((dict["subsystem"] as? String) == "app", "testSignpostRecordJSONRepresentation: subsystem")
    mxRequire((dict["category"] as? String) == "ui", "testSignpostRecordJSONRepresentation: category")
    mxRequire((dict["name"] as? String) == "frame", "testSignpostRecordJSONRepresentation: name")
    mxRequire(mxJSONNumber(dict["beginTimeStamp"], equals: 10), "testSignpostRecordJSONRepresentation: begin")
    mxRequire(mxJSONNumber(dict["endTimeStamp"], equals: 11), "testSignpostRecordJSONRepresentation: end")
    mxRequire(mxJSONBool(dict["isInterval"], equals: true), "testSignpostRecordJSONRepresentation: interval")
    let duration = mxMeasurementDict(dict["duration"])
    mxRequire(mxJSONNumber(duration?["value"], equals: 1), "testSignpostRecordJSONRepresentation: duration")

    let parsed = mxJSONObject(record.jsonRepresentation(), "testSignpostRecordJSONRepresentation: json")
    mxRequire((parsed["name"] as? String) == "frame", "testSignpostRecordJSONRepresentation: json name")
}

func testExceptionReasonJSONRepresentation() {
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(
        composedMessage: "boom",
        formatString: "%@",
        arguments: ["x"],
        exceptionType: "NSException",
        className: "Thing",
        exceptionName: "Test"
    )
    let dict = reason.dictionaryRepresentation()
    mxRequire((dict["composedMessage"] as? String) == "boom", "testExceptionReasonJSONRepresentation: composed")
    mxRequire((dict["formatString"] as? String) == "%@", "testExceptionReasonJSONRepresentation: format")
    mxRequire((dict["arguments"] as? [String]) == ["x"], "testExceptionReasonJSONRepresentation: args")
    mxRequire((dict["exceptionType"] as? String) == "NSException", "testExceptionReasonJSONRepresentation: type")
    mxRequire((dict["className"] as? String) == "Thing", "testExceptionReasonJSONRepresentation: class")
    mxRequire((dict["exceptionName"] as? String) == "Test", "testExceptionReasonJSONRepresentation: name")

    let parsed = mxJSONObject(reason.jsonRepresentation(), "testExceptionReasonJSONRepresentation: json")
    mxRequire((parsed["composedMessage"] as? String) == "boom", "testExceptionReasonJSONRepresentation: json composed")
    let parsedArgs = parsed["arguments"] as? [String]
    mxRequire(parsedArgs == ["x"], "testExceptionReasonJSONRepresentation: json args")
}

// --- MXLaunchTaskTests.swift ---
func testMXLaunchTaskID() {
    let task = MXLaunchTaskID("extended-launch")
    mxRequire(task.rawValue == "extended-launch", "testMXLaunchTaskID: rawValue")
    mxRequire(MXLaunchTaskID(rawValue: "extended-launch") == task, "testMXLaunchTaskID: init(rawValue:)")
    mxRequire(MXLaunchTaskID("other") != task, "testMXLaunchTaskID: !=")
    var hasher = Hasher()
    task.hash(into: &hasher)
    mxRequire(task.hashValue == MXLaunchTaskID("extended-launch").hashValue, "testMXLaunchTaskID: hashValue")
}

private func requireLaunchFailClosed(_ body: () throws -> Void, _ message: String) {
    do {
        try body()
        fatalError("\(message): expected throw")
    } catch let error as MXError {
        mxRequire(error.code == .launchTaskInternalFailure, "\(message): MXError.Code")
        mxRequire(error.errorCode == 5, "\(message): raw 5")
        let cocoa = error as NSError
        mxRequire(cocoa.domain == MXErrorDomain, "\(message): domain")
        mxRequire(cocoa.code == 5, "\(message): NSError code 5")
    } catch {
        fatalError("\(message): expected MXError")
    }
}

func testExtendLaunchMeasurementFailClosed() {
    requireLaunchFailClosed({
        try MXMetricManager.extendLaunchMeasurement(forTaskID: MXLaunchTaskID(""))
    }, "testExtendLaunchMeasurementFailClosed: empty")
    requireLaunchFailClosed({
        try MXMetricManager.extendLaunchMeasurement(forTaskID: MXLaunchTaskID("task"))
    }, "testExtendLaunchMeasurementFailClosed: nonempty")
}

func testFinishExtendedLaunchMeasurementFailClosed() {
    requireLaunchFailClosed({
        try MXMetricManager.finishExtendedLaunchMeasurement(forTaskID: MXLaunchTaskID(""))
    }, "testFinishExtendedLaunchMeasurementFailClosed: empty")
    requireLaunchFailClosed({
        try MXMetricManager.finishExtendedLaunchMeasurement(
            forTaskID: MXLaunchTaskID("never-started")
        )
    }, "testFinishExtendedLaunchMeasurementFailClosed: never-started")
}

// --- MXMetricGetterTests.swift ---
func testAnimationMetricGetters() {
    let animation = MXAnimationMetric(
        hitchTimeRatio: Measurement(value: 0.1, unit: Unit(symbol: "")),
        scrollHitchTimeRatio: Measurement(value: 0.2, unit: Unit(symbol: ""))
    )
    mxRequire(animation.hitchTimeRatio.value == 0.1, "testAnimationMetricGetters: hitchTimeRatio")
    mxRequire(animation.scrollHitchTimeRatio.value == 0.2, "testAnimationMetricGetters: scrollHitchTimeRatio")
}

func testAppExitMetricGetters() {
    let background = MXBackgroundExitData(
        cumulativeNormalAppExitCount: 1,
        cumulativeMemoryResourceLimitExitCount: 2,
        cumulativeCPUResourceLimitExitCount: 3,
        cumulativeMemoryPressureExitCount: 4,
        cumulativeBadAccessExitCount: 5,
        cumulativeAbnormalExitCount: 6,
        cumulativeIllegalInstructionExitCount: 7,
        cumulativeAppWatchdogExitCount: 8,
        cumulativeSuspendedWithLockedFileExitCount: 9,
        cumulativeBackgroundTaskAssertionTimeoutExitCount: 10
    )
    mxRequire(background.cumulativeNormalAppExitCount == 1, "testAppExitMetricGetters: bg normal")
    mxRequire(background.cumulativeMemoryResourceLimitExitCount == 2, "testAppExitMetricGetters: bg mem")
    mxRequire(background.cumulativeCPUResourceLimitExitCount == 3, "testAppExitMetricGetters: bg cpu")
    mxRequire(background.cumulativeMemoryPressureExitCount == 4, "testAppExitMetricGetters: bg pressure")
    mxRequire(background.cumulativeBadAccessExitCount == 5, "testAppExitMetricGetters: bg bad access")
    mxRequire(background.cumulativeAbnormalExitCount == 6, "testAppExitMetricGetters: bg abnormal")
    mxRequire(background.cumulativeIllegalInstructionExitCount == 7, "testAppExitMetricGetters: bg illegal")
    mxRequire(background.cumulativeAppWatchdogExitCount == 8, "testAppExitMetricGetters: bg watchdog")
    mxRequire(background.cumulativeSuspendedWithLockedFileExitCount == 9, "testAppExitMetricGetters: bg locked")
    mxRequire(
        background.cumulativeBackgroundTaskAssertionTimeoutExitCount == 10,
        "testAppExitMetricGetters: bg assertion"
    )

    let foreground = MXForegroundExitData(
        cumulativeNormalAppExitCount: 11,
        cumulativeMemoryResourceLimitExitCount: 12,
        cumulativeBadAccessExitCount: 13,
        cumulativeAbnormalExitCount: 14,
        cumulativeIllegalInstructionExitCount: 15,
        cumulativeAppWatchdogExitCount: 16
    )
    mxRequire(foreground.cumulativeNormalAppExitCount == 11, "testAppExitMetricGetters: fg normal")
    mxRequire(foreground.cumulativeMemoryResourceLimitExitCount == 12, "testAppExitMetricGetters: fg mem")
    mxRequire(foreground.cumulativeBadAccessExitCount == 13, "testAppExitMetricGetters: fg bad access")
    mxRequire(foreground.cumulativeAbnormalExitCount == 14, "testAppExitMetricGetters: fg abnormal")
    mxRequire(foreground.cumulativeIllegalInstructionExitCount == 15, "testAppExitMetricGetters: fg illegal")
    mxRequire(foreground.cumulativeAppWatchdogExitCount == 16, "testAppExitMetricGetters: fg watchdog")

    let exits = MXAppExitMetric(foregroundExitData: foreground, backgroundExitData: background)
    mxRequire(exits.foregroundExitData.cumulativeNormalAppExitCount == 11, "testAppExitMetricGetters: exit fg")
    mxRequire(exits.backgroundExitData.cumulativeNormalAppExitCount == 1, "testAppExitMetricGetters: exit bg")
}

func testAppLaunchMetricGetters() {
    let launch = MXAppLaunchMetric()
    mxRequire(launch.histogrammedTimeToFirstDraw.totalBucketCount == 0, "testAppLaunchMetricGetters: ttfd")
    mxRequire(launch.histogrammedApplicationResumeTime.totalBucketCount == 0, "testAppLaunchMetricGetters: resume")
    mxRequire(
        launch.histogrammedOptimizedTimeToFirstDraw.totalBucketCount == 0,
        "testAppLaunchMetricGetters: optimized"
    )
    mxRequire(launch.histogrammedExtendedLaunch.totalBucketCount == 0, "testAppLaunchMetricGetters: extended")
}

func testAppResponsivenessMetricGetters() {
    let responsiveness = MXAppResponsivenessMetric()
    mxRequire(
        responsiveness.histogrammedApplicationHangTime.totalBucketCount == 0,
        "testAppResponsivenessMetricGetters: hang hist"
    )
}

func testAppRunTimeMetricGetters() {
    let runtime = MXAppRunTimeMetric(
        cumulativeForegroundTime: Measurement(value: 1, unit: .seconds),
        cumulativeBackgroundTime: Measurement(value: 2, unit: .seconds),
        cumulativeBackgroundAudioTime: Measurement(value: 3, unit: .seconds),
        cumulativeBackgroundLocationTime: Measurement(value: 4, unit: .seconds)
    )
    mxRequire(runtime.cumulativeForegroundTime.value == 1, "testAppRunTimeMetricGetters: fg time")
    mxRequire(runtime.cumulativeBackgroundTime.value == 2, "testAppRunTimeMetricGetters: bg time")
    mxRequire(runtime.cumulativeBackgroundAudioTime.value == 3, "testAppRunTimeMetricGetters: bg audio")
    mxRequire(runtime.cumulativeBackgroundLocationTime.value == 4, "testAppRunTimeMetricGetters: bg location")
}

func testCPUMetricGetters() {
    let cpu = MXCPUMetric(
        cumulativeCPUTime: Measurement(value: 5, unit: .seconds),
        cumulativeCPUInstructions: Measurement(value: 6, unit: Unit(symbol: ""))
    )
    mxRequire(cpu.cumulativeCPUTime.value == 5, "testCPUMetricGetters: cpu time")
    mxRequire(cpu.cumulativeCPUInstructions.value == 6, "testCPUMetricGetters: cpu instr")
}

func testGPUMetricGetters() {
    let gpu = MXGPUMetric(cumulativeGPUTime: Measurement(value: 7, unit: .seconds))
    mxRequire(gpu.cumulativeGPUTime.value == 7, "testGPUMetricGetters: gpu")
}

func testCellularConditionMetricGetters() {
    let cellular = MXCellularConditionMetric()
    mxRequire(
        cellular.histogrammedCellularConditionTime.totalBucketCount == 0,
        "testCellularConditionMetricGetters: cellular"
    )
}

func testDiskIOMetricGetters() {
    let disk = MXDiskIOMetric(cumulativeLogicalWrites: Measurement(value: 8, unit: .bytes))
    mxRequire(disk.cumulativeLogicalWrites.value == 8, "testDiskIOMetricGetters: disk writes")
}

func testDiskSpaceUsageMetricGetters() {
    let space = MXDiskSpaceUsageMetric(
        totalBinaryFileCount: 1,
        totalBinaryFileSize: Measurement(value: 2, unit: .bytes),
        totalDataFileCount: 3,
        totalDataFileSize: Measurement(value: 4, unit: .bytes),
        totalCacheFolderSize: Measurement(value: 5, unit: .bytes),
        totalCloneSize: Measurement(value: 6, unit: .bytes),
        totalDiskSpaceUsedSize: Measurement(value: 7, unit: .bytes),
        totalDiskSpaceCapacity: Measurement(value: 8, unit: .bytes)
    )
    mxRequire(space.totalBinaryFileCount == 1, "testDiskSpaceUsageMetricGetters: bin count")
    mxRequire(space.totalBinaryFileSize.value == 2, "testDiskSpaceUsageMetricGetters: bin size")
    mxRequire(space.totalDataFileCount == 3, "testDiskSpaceUsageMetricGetters: data count")
    mxRequire(space.totalDataFileSize.value == 4, "testDiskSpaceUsageMetricGetters: data size")
    mxRequire(space.totalCacheFolderSize.value == 5, "testDiskSpaceUsageMetricGetters: cache")
    mxRequire(space.totalCloneSize.value == 6, "testDiskSpaceUsageMetricGetters: clone")
    mxRequire(space.totalDiskSpaceUsedSize.value == 7, "testDiskSpaceUsageMetricGetters: used")
    mxRequire(space.totalDiskSpaceCapacity.value == 8, "testDiskSpaceUsageMetricGetters: capacity")
}

func testDisplayMetricGetters() {
    let displayAverage = MXAverage(
        averageMeasurement: Measurement(value: 9, unit: MXUnitAveragePixelLuminance.apl)
    )
    let display = MXDisplayMetric(averagePixelLuminance: displayAverage)
    mxRequire(display.averagePixelLuminance?.averageMeasurement.value == 9, "testDisplayMetricGetters: display")
    mxRequire(MXDisplayMetric().averagePixelLuminance == nil, "testDisplayMetricGetters: display nil")
}

func testLocationActivityMetricGetters() {
    let location = MXLocationActivityMetric(
        cumulativeBestAccuracyForNavigationTime: Measurement(value: 1, unit: .seconds),
        cumulativeBestAccuracyTime: Measurement(value: 2, unit: .seconds),
        cumulativeNearestTenMetersAccuracyTime: Measurement(value: 3, unit: .seconds),
        cumulativeHundredMetersAccuracyTime: Measurement(value: 4, unit: .seconds),
        cumulativeKilometerAccuracyTime: Measurement(value: 5, unit: .seconds),
        cumulativeThreeKilometersAccuracyTime: Measurement(value: 6, unit: .seconds)
    )
    mxRequire(location.cumulativeBestAccuracyForNavigationTime.value == 1, "testLocationActivityMetricGetters: nav")
    mxRequire(location.cumulativeBestAccuracyTime.value == 2, "testLocationActivityMetricGetters: best")
    mxRequire(location.cumulativeNearestTenMetersAccuracyTime.value == 3, "testLocationActivityMetricGetters: 10m")
    mxRequire(location.cumulativeHundredMetersAccuracyTime.value == 4, "testLocationActivityMetricGetters: 100m")
    mxRequire(location.cumulativeKilometerAccuracyTime.value == 5, "testLocationActivityMetricGetters: 1km")
    mxRequire(location.cumulativeThreeKilometersAccuracyTime.value == 6, "testLocationActivityMetricGetters: 3km")
}

func testMemoryMetricGetters() {
    let memory = MXMemoryMetric(peakMemoryUsage: Measurement(value: 10, unit: .bytes))
    mxRequire(memory.peakMemoryUsage.value == 10, "testMemoryMetricGetters: peak")
    mxRequire(memory.averageSuspendedMemory.sampleCount == 0, "testMemoryMetricGetters: suspended")
}

func testNetworkTransferMetricGetters() {
    let network = MXNetworkTransferMetric(
        cumulativeWifiUpload: Measurement(value: 1, unit: .bytes),
        cumulativeWifiDownload: Measurement(value: 2, unit: .bytes),
        cumulativeCellularUpload: Measurement(value: 3, unit: .bytes),
        cumulativeCellularDownload: Measurement(value: 4, unit: .bytes)
    )
    mxRequire(network.cumulativeWifiUpload.value == 1, "testNetworkTransferMetricGetters: wifi up")
    mxRequire(network.cumulativeWifiDownload.value == 2, "testNetworkTransferMetricGetters: wifi down")
    mxRequire(network.cumulativeCellularUpload.value == 3, "testNetworkTransferMetricGetters: cell up")
    mxRequire(network.cumulativeCellularDownload.value == 4, "testNetworkTransferMetricGetters: cell down")
}

func testSignpostMetricGetters() {
    let interval = MXSignpostIntervalData(
        histogrammedSignpostDuration: MXHistogram(),
        cumulativeCPUTime: Measurement(value: 1, unit: .seconds),
        averageMemory: MXAverage(averageMeasurement: Measurement(value: 2, unit: .bytes)),
        cumulativeLogicalWrites: Measurement(value: 3, unit: .bytes),
        cumulativeHitchTimeRatio: Measurement(value: 4, unit: Unit(symbol: ""))
    )
    mxRequire(
        interval.histogrammedSignpostDuration.totalBucketCount == 0,
        "testSignpostMetricGetters: signpost hist"
    )
    mxRequire(interval.cumulativeCPUTime?.value == 1, "testSignpostMetricGetters: signpost cpu")
    mxRequire(interval.averageMemory?.averageMeasurement.value == 2, "testSignpostMetricGetters: signpost mem")
    mxRequire(interval.cumulativeLogicalWrites?.value == 3, "testSignpostMetricGetters: signpost writes")
    mxRequire(interval.cumulativeHitchTimeRatio?.value == 4, "testSignpostMetricGetters: signpost hitch")

    let signpost = MXSignpostMetric(
        signpostName: "draw",
        signpostCategory: "ui",
        signpostIntervalData: interval,
        totalCount: 3
    )
    mxRequire(signpost.signpostName == "draw", "testSignpostMetricGetters: signpost name")
    mxRequire(signpost.signpostCategory == "ui", "testSignpostMetricGetters: signpost category")
    mxRequire(signpost.signpostIntervalData === interval, "testSignpostMetricGetters: signpost interval")
    mxRequire(signpost.totalCount == 3, "testSignpostMetricGetters: signpost count")
}

// --- MXMetricManagerTests.swift ---
func testSharedManagerAndEmptyPayloads() {
    mxRequire(MXMetricManager.shared === MXMetricManager.shared, "testSharedManagerAndEmptyPayloads: shared")
    mxRequire(MXMetricManager.shared.pastPayloads.isEmpty, "testSharedManagerAndEmptyPayloads: pastPayloads")
    mxRequire(
        MXMetricManager.shared.pastDiagnosticPayloads.isEmpty,
        "testSharedManagerAndEmptyPayloads: pastDiagnosticPayloads"
    )
}

private final class MXDeinitBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _deinited = false

    var deinited: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _deinited
    }

    func mark() {
        lock.lock()
        _deinited = true
        lock.unlock()
    }
}

private final class MXLifetimeSubscriber: NSObject, MXMetricManagerSubscriber {
    let box: MXDeinitBox

    init(box: MXDeinitBox) {
        self.box = box
        super.init()
    }

    deinit {
        box.mark()
    }
}

func testSubscriberAddRemoveRetention() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let box = MXDeinitBox()
    weak var weakSubscriber: MXLifetimeSubscriber?
    do {
        let subscriber = MXLifetimeSubscriber(box: box)
        weakSubscriber = subscriber
        MXMetricManager.shared.add(subscriber)
        MXMetricManager.shared.add(subscriber)
    }
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 1,
        "testSubscriberAddRemoveRetention: idempotent add"
    )
    mxRequire(weakSubscriber != nil, "testSubscriberAddRemoveRetention: strong retention")
    mxRequire(!box.deinited, "testSubscriberAddRemoveRetention: not deinited while retained")
    mxRequire(
        MXMetricManager.shared._portableContains(weakSubscriber!),
        "testSubscriberAddRemoveRetention: contains"
    )
    let probe = MXCountingSubscriber()
    MXMetricManager.shared.add(probe)
    mxRequire(probe.metricDeliveries == 0, "testSubscriberAddRemoveRetention: no metric telemetry")
    mxRequire(probe.diagnosticDeliveries == 0, "testSubscriberAddRemoveRetention: no diagnostic telemetry")
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 2,
        "testSubscriberAddRemoveRetention: two subscribers"
    )
    MXMetricManager.shared.remove(probe)
    MXMetricManager.shared.remove(weakSubscriber!)
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 0,
        "testSubscriberAddRemoveRetention: count after remove"
    )
    mxRequire(weakSubscriber == nil, "testSubscriberAddRemoveRetention: released after remove")
    mxRequire(box.deinited, "testSubscriberAddRemoveRetention: deinit after remove")
}

private final class MXSubscriberList: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [MXCountingSubscriber] = []

    func append(_ subscriber: MXCountingSubscriber) {
        lock.lock()
        items.append(subscriber)
        lock.unlock()
    }

    func snapshot() -> [MXCountingSubscriber] {
        lock.lock()
        let copy = items
        lock.unlock()
        return copy
    }
}

func testSubscriberConcurrentAddRemove() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "metrickit.subscribers", attributes: .concurrent)
    let live = MXSubscriberList()
    for _ in 0..<64 {
        queue.async(group: group) {
            let subscriber = MXCountingSubscriber()
            MXMetricManager.shared.add(subscriber)
            MXMetricManager.shared.add(subscriber)
            live.append(subscriber)
        }
    }
    group.wait()
    let items = live.snapshot()
    mxRequire(items.count == 64, "testSubscriberConcurrentAddRemove: live count")
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 64,
        "testSubscriberConcurrentAddRemove: unique adds"
    )
    for subscriber in items {
        queue.async(group: group) {
            MXMetricManager.shared.remove(subscriber)
            MXMetricManager.shared.remove(subscriber)
        }
    }
    group.wait()
    mxRequire(
        MXMetricManager.shared._portableSubscriberCount == 0,
        "testSubscriberConcurrentAddRemove: released"
    )
}

// --- MXPayloadTests.swift ---
func testMetricPayloadGetters() {
    let begin = Date(timeIntervalSince1970: 1)
    let end = Date(timeIntervalSince1970: 2)
    let payload = MXMetricPayload(
        latestApplicationVersion: "9",
        includesMultipleApplicationVersions: true,
        timeStampBegin: begin,
        timeStampEnd: end,
        cpuMetrics: MXCPUMetric(),
        gpuMetrics: MXGPUMetric(),
        cellularConditionMetrics: MXCellularConditionMetric(),
        applicationTimeMetrics: MXAppRunTimeMetric(),
        locationActivityMetrics: MXLocationActivityMetric(),
        networkTransferMetrics: MXNetworkTransferMetric(),
        applicationLaunchMetrics: MXAppLaunchMetric(),
        applicationResponsivenessMetrics: MXAppResponsivenessMetric(),
        diskIOMetrics: MXDiskIOMetric(),
        memoryMetrics: MXMemoryMetric(),
        displayMetrics: MXDisplayMetric(),
        animationMetrics: MXAnimationMetric(),
        applicationExitMetrics: MXAppExitMetric(),
        diskSpaceUsageMetrics: MXDiskSpaceUsageMetric(),
        signpostMetrics: [MXSignpostMetric(signpostName: "n")],
        metaData: MXMetaData(bundleIdentifier: "payload.app")
    )
    mxRequire(payload.latestApplicationVersion == "9", "testMetricPayloadGetters: version")
    mxRequire(payload.includesMultipleApplicationVersions, "testMetricPayloadGetters: multi")
    mxRequire(payload.timeStampBegin == begin, "testMetricPayloadGetters: begin")
    mxRequire(payload.timeStampEnd == end, "testMetricPayloadGetters: end")
    mxRequire(payload.cpuMetrics != nil, "testMetricPayloadGetters: cpu")
    mxRequire(payload.gpuMetrics != nil, "testMetricPayloadGetters: gpu")
    mxRequire(payload.cellularConditionMetrics != nil, "testMetricPayloadGetters: cellular")
    mxRequire(payload.applicationTimeMetrics != nil, "testMetricPayloadGetters: time")
    mxRequire(payload.locationActivityMetrics != nil, "testMetricPayloadGetters: location")
    mxRequire(payload.networkTransferMetrics != nil, "testMetricPayloadGetters: network")
    mxRequire(payload.applicationLaunchMetrics != nil, "testMetricPayloadGetters: launch")
    mxRequire(payload.applicationResponsivenessMetrics != nil, "testMetricPayloadGetters: resp")
    mxRequire(payload.diskIOMetrics != nil, "testMetricPayloadGetters: diskio")
    mxRequire(payload.memoryMetrics != nil, "testMetricPayloadGetters: memory")
    mxRequire(payload.displayMetrics != nil, "testMetricPayloadGetters: display")
    mxRequire(payload.animationMetrics != nil, "testMetricPayloadGetters: animation")
    mxRequire(payload.applicationExitMetrics != nil, "testMetricPayloadGetters: exits")
    mxRequire(payload.diskSpaceUsageMetrics != nil, "testMetricPayloadGetters: space")
    mxRequire(payload.signpostMetrics?.count == 1, "testMetricPayloadGetters: signposts")
    mxRequire(payload.metaData?.bundleIdentifier == "payload.app", "testMetricPayloadGetters: meta")
}

func testDiagnosticPayloadGetters() {
    let diagBegin = Date(timeIntervalSince1970: 3)
    let diagEnd = Date(timeIntervalSince1970: 4)
    let diagnostics = MXDiagnosticPayload(
        cpuExceptionDiagnostics: [MXCPUExceptionDiagnostic()],
        diskWriteExceptionDiagnostics: [MXDiskWriteExceptionDiagnostic()],
        hangDiagnostics: [MXHangDiagnostic()],
        appLaunchDiagnostics: [MXAppLaunchDiagnostic()],
        crashDiagnostics: [MXCrashDiagnostic()],
        timeStampBegin: diagBegin,
        timeStampEnd: diagEnd
    )
    mxRequire(diagnostics.cpuExceptionDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag cpu")
    mxRequire(diagnostics.diskWriteExceptionDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag disk")
    mxRequire(diagnostics.hangDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag hang")
    mxRequire(diagnostics.appLaunchDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag launch")
    mxRequire(diagnostics.crashDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag crash")
    mxRequire(diagnostics.timeStampBegin == diagBegin, "testDiagnosticPayloadGetters: diag begin")
    mxRequire(diagnostics.timeStampEnd == diagEnd, "testDiagnosticPayloadGetters: diag end")
}

// --- MXSubscriberTests.swift ---
func testSubscriberDidReceiveMetricPayloads() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let defaults = MXDefaultingSubscriber()
    defaults.didReceive([MXMetricPayload]())
    defaults.didReceive([MXMetricPayload(latestApplicationVersion: "1")])

    let counting = MXCountingSubscriber()
    MXMetricManager.shared.add(counting)
    mxRequire(counting.metricDeliveries == 0, "testSubscriberDidReceiveMetricPayloads: manager silent")
    counting.didReceive([MXMetricPayload(), MXMetricPayload()])
    mxRequire(counting.metricDeliveries == 2, "testSubscriberDidReceiveMetricPayloads: direct call")
    mxRequire(counting.diagnosticDeliveries == 0, "testSubscriberDidReceiveMetricPayloads: no diagnostic mix")
    MXMetricManager.shared.remove(counting)
}

func testSubscriberDidReceiveDiagnosticPayloads() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let defaults = MXDefaultingSubscriber()
    defaults.didReceive([MXDiagnosticPayload]())
    defaults.didReceive([MXDiagnosticPayload()])

    let counting = MXCountingSubscriber()
    MXMetricManager.shared.add(counting)
    mxRequire(
        counting.diagnosticDeliveries == 0,
        "testSubscriberDidReceiveDiagnosticPayloads: manager silent"
    )
    counting.didReceive([MXDiagnosticPayload()])
    mxRequire(counting.diagnosticDeliveries == 1, "testSubscriberDidReceiveDiagnosticPayloads: direct call")
    mxRequire(counting.metricDeliveries == 0, "testSubscriberDidReceiveDiagnosticPayloads: no metric mix")
    MXMetricManager.shared.remove(counting)
}

// --- MetricKitSupportTests.swift ---
func mxRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

final class MXDummyCoder: NSCoder {}

final class MXDefaultingSubscriber: NSObject, MXMetricManagerSubscriber {}

final class MXCountingSubscriber: NSObject, MXMetricManagerSubscriber {
    var metricDeliveries = 0
    var diagnosticDeliveries = 0

    func didReceive(_ payloads: [MXMetricPayload]) {
        metricDeliveries += payloads.count
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        diagnosticDeliveries += payloads.count
    }
}

func mxJSONObject(_ data: Data, _ message: String) -> [String: Any] {
    do {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = object as? [String: Any] else {
            fatalError("\(message): JSON is not an object")
        }
        return dictionary
    } catch {
        fatalError("\(message): \(error)")
    }
}

func mxJSONNumber(_ value: Any?, equals expected: Double) -> Bool {
    if let number = value as? NSNumber {
        return number.doubleValue == expected
    }
    if let number = value as? Double {
        return number == expected
    }
    if let number = value as? Int {
        return Double(number) == expected
    }
    return false
}

func mxJSONInt(_ value: Any?, equals expected: Int) -> Bool {
    if let number = value as? NSNumber {
        return number.intValue == expected
    }
    if let number = value as? Int {
        return number == expected
    }
    return false
}

func mxJSONBool(_ value: Any?, equals expected: Bool) -> Bool {
    if let flag = value as? Bool {
        return flag == expected
    }
    if let number = value as? NSNumber {
        return number.boolValue == expected
    }
    return false
}

func mxMeasurementDict(_ value: Any?) -> [String: Any]? {
    value as? [String: Any]
}

testSupportInitWithCoder()
testMetricInitWithCoder()
testDiagnosticInitWithCoder()
testPayloadInitWithCoder()
testMetaDataGetters()
testSignpostRecordGetters()
testExceptionReasonGetters()
testMXCrashDiagnosticObjectiveCExceptionReasonClassName()
testDiagnosticGetters()
testAppLaunchDiagnosticGetters()
testCPUExceptionDiagnosticGetters()
testCrashDiagnosticGetters()
testDiskWriteExceptionDiagnosticGetters()
testHangDiagnosticGetters()
testCallStackTreeType()
testMXErrorCodeRawValues()
testMXErrorDomainAndBridging()
testUnitSymbols()
testHistogramAndAverageGetters()
testMetricJSONRepresentation()
testMetricPayloadJSONRepresentation()
testDiagnosticPayloadJSONRepresentation()
testDiagnosticJSONRepresentation()
testMetaDataJSONRepresentation()
testCallStackTreeJSONRepresentation()
testSignpostRecordJSONRepresentation()
testExceptionReasonJSONRepresentation()
testMXLaunchTaskID()
testExtendLaunchMeasurementFailClosed()
testFinishExtendedLaunchMeasurementFailClosed()
testAnimationMetricGetters()
testAppExitMetricGetters()
testAppLaunchMetricGetters()
testAppResponsivenessMetricGetters()
testAppRunTimeMetricGetters()
testCPUMetricGetters()
testGPUMetricGetters()
testCellularConditionMetricGetters()
testDiskIOMetricGetters()
testDiskSpaceUsageMetricGetters()
testDisplayMetricGetters()
testLocationActivityMetricGetters()
testMemoryMetricGetters()
testNetworkTransferMetricGetters()
testSignpostMetricGetters()
testSharedManagerAndEmptyPayloads()
testSubscriberAddRemoveRetention()
testSubscriberConcurrentAddRemove()
testMetricPayloadGetters()
testDiagnosticPayloadGetters()
testSubscriberDidReceiveMetricPayloads()
testSubscriberDidReceiveDiagnosticPayloads()
print("METRICKIT_AGENT_RUNTIME_OK")

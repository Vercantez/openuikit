@_spi(OpenUIKitHost) import MetricKit
import Foundation

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

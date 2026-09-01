@_spi(OpenUIKitHost) import MetricKit
import Foundation

private final class DummyCoder: NSCoder {}

private final class ProbeSubscriber: NSObject, MXMetricManagerSubscriber {
    var metricDeliveries = 0
    var diagnosticDeliveries = 0

    func didReceive(_ payloads: [MXMetricPayload]) {
        metricDeliveries += payloads.count
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        diagnosticDeliveries += payloads.count
    }
}

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func collectBuckets<UnitType: Unit>(_ histogram: MXHistogram<UnitType>) -> [MXHistogramBucket<UnitType>] {
    var result: [MXHistogramBucket<UnitType>] = []
    let enumerator = histogram.bucketEnumerator
    while let object = enumerator.nextObject() {
        guard let bucket = object as? MXHistogramBucket<UnitType> else {
            fatalError("histogram enumerator yielded a non-bucket")
        }
        result.append(bucket)
    }
    return result
}

private func exerciseErrors() {
    require(MXErrorDomain == MXError.errorDomain, "error domain mismatch")
    require(MXError.Code.launchTaskUnknown.rawValue == 0, "unknown raw value")
    require(MXError.Code.launchTaskInvalidID.rawValue == 1, "invalid ID raw value")
    require(MXError.Code.launchTaskDuplicated.rawValue == 2, "duplicated raw value")
    require(MXError.Code.launchTaskInternalFailure.rawValue == 3, "internal failure raw value")
    require(MXError.Code.launchTaskMaxCount.rawValue == 4, "max count raw value")
    require(MXError.Code.launchTaskPastDeadline.rawValue == 5, "past deadline raw value")
    require(MXError.Code(rawValue: 3) == .launchTaskInternalFailure, "rawValue init")
    require(MXError.Code(rawValue: 99) == nil, "invalid rawValue")

    require(MXError.launchTaskUnknown == .launchTaskUnknown, "static unknown")
    require(MXError.launchTaskInvalidID == .launchTaskInvalidID, "static invalid")
    require(MXError.launchTaskDuplicated == .launchTaskDuplicated, "static duplicated")
    require(MXError.launchTaskInternalFailure == .launchTaskInternalFailure, "static internal")
    require(MXError.launchTaskMaxCount == .launchTaskMaxCount, "static max")
    require(MXError.launchTaskPastDeadline == .launchTaskPastDeadline, "static deadline")

    let error = MXError(.launchTaskInternalFailure, userInfo: ["reason": "linux"])
    require(error.code == .launchTaskInternalFailure, "stored code")
    require(error.errorCode == 3, "errorCode")
    require((error.userInfo["reason"] as? String) == "linux", "userInfo")
    require((error.errorUserInfo["reason"] as? String) == "linux", "errorUserInfo")
    require(!error.localizedDescription.isEmpty, "localizedDescription")
    require(error.hashValue == MXError(.launchTaskInternalFailure).hashValue, "hash ignores userInfo")
    require(error != MXError(.launchTaskUnknown), "inequality")
    require(MXError(.launchTaskDuplicated) == MXError(.launchTaskDuplicated), "equality")

    var hasher = Hasher()
    error.hash(into: &hasher)
    MXError.Code.launchTaskMaxCount.hash(into: &hasher)
    require(MXError.Code.launchTaskMaxCount.hashValue != 0 || MXError.Code.launchTaskMaxCount.rawValue == 4, "code hash")

    require(MXError.Code.launchTaskInternalFailure ~= error, "pattern match ~=")
}

private func exerciseLaunchTasks() {
    let task = MXLaunchTaskID("extended-launch")
    require(task.rawValue == "extended-launch", "rawValue")
    require(MXLaunchTaskID(rawValue: "extended-launch") == task, "rawValue init equality")
    require(MXLaunchTaskID("other") != task, "launch task inequality")
    var hasher = Hasher()
    task.hash(into: &hasher)
    require(task.hashValue == MXLaunchTaskID("extended-launch").hashValue, "launch task hash")

    do {
        try MXMetricManager.extendLaunchMeasurement(forTaskID: task)
        fatalError("extendLaunchMeasurement must fail closed")
    } catch let error as MXError {
        require(error.code == .launchTaskInternalFailure, "extend error")
    } catch {
        fatalError("extendLaunchMeasurement must throw MXError")
    }

    do {
        try MXMetricManager.finishExtendedLaunchMeasurement(forTaskID: task)
        fatalError("finishExtendedLaunchMeasurement must fail closed")
    } catch let error as MXError {
        require(error.code == .launchTaskUnknown, "finish error")
    } catch {
        fatalError("finishExtendedLaunchMeasurement must throw MXError")
    }
}

private func exerciseManager() {
    require(MXMetricManager.shared === MXMetricManager.shared, "shared identity")
    require(MXMetricManager.shared.pastPayloads.isEmpty, "pastPayloads must be empty")
    require(MXMetricManager.shared.pastDiagnosticPayloads.isEmpty, "pastDiagnosticPayloads must be empty")

    let subscriber = ProbeSubscriber()
    MXMetricManager.shared.add(subscriber)
    require(MXMetricManager.shared._portableSubscriberCount == 1, "add subscriber")
    require(subscriber.metricDeliveries == 0, "no metric telemetry")
    require(subscriber.diagnosticDeliveries == 0, "no diagnostic telemetry")
    MXMetricManager.shared.add(subscriber)
    require(MXMetricManager.shared._portableSubscriberCount == 1, "duplicate add is idempotent")
    MXMetricManager.shared.remove(subscriber)
    require(MXMetricManager.shared._portableSubscriberCount == 0, "remove subscriber")
}

private func exerciseUnitsAndAggregates() {
    require(MXUnitAveragePixelLuminance.apl === MXUnitAveragePixelLuminance.baseUnit(), "apl base unit")
    require(MXUnitAveragePixelLuminance.apl.symbol == "apl", "apl symbol")
    require(MXUnitSignalBars.bars === MXUnitSignalBars.baseUnit(), "bars base unit")
    require(MXUnitSignalBars.bars.symbol == "bars", "bars symbol")

    let average = MXAverage(
        averageMeasurement: Measurement(value: 12.5, unit: MXUnitAveragePixelLuminance.apl),
        sampleCount: 4,
        standardDeviation: 1.25
    )
    require(average.averageMeasurement.value == 12.5, "average value")
    require(average.sampleCount == 4, "sample count")
    require(average.standardDeviation == 1.25, "std dev")
    require(type(of: average).init(coder: DummyCoder()) == nil, "average coder fail-closed")

    let start = Measurement(value: 0, unit: UnitDuration.seconds)
    let end = Measurement(value: 1, unit: UnitDuration.seconds)
    let bucket = MXHistogramBucket(bucketStart: start, bucketEnd: end, bucketCount: 7)
    require(bucket.bucketStart.value == 0, "bucket start")
    require(bucket.bucketEnd.value == 1, "bucket end")
    require(bucket.bucketCount == 7, "bucket count")
    require(type(of: bucket).init(coder: DummyCoder()) == nil, "bucket coder fail-closed")

    let histogram = MXHistogram(buckets: [bucket])
    require(histogram.totalBucketCount == 1, "histogram count")
    let collected = collectBuckets(histogram)
    require(collected.count == 1, "enumerator count")
    require(collected[0].bucketCount == 7, "enumerated bucket")
    require(MXHistogram<UnitDuration>().totalBucketCount == 0, "empty histogram")
    require(type(of: histogram).init(coder: DummyCoder()) == nil, "histogram coder fail-closed")
}

private func exerciseMetrics() {
    let animation = MXAnimationMetric(
        hitchTimeRatio: Measurement(value: 0.1, unit: Unit(symbol: "")),
        scrollHitchTimeRatio: Measurement(value: 0.2, unit: Unit(symbol: ""))
    )
    require(animation.hitchTimeRatio.value == 0.1, "hitch")
    require(animation.scrollHitchTimeRatio.value == 0.2, "scroll hitch")
    require(!animation.jsonRepresentation().isEmpty, "animation json")
    require(!animation.dictionaryRepresentation().isEmpty, "animation dict")
    require(type(of: animation).init(coder: DummyCoder()) == nil, "animation coder")

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
    require(background.cumulativeNormalAppExitCount == 1, "bg normal")
    require(background.cumulativeMemoryResourceLimitExitCount == 2, "bg mem limit")
    require(background.cumulativeCPUResourceLimitExitCount == 3, "bg cpu")
    require(background.cumulativeMemoryPressureExitCount == 4, "bg pressure")
    require(background.cumulativeBadAccessExitCount == 5, "bg bad access")
    require(background.cumulativeAbnormalExitCount == 6, "bg abnormal")
    require(background.cumulativeIllegalInstructionExitCount == 7, "bg illegal")
    require(background.cumulativeAppWatchdogExitCount == 8, "bg watchdog")
    require(background.cumulativeSuspendedWithLockedFileExitCount == 9, "bg locked")
    require(background.cumulativeBackgroundTaskAssertionTimeoutExitCount == 10, "bg assertion")
    require(type(of: background).init(coder: DummyCoder()) == nil, "bg coder")

    let foreground = MXForegroundExitData(
        cumulativeNormalAppExitCount: 11,
        cumulativeMemoryResourceLimitExitCount: 12,
        cumulativeBadAccessExitCount: 13,
        cumulativeAbnormalExitCount: 14,
        cumulativeIllegalInstructionExitCount: 15,
        cumulativeAppWatchdogExitCount: 16
    )
    require(foreground.cumulativeNormalAppExitCount == 11, "fg normal")
    require(foreground.cumulativeMemoryResourceLimitExitCount == 12, "fg mem")
    require(foreground.cumulativeBadAccessExitCount == 13, "fg bad access")
    require(foreground.cumulativeAbnormalExitCount == 14, "fg abnormal")
    require(foreground.cumulativeIllegalInstructionExitCount == 15, "fg illegal")
    require(foreground.cumulativeAppWatchdogExitCount == 16, "fg watchdog")
    require(type(of: foreground).init(coder: DummyCoder()) == nil, "fg coder")

    let exits = MXAppExitMetric(foregroundExitData: foreground, backgroundExitData: background)
    require(exits.foregroundExitData.cumulativeNormalAppExitCount == 11, "exit fg")
    require(exits.backgroundExitData.cumulativeNormalAppExitCount == 1, "exit bg")

    let launch = MXAppLaunchMetric()
    require(launch.histogrammedTimeToFirstDraw.totalBucketCount == 0, "ttfd")
    require(launch.histogrammedApplicationResumeTime.totalBucketCount == 0, "resume")
    require(launch.histogrammedOptimizedTimeToFirstDraw.totalBucketCount == 0, "optimized")
    require(launch.histogrammedExtendedLaunch.totalBucketCount == 0, "extended")

    let responsiveness = MXAppResponsivenessMetric()
    require(responsiveness.histogrammedApplicationHangTime.totalBucketCount == 0, "hang histogram")

    let runtime = MXAppRunTimeMetric(
        cumulativeForegroundTime: Measurement(value: 1, unit: .seconds),
        cumulativeBackgroundTime: Measurement(value: 2, unit: .seconds),
        cumulativeBackgroundAudioTime: Measurement(value: 3, unit: .seconds),
        cumulativeBackgroundLocationTime: Measurement(value: 4, unit: .seconds)
    )
    require(runtime.cumulativeForegroundTime.value == 1, "fg time")
    require(runtime.cumulativeBackgroundTime.value == 2, "bg time")
    require(runtime.cumulativeBackgroundAudioTime.value == 3, "bg audio")
    require(runtime.cumulativeBackgroundLocationTime.value == 4, "bg location")

    let cpu = MXCPUMetric(
        cumulativeCPUTime: Measurement(value: 5, unit: .seconds),
        cumulativeCPUInstructions: Measurement(value: 6, unit: Unit(symbol: ""))
    )
    require(cpu.cumulativeCPUTime.value == 5, "cpu time")
    require(cpu.cumulativeCPUInstructions.value == 6, "cpu instr")

    let gpu = MXGPUMetric(cumulativeGPUTime: Measurement(value: 7, unit: .seconds))
    require(gpu.cumulativeGPUTime.value == 7, "gpu")

    let cellular = MXCellularConditionMetric()
    require(cellular.histogrammedCellularConditionTime.totalBucketCount == 0, "cellular")

    let disk = MXDiskIOMetric(cumulativeLogicalWrites: Measurement(value: 8, unit: .bytes))
    require(disk.cumulativeLogicalWrites.value == 8, "disk writes")

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
    require(space.totalBinaryFileCount == 1, "bin count")
    require(space.totalBinaryFileSize.value == 2, "bin size")
    require(space.totalDataFileCount == 3, "data count")
    require(space.totalDataFileSize.value == 4, "data size")
    require(space.totalCacheFolderSize.value == 5, "cache")
    require(space.totalCloneSize.value == 6, "clone")
    require(space.totalDiskSpaceUsedSize.value == 7, "used")
    require(space.totalDiskSpaceCapacity.value == 8, "capacity")

    let displayAverage = MXAverage(
        averageMeasurement: Measurement(value: 9, unit: MXUnitAveragePixelLuminance.apl)
    )
    let display = MXDisplayMetric(averagePixelLuminance: displayAverage)
    require(display.averagePixelLuminance?.sampleCount == 0, "display average")
    require(MXDisplayMetric().averagePixelLuminance == nil, "display nil")

    let location = MXLocationActivityMetric(
        cumulativeBestAccuracyForNavigationTime: Measurement(value: 1, unit: .seconds),
        cumulativeBestAccuracyTime: Measurement(value: 2, unit: .seconds),
        cumulativeNearestTenMetersAccuracyTime: Measurement(value: 3, unit: .seconds),
        cumulativeHundredMetersAccuracyTime: Measurement(value: 4, unit: .seconds),
        cumulativeKilometerAccuracyTime: Measurement(value: 5, unit: .seconds),
        cumulativeThreeKilometersAccuracyTime: Measurement(value: 6, unit: .seconds)
    )
    require(location.cumulativeBestAccuracyForNavigationTime.value == 1, "nav")
    require(location.cumulativeBestAccuracyTime.value == 2, "best")
    require(location.cumulativeNearestTenMetersAccuracyTime.value == 3, "10m")
    require(location.cumulativeHundredMetersAccuracyTime.value == 4, "100m")
    require(location.cumulativeKilometerAccuracyTime.value == 5, "1km")
    require(location.cumulativeThreeKilometersAccuracyTime.value == 6, "3km")

    let memory = MXMemoryMetric(
        peakMemoryUsage: Measurement(value: 10, unit: .bytes)
    )
    require(memory.peakMemoryUsage.value == 10, "peak")
    require(memory.averageSuspendedMemory.sampleCount == 0, "suspended")

    let network = MXNetworkTransferMetric(
        cumulativeWifiUpload: Measurement(value: 1, unit: .bytes),
        cumulativeWifiDownload: Measurement(value: 2, unit: .bytes),
        cumulativeCellularUpload: Measurement(value: 3, unit: .bytes),
        cumulativeCellularDownload: Measurement(value: 4, unit: .bytes)
    )
    require(network.cumulativeWifiUpload.value == 1, "wifi up")
    require(network.cumulativeWifiDownload.value == 2, "wifi down")
    require(network.cumulativeCellularUpload.value == 3, "cell up")
    require(network.cumulativeCellularDownload.value == 4, "cell down")

    let interval = MXSignpostIntervalData(
        histogrammedSignpostDuration: MXHistogram(),
        cumulativeCPUTime: Measurement(value: 1, unit: .seconds),
        averageMemory: MXAverage(averageMeasurement: Measurement(value: 2, unit: .bytes)),
        cumulativeLogicalWrites: Measurement(value: 3, unit: .bytes),
        cumulativeHitchTimeRatio: Measurement(value: 4, unit: Unit(symbol: ""))
    )
    require(interval.histogrammedSignpostDuration.totalBucketCount == 0, "signpost hist")
    require(interval.cumulativeCPUTime?.value == 1, "signpost cpu")
    require(interval.averageMemory?.averageMeasurement.value == 2, "signpost mem")
    require(interval.cumulativeLogicalWrites?.value == 3, "signpost writes")
    require(interval.cumulativeHitchTimeRatio?.value == 4, "signpost hitch")
    require(type(of: interval).init(coder: DummyCoder()) == nil, "interval coder")

    let signpost = MXSignpostMetric(
        signpostName: "draw",
        signpostCategory: "ui",
        signpostIntervalData: interval,
        totalCount: 3
    )
    require(signpost.signpostName == "draw", "signpost name")
    require(signpost.signpostCategory == "ui", "signpost category")
    require(signpost.signpostIntervalData === interval, "signpost interval")
    require(signpost.totalCount == 3, "signpost count")

    require(type(of: MXMetric()).init(coder: DummyCoder()) == nil, "metric coder")
    require(type(of: MXCPUMetric()).init(coder: DummyCoder()) == nil, "cpu coder")
}

private func exerciseDiagnostics() {
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
    require(meta.regionFormat == "US", "region")
    require(meta.osVersion == "Linux", "os")
    require(meta.deviceType == "test", "device")
    require(meta.applicationBuildVersion == "1", "build")
    require(meta.platformArchitecture == "x86_64", "arch")
    require(meta.lowPowerModeEnabled, "low power")
    require(!meta.isTestFlightApp, "testflight")
    require(meta.pid == 42, "pid")
    require(meta.bundleIdentifier == "example.app", "bundle")
    require(!meta.jsonRepresentation().isEmpty, "meta json")
    require(!meta.dictionaryRepresentation().isEmpty, "meta dict")
    require(type(of: meta).init(coder: DummyCoder()) == nil, "meta coder")

    let tree = MXCallStackTree()
    require(String(data: tree.jsonRepresentation(), encoding: .utf8) == "{}", "empty call stack")
    require(type(of: tree).init(coder: DummyCoder()) == nil, "tree coder")

    let record = MXSignpostRecord(
        subsystem: "app",
        category: "ui",
        name: "frame",
        beginTimeStamp: Date(timeIntervalSince1970: 10),
        endTimeStamp: Date(timeIntervalSince1970: 11),
        duration: Measurement(value: 1, unit: .seconds),
        isInterval: true
    )
    require(record.subsystem == "app", "record subsystem")
    require(record.category == "ui", "record category")
    require(record.name == "frame", "record name")
    require(record.beginTimeStamp.timeIntervalSince1970 == 10, "record begin")
    require(record.endTimeStamp?.timeIntervalSince1970 == 11, "record end")
    require(record.duration?.value == 1, "record duration")
    require(record.isInterval, "record interval")
    require(!record.jsonRepresentation().isEmpty, "record json")
    require(type(of: record).init(coder: DummyCoder()) == nil, "record coder")

    let reason = MXCrashDiagnosticObjectiveCExceptionReason(
        composedMessage: "boom",
        formatString: "%@",
        arguments: ["x"],
        exceptionType: "NSException",
        className: "Thing",
        exceptionName: "Test"
    )
    require(reason.composedMessage == "boom", "composed")
    require(reason.formatString == "%@", "format")
    require(reason.arguments == ["x"], "args")
    require(reason.exceptionType == "NSException", "exc type")
    require(reason.className == "Thing", "class")
    require(reason.exceptionName == "Test", "name")
    require(!reason.dictionaryRepresentation().isEmpty, "reason dict")
    require(type(of: reason).init(coder: DummyCoder()) == nil, "reason coder")

    let diagnostic = MXDiagnostic(
        applicationVersion: "1.0",
        metaData: meta,
        signpostData: [record]
    )
    require(diagnostic.applicationVersion == "1.0", "diag version")
    require(diagnostic.metaData.pid == 42, "diag meta")
    require(diagnostic.signpostData?.count == 1, "diag signposts")
    require(!diagnostic.jsonRepresentation().isEmpty, "diag json")
    require(type(of: diagnostic).init(coder: DummyCoder()) == nil, "diag coder")

    let launch = MXAppLaunchDiagnostic(launchDuration: Measurement(value: 2, unit: .seconds))
    require(launch.launchDuration.value == 2, "launch duration")
    require(String(data: launch.callStackTree.jsonRepresentation(), encoding: .utf8) == "{}", "launch tree")
    require(type(of: launch).init(coder: DummyCoder()) == nil, "launch diag coder")

    let cpuExc = MXCPUExceptionDiagnostic(
        totalCPUTime: Measurement(value: 3, unit: .seconds),
        totalSampledTime: Measurement(value: 4, unit: .seconds)
    )
    require(cpuExc.totalCPUTime.value == 3, "cpu exc time")
    require(cpuExc.totalSampledTime.value == 4, "cpu sampled")
    require(type(of: cpuExc).init(coder: DummyCoder()) == nil, "cpu exc coder")

    let crash = MXCrashDiagnostic(
        terminationReason: "signal",
        virtualMemoryRegionInfo: "stack",
        exceptionType: 1,
        exceptionCode: 2,
        signal: 11,
        exceptionReason: reason
    )
    require(crash.terminationReason == "signal", "term")
    require(crash.virtualMemoryRegionInfo == "stack", "vm")
    require(crash.exceptionType == 1, "crash type")
    require(crash.exceptionCode == 2, "crash code")
    require(crash.signal == 11, "crash signal")
    require(crash.exceptionReason?.exceptionName == "Test", "crash reason")
    require(type(of: crash).init(coder: DummyCoder()) == nil, "crash coder")

    let disk = MXDiskWriteExceptionDiagnostic(
        totalWritesCaused: Measurement(value: 9, unit: .bytes)
    )
    require(disk.totalWritesCaused.value == 9, "writes caused")
    require(type(of: disk).init(coder: DummyCoder()) == nil, "disk write coder")

    let hang = MXHangDiagnostic(hangDuration: Measurement(value: 5, unit: .seconds))
    require(hang.hangDuration.value == 5, "hang duration")
    require(type(of: hang).init(coder: DummyCoder()) == nil, "hang coder")
}

private func exercisePayloads() {
    let cpu = MXCPUMetric()
    let gpu = MXGPUMetric()
    let payload = MXMetricPayload(
        latestApplicationVersion: "9",
        includesMultipleApplicationVersions: true,
        timeStampBegin: Date(timeIntervalSince1970: 1),
        timeStampEnd: Date(timeIntervalSince1970: 2),
        cpuMetrics: cpu,
        gpuMetrics: gpu,
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
    require(payload.latestApplicationVersion == "9", "payload version")
    require(payload.includesMultipleApplicationVersions, "payload multi")
    require(payload.timeStampBegin.timeIntervalSince1970 == 1, "payload begin")
    require(payload.timeStampEnd.timeIntervalSince1970 == 2, "payload end")
    require(payload.cpuMetrics != nil, "payload cpu")
    require(payload.gpuMetrics != nil, "payload gpu")
    require(payload.cellularConditionMetrics != nil, "payload cellular")
    require(payload.applicationTimeMetrics != nil, "payload time")
    require(payload.locationActivityMetrics != nil, "payload location")
    require(payload.networkTransferMetrics != nil, "payload network")
    require(payload.applicationLaunchMetrics != nil, "payload launch")
    require(payload.applicationResponsivenessMetrics != nil, "payload resp")
    require(payload.diskIOMetrics != nil, "payload diskio")
    require(payload.memoryMetrics != nil, "payload memory")
    require(payload.displayMetrics != nil, "payload display")
    require(payload.animationMetrics != nil, "payload animation")
    require(payload.applicationExitMetrics != nil, "payload exits")
    require(payload.diskSpaceUsageMetrics != nil, "payload space")
    require(payload.signpostMetrics?.count == 1, "payload signposts")
    require(payload.metaData?.bundleIdentifier == "payload.app", "payload meta")
    require(!payload.jsonRepresentation().isEmpty, "payload json")
    require(!payload.dictionaryRepresentation().isEmpty, "payload dict")
    require(type(of: payload).init(coder: DummyCoder()) == nil, "payload coder")

    let diagnostics = MXDiagnosticPayload(
        cpuExceptionDiagnostics: [MXCPUExceptionDiagnostic()],
        diskWriteExceptionDiagnostics: [MXDiskWriteExceptionDiagnostic()],
        hangDiagnostics: [MXHangDiagnostic()],
        appLaunchDiagnostics: [MXAppLaunchDiagnostic()],
        crashDiagnostics: [MXCrashDiagnostic()],
        timeStampBegin: Date(timeIntervalSince1970: 3),
        timeStampEnd: Date(timeIntervalSince1970: 4)
    )
    require(diagnostics.cpuExceptionDiagnostics?.count == 1, "diag cpu")
    require(diagnostics.diskWriteExceptionDiagnostics?.count == 1, "diag disk")
    require(diagnostics.hangDiagnostics?.count == 1, "diag hang")
    require(diagnostics.appLaunchDiagnostics?.count == 1, "diag launch")
    require(diagnostics.crashDiagnostics?.count == 1, "diag crash")
    require(diagnostics.timeStampBegin.timeIntervalSince1970 == 3, "diag begin")
    require(diagnostics.timeStampEnd.timeIntervalSince1970 == 4, "diag end")
    require(!diagnostics.jsonRepresentation().isEmpty, "diag payload json")
    require(type(of: diagnostics).init(coder: DummyCoder()) == nil, "diag payload coder")
}

exerciseErrors()
exerciseLaunchTasks()
exerciseManager()
exerciseUnitsAndAggregates()
exerciseMetrics()
exerciseDiagnostics()
exercisePayloads()
print("METRICKIT_AGENT_RUNTIME_OK")

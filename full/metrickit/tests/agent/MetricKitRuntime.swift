@_spi(OpenUIKitHost) import MetricKit
import Foundation
import Dispatch

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

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

private final class DeinitBox: @unchecked Sendable {
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

private final class LifetimeSubscriber: NSObject, MXMetricManagerSubscriber {
    let box: DeinitBox

    init(box: DeinitBox) {
        self.box = box
        super.init()
    }

    deinit {
        box.mark()
    }
}

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

private func testMXErrorCodeRawValues() {
    require(mxErrorCodeMappings.count == 6, "testMXErrorCodeRawValues: every mapping")
    var seenRaw = Set<Int>()
    for mapping in mxErrorCodeMappings {
        require(
            mapping.code.rawValue == mapping.rawValue,
            "testMXErrorCodeRawValues: \(mapping.name) rawValue"
        )
        require(
            MXError.Code(rawValue: mapping.rawValue) == mapping.code,
            "testMXErrorCodeRawValues: \(mapping.name) init(rawValue:)"
        )
        require(
            mapping.staticAlias == mapping.code,
            "testMXErrorCodeRawValues: \(mapping.name) static alias"
        )
        require(
            MXError(mapping.code).errorCode == mapping.rawValue,
            "testMXErrorCodeRawValues: \(mapping.name) errorCode"
        )
        require(
            seenRaw.insert(mapping.rawValue).inserted,
            "testMXErrorCodeRawValues: \(mapping.name) unique raw"
        )
    }
    require(MXError.Code(rawValue: 99) == nil, "testMXErrorCodeRawValues: invalid rawValue")
}

private func testMXErrorDomainAndBridging() {
    require(MXErrorDomain == "MXErrorDomain", "testMXErrorDomainAndBridging: MXErrorDomain")
    require(MXError.errorDomain == MXErrorDomain, "testMXErrorDomainAndBridging: errorDomain")
    let error = MXError(.launchTaskInternalFailure, userInfo: ["reason": "linux"])
    require(error.code == .launchTaskInternalFailure, "testMXErrorDomainAndBridging: code")
    require(error.errorCode == 5, "testMXErrorDomainAndBridging: errorCode 5")
    require((error.userInfo["reason"] as? String) == "linux", "testMXErrorDomainAndBridging: userInfo")
    require((error.errorUserInfo["reason"] as? String) == "linux", "testMXErrorDomainAndBridging: errorUserInfo")
    require(!error.localizedDescription.isEmpty, "testMXErrorDomainAndBridging: localizedDescription")
    require(error == MXError(.launchTaskInternalFailure, userInfo: ["reason": "linux"]), "testMXErrorDomainAndBridging: ==")
    require(error != MXError(.launchTaskUnknown), "testMXErrorDomainAndBridging: !=")
    require(error.hashValue == MXError(.launchTaskInternalFailure).hashValue, "testMXErrorDomainAndBridging: hashValue")
    var hasher = Hasher()
    error.hash(into: &hasher)
    MXError.Code.launchTaskMaxCount.hash(into: &hasher)
    _ = MXError.Code.launchTaskMaxCount.hashValue
    require(MXError.Code.launchTaskInternalFailure ~= error, "testMXErrorDomainAndBridging: ~=")
    let cocoa = error as NSError
    require(cocoa.domain == MXErrorDomain, "testMXErrorDomainAndBridging: NSError.domain")
    require(cocoa.code == 5, "testMXErrorDomainAndBridging: NSError.code")
}

private func testMXLaunchTaskID() {
    let task = MXLaunchTaskID("extended-launch")
    require(task.rawValue == "extended-launch", "testMXLaunchTaskID: rawValue")
    require(MXLaunchTaskID(rawValue: "extended-launch") == task, "testMXLaunchTaskID: init(rawValue:)")
    require(MXLaunchTaskID("other") != task, "testMXLaunchTaskID: !=")
    var hasher = Hasher()
    task.hash(into: &hasher)
    require(task.hashValue == MXLaunchTaskID("extended-launch").hashValue, "testMXLaunchTaskID: hashValue")
}

private func requireLaunchFailClosed(_ body: () throws -> Void, _ message: String) {
    do {
        try body()
        fatalError("\(message): expected throw")
    } catch let error as MXError {
        require(error.code == .launchTaskInternalFailure, "\(message): MXError.Code")
        require(error.errorCode == 5, "\(message): raw 5")
        let cocoa = error as NSError
        require(cocoa.domain == MXErrorDomain, "\(message): domain")
        require(cocoa.code == 5, "\(message): NSError code 5")
    } catch {
        fatalError("\(message): expected MXError")
    }
}

private func testLaunchMeasurementFailClosed() {
    // Linux has no MetricKit service. Fail closed with the corrected identity
    // (MXErrorDomain code 5). On the pinned simulator, extend of an empty task
    // ID returned success, while an immediate finish of that ID and of a
    // never-started ID threw domain MXErrorDomain code 5. That finite
    // observation is not a universal daemon contract; Linux does not fabricate
    // extend success.
    requireLaunchFailClosed({
        try MXMetricManager.extendLaunchMeasurement(forTaskID: MXLaunchTaskID(""))
    }, "testLaunchMeasurementFailClosed: extend empty")
    requireLaunchFailClosed({
        try MXMetricManager.extendLaunchMeasurement(forTaskID: MXLaunchTaskID("task"))
    }, "testLaunchMeasurementFailClosed: extend nonempty")
    requireLaunchFailClosed({
        try MXMetricManager.finishExtendedLaunchMeasurement(forTaskID: MXLaunchTaskID(""))
    }, "testLaunchMeasurementFailClosed: immediate finish empty")
    requireLaunchFailClosed({
        try MXMetricManager.finishExtendedLaunchMeasurement(
            forTaskID: MXLaunchTaskID("never-started")
        )
    }, "testLaunchMeasurementFailClosed: immediate finish never-started")
}

private func testSharedManagerAndEmptyPayloads() {
    require(MXMetricManager.shared === MXMetricManager.shared, "testSharedManagerAndEmptyPayloads: shared")
    require(MXMetricManager.shared.pastPayloads.isEmpty, "testSharedManagerAndEmptyPayloads: pastPayloads")
    require(
        MXMetricManager.shared.pastDiagnosticPayloads.isEmpty,
        "testSharedManagerAndEmptyPayloads: pastDiagnosticPayloads"
    )
}

private func testSubscriberRetentionIdempotentRelease() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let box = DeinitBox()
    weak var weakSubscriber: LifetimeSubscriber?
    do {
        let subscriber = LifetimeSubscriber(box: box)
        weakSubscriber = subscriber
        MXMetricManager.shared.add(subscriber)
        MXMetricManager.shared.add(subscriber)
    }
    require(MXMetricManager.shared._portableSubscriberCount == 1, "testSubscriberRetentionIdempotentRelease: idempotent add")
    require(weakSubscriber != nil, "testSubscriberRetentionIdempotentRelease: strong retention")
    require(!box.deinited, "testSubscriberRetentionIdempotentRelease: not deinited while retained")
    require(MXMetricManager.shared._portableContains(weakSubscriber!), "testSubscriberRetentionIdempotentRelease: contains")
    let probe = ProbeSubscriber()
    MXMetricManager.shared.add(probe)
    require(probe.metricDeliveries == 0, "testSubscriberRetentionIdempotentRelease: no metric telemetry")
    require(probe.diagnosticDeliveries == 0, "testSubscriberRetentionIdempotentRelease: no diagnostic telemetry")
    require(MXMetricManager.shared._portableSubscriberCount == 2, "testSubscriberRetentionIdempotentRelease: two subscribers")
    MXMetricManager.shared.remove(probe)
    MXMetricManager.shared.remove(weakSubscriber!)
    require(MXMetricManager.shared._portableSubscriberCount == 0, "testSubscriberRetentionIdempotentRelease: count after remove")
    require(weakSubscriber == nil, "testSubscriberRetentionIdempotentRelease: released after remove")
    require(box.deinited, "testSubscriberRetentionIdempotentRelease: deinit after remove")
}

private final class SubscriberList: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [ProbeSubscriber] = []

    func append(_ subscriber: ProbeSubscriber) {
        lock.lock()
        items.append(subscriber)
        lock.unlock()
    }

    func snapshot() -> [ProbeSubscriber] {
        lock.lock()
        let copy = items
        lock.unlock()
        return copy
    }
}

private func testSubscriberConcurrentAddRemove() {
    MXMetricManager.shared._portableRemoveAllSubscribers()
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "metrickit.subscribers", attributes: .concurrent)
    let live = SubscriberList()
    for _ in 0..<64 {
        queue.async(group: group) {
            let subscriber = ProbeSubscriber()
            MXMetricManager.shared.add(subscriber)
            MXMetricManager.shared.add(subscriber)
            live.append(subscriber)
        }
    }
    group.wait()
    let items = live.snapshot()
    require(items.count == 64, "testSubscriberConcurrentAddRemove: live count")
    require(MXMetricManager.shared._portableSubscriberCount == 64, "testSubscriberConcurrentAddRemove: unique adds")
    for subscriber in items {
        queue.async(group: group) {
            MXMetricManager.shared.remove(subscriber)
            MXMetricManager.shared.remove(subscriber)
        }
    }
    group.wait()
    require(MXMetricManager.shared._portableSubscriberCount == 0, "testSubscriberConcurrentAddRemove: released")
}

private func testUnitSymbols() {
    require(MXUnitAveragePixelLuminance.apl.symbol == "apl", "testUnitSymbols: apl")
    require(MXUnitSignalBars.bars.symbol == "bars", "testUnitSymbols: bars")
    require(
        MXUnitAveragePixelLuminance.apl === MXUnitAveragePixelLuminance.baseUnit(),
        "testUnitSymbols: apl baseUnit"
    )
    require(MXUnitSignalBars.bars === MXUnitSignalBars.baseUnit(), "testUnitSymbols: bars baseUnit")
}

private func testHistogramAndAverageGetters() {
    let average = MXAverage(
        averageMeasurement: Measurement(value: 12.5, unit: MXUnitAveragePixelLuminance.apl),
        sampleCount: 4,
        standardDeviation: 1.25
    )
    require(average.averageMeasurement.value == 12.5, "testHistogramAndAverageGetters: averageMeasurement")
    require(average.sampleCount == 4, "testHistogramAndAverageGetters: sampleCount")
    require(average.standardDeviation == 1.25, "testHistogramAndAverageGetters: standardDeviation")

    let start = Measurement(value: 0, unit: UnitDuration.seconds)
    let end = Measurement(value: 1, unit: UnitDuration.seconds)
    let bucket = MXHistogramBucket(bucketStart: start, bucketEnd: end, bucketCount: 7)
    require(bucket.bucketStart.value == 0, "testHistogramAndAverageGetters: bucketStart")
    require(bucket.bucketEnd.value == 1, "testHistogramAndAverageGetters: bucketEnd")
    require(bucket.bucketCount == 7, "testHistogramAndAverageGetters: bucketCount")

    let histogram = MXHistogram(buckets: [bucket])
    require(histogram.totalBucketCount == 1, "testHistogramAndAverageGetters: totalBucketCount")
    var collected = 0
    let enumerator = histogram.bucketEnumerator
    while let object = enumerator.nextObject() {
        let item = object as? MXHistogramBucket<UnitDuration>
        require(item?.bucketCount == 7, "testHistogramAndAverageGetters: enumerated bucket")
        collected += 1
    }
    require(collected == 1, "testHistogramAndAverageGetters: bucketEnumerator")
}

private func testMetricGetters() {
    let animation = MXAnimationMetric(
        hitchTimeRatio: Measurement(value: 0.1, unit: Unit(symbol: "")),
        scrollHitchTimeRatio: Measurement(value: 0.2, unit: Unit(symbol: ""))
    )
    require(animation.hitchTimeRatio.value == 0.1, "testMetricGetters: hitchTimeRatio")
    require(animation.scrollHitchTimeRatio.value == 0.2, "testMetricGetters: scrollHitchTimeRatio")

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
    require(background.cumulativeNormalAppExitCount == 1, "testMetricGetters: bg normal")
    require(background.cumulativeMemoryResourceLimitExitCount == 2, "testMetricGetters: bg mem")
    require(background.cumulativeCPUResourceLimitExitCount == 3, "testMetricGetters: bg cpu")
    require(background.cumulativeMemoryPressureExitCount == 4, "testMetricGetters: bg pressure")
    require(background.cumulativeBadAccessExitCount == 5, "testMetricGetters: bg bad access")
    require(background.cumulativeAbnormalExitCount == 6, "testMetricGetters: bg abnormal")
    require(background.cumulativeIllegalInstructionExitCount == 7, "testMetricGetters: bg illegal")
    require(background.cumulativeAppWatchdogExitCount == 8, "testMetricGetters: bg watchdog")
    require(background.cumulativeSuspendedWithLockedFileExitCount == 9, "testMetricGetters: bg locked")
    require(background.cumulativeBackgroundTaskAssertionTimeoutExitCount == 10, "testMetricGetters: bg assertion")

    let foreground = MXForegroundExitData(
        cumulativeNormalAppExitCount: 11,
        cumulativeMemoryResourceLimitExitCount: 12,
        cumulativeBadAccessExitCount: 13,
        cumulativeAbnormalExitCount: 14,
        cumulativeIllegalInstructionExitCount: 15,
        cumulativeAppWatchdogExitCount: 16
    )
    require(foreground.cumulativeNormalAppExitCount == 11, "testMetricGetters: fg normal")
    require(foreground.cumulativeMemoryResourceLimitExitCount == 12, "testMetricGetters: fg mem")
    require(foreground.cumulativeBadAccessExitCount == 13, "testMetricGetters: fg bad access")
    require(foreground.cumulativeAbnormalExitCount == 14, "testMetricGetters: fg abnormal")
    require(foreground.cumulativeIllegalInstructionExitCount == 15, "testMetricGetters: fg illegal")
    require(foreground.cumulativeAppWatchdogExitCount == 16, "testMetricGetters: fg watchdog")

    let exits = MXAppExitMetric(foregroundExitData: foreground, backgroundExitData: background)
    require(exits.foregroundExitData.cumulativeNormalAppExitCount == 11, "testMetricGetters: exit fg")
    require(exits.backgroundExitData.cumulativeNormalAppExitCount == 1, "testMetricGetters: exit bg")

    let launch = MXAppLaunchMetric()
    require(launch.histogrammedTimeToFirstDraw.totalBucketCount == 0, "testMetricGetters: ttfd")
    require(launch.histogrammedApplicationResumeTime.totalBucketCount == 0, "testMetricGetters: resume")
    require(launch.histogrammedOptimizedTimeToFirstDraw.totalBucketCount == 0, "testMetricGetters: optimized")
    require(launch.histogrammedExtendedLaunch.totalBucketCount == 0, "testMetricGetters: extended")

    let responsiveness = MXAppResponsivenessMetric()
    require(responsiveness.histogrammedApplicationHangTime.totalBucketCount == 0, "testMetricGetters: hang hist")

    let runtime = MXAppRunTimeMetric(
        cumulativeForegroundTime: Measurement(value: 1, unit: .seconds),
        cumulativeBackgroundTime: Measurement(value: 2, unit: .seconds),
        cumulativeBackgroundAudioTime: Measurement(value: 3, unit: .seconds),
        cumulativeBackgroundLocationTime: Measurement(value: 4, unit: .seconds)
    )
    require(runtime.cumulativeForegroundTime.value == 1, "testMetricGetters: fg time")
    require(runtime.cumulativeBackgroundTime.value == 2, "testMetricGetters: bg time")
    require(runtime.cumulativeBackgroundAudioTime.value == 3, "testMetricGetters: bg audio")
    require(runtime.cumulativeBackgroundLocationTime.value == 4, "testMetricGetters: bg location")

    let cpu = MXCPUMetric(
        cumulativeCPUTime: Measurement(value: 5, unit: .seconds),
        cumulativeCPUInstructions: Measurement(value: 6, unit: Unit(symbol: ""))
    )
    require(cpu.cumulativeCPUTime.value == 5, "testMetricGetters: cpu time")
    require(cpu.cumulativeCPUInstructions.value == 6, "testMetricGetters: cpu instr")

    let gpu = MXGPUMetric(cumulativeGPUTime: Measurement(value: 7, unit: .seconds))
    require(gpu.cumulativeGPUTime.value == 7, "testMetricGetters: gpu")

    let cellular = MXCellularConditionMetric()
    require(cellular.histogrammedCellularConditionTime.totalBucketCount == 0, "testMetricGetters: cellular")

    let disk = MXDiskIOMetric(cumulativeLogicalWrites: Measurement(value: 8, unit: .bytes))
    require(disk.cumulativeLogicalWrites.value == 8, "testMetricGetters: disk writes")

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
    require(space.totalBinaryFileCount == 1, "testMetricGetters: bin count")
    require(space.totalBinaryFileSize.value == 2, "testMetricGetters: bin size")
    require(space.totalDataFileCount == 3, "testMetricGetters: data count")
    require(space.totalDataFileSize.value == 4, "testMetricGetters: data size")
    require(space.totalCacheFolderSize.value == 5, "testMetricGetters: cache")
    require(space.totalCloneSize.value == 6, "testMetricGetters: clone")
    require(space.totalDiskSpaceUsedSize.value == 7, "testMetricGetters: used")
    require(space.totalDiskSpaceCapacity.value == 8, "testMetricGetters: capacity")

    let displayAverage = MXAverage(
        averageMeasurement: Measurement(value: 9, unit: MXUnitAveragePixelLuminance.apl)
    )
    let display = MXDisplayMetric(averagePixelLuminance: displayAverage)
    require(display.averagePixelLuminance?.averageMeasurement.value == 9, "testMetricGetters: display")
    require(MXDisplayMetric().averagePixelLuminance == nil, "testMetricGetters: display nil")

    let location = MXLocationActivityMetric(
        cumulativeBestAccuracyForNavigationTime: Measurement(value: 1, unit: .seconds),
        cumulativeBestAccuracyTime: Measurement(value: 2, unit: .seconds),
        cumulativeNearestTenMetersAccuracyTime: Measurement(value: 3, unit: .seconds),
        cumulativeHundredMetersAccuracyTime: Measurement(value: 4, unit: .seconds),
        cumulativeKilometerAccuracyTime: Measurement(value: 5, unit: .seconds),
        cumulativeThreeKilometersAccuracyTime: Measurement(value: 6, unit: .seconds)
    )
    require(location.cumulativeBestAccuracyForNavigationTime.value == 1, "testMetricGetters: nav")
    require(location.cumulativeBestAccuracyTime.value == 2, "testMetricGetters: best")
    require(location.cumulativeNearestTenMetersAccuracyTime.value == 3, "testMetricGetters: 10m")
    require(location.cumulativeHundredMetersAccuracyTime.value == 4, "testMetricGetters: 100m")
    require(location.cumulativeKilometerAccuracyTime.value == 5, "testMetricGetters: 1km")
    require(location.cumulativeThreeKilometersAccuracyTime.value == 6, "testMetricGetters: 3km")

    let memory = MXMemoryMetric(peakMemoryUsage: Measurement(value: 10, unit: .bytes))
    require(memory.peakMemoryUsage.value == 10, "testMetricGetters: peak")
    require(memory.averageSuspendedMemory.sampleCount == 0, "testMetricGetters: suspended")

    let network = MXNetworkTransferMetric(
        cumulativeWifiUpload: Measurement(value: 1, unit: .bytes),
        cumulativeWifiDownload: Measurement(value: 2, unit: .bytes),
        cumulativeCellularUpload: Measurement(value: 3, unit: .bytes),
        cumulativeCellularDownload: Measurement(value: 4, unit: .bytes)
    )
    require(network.cumulativeWifiUpload.value == 1, "testMetricGetters: wifi up")
    require(network.cumulativeWifiDownload.value == 2, "testMetricGetters: wifi down")
    require(network.cumulativeCellularUpload.value == 3, "testMetricGetters: cell up")
    require(network.cumulativeCellularDownload.value == 4, "testMetricGetters: cell down")

    let interval = MXSignpostIntervalData(
        histogrammedSignpostDuration: MXHistogram(),
        cumulativeCPUTime: Measurement(value: 1, unit: .seconds),
        averageMemory: MXAverage(averageMeasurement: Measurement(value: 2, unit: .bytes)),
        cumulativeLogicalWrites: Measurement(value: 3, unit: .bytes),
        cumulativeHitchTimeRatio: Measurement(value: 4, unit: Unit(symbol: ""))
    )
    require(interval.histogrammedSignpostDuration.totalBucketCount == 0, "testMetricGetters: signpost hist")
    require(interval.cumulativeCPUTime?.value == 1, "testMetricGetters: signpost cpu")
    require(interval.averageMemory?.averageMeasurement.value == 2, "testMetricGetters: signpost mem")
    require(interval.cumulativeLogicalWrites?.value == 3, "testMetricGetters: signpost writes")
    require(interval.cumulativeHitchTimeRatio?.value == 4, "testMetricGetters: signpost hitch")

    let signpost = MXSignpostMetric(
        signpostName: "draw",
        signpostCategory: "ui",
        signpostIntervalData: interval,
        totalCount: 3
    )
    require(signpost.signpostName == "draw", "testMetricGetters: signpost name")
    require(signpost.signpostCategory == "ui", "testMetricGetters: signpost category")
    require(signpost.signpostIntervalData === interval, "testMetricGetters: signpost interval")
    require(signpost.totalCount == 3, "testMetricGetters: signpost count")
}

private func testDiagnosticGetters() {
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
    require(meta.regionFormat == "US", "testDiagnosticGetters: region")
    require(meta.osVersion == "Linux", "testDiagnosticGetters: os")
    require(meta.deviceType == "test", "testDiagnosticGetters: device")
    require(meta.applicationBuildVersion == "1", "testDiagnosticGetters: build")
    require(meta.platformArchitecture == "x86_64", "testDiagnosticGetters: arch")
    require(meta.lowPowerModeEnabled, "testDiagnosticGetters: low power")
    require(!meta.isTestFlightApp, "testDiagnosticGetters: testflight")
    require(meta.pid == 42, "testDiagnosticGetters: pid")
    require(meta.bundleIdentifier == "example.app", "testDiagnosticGetters: bundle")

    let tree = MXCallStackTree()
    let record = MXSignpostRecord(
        subsystem: "app",
        category: "ui",
        name: "frame",
        beginTimeStamp: Date(timeIntervalSince1970: 10),
        endTimeStamp: Date(timeIntervalSince1970: 11),
        duration: Measurement(value: 1, unit: .seconds),
        isInterval: true
    )
    require(record.subsystem == "app", "testDiagnosticGetters: record subsystem")
    require(record.category == "ui", "testDiagnosticGetters: record category")
    require(record.name == "frame", "testDiagnosticGetters: record name")
    require(record.beginTimeStamp.timeIntervalSince1970 == 10, "testDiagnosticGetters: record begin")
    require(record.endTimeStamp?.timeIntervalSince1970 == 11, "testDiagnosticGetters: record end")
    require(record.duration?.value == 1, "testDiagnosticGetters: record duration")
    require(record.isInterval, "testDiagnosticGetters: record interval")

    let reason = MXCrashDiagnosticObjectiveCExceptionReason(
        composedMessage: "boom",
        formatString: "%@",
        arguments: ["x"],
        exceptionType: "NSException",
        className: "Thing",
        exceptionName: "Test"
    )
    require(reason.composedMessage == "boom", "testDiagnosticGetters: composed")
    require(reason.formatString == "%@", "testDiagnosticGetters: format")
    require(reason.arguments == ["x"], "testDiagnosticGetters: args")
    require(reason.exceptionType == "NSException", "testDiagnosticGetters: exc type")
    require(reason.className == "Thing", "testDiagnosticGetters: class")
    require(reason.exceptionName == "Test", "testDiagnosticGetters: name")

    let diagnostic = MXDiagnostic(applicationVersion: "1.0", metaData: meta, signpostData: [record])
    require(diagnostic.applicationVersion == "1.0", "testDiagnosticGetters: version")
    require(diagnostic.metaData.pid == 42, "testDiagnosticGetters: meta")
    require(diagnostic.signpostData?.count == 1, "testDiagnosticGetters: signposts")

    let launch = MXAppLaunchDiagnostic(callStackTree: tree, launchDuration: Measurement(value: 2, unit: .seconds))
    require(launch.launchDuration.value == 2, "testDiagnosticGetters: launch duration")
    require(launch.callStackTree === tree, "testDiagnosticGetters: launch tree")

    let cpuExc = MXCPUExceptionDiagnostic(
        totalCPUTime: Measurement(value: 3, unit: .seconds),
        totalSampledTime: Measurement(value: 4, unit: .seconds)
    )
    require(cpuExc.totalCPUTime.value == 3, "testDiagnosticGetters: cpu time")
    require(cpuExc.totalSampledTime.value == 4, "testDiagnosticGetters: sampled")
    require(cpuExc.callStackTree !== tree, "testDiagnosticGetters: cpu tree")

    let crash = MXCrashDiagnostic(
        callStackTree: tree,
        terminationReason: "signal",
        virtualMemoryRegionInfo: "stack",
        exceptionType: NSNumber(value: 1),
        exceptionCode: NSNumber(value: 2),
        signal: NSNumber(value: 11),
        exceptionReason: reason
    )
    require(crash.callStackTree === tree, "testDiagnosticGetters: crash tree")
    require(crash.terminationReason == "signal", "testDiagnosticGetters: term")
    require(crash.virtualMemoryRegionInfo == "stack", "testDiagnosticGetters: vm")
    require(crash.exceptionType == NSNumber(value: 1), "testDiagnosticGetters: crash type")
    require(crash.exceptionCode == NSNumber(value: 2), "testDiagnosticGetters: crash code")
    require(crash.signal == NSNumber(value: 11), "testDiagnosticGetters: crash signal")
    require(crash.exceptionReason?.exceptionName == "Test", "testDiagnosticGetters: crash reason")

    let disk = MXDiskWriteExceptionDiagnostic(totalWritesCaused: Measurement(value: 9, unit: .bytes))
    require(disk.totalWritesCaused.value == 9, "testDiagnosticGetters: writes")
    require(disk.callStackTree !== tree, "testDiagnosticGetters: disk tree")

    let hang = MXHangDiagnostic(hangDuration: Measurement(value: 5, unit: .seconds))
    require(hang.hangDuration.value == 5, "testDiagnosticGetters: hang")
    require(hang.callStackTree !== tree, "testDiagnosticGetters: hang tree")
}

private func testPayloadGetters() {
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
    require(payload.latestApplicationVersion == "9", "testPayloadGetters: version")
    require(payload.includesMultipleApplicationVersions, "testPayloadGetters: multi")
    require(payload.timeStampBegin == begin, "testPayloadGetters: begin")
    require(payload.timeStampEnd == end, "testPayloadGetters: end")
    require(payload.cpuMetrics != nil, "testPayloadGetters: cpu")
    require(payload.gpuMetrics != nil, "testPayloadGetters: gpu")
    require(payload.cellularConditionMetrics != nil, "testPayloadGetters: cellular")
    require(payload.applicationTimeMetrics != nil, "testPayloadGetters: time")
    require(payload.locationActivityMetrics != nil, "testPayloadGetters: location")
    require(payload.networkTransferMetrics != nil, "testPayloadGetters: network")
    require(payload.applicationLaunchMetrics != nil, "testPayloadGetters: launch")
    require(payload.applicationResponsivenessMetrics != nil, "testPayloadGetters: resp")
    require(payload.diskIOMetrics != nil, "testPayloadGetters: diskio")
    require(payload.memoryMetrics != nil, "testPayloadGetters: memory")
    require(payload.displayMetrics != nil, "testPayloadGetters: display")
    require(payload.animationMetrics != nil, "testPayloadGetters: animation")
    require(payload.applicationExitMetrics != nil, "testPayloadGetters: exits")
    require(payload.diskSpaceUsageMetrics != nil, "testPayloadGetters: space")
    require(payload.signpostMetrics?.count == 1, "testPayloadGetters: signposts")
    require(payload.metaData?.bundleIdentifier == "payload.app", "testPayloadGetters: meta")

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
    require(diagnostics.cpuExceptionDiagnostics?.count == 1, "testPayloadGetters: diag cpu")
    require(diagnostics.diskWriteExceptionDiagnostics?.count == 1, "testPayloadGetters: diag disk")
    require(diagnostics.hangDiagnostics?.count == 1, "testPayloadGetters: diag hang")
    require(diagnostics.appLaunchDiagnostics?.count == 1, "testPayloadGetters: diag launch")
    require(diagnostics.crashDiagnostics?.count == 1, "testPayloadGetters: diag crash")
    require(diagnostics.timeStampBegin == diagBegin, "testPayloadGetters: diag begin")
    require(diagnostics.timeStampEnd == diagEnd, "testPayloadGetters: diag end")
}

private func testMXCrashDiagnosticObjectiveCExceptionReasonClassName() {
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(
        composedMessage: "boom",
        formatString: "%@",
        arguments: ["x"],
        exceptionType: "NSException",
        className: "Thing",
        exceptionName: "Test"
    )
    let observed: String = reason.className
    require(
        observed == "Thing",
        "testMXCrashDiagnosticObjectiveCExceptionReasonClassName: stored className"
    )
    // Apple Foundation exposes NSObject.className, so the MetricKit property
    // is an override there. Reading through NSObject is a compile-time catch
    // for a missing override when Objective-C Foundation is imported. This
    // Linux host does not execute Apple Foundation.
#if canImport(ObjectiveC)
    let asObject: NSObject = reason
    require(
        asObject.className == "Thing",
        "testMXCrashDiagnosticObjectiveCExceptionReasonClassName: NSObject override"
    )
#endif
}

testMXErrorCodeRawValues()
testMXErrorDomainAndBridging()
testMXLaunchTaskID()
testLaunchMeasurementFailClosed()
testSharedManagerAndEmptyPayloads()
testSubscriberRetentionIdempotentRelease()
testSubscriberConcurrentAddRemove()
testUnitSymbols()
testHistogramAndAverageGetters()
testMetricGetters()
testDiagnosticGetters()
testMXCrashDiagnosticObjectiveCExceptionReasonClassName()
testPayloadGetters()
print("METRICKIT_AGENT_RUNTIME_OK")

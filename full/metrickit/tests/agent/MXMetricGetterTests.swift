@_spi(OpenUIKitHost) import MetricKit
import Foundation

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

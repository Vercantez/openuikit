import Foundation

open class MXMetric: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    @_spi(OpenUIKitHost)
    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        mxFailClosedEncode(coder)
    }

    open func dictionaryRepresentation() -> [AnyHashable: Any] {
        [:]
    }

    open func jsonRepresentation() -> Data {
        MXSerialization.jsonData(from: dictionaryRepresentation())
    }
}

open class MXAnimationMetric: MXMetric, @unchecked Sendable {
    private let _hitchTimeRatio: Measurement<Unit>
    private let _scrollHitchTimeRatio: Measurement<Unit>

    open var hitchTimeRatio: Measurement<Unit> { _hitchTimeRatio }
    open var scrollHitchTimeRatio: Measurement<Unit> { _scrollHitchTimeRatio }

    @_spi(OpenUIKitHost)
    public init(
        hitchTimeRatio: Measurement<Unit> = Measurement(value: 0, unit: Unit(symbol: "")),
        scrollHitchTimeRatio: Measurement<Unit> = Measurement(value: 0, unit: Unit(symbol: ""))
    ) {
        self._hitchTimeRatio = hitchTimeRatio
        self._scrollHitchTimeRatio = scrollHitchTimeRatio
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "hitchTimeRatio": MXSerialization.measurement(_hitchTimeRatio),
            "scrollHitchTimeRatio": MXSerialization.measurement(_scrollHitchTimeRatio),
        ]
    }
}

open class MXBackgroundExitData: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _cumulativeNormalAppExitCount: Int
    private let _cumulativeMemoryResourceLimitExitCount: Int
    private let _cumulativeCPUResourceLimitExitCount: Int
    private let _cumulativeMemoryPressureExitCount: Int
    private let _cumulativeBadAccessExitCount: Int
    private let _cumulativeAbnormalExitCount: Int
    private let _cumulativeIllegalInstructionExitCount: Int
    private let _cumulativeAppWatchdogExitCount: Int
    private let _cumulativeSuspendedWithLockedFileExitCount: Int
    private let _cumulativeBackgroundTaskAssertionTimeoutExitCount: Int

    open var cumulativeNormalAppExitCount: Int { _cumulativeNormalAppExitCount }
    open var cumulativeMemoryResourceLimitExitCount: Int { _cumulativeMemoryResourceLimitExitCount }
    open var cumulativeCPUResourceLimitExitCount: Int { _cumulativeCPUResourceLimitExitCount }
    open var cumulativeMemoryPressureExitCount: Int { _cumulativeMemoryPressureExitCount }
    open var cumulativeBadAccessExitCount: Int { _cumulativeBadAccessExitCount }
    open var cumulativeAbnormalExitCount: Int { _cumulativeAbnormalExitCount }
    open var cumulativeIllegalInstructionExitCount: Int { _cumulativeIllegalInstructionExitCount }
    open var cumulativeAppWatchdogExitCount: Int { _cumulativeAppWatchdogExitCount }
    open var cumulativeSuspendedWithLockedFileExitCount: Int { _cumulativeSuspendedWithLockedFileExitCount }
    open var cumulativeBackgroundTaskAssertionTimeoutExitCount: Int { _cumulativeBackgroundTaskAssertionTimeoutExitCount }

    @_spi(OpenUIKitHost)
    public init(
        cumulativeNormalAppExitCount: Int = 0,
        cumulativeMemoryResourceLimitExitCount: Int = 0,
        cumulativeCPUResourceLimitExitCount: Int = 0,
        cumulativeMemoryPressureExitCount: Int = 0,
        cumulativeBadAccessExitCount: Int = 0,
        cumulativeAbnormalExitCount: Int = 0,
        cumulativeIllegalInstructionExitCount: Int = 0,
        cumulativeAppWatchdogExitCount: Int = 0,
        cumulativeSuspendedWithLockedFileExitCount: Int = 0,
        cumulativeBackgroundTaskAssertionTimeoutExitCount: Int = 0
    ) {
        self._cumulativeNormalAppExitCount = cumulativeNormalAppExitCount
        self._cumulativeMemoryResourceLimitExitCount = cumulativeMemoryResourceLimitExitCount
        self._cumulativeCPUResourceLimitExitCount = cumulativeCPUResourceLimitExitCount
        self._cumulativeMemoryPressureExitCount = cumulativeMemoryPressureExitCount
        self._cumulativeBadAccessExitCount = cumulativeBadAccessExitCount
        self._cumulativeAbnormalExitCount = cumulativeAbnormalExitCount
        self._cumulativeIllegalInstructionExitCount = cumulativeIllegalInstructionExitCount
        self._cumulativeAppWatchdogExitCount = cumulativeAppWatchdogExitCount
        self._cumulativeSuspendedWithLockedFileExitCount = cumulativeSuspendedWithLockedFileExitCount
        self._cumulativeBackgroundTaskAssertionTimeoutExitCount = cumulativeBackgroundTaskAssertionTimeoutExitCount
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        mxFailClosedEncode(coder)
    }

    func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "cumulativeNormalAppExitCount": _cumulativeNormalAppExitCount,
            "cumulativeMemoryResourceLimitExitCount": _cumulativeMemoryResourceLimitExitCount,
            "cumulativeCPUResourceLimitExitCount": _cumulativeCPUResourceLimitExitCount,
            "cumulativeMemoryPressureExitCount": _cumulativeMemoryPressureExitCount,
            "cumulativeBadAccessExitCount": _cumulativeBadAccessExitCount,
            "cumulativeAbnormalExitCount": _cumulativeAbnormalExitCount,
            "cumulativeIllegalInstructionExitCount": _cumulativeIllegalInstructionExitCount,
            "cumulativeAppWatchdogExitCount": _cumulativeAppWatchdogExitCount,
            "cumulativeSuspendedWithLockedFileExitCount": _cumulativeSuspendedWithLockedFileExitCount,
            "cumulativeBackgroundTaskAssertionTimeoutExitCount": _cumulativeBackgroundTaskAssertionTimeoutExitCount,
        ]
    }
}

open class MXForegroundExitData: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _cumulativeNormalAppExitCount: Int
    private let _cumulativeMemoryResourceLimitExitCount: Int
    private let _cumulativeBadAccessExitCount: Int
    private let _cumulativeAbnormalExitCount: Int
    private let _cumulativeIllegalInstructionExitCount: Int
    private let _cumulativeAppWatchdogExitCount: Int

    open var cumulativeNormalAppExitCount: Int { _cumulativeNormalAppExitCount }
    open var cumulativeMemoryResourceLimitExitCount: Int { _cumulativeMemoryResourceLimitExitCount }
    open var cumulativeBadAccessExitCount: Int { _cumulativeBadAccessExitCount }
    open var cumulativeAbnormalExitCount: Int { _cumulativeAbnormalExitCount }
    open var cumulativeIllegalInstructionExitCount: Int { _cumulativeIllegalInstructionExitCount }
    open var cumulativeAppWatchdogExitCount: Int { _cumulativeAppWatchdogExitCount }

    @_spi(OpenUIKitHost)
    public init(
        cumulativeNormalAppExitCount: Int = 0,
        cumulativeMemoryResourceLimitExitCount: Int = 0,
        cumulativeBadAccessExitCount: Int = 0,
        cumulativeAbnormalExitCount: Int = 0,
        cumulativeIllegalInstructionExitCount: Int = 0,
        cumulativeAppWatchdogExitCount: Int = 0
    ) {
        self._cumulativeNormalAppExitCount = cumulativeNormalAppExitCount
        self._cumulativeMemoryResourceLimitExitCount = cumulativeMemoryResourceLimitExitCount
        self._cumulativeBadAccessExitCount = cumulativeBadAccessExitCount
        self._cumulativeAbnormalExitCount = cumulativeAbnormalExitCount
        self._cumulativeIllegalInstructionExitCount = cumulativeIllegalInstructionExitCount
        self._cumulativeAppWatchdogExitCount = cumulativeAppWatchdogExitCount
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        mxFailClosedEncode(coder)
    }

    func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "cumulativeNormalAppExitCount": _cumulativeNormalAppExitCount,
            "cumulativeMemoryResourceLimitExitCount": _cumulativeMemoryResourceLimitExitCount,
            "cumulativeBadAccessExitCount": _cumulativeBadAccessExitCount,
            "cumulativeAbnormalExitCount": _cumulativeAbnormalExitCount,
            "cumulativeIllegalInstructionExitCount": _cumulativeIllegalInstructionExitCount,
            "cumulativeAppWatchdogExitCount": _cumulativeAppWatchdogExitCount,
        ]
    }
}

open class MXAppExitMetric: MXMetric, @unchecked Sendable {
    private let _foregroundExitData: MXForegroundExitData
    private let _backgroundExitData: MXBackgroundExitData

    open var foregroundExitData: MXForegroundExitData { _foregroundExitData }
    open var backgroundExitData: MXBackgroundExitData { _backgroundExitData }

    @_spi(OpenUIKitHost)
    public init(
        foregroundExitData: MXForegroundExitData = MXForegroundExitData(),
        backgroundExitData: MXBackgroundExitData = MXBackgroundExitData()
    ) {
        self._foregroundExitData = foregroundExitData
        self._backgroundExitData = backgroundExitData
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "foregroundExitData": _foregroundExitData.dictionaryRepresentation(),
            "backgroundExitData": _backgroundExitData.dictionaryRepresentation(),
        ]
    }
}

open class MXAppLaunchMetric: MXMetric, @unchecked Sendable {
    private let _histogrammedTimeToFirstDraw: MXHistogram<UnitDuration>
    private let _histogrammedApplicationResumeTime: MXHistogram<UnitDuration>
    private let _histogrammedOptimizedTimeToFirstDraw: MXHistogram<UnitDuration>
    private let _histogrammedExtendedLaunch: MXHistogram<UnitDuration>

    open var histogrammedTimeToFirstDraw: MXHistogram<UnitDuration> { _histogrammedTimeToFirstDraw }
    open var histogrammedApplicationResumeTime: MXHistogram<UnitDuration> { _histogrammedApplicationResumeTime }
    open var histogrammedOptimizedTimeToFirstDraw: MXHistogram<UnitDuration> { _histogrammedOptimizedTimeToFirstDraw }
    open var histogrammedExtendedLaunch: MXHistogram<UnitDuration> { _histogrammedExtendedLaunch }

    @_spi(OpenUIKitHost)
    public init(
        histogrammedTimeToFirstDraw: MXHistogram<UnitDuration> = MXHistogram(),
        histogrammedApplicationResumeTime: MXHistogram<UnitDuration> = MXHistogram(),
        histogrammedOptimizedTimeToFirstDraw: MXHistogram<UnitDuration> = MXHistogram(),
        histogrammedExtendedLaunch: MXHistogram<UnitDuration> = MXHistogram()
    ) {
        self._histogrammedTimeToFirstDraw = histogrammedTimeToFirstDraw
        self._histogrammedApplicationResumeTime = histogrammedApplicationResumeTime
        self._histogrammedOptimizedTimeToFirstDraw = histogrammedOptimizedTimeToFirstDraw
        self._histogrammedExtendedLaunch = histogrammedExtendedLaunch
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "histogrammedTimeToFirstDrawBucketCount": _histogrammedTimeToFirstDraw.totalBucketCount,
            "histogrammedApplicationResumeTimeBucketCount": _histogrammedApplicationResumeTime.totalBucketCount,
            "histogrammedOptimizedTimeToFirstDrawBucketCount": _histogrammedOptimizedTimeToFirstDraw.totalBucketCount,
            "histogrammedExtendedLaunchBucketCount": _histogrammedExtendedLaunch.totalBucketCount,
        ]
    }
}

open class MXAppResponsivenessMetric: MXMetric, @unchecked Sendable {
    private let _histogrammedApplicationHangTime: MXHistogram<UnitDuration>

    open var histogrammedApplicationHangTime: MXHistogram<UnitDuration> { _histogrammedApplicationHangTime }

    @_spi(OpenUIKitHost)
    public init(histogrammedApplicationHangTime: MXHistogram<UnitDuration> = MXHistogram()) {
        self._histogrammedApplicationHangTime = histogrammedApplicationHangTime
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        ["histogrammedApplicationHangTimeBucketCount": _histogrammedApplicationHangTime.totalBucketCount]
    }
}

open class MXAppRunTimeMetric: MXMetric, @unchecked Sendable {
    private let _cumulativeForegroundTime: Measurement<UnitDuration>
    private let _cumulativeBackgroundTime: Measurement<UnitDuration>
    private let _cumulativeBackgroundAudioTime: Measurement<UnitDuration>
    private let _cumulativeBackgroundLocationTime: Measurement<UnitDuration>

    open var cumulativeForegroundTime: Measurement<UnitDuration> { _cumulativeForegroundTime }
    open var cumulativeBackgroundTime: Measurement<UnitDuration> { _cumulativeBackgroundTime }
    open var cumulativeBackgroundAudioTime: Measurement<UnitDuration> { _cumulativeBackgroundAudioTime }
    open var cumulativeBackgroundLocationTime: Measurement<UnitDuration> { _cumulativeBackgroundLocationTime }

    @_spi(OpenUIKitHost)
    public init(
        cumulativeForegroundTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeBackgroundTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeBackgroundAudioTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeBackgroundLocationTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds)
    ) {
        self._cumulativeForegroundTime = cumulativeForegroundTime
        self._cumulativeBackgroundTime = cumulativeBackgroundTime
        self._cumulativeBackgroundAudioTime = cumulativeBackgroundAudioTime
        self._cumulativeBackgroundLocationTime = cumulativeBackgroundLocationTime
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "cumulativeForegroundTime": MXSerialization.measurement(_cumulativeForegroundTime),
            "cumulativeBackgroundTime": MXSerialization.measurement(_cumulativeBackgroundTime),
            "cumulativeBackgroundAudioTime": MXSerialization.measurement(_cumulativeBackgroundAudioTime),
            "cumulativeBackgroundLocationTime": MXSerialization.measurement(_cumulativeBackgroundLocationTime),
        ]
    }
}

open class MXCPUMetric: MXMetric, @unchecked Sendable {
    private let _cumulativeCPUTime: Measurement<UnitDuration>
    private let _cumulativeCPUInstructions: Measurement<Unit>

    open var cumulativeCPUTime: Measurement<UnitDuration> { _cumulativeCPUTime }
    open var cumulativeCPUInstructions: Measurement<Unit> { _cumulativeCPUInstructions }

    @_spi(OpenUIKitHost)
    public init(
        cumulativeCPUTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeCPUInstructions: Measurement<Unit> = Measurement(value: 0, unit: Unit(symbol: ""))
    ) {
        self._cumulativeCPUTime = cumulativeCPUTime
        self._cumulativeCPUInstructions = cumulativeCPUInstructions
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "cumulativeCPUTime": MXSerialization.measurement(_cumulativeCPUTime),
            "cumulativeCPUInstructions": MXSerialization.measurement(_cumulativeCPUInstructions),
        ]
    }
}

open class MXGPUMetric: MXMetric, @unchecked Sendable {
    private let _cumulativeGPUTime: Measurement<UnitDuration>

    open var cumulativeGPUTime: Measurement<UnitDuration> { _cumulativeGPUTime }

    @_spi(OpenUIKitHost)
    public init(cumulativeGPUTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds)) {
        self._cumulativeGPUTime = cumulativeGPUTime
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        ["cumulativeGPUTime": MXSerialization.measurement(_cumulativeGPUTime)]
    }
}

open class MXCellularConditionMetric: MXMetric, @unchecked Sendable {
    private let _histogrammedCellularConditionTime: MXHistogram<MXUnitSignalBars>

    open var histogrammedCellularConditionTime: MXHistogram<MXUnitSignalBars> {
        _histogrammedCellularConditionTime
    }

    @_spi(OpenUIKitHost)
    public init(histogrammedCellularConditionTime: MXHistogram<MXUnitSignalBars> = MXHistogram()) {
        self._histogrammedCellularConditionTime = histogrammedCellularConditionTime
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        ["histogrammedCellularConditionTimeBucketCount": _histogrammedCellularConditionTime.totalBucketCount]
    }
}

open class MXDiskIOMetric: MXMetric, @unchecked Sendable {
    private let _cumulativeLogicalWrites: Measurement<UnitInformationStorage>

    open var cumulativeLogicalWrites: Measurement<UnitInformationStorage> { _cumulativeLogicalWrites }

    @_spi(OpenUIKitHost)
    public init(cumulativeLogicalWrites: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes)) {
        self._cumulativeLogicalWrites = cumulativeLogicalWrites
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        ["cumulativeLogicalWrites": MXSerialization.measurement(_cumulativeLogicalWrites)]
    }
}

open class MXDiskSpaceUsageMetric: MXMetric, @unchecked Sendable {
    private let _totalBinaryFileCount: Int
    private let _totalBinaryFileSize: Measurement<UnitInformationStorage>
    private let _totalDataFileCount: Int
    private let _totalDataFileSize: Measurement<UnitInformationStorage>
    private let _totalCacheFolderSize: Measurement<UnitInformationStorage>
    private let _totalCloneSize: Measurement<UnitInformationStorage>
    private let _totalDiskSpaceUsedSize: Measurement<UnitInformationStorage>
    private let _totalDiskSpaceCapacity: Measurement<UnitInformationStorage>

    open var totalBinaryFileCount: Int { _totalBinaryFileCount }
    open var totalBinaryFileSize: Measurement<UnitInformationStorage> { _totalBinaryFileSize }
    open var totalDataFileCount: Int { _totalDataFileCount }
    open var totalDataFileSize: Measurement<UnitInformationStorage> { _totalDataFileSize }
    open var totalCacheFolderSize: Measurement<UnitInformationStorage> { _totalCacheFolderSize }
    open var totalCloneSize: Measurement<UnitInformationStorage> { _totalCloneSize }
    open var totalDiskSpaceUsedSize: Measurement<UnitInformationStorage> { _totalDiskSpaceUsedSize }
    open var totalDiskSpaceCapacity: Measurement<UnitInformationStorage> { _totalDiskSpaceCapacity }

    @_spi(OpenUIKitHost)
    public init(
        totalBinaryFileCount: Int = 0,
        totalBinaryFileSize: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        totalDataFileCount: Int = 0,
        totalDataFileSize: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        totalCacheFolderSize: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        totalCloneSize: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        totalDiskSpaceUsedSize: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        totalDiskSpaceCapacity: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes)
    ) {
        self._totalBinaryFileCount = totalBinaryFileCount
        self._totalBinaryFileSize = totalBinaryFileSize
        self._totalDataFileCount = totalDataFileCount
        self._totalDataFileSize = totalDataFileSize
        self._totalCacheFolderSize = totalCacheFolderSize
        self._totalCloneSize = totalCloneSize
        self._totalDiskSpaceUsedSize = totalDiskSpaceUsedSize
        self._totalDiskSpaceCapacity = totalDiskSpaceCapacity
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "totalBinaryFileCount": _totalBinaryFileCount,
            "totalBinaryFileSize": MXSerialization.measurement(_totalBinaryFileSize),
            "totalDataFileCount": _totalDataFileCount,
            "totalDataFileSize": MXSerialization.measurement(_totalDataFileSize),
            "totalCacheFolderSize": MXSerialization.measurement(_totalCacheFolderSize),
            "totalCloneSize": MXSerialization.measurement(_totalCloneSize),
            "totalDiskSpaceUsedSize": MXSerialization.measurement(_totalDiskSpaceUsedSize),
            "totalDiskSpaceCapacity": MXSerialization.measurement(_totalDiskSpaceCapacity),
        ]
    }
}

open class MXDisplayMetric: MXMetric, @unchecked Sendable {
    private let _averagePixelLuminance: MXAverage<MXUnitAveragePixelLuminance>?

    open var averagePixelLuminance: MXAverage<MXUnitAveragePixelLuminance>? { _averagePixelLuminance }

    @_spi(OpenUIKitHost)
    public init(averagePixelLuminance: MXAverage<MXUnitAveragePixelLuminance>? = nil) {
        self._averagePixelLuminance = averagePixelLuminance
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        if let average = _averagePixelLuminance {
            dict["averagePixelLuminance"] = [
                "averageMeasurement": MXSerialization.measurement(average.averageMeasurement),
                "sampleCount": average.sampleCount,
                "standardDeviation": average.standardDeviation,
            ]
        }
        return dict
    }
}

open class MXLocationActivityMetric: MXMetric, @unchecked Sendable {
    private let _cumulativeBestAccuracyForNavigationTime: Measurement<UnitDuration>
    private let _cumulativeBestAccuracyTime: Measurement<UnitDuration>
    private let _cumulativeNearestTenMetersAccuracyTime: Measurement<UnitDuration>
    private let _cumulativeHundredMetersAccuracyTime: Measurement<UnitDuration>
    private let _cumulativeKilometerAccuracyTime: Measurement<UnitDuration>
    private let _cumulativeThreeKilometersAccuracyTime: Measurement<UnitDuration>

    open var cumulativeBestAccuracyForNavigationTime: Measurement<UnitDuration> {
        _cumulativeBestAccuracyForNavigationTime
    }
    open var cumulativeBestAccuracyTime: Measurement<UnitDuration> { _cumulativeBestAccuracyTime }
    open var cumulativeNearestTenMetersAccuracyTime: Measurement<UnitDuration> {
        _cumulativeNearestTenMetersAccuracyTime
    }
    open var cumulativeHundredMetersAccuracyTime: Measurement<UnitDuration> {
        _cumulativeHundredMetersAccuracyTime
    }
    open var cumulativeKilometerAccuracyTime: Measurement<UnitDuration> { _cumulativeKilometerAccuracyTime }
    open var cumulativeThreeKilometersAccuracyTime: Measurement<UnitDuration> {
        _cumulativeThreeKilometersAccuracyTime
    }

    @_spi(OpenUIKitHost)
    public init(
        cumulativeBestAccuracyForNavigationTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeBestAccuracyTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeNearestTenMetersAccuracyTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeHundredMetersAccuracyTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeKilometerAccuracyTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        cumulativeThreeKilometersAccuracyTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds)
    ) {
        self._cumulativeBestAccuracyForNavigationTime = cumulativeBestAccuracyForNavigationTime
        self._cumulativeBestAccuracyTime = cumulativeBestAccuracyTime
        self._cumulativeNearestTenMetersAccuracyTime = cumulativeNearestTenMetersAccuracyTime
        self._cumulativeHundredMetersAccuracyTime = cumulativeHundredMetersAccuracyTime
        self._cumulativeKilometerAccuracyTime = cumulativeKilometerAccuracyTime
        self._cumulativeThreeKilometersAccuracyTime = cumulativeThreeKilometersAccuracyTime
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "cumulativeBestAccuracyForNavigationTime": MXSerialization.measurement(_cumulativeBestAccuracyForNavigationTime),
            "cumulativeBestAccuracyTime": MXSerialization.measurement(_cumulativeBestAccuracyTime),
            "cumulativeNearestTenMetersAccuracyTime": MXSerialization.measurement(_cumulativeNearestTenMetersAccuracyTime),
            "cumulativeHundredMetersAccuracyTime": MXSerialization.measurement(_cumulativeHundredMetersAccuracyTime),
            "cumulativeKilometerAccuracyTime": MXSerialization.measurement(_cumulativeKilometerAccuracyTime),
            "cumulativeThreeKilometersAccuracyTime": MXSerialization.measurement(_cumulativeThreeKilometersAccuracyTime),
        ]
    }
}

open class MXMemoryMetric: MXMetric, @unchecked Sendable {
    private let _peakMemoryUsage: Measurement<UnitInformationStorage>
    private let _averageSuspendedMemory: MXAverage<UnitInformationStorage>

    open var peakMemoryUsage: Measurement<UnitInformationStorage> { _peakMemoryUsage }
    open var averageSuspendedMemory: MXAverage<UnitInformationStorage> { _averageSuspendedMemory }

    @_spi(OpenUIKitHost)
    public init(
        peakMemoryUsage: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        averageSuspendedMemory: MXAverage<UnitInformationStorage> = MXAverage(
            averageMeasurement: Measurement(value: 0, unit: UnitInformationStorage.bytes)
        )
    ) {
        self._peakMemoryUsage = peakMemoryUsage
        self._averageSuspendedMemory = averageSuspendedMemory
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "peakMemoryUsage": MXSerialization.measurement(_peakMemoryUsage),
            "averageSuspendedMemory": [
                "averageMeasurement": MXSerialization.measurement(_averageSuspendedMemory.averageMeasurement),
                "sampleCount": _averageSuspendedMemory.sampleCount,
                "standardDeviation": _averageSuspendedMemory.standardDeviation,
            ],
        ]
    }
}

open class MXNetworkTransferMetric: MXMetric, @unchecked Sendable {
    private let _cumulativeWifiUpload: Measurement<UnitInformationStorage>
    private let _cumulativeWifiDownload: Measurement<UnitInformationStorage>
    private let _cumulativeCellularUpload: Measurement<UnitInformationStorage>
    private let _cumulativeCellularDownload: Measurement<UnitInformationStorage>

    open var cumulativeWifiUpload: Measurement<UnitInformationStorage> { _cumulativeWifiUpload }
    open var cumulativeWifiDownload: Measurement<UnitInformationStorage> { _cumulativeWifiDownload }
    open var cumulativeCellularUpload: Measurement<UnitInformationStorage> { _cumulativeCellularUpload }
    open var cumulativeCellularDownload: Measurement<UnitInformationStorage> { _cumulativeCellularDownload }

    @_spi(OpenUIKitHost)
    public init(
        cumulativeWifiUpload: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        cumulativeWifiDownload: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        cumulativeCellularUpload: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes),
        cumulativeCellularDownload: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes)
    ) {
        self._cumulativeWifiUpload = cumulativeWifiUpload
        self._cumulativeWifiDownload = cumulativeWifiDownload
        self._cumulativeCellularUpload = cumulativeCellularUpload
        self._cumulativeCellularDownload = cumulativeCellularDownload
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        [
            "cumulativeWifiUpload": MXSerialization.measurement(_cumulativeWifiUpload),
            "cumulativeWifiDownload": MXSerialization.measurement(_cumulativeWifiDownload),
            "cumulativeCellularUpload": MXSerialization.measurement(_cumulativeCellularUpload),
            "cumulativeCellularDownload": MXSerialization.measurement(_cumulativeCellularDownload),
        ]
    }
}

open class MXSignpostIntervalData: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _histogrammedSignpostDuration: MXHistogram<UnitDuration>
    private let _cumulativeCPUTime: Measurement<UnitDuration>?
    private let _averageMemory: MXAverage<UnitInformationStorage>?
    private let _cumulativeLogicalWrites: Measurement<UnitInformationStorage>?
    private let _cumulativeHitchTimeRatio: Measurement<Unit>?

    open var histogrammedSignpostDuration: MXHistogram<UnitDuration> { _histogrammedSignpostDuration }
    open var cumulativeCPUTime: Measurement<UnitDuration>? { _cumulativeCPUTime }
    open var averageMemory: MXAverage<UnitInformationStorage>? { _averageMemory }
    open var cumulativeLogicalWrites: Measurement<UnitInformationStorage>? { _cumulativeLogicalWrites }
    open var cumulativeHitchTimeRatio: Measurement<Unit>? { _cumulativeHitchTimeRatio }

    @_spi(OpenUIKitHost)
    public init(
        histogrammedSignpostDuration: MXHistogram<UnitDuration> = MXHistogram(),
        cumulativeCPUTime: Measurement<UnitDuration>? = nil,
        averageMemory: MXAverage<UnitInformationStorage>? = nil,
        cumulativeLogicalWrites: Measurement<UnitInformationStorage>? = nil,
        cumulativeHitchTimeRatio: Measurement<Unit>? = nil
    ) {
        self._histogrammedSignpostDuration = histogrammedSignpostDuration
        self._cumulativeCPUTime = cumulativeCPUTime
        self._averageMemory = averageMemory
        self._cumulativeLogicalWrites = cumulativeLogicalWrites
        self._cumulativeHitchTimeRatio = cumulativeHitchTimeRatio
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        mxFailClosedEncode(coder)
    }

    func dictionaryRepresentation() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [
            "histogrammedSignpostDurationBucketCount": _histogrammedSignpostDuration.totalBucketCount
        ]
        if let cpu = _cumulativeCPUTime {
            dict["cumulativeCPUTime"] = MXSerialization.measurement(cpu)
        }
        if let memory = _averageMemory {
            dict["averageMemory"] = [
                "averageMeasurement": MXSerialization.measurement(memory.averageMeasurement),
                "sampleCount": memory.sampleCount,
                "standardDeviation": memory.standardDeviation,
            ]
        }
        if let writes = _cumulativeLogicalWrites {
            dict["cumulativeLogicalWrites"] = MXSerialization.measurement(writes)
        }
        if let hitch = _cumulativeHitchTimeRatio {
            dict["cumulativeHitchTimeRatio"] = MXSerialization.measurement(hitch)
        }
        return dict
    }
}

open class MXSignpostMetric: MXMetric, @unchecked Sendable {
    private let _signpostName: String
    private let _signpostCategory: String
    private let _signpostIntervalData: MXSignpostIntervalData?
    private let _totalCount: Int

    open var signpostName: String { _signpostName }
    open var signpostCategory: String { _signpostCategory }
    open var signpostIntervalData: MXSignpostIntervalData? { _signpostIntervalData }
    open var totalCount: Int { _totalCount }

    @_spi(OpenUIKitHost)
    public init(
        signpostName: String = "",
        signpostCategory: String = "",
        signpostIntervalData: MXSignpostIntervalData? = nil,
        totalCount: Int = 0
    ) {
        self._signpostName = signpostName
        self._signpostCategory = signpostCategory
        self._signpostIntervalData = signpostIntervalData
        self._totalCount = totalCount
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [
            "signpostName": _signpostName,
            "signpostCategory": _signpostCategory,
            "totalCount": _totalCount,
        ]
        if let interval = _signpostIntervalData {
            dict["signpostIntervalData"] = interval.dictionaryRepresentation()
        }
        return dict
    }
}

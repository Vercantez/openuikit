import Foundation

open class MXMetricPayload: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _latestApplicationVersion: String
    private let _includesMultipleApplicationVersions: Bool
    private let _timeStampBegin: Date
    private let _timeStampEnd: Date
    private let _cpuMetrics: MXCPUMetric?
    private let _gpuMetrics: MXGPUMetric?
    private let _cellularConditionMetrics: MXCellularConditionMetric?
    private let _applicationTimeMetrics: MXAppRunTimeMetric?
    private let _locationActivityMetrics: MXLocationActivityMetric?
    private let _networkTransferMetrics: MXNetworkTransferMetric?
    private let _applicationLaunchMetrics: MXAppLaunchMetric?
    private let _applicationResponsivenessMetrics: MXAppResponsivenessMetric?
    private let _diskIOMetrics: MXDiskIOMetric?
    private let _memoryMetrics: MXMemoryMetric?
    private let _displayMetrics: MXDisplayMetric?
    private let _animationMetrics: MXAnimationMetric?
    private let _applicationExitMetrics: MXAppExitMetric?
    private let _diskSpaceUsageMetrics: MXDiskSpaceUsageMetric?
    private let _signpostMetrics: [MXSignpostMetric]?
    private let _metaData: MXMetaData?

    open var latestApplicationVersion: String { _latestApplicationVersion }
    open var includesMultipleApplicationVersions: Bool { _includesMultipleApplicationVersions }
    open var timeStampBegin: Date { _timeStampBegin }
    open var timeStampEnd: Date { _timeStampEnd }
    open var cpuMetrics: MXCPUMetric? { _cpuMetrics }
    open var gpuMetrics: MXGPUMetric? { _gpuMetrics }
    open var cellularConditionMetrics: MXCellularConditionMetric? { _cellularConditionMetrics }
    open var applicationTimeMetrics: MXAppRunTimeMetric? { _applicationTimeMetrics }
    open var locationActivityMetrics: MXLocationActivityMetric? { _locationActivityMetrics }
    open var networkTransferMetrics: MXNetworkTransferMetric? { _networkTransferMetrics }
    open var applicationLaunchMetrics: MXAppLaunchMetric? { _applicationLaunchMetrics }
    open var applicationResponsivenessMetrics: MXAppResponsivenessMetric? { _applicationResponsivenessMetrics }
    open var diskIOMetrics: MXDiskIOMetric? { _diskIOMetrics }
    open var memoryMetrics: MXMemoryMetric? { _memoryMetrics }
    open var displayMetrics: MXDisplayMetric? { _displayMetrics }
    open var animationMetrics: MXAnimationMetric? { _animationMetrics }
    open var applicationExitMetrics: MXAppExitMetric? { _applicationExitMetrics }
    open var diskSpaceUsageMetrics: MXDiskSpaceUsageMetric? { _diskSpaceUsageMetrics }
    open var signpostMetrics: [MXSignpostMetric]? { _signpostMetrics }
    open var metaData: MXMetaData? { _metaData }

    @_spi(OpenUIKitHost)
    public init(
        latestApplicationVersion: String = "",
        includesMultipleApplicationVersions: Bool = false,
        timeStampBegin: Date = Date(timeIntervalSince1970: 0),
        timeStampEnd: Date = Date(timeIntervalSince1970: 0),
        cpuMetrics: MXCPUMetric? = nil,
        gpuMetrics: MXGPUMetric? = nil,
        cellularConditionMetrics: MXCellularConditionMetric? = nil,
        applicationTimeMetrics: MXAppRunTimeMetric? = nil,
        locationActivityMetrics: MXLocationActivityMetric? = nil,
        networkTransferMetrics: MXNetworkTransferMetric? = nil,
        applicationLaunchMetrics: MXAppLaunchMetric? = nil,
        applicationResponsivenessMetrics: MXAppResponsivenessMetric? = nil,
        diskIOMetrics: MXDiskIOMetric? = nil,
        memoryMetrics: MXMemoryMetric? = nil,
        displayMetrics: MXDisplayMetric? = nil,
        animationMetrics: MXAnimationMetric? = nil,
        applicationExitMetrics: MXAppExitMetric? = nil,
        diskSpaceUsageMetrics: MXDiskSpaceUsageMetric? = nil,
        signpostMetrics: [MXSignpostMetric]? = nil,
        metaData: MXMetaData? = nil
    ) {
        self._latestApplicationVersion = latestApplicationVersion
        self._includesMultipleApplicationVersions = includesMultipleApplicationVersions
        self._timeStampBegin = timeStampBegin
        self._timeStampEnd = timeStampEnd
        self._cpuMetrics = cpuMetrics
        self._gpuMetrics = gpuMetrics
        self._cellularConditionMetrics = cellularConditionMetrics
        self._applicationTimeMetrics = applicationTimeMetrics
        self._locationActivityMetrics = locationActivityMetrics
        self._networkTransferMetrics = networkTransferMetrics
        self._applicationLaunchMetrics = applicationLaunchMetrics
        self._applicationResponsivenessMetrics = applicationResponsivenessMetrics
        self._diskIOMetrics = diskIOMetrics
        self._memoryMetrics = memoryMetrics
        self._displayMetrics = displayMetrics
        self._animationMetrics = animationMetrics
        self._applicationExitMetrics = applicationExitMetrics
        self._diskSpaceUsageMetrics = diskSpaceUsageMetrics
        self._signpostMetrics = signpostMetrics
        self._metaData = metaData
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
        var dict: [AnyHashable: Any] = [
            "latestApplicationVersion": _latestApplicationVersion,
            "includesMultipleApplicationVersions": _includesMultipleApplicationVersions,
            "timeStampBegin": _timeStampBegin.timeIntervalSince1970,
            "timeStampEnd": _timeStampEnd.timeIntervalSince1970,
        ]
        if let cpuMetrics { dict["cpuMetrics"] = cpuMetrics.dictionaryRepresentation() }
        if let gpuMetrics { dict["gpuMetrics"] = gpuMetrics.dictionaryRepresentation() }
        if let cellularConditionMetrics {
            dict["cellularConditionMetrics"] = cellularConditionMetrics.dictionaryRepresentation()
        }
        if let applicationTimeMetrics {
            dict["applicationTimeMetrics"] = applicationTimeMetrics.dictionaryRepresentation()
        }
        if let locationActivityMetrics {
            dict["locationActivityMetrics"] = locationActivityMetrics.dictionaryRepresentation()
        }
        if let networkTransferMetrics {
            dict["networkTransferMetrics"] = networkTransferMetrics.dictionaryRepresentation()
        }
        if let applicationLaunchMetrics {
            dict["applicationLaunchMetrics"] = applicationLaunchMetrics.dictionaryRepresentation()
        }
        if let applicationResponsivenessMetrics {
            dict["applicationResponsivenessMetrics"] = applicationResponsivenessMetrics.dictionaryRepresentation()
        }
        if let diskIOMetrics { dict["diskIOMetrics"] = diskIOMetrics.dictionaryRepresentation() }
        if let memoryMetrics { dict["memoryMetrics"] = memoryMetrics.dictionaryRepresentation() }
        if let displayMetrics { dict["displayMetrics"] = displayMetrics.dictionaryRepresentation() }
        if let animationMetrics { dict["animationMetrics"] = animationMetrics.dictionaryRepresentation() }
        if let applicationExitMetrics {
            dict["applicationExitMetrics"] = applicationExitMetrics.dictionaryRepresentation()
        }
        if let diskSpaceUsageMetrics {
            dict["diskSpaceUsageMetrics"] = diskSpaceUsageMetrics.dictionaryRepresentation()
        }
        if let signpostMetrics {
            dict["signpostMetrics"] = signpostMetrics.map { $0.dictionaryRepresentation() }
        }
        if let metaData { dict["metaData"] = metaData.dictionaryRepresentation() }
        return dict
    }

    open func jsonRepresentation() -> Data {
        MXSerialization.jsonData(from: dictionaryRepresentation())
    }
}

open class MXDiagnosticPayload: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _cpuExceptionDiagnostics: [MXCPUExceptionDiagnostic]?
    private let _diskWriteExceptionDiagnostics: [MXDiskWriteExceptionDiagnostic]?
    private let _hangDiagnostics: [MXHangDiagnostic]?
    private let _appLaunchDiagnostics: [MXAppLaunchDiagnostic]?
    private let _crashDiagnostics: [MXCrashDiagnostic]?
    private let _timeStampBegin: Date
    private let _timeStampEnd: Date

    open var cpuExceptionDiagnostics: [MXCPUExceptionDiagnostic]? { _cpuExceptionDiagnostics }
    open var diskWriteExceptionDiagnostics: [MXDiskWriteExceptionDiagnostic]? { _diskWriteExceptionDiagnostics }
    open var hangDiagnostics: [MXHangDiagnostic]? { _hangDiagnostics }
    open var appLaunchDiagnostics: [MXAppLaunchDiagnostic]? { _appLaunchDiagnostics }
    open var crashDiagnostics: [MXCrashDiagnostic]? { _crashDiagnostics }
    open var timeStampBegin: Date { _timeStampBegin }
    open var timeStampEnd: Date { _timeStampEnd }

    @_spi(OpenUIKitHost)
    public init(
        cpuExceptionDiagnostics: [MXCPUExceptionDiagnostic]? = nil,
        diskWriteExceptionDiagnostics: [MXDiskWriteExceptionDiagnostic]? = nil,
        hangDiagnostics: [MXHangDiagnostic]? = nil,
        appLaunchDiagnostics: [MXAppLaunchDiagnostic]? = nil,
        crashDiagnostics: [MXCrashDiagnostic]? = nil,
        timeStampBegin: Date = Date(timeIntervalSince1970: 0),
        timeStampEnd: Date = Date(timeIntervalSince1970: 0)
    ) {
        self._cpuExceptionDiagnostics = cpuExceptionDiagnostics
        self._diskWriteExceptionDiagnostics = diskWriteExceptionDiagnostics
        self._hangDiagnostics = hangDiagnostics
        self._appLaunchDiagnostics = appLaunchDiagnostics
        self._crashDiagnostics = crashDiagnostics
        self._timeStampBegin = timeStampBegin
        self._timeStampEnd = timeStampEnd
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
        var dict: [AnyHashable: Any] = [
            "timeStampBegin": _timeStampBegin.timeIntervalSince1970,
            "timeStampEnd": _timeStampEnd.timeIntervalSince1970,
        ]
        if let cpuExceptionDiagnostics {
            dict["cpuExceptionDiagnostics"] = cpuExceptionDiagnostics.map { $0.dictionaryRepresentation() }
        }
        if let diskWriteExceptionDiagnostics {
            dict["diskWriteExceptionDiagnostics"] = diskWriteExceptionDiagnostics.map {
                $0.dictionaryRepresentation()
            }
        }
        if let hangDiagnostics {
            dict["hangDiagnostics"] = hangDiagnostics.map { $0.dictionaryRepresentation() }
        }
        if let appLaunchDiagnostics {
            dict["appLaunchDiagnostics"] = appLaunchDiagnostics.map { $0.dictionaryRepresentation() }
        }
        if let crashDiagnostics {
            dict["crashDiagnostics"] = crashDiagnostics.map { $0.dictionaryRepresentation() }
        }
        return dict
    }

    open func jsonRepresentation() -> Data {
        MXSerialization.jsonData(from: dictionaryRepresentation())
    }
}

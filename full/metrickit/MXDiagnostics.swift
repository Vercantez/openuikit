import Foundation

open class MXMetaData: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _regionFormat: String
    private let _osVersion: String
    private let _deviceType: String
    private let _applicationBuildVersion: String
    private let _platformArchitecture: String
    private let _lowPowerModeEnabled: Bool
    private let _isTestFlightApp: Bool
    private let _pid: pid_t
    private let _bundleIdentifier: String

    open var regionFormat: String { _regionFormat }
    open var osVersion: String { _osVersion }
    open var deviceType: String { _deviceType }
    open var applicationBuildVersion: String { _applicationBuildVersion }
    open var platformArchitecture: String { _platformArchitecture }
    open var lowPowerModeEnabled: Bool { _lowPowerModeEnabled }
    open var isTestFlightApp: Bool { _isTestFlightApp }
    open var pid: pid_t { _pid }
    open var bundleIdentifier: String { _bundleIdentifier }

    @_spi(OpenUIKitHost)
    public init(
        regionFormat: String = "",
        osVersion: String = "",
        deviceType: String = "",
        applicationBuildVersion: String = "",
        platformArchitecture: String = "",
        lowPowerModeEnabled: Bool = false,
        isTestFlightApp: Bool = false,
        pid: pid_t = 0,
        bundleIdentifier: String = ""
    ) {
        self._regionFormat = regionFormat
        self._osVersion = osVersion
        self._deviceType = deviceType
        self._applicationBuildVersion = applicationBuildVersion
        self._platformArchitecture = platformArchitecture
        self._lowPowerModeEnabled = lowPowerModeEnabled
        self._isTestFlightApp = isTestFlightApp
        self._pid = pid
        self._bundleIdentifier = bundleIdentifier
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
        [
            "regionFormat": _regionFormat,
            "osVersion": _osVersion,
            "deviceType": _deviceType,
            "applicationBuildVersion": _applicationBuildVersion,
            "platformArchitecture": _platformArchitecture,
            "lowPowerModeEnabled": _lowPowerModeEnabled,
            "isTestFlightApp": _isTestFlightApp,
            "pid": Int(_pid),
            "bundleIdentifier": _bundleIdentifier,
        ]
    }

    open func jsonRepresentation() -> Data {
        MXSerialization.jsonData(from: dictionaryRepresentation())
    }
}

open class MXCallStackTree: NSObject, NSSecureCoding, @unchecked Sendable {
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

    /// Empty JSON object: Apple's call-stack schema is not in the pinned inputs.
    open func jsonRepresentation() -> Data {
        MXSerialization.emptyJSON
    }
}

open class MXSignpostRecord: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _subsystem: String
    private let _category: String
    private let _name: String
    private let _beginTimeStamp: Date
    private let _endTimeStamp: Date?
    private let _duration: Measurement<UnitDuration>?
    private let _isInterval: Bool

    open var subsystem: String { _subsystem }
    open var category: String { _category }
    open var name: String { _name }
    open var beginTimeStamp: Date { _beginTimeStamp }
    open var endTimeStamp: Date? { _endTimeStamp }
    open var duration: Measurement<UnitDuration>? { _duration }
    open var isInterval: Bool { _isInterval }

    @_spi(OpenUIKitHost)
    public init(
        subsystem: String = "",
        category: String = "",
        name: String = "",
        beginTimeStamp: Date = Date(timeIntervalSince1970: 0),
        endTimeStamp: Date? = nil,
        duration: Measurement<UnitDuration>? = nil,
        isInterval: Bool = false
    ) {
        self._subsystem = subsystem
        self._category = category
        self._name = name
        self._beginTimeStamp = beginTimeStamp
        self._endTimeStamp = endTimeStamp
        self._duration = duration
        self._isInterval = isInterval
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
            "subsystem": _subsystem,
            "category": _category,
            "name": _name,
            "beginTimeStamp": _beginTimeStamp.timeIntervalSince1970,
            "isInterval": _isInterval,
        ]
        if let end = _endTimeStamp {
            dict["endTimeStamp"] = end.timeIntervalSince1970
        }
        if let duration {
            dict["duration"] = MXSerialization.measurement(duration)
        }
        return dict
    }

    open func jsonRepresentation() -> Data {
        MXSerialization.jsonData(from: dictionaryRepresentation())
    }
}

open class MXCrashDiagnosticObjectiveCExceptionReason: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _composedMessage: String
    private let _formatString: String
    private let _arguments: [String]
    private let _exceptionType: String
    private let _className: String
    private let _exceptionName: String

    open var composedMessage: String { _composedMessage }
    open var formatString: String { _formatString }
    open var arguments: [String] { _arguments }
    open var exceptionType: String { _exceptionType }
    // Apple Foundation's NSObject exposes inherited `className`, so this
    // MetricKit getter must `override` there. swift-corelibs-Foundation's
    // NSObject does not have that member, so `override` is rejected on Linux.
    // The public API and `_className` storage stay the same on both.
#if canImport(ObjectiveC)
    open override var className: String { _className }
#else
    open var className: String { _className }
#endif
    open var exceptionName: String { _exceptionName }

    @_spi(OpenUIKitHost)
    public init(
        composedMessage: String = "",
        formatString: String = "",
        arguments: [String] = [],
        exceptionType: String = "",
        className: String = "",
        exceptionName: String = ""
    ) {
        self._composedMessage = composedMessage
        self._formatString = formatString
        self._arguments = arguments
        self._exceptionType = exceptionType
        self._className = className
        self._exceptionName = exceptionName
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
        [
            "composedMessage": _composedMessage,
            "formatString": _formatString,
            "arguments": _arguments,
            "exceptionType": _exceptionType,
            "className": _className,
            "exceptionName": _exceptionName,
        ]
    }

    open func jsonRepresentation() -> Data {
        MXSerialization.jsonData(from: dictionaryRepresentation())
    }
}

open class MXDiagnostic: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let _applicationVersion: String
    private let _metaData: MXMetaData
    private let _signpostData: [MXSignpostRecord]?

    open var applicationVersion: String { _applicationVersion }
    open var metaData: MXMetaData { _metaData }
    open var signpostData: [MXSignpostRecord]? { _signpostData }

    @_spi(OpenUIKitHost)
    public init(
        applicationVersion: String = "",
        metaData: MXMetaData = MXMetaData(),
        signpostData: [MXSignpostRecord]? = nil
    ) {
        self._applicationVersion = applicationVersion
        self._metaData = metaData
        self._signpostData = signpostData
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
            "applicationVersion": _applicationVersion,
            "metaData": _metaData.dictionaryRepresentation(),
        ]
        if let signpostData {
            dict["signpostData"] = signpostData.map { $0.dictionaryRepresentation() }
        }
        return dict
    }

    open func jsonRepresentation() -> Data {
        MXSerialization.jsonData(from: dictionaryRepresentation())
    }
}

open class MXAppLaunchDiagnostic: MXDiagnostic, @unchecked Sendable {
    private let _callStackTree: MXCallStackTree
    private let _launchDuration: Measurement<UnitDuration>

    open var callStackTree: MXCallStackTree { _callStackTree }
    open var launchDuration: Measurement<UnitDuration> { _launchDuration }

    @_spi(OpenUIKitHost)
    public init(
        applicationVersion: String = "",
        metaData: MXMetaData = MXMetaData(),
        signpostData: [MXSignpostRecord]? = nil,
        callStackTree: MXCallStackTree = MXCallStackTree(),
        launchDuration: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds)
    ) {
        self._callStackTree = callStackTree
        self._launchDuration = launchDuration
        super.init(applicationVersion: applicationVersion, metaData: metaData, signpostData: signpostData)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        var dict = super.dictionaryRepresentation()
        dict["launchDuration"] = MXSerialization.measurement(_launchDuration)
        dict["callStackTree"] = String(data: _callStackTree.jsonRepresentation(), encoding: .utf8) ?? "{}"
        return dict
    }
}

open class MXCPUExceptionDiagnostic: MXDiagnostic, @unchecked Sendable {
    private let _callStackTree: MXCallStackTree
    private let _totalCPUTime: Measurement<UnitDuration>
    private let _totalSampledTime: Measurement<UnitDuration>

    open var callStackTree: MXCallStackTree { _callStackTree }
    open var totalCPUTime: Measurement<UnitDuration> { _totalCPUTime }
    open var totalSampledTime: Measurement<UnitDuration> { _totalSampledTime }

    @_spi(OpenUIKitHost)
    public init(
        applicationVersion: String = "",
        metaData: MXMetaData = MXMetaData(),
        signpostData: [MXSignpostRecord]? = nil,
        callStackTree: MXCallStackTree = MXCallStackTree(),
        totalCPUTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds),
        totalSampledTime: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds)
    ) {
        self._callStackTree = callStackTree
        self._totalCPUTime = totalCPUTime
        self._totalSampledTime = totalSampledTime
        super.init(applicationVersion: applicationVersion, metaData: metaData, signpostData: signpostData)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        var dict = super.dictionaryRepresentation()
        dict["totalCPUTime"] = MXSerialization.measurement(_totalCPUTime)
        dict["totalSampledTime"] = MXSerialization.measurement(_totalSampledTime)
        dict["callStackTree"] = String(data: _callStackTree.jsonRepresentation(), encoding: .utf8) ?? "{}"
        return dict
    }
}

open class MXCrashDiagnostic: MXDiagnostic, @unchecked Sendable {
    private let _callStackTree: MXCallStackTree
    private let _terminationReason: String?
    private let _virtualMemoryRegionInfo: String?
    private let _exceptionType: NSNumber?
    private let _exceptionCode: NSNumber?
    private let _signal: NSNumber?
    private let _exceptionReason: MXCrashDiagnosticObjectiveCExceptionReason?

    open var callStackTree: MXCallStackTree { _callStackTree }
    open var terminationReason: String? { _terminationReason }
    open var virtualMemoryRegionInfo: String? { _virtualMemoryRegionInfo }
    open var exceptionType: NSNumber? { _exceptionType }
    open var exceptionCode: NSNumber? { _exceptionCode }
    open var signal: NSNumber? { _signal }
    open var exceptionReason: MXCrashDiagnosticObjectiveCExceptionReason? { _exceptionReason }

    @_spi(OpenUIKitHost)
    public init(
        applicationVersion: String = "",
        metaData: MXMetaData = MXMetaData(),
        signpostData: [MXSignpostRecord]? = nil,
        callStackTree: MXCallStackTree = MXCallStackTree(),
        terminationReason: String? = nil,
        virtualMemoryRegionInfo: String? = nil,
        exceptionType: NSNumber? = nil,
        exceptionCode: NSNumber? = nil,
        signal: NSNumber? = nil,
        exceptionReason: MXCrashDiagnosticObjectiveCExceptionReason? = nil
    ) {
        self._callStackTree = callStackTree
        self._terminationReason = terminationReason
        self._virtualMemoryRegionInfo = virtualMemoryRegionInfo
        self._exceptionType = exceptionType
        self._exceptionCode = exceptionCode
        self._signal = signal
        self._exceptionReason = exceptionReason
        super.init(applicationVersion: applicationVersion, metaData: metaData, signpostData: signpostData)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        var dict = super.dictionaryRepresentation()
        dict["callStackTree"] = String(data: _callStackTree.jsonRepresentation(), encoding: .utf8) ?? "{}"
        if let terminationReason { dict["terminationReason"] = terminationReason }
        if let virtualMemoryRegionInfo { dict["virtualMemoryRegionInfo"] = virtualMemoryRegionInfo }
        if let exceptionType { dict["exceptionType"] = exceptionType }
        if let exceptionCode { dict["exceptionCode"] = exceptionCode }
        if let signal { dict["signal"] = signal }
        if let exceptionReason {
            dict["exceptionReason"] = exceptionReason.dictionaryRepresentation()
        }
        return dict
    }
}

open class MXDiskWriteExceptionDiagnostic: MXDiagnostic, @unchecked Sendable {
    private let _callStackTree: MXCallStackTree
    private let _totalWritesCaused: Measurement<UnitInformationStorage>

    open var callStackTree: MXCallStackTree { _callStackTree }
    open var totalWritesCaused: Measurement<UnitInformationStorage> { _totalWritesCaused }

    @_spi(OpenUIKitHost)
    public init(
        applicationVersion: String = "",
        metaData: MXMetaData = MXMetaData(),
        signpostData: [MXSignpostRecord]? = nil,
        callStackTree: MXCallStackTree = MXCallStackTree(),
        totalWritesCaused: Measurement<UnitInformationStorage> = Measurement(value: 0, unit: UnitInformationStorage.bytes)
    ) {
        self._callStackTree = callStackTree
        self._totalWritesCaused = totalWritesCaused
        super.init(applicationVersion: applicationVersion, metaData: metaData, signpostData: signpostData)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        var dict = super.dictionaryRepresentation()
        dict["totalWritesCaused"] = MXSerialization.measurement(_totalWritesCaused)
        dict["callStackTree"] = String(data: _callStackTree.jsonRepresentation(), encoding: .utf8) ?? "{}"
        return dict
    }
}

open class MXHangDiagnostic: MXDiagnostic, @unchecked Sendable {
    private let _callStackTree: MXCallStackTree
    private let _hangDuration: Measurement<UnitDuration>

    open var callStackTree: MXCallStackTree { _callStackTree }
    open var hangDuration: Measurement<UnitDuration> { _hangDuration }

    @_spi(OpenUIKitHost)
    public init(
        applicationVersion: String = "",
        metaData: MXMetaData = MXMetaData(),
        signpostData: [MXSignpostRecord]? = nil,
        callStackTree: MXCallStackTree = MXCallStackTree(),
        hangDuration: Measurement<UnitDuration> = Measurement(value: 0, unit: UnitDuration.seconds)
    ) {
        self._callStackTree = callStackTree
        self._hangDuration = hangDuration
        super.init(applicationVersion: applicationVersion, metaData: metaData, signpostData: signpostData)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open override func dictionaryRepresentation() -> [AnyHashable: Any] {
        var dict = super.dictionaryRepresentation()
        dict["hangDuration"] = MXSerialization.measurement(_hangDuration)
        dict["callStackTree"] = String(data: _callStackTree.jsonRepresentation(), encoding: .utf8) ?? "{}"
        return dict
    }
}

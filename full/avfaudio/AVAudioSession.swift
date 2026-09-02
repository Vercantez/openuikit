import Foundation

public final class AVAudioSession: NSObject, @unchecked Sendable {
    public struct Category: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.init(rawValue: value) }
        public static let ambient = Category(rawValue: "AVAudioSessionCategoryAmbient")
        public static let soloAmbient = Category(rawValue: "AVAudioSessionCategorySoloAmbient")
        public static let playback = Category(rawValue: "AVAudioSessionCategoryPlayback")
        public static let record = Category(rawValue: "AVAudioSessionCategoryRecord")
        public static let playAndRecord = Category(rawValue: "AVAudioSessionCategoryPlayAndRecord")
        public static let multiRoute = Category(rawValue: "AVAudioSessionCategoryMultiRoute")
        public static let audioProcessing = Category(rawValue: "AVAudioSessionCategoryAudioProcessing")
    }

    public struct Mode: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.init(rawValue: value) }
        public static let `default` = Mode(rawValue: "AVAudioSessionModeDefault")
        public static let voiceChat = Mode(rawValue: "AVAudioSessionModeVoiceChat")
        public static let videoChat = Mode(rawValue: "AVAudioSessionModeVideoChat")
        public static let gameChat = Mode(rawValue: "AVAudioSessionModeGameChat")
        public static let videoRecording = Mode(rawValue: "AVAudioSessionModeVideoRecording")
        public static let measurement = Mode(rawValue: "AVAudioSessionModeMeasurement")
        public static let moviePlayback = Mode(rawValue: "AVAudioSessionModeMoviePlayback")
        public static let spokenAudio = Mode(rawValue: "AVAudioSessionModeSpokenAudio")
        public static let voicePrompt = Mode(rawValue: "AVAudioSessionModeVoicePrompt")
        public static let shortFormVideo = Mode(rawValue: "AVAudioSessionModeShortFormVideo")
    }

    public struct Port: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.init(rawValue: value) }
        public static let lineIn = Port(rawValue: "LineIn")
        public static let lineOut = Port(rawValue: "LineOut")
        public static let builtInMic = Port(rawValue: "MicrophoneBuiltIn")
        public static let builtInSpeaker = Port(rawValue: "Speaker")
        public static let headphones = Port(rawValue: "Headphones")
        public static let headsetMic = Port(rawValue: "HeadsetMic")
        public static let bluetoothA2DP = Port(rawValue: "BluetoothA2DPOutput")
        public static let bluetoothLE = Port(rawValue: "BluetoothLE")
        public static let bluetoothHFP = Port(rawValue: "BluetoothHFP")
        public static let usbAudio = Port(rawValue: "USBAudio")
        public static let carAudio = Port(rawValue: "CarAudio")
        public static let airPlay = Port(rawValue: "AirPlay")
        public static let HDMI = Port(rawValue: "HDMI")
        public static let displayPort = Port(rawValue: "DisplayPort")
        public static let fireWire = Port(rawValue: "FireWire")
        public static let PCI = Port(rawValue: "PCI")
        public static let thunderbolt = Port(rawValue: "Thunderbolt")
        public static let AVB = Port(rawValue: "AVB")
        public static let virtual = Port(rawValue: "Virtual")
        public static let builtInReceiver = Port(rawValue: "Receiver")
        public static let continuityMicrophone = Port(rawValue: "ContinuityMicrophone")
    }

    public struct Location: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let upper = Location(rawValue: "Upper")
        public static let lower = Location(rawValue: "Lower")
        public static var orientationTop: Location { Location(rawValue: "Top") }
        public static var orientationBottom: Location { Location(rawValue: "Bottom") }
        public static var orientationFront: Location { Location(rawValue: "Front") }
        public static var orientationBack: Location { Location(rawValue: "Back") }
        public static var orientationLeft: Location { Location(rawValue: "Left") }
        public static var orientationRight: Location { Location(rawValue: "Right") }
        public static var polarPatternOmnidirectional: Location {
            Location(rawValue: "Omnidirectional")
        }
        public static var polarPatternCardioid: Location { Location(rawValue: "Cardioid") }
        public static var polarPatternSubcardioid: Location { Location(rawValue: "Subcardioid") }
    }

    public struct Orientation: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let top = Orientation(rawValue: "Top")
        public static let bottom = Orientation(rawValue: "Bottom")
        public static let front = Orientation(rawValue: "Front")
        public static let back = Orientation(rawValue: "Back")
        public static let left = Orientation(rawValue: "Left")
        public static let right = Orientation(rawValue: "Right")
    }

    public struct PolarPattern: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let omnidirectional = PolarPattern(rawValue: "Omnidirectional")
        public static let cardioid = PolarPattern(rawValue: "Cardioid")
        public static let subcardioid = PolarPattern(rawValue: "Subcardioid")
        public static let stereo = PolarPattern(rawValue: "Stereo")
    }

    public struct CategoryOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let mixWithOthers = CategoryOptions(rawValue: 0x1)
        public static let duckOthers = CategoryOptions(rawValue: 0x2)
        public static let allowBluetooth = CategoryOptions(rawValue: 0x4)
        public static let defaultToSpeaker = CategoryOptions(rawValue: 0x8)
        public static let interruptSpokenAudioAndMixWithOthers = CategoryOptions(rawValue: 0x11)
        public static let allowBluetoothA2DP = CategoryOptions(rawValue: 0x20)
        public static let allowAirPlay = CategoryOptions(rawValue: 0x40)
        public static let overrideMutedMicrophoneInterruption = CategoryOptions(rawValue: 0x80)
        public static let allowBluetoothHFP = CategoryOptions(rawValue: 0x100)
        public static let bluetoothHighQualityRecording = CategoryOptions(rawValue: 0x200)
    }

    public struct SetActiveOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let notifyOthersOnDeactivation = SetActiveOptions(rawValue: 1 << 0)
    }

    public struct InterruptionOptions: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let shouldResume = InterruptionOptions(rawValue: 1 << 0)
    }

    public enum IOType: UInt, Hashable, Sendable {
        case notSpecified = 0
        case aggregated = 1
    }

    public enum InterruptionType: UInt, Hashable, Sendable {
        case ended = 0
        case began = 1
    }

    public enum InterruptionReason: UInt, Hashable, Sendable {
        case `default` = 0
        case builtInMicMuted = 1
        case appWasSuspended = 2
        case routeDisconnected = 4
    }

    public enum PortOverride: UInt, Hashable, Sendable {
        case none = 0
        case speaker = 0x73706B72
    }

    public enum RouteChangeReason: UInt, Hashable, Sendable {
        case unknown = 0
        case newDeviceAvailable = 1
        case oldDeviceUnavailable = 2
        case categoryChange = 3
        case override = 4
        case wakeFromSleep = 5
        case noSuitableRouteForCategory = 6
        case routeConfigurationChange = 7
    }

    public enum RouteSharingPolicy: UInt, Hashable, Sendable {
        case `default` = 0
        case longFormAudio = 1
        case independent = 2
        case longFormVideo = 3
        public static var longForm: RouteSharingPolicy { .longFormAudio }
    }

    public enum RecordPermission: UInt, Hashable, Sendable {
        case undetermined = 1970168948
        case denied = 1684369017
        case granted = 1735552628
    }

    public enum SilenceSecondaryAudioHintType: UInt, Hashable, Sendable {
        case end = 0
        case begin = 1
    }

    public enum PromptStyle: UInt, Hashable, Sendable {
        case none = 0x6E6F6E65
        case short = 0x73687274
        case normal = 0x6E726D6C
    }

    public enum StereoOrientation: Int, Hashable, Sendable {
        case none = 0
        case portrait = 1
        case portraitUpsideDown = 2
        case landscapeRight = 3
        case landscapeLeft = 4
    }

    public enum RenderingMode: Int, Hashable, Sendable {
        case notApplicable = 0
        case monoStereo = 1
        case surround = 2
        case spatialAudio = 3
        case dolbyAudio = 4
        case dolbyAtmos = 5
    }

    public enum MicrophoneInjectionMode: Int, Hashable, Sendable {
        case none = 0
        case spokenAudio = 1
    }

    public static let interruptionNotification = NSNotification.Name(
        "AVAudioSessionInterruptionNotification"
    )
    public static let routeChangeNotification = NSNotification.Name(
        "AVAudioSessionRouteChangeNotification"
    )
    public static let mediaServicesWereLostNotification = NSNotification.Name(
        "AVAudioSessionMediaServicesWereLostNotification"
    )
    public static let mediaServicesWereResetNotification = NSNotification.Name(
        "AVAudioSessionMediaServicesWereResetNotification"
    )
    public static let silenceSecondaryAudioHintNotification = NSNotification.Name(
        "AVAudioSessionSilenceSecondaryAudioHintNotification"
    )
    public static let spatialPlaybackCapabilitiesChangedNotification = NSNotification.Name(
        "AVAudioSessionSpatialPlaybackCapabilitiesChangedNotification"
    )
    public static let availableInputsChangeNotification = NSNotification.Name(
        "AVAudioSessionAvailableInputsChangeNotification"
    )
    public static let renderingModeChangeNotification = NSNotification.Name(
        "AVAudioSessionRenderingModeChangeNotification"
    )
    public static let renderingCapabilitiesChangeNotification = NSNotification.Name(
        "AVAudioSessionRenderingCapabilitiesChangeNotification"
    )
    public static let microphoneInjectionCapabilitiesChangeNotification = NSNotification.Name(
        "AVAudioSessionMicrophoneInjectionCapabilitiesChangeNotification"
    )
    public static let outputMuteStateChangeNotification = NSNotification.Name(
        "AVAudioSessionOutputMuteStateChangeNotification"
    )
    public static let userIntentToUnmuteOutputNotification = NSNotification.Name(
        "AVAudioSessionUserIntentToUnmuteOutputNotification"
    )
    public static let muteStateKey = "AVAudioSessionMuteStateKey"

    private static let sharedSession = AVAudioSession()
    private let lock = NSLock()
    private var storedCategory = Category.soloAmbient
    private var storedMode = Mode.default
    private var storedOptions = CategoryOptions()
    private var storedActive = false
    private var storedSampleRate: Double = 0
    private var storedPreferredSampleRate: Double = 0
    private var storedIOBufferDuration: TimeInterval = 0
    private var storedPreferredIOBufferDuration: TimeInterval = 0
    private var storedOutputMuted = false
    private var storedAllowHaptics = false
    private var storedSupportsMultichannel = false
    private var storedPrefersEchoCancelled = false
    private var storedPrefersInterruptionOnDisconnect = true
    private var storedPrefersNoInterruptionsFromAlerts = false
    private var storedPreferredInputChannels = 0
    private var storedPreferredOutputChannels = 2
    private var storedPreferredInputOrientation = StereoOrientation.none
    private var storedPreferredInjection = MicrophoneInjectionMode.none
    private var storedPolicy = RouteSharingPolicy.default
    private var storedPreferredInput: AVAudioSessionPortDescription?
    private var storedInputDataSource: AVAudioSessionDataSourceDescription?
    private var storedOutputDataSource: AVAudioSessionDataSourceDescription?
    private var storedRoute = AVAudioSessionRouteDescription.emptyRoute()
    private var storedIOType = IOType.notSpecified

    public class func sharedInstance() -> AVAudioSession { sharedSession }

    public var category: Category { avfaudioLock(lock) { storedCategory } }
    public var mode: Mode { avfaudioLock(lock) { storedMode } }
    public var categoryOptions: CategoryOptions { avfaudioLock(lock) { storedOptions } }
    public var routeSharingPolicy: RouteSharingPolicy { avfaudioLock(lock) { storedPolicy } }
    public var sampleRate: Double { avfaudioLock(lock) { storedSampleRate } }
    public var preferredSampleRate: Double { avfaudioLock(lock) { storedPreferredSampleRate } }
    public var ioBufferDuration: TimeInterval { avfaudioLock(lock) { storedIOBufferDuration } }
    public var preferredIOBufferDuration: TimeInterval {
        avfaudioLock(lock) { storedPreferredIOBufferDuration }
    }
    public var isOutputMuted: Bool { avfaudioLock(lock) { storedOutputMuted } }
    public var outputVolume: Float { 0 }
    public var inputGain: Float { 0 }
    public var isInputGainSettable: Bool { false }
    public var isInputAvailable: Bool { false }
    public var isOtherAudioPlaying: Bool { false }
    public var secondaryAudioShouldBeSilencedHint: Bool { false }
    public var inputNumberOfChannels: Int { 0 }
    public var outputNumberOfChannels: Int { 0 }
    public var maximumInputNumberOfChannels: Int { 0 }
    public var maximumOutputNumberOfChannels: Int { 0 }
    public var preferredInputNumberOfChannels: Int {
        avfaudioLock(lock) { storedPreferredInputChannels }
    }
    public var preferredOutputNumberOfChannels: Int {
        avfaudioLock(lock) { storedPreferredOutputChannels }
    }
    public var inputLatency: TimeInterval { 0 }
    public var outputLatency: TimeInterval { 0 }
    public var currentRoute: AVAudioSessionRouteDescription { avfaudioLock(lock) { storedRoute } }
    public var availableInputs: [AVAudioSessionPortDescription]? { nil }
    public var availableCategories: [Category] {
        [.ambient, .soloAmbient, .playback, .record, .playAndRecord, .multiRoute]
    }
    public var availableModes: [Mode] {
        [
            .default, .voiceChat, .videoChat, .gameChat, .videoRecording, .measurement,
            .moviePlayback, .spokenAudio, .voicePrompt, .shortFormVideo,
        ]
    }
    public var recordPermission: RecordPermission { .denied }
    public var promptStyle: PromptStyle { .none }
    public var renderingMode: RenderingMode { .notApplicable }
    public var inputOrientation: StereoOrientation { .none }
    public var preferredInputOrientation: StereoOrientation {
        avfaudioLock(lock) { storedPreferredInputOrientation }
    }
    public var preferredInput: AVAudioSessionPortDescription? {
        avfaudioLock(lock) { storedPreferredInput }
    }
    public var preferredMicrophoneInjectionMode: MicrophoneInjectionMode {
        avfaudioLock(lock) { storedPreferredInjection }
    }
    public var isMicrophoneInjectionAvailable: Bool { false }
    public var isEchoCancelledInputAvailable: Bool { false }
    public var isEchoCancelledInputEnabled: Bool { false }
    public var prefersEchoCancelledInput: Bool {
        avfaudioLock(lock) { storedPrefersEchoCancelled }
    }
    public var prefersInterruptionOnRouteDisconnect: Bool {
        avfaudioLock(lock) { storedPrefersInterruptionOnDisconnect }
    }
    public var prefersNoInterruptionsFromSystemAlerts: Bool {
        avfaudioLock(lock) { storedPrefersNoInterruptionsFromAlerts }
    }
    public var allowHapticsAndSystemSoundsDuringRecording: Bool {
        avfaudioLock(lock) { storedAllowHaptics }
    }
    public var supportsMultichannelContent: Bool {
        avfaudioLock(lock) { storedSupportsMultichannel }
    }
    public var supportedOutputChannelLayouts: [AVAudioChannelLayout] { [] }
    public var inputDataSource: AVAudioSessionDataSourceDescription? {
        avfaudioLock(lock) { storedInputDataSource }
    }
    public var outputDataSource: AVAudioSessionDataSourceDescription? {
        avfaudioLock(lock) { storedOutputDataSource }
    }
    public var inputDataSources: [AVAudioSessionDataSourceDescription]? { nil }
    public var outputDataSources: [AVAudioSessionDataSourceDescription]? { nil }

    public func setCategory(_ category: Category) throws {
        try setCategory(category, mode: .default, options: [])
    }

    public func setCategory(_ category: Category, options: CategoryOptions = []) throws {
        try setCategory(category, mode: .default, options: options)
    }

    public func setCategory(
        _ category: Category,
        mode: Mode,
        options: CategoryOptions = []
    ) throws {
        avfaudioLock(lock) {
            storedCategory = category
            storedMode = mode
            storedOptions = options
        }
    }

    public func setCategory(
        _ category: Category,
        mode: Mode,
        policy: RouteSharingPolicy,
        options: CategoryOptions = []
    ) throws {
        avfaudioLock(lock) {
            storedCategory = category
            storedMode = mode
            storedOptions = options
            storedPolicy = policy
        }
    }

    public func setMode(_ mode: Mode) throws {
        avfaudioLock(lock) { storedMode = mode }
    }

    public func setActive(_ active: Bool, options: SetActiveOptions = []) throws {
        _ = active
        _ = options
        throw avfaudioHostUnavailableError(
            "AVAudioSession activation requires a host audio session service."
        )
    }

    public func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        AVFAudioCallbackDelivery.deliverExactlyOnce {
            response(false)
        }
    }

    public func overrideOutputAudioPort(_ portOverride: PortOverride) throws {
        _ = portOverride
        throw avfaudioHostUnavailableError(
            "Output port override requires a host audio session service."
        )
    }

    public func setPreferredSampleRate(_ sampleRate: Double) throws {
        _ = sampleRate
        throw avfaudioHostUnavailableError(
            "Hardware sample-rate configuration requires a host audio session service."
        )
    }

    public func setPreferredIOBufferDuration(_ duration: TimeInterval) throws {
        _ = duration
        throw avfaudioHostUnavailableError(
            "Hardware IO buffer configuration requires a host audio session service."
        )
    }

    public func setPreferredInput(_ inPort: AVAudioSessionPortDescription?) throws {
        _ = inPort
        throw avfaudioHostUnavailableError(
            "Preferred input selection requires a host audio session service."
        )
    }

    public func setPreferredInputNumberOfChannels(_ count: Int) throws {
        _ = count
        throw avfaudioHostUnavailableError(
            "Hardware channel configuration requires a host audio session service."
        )
    }

    public func setPreferredOutputNumberOfChannels(_ count: Int) throws {
        _ = count
        throw avfaudioHostUnavailableError(
            "Hardware channel configuration requires a host audio session service."
        )
    }

    public func setPreferredInputOrientation(_ orientation: StereoOrientation) throws {
        _ = orientation
        throw avfaudioHostUnavailableError(
            "Input orientation configuration requires a host audio session service."
        )
    }

    public func setPreferredMicrophoneInjectionMode(_ inValue: MicrophoneInjectionMode) throws {
        _ = inValue
        throw avfaudioHostUnavailableError(
            "Microphone injection requires a host audio session service."
        )
    }

    public func setOutputMuted(_ muted: Bool) throws {
        _ = muted
        throw avfaudioHostUnavailableError(
            "Output mute requires a host audio session service."
        )
    }

    public func setInputGain(_ gain: Float) throws {
        _ = gain
        throw avfaudioHostUnavailableError(
            "Input gain requires a host audio session service."
        )
    }

    public func setInputDataSource(_ dataSource: AVAudioSessionDataSourceDescription?) throws {
        _ = dataSource
        throw avfaudioHostUnavailableError(
            "Input data source selection requires a host audio session service."
        )
    }

    public func setOutputDataSource(_ dataSource: AVAudioSessionDataSourceDescription?) throws {
        _ = dataSource
        throw avfaudioHostUnavailableError(
            "Output data source selection requires a host audio session service."
        )
    }

    public func setAggregatedIOPreference(_ inIOType: IOType) throws {
        _ = inIOType
        throw avfaudioHostUnavailableError(
            "Aggregated IO preference requires a host audio session service."
        )
    }

    public func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws {
        _ = inValue
        throw avfaudioHostUnavailableError(
            "Haptics-during-recording preference requires a host audio session service."
        )
    }

    public func setSupportsMultichannelContent(_ inValue: Bool) throws {
        _ = inValue
        throw avfaudioHostUnavailableError(
            "Multichannel content preference requires a host audio session service."
        )
    }

    public func setPrefersEchoCancelledInput(_ value: Bool) throws {
        _ = value
        throw avfaudioHostUnavailableError(
            "Echo-cancelled input preference requires a host audio session service."
        )
    }

    public func setPrefersInterruptionOnRouteDisconnect(_ inValue: Bool) throws {
        _ = inValue
        throw avfaudioHostUnavailableError(
            "Route-disconnect interruption preference requires a host audio session service."
        )
    }

    public func setPrefersNoInterruptionsFromSystemAlerts(_ inValue: Bool) throws {
        _ = inValue
        throw avfaudioHostUnavailableError(
            "System-alert interruption preference requires a host audio session service."
        )
    }

    internal var isActiveForInspection: Bool { avfaudioLock(lock) { storedActive } }
}

public final class AVAudioSessionRouteDescription: NSObject, @unchecked Sendable {
    public private(set) var inputs: [AVAudioSessionPortDescription]
    public private(set) var outputs: [AVAudioSessionPortDescription]

    public override init() {
        self.inputs = []
        self.outputs = []
        super.init()
    }

    init(inputs: [AVAudioSessionPortDescription], outputs: [AVAudioSessionPortDescription]) {
        self.inputs = inputs
        self.outputs = outputs
        super.init()
    }

    static func emptyRoute() -> AVAudioSessionRouteDescription {
        AVAudioSessionRouteDescription(inputs: [], outputs: [])
    }
}

public final class AVAudioSessionPortDescription: NSObject, @unchecked Sendable {
    public let portName: String
    public let portType: AVAudioSession.Port
    public let uid: String
    public var hasHardwareVoiceCallProcessing: Bool { false }
    public var isSpatialAudioEnabled: Bool { false }
    public var channels: [AVAudioSessionChannelDescription]? { nil }
    public var dataSources: [AVAudioSessionDataSourceDescription]? { nil }
    public var selectedDataSource: AVAudioSessionDataSourceDescription? { nil }
    public var preferredDataSource: AVAudioSessionDataSourceDescription? { nil }

    public init(portType: AVAudioSession.Port, portName: String, uid: String) {
        self.portType = portType
        self.portName = portName
        self.uid = uid
        super.init()
    }

    public func setPreferredDataSource(_ dataSource: AVAudioSessionDataSourceDescription?) throws {
        _ = dataSource
        throw avfaudioHostUnavailableError(
            "Preferred data source requires a host audio session service."
        )
    }
}

public final class AVAudioSessionChannelDescription: NSObject, @unchecked Sendable {
    public let channelName: String
    public let channelNumber: Int
    public let owningPortUID: String
    public let channelLabel: UInt32

    public init(
        channelName: String,
        channelNumber: Int,
        owningPortUID: String,
        channelLabel: UInt32
    ) {
        self.channelName = channelName
        self.channelNumber = channelNumber
        self.owningPortUID = owningPortUID
        self.channelLabel = channelLabel
        super.init()
    }
}

public final class AVAudioSessionDataSourceDescription: NSObject, @unchecked Sendable {
    public let dataSourceID: NSNumber
    public let dataSourceName: String
    public let location: AVAudioSession.Location?
    public let orientation: AVAudioSession.Orientation?
    public private(set) var preferredPolarPattern: AVAudioSession.PolarPattern?
    public var selectedPolarPattern: AVAudioSession.PolarPattern? { preferredPolarPattern }
    public var supportedPolarPatterns: [AVAudioSession.PolarPattern]? {
        [.omnidirectional, .cardioid, .subcardioid]
    }

    public init(
        dataSourceID: NSNumber,
        dataSourceName: String,
        location: AVAudioSession.Location? = nil,
        orientation: AVAudioSession.Orientation? = nil
    ) {
        self.dataSourceID = dataSourceID
        self.dataSourceName = dataSourceName
        self.location = location
        self.orientation = orientation
        super.init()
    }

    public func setPreferredPolarPattern(_ pattern: AVAudioSession.PolarPattern?) throws {
        preferredPolarPattern = pattern
    }
}

public final class AVAudioSessionCapability: NSObject, @unchecked Sendable {
    public let isSupported: Bool
    public let isEnabled: Bool
    public init(isSupported: Bool = false, isEnabled: Bool = false) {
        self.isSupported = isSupported
        self.isEnabled = isEnabled
        super.init()
    }
}

public final class AVAudioSessionPortExtensionBluetoothMicrophone: NSObject, @unchecked Sendable {
    public var highQualityRecording: AVAudioSessionCapability {
        AVAudioSessionCapability(isSupported: false, isEnabled: false)
    }
    public var farFieldCapture: AVAudioSessionCapability {
        AVAudioSessionCapability(isSupported: false, isEnabled: false)
    }
}

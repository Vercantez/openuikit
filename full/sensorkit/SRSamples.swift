import Foundation

public class SRAmbientLightSample: NSObject {
    public enum SensorPlacement: Int, Hashable, Sendable {
        case unknown = 0
        case frontTop = 1
        case frontBottom = 2
        case frontRight = 3
        case frontLeft = 4
        case frontTopRight = 5
        case frontTopLeft = 6
        case frontBottomRight = 7
        case frontBottomLeft = 8
    }

    public struct Chromaticity: Hashable, Sendable {
        public var x: Float32
        public var y: Float32

        public init() {
            self.x = 0
            self.y = 0
        }

        public init(x: Float32, y: Float32) {
            self.x = x
            self.y = y
        }
    }

    public private(set) var chromaticity: Chromaticity
    public private(set) var lux: Measurement<UnitIlluminance>
    public private(set) var placement: SensorPlacement

    @_spi(OpenUIKitHost)
    public init(
        chromaticity: Chromaticity,
        lux: Measurement<UnitIlluminance>,
        placement: SensorPlacement
    ) {
        self.chromaticity = chromaticity
        self.lux = lux
        self.placement = placement
        super.init()
    }
}

public class SRWristDetection: NSObject {
    public enum CrownOrientation: Int, Hashable, Sendable {
        case left = 0
        case right = 1
    }

    public enum WristLocation: Int, Hashable, Sendable {
        case left = 0
        case right = 1
    }

    public private(set) var crownOrientation: CrownOrientation
    public private(set) var offWristDate: Date?
    public private(set) var onWrist: Bool
    public private(set) var onWristDate: Date?
    public private(set) var wristLocation: WristLocation

    @_spi(OpenUIKitHost)
    public init(
        crownOrientation: CrownOrientation,
        offWristDate: Date?,
        onWrist: Bool,
        onWristDate: Date?,
        wristLocation: WristLocation
    ) {
        self.crownOrientation = crownOrientation
        self.offWristDate = offWristDate
        self.onWrist = onWrist
        self.onWristDate = onWristDate
        self.wristLocation = wristLocation
        super.init()
    }
}

public class SRWristTemperature: NSObject {
    public struct Condition: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let offWrist = Condition(rawValue: 1 << 0)
        public static let onCharger = Condition(rawValue: 1 << 1)
        public static let inMotion = Condition(rawValue: 1 << 2)
    }

    public private(set) var condition: Condition
    public private(set) var errorEstimate: Measurement<UnitTemperature>
    public private(set) var timestamp: Date
    public private(set) var value: Measurement<UnitTemperature>

    @_spi(OpenUIKitHost)
    public init(
        condition: Condition,
        errorEstimate: Measurement<UnitTemperature>,
        timestamp: Date,
        value: Measurement<UnitTemperature>
    ) {
        self.condition = condition
        self.errorEstimate = errorEstimate
        self.timestamp = timestamp
        self.value = value
        super.init()
    }
}

public class SRWristTemperatureSession: NSObject {
    public private(set) var duration: TimeInterval
    public private(set) var startDate: Date
    public private(set) var version: String
    private let _temperatures: [SRWristTemperature]

    public var temperatures: some Sequence<SRWristTemperature> { _temperatures }

    @_spi(OpenUIKitHost)
    public init(
        duration: TimeInterval,
        startDate: Date,
        version: String,
        temperatures: [SRWristTemperature]
    ) {
        self.duration = duration
        self.startDate = startDate
        self.version = version
        self._temperatures = temperatures
        super.init()
    }
}

public class SRElectrocardiogramData: NSObject {
    public struct Flags: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let signalInvalid = Flags(rawValue: 1 << 0)
        public static let crownTouched = Flags(rawValue: 1 << 1)
    }

    public private(set) var flags: Flags
    public private(set) var value: Measurement<UnitElectricPotentialDifference>

    @_spi(OpenUIKitHost)
    public init(flags: Flags, value: Measurement<UnitElectricPotentialDifference>) {
        self.flags = flags
        self.value = value
        super.init()
    }
}

public class SRElectrocardiogramSession: NSObject {
    public enum SessionGuidance: Int, Hashable, Sendable {
        case guided = 1
        case unguided = 2
    }

    public enum State: Int, Hashable, Sendable {
        case begin = 1
        case active = 2
        case end = 3
    }

    public private(set) var identifier: String
    public private(set) var sessionGuidance: SessionGuidance
    public private(set) var state: State

    @_spi(OpenUIKitHost)
    public init(identifier: String, sessionGuidance: SessionGuidance, state: State) {
        self.identifier = identifier
        self.sessionGuidance = sessionGuidance
        self.state = state
        super.init()
    }
}

public class SRElectrocardiogramSample: NSObject {
    public enum Lead: Int, Hashable, Sendable {
        case rightArmMinusLeftArm = 1
        case leftArmMinusRightArm = 2
    }

    public private(set) var data: [SRElectrocardiogramData]
    public private(set) var date: Date
    public private(set) var frequency: Measurement<UnitFrequency>
    public private(set) var lead: Lead
    public private(set) var session: SRElectrocardiogramSession

    @_spi(OpenUIKitHost)
    public init(
        data: [SRElectrocardiogramData],
        date: Date,
        frequency: Measurement<UnitFrequency>,
        lead: Lead,
        session: SRElectrocardiogramSession
    ) {
        self.data = data
        self.date = date
        self.frequency = frequency
        self.lead = lead
        self.session = session
        super.init()
    }
}

public class SRPhotoplethysmogramOpticalSample: NSObject {
    public struct Condition: RawRepresentable, Hashable, Sendable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let signalSaturation = Condition(rawValue: "SRPhotoplethysmogramOpticalSampleConditionSignalSaturation")
        public static let unreliableNoise = Condition(rawValue: "SRPhotoplethysmogramOpticalSampleConditionUnreliableNoise")
    }

    public struct NoiseTerms: Hashable, Sendable {
        public let backgroundNoise: Double
        public let backgroundNoiseOffset: Double
        public let pinkNoise: Double
        public let whiteNoise: Double

        public init(
            backgroundNoise: Double,
            backgroundNoiseOffset: Double,
            pinkNoise: Double,
            whiteNoise: Double
        ) {
            self.backgroundNoise = backgroundNoise
            self.backgroundNoiseOffset = backgroundNoiseOffset
            self.pinkNoise = pinkNoise
            self.whiteNoise = whiteNoise
        }
    }

    public private(set) var activePhotodiodeIndexes: IndexSet
    public private(set) var conditions: [Condition]
    public private(set) var effectiveWavelength: Measurement<UnitLength>
    public private(set) var emitter: Int
    public private(set) var nanosecondsSinceStart: Int64
    public private(set) var nominalWavelength: Measurement<UnitLength>
    public private(set) var samplingFrequency: Measurement<UnitFrequency>
    public private(set) var signalIdentifier: Int
    public private(set) var noiseTerms: NoiseTerms?
    public private(set) var normalizedReflectance: Double?

    @_spi(OpenUIKitHost)
    public init(
        activePhotodiodeIndexes: IndexSet,
        conditions: [Condition],
        effectiveWavelength: Measurement<UnitLength>,
        emitter: Int,
        nanosecondsSinceStart: Int64,
        nominalWavelength: Measurement<UnitLength>,
        samplingFrequency: Measurement<UnitFrequency>,
        signalIdentifier: Int,
        noiseTerms: NoiseTerms? = nil,
        normalizedReflectance: Double? = nil
    ) {
        self.activePhotodiodeIndexes = activePhotodiodeIndexes
        self.conditions = conditions
        self.effectiveWavelength = effectiveWavelength
        self.emitter = emitter
        self.nanosecondsSinceStart = nanosecondsSinceStart
        self.nominalWavelength = nominalWavelength
        self.samplingFrequency = samplingFrequency
        self.signalIdentifier = signalIdentifier
        self.noiseTerms = noiseTerms
        self.normalizedReflectance = normalizedReflectance
        super.init()
    }
}

public class SRPhotoplethysmogramAccelerometerSample: NSObject {
    public private(set) var nanosecondsSinceStart: Int64
    public private(set) var samplingFrequency: Measurement<UnitFrequency>
    public private(set) var x: Measurement<UnitAcceleration>
    public private(set) var y: Measurement<UnitAcceleration>
    public private(set) var z: Measurement<UnitAcceleration>

    @_spi(OpenUIKitHost)
    public init(
        nanosecondsSinceStart: Int64,
        samplingFrequency: Measurement<UnitFrequency>,
        x: Measurement<UnitAcceleration>,
        y: Measurement<UnitAcceleration>,
        z: Measurement<UnitAcceleration>
    ) {
        self.nanosecondsSinceStart = nanosecondsSinceStart
        self.samplingFrequency = samplingFrequency
        self.x = x
        self.y = y
        self.z = z
        super.init()
    }
}

public class SRPhotoplethysmogramSample: NSObject {
    public struct Usage: RawRepresentable, Hashable, Sendable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let backgroundSystem = Usage(rawValue: "SRPhotoplethysmogramSampleUsageBackgroundSystem")
        public static let deepBreathing = Usage(rawValue: "SRPhotoplethysmogramSampleUsageDeepBreathing")
        public static let foregroundBloodOxygen = Usage(rawValue: "SRPhotoplethysmogramSampleUsageForegroundBloodOxygen")
        public static let foregroundHeartRate = Usage(rawValue: "SRPhotoplethysmogramSampleUsageForegroundHeartRate")
    }

    public private(set) var accelerometerSamples: [SRPhotoplethysmogramAccelerometerSample]
    public private(set) var nanosecondsSinceStart: Int64
    public private(set) var opticalSamples: [SRPhotoplethysmogramOpticalSample]
    public private(set) var startDate: Date
    public private(set) var temperature: Measurement<UnitTemperature>?
    public private(set) var usage: [Usage]

    @_spi(OpenUIKitHost)
    public init(
        accelerometerSamples: [SRPhotoplethysmogramAccelerometerSample],
        nanosecondsSinceStart: Int64,
        opticalSamples: [SRPhotoplethysmogramOpticalSample],
        startDate: Date,
        temperature: Measurement<UnitTemperature>?,
        usage: [Usage]
    ) {
        self.accelerometerSamples = accelerometerSamples
        self.nanosecondsSinceStart = nanosecondsSinceStart
        self.opticalSamples = opticalSamples
        self.startDate = startDate
        self.temperature = temperature
        self.usage = usage
        super.init()
    }
}

public class SRSleepSession: NSObject {
    public private(set) var duration: TimeInterval
    public private(set) var identifier: String
    public private(set) var startDate: Date

    @_spi(OpenUIKitHost)
    public init(duration: TimeInterval, identifier: String, startDate: Date) {
        self.duration = duration
        self.identifier = identifier
        self.startDate = startDate
        super.init()
    }
}

public class SRAudioLevel: NSObject {
    public private(set) var loudness: Double

    @_spi(OpenUIKitHost)
    public init(loudness: Double) {
        self.loudness = loudness
        super.init()
    }
}

public class SRSpeechExpression: NSObject {
    public private(set) var activation: Double
    public private(set) var confidence: Double
    public private(set) var dominance: Double
    public private(set) var mood: Double
    public private(set) var valence: Double
    public private(set) var version: String

    @_spi(OpenUIKitHost)
    public init(
        activation: Double,
        confidence: Double,
        dominance: Double,
        mood: Double,
        valence: Double,
        version: String
    ) {
        self.activation = activation
        self.confidence = confidence
        self.dominance = dominance
        self.mood = mood
        self.valence = valence
        self.version = version
        super.init()
    }
}

public class SRSpeechMetrics: NSObject {
    public struct SessionFlags: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let bypassVoiceProcessing = SessionFlags(rawValue: 1 << 0)
    }

    public private(set) var audioLevel: SRAudioLevel?
    public private(set) var sessionFlags: SessionFlags
    public private(set) var sessionIdentifier: String
    public private(set) var speechExpression: SRSpeechExpression?
    public private(set) var timeSinceAudioStart: TimeInterval
    public private(set) var timestamp: Date

    @_spi(OpenUIKitHost)
    public init(
        audioLevel: SRAudioLevel?,
        sessionFlags: SessionFlags,
        sessionIdentifier: String,
        speechExpression: SRSpeechExpression?,
        timeSinceAudioStart: TimeInterval,
        timestamp: Date
    ) {
        self.audioLevel = audioLevel
        self.sessionFlags = sessionFlags
        self.sessionIdentifier = sessionIdentifier
        self.speechExpression = speechExpression
        self.timeSinceAudioStart = timeSinceAudioStart
        self.timestamp = timestamp
        super.init()
    }
}

public class SRFaceMetricsExpression: NSObject {
    public private(set) var identifier: String
    public private(set) var value: Double

    @_spi(OpenUIKitHost)
    public init(identifier: String, value: Double) {
        self.identifier = identifier
        self.value = value
        super.init()
    }
}

public class SRFaceMetrics: NSObject {
    public struct Context: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let deviceUnlock = Context(rawValue: 1 << 0)
        public static let messagingAppUsage = Context(rawValue: 1 << 1)
    }

    public private(set) var context: Context
    public private(set) var partialFaceExpressions: [SRFaceMetricsExpression]
    public private(set) var sessionIdentifier: String
    public private(set) var version: String
    public private(set) var wholeFaceExpressions: [SRFaceMetricsExpression]

    @_spi(OpenUIKitHost)
    public init(
        context: Context,
        partialFaceExpressions: [SRFaceMetricsExpression],
        sessionIdentifier: String,
        version: String,
        wholeFaceExpressions: [SRFaceMetricsExpression]
    ) {
        self.context = context
        self.partialFaceExpressions = partialFaceExpressions
        self.sessionIdentifier = sessionIdentifier
        self.version = version
        self.wholeFaceExpressions = wholeFaceExpressions
        super.init()
    }
}

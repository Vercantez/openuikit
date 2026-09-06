import Foundation

#if canImport(AVFAudio)
import AVFAudio
#endif

public class PHASESoundEventNodeDefinition: PHASEDefinition {
    public private(set) var children: [PHASESoundEventNodeDefinition] = []

    init(nodeIdentifier identifier: String) {
        super.init(definitionIdentifier: identifier)
    }

    func appendChild(_ child: PHASESoundEventNodeDefinition) {
        children.append(child)
    }
}

public class PHASEGeneratorNodeDefinition: PHASESoundEventNodeDefinition {
    public private(set) var calibrationMode: PHASECalibrationMode = .none
    public private(set) var level: Double = 0
    public var rate: Double = 1
    public weak var group: PHASEGroup?
    public var gainMetaParameterDefinition: PHASENumberMetaParameterDefinition?
    public var rateMetaParameterDefinition: PHASENumberMetaParameterDefinition?
    public let mixerDefinition: PHASEMixerDefinition

    init(identifier: String, mixerDefinition: PHASEMixerDefinition) {
        self.mixerDefinition = mixerDefinition
        super.init(nodeIdentifier: identifier)
    }

    public func setCalibrationMode(calibrationMode: PHASECalibrationMode, level: Double) {
        self.calibrationMode = calibrationMode
        self.level = level
    }
}

public final class PHASESamplerNodeDefinition: PHASEGeneratorNodeDefinition {
    public let assetIdentifier: String
    public var cullOption: PHASECullOption = .terminate
    public var playbackMode: PHASEPlaybackMode = .oneShot

    public init(soundAssetIdentifier: String, mixerDefinition: PHASEMixerDefinition) {
        self.assetIdentifier = soundAssetIdentifier
        super.init(identifier: phaseGeneratedIdentifier(), mixerDefinition: mixerDefinition)
    }

    public convenience init(
        soundAssetIdentifier: String,
        mixerDefinition: PHASEMixerDefinition,
        identifier: String
    ) {
        self.init(
            hostAsset: soundAssetIdentifier,
            mixerDefinition: mixerDefinition,
            identifier: identifier
        )
    }

    init(
        hostAsset soundAssetIdentifier: String,
        mixerDefinition: PHASEMixerDefinition,
        identifier: String
    ) {
        self.assetIdentifier = soundAssetIdentifier
        super.init(identifier: identifier, mixerDefinition: mixerDefinition)
    }
}

public final class PHASEContainerNodeDefinition: PHASESoundEventNodeDefinition {
    public init() {
        super.init(nodeIdentifier: phaseGeneratedIdentifier())
    }

    public init(identifier: String) {
        super.init(nodeIdentifier: identifier)
    }

    public class func new() -> Self {
        Self.init()
    }

    public func addSubtree(_ subtree: PHASESoundEventNodeDefinition) {
        appendChild(subtree)
    }
}

public final class PHASEBlendNodeDefinition: PHASESoundEventNodeDefinition {
    public private(set) var blendParameterDefinition: PHASENumberMetaParameterDefinition?
    public private(set) var spatialMixerDefinitionForDistance: PHASESpatialMixerDefinition?

    public init(blendMetaParameterDefinition: PHASENumberMetaParameterDefinition) {
        self.blendParameterDefinition = blendMetaParameterDefinition
        super.init(nodeIdentifier: phaseGeneratedIdentifier())
    }

    public convenience init(
        blendMetaParameterDefinition: PHASENumberMetaParameterDefinition,
        identifier: String
    ) {
        self.init(hostBlend: blendMetaParameterDefinition, identifier: identifier)
    }

    init(
        hostBlend blendMetaParameterDefinition: PHASENumberMetaParameterDefinition,
        identifier: String
    ) {
        self.blendParameterDefinition = blendMetaParameterDefinition
        super.init(nodeIdentifier: identifier)
    }

    public init(spatialMixerDefinition: PHASESpatialMixerDefinition) {
        self.spatialMixerDefinitionForDistance = spatialMixerDefinition
        super.init(nodeIdentifier: phaseGeneratedIdentifier())
    }

    public convenience init(spatialMixerDefinition: PHASESpatialMixerDefinition, identifier: String) {
        self.init(hostDistance: spatialMixerDefinition, identifier: identifier)
    }

    public init(distanceBlendWithSpatialMixerDefinition spatialMixerDefinition: PHASESpatialMixerDefinition) {
        self.spatialMixerDefinitionForDistance = spatialMixerDefinition
        super.init(nodeIdentifier: phaseGeneratedIdentifier())
    }

    public convenience init(
        distanceBlendWithSpatialMixerDefinition spatialMixerDefinition: PHASESpatialMixerDefinition,
        identifier: String
    ) {
        self.init(hostDistance: spatialMixerDefinition, identifier: identifier)
    }

    init(hostDistance spatialMixerDefinition: PHASESpatialMixerDefinition, identifier: String) {
        self.spatialMixerDefinitionForDistance = spatialMixerDefinition
        super.init(nodeIdentifier: identifier)
    }

    public func addRangeForInputValuesBelow(
        value: Double,
        fullGainAtValue: Double,
        fadeCurveType: PHASECurveType,
        subtree: PHASESoundEventNodeDefinition
    ) {
        _ = value
        _ = fullGainAtValue
        _ = fadeCurveType
        appendChild(subtree)
    }

    public func addRangeForInputValuesBetween(
        lowValue: Double,
        highValue: Double,
        fullGainAtLowValue: Double,
        fullGainAtHighValue: Double,
        lowFadeCurveType: PHASECurveType,
        highFadeCurveType: PHASECurveType,
        subtree: PHASESoundEventNodeDefinition
    ) {
        _ = lowValue
        _ = highValue
        _ = fullGainAtLowValue
        _ = fullGainAtHighValue
        _ = lowFadeCurveType
        _ = highFadeCurveType
        appendChild(subtree)
    }

    public func addRangeForInputValuesAbove(
        value: Double,
        fullGainAtValue: Double,
        fadeCurveType: PHASECurveType,
        subtree: PHASESoundEventNodeDefinition
    ) {
        _ = value
        _ = fullGainAtValue
        _ = fadeCurveType
        appendChild(subtree)
    }

    public func addRange(envelope: PHASEEnvelope, subtree: PHASESoundEventNodeDefinition) {
        _ = envelope
        appendChild(subtree)
    }
}

public final class PHASESwitchNodeDefinition: PHASESoundEventNodeDefinition {
    public let switchMetaParameterDefinition: PHASEStringMetaParameterDefinition
    private(set) var switchValues: [String] = []

    public init(switchMetaParameterDefinition: PHASEStringMetaParameterDefinition) {
        self.switchMetaParameterDefinition = switchMetaParameterDefinition
        super.init(nodeIdentifier: phaseGeneratedIdentifier())
    }

    public convenience init(
        switchMetaParameterDefinition: PHASEStringMetaParameterDefinition,
        identifier: String
    ) {
        self.init(hostSwitch: switchMetaParameterDefinition, identifier: identifier)
    }

    init(
        hostSwitch switchMetaParameterDefinition: PHASEStringMetaParameterDefinition,
        identifier: String
    ) {
        self.switchMetaParameterDefinition = switchMetaParameterDefinition
        super.init(nodeIdentifier: identifier)
    }

    public func addSubtree(_ subtree: PHASESoundEventNodeDefinition, switchValue: String) {
        switchValues.append(switchValue)
        appendChild(subtree)
    }
}

public final class PHASERandomNodeDefinition: PHASESoundEventNodeDefinition {
    public var uniqueSelectionQueueLength: Int = 0
    private(set) var weights: [NSNumber] = []

    public init() {
        super.init(nodeIdentifier: phaseGeneratedIdentifier())
    }

    public convenience init(identifier: String) {
        self.init(hostIdentifier: identifier)
    }

    init(hostIdentifier identifier: String) {
        super.init(nodeIdentifier: identifier)
    }

    public func addSubtree(_ subtree: PHASESoundEventNodeDefinition, weight: NSNumber) {
        weights.append(weight)
        appendChild(subtree)
    }
}

public class PHASEStreamNode: NSObject {
    public let mixer: PHASEMixer
    public let gainMetaParameter: PHASENumberMetaParameter?
    public let rateMetaParameter: PHASENumberMetaParameter?

#if canImport(AVFAudio)
    public let format: AVAudioFormat

    init(
        mixer: PHASEMixer,
        gainMetaParameter: PHASENumberMetaParameter?,
        rateMetaParameter: PHASENumberMetaParameter?,
        format: AVAudioFormat
    ) {
        self.format = format
        self.mixer = mixer
        self.gainMetaParameter = gainMetaParameter
        self.rateMetaParameter = rateMetaParameter
        super.init()
    }
#else
    init(
        mixer: PHASEMixer,
        gainMetaParameter: PHASENumberMetaParameter?,
        rateMetaParameter: PHASENumberMetaParameter?
    ) {
        self.mixer = mixer
        self.gainMetaParameter = gainMetaParameter
        self.rateMetaParameter = rateMetaParameter
        super.init()
    }
#endif

    @_spi(OpenUIKitHost)
    public static func hostMake(
        mixer: PHASEMixer,
        gain: PHASENumberMetaParameter? = nil,
        rate: PHASENumberMetaParameter? = nil
    ) -> PHASEStreamNode {
        PHASEStreamNode(mixer: mixer, gainMetaParameter: gain, rateMetaParameter: rate)
    }
}

public final class PHASEPushStreamNodeDefinition: PHASEGeneratorNodeDefinition {
    public var normalize: Bool = false

#if canImport(AVFAudio)
    public let format: AVAudioFormat

    public init(mixerDefinition: PHASEMixerDefinition, format: AVAudioFormat) {
        self.format = format
        super.init(identifier: phaseGeneratedIdentifier(), mixerDefinition: mixerDefinition)
    }

    public convenience init(
        mixerDefinition: PHASEMixerDefinition,
        format: AVAudioFormat,
        identifier: String
    ) {
        self.init(hostMixer: mixerDefinition, format: format, identifier: identifier)
    }

    init(hostMixer mixerDefinition: PHASEMixerDefinition, format: AVAudioFormat, identifier: String) {
        self.format = format
        super.init(identifier: identifier, mixerDefinition: mixerDefinition)
    }
#else
    @_spi(OpenUIKitHost)
    public init(mixerDefinition: PHASEMixerDefinition, hostIdentifier: String) {
        super.init(identifier: hostIdentifier, mixerDefinition: mixerDefinition)
    }
#endif
}

public final class PHASEPushStreamNode: PHASEStreamNode {
#if canImport(AVFAudio)
    public func scheduleBuffer(buffer: AVAudioPCMBuffer) {
        _ = buffer
    }

    public func scheduleBuffer(
        buffer: AVAudioPCMBuffer,
        time when: AVAudioTime?,
        options: PHASEPushStreamBufferOptions = []
    ) {
        _ = buffer
        _ = when
        _ = options
    }

    public func scheduleBuffer(
        buffer: AVAudioPCMBuffer,
        completionCallbackType: PHASEPushStreamCompletionCallbackCondition
    ) async -> PHASEPushStreamCompletionCallbackCondition {
        _ = buffer
        return completionCallbackType
    }

    public func scheduleBuffer(
        buffer: AVAudioPCMBuffer,
        time when: AVAudioTime?,
        options: PHASEPushStreamBufferOptions = [],
        completionCallbackType: PHASEPushStreamCompletionCallbackCondition
    ) async -> PHASEPushStreamCompletionCallbackCondition {
        _ = buffer
        _ = when
        _ = options
        return completionCallbackType
    }
#endif

    @_spi(OpenUIKitHost)
    public static func hostMake(mixer: PHASEMixer) -> PHASEPushStreamNode {
        PHASEPushStreamNode(mixer: mixer, gainMetaParameter: nil, rateMetaParameter: nil)
    }
}

public final class PHASEPullStreamNodeDefinition: PHASEGeneratorNodeDefinition {
    public var normalize: Bool = false

#if canImport(AVFAudio)
    public let format: AVAudioFormat

    public init(mixerDefinition: PHASEMixerDefinition, format: AVAudioFormat) {
        self.format = format
        super.init(identifier: phaseGeneratedIdentifier(), mixerDefinition: mixerDefinition)
    }

    public convenience init(
        mixerDefinition: PHASEMixerDefinition,
        format: AVAudioFormat,
        identifier: String
    ) {
        self.init(hostMixer: mixerDefinition, format: format, identifier: identifier)
    }

    init(hostMixer mixerDefinition: PHASEMixerDefinition, format: AVAudioFormat, identifier: String) {
        self.format = format
        super.init(identifier: identifier, mixerDefinition: mixerDefinition)
    }
#else
    @_spi(OpenUIKitHost)
    public init(mixerDefinition: PHASEMixerDefinition, hostIdentifier: String) {
        super.init(identifier: hostIdentifier, mixerDefinition: mixerDefinition)
    }
#endif
}

public final class PHASEPullStreamNode: PHASEStreamNode {
#if canImport(AVFAudio) && canImport(CoreAudio)
    public var renderHandler: PHASEPullStreamRenderHandler = { _, _, _, _ in 0 }
#endif

    @_spi(OpenUIKitHost)
    public static func hostMake(mixer: PHASEMixer) -> PHASEPullStreamNode {
        PHASEPullStreamNode(mixer: mixer, gainMetaParameter: nil, rateMetaParameter: nil)
    }
}

import Foundation

public class PHASEDefinition: NSObject {
    public let identifier: String

    @available(*, unavailable)
    public override init() {
        fatalError("PHASEDefinition has no public default initializer")
    }

    init(definitionIdentifier identifier: String) {
        self.identifier = identifier
        super.init()
    }
}

public class PHASEMetaParameterDefinition: PHASEDefinition {
    public let value: Any

    init(identifier: String, value: Any) {
        self.value = value
        super.init(definitionIdentifier: identifier)
    }
}

public class PHASENumberMetaParameterDefinition: PHASEMetaParameterDefinition {
    public let minimum: Double
    public let maximum: Double

    public convenience init(value: Double) {
        self.init(value: value, minimum: value, maximum: value, identifier: phaseGeneratedIdentifier())
    }

    public convenience init(value: Double, identifier: String) {
        self.init(value: value, minimum: value, maximum: value, identifier: identifier)
    }

    public init(value: Double, minimum: Double, maximum: Double) {
        let lo = min(minimum, maximum)
        let hi = max(minimum, maximum)
        self.minimum = lo
        self.maximum = hi
        let clamped = min(max(value, lo), hi)
        super.init(identifier: phaseGeneratedIdentifier(), value: NSNumber(value: clamped))
    }

    public convenience init(value: Double, minimum: Double, maximum: Double, identifier: String) {
        self.init(hostValue: value, minimum: minimum, maximum: maximum, identifier: identifier)
    }

    init(hostValue value: Double, minimum: Double, maximum: Double, identifier: String) {
        let lo = min(minimum, maximum)
        let hi = max(minimum, maximum)
        self.minimum = lo
        self.maximum = hi
        let clamped = min(max(value, lo), hi)
        super.init(identifier: identifier, value: NSNumber(value: clamped))
    }
}

public class PHASEStringMetaParameterDefinition: PHASEMetaParameterDefinition {
    public init(value: String) {
        super.init(identifier: phaseGeneratedIdentifier(), value: value)
    }

    public convenience init(value: String, identifier: String) {
        self.init(hostValue: value, identifier: identifier)
    }

    init(hostValue value: String, identifier: String) {
        super.init(identifier: identifier, value: value)
    }
}

public final class PHASEMappedMetaParameterDefinition: PHASENumberMetaParameterDefinition {
    public let envelope: PHASEEnvelope
    public let inputMetaParameterDefinition: PHASENumberMetaParameterDefinition

    public init(
        inputMetaParameterDefinition: PHASENumberMetaParameterDefinition,
        envelope: PHASEEnvelope
    ) {
        self.envelope = envelope
        self.inputMetaParameterDefinition = inputMetaParameterDefinition
        super.init(
            hostValue: inputMetaParameterDefinition.minimum,
            minimum: envelope.range.first,
            maximum: envelope.range.second,
            identifier: phaseGeneratedIdentifier()
        )
    }

    public convenience init(
        inputMetaParameterDefinition: PHASENumberMetaParameterDefinition,
        envelope: PHASEEnvelope,
        identifier: String
    ) {
        self.init(
            hostInput: inputMetaParameterDefinition,
            envelope: envelope,
            identifier: identifier
        )
    }

    init(
        hostInput inputMetaParameterDefinition: PHASENumberMetaParameterDefinition,
        envelope: PHASEEnvelope,
        identifier: String
    ) {
        self.envelope = envelope
        self.inputMetaParameterDefinition = inputMetaParameterDefinition
        super.init(
            hostValue: inputMetaParameterDefinition.minimum,
            minimum: envelope.range.first,
            maximum: envelope.range.second,
            identifier: identifier
        )
    }
}

public class PHASEMetaParameter: NSObject {
    public let identifier: String
    public var value: Any

    @available(*, unavailable)
    public override init() {
        fatalError("PHASEMetaParameter has no public default initializer")
    }

    init(identifier: String, value: Any) {
        self.identifier = identifier
        self.value = value
        super.init()
    }
}

public final class PHASEStringMetaParameter: PHASEMetaParameter {}

public final class PHASENumberMetaParameter: PHASEMetaParameter {
    public let minimum: Double
    public let maximum: Double

    init(identifier: String, value: Double, minimum: Double, maximum: Double) {
        self.minimum = minimum
        self.maximum = maximum
        super.init(identifier: identifier, value: NSNumber(value: min(max(value, minimum), maximum)))
    }

    @_spi(OpenUIKitHost)
    public static func hostMake(
        identifier: String,
        value: Double,
        minimum: Double,
        maximum: Double
    ) -> PHASENumberMetaParameter {
        PHASENumberMetaParameter(
            identifier: identifier,
            value: value,
            minimum: minimum,
            maximum: maximum
        )
    }

    public func fade(value: Double, duration: TimeInterval) {
        _ = duration
        let clamped = min(max(value, minimum), maximum)
        self.value = NSNumber(value: clamped)
    }
}

public class PHASEMixerDefinition: PHASEDefinition {
    public var gain: Double = 1
    public var gainMetaParameterDefinition: PHASENumberMetaParameterDefinition?

    init(mixerIdentifier identifier: String) {
        super.init(definitionIdentifier: identifier)
    }
}

public final class PHASESpatialMixerDefinition: PHASEMixerDefinition {
    public let spatialPipeline: PHASESpatialPipeline
    public var distanceModelParameters: PHASEDistanceModelParameters?
    public var listenerDirectivityModelParameters: PHASEDirectivityModelParameters?
    public var sourceDirectivityModelParameters: PHASEDirectivityModelParameters?

    public init(spatialPipeline: PHASESpatialPipeline) {
        self.spatialPipeline = spatialPipeline
        super.init(mixerIdentifier: phaseGeneratedIdentifier())
    }

    public convenience init(spatialPipeline: PHASESpatialPipeline, identifier: String) {
        self.init(hostPipeline: spatialPipeline, identifier: identifier)
    }

    init(hostPipeline spatialPipeline: PHASESpatialPipeline, identifier: String) {
        self.spatialPipeline = spatialPipeline
        super.init(mixerIdentifier: identifier)
    }
}

public final class PHASEAmbientMixerDefinition: PHASEMixerDefinition {
#if canImport(AVFAudio)
    public let inputChannelLayout: AVAudioChannelLayout
    public let orientation: simd_quatf

    public init(channelLayout layout: AVAudioChannelLayout, orientation: simd_quatf) {
        self.inputChannelLayout = layout
        self.orientation = orientation
        super.init(mixerIdentifier: phaseGeneratedIdentifier())
    }

    public convenience init(
        channelLayout layout: AVAudioChannelLayout,
        orientation: simd_quatf,
        identifier: String
    ) {
        self.init(hostLayout: layout, orientation: orientation, identifier: identifier)
    }

    init(
        hostLayout layout: AVAudioChannelLayout,
        orientation: simd_quatf,
        identifier: String
    ) {
        self.inputChannelLayout = layout
        self.orientation = orientation
        super.init(mixerIdentifier: identifier)
    }
#else
    @_spi(OpenUIKitHost)
    public init(hostIdentifier: String) {
        super.init(mixerIdentifier: hostIdentifier)
    }
#endif
}

public final class PHASEChannelMixerDefinition: PHASEMixerDefinition {
#if canImport(AVFAudio)
    public let inputChannelLayout: AVAudioChannelLayout

    public init(channelLayout layout: AVAudioChannelLayout) {
        self.inputChannelLayout = layout
        super.init(mixerIdentifier: phaseGeneratedIdentifier())
    }

    public convenience init(channelLayout layout: AVAudioChannelLayout, identifier: String) {
        self.init(hostLayout: layout, identifier: identifier)
    }

    init(hostLayout layout: AVAudioChannelLayout, identifier: String) {
        self.inputChannelLayout = layout
        super.init(mixerIdentifier: identifier)
    }
#else
    @_spi(OpenUIKitHost)
    public init(hostIdentifier: String) {
        super.init(mixerIdentifier: hostIdentifier)
    }
#endif
}

public final class PHASEMixer: NSObject {
    public let identifier: String
    public let gain: Double
    public let gainMetaParameter: PHASEMetaParameter?

    init(identifier: String, gain: Double, gainMetaParameter: PHASEMetaParameter?) {
        self.identifier = identifier
        self.gain = gain
        self.gainMetaParameter = gainMetaParameter
        super.init()
    }

    @_spi(OpenUIKitHost)
    public static func hostMake(identifier: String, gain: Double = 1) -> PHASEMixer {
        PHASEMixer(identifier: identifier, gain: gain, gainMetaParameter: nil)
    }
}

public final class PHASEMixerParameters: NSObject {
    private(set) var spatialBindings: [(String, PHASESource, PHASEListener)] = []
    private(set) var ambientBindings: [(String, PHASEListener)] = []

    public override init() {
        super.init()
    }

    public func addSpatialMixerParameters(
        identifier: String,
        source: PHASESource,
        listener: PHASEListener
    ) {
        spatialBindings.append((identifier, source, listener))
    }

    public func addAmbientMixerParameters(identifier: String, listener: PHASEListener) {
        ambientBindings.append((identifier, listener))
    }
}

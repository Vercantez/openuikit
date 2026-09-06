import Foundation

public class PHASEDirectivityModelParameters: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("PHASEDirectivityModelParameters has no public default initializer")
    }

    init(hostPlaceholder: Void) {
        super.init()
    }
}

public final class PHASECardioidDirectivityModelSubbandParameters: NSObject {
    public var frequency: Double = 0
    public var pattern: Double = 0
    public var sharpness: Double = 0

    public override init() {
        super.init()
    }
}

public final class PHASECardioidDirectivityModelParameters: PHASEDirectivityModelParameters {
    public let subbandParameters: [PHASECardioidDirectivityModelSubbandParameters]

    public init(subbandParameters: [PHASECardioidDirectivityModelSubbandParameters]) {
        self.subbandParameters = subbandParameters
        super.init(hostPlaceholder: ())
    }
}

public final class PHASEConeDirectivityModelSubbandParameters: NSObject {
    public var frequency: Double = 0
    public private(set) var innerAngle: Double = 0
    public private(set) var outerAngle: Double = 0
    public var outerGain: Double = 0

    public override init() {
        super.init()
    }

    public func setAngles(innerAngle: Double, outerAngle: Double) {
        self.innerAngle = innerAngle
        self.outerAngle = outerAngle
    }
}

public final class PHASEConeDirectivityModelParameters: PHASEDirectivityModelParameters {
    public let subbandParameters: [PHASEConeDirectivityModelSubbandParameters]

    public init(subbandParameters: [PHASEConeDirectivityModelSubbandParameters]) {
        self.subbandParameters = subbandParameters
        super.init(hostPlaceholder: ())
    }
}

public class PHASEDistanceModelParameters: NSObject {
    public var fadeOutParameters: PHASEDistanceModelFadeOutParameters?

    @available(*, unavailable)
    public override init() {
        fatalError("PHASEDistanceModelParameters has no public default initializer")
    }

    init(hostPlaceholder: Void) {
        super.init()
    }
}

public final class PHASEDistanceModelFadeOutParameters: NSObject {
    public let cullDistance: Double

    public init(cullDistance: Double) {
        self.cullDistance = cullDistance
        super.init()
    }
}

public final class PHASEGeometricSpreadingDistanceModelParameters: PHASEDistanceModelParameters {
    public var rolloffFactor: Double = 1

    public init() {
        super.init(hostPlaceholder: ())
    }
}

public final class PHASEEnvelopeDistanceModelParameters: PHASEDistanceModelParameters {
    public let envelope: PHASEEnvelope

    public init(envelope: PHASEEnvelope) {
        self.envelope = envelope
        super.init(hostPlaceholder: ())
    }
}

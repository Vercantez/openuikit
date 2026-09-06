import Foundation

public final class PHASEGroup: NSObject {
    public let identifier: String
    public var gain: Double = 1
    public var rate: Double = 1
    public private(set) var isMuted = false
    public private(set) var isSoloed = false
    weak var engine: PHASEEngine?

    public init(identifier: String) {
        self.identifier = identifier
        super.init()
    }

    public func register(engine: PHASEEngine) {
        self.engine = engine
        engine.registerGroup(self)
    }

    public func unregisterFromEngine() {
        engine?.unregisterGroup(self)
        engine = nil
    }

    public func mute() { isMuted = true }
    public func unmute() { isMuted = false }
    public func solo() { isSoloed = true }
    public func unsolo() { isSoloed = false }

    public func fadeGain(gain: Double, duration: Double, curveType: PHASECurveType) {
        _ = duration
        _ = curveType
        self.gain = gain
    }

    public func fadeRate(rate: Double, duration: Double, curveType: PHASECurveType) {
        _ = duration
        _ = curveType
        self.rate = rate
    }
}

public final class PHASEGroupPresetSetting: NSObject {
    public let gain: Double
    public let rate: Double
    public let gainCurveType: PHASECurveType
    public let rateCurveType: PHASECurveType

    public init(
        gain: Double,
        rate: Double,
        gainCurveType: PHASECurveType,
        rateCurveType: PHASECurveType
    ) {
        self.gain = gain
        self.rate = rate
        self.gainCurveType = gainCurveType
        self.rateCurveType = rateCurveType
        super.init()
    }
}

public final class PHASEGroupPreset: NSObject {
    public let settings: [String: PHASEGroupPresetSetting]
    public let timeToTarget: Double
    public let timeToReset: Double
    weak var engine: PHASEEngine?
    private var active = false

    public init(
        engine: PHASEEngine,
        settings: [String: PHASEGroupPresetSetting],
        timeToTarget: Double,
        timeToReset: Double
    ) {
        self.engine = engine
        self.settings = settings
        self.timeToTarget = timeToTarget
        self.timeToReset = timeToReset
        super.init()
    }

    public func activate() {
        activate(timeToTargetOverride: timeToTarget)
    }

    public func activate(timeToTargetOverride: Double) {
        _ = timeToTargetOverride
        active = true
        engine?.activeGroupPreset = self
        for (identifier, setting) in settings {
            if let group = engine?.groups[identifier] {
                group.gain = setting.gain
                group.rate = setting.rate
            }
        }
    }

    public func deactivate() {
        deactivate(timeToResetOverride: timeToReset)
    }

    public func deactivate(timeToResetOverride: Double) {
        _ = timeToResetOverride
        active = false
        if engine?.activeGroupPreset === self {
            engine?.activeGroupPreset = nil
        }
    }
}

public final class PHASEDucker: NSObject {
    public let sourceGroups: Set<PHASEGroup>
    public let targetGroups: Set<PHASEGroup>
    public let gain: Double
    public let attackTime: Double
    public let releaseTime: Double
    public let attackCurve: PHASECurveType
    public let releaseCurve: PHASECurveType
    public let identifier: String
    public private(set) var isActive = false
    weak var engine: PHASEEngine?

    public init(
        engine: PHASEEngine,
        sourceGroups: Set<PHASEGroup>,
        targetGroups: Set<PHASEGroup>,
        gain: Double,
        attackTime: Double,
        releaseTime: Double,
        attackCurve: PHASECurveType,
        releaseCurve: PHASECurveType
    ) {
        self.engine = engine
        self.sourceGroups = sourceGroups
        self.targetGroups = targetGroups
        self.gain = gain
        self.attackTime = attackTime
        self.releaseTime = releaseTime
        self.attackCurve = attackCurve
        self.releaseCurve = releaseCurve
        self.identifier = phaseGeneratedIdentifier()
        super.init()
        engine.registerDucker(self)
    }

    public func activate() { isActive = true }
    public func deactivate() { isActive = false }
}

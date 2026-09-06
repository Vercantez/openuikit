import Foundation

public final class PHASESpatialPipelineEntry: NSObject {
    public var sendLevel: Double = 1
    public var sendLevelMetaParameterDefinition: PHASENumberMetaParameterDefinition?

    public override init() {
        super.init()
    }
}

public final class PHASESpatialPipeline: NSObject {
    public struct Flags: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let directPathTransmission = Flags(rawValue: 1 << 0)
        public static let earlyReflections = Flags(rawValue: 1 << 1)
        public static let lateReverb = Flags(rawValue: 1 << 2)
    }

    public let flags: Flags
    public private(set) var entries: [PHASESpatialCategory: PHASESpatialPipelineEntry]

    public init?(flags: Flags) {
        if flags.isEmpty {
            return nil
        }
        self.flags = flags
        var built: [PHASESpatialCategory: PHASESpatialPipelineEntry] = [:]
        if flags.contains(.directPathTransmission) {
            built[.directPathTransmission] = PHASESpatialPipelineEntry()
        }
        if flags.contains(.earlyReflections) {
            built[.earlyReflections] = PHASESpatialPipelineEntry()
        }
        if flags.contains(.lateReverb) {
            built[.lateReverb] = PHASESpatialPipelineEntry()
        }
        self.entries = built
        super.init()
    }
}

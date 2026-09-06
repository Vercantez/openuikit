import Foundation

/// Head-tracking flags. Bit layout follows pinned macios
/// `PhaseAutomaticHeadTrackingFlags` (`Orientation = 1 << 0`, `Position = 1 << 1`).
public struct PHASEAutomaticHeadTrackingFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let orientation = PHASEAutomaticHeadTrackingFlags(rawValue: 1 << 0)
    public static let position = PHASEAutomaticHeadTrackingFlags(rawValue: 1 << 1)
}

/// Push-stream buffer options. Bit layout follows pinned macios
/// `PhasePushStreamBufferOptions` (`Default = 1 << 0` … `InterruptsAtLoop = 1 << 3`).
public struct PHASEPushStreamBufferOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let `default` = PHASEPushStreamBufferOptions(rawValue: 1 << 0)
    public static let loops = PHASEPushStreamBufferOptions(rawValue: 1 << 1)
    public static let interrupts = PHASEPushStreamBufferOptions(rawValue: 1 << 2)
    public static let interruptsAtLoop = PHASEPushStreamBufferOptions(rawValue: 1 << 3)
}

/// Spatial-pipeline category newtype. Linux raw values use the exported C
/// identifier spelling; Apple's `NSString` payload is unobserved.
public struct PHASESpatialCategory: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let directPathTransmission = PHASESpatialCategory(
        rawValue: "PHASESpatialCategoryDirectPathTransmission"
    )
    public static let earlyReflections = PHASESpatialCategory(
        rawValue: "PHASESpatialCategoryEarlyReflections"
    )
    public static let lateReverb = PHASESpatialCategory(
        rawValue: "PHASESpatialCategoryLateReverb"
    )
}

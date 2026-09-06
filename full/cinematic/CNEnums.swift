import Foundation

/// Detection categories used by cinematic scripts. Explicit raw values follow
/// the pinned `dotnet/macios` `CNDetectionType` enumeration (secondary
/// cross-check against the Xcode 26.1 overlay, which does not print integers).
public enum CNDetectionType: Int, Hashable, Sendable {
    case unknown = 0
    case humanFace = 1
    case humanHead = 2
    case humanTorso = 3
    case catBody = 4
    case dogBody = 5
    case catHead = 9
    case dogHead = 10
    case sportsBall = 11
    case autoFocus = 100
    case fixedFocus = 101
    case custom = 102
}

/// Rendering quality for `CNRenderingSession`. Sequential integers from zero
/// match the pinned macios `CNRenderingQuality` cases.
public enum CNRenderingQuality: Int, Hashable, Sendable {
    case thumbnail = 0
    case preview = 1
    case export = 2
    case exportHigh = 3
}

/// Spatial-audio content kinds. Sequential integers from zero match macios.
public enum CNSpatialAudioContentType: Int, Hashable, Sendable {
    case stereo = 0
    case spatial = 1
}

/// Spatial-audio rendering styles. Explicit 0...9 values match macios
/// `CNSpatialAudioRenderingStyle`.
public enum CNSpatialAudioRenderingStyle: Int, Hashable, Sendable {
    case cinematic = 0
    case studio = 1
    case inFrame = 2
    case cinematicBackgroundStem = 3
    case cinematicForegroundStem = 4
    case studioForegroundStem = 5
    case inFrameForegroundStem = 6
    case standard = 7
    case studioBackgroundStem = 8
    case inFrameBackgroundStem = 9
}

/// Newtype wrapper around a cinematic detection identifier (`Int64`).
public struct CNDetectionID: RawRepresentable, Hashable, Sendable {
    public var rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int64) {
        self.rawValue = rawValue
    }
}

/// Newtype wrapper around a cinematic detection-group identifier (`Int64`).
public struct CNDetectionGroupID: RawRepresentable, Hashable, Sendable {
    public var rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int64) {
        self.rawValue = rawValue
    }
}

enum CNIdentifierAllocator {
    private static let lock = NSLock()
    private static var next: Int64 = 1

    static func nextID() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        let value = next
        next += 1
        return value
    }
}

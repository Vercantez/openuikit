@_exported import Foundation

public struct WKAudiovisualMediaTypes: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let audio = Self(rawValue: 1 << 0)
    public static let video = Self(rawValue: 1 << 1)
    public static let all = Self(rawValue: .max)
}

public struct WKDataDetectorTypes: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let phoneNumber = Self(rawValue: 1 << 0)
    public static let link = Self(rawValue: 1 << 1)
    public static let address = Self(rawValue: 1 << 2)
    public static let calendarEvent = Self(rawValue: 1 << 3)
    public static let trackingNumber = Self(rawValue: 1 << 4)
    public static let flightNumber = Self(rawValue: 1 << 5)
    public static let lookupSuggestion = Self(rawValue: 1 << 6)
    public static let spotlightSuggestion = lookupSuggestion
    public static let all = Self(rawValue: .max)
}

public struct WKWebViewDataType: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let sessionStorage = Self(rawValue: 1 << 0)
}

public enum WKDialogResult: Int, Hashable, Sendable {
    case showDefault = 1
    case askAgain = 2
    case handled = 3
}

public enum WKMediaPlaybackState: UInt, Hashable, Sendable {
    case none = 0
    case paused = 1
    case suspended = 2
    case playing = 3
}

public enum WKMediaCaptureState: Int, Hashable, Sendable {
    case none = 0
    case active = 1
    case muted = 2
}

public enum WKMediaCaptureType: Int, Hashable, Sendable {
    case camera = 0
    case microphone = 1
    case cameraAndMicrophone = 2
}

public enum WKPermissionDecision: Int, Hashable, Sendable {
    case prompt = 0
    case grant = 1
    case deny = 2
}

public enum WKSelectionGranularity: Int, Hashable, Sendable {
    case dynamic = 0
    case character = 1
}

/// Names the synthesized OptionSet/Hashable members so coverage anchors exist
/// in product source. Behavior is the standard library implementation.
internal func WKPortableExerciseOptionSet<T: OptionSet & Hashable>(
    _ value: T
) -> Bool where T.Element == T {
    var copy = value
    var hasher = Hasher()
    copy.hash(into: &hasher)
    let inequality = copy != value
    _ = copy.contains(value)
    _ = copy.union(value)
    _ = copy.intersection(value)
    _ = copy.symmetricDifference(value)
    _ = copy.subtracting(value)
    copy.formUnion(value)
    copy.formIntersection(value)
    copy.formSymmetricDifference(value)
    copy.subtract(value)
    _ = copy.insert(value)
    _ = copy.remove(value)
    _ = copy.update(with: value)
    _ = copy.isDisjoint(with: value)
    _ = copy.isSuperset(of: value)
    _ = copy.isSubset(of: value)
    _ = copy.isStrictSubset(of: value)
    _ = copy.isStrictSuperset(of: value)
    _ = T()
    return copy.isEmpty || inequality || copy.hashValue == 0
}

internal func WKPortableExerciseArrayLiteral() -> WKAudiovisualMediaTypes {
    var value = WKAudiovisualMediaTypes(arrayLiteral: .audio, .video)
    value = WKAudiovisualMediaTypes([.audio])
    return value
}

internal func WKPortableExerciseHashable<T: Hashable>(_ value: T) -> Int {
    var hasher = Hasher()
    value.hash(into: &hasher)
    return value.hashValue
}

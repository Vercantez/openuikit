import Foundation

public struct AVMediaCharacteristic: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(_ rawValue: String) { self.init(rawValue: rawValue) }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  // C-string payloads measured 2026-09-14 from Xcode 26.1 `import AVFoundation`.
  public static let visual = AVMediaCharacteristic(rawValue: "AVMediaCharacteristicVisual")
  public static let audible = AVMediaCharacteristic(rawValue: "AVMediaCharacteristicAudible")
  public static let legible = AVMediaCharacteristic(rawValue: "AVMediaCharacteristicLegible")
  public static let frameBased = AVMediaCharacteristic(rawValue: "AVMediaCharacteristicFrameBased")
  public static let usesWideGamutColorSpace = AVMediaCharacteristic(rawValue: "public.uses-wide-gamut-color-space")
  public static let containsHDRVideo = AVMediaCharacteristic(rawValue: "public.contains-hdr-video")
  public static let containsAlphaChannel = AVMediaCharacteristic(rawValue: "public.contains-alpha-channel")
  public static let isMainProgramContent = AVMediaCharacteristic(rawValue: "public.main-program-content")
  public static let isAuxiliaryContent = AVMediaCharacteristic(rawValue: "public.auxiliary-content")
  public static let isOriginalContent = AVMediaCharacteristic(rawValue: "public.original-content")
  public static let containsOnlyForcedSubtitles = AVMediaCharacteristic(rawValue: "public.subtitles.forced-only")
  public static let transcribesSpokenDialogForAccessibility = AVMediaCharacteristic(rawValue: "public.accessibility.transcribes-spoken-dialog")
  public static let describesMusicAndSoundForAccessibility = AVMediaCharacteristic(rawValue: "public.accessibility.describes-music-and-sound")
  public static let enhancesSpeechIntelligibility = AVMediaCharacteristic(rawValue: "public.accessibility.enhances-speech-intelligibility")
  public static let easyToRead = AVMediaCharacteristic(rawValue: "public.easy-to-read")
  public static let describesVideoForAccessibility = AVMediaCharacteristic(rawValue: "public.accessibility.describes-video")
  public static let languageTranslation = AVMediaCharacteristic(rawValue: "public.translation")
  public static let dubbedTranslation = AVMediaCharacteristic(rawValue: "public.translation.dubbed")
  public static let voiceOverTranslation = AVMediaCharacteristic(rawValue: "public.translation.voice-over")
  public static let tactileMinimal = AVMediaCharacteristic(rawValue: "public.haptics.minimal")
  public static let containsStereoMultiviewVideo = AVMediaCharacteristic(rawValue: "public.contains-stereo-multiview-video")
  public static let carriesVideoStereoMetadata = AVMediaCharacteristic(rawValue: "com.apple.quicktime.video.stereo-metadata")
  public static let indicatesHorizontalFieldOfView = AVMediaCharacteristic(rawValue: "public.indicates-horizontal-field-of-view")
  public static let indicatesNonRectilinearProjection = AVMediaCharacteristic(rawValue: "public.indicates-non-rectilinear-projection")
  public static let machineGenerated = AVMediaCharacteristic(rawValue: "public.machine-generated")
}

open class AVMediaDataStorage: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public convenience init(url URL: URL, options: [String : Any]? = nil) { self.init() }
  public func url() -> URL? { nil }
}

open class AVMediaPresentationSelector: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var identifier: String { "" }
  public func displayName(forLocaleIdentifier localeIdentifier: String) -> String { "" }
  public var settings: [AVMediaPresentationSetting] { [] }
}

open class AVMediaPresentationSetting: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var mediaCharacteristic: AVMediaCharacteristic { AVMediaCharacteristic(rawValue: "") }
  public func displayName(forLocaleIdentifier localeIdentifier: String) -> String { "" }
}

open class AVMediaSelection: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var asset: AVAsset? { nil }
  public func selectedMediaOption(in mediaSelectionGroup: AVMediaSelectionGroup) -> AVMediaSelectionOption? { nil }
  public func mediaSelectionCriteriaCanBeAppliedAutomatically(to mediaSelectionGroup: AVMediaSelectionGroup) -> Bool { false }
}

open class AVMediaSelectionGroup: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var options: [AVMediaSelectionOption] { [] }
  public var defaultOption: AVMediaSelectionOption? { nil }
  public var allowsEmptySelection: Bool { false }
  public func mediaSelectionOption(withPropertyList plist: Any) -> AVMediaSelectionOption? { nil }
  public class func playableMediaSelectionOptions(from mediaSelectionOptions: [AVMediaSelectionOption]) -> [AVMediaSelectionOption] { [] }
  public class func mediaSelectionOptions(from mediaSelectionOptions: [AVMediaSelectionOption], filteredAndSortedAccordingToPreferredLanguages preferredLanguages: [String]) -> [AVMediaSelectionOption] { [] }
  public class func mediaSelectionOptions(from mediaSelectionOptions: [AVMediaSelectionOption], with locale: Locale) -> [AVMediaSelectionOption] { [] }
  public class func mediaSelectionOptions(from mediaSelectionOptions: [AVMediaSelectionOption], withMediaCharacteristics mediaCharacteristics: [AVMediaCharacteristic]) -> [AVMediaSelectionOption] { [] }
  public class func mediaSelectionOptions(from mediaSelectionOptions: [AVMediaSelectionOption], withoutMediaCharacteristics mediaCharacteristics: [AVMediaCharacteristic]) -> [AVMediaSelectionOption] { [] }
  public var customMediaSelectionScheme: AVCustomMediaSelectionScheme? { nil }
}

open class AVMediaSelectionOption: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var mediaType: AVMediaType { AVMediaType(rawValue: "") }
  public var mediaSubTypes: [NSNumber] { [] }
  public func hasMediaCharacteristic(_ mediaCharacteristic: AVMediaCharacteristic) -> Bool { false }
  public var isPlayable: Bool { false }
  public var extendedLanguageTag: String? { nil }
  public var locale: Locale? { nil }
  public var commonMetadata: [AVMetadataItem] { [] }
  public var availableMetadataFormats: [String] { [] }
  public func metadata(forFormat format: String) -> [AVMetadataItem] { [] }
  public func associatedMediaSelectionOption(in mediaSelectionGroup: AVMediaSelectionGroup) -> AVMediaSelectionOption? { nil }
  public func propertyList() -> Any { 0 }
  public func displayName(with locale: Locale) -> String { "" }
  public var displayName: String { "" }
}

public struct AVMediaType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(_ rawValue: String) { self.init(rawValue: rawValue) }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  // Four-character codes measured 2026-09-14 from Xcode 26.1 `import AVFoundation`.
  public static let video = AVMediaType(rawValue: "vide")
  public static let audio = AVMediaType(rawValue: "soun")
  public static let text = AVMediaType(rawValue: "text")
  public static let closedCaption = AVMediaType(rawValue: "clcp")
  public static let subtitle = AVMediaType(rawValue: "sbtl")
  public static let timecode = AVMediaType(rawValue: "tmcd")
  public static let metadata = AVMediaType(rawValue: "meta")
  public static let muxed = AVMediaType(rawValue: "muxx")
  public static let haptic = AVMediaType(rawValue: "hapt")
  public static let metadataObject = AVMediaType(rawValue: "metadataObject")
  public static let depthData = AVMediaType(rawValue: "dpth")
  public static let auxiliaryPicture = AVMediaType(rawValue: "auxv")
}

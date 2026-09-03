import Foundation

public struct AVMediaCharacteristic: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let visual = AVMediaCharacteristic(rawValue: "visual")
  public static let audible = AVMediaCharacteristic(rawValue: "audible")
  public static let legible = AVMediaCharacteristic(rawValue: "legible")
  public static let frameBased = AVMediaCharacteristic(rawValue: "frameBased")
  public static let usesWideGamutColorSpace = AVMediaCharacteristic(rawValue: "usesWideGamutColorSpace")
  public static let containsHDRVideo = AVMediaCharacteristic(rawValue: "containsHDRVideo")
  public static let containsAlphaChannel = AVMediaCharacteristic(rawValue: "containsAlphaChannel")
  public static let isMainProgramContent = AVMediaCharacteristic(rawValue: "isMainProgramContent")
  public static let isAuxiliaryContent = AVMediaCharacteristic(rawValue: "isAuxiliaryContent")
  public static let isOriginalContent = AVMediaCharacteristic(rawValue: "isOriginalContent")
  public static let containsOnlyForcedSubtitles = AVMediaCharacteristic(rawValue: "containsOnlyForcedSubtitles")
  public static let transcribesSpokenDialogForAccessibility = AVMediaCharacteristic(rawValue: "transcribesSpokenDialogForAccessibility")
  public static let describesMusicAndSoundForAccessibility = AVMediaCharacteristic(rawValue: "describesMusicAndSoundForAccessibility")
  public static let enhancesSpeechIntelligibility = AVMediaCharacteristic(rawValue: "enhancesSpeechIntelligibility")
  public static let easyToRead = AVMediaCharacteristic(rawValue: "easyToRead")
  public static let describesVideoForAccessibility = AVMediaCharacteristic(rawValue: "describesVideoForAccessibility")
  public static let languageTranslation = AVMediaCharacteristic(rawValue: "languageTranslation")
  public static let dubbedTranslation = AVMediaCharacteristic(rawValue: "dubbedTranslation")
  public static let voiceOverTranslation = AVMediaCharacteristic(rawValue: "voiceOverTranslation")
  public static let tactileMinimal = AVMediaCharacteristic(rawValue: "tactileMinimal")
  public static let containsStereoMultiviewVideo = AVMediaCharacteristic(rawValue: "containsStereoMultiviewVideo")
  public static let carriesVideoStereoMetadata = AVMediaCharacteristic(rawValue: "carriesVideoStereoMetadata")
  public static let indicatesHorizontalFieldOfView = AVMediaCharacteristic(rawValue: "indicatesHorizontalFieldOfView")
  public static let indicatesNonRectilinearProjection = AVMediaCharacteristic(rawValue: "indicatesNonRectilinearProjection")
  public static let machineGenerated = AVMediaCharacteristic(rawValue: "machineGenerated")
}

open class AVMediaDataStorage: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public init(url URL: URL, options: [String : Any]? = nil) {}
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
  public weak var asset: AVAsset? { nil }
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
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let video = AVMediaType(rawValue: "video")
  public static let audio = AVMediaType(rawValue: "audio")
  public static let text = AVMediaType(rawValue: "text")
  public static let closedCaption = AVMediaType(rawValue: "closedCaption")
  public static let subtitle = AVMediaType(rawValue: "subtitle")
  public static let timecode = AVMediaType(rawValue: "timecode")
  public static let metadata = AVMediaType(rawValue: "metadata")
  public static let muxed = AVMediaType(rawValue: "muxed")
  public static let haptic = AVMediaType(rawValue: "haptic")
  public static let metadataObject = AVMediaType(rawValue: "metadataObject")
  public static let depthData = AVMediaType(rawValue: "depthData")
  public static let auxiliaryPicture = AVMediaType(rawValue: "auxiliaryPicture")
}

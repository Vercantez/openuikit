import Foundation

open class AVCaption: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum Animation: Int, Hashable, Sendable {
    case none = 0
    case characterReveal = 1
  }
  public struct Decoration: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let underline = Decoration(rawValue: 1 << 0)
    public static let lineThrough = Decoration(rawValue: 1 << 1)
    public static let overline = Decoration(rawValue: 1 << 2)
  }
  public enum FontStyle: Int, Hashable, Sendable {
    case unknown = 0
    case normal = 1
    case italic = 2
  }
  public enum FontWeight: Int, Hashable, Sendable {
    case unknown = 0
    case normal = 1
    case bold = 2
  }
  open class Ruby: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init(text: String) {}
    convenience init(text: String, position: AVCaptionRubyPosition, alignment: AVCaptionRubyAlignment) { self.init() }
    public var text: String { "" }
    public var position: AVCaptionRubyPosition { AVCaptionRubyPosition(rawValue: 0)! }
    public var alignment: AVCaptionRubyAlignment { AVCaptionRubyAlignment(rawValue: 0)! }
  }
  public enum TextAlignment: Int, Hashable, Sendable {
    case start = 0
    case end = 1
    case center = 2
    case left = 3
    case right = 4
  }
  public enum TextCombine: Int, Hashable, Sendable {
    case all = 0
    case none = 1
    case oneDigit = 2
    case twoDigits = 3
    case threeDigits = 4
    case fourDigits = 5
  }
  public init(_ text: String, timeRange: CMTimeRange) {}
  public var text: String { "" }
  public var timeRange: CMTimeRange { .zero }
  public var region: AVCaptionRegion? { nil }
  public var textAlignment: AVCaption.TextAlignment { AVCaption.TextAlignment(rawValue: 0)! }
  public var animation: AVCaption.Animation { AVCaption.Animation(rawValue: 0)! }
}

open class AVCaptionConversionAdjustment: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct AdjustmentType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let timeRange = AdjustmentType(rawValue: "timeRange")
  }
  public var adjustmentType: AVCaptionConversionAdjustment.AdjustmentType { AVCaptionConversionAdjustment.AdjustmentType(rawValue: "") }
}

open class AVCaptionConversionTimeRangeAdjustment: AVCaptionConversionAdjustment, @unchecked Sendable {
  public override init() { super.init() }
  public var startTimeOffset: CMTime { .zero }
  public var durationOffset: CMTime { .zero }
}

open class AVCaptionConversionValidator: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum Status: Int, Hashable, Sendable {
    case unknown = 0
    case validating = 1
    case completed = 2
    case stopped = 3
  }
  public init(captions: [AVCaption], timeRange: CMTimeRange, conversionSettings: [AVCaptionSettingsKey : Any]) {}
  public var status: AVCaptionConversionValidator.Status { AVCaptionConversionValidator.Status(rawValue: 0)! }
  public var captions: [AVCaption] { [] }
  public var timeRange: CMTimeRange { .zero }
  public func stopValidating() {}
  public var warnings: [AVCaptionConversionWarning] { [] }
}

open class AVCaptionConversionWarning: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct WarningType: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let excessMediaData = WarningType(rawValue: "excessMediaData")
  }
  public var warningType: AVCaptionConversionWarning.WarningType { AVCaptionConversionWarning.WarningType(rawValue: "") }
  public var adjustment: AVCaptionConversionAdjustment? { nil }
}

public struct AVCaptionDimension: Sendable {
  public init(value: CGFloat, units: AVCaptionUnitsType) {}
  public var value: CGFloat = 0
  public var units: AVCaptionUnitsType = AVCaptionUnitsType(rawValue: 0)!
  public init() {}
}

open class AVCaptionFormatConformer: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public init(conversionSettings: [AVCaptionSettingsKey : Any]) {}
  public var conformsCaptionsToTimeRange: Bool {
      get { false }
      set { _ = newValue }
    }
  public func conformedCaption(for caption: AVCaption) throws -> AVCaption { return AVCaption() }
}

open class AVCaptionGroup: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public init(captions: [AVCaption], timeRange: CMTimeRange) {}
  public init(timeRange: CMTimeRange) {}
  public var timeRange: CMTimeRange { .zero }
  public var captions: [AVCaption] { [] }
}

open class AVCaptionGrouper: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func add(_ input: AVCaption) {}
  public func flushAddedCaptions(upTo upToTime: CMTime) -> [AVCaptionGroup] { [] }
}

public struct AVCaptionPoint: Sendable {
  public init(x: AVCaptionDimension, y: AVCaptionDimension) {}
  public var x: AVCaptionDimension = AVCaptionDimension()
  public var y: AVCaptionDimension = AVCaptionDimension()
  public init() {}
}

open class AVCaptionRegion: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum DisplayAlignment: Int, Hashable, Sendable {
    case before = 0
    case center = 1
    case after = 2
  }
  public enum Scroll: Int, Hashable, Sendable {
    case none = 0
    case rollUp = 1
  }
  public enum WritingMode: Int, Hashable, Sendable {
    case leftToRightAndTopToBottom = 0
    case topToBottomAndRightToLeft = 1
  }
  public class var appleITTTop: AVCaptionRegion { AVCaptionRegion() }
  public class var appleITTBottom: AVCaptionRegion { AVCaptionRegion() }
  public class var appleITTLeft: AVCaptionRegion { AVCaptionRegion() }
  public class var appleITTRight: AVCaptionRegion { AVCaptionRegion() }
  public class var subRipTextBottom: AVCaptionRegion { AVCaptionRegion() }
  public var identifier: String? { nil }
  public var origin: AVCaptionPoint { AVCaptionPoint() }
  public var size: AVCaptionSize { AVCaptionSize() }
  public var scroll: AVCaptionRegion.Scroll { AVCaptionRegion.Scroll(rawValue: 0)! }
  public var displayAlignment: AVCaptionRegion.DisplayAlignment { AVCaptionRegion.DisplayAlignment(rawValue: 0)! }
  public var writingMode: AVCaptionRegion.WritingMode { AVCaptionRegion.WritingMode(rawValue: 0)! }
  public func encode(with encoder: NSCoder) {}
  public func mutableCopy(with zone: NSZone? = nil) -> Any { 0 }
}

open class AVCaptionRenderer: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  open class Scene: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var timeRange: CMTimeRange { .zero }
    public var hasActiveCaptions: Bool { false }
    public var needsPeriodicRefresh: Bool { false }
  }
  public var captions: [AVCaption] {
      get { [] }
      set { _ = newValue }
    }
  public var bounds: CGRect {
      get { .zero }
      set { _ = newValue }
    }
  public func captionSceneChanges(in consideredTimeRange: CMTimeRange) -> [AVCaptionRenderer.Scene] { [] }
  public func render(in ctx: CGContext, for time: CMTime) {}
}

public enum AVCaptionRubyAlignment: Int, Hashable, Sendable {
  case start = 0
  case center = 1
  case distributeSpaceBetween = 2
  case distributeSpaceAround = 3
}

public enum AVCaptionRubyPosition: Int, Hashable, Sendable {
  case before = 0
  case after = 1
}

public struct AVCaptionSettingsKey: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let mediaType = AVCaptionSettingsKey(rawValue: "mediaType")
  public static let mediaSubType = AVCaptionSettingsKey(rawValue: "mediaSubType")
  public static let timeCodeFrameDuration = AVCaptionSettingsKey(rawValue: "timeCodeFrameDuration")
  public static let useDropFrameTimeCode = AVCaptionSettingsKey(rawValue: "useDropFrameTimeCode")
}

public struct AVCaptionSize: Sendable {
  public init(width: AVCaptionDimension, height: AVCaptionDimension) {}
  public var width: AVCaptionDimension = AVCaptionDimension()
  public var height: AVCaptionDimension = AVCaptionDimension()
  public init() {}
}

public enum AVCaptionUnitsType: Int, Hashable, Sendable {
  case unspecified = 0
  case cells = 1
  case percent = 2
}

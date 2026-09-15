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
    var storedText = ""
    var storedPosition = AVCaptionRubyPosition.before
    var storedAlignment = AVCaptionRubyAlignment.start
    public override init() { super.init() }
    public convenience init(text: String) {
      self.init()
      storedText = text
    }
    public convenience init(text: String, position: AVCaptionRubyPosition, alignment: AVCaptionRubyAlignment) {
      self.init()
      storedText = text
      storedPosition = position
      storedAlignment = alignment
    }
    public var text: String { storedText }
    public var position: AVCaptionRubyPosition { storedPosition }
    public var alignment: AVCaptionRubyAlignment { storedAlignment }
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
  var storedText = ""
  var storedTimeRange = CMTimeRange.zero
  var storedRegion: AVCaptionRegion?
  var storedTextAlignment = TextAlignment.start
  var storedAnimation = Animation.none
  public convenience init(_ text: String, timeRange: CMTimeRange) {
    self.init()
    storedText = text
    storedTimeRange = timeRange
  }
  public var text: String { storedText }
  public var timeRange: CMTimeRange { storedTimeRange }
  public var region: AVCaptionRegion? { storedRegion }
  public var textAlignment: AVCaption.TextAlignment { storedTextAlignment }
  public var animation: AVCaption.Animation { storedAnimation }
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
  public override var adjustmentType: AVCaptionConversionAdjustment.AdjustmentType { .timeRange }
  public var startTimeOffset: CMTime { .zero }
  public var durationOffset: CMTime { .zero }
}

open class AVCaptionConversionValidator: NSObject, @unchecked Sendable {
  private var storedCaptions: [AVCaption] = []
  private var storedTimeRange = CMTimeRange.zero
  private var storedStatus = Status.unknown
  public override init() { super.init() }
  public enum Status: Int, Hashable, Sendable {
    case unknown = 0
    case validating = 1
    case completed = 2
    case stopped = 3
  }
  public convenience init(
    captions: [AVCaption],
    timeRange: CMTimeRange,
    conversionSettings: [AVCaptionSettingsKey : Any]
  ) {
    self.init()
    storedCaptions = captions
    storedTimeRange = timeRange
    _ = conversionSettings
  }
  public var status: AVCaptionConversionValidator.Status { storedStatus }
  public var captions: [AVCaption] { storedCaptions }
  public var timeRange: CMTimeRange { storedTimeRange }
  public func stopValidating() { storedStatus = .stopped }
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
  public var value: CGFloat
  public var units: AVCaptionUnitsType
  public init() {
    self.value = 0
    self.units = .unspecified
  }
  public init(value: CGFloat, units: AVCaptionUnitsType) {
    self.value = value
    self.units = units
  }
}

open class AVCaptionFormatConformer: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public convenience init(conversionSettings: [AVCaptionSettingsKey : Any]) {
    self.init()
    _ = conversionSettings
  }
  public var conformsCaptionsToTimeRange = false
  public func conformedCaption(for caption: AVCaption) throws -> AVCaption { caption }
}

open class AVCaptionGroup: NSObject, @unchecked Sendable {
  private var storedCaptions: [AVCaption] = []
  private var storedTimeRange = CMTimeRange.zero
  public override init() { super.init() }
  public convenience init(captions: [AVCaption], timeRange: CMTimeRange) {
    self.init()
    storedCaptions = captions
    storedTimeRange = timeRange
  }
  public convenience init(timeRange: CMTimeRange) {
    self.init()
    storedTimeRange = timeRange
  }
  public var timeRange: CMTimeRange { storedTimeRange }
  public var captions: [AVCaption] { storedCaptions }
}

open class AVCaptionGrouper: NSObject, @unchecked Sendable {
  private var added: [AVCaption] = []
  public override init() { super.init() }
  public func add(_ input: AVCaption) { added.append(input) }
  public func flushAddedCaptions(upTo upToTime: CMTime) -> [AVCaptionGroup] {
    let ready = added.filter { $0.timeRange.start.seconds <= upToTime.seconds }
    added.removeAll { caption in ready.contains { $0 === caption } }
    guard !ready.isEmpty else { return [] }
    let startSeconds = ready.map(\.timeRange.start.seconds).min() ?? 0
    let endSeconds = ready.map { $0.timeRange.start.seconds + $0.timeRange.duration.seconds }.max() ?? startSeconds
    let range = CMTimeRange(
      start: CMTime(seconds: startSeconds, preferredTimescale: 600),
      duration: CMTime(seconds: max(0, endSeconds - startSeconds), preferredTimescale: 600)
    )
    return [AVCaptionGroup(captions: ready, timeRange: range)]
  }
}

public struct AVCaptionPoint: Sendable {
  public var x: AVCaptionDimension
  public var y: AVCaptionDimension
  public init() {
    self.x = AVCaptionDimension()
    self.y = AVCaptionDimension()
  }
  public init(x: AVCaptionDimension, y: AVCaptionDimension) {
    self.x = x
    self.y = y
  }
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
  var storedIdentifier: String?
  var storedOrigin = AVCaptionPoint()
  var storedSize = AVCaptionSize()
  var storedScroll = Scroll.none
  var storedDisplayAlignment = DisplayAlignment.before
  var storedWritingMode = WritingMode.leftToRightAndTopToBottom
  public class var appleITTTop: AVCaptionRegion { AVCaptionRegion() }
  public class var appleITTBottom: AVCaptionRegion { AVCaptionRegion() }
  public class var appleITTLeft: AVCaptionRegion { AVCaptionRegion() }
  public class var appleITTRight: AVCaptionRegion { AVCaptionRegion() }
  public class var subRipTextBottom: AVCaptionRegion { AVCaptionRegion() }
  public var identifier: String? { storedIdentifier }
  public var origin: AVCaptionPoint { storedOrigin }
  public var size: AVCaptionSize { storedSize }
  public var scroll: AVCaptionRegion.Scroll { storedScroll }
  public var displayAlignment: AVCaptionRegion.DisplayAlignment { storedDisplayAlignment }
  public var writingMode: AVCaptionRegion.WritingMode { storedWritingMode }
  public func encode(with encoder: NSCoder) {}
  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? AVCaptionRegion else { return false }
    return storedIdentifier == other.storedIdentifier
      && storedOrigin.x.value == other.storedOrigin.x.value
      && storedOrigin.x.units == other.storedOrigin.x.units
      && storedOrigin.y.value == other.storedOrigin.y.value
      && storedOrigin.y.units == other.storedOrigin.y.units
      && storedSize.width.value == other.storedSize.width.value
      && storedSize.width.units == other.storedSize.width.units
      && storedSize.height.value == other.storedSize.height.value
      && storedSize.height.units == other.storedSize.height.units
      && storedScroll == other.storedScroll
      && storedDisplayAlignment == other.storedDisplayAlignment
      && storedWritingMode == other.storedWritingMode
  }
  public override func mutableCopy() -> Any {
    mutableCopy(with: nil)
  }
  public func mutableCopy(with zone: NSZone? = nil) -> Any {
    _ = zone
    let copy = AVMutableCaptionRegion()
    copy.storedIdentifier = storedIdentifier
    copy.storedOrigin = storedOrigin
    copy.storedSize = storedSize
    copy.storedScroll = storedScroll
    copy.storedDisplayAlignment = storedDisplayAlignment
    copy.storedWritingMode = storedWritingMode
    return copy
  }
}

open class AVCaptionRenderer: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  open class Scene: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var timeRange: CMTimeRange { .zero }
    public var hasActiveCaptions: Bool { false }
    public var needsPeriodicRefresh: Bool { false }
  }
  public var captions: [AVCaption] = []
  public var bounds: CGRect = .zero
  public func captionSceneChanges(in consideredTimeRange: CMTimeRange) -> [AVCaptionRenderer.Scene] {
    _ = consideredTimeRange
    return []
  }
  public func render(in ctx: CGContext, for time: CMTime) {
    _ = (ctx, time)
  }
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
  public var width: AVCaptionDimension
  public var height: AVCaptionDimension
  public init() {
    self.width = AVCaptionDimension()
    self.height = AVCaptionDimension()
  }
  public init(width: AVCaptionDimension, height: AVCaptionDimension) {
    self.width = width
    self.height = height
  }
}

public enum AVCaptionUnitsType: Int, Hashable, Sendable {
  case unspecified = 0
  case cells = 1
  case percent = 2
}

import Foundation

open class AVOutputSettingsAssistant: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public class func availableOutputSettingsPresets() -> [AVOutputSettingsPreset] { [] }
  convenience init?(preset presetIdentifier: AVOutputSettingsPreset) { return nil }
  public var audioSettings: [String : Any]? { nil }
  public var videoSettings: [String : Any]? { nil }
  public var outputFileType: AVFileType { AVFileType(rawValue: "") }
  public var sourceAudioFormat: CMAudioFormatDescription? {
      get { nil }
      set { _ = newValue }
    }
  public var sourceVideoFormat: CMVideoFormatDescription? {
      get { nil }
      set { _ = newValue }
    }
  public var sourceVideoAverageFrameDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var sourceVideoMinFrameDuration: CMTime {
      get { .zero }
      set { _ = newValue }
    }
}

public struct AVOutputSettingsPreset: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let preset640x480 = AVOutputSettingsPreset(rawValue: "preset640x480")
  public static let preset960x540 = AVOutputSettingsPreset(rawValue: "preset960x540")
  public static let preset1280x720 = AVOutputSettingsPreset(rawValue: "preset1280x720")
  public static let preset1920x1080 = AVOutputSettingsPreset(rawValue: "preset1920x1080")
  public static let preset3840x2160 = AVOutputSettingsPreset(rawValue: "preset3840x2160")
  public static let hevc1920x1080 = AVOutputSettingsPreset(rawValue: "hevc1920x1080")
  public static let hevc1920x1080WithAlpha = AVOutputSettingsPreset(rawValue: "hevc1920x1080WithAlpha")
  public static let hevc3840x2160 = AVOutputSettingsPreset(rawValue: "hevc3840x2160")
  public static let hevc3840x2160WithAlpha = AVOutputSettingsPreset(rawValue: "hevc3840x2160WithAlpha")
  public static let hevc4320x2160 = AVOutputSettingsPreset(rawValue: "hevc4320x2160")
  public static let hevc7680x4320 = AVOutputSettingsPreset(rawValue: "hevc7680x4320")
  public static let mvhevc960x960 = AVOutputSettingsPreset(rawValue: "mvhevc960x960")
  public static let mvhevc1440x1440 = AVOutputSettingsPreset(rawValue: "mvhevc1440x1440")
  public static let mvhevc4320x4320 = AVOutputSettingsPreset(rawValue: "mvhevc4320x4320")
  public static let mvhevc7680x7680 = AVOutputSettingsPreset(rawValue: "mvhevc7680x7680")
}

import Foundation

open class AVOutputSettingsAssistant: NSObject, @unchecked Sendable {
  private var storedPreset: AVOutputSettingsPreset?
  private var storedSourceAudioFormat: CMAudioFormatDescription?
  private var storedSourceVideoFormat: CMVideoFormatDescription?
  private var storedAverageFrameDuration = CMTime.zero
  private var storedMinFrameDuration = CMTime.zero
  public override init() { super.init() }
  public class func availableOutputSettingsPresets() -> [AVOutputSettingsPreset] { [] }
  public convenience init?(preset presetIdentifier: AVOutputSettingsPreset) {
    _ = presetIdentifier
    return nil
  }
  public var audioSettings: [String : Any]? { nil }
  public var videoSettings: [String : Any]? { nil }
  public var outputFileType: AVFileType { AVFileType.mp4 }
  public var sourceAudioFormat: CMAudioFormatDescription? {
      get { storedSourceAudioFormat }
      set { storedSourceAudioFormat = newValue }
    }
  public var sourceVideoFormat: CMVideoFormatDescription? {
      get { storedSourceVideoFormat }
      set { storedSourceVideoFormat = newValue }
    }
  public var sourceVideoAverageFrameDuration: CMTime {
      get { storedAverageFrameDuration }
      set { storedAverageFrameDuration = newValue }
    }
  public var sourceVideoMinFrameDuration: CMTime {
      get { storedMinFrameDuration }
      set { storedMinFrameDuration = newValue }
    }
}

public struct AVOutputSettingsPreset: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let preset640x480 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPreset640x480")
  public static let preset960x540 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPreset960x540")
  public static let preset1280x720 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPreset1280x720")
  public static let preset1920x1080 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPreset1920x1080")
  public static let preset3840x2160 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPreset3840x2160")
  public static let hevc1920x1080 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetHEVC1920x1080")
  public static let hevc1920x1080WithAlpha = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetHEVC1920x1080WithAlpha")
  public static let hevc3840x2160 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetHEVC3840x2160")
  public static let hevc3840x2160WithAlpha = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetHEVC3840x2160WithAlpha")
  public static let hevc4320x2160 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetHEVC4320x2160")
  public static let hevc7680x4320 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetHEVC7680x4320")
  public static let mvhevc960x960 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetMVHEVC960x960")
  public static let mvhevc1440x1440 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetMVHEVC1440x1440")
  public static let mvhevc4320x4320 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetMVHEVC4320x4320")
  public static let mvhevc7680x7680 = AVOutputSettingsPreset(rawValue: "AVOutputSettingsPresetMVHEVC7680x7680")
}

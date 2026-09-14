import Foundation

extension AVFileType {
  // UTI strings measured 2026-09-14 from Xcode 26.1 `import AVFoundation` on macOS 26.
  public static let qta: AVFileType = AVFileType(rawValue: "com.apple.quicktime-audio")
  public static let m4v: AVFileType = AVFileType(rawValue: "com.apple.m4v-video")
  public static let mobile3GPP: AVFileType = AVFileType(rawValue: "public.3gpp")
  public static let mobile3GPP2: AVFileType = AVFileType(rawValue: "public.3gpp2")
  public static let caf: AVFileType = AVFileType(rawValue: "com.apple.coreaudio-format")
  public static let wav: AVFileType = AVFileType(rawValue: "com.microsoft.waveform-audio")
  public static let aiff: AVFileType = AVFileType(rawValue: "public.aiff-audio")
  public static let aifc: AVFileType = AVFileType(rawValue: "public.aifc-audio")
  public static let amr: AVFileType = AVFileType(rawValue: "org.3gpp.adaptive-multi-rate-audio")
  public static let mp3: AVFileType = AVFileType(rawValue: "public.mp3")
  public static let au: AVFileType = AVFileType(rawValue: "public.au-audio")
  public static let ac3: AVFileType = AVFileType(rawValue: "public.ac3-audio")
  public static let eac3: AVFileType = AVFileType(rawValue: "public.enhanced-ac3-audio")
  public static let jpg: AVFileType = AVFileType(rawValue: "public.jpeg")
  public static let dng: AVFileType = AVFileType(rawValue: "com.adobe.raw-image")
  public static let heic: AVFileType = AVFileType(rawValue: "public.heic")
  public static let avci: AVFileType = AVFileType(rawValue: "public.avci")
  public static let heif: AVFileType = AVFileType(rawValue: "public.heif")
  public static let tif: AVFileType = AVFileType(rawValue: "public.tiff")
  public static let appleiTT: AVFileType = AVFileType(rawValue: "com.apple.itunes-timed-text")
  public static let SCC: AVFileType = AVFileType(rawValue: "com.scenarist.closed-caption")
  public static let AHAP: AVFileType = AVFileType(rawValue: "public.haptics-content")
  public static let dcm: AVFileType = AVFileType(rawValue: "org.nema.dicom")
}

public struct AVFileTypeProfile: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(_ rawValue: String) { self.init(rawValue: rawValue) }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let mpeg4AppleHLS = AVFileTypeProfile(rawValue: "MPEG4AppleHLS")
  public static let mpeg4CMAFCompliant = AVFileTypeProfile(rawValue: "MPEG4CMAFCompliant")
}

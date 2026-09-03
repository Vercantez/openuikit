import Foundation

extension AVFileType {
  public static let qta: AVFileType = AVFileType(rawValue: "")
  public static let m4v: AVFileType = AVFileType(rawValue: "")
  public static let mobile3GPP: AVFileType = AVFileType(rawValue: "")
  public static let mobile3GPP2: AVFileType = AVFileType(rawValue: "")
  public static let caf: AVFileType = AVFileType(rawValue: "")
  public static let wav: AVFileType = AVFileType(rawValue: "")
  public static let aiff: AVFileType = AVFileType(rawValue: "")
  public static let aifc: AVFileType = AVFileType(rawValue: "")
  public static let amr: AVFileType = AVFileType(rawValue: "")
  public static let mp3: AVFileType = AVFileType(rawValue: "")
  public static let au: AVFileType = AVFileType(rawValue: "")
  public static let ac3: AVFileType = AVFileType(rawValue: "")
  public static let eac3: AVFileType = AVFileType(rawValue: "")
  public static let jpg: AVFileType = AVFileType(rawValue: "")
  public static let dng: AVFileType = AVFileType(rawValue: "")
  public static let heic: AVFileType = AVFileType(rawValue: "")
  public static let avci: AVFileType = AVFileType(rawValue: "")
  public static let heif: AVFileType = AVFileType(rawValue: "")
  public static let tif: AVFileType = AVFileType(rawValue: "")
  public static let appleiTT: AVFileType = AVFileType(rawValue: "")
  public static let SCC: AVFileType = AVFileType(rawValue: "")
  public static let AHAP: AVFileType = AVFileType(rawValue: "")
  public static let dcm: AVFileType = AVFileType(rawValue: "")
}

public struct AVFileTypeProfile: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let mpeg4AppleHLS = AVFileTypeProfile(rawValue: "mpeg4AppleHLS")
  public static let mpeg4CMAFCompliant = AVFileTypeProfile(rawValue: "mpeg4CMAFCompliant")
}

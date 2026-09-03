import Foundation

extension AVFileType {
  convenience init(_ rawValue: String) {}
  public static let qta = AVFileType()
  public static let m4v = AVFileType()
  public static let mobile3GPP = AVFileType()
  public static let mobile3GPP2 = AVFileType()
  public static let caf = AVFileType()
  public static let wav = AVFileType()
  public static let aiff = AVFileType()
  public static let aifc = AVFileType()
  public static let amr = AVFileType()
  public static let mp3 = AVFileType()
  public static let au = AVFileType()
  public static let ac3 = AVFileType()
  public static let eac3 = AVFileType()
  public static let jpg = AVFileType()
  public static let dng = AVFileType()
  public static let heic = AVFileType()
  public static let avci = AVFileType()
  public static let heif = AVFileType()
  public static let tif = AVFileType()
  public static let appleiTT = AVFileType()
  public static let SCC = AVFileType()
  public static let AHAP = AVFileType()
  public static let dcm = AVFileType()
}

public struct AVFileTypeProfile: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let mpeg4AppleHLS = AVFileTypeProfile(rawValue: "mpeg4AppleHLS")
  public static let mpeg4CMAFCompliant = AVFileTypeProfile(rawValue: "mpeg4CMAFCompliant")
}

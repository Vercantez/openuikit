import Foundation

open class AVMovie: AVAsset, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(url: URL) { self.init() }
  public class func movieTypes() -> [AVFileType] { [] }
  public init(url URL: URL, options: [String : Any]? = nil) {}
  public init(data: Data, options: [String : Any]? = nil) {}
  public var url: URL? { nil }
  public var data: Data? { nil }
  public var defaultMediaDataStorage: AVMediaDataStorage? { nil }
  public var canContainMovieFragments: Bool { false }
  public var containsMovieFragments: Bool { false }
  public func makeMovieHeader(fileType: AVFileType) throws -> Data { return .init() }
  public func writeHeader(to URL: URL, fileType: AVFileType, options: AVMovieWritingOptions = []) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public func `is`(compatibleWithFileType fileType: AVFileType) -> Bool { false }
}

open class AVMovieTrack: AVAssetTrack, @unchecked Sendable {
  public override init() { super.init() }
  public var mediaPresentationTimeRange: CMTimeRange { .zero }
  public var mediaDecodeTimeRange: CMTimeRange { .zero }
  public var alternateGroupID: Int { 0 }
  public var mediaDataStorage: AVMediaDataStorage? { nil }
}

public struct AVMovieWritingOptions: OptionSet, Hashable, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let addMovieHeaderToDestination = AVMovieWritingOptions(rawValue: 1 << 0)
  public static let truncateDestinationToMovieHeaderOnly = AVMovieWritingOptions(rawValue: 1 << 1)
}

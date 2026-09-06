import Foundation

open class AVMovie: AVAsset, @unchecked Sendable {
  var portableURL: URL?
  var portableData: Data?
  var portableDefaultStorage: AVMediaDataStorage?
  var portableTimescale: CMTimeScale = 0
  var portableModified = false
  var portableInterleavingPeriod = CMTime.zero

  public override init() { super.init() }

  public convenience init(url: URL) {
    self.init(url: url, options: nil)
  }

  public init(url URL: URL, options: [String : Any]? = nil) {
    self.portableURL = URL
    super.init()
    attachMovieProbeIfNeeded(mutable: false)
    _ = options
  }

  public init(data: Data, options: [String : Any]? = nil) {
    self.portableData = data
    super.init()
    attachMovieProbeIfNeeded(mutable: false)
    _ = options
  }

  public class func movieTypes() -> [AVFileType] { [.mp4, .mov, .m4a] }

  public var url: URL? { portableURL }
  public var data: Data? { portableData }
  public var defaultMediaDataStorage: AVMediaDataStorage? { portableDefaultStorage }
  public var canContainMovieFragments: Bool { false }
  public var containsMovieFragments: Bool { false }

  public func makeMovieHeader(fileType: AVFileType) throws -> Data {
    _ = fileType
    throw AVError(.encoderNotFound)
  }

  public func writeHeader(
    to URL: URL,
    fileType: AVFileType,
    options: AVMovieWritingOptions = []
  ) throws {
    _ = (URL, fileType, options)
    throw AVError(.encoderNotFound)
  }

  public func `is`(compatibleWithFileType fileType: AVFileType) -> Bool {
    Self.movieTypes().contains(fileType)
  }

  func attachMovieProbeIfNeeded(mutable: Bool) {
    let probe: AVLocalMediaProbe?
    if let url = portableURL, url.isFileURL {
      probe = AVLocalMediaProbe.probe(url: url)
    } else if let portableData {
      probe = AVLocalMediaProbe.probe(data: portableData)
    } else {
      probe = nil
    }
    guard let probe else { return }
    attachPortableProbe(probe)
    if portableTimescale == 0, probe.duration.isValid {
      portableTimescale = probe.duration.timescale
    }
    let built: [AVAssetTrack] = probe.tracks.map { record in
      let track: AVMovieTrack = mutable ? AVMutableMovieTrack() : AVMovieTrack()
      track.portableAsset = self
      track.portableRecord = record
      return track
    }
    loadState.lock.lock()
    loadState.storedTracks = built
    loadState.lock.unlock()
  }
}

open class AVMovieTrack: AVAssetTrack, @unchecked Sendable {
  public override init() { super.init() }
  public var mediaPresentationTimeRange: CMTimeRange { timeRange }
  public var mediaDecodeTimeRange: CMTimeRange { timeRange }
  public var alternateGroupID: Int { 0 }
  public var mediaDataStorage: AVMediaDataStorage? { nil }
}

public struct AVMovieWritingOptions: OptionSet, Hashable, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let addMovieHeaderToDestination = AVMovieWritingOptions(rawValue: 1 << 0)
  public static let truncateDestinationToMovieHeaderOnly = AVMovieWritingOptions(rawValue: 1 << 1)
}

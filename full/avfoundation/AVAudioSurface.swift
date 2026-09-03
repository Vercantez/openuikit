import Foundation

open class AVAudioMix: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var inputParameters: [AVAudioMixInputParameters] { [] }
}

open class AVAudioMixInputParameters: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var trackID: CMPersistentTrackID { 0 }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm? { nil }
  public func getVolumeRamp(for time: CMTime, startVolume: UnsafeMutablePointer<Float>?, endVolume: UnsafeMutablePointer<Float>?, timeRange: UnsafeMutablePointer<CMTimeRange>?) -> Bool { false }
}

public struct AVAudioSpatializationFormats: OptionSet, Hashable, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let monoAndStereo = AVAudioSpatializationFormats(rawValue: 1 << 0)
  public static let multichannel = AVAudioSpatializationFormats(rawValue: 1 << 1)
  public static let monoStereoAndMultichannel = AVAudioSpatializationFormats(rawValue: 1 << 2)
}

public struct AVAudioTimePitchAlgorithm: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let lowQualityZeroLatency = AVAudioTimePitchAlgorithm(rawValue: "lowQualityZeroLatency")
  public static let timeDomain = AVAudioTimePitchAlgorithm(rawValue: "timeDomain")
  public static let spectral = AVAudioTimePitchAlgorithm(rawValue: "spectral")
  public static let varispeed = AVAudioTimePitchAlgorithm(rawValue: "varispeed")
}

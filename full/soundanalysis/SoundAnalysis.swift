@_exported import Foundation

#if canImport(AVFAudio)
import AVFAudio
#endif
#if canImport(CoreML)
import CoreML
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

/// Linux starting implementation of Apple's public `SoundAnalysis` module.
///
/// Value types, request-table state, and `SNError.Code` raw values are real.
/// Apple sound classification, audio decode, and Core ML inference are absent:
/// analysis paths fail closed with `SNError` instead of inventing success.
/// Isolated-host Swift has no `AVFAudio`, `CoreMedia`, or `CoreML` modules;
/// `CMTime` / `CMTimeRange` below are compile stand-ins used only when the
/// real CoreMedia module is missing. They are not SoundAnalysis-owned ABI
/// and must not be copied into a guest CoreMedia product.

public let SNErrorDomain = "SNErrorDomain"

func snLinuxUnavailable(
    _ code: SNError.Code,
    reason: String = "Sound Analysis has no Apple classifier, audio decoder, or ML runtime on this Linux host"
) -> SNError {
    SNError(code, userInfo: [NSLocalizedDescriptionKey: reason])
}

#if !canImport(CoreMedia)
/// Isolated-host CoreMedia stand-in. Field layout matches the documented
/// `CMTime` C struct (value, timescale, flags, epoch). Not Darwin ABI.
public struct CMTime: Equatable, Hashable, Sendable {
    public var value: Int64
    public var timescale: Int32
    public var flags: UInt32
    public var epoch: Int64

    public init(value: Int64, timescale: Int32, flags: UInt32 = 1, epoch: Int64 = 0) {
        self.value = value
        self.timescale = timescale
        self.flags = flags
        self.epoch = epoch
    }

    public static let zero = CMTime(value: 0, timescale: 1, flags: 1, epoch: 0)
    public static let invalid = CMTime(value: 0, timescale: 0, flags: 0, epoch: 0)

    public var isValid: Bool { flags & 1 != 0 }
}

/// Isolated-host CoreMedia stand-in. Not Darwin ABI.
public struct CMTimeRange: Equatable, Hashable, Sendable {
    public var start: CMTime
    public var duration: CMTime

    public init(start: CMTime, duration: CMTime) {
        self.start = start
        self.duration = duration
    }

    public static let zero = CMTimeRange(start: .zero, duration: .zero)
    public static let invalid = CMTimeRange(start: .invalid, duration: .invalid)
}
#endif

final class SNAnalyzerRequestTable {
    private var entries: [(request: any SNRequest, observer: any SNResultsObserving)] = []
    private(set) var cancelled = false
    private(set) var completed = false

    var count: Int { entries.count }

    func add(_ request: any SNRequest, observer: any SNResultsObserving) throws {
        let identity = ObjectIdentifier(request as AnyObject)
        if entries.contains(where: { ObjectIdentifier($0.request as AnyObject) == identity }) {
            throw snLinuxUnavailable(
                .operationFailed,
                reason: "The request is already attached to this analyzer"
            )
        }
        entries.append((request, observer))
    }

    func remove(_ request: any SNRequest) {
        let identity = ObjectIdentifier(request as AnyObject)
        entries.removeAll { ObjectIdentifier($0.request as AnyObject) == identity }
    }

    func removeAll() {
        entries.removeAll()
    }

    func cancel() {
        cancelled = true
    }

    func failAll(_ error: SNError) {
        let snapshot = entries
        for entry in snapshot {
            entry.observer.request(entry.request, didFailWithError: error)
        }
    }

    func completeAll() {
        completed = true
        let snapshot = entries
        for entry in snapshot {
            entry.observer.requestDidComplete(entry.request)
        }
    }
}

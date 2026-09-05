import Foundation

#if canImport(AVFAudio)
import AVFAudio
#endif

/// Stream analyzer. Isolated Linux Swift cannot import `AVFAudio`, so
/// `init(format:)` and `analyze(_:atAudioFramePosition:)` are compiled only
/// when that real module exists. Host tests use `@_spi(OpenUIKitHost)` to
/// exercise the request table without an `AVAudioFormat` lookalike.
public final class SNAudioStreamAnalyzer: NSObject {
    private let table = SNAnalyzerRequestTable()

    @available(*, unavailable)
    public override init() {
        fatalError("SNAudioStreamAnalyzer has no public default initializer")
    }

#if canImport(AVFAudio)
    public init(format: AVAudioFormat) {
        _ = format
        super.init()
    }

    public func analyze(
        _ audioBuffer: AVAudioBuffer,
        atAudioFramePosition audioFramePosition: AVAudioFramePosition
    ) {
        _ = audioBuffer
        _ = audioFramePosition
        table.failAll(snLinuxUnavailable(.invalidFormat))
    }
#endif

    @_spi(OpenUIKitHost)
    public init(hostPlaceholder: Void) {
        super.init()
    }

    public func add(_ request: any SNRequest, withObserver observer: any SNResultsObserving) throws {
        try table.add(request, observer: observer)
    }

    public func remove(_ request: any SNRequest) {
        table.remove(request)
    }

    public func removeAllRequests() {
        table.removeAll()
    }

    public func completeAnalysis() {
        table.completeAll()
    }
}

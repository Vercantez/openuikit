import Foundation

/// Empty fail-closed stream of analysis results. Linux never yields a
/// detection; iteration completes with `nil` and does not throw.
struct SCVideoStreamAnalysisChangeSequence: AsyncSequence, Sendable {
    typealias Element = SCSensitivityAnalysis
    typealias Failure = Error

    struct AsyncIterator: AsyncIteratorProtocol, Sendable {
        mutating func next() async throws -> SCSensitivityAnalysis? {
            nil
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }
}

/// Video-stream sensitivity analyzer for FaceTime-style calls. Linux has no
/// capture device, decompression session, or pixel-buffer classifier.
open class SCVideoStreamAnalyzer: NSObject {
    /// Stream direction. Raw values follow the pinned `dotnet/macios`
    /// `SCVideoStreamAnalyzerStreamDirection` enumeration
    /// (`outgoing = 1`, `incoming = 2`). `0` is not a valid value.
    public enum StreamDirection: Int, Hashable, Sendable {
        case outgoing = 1
        case incoming = 2
    }

    private let participantUUID: String
    private let streamDirection: StreamDirection
    private var continueCount = 0
    private var sessionEnded = false

    /// Latest analysis, if any. Linux never produces one; remains `nil`.
    open var analysis: SCSensitivityAnalysis? { nil }

    /// Creates a stream analyzer for a conference participant.
    /// Linux constructs the tracker object; analysis hardware is not required
    /// until `beginAnalysis(of:)` (those overloads need AVFoundation /
    /// VideoToolbox types and are not compiled here).
    public init(participantUUID: String, streamDirection: StreamDirection) throws {
        self.participantUUID = participantUUID
        self.streamDirection = streamDirection
        super.init()
    }

    @available(*, unavailable, message: "SCVideoStreamAnalyzer has no public default initializer on Apple.")
    public override init() {
        fatalError("SCVideoStreamAnalyzer.init is unavailable")
    }

    /// Isolated-host: UUID captured at construction.
    @_spi(OpenUIKitHost)
    public var host_participantUUID: String { participantUUID }

    /// Isolated-host: direction captured at construction.
    @_spi(OpenUIKitHost)
    public var host_streamDirection: StreamDirection { streamDirection }

    /// Isolated-host: times `continueStream()` ran before `endAnalysis()`.
    @_spi(OpenUIKitHost)
    public var host_continueCount: Int { continueCount }

    /// Isolated-host: whether `endAnalysis()` has been called.
    @_spi(OpenUIKitHost)
    public var host_sessionEnded: Bool { sessionEnded }

    /// Isolated-host: the analysis-changes sequence never yields.
    @_spi(OpenUIKitHost)
    public var host_analysisChangesNeverYields: Bool { true }

    /// Signals that the local user chose to continue a flagged stream.
    /// Linux has no flag to clear; increments a host counter while the
    /// session has not ended and never mutates `analysis`.
    open func continueStream() {
        if !sessionEnded {
            continueCount += 1
        }
    }

    /// Ends analysis for this stream. Linux clears the continue counter's
    /// active session; `analysis` stays `nil`.
    open func endAnalysis() {
        sessionEnded = true
    }

    /// `analyze(_:)` requires a real `CoreVideo.CVPixelBuffer`. Isolated
    /// Swift has no CoreVideo module and this seed must not ship a lookalike.
    ///
    /// `beginAnalysis(of: AVCaptureDeviceInput)` requires AVFoundation.
    /// `beginAnalysis(of: VTDecompressionSession)` requires VideoToolbox.
}

extension SCVideoStreamAnalyzer {
    /// A stream the app uses to receive video-stream analysis results.
    /// Linux yields nothing and finishes; it does not invent detections.
    public var analysisChanges: some AsyncSequence<SCSensitivityAnalysis, any Error> {
        SCVideoStreamAnalysisChangeSequence()
    }
}

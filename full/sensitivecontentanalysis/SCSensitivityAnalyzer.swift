import Foundation

/// Analyzer for images and video files. Linux has no Communication Safety
/// setting and no on-device classifier: `analysisPolicy` is `.disabled` and
/// analysis methods fail closed.
open class SCSensitivityAnalyzer: NSObject, @unchecked Sendable {
    /// Linux has no Communication Safety / Sensitive Content Warning setting.
    /// The honest local policy is `.disabled`. Darwin's default when the
    /// setting is unset is an oracle question.
    open var analysisPolicy: SCSensitivityAnalysisPolicy { .disabled }

    public override init() {
        super.init()
    }

    /// Completion-handler overlay of `analyzeImageFile:completionHandler:`.
    /// Invokes the handler once, synchronously, with `(nil, SCLinuxUnavailableError)`.
    open func analyzeImage(
        at fileURL: URL,
        completionHandler: @escaping (SCSensitivityAnalysis?, (any Error)?) -> Void
    ) {
        _ = fileURL
        completionHandler(nil, scLinuxUnavailable())
    }

    /// Async overlay of the same ObjC selector. Throws `SCLinuxUnavailableError`
    /// without inventing an analysis result.
    open func analyzeImage(at fileURL: URL) async throws -> SCSensitivityAnalysis {
        _ = fileURL
        throw scLinuxUnavailable()
    }

    /// `analyzeImage(_:)` / `analyzeCGImage:completionHandler:` require a real
    /// `CoreGraphics.CGImage`. Isolated Swift has no CoreGraphics module and
    /// this seed must not ship a lookalike type.
}

extension SCSensitivityAnalyzer {
    /// Encapsulates a `Progress` instance and an async method to run analysis.
    /// Apple's designated initializer is missing; construct via
    /// `videoAnalysis(forFileAt:)`.
    public final class VideoAnalysisHandler {
        /// Progress used to track sensitivity analysis. Stored, assignable
        /// (API digester records a setter). Linux never completes this as
        /// successful classification.
        public var progress: Progress

        let fileURL: URL

        fileprivate init(fileURL: URL) {
            self.fileURL = fileURL
            self.progress = Progress(totalUnitCount: 1)
        }

        /// Shared fail-closed body of `hasSensitiveContent()`. Cancels
        /// `progress` and returns the Linux unavailable error. Does not
        /// invent an `SCSensitivityAnalysis`.
        func prepareFailClosed() -> SCLinuxUnavailableError {
            if !progress.isCancelled {
                progress.cancel()
            }
            return scLinuxUnavailable()
        }

        /// Isolated-host: same error `hasSensitiveContent()` throws.
        @_spi(OpenUIKitHost)
        public func host_prepareFailClosed() -> SCLinuxUnavailableError {
            prepareFailClosed()
        }

        /// Isolated-host: the file URL captured at construction.
        @_spi(OpenUIKitHost)
        public var host_fileURL: URL { fileURL }

        /// Performs sensitivity analysis on the previously specified video
        /// file. Linux has no decoder or classifier; throws
        /// `SCLinuxUnavailableError` after cancelling `progress`.
        public func hasSensitiveContent() async throws -> SCSensitivityAnalysis {
            throw prepareFailClosed()
        }
    }

    /// Creates a `VideoAnalysisHandler` for a video file. Construction does
    /// not inspect the file and does not start analysis.
    public func videoAnalysis(forFileAt fileURL: URL) -> VideoAnalysisHandler {
        VideoAnalysisHandler(fileURL: fileURL)
    }
}

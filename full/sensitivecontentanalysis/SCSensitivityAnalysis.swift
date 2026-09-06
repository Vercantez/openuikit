import Foundation

/// Result of a sensitivity analysis. Apple's public surface has no designated
/// initializer (`DisableDefaultCtor`); instances come from analysis APIs.
/// Linux never returns one of those from ML. Tests construct snapshots through
/// `host_makeUnanalyzed`.
open class SCSensitivityAnalysis: NSObject, @unchecked Sendable {
    private let _isSensitive: Bool
    private let _shouldIndicateSensitivity: Bool
    private let _shouldInterruptVideo: Bool
    private let _shouldMuteAudio: Bool

    @available(*, unavailable, message: "SCSensitivityAnalysis has no public designated initializer on Apple; results come from analysis APIs.")
    public override init() {
        fatalError("SCSensitivityAnalysis.init is unavailable")
    }

    /// Isolated-host constructor. Not part of Apple's public surface.
    /// Stored flags are independent; Linux analysis paths never produce a
    /// snapshot by claiming content was classified.
    @_spi(OpenUIKitHost)
    public static func host_makeUnanalyzed(
        isSensitive: Bool = false,
        shouldIndicateSensitivity: Bool = false,
        shouldInterruptVideo: Bool = false,
        shouldMuteAudio: Bool = false
    ) -> SCSensitivityAnalysis {
        SCSensitivityAnalysis(
            isSensitive: isSensitive,
            shouldIndicateSensitivity: shouldIndicateSensitivity,
            shouldInterruptVideo: shouldInterruptVideo,
            shouldMuteAudio: shouldMuteAudio
        )
    }

    fileprivate init(
        isSensitive: Bool,
        shouldIndicateSensitivity: Bool,
        shouldInterruptVideo: Bool,
        shouldMuteAudio: Bool
    ) {
        self._isSensitive = isSensitive
        self._shouldIndicateSensitivity = shouldIndicateSensitivity
        self._shouldInterruptVideo = shouldInterruptVideo
        self._shouldMuteAudio = shouldMuteAudio
        super.init()
    }

    open var isSensitive: Bool { _isSensitive }

    open var shouldIndicateSensitivity: Bool { _shouldIndicateSensitivity }

    open var shouldInterruptVideo: Bool { _shouldInterruptVideo }

    open var shouldMuteAudio: Bool { _shouldMuteAudio }
}

/// Linux-only host-control SPI for Audio Unit plug-in and render availability.
///
/// These hooks are not Apple public API. They exist so Linux callers can query
/// and fail closed without fabricating Apple AU plug-in hosting, realtime
/// render, or Apple-supplied system units (HighPass, DynamicsProcessor,
/// PeakLimiter, AUiPodTimeOther).
@_spi(AudioUnitLinux)
public enum AudioUnitLinuxHost: Sendable {
    /// Historical Component Manager vs Audio Component threshold used by
    /// open-source clients (`AUDIO_UNIT_VERSION < 1060`).
    public static let audioComponentAPIFloor: Int32 = 1060

    /// Apple Audio Unit plug-in registry, instantiation, and in-process hosting.
    public static var pluginHostingAvailable: Bool { false }

    /// Realtime render callbacks on a Core Audio hardware I/O timeline.
    public static var realtimeRenderAvailable: Bool { false }

    /// Apple-supplied AU effects and converters from the system component registry.
    public static var appleSystemUnitsAvailable: Bool { false }

    /// Fail closed: Linux has no Audio Unit plug-in host.
    public static func requirePluginHosting() throws {
        throw AudioUnitLinuxHostError.pluginHostingUnavailable
    }

    /// Fail closed: Linux has no Core Audio realtime render timeline.
    public static func requireRealtimeRender() throws {
        throw AudioUnitLinuxHostError.realtimeRenderUnavailable
    }

    /// Fail closed: Apple system AUs are not instantiated on Linux.
    ///
    /// `subtypeFourCC` is a raw four-character code from the caller. Named
    /// `kAudioUnitSubType_*` constants are owned by AudioToolbox and are not
    /// redeclared here.
    public static func instantiateAppleSystemUnit(subtypeFourCC: UInt32) throws {
        throw AudioUnitLinuxHostError.appleSystemUnitUnavailable(subtypeFourCC: subtypeFourCC)
    }
}

/// Fail-closed errors for Linux Audio Unit host operations.
@_spi(AudioUnitLinux)
public enum AudioUnitLinuxHostError: Error, Equatable, Sendable {
    case pluginHostingUnavailable
    case realtimeRenderUnavailable
    case appleSystemUnitUnavailable(subtypeFourCC: UInt32)
}

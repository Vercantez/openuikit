import AVFoundation

/// Schema-v1-era runtime probe kept beside the sealed load-smoke marker.
/// Behavioral checks live in `*Tests.swift`; the host runner prints the marker.
enum AVFoundationRuntimeProbe {
    static let marker = "AVFOUNDATION_AGENT_RUNTIME_OK"
}

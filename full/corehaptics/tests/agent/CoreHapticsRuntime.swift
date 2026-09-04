import CoreHaptics
import Foundation

/// Schema-v2 sealed acceptance compiles `tests/agent/*Tests.swift` and the
/// generated load-smoke runner. This file records the runtime contract those
/// tests exercise: AHAP-shaped pattern dictionaries, macios error codes, and
/// fail-closed engine/player operations on Linux (no haptic renderer).
enum CoreHapticsRuntime {
    static let errorDomain = "CoreHapticsErrorDomain"
    static let timeImmediate: TimeInterval = 0
}

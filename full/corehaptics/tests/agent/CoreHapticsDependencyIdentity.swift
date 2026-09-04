import CoreHaptics
import Foundation

/// Isolated-host identity probe. Real Foundation values pass through
/// CoreHaptics APIs. The sealed host gate does not compile this file.
func coreHapticsDependencyIdentityProbe() {
    let immediate: TimeInterval = CHHapticTimeImmediate
    let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
    intensity.value = Float(1)
    let event = CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [intensity],
        relativeTime: immediate
    )
    event.relativeTime = TimeInterval(0)
    event.duration = TimeInterval(0)

    let pattern: CHHapticPattern
    do {
        pattern = try CHHapticPattern(events: [event], parameters: [])
    } catch {
        preconditionFailure("pattern construction failed: \(error)")
    }
    precondition(pattern.duration == TimeInterval(0))

    let engine: CHHapticEngine
    do {
        engine = try CHHapticEngine()
    } catch {
        preconditionFailure("engine construction failed: \(error)")
    }
    engine.isAutoShutdownEnabled = true
    precondition(engine.isAutoShutdownEnabled)

    let data = Data()
    do {
        try engine.playPattern(from: data)
        preconditionFailure("empty data must not play")
    } catch let error as CHHapticError {
        precondition(error.code == .invalidPatternData)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }

    let missing = URL(fileURLWithPath: "/tmp/corehaptics-identity-missing.ahap")
    do {
        try engine.playPattern(from: missing)
        preconditionFailure("missing URL must not play")
    } catch let error as CHHapticError {
        precondition(error.code == .fileNotFound)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }

    let domain: String = CoreHapticsErrorDomain
    let bridged = CHHapticError(.notSupported, userInfo: ["foundation": domain])
    precondition(bridged.userInfo["foundation"] as? String == domain)
    let ns = bridged as NSError
    precondition(ns.domain == CoreHapticsErrorDomain)
    precondition(ns.code == CHHapticError.Code.notSupported.rawValue)
}

#if COREHAPTICS_IDENTITY_MAIN
coreHapticsDependencyIdentityProbe()
print("COREHAPTICS_DEPENDENCY_IDENTITY_OK")
#endif

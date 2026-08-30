// Host-owned build input for generated UIApplication scene entry points.
//
// This is deliberately outside OpenUIKit: the framework owns lifecycle
// state, while the executable host owns the monotonic clock and every moment
// the main thread blocks. `UIKitRunLoop` is the production frame driver from
// full/driver/RunLoop.swift, compiled into the same application module.
//
// Production runs do not return. A proof runner may set
// OPENUIKIT_HOST_TURNS to a positive integer; that bounds the real clocked,
// sleeping loop after exactly that many UIWindow.tick turns and then reports
// a normal host-requested termination.

import CPortableIO
import UIKit

@MainActor
enum PortableUIKitApplicationHost {
    private static func boundedTurnCount() -> Int? {
        guard let value = cpio_getenv("OPENUIKIT_HOST_TURNS") else { return nil }
        guard let count = Int(String(cString: value)), count > 0 else {
            preconditionFailure("OPENUIKIT_HOST_TURNS must be a positive integer")
        }
        return count
    }

    static func run(application: UIApplication, scene: UIWindowScene) {
        precondition(scene.activationState == .foregroundActive,
                     "generated bootstrap must activate its scene before entering the host loop")
        guard let window = scene.keyWindow ?? scene.windows.first else {
            preconditionFailure("scene delegate returned without installing a UIWindow")
        }

        print("PORTABLE_UIKIT_HOST_ACTIVE windows=\(scene.windows.count)")
        let runLoop = UIKitRunLoop(window: window, source: MonotonicFrameSource())
        var turns = 0
        if let limit = boundedTurnCount() {
            let result = runLoop.run(timeout: .greatestFiniteMagnitude) {
                turns += 1
                return turns >= limit
            }
            precondition(result.turns == limit,
                         "bounded host loop returned before its requested turn count")
            let minimumElapsed = runLoop.frameInterval * Double(max(0, limit - 1)) * 0.8
            precondition(result.elapsed >= minimumElapsed,
                         "bounded proof did not use the real paced host clock")
            print("PORTABLE_UIKIT_HOST_LOOP_OK turns=\(turns) paced=true")
            application._hostWillTerminate()
            return
        }

        // The production contract: the application entry point remains in a
        // clocked host loop instead of returning immediately after willConnect.
        _ = runLoop.run(timeout: .greatestFiniteMagnitude) { false }
        preconditionFailure("unbounded application host loop returned")
    }
}

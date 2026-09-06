@_exported import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

/// Linux starting implementation of Apple's public `WorkoutKit` module,
/// seeded from the Xcode 26.1 iPhoneOS symbol graph (279 exact IDs).
///
/// Value types (goals, alerts, steps, interval blocks, the four workout
/// shapes, and `WorkoutPlan`) are real in-process values with documented
/// equality, hashing, support matrices, and a Linux-local plan codec.
/// Watch pairing, HealthKit workout-plan attachment, and the SwiftUI
/// preview overlay stay fail-closed or not-applicable: this port never
/// invents a paired Apple Watch, a Workout app install, or a successful
/// authorization grant.
enum WorkoutKitModule {
    /// Codec identifier stored in `WorkoutPlan.dataRepresentation`.
    /// This is not Apple's on-watch binary layout.
    static let planFormat = "OpenUIKit.WorkoutKit.WorkoutPlan.v1"
}

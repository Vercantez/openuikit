@_exported import Foundation

/// Linux starting point for Apple's public `HealthKit` module.
///
/// Local unit conversion, type identifiers, sample construction, and query
/// predicates are implemented. The Health store, authorization, background
/// delivery, clinical records, and device/session hardware paths fail closed:
/// `HKHealthStore.isHealthDataAvailable()` is `false` and mutating APIs throw
/// or complete with `HKError.errorHealthDataUnavailable`.
public enum HealthKitModule {
    public static let linuxPortName = "HealthKit"
}

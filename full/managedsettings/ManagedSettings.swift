import Foundation

// Linux starting point for Apple's ManagedSettings. Screen Time / Family
// Controls authorization, the Managed Settings daemon, and shield UI
// extensions do not exist on this host. Value types, named in-process
// stores, documented metadata defaults, and fail-closed shield-action
// replies are implemented and tested here. Writing a store never applies
// an operating-system restriction.

// MARK: - Groups

/// A group of settings to manage.
public protocol ManagedSettingsGroup {}

// MARK: - Metadata

/// Additional information about a configurable setting.
public struct SettingMetadata<Value> {
    /// The implicit value for a setting if your app doesn't set a value.
    public let defaultValue: Value

    init(defaultValue: Value) {
        self.defaultValue = defaultValue
    }
}

/// Additional information about a bounded setting.
public struct BoundedSettingMetadata<Value> where Value: Comparable {
    /// The implicit value for a setting if your app doesn't set a value.
    public let defaultValue: Value

    /// The range of values that a setting can accomodate.
    public let bounds: ClosedRange<Value>

    init(defaultValue: Value, bounds: ClosedRange<Value>) {
        self.defaultValue = defaultValue
        self.bounds = bounds
    }
}

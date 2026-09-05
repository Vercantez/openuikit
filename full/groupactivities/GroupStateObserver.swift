import Foundation

/// Process-local observer for SharePlay eligibility.
///
/// Linux has no FaceTime / Messages entitlement check, so
/// ``isEligibleForGroupSession`` is always `false`. Combine `$` publishers are
/// omitted because Combine is not a declared isolated-host dependency.
public final class GroupStateObserver {
    public var isEligibleForGroupSession: Bool { false }

    public init() {}
}

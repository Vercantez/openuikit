import Foundation

/// Broadcast presentation flags for a group activity.
///
/// Only ``mirroredVideo`` is named in the Xcode 26.1 graph. Its raw value is
/// the first option-set bit (`1`). That assignment is declaration-order
/// inference, not an observed Apple runtime probe.
public struct BroadcastOptions: OptionSet, Hashable, Sendable {
    public typealias RawValue = Int
    public typealias Element = BroadcastOptions
    public typealias ArrayLiteralElement = BroadcastOptions

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let mirroredVideo = BroadcastOptions(rawValue: 1 << 0)
}

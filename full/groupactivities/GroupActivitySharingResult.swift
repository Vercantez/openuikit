import Foundation

/// Overlay result of presenting a sharing UI. The UIKit controller itself is
/// unavailable on Linux; this enum is reconstructed so callers can still switch
/// on a sharing outcome without importing UIKit.
public enum GroupActivitySharingResult: Hashable, Sendable {
    case success
    case cancelled
}

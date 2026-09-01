@_exported import Foundation
#if canImport(Matter)
import Matter
#endif

/// Internal fail-closed error. Apple's thrown identity for `perform()` and the
/// extension callbacks is not in the public graph, so this type is not public.
enum MatterSupportPlatformError: Error, Equatable {
    case unavailable
}

func _matterSupportFailClosed() -> MatterSupportPlatformError {
    .unavailable
}

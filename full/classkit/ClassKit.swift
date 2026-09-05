import Foundation

/// Linux starting point for Apple's public `ClassKit` module.
///
/// Value types, curriculum-tree state, activity progress, and error codes are
/// real and process-local. Persistence into Apple Schoolwork / the ClassKit
/// daemon is fail-closed with `CLSError.Code.classKitUnavailable`.
///
/// This file is the required primary product source for the sealed fan-out
/// gate. Declarations live in the companion sources listed in
/// `classkit_guest_sources.txt`.
public enum ClassKitModule {
    /// Human-readable overlay identity; not an Apple public symbol.
    public static let portableOverlayName = "ClassKit"
}

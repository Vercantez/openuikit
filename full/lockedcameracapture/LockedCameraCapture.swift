/// Portable Linux starting point for Apple's public `LockedCameraCapture` module.
///
/// Value types, the session working directory, the manager URL list, appearance
/// delay depth, and `ApplicationLaunchError` discriminators are real. Linux has
/// no Lock Screen camera extension, containing-app handoff, PhotoKit ingest, or
/// device authentication: `openApplication(for:)` always throws
/// `ApplicationLaunchError.unknown`, and manager session-content URLs stay empty
/// until a host injects them. Isolated-host `async throws` methods are
/// synchronous `throws` so the sealed runner (no run loop) can exercise them.
///
/// Apple annotates extension types `@MainActor`. The isolated Linux host has no
/// UIKit/SwiftUI run loop, so those types are usable from synchronous tests.

import Foundation

/// A type to use when opening your app from the capture extension.
///
/// Apple's string payload is not in the pinned graph, digester, TBD, or
/// `dotnet/macios` bindings. Linux uses the constant's own name as a stable
/// identity so `NSUserActivity(activityType:)` round-trips; the Darwin value
/// is an oracle question.
public let NSUserActivityTypeLockedCameraCapture: String =
    "NSUserActivityTypeLockedCameraCapture"

/// Linux-local fail-closed errors that are not Apple `ApplicationLaunchError`
/// cases. Used when a session working directory cannot be created.
public enum LockedCameraCaptureHostError: Error, Equatable, Hashable, Sendable {
    /// `FileManager` could not create the session working directory.
    case sessionDirectoryUnavailable
}

extension LockedCameraCaptureHostError: CustomNSError {
    public static var errorDomain: String { "LockedCameraCapture.Linux" }

    public var errorCode: Int {
        switch self {
        case .sessionDirectoryUnavailable: return 1
        }
    }
}

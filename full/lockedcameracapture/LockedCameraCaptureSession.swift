import Foundation

/// An object that can request to open the extension's containing app and
/// receives session configuration updates.
///
/// Darwin: only the system initializes this type. Linux vends a process-local
/// session with a unique temporary working directory. `openApplication(for:)`
/// never unlocks a device or launches a containing app.
public final class LockedCameraCaptureSession: @unchecked Sendable {
    private let lock = NSLock()
    private let contentURL: URL
    private var lastOpenActivityType: String?

    /// A temporary directory URL inside the extension's data container.
    ///
    /// Store captured content during the current session to this URL. Linux
    /// creates a process-local directory; it is not an Apple extension data
    /// container and is never copied into a containing app.
    public var sessionContentURL: URL { contentURL }

    init(sessionContentURL: URL) {
        self.contentURL = sessionContentURL
    }

    /// Initiates a request to open the extension's containing app.
    ///
    /// Darwin prompts for authentication when needed. Linux has no lock-screen
    /// auth or containing app, so this always throws `.unknown`. Isolated-host
    /// signature is `throws` (Apple's USR is `async throws`); `try await` still
    /// compiles.
    public func openApplication(for userActivity: NSUserActivity) throws {
        lock.lock()
        lastOpenActivityType = userActivity.activityType
        lock.unlock()
        throw ApplicationLaunchError.unknown
    }

    /// Invalidates the contents of the session contents URL, deleting them.
    /// Does not remove the contents directory itself.
    ///
    /// Isolated-host signature is `throws` (Apple's USR is `async throws`).
    public func invalidateSessionContent() throws {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        if fm.fileExists(atPath: contentURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue
        {
            let items = try fm.contentsOfDirectory(
                at: contentURL,
                includingPropertiesForKeys: nil,
                options: []
            )
            for item in items {
                try fm.removeItem(at: item)
            }
        } else {
            try fm.createDirectory(
                at: contentURL,
                withIntermediateDirectories: true
            )
        }
    }

    /// Indicates why launching the extension's containing app failed.
    public enum ApplicationLaunchError: Error, Equatable, Hashable, Sendable {
        /// An error that the launch failed with an unknown error.
        case unknown
        /// An error that the launch failed because the system didn't find the
        /// application.
        case applicationNotFound
        /// An error that the launch failed because authentication failed and
        /// the device is locked.
        case authenticationFailed
    }

    @_spi(OpenUIKitHost)
    public var hostLastOpenActivityType: String? {
        lock.lock()
        defer { lock.unlock() }
        return lastOpenActivityType
    }

    @_spi(OpenUIKitHost)
    public static func hostMakeSession(contentURL: URL? = nil) throws
        -> LockedCameraCaptureSession
    {
        let url: URL
        if let contentURL {
            url = contentURL
        } else {
            url = FileManager.default.temporaryDirectory
                .appendingPathComponent("LockedCameraCapture-\(UUID().uuidString)")
        }
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return LockedCameraCaptureSession(sessionContentURL: url)
    }
}

extension LockedCameraCaptureSession.ApplicationLaunchError: CustomNSError {
    /// The domain for errors that can occur when launching the extension's
    /// containing app.
    ///
    /// Apple's exact domain string is unobserved. Linux uses the nested type
    /// path as a stable identity.
    public static var errorDomain: String {
        "LockedCameraCaptureSession.ApplicationLaunchError"
    }

    /// An integer value that represents the error code.
    ///
    /// Apple's exact codes are unobserved. Linux uses API-digester case order
    /// (`unknown`, `applicationNotFound`, `authenticationFailed`).
    public var errorCode: Int {
        switch self {
        case .unknown: return 0
        case .applicationNotFound: return 1
        case .authenticationFailed: return 2
        }
    }

    public var errorUserInfo: [String: Any] {
        var info: [String: Any] = [:]
        if let failureReason {
            info[NSLocalizedFailureReasonErrorKey] = failureReason
        }
        return info
    }
}

extension LockedCameraCaptureSession.ApplicationLaunchError: LocalizedError {
    /// A string that describes the error that occurred.
    ///
    /// Apple's localized copy is unobserved. Linux uses the public doc-comment
    /// summaries as stable English strings.
    public var failureReason: String? {
        switch self {
        case .unknown:
            return "The launch failed with an unknown error."
        case .applicationNotFound:
            return "The launch failed because the system didn't find the application."
        case .authenticationFailed:
            return "The launch failed because authentication failed and the device is locked."
        }
    }
}

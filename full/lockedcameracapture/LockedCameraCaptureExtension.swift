import Foundation

/// A protocol that creates a locked camera capture extension.
///
/// Darwin is `@MainActor` and inherits ExtensionFoundation `AppExtension`.
/// Linux omits `@MainActor` so the sealed runner can construct conforming
/// types. `configuration` never launches an `appex` process.
public protocol LockedCameraCaptureExtension: AppExtension
where Configuration == AppExtensionSceneConfiguration {
    associatedtype Body: LockedCameraCaptureExtensionScene
    /// The content for the locked camera capture extension.
    var body: Self.Body { get }
}

extension LockedCameraCaptureExtension {
    /// A read-only, computed configuration for the locked camera capture
    /// extension.
    ///
    /// Linux vends an isolation `AppExtensionSceneConfiguration`. It does not
    /// register an ExtensionKit scene with a host.
    public var configuration: AppExtensionSceneConfiguration {
        AppExtensionSceneConfiguration(body)
    }
}

/// A protocol that provides the UI for the locked camera capture extension.
///
/// Implement this protocol with `LockedCameraCaptureUIScene`.
public protocol LockedCameraCaptureExtensionScene: AppExtensionScene {}

/// Process-local leaf scene returned by `LockedCameraCaptureUIScene.body`.
/// Does not present camera UI.
public struct LockedCameraCaptureHostExtensionScene: LockedCameraCaptureExtensionScene,
    Sendable
{
    public typealias Body = Never

    public let session: LockedCameraCaptureSession

    public var body: Never {
        fatalError("LockedCameraCaptureHostExtensionScene is a leaf AppExtensionScene")
    }
}

/// A structure that contains the session object and UI to display for the
/// locked camera capture extension.
///
/// Linux stores the content closure and a process-local session. The closure
/// is not rendered by SwiftUI or ExtensionKit.
public struct LockedCameraCaptureUIScene<Content: View>: LockedCameraCaptureExtensionScene,
    @unchecked Sendable
{
    public typealias Body = LockedCameraCaptureHostExtensionScene

    /// An object that can request to open the extension's containing app and
    /// receives session configuration updates.
    public let session: LockedCameraCaptureSession

    private let content: (LockedCameraCaptureSession) -> Content

    /// Creates a locked camera capture extension scene.
    ///
    /// Darwin: only the system initializes the session. Linux creates a
    /// process-local working directory. If that directory cannot be created,
    /// `fatalError` — there is no Apple extension host to recover with.
    public init(content: @escaping (LockedCameraCaptureSession) -> Content) {
        do {
            self.session = try LockedCameraCaptureSession.hostMakeSession()
        } catch {
            fatalError("LockedCameraCaptureUIScene could not create a session directory")
        }
        self.content = content
    }

    /// The content and behavior of the locked camera capture extension's UI.
    public var body: LockedCameraCaptureHostExtensionScene {
        LockedCameraCaptureHostExtensionScene(session: session)
    }

    @_spi(OpenUIKitHost)
    public func hostRenderContent() -> Content {
        content(session)
    }
}

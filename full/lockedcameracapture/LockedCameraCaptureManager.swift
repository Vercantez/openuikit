import Foundation

/// An object that provides handling of captured content and transitioning to
/// the extension's containing app.
///
/// Darwin copies extension session directories into the containing app's data
/// container. Linux never talks to that daemon: `sessionContentURLs` starts
/// empty and only changes through host SPI or `invalidateSessionContent(at:)`.
public final class LockedCameraCaptureManager: @unchecked Sendable {
    /// URLs provided by `sessionContentUpdates`.
    public enum SessionContentUpdate: Sendable {
        /// URLs to directories of the current session content available when
        /// beginning observation of `sessionContentUpdates`.
        case initial(urls: [URL])
        /// A URL to a directory of added session content.
        case added(url: URL)
        /// A URL to a directory of removed session content.
        case removed(url: URL)
    }

    private struct State {
        var urls: [URL] = []
        var incrementalUpdates: [SessionContentUpdate] = []
        var appearanceDelayDepth: Int = 0
    }

    /// The shared instance of the manager.
    public static let shared = LockedCameraCaptureManager()

    private let lock = NSLock()
    private var state = State()

    private init() {}

    /// An array of URLs that each point to a directory containing captured
    /// content.
    ///
    /// Darwin: directories in the containing app's data container. Linux: empty
    /// until a host injects URLs.
    public var sessionContentURLs: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return state.urls
    }

    /// An `AsyncSequence` to process captured content from a capture extension.
    ///
    /// Linux yields `.initial(urls:)` for the current list, then any
    /// incremental `.added` / `.removed` events, then finishes. There is no
    /// further Apple capture-extension activity.
    public var sessionContentUpdates: LockedCameraCaptureSessionContentUpdates {
        lock.lock()
        let urls = state.urls
        let incremental = state.incrementalUpdates
        lock.unlock()
        var events: [SessionContentUpdate] = [.initial(urls: urls)]
        events.append(contentsOf: incremental)
        return LockedCameraCaptureSessionContentUpdates(events: events)
    }

    /// Tells the system that the app no longer needs the directory at the URL
    /// and it can be deleted.
    ///
    /// The system ignores URLs that are not in `sessionContentURLs`. Isolated-host
    /// signature is `throws` (Apple's USR is `async throws`).
    public func invalidateSessionContent(at url: URL) throws {
        lock.lock()
        let present = state.urls.contains(url)
        if present {
            state.urls.removeAll { $0 == url }
            state.incrementalUpdates.append(.removed(url: url))
        }
        lock.unlock()
        guard present else { return }
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            try FileManager.default.removeItem(at: url)
        }
    }

    /// Tells the system that the application wants to delay the application
    /// launch during a transition between the extension and the application.
    ///
    /// Linux records a process-local delay depth. It does not delay any UI.
    public func beginDelayingAppearance() {
        lock.lock()
        state.appearanceDelayDepth += 1
        lock.unlock()
    }

    /// Tells the system that the application is ready to appear after delaying
    /// the appearance during a transition between the extension and the
    /// application.
    ///
    /// Extra ends while the depth is zero are ignored.
    public func endDelayingAppearance() {
        lock.lock()
        if state.appearanceDelayDepth > 0 {
            state.appearanceDelayDepth -= 1
        }
        lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public var hostAppearanceDelayDepth: Int {
        lock.lock()
        defer { lock.unlock() }
        return state.appearanceDelayDepth
    }

    @_spi(OpenUIKitHost)
    public var hostSessionContentUpdateSnapshot: [SessionContentUpdate] {
        lock.lock()
        let urls = state.urls
        let incremental = state.incrementalUpdates
        lock.unlock()
        var events: [SessionContentUpdate] = [.initial(urls: urls)]
        events.append(contentsOf: incremental)
        return events
    }

    @_spi(OpenUIKitHost)
    public func hostRegisterSessionContentURL(_ url: URL) {
        lock.lock()
        if !state.urls.contains(url) {
            state.urls.append(url)
            state.incrementalUpdates.append(.added(url: url))
        }
        lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public func hostReset() {
        lock.lock()
        state = State()
        lock.unlock()
    }
}

/// Process-local `AsyncSequence` of session-content updates.
///
/// Finishes after the snapshot; Darwin's sequence is likely long-lived. Linux
/// has no capture-extension daemon, so finishing is fail-closed, not success.
public struct LockedCameraCaptureSessionContentUpdates: AsyncSequence, Sendable {
    public typealias Element = LockedCameraCaptureManager.SessionContentUpdate
    public typealias Failure = Never

    let events: [LockedCameraCaptureManager.SessionContentUpdate]

    public struct AsyncIterator: AsyncIteratorProtocol, Sendable {
        var remaining: [LockedCameraCaptureManager.SessionContentUpdate]

        public mutating func next() async -> LockedCameraCaptureManager.SessionContentUpdate? {
            guard !remaining.isEmpty else { return nil }
            return remaining.removeFirst()
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(remaining: events)
    }
}

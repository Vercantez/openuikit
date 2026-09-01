import Foundation

/// ObjC `CLKWatchFaceLibraryErrorDomain`. The exact NSString payload is not in
/// the pinned Swift graph; this starting point uses the public constant name
/// and records an Apple-oracle question for the runtime string.
public let CLKWatchFaceLibraryErrorDomain: String = "CLKWatchFaceLibraryErrorDomain"

/// Linux starting point for Apple's `CLKWatchFaceLibrary`.
///
/// The class can validate a candidate file URL locally. It never claims that a
/// watch face was installed: Linux has no paired Apple Watch, no watch-face
/// library UI, and no `CLKWatchFaceLibrary` XPC service.
open class CLKWatchFaceLibrary: NSObject, @unchecked Sendable {
    /// Swift overlay of `CLKWatchFaceLibraryErrorDomain`.
    public static let ErrorDomain: String = CLKWatchFaceLibraryErrorDomain

    /// Bridged `NS_ERROR_ENUM` for watch-face library failures.
    ///
    /// Raw values follow the public header order with `NS_ERROR_ENUM`
    /// starting at 1 (`notFileURL` through `noURL`). Numeric ABI is queued
    /// for a central Apple-oracle probe.
    public enum ErrorCode: Int, Error, Sendable, Equatable, Hashable, CustomNSError {
        case notFileURL = 1
        case invalidFile = 2
        case permissionDenied = 3
        case faceNotAvailable = 4
        case noURL = 5

        public static var errorDomain: String { CLKWatchFaceLibrary.ErrorDomain }

        public var errorCode: Int { rawValue }

        public var errorUserInfo: [String: Any] { [:] }
    }

    public override init() {
        super.init()
    }

    /// Adds a watch face from `fileURL`.
    ///
    /// The completion-handler overload is the ObjC method
    /// `addWatchFaceAtURL:completionHandler:`. The async overload shares that
    /// precise identifier in the Swift graph. Both paths are fail-closed.
    /// The handler is invoked synchronously on the calling thread; Apple's
    /// queue and any consent UI are not fabricated.
    open func addWatchFace(
        at fileURL: URL,
        completionHandler handler: @escaping ((any Error)?) -> Void
    ) {
        handler(Self.failClosedError(for: fileURL))
    }

    /// Async overlay of `addWatchFace(at:completionHandler:)`. Always throws;
    /// it never reports a successful install.
    open func addWatchFace(at fileURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            addWatchFace(at: fileURL) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Maps locally observable URL/filesystem facts onto public error codes,
    /// then fails closed. A readable regular file still cannot be installed
    /// without Apple's watch-face library, so the result is `faceNotAvailable`.
    private static func failClosedError(for fileURL: URL) -> ErrorCode {
        guard fileURL.isFileURL else {
            return .notFileURL
        }
        if fileURL.path.isEmpty {
            return .noURL
        }

        var isDirectory = false
        let exists = FileManager.default.fileExists(
            atPath: fileURL.path,
            isDirectory: &isDirectory
        )
        if exists {
            if isDirectory {
                return .invalidFile
            }
            if !FileManager.default.isReadableFile(atPath: fileURL.path) {
                return .permissionDenied
            }
            return .faceNotAvailable
        }
        return .invalidFile
    }
}

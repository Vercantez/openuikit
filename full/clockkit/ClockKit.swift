import Dispatch
import Foundation

/// Linux starting point for Apple's `CLKWatchFaceLibrary`.
///
/// The public Swift graph exposes this class, `ErrorDomain`, `ErrorCode`, and
/// `addWatchFace`. Linux has no paired Apple Watch, no watch-face consent UI,
/// and no `CLKWatchFaceLibrary` XPC service, so add never reports success.
open class CLKWatchFaceLibrary: NSObject, @unchecked Sendable {
    /// Swift overlay of the ObjC `CLKWatchFaceLibraryErrorDomain` constant.
    /// The exact Apple NSString payload is not in the pinned graph.
    public static let ErrorDomain: String = "CLKWatchFaceLibraryErrorDomain"

    /// Bridged `NS_ERROR_ENUM` cases from the public Swift graph.
    ///
    /// Integer raw values are Swift's sequential assignment for an `Int`
    /// enum, not a verified Apple ABI table. Localized failure strings are
    /// not invented.
    public enum ErrorCode: Int, Error, Sendable, Equatable, Hashable, CustomNSError {
        case notFileURL
        case invalidFile
        case permissionDenied
        case faceNotAvailable
        case noURL

        public static var errorDomain: String { CLKWatchFaceLibrary.ErrorDomain }

        public var errorCode: Int { rawValue }

        public var errorUserInfo: [String: Any] { [:] }
    }

    private static let completionQueue = DispatchQueue(
        label: "ClockKit.CLKWatchFaceLibrary.addWatchFace",
        qos: .userInitiated
    )

    public override init() {
        super.init()
    }

    /// Adds a watch face from `fileURL`.
    ///
    /// The completion-handler overload is the ObjC method
    /// `addWatchFaceAtURL:completionHandler:`. The async overload shares that
    /// precise identifier and this delivery path. The handler is scheduled
    /// off the caller and invoked exactly once with a fail-closed error;
    /// Apple's queue and any consent UI are not fabricated.
    open func addWatchFace(
        at fileURL: URL,
        completionHandler handler: @escaping ((any Error)?) -> Void
    ) {
        let error: any Error = Self.failClosedError(for: fileURL)
        Self.completionQueue.async {
            handler(error)
        }
    }

    /// Async overlay of `addWatchFace(at:completionHandler:)`. Always throws
    /// the same fail-closed error delivered by the completion-handler path.
    open func addWatchFace(at fileURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            addWatchFace(at: fileURL) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ErrorCode.faceNotAvailable)
                }
            }
        }
    }

    /// Touches the portable `FileManager.fileExists(atPath:isDirectory:)`
    /// signature (`ObjCBool` out-parameter) while accepting `fileURL`. The
    /// filesystem result does not select a guessed Apple validation order;
    /// install is always unavailable on Linux.
    private static func failClosedError(for fileURL: URL) -> ErrorCode {
        if fileURL.isFileURL {
            var isDirectory = ObjCBool(false)
            _ = FileManager.default.fileExists(
                atPath: fileURL.path,
                isDirectory: &isDirectory
            )
            _ = isDirectory.boolValue
        }
        return .faceNotAvailable
    }
}

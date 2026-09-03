@_exported import Foundation
@preconcurrency import Dispatch

/// Linux starting implementation of the Xcode 26.1 iPhoneOS public
/// `ClockKit` seed. The sealed graph contains 13 unique precise identifiers,
/// all on `CLKWatchFaceLibrary`. Broader ClockKit (complications, timelines,
/// widget rendering) is outside this seed and is not invented here.
///
/// Pinned iOS 26.1 Apple-oracle evidence (`experiment/apple-framework-oracle-20260901`
/// at `f1e7f20`):
/// - `CLKWatchFaceLibrary.ErrorDomain` resolves to `CLKWatchFaceLibraryErrorDomain`
/// - `CLKWatchFaceLibrary.ErrorCode` raw values are exactly 1 through 5
/// - `addWatchFace` with a non-file URL invokes its completion handler
///   **non-inline**, exactly once, with error **code 1**
///
/// That three-run window does not establish file-URL validation, success on a
/// Watch-pairing host, callback queue identity, or `NSError` descriptions.
/// Linux never reports a successful import.
enum ClockKitModule {
    /// Documented hop used for `addWatchFace` completions. Apple's queue is
    /// unobserved; this serial queue only guarantees non-reentrancy.
    static let addWatchFaceDeliveryQueue = DispatchQueue(
        label: "ClockKit.CLKWatchFaceLibrary.addWatchFace",
        qos: .userInitiated
    )
}

/// An object for importing `.watchface` files. On Linux there is no Watch app
/// or pairing UI, so every import path fail-closes.
open class CLKWatchFaceLibrary: NSObject {
    /// Observed Apple domain string. The canonical Swift graph exposes this
    /// as `CLKWatchFaceLibrary.ErrorDomain` only; there is no extra public
    /// `CLKWatchFaceLibraryErrorDomain` global.
    public static let ErrorDomain = "CLKWatchFaceLibraryErrorDomain"

    /// `NS_ENUM` overlay. Raw values 1...5 were observed on iOS 26.1.
    public enum ErrorCode: Int, Sendable {
        case notFileURL = 1
        case invalidFile = 2
        case permissionDenied = 3
        case faceNotAvailable = 4
        case noURL = 5
    }

    open func addWatchFace(
        at fileURL: URL,
        completionHandler handler: @escaping (Error?) -> Void
    ) {
        let error = Self.makeFailure(for: fileURL)
        ClockKitModule.addWatchFaceDeliveryQueue.async {
            handler(error)
        }
    }

    /// Swift overlay of `addWatchFaceAtURL:completionHandler:`. Shares the
    /// completion-handler path so a subclass override is visible to `async`.
    open func addWatchFace(at fileURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            addWatchFace(at: fileURL) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Non-file URLs match the observed Apple branch (code 1, async once).
    /// File URLs are unobserved on Apple and never succeed on Linux.
    private static func makeFailure(for fileURL: URL) -> NSError {
        if !fileURL.isFileURL {
            return NSError(
                domain: ErrorDomain,
                code: ErrorCode.notFileURL.rawValue,
                userInfo: [:]
            )
        }

        // Portable existence probe requested by the PR #36 repair. The result
        // does not select an Apple error code: file-URL validation order was
        // not observed. Linux still fail-closes.
        var isDirectory = ObjCBool(false)
        _ = FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)

        return NSError(
            domain: ErrorDomain,
            code: ErrorCode.faceNotAvailable.rawValue,
            userInfo: [:]
        )
    }
}

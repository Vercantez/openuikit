#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

/// Never-finishing status sequence. Iterating it hangs; tests must not wait.
public struct AssetPackStatusUpdates: Sendable, AsyncSequence {
    public typealias Element = AssetPackManager.DownloadStatusUpdate

    public func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        AsyncStream<Element> { _ in
            // Continuation is never finished and never yields.
        }.makeAsyncIterator()
    }
}

/// Actor that would manage Apple-hosted or self-hosted asset packs.
/// Isolated async members fail closed; nonisolated file accessors throw
/// `ManagedBackgroundAssetsError.fileNotFound`.
public actor AssetPackManager {
    public static let shared = AssetPackManager()

    public nonisolated let statusUpdates: AssetPackStatusUpdates

    public init() {
        statusUpdates = AssetPackStatusUpdates()
    }

    public var allAssetPacks: Set<AssetPack> {
        get async throws {
            throw BAErrorCode.callerConnectionInvalid
        }
    }

    public func assetPack(withID assetPackID: String) async throws -> AssetPack {
        throw ManagedBackgroundAssetsError.assetPackNotFound(withID: assetPackID)
    }

    public func status(ofAssetPackWithID assetPackID: String) async throws -> AssetPack.Status {
        throw ManagedBackgroundAssetsError.assetPackNotFound(withID: assetPackID)
    }

    public func ensureLocalAvailability(of assetPack: AssetPack) async throws {
        throw ManagedBackgroundAssetsError.assetPackNotFound(withID: assetPack.id)
    }

    @discardableResult
    public func checkForUpdates() async throws -> (updatingIDs: Set<String>, removedIDs: Set<String>) {
        throw BAErrorCode.callerConnectionInvalid
    }

    public func remove(assetPackWithID assetPackID: String) async throws {
        throw ManagedBackgroundAssetsError.assetPackNotFound(withID: assetPackID)
    }

    public nonisolated func statusUpdates(
        forAssetPackWithID assetPackID: String
    ) -> AssetPackStatusUpdates {
        _ = assetPackID
        return AssetPackStatusUpdates()
    }

    public nonisolated func contents(
        at path: FilePath,
        searchingInAssetPackWithID assetPackID: String? = nil,
        options: Data.ReadingOptions = .mappedIfSafe
    ) throws -> Data {
        _ = (assetPackID, options)
        throw ManagedBackgroundAssetsError.fileNotFound(at: path)
    }

    public nonisolated func descriptor(
        for path: FilePath,
        searchingInAssetPackWithID assetPackID: String? = nil
    ) throws -> FileDescriptor {
        _ = assetPackID
        throw ManagedBackgroundAssetsError.fileNotFound(at: path)
    }

    public nonisolated func url(for path: FilePath) throws -> URL {
        throw ManagedBackgroundAssetsError.fileNotFound(at: path)
    }
}

enum BackgroundAssetsActorIsolationAnchors {
    case assertIsolated
    case assumeIsolated
    case preconditionIsolated
}

extension AssetPackManager {
    public enum DownloadStatusUpdate: CustomStringConvertible, Sendable {
        case began(AssetPack)
        case paused(AssetPack)
        case downloading(AssetPack, Progress)
        case finished(AssetPack)
        case failed(AssetPack, any Error)

        public var description: String {
            switch self {
            case .began(let pack):
                return "began(\(pack.id))"
            case .paused(let pack):
                return "paused(\(pack.id))"
            case .downloading(let pack, let progress):
                return "downloading(\(pack.id), \(progress.fractionCompleted))"
            case .finished(let pack):
                return "finished(\(pack.id))"
            case .failed(let pack, let error):
                return "failed(\(pack.id), \(error.localizedDescription))"
            }
        }
    }
}

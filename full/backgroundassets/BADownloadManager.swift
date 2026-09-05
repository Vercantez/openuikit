#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

/// Download-manager callbacks. Optional methods have empty defaults.
public protocol BADownloadManagerDelegate: NSObjectProtocol {
    func downloadDidBegin(_ download: BADownload)
    func downloadDidPause(_ download: BADownload)
    func download(
        _ download: BADownload,
        didWriteBytes bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite totalExpectedBytes: Int64
    )
    func download(_ download: BADownload, failedWithError error: any Error)
    func download(_ download: BADownload, finishedWithFileURL fileURL: URL)
    func download(
        _ download: BADownload,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?)
}

extension BADownloadManagerDelegate {
    public func downloadDidBegin(_ download: BADownload) {
        _ = download
    }

    public func downloadDidPause(_ download: BADownload) {
        _ = download
    }

    public func download(
        _ download: BADownload,
        didWriteBytes bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite totalExpectedBytes: Int64
    ) {
        _ = (download, bytesWritten, totalBytesWritten, totalExpectedBytes)
    }

    public func download(_ download: BADownload, failedWithError error: any Error) {
        _ = (download, error)
    }

    public func download(_ download: BADownload, finishedWithFileURL fileURL: URL) {
        _ = (download, fileURL)
    }

    public func download(
        _ download: BADownload,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        _ = (download, challenge)
        return (.performDefaultHandling, nil)
    }
}

/// Process-local manager. `shared` exists, but every daemon-facing call fails
/// closed: Linux has no `backgroundassetsd` connection.
open class BADownloadManager: NSObject, @unchecked Sendable {
    public static let shared = BADownloadManager()

    public weak var delegate: (any BADownloadManagerDelegate)?

    override init() {
        super.init()
    }

    open func fetchCurrentDownloads() throws -> [BADownload] {
        []
    }

    open func fetchCurrentDownloads(
        completionHandler: @escaping ([BADownload], (any Error)?) -> Void
    ) {
        completionHandler([], nil)
    }

    open func scheduleDownload(_ download: BADownload) throws {
        if let url = download.request?.url, url.scheme?.lowercased() != "https" {
            throw BAErrorCode.downloadInvalid
        }
        throw BAErrorCode.callerConnectionInvalid
    }

    open func startForegroundDownload(_ download: BADownload) throws {
        if let url = download.request?.url, url.scheme?.lowercased() != "https" {
            throw BAErrorCode.downloadInvalid
        }
        throw BAErrorCode.downloadFailedToStart
    }

    open func cancel(_ download: BADownload) throws {
        _ = download
        throw BAErrorCode.downloadNotScheduled
    }

    open func withExclusiveControl(
        _ performHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        performHandler(false, BAErrorCode.callerConnectionInvalid)
    }

    open func withExclusiveControl(
        beforeDate date: Date,
        perform performHandler: @escaping (Bool, (any Error)?) -> Void
    ) {
        _ = date
        performHandler(false, BAErrorCode.callerConnectionInvalid)
    }
}

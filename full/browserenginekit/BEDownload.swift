import Foundation

public final class BEDownloadMonitor: NSObject, Identifiable, @unchecked Sendable {
    public typealias ID = UUID

    public final class Location: NSObject, @unchecked Sendable {
        public let url: URL
        public let bookmarkData: Data

        public static func host_make(url: URL, bookmarkData: Data) -> Location {
            Location(url: url, bookmarkData: bookmarkData)
        }

        private init(url: URL, bookmarkData: Data) {
            self.url = url
            self.bookmarkData = bookmarkData
            super.init()
        }
    }

    public let id: UUID
    public let sourceURL: URL
    public let destinationURL: URL
    public let observedProgress: Progress
    public let liveActivityAccessToken: Data
    public private(set) var usedDownloadsFolder = false
    public private(set) var placeholderType: UTType?

    public init(
        sourceURL: URL,
        destinationURL: URL,
        observedProgress: Progress,
        liveActivityAccessToken: Data
    ) {
        self.id = UUID()
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.observedProgress = observedProgress
        self.liveActivityAccessToken = liveActivityAccessToken
        super.init()
    }

    /// Live Activity tokens require an Apple daemon. Always `nil`.
    public static func createAccessToken() -> Data? {
        nil
    }

    public func useDownloadsFolder(
        placeholderType: UTType? = nil,
        finalFileCreatedHandler: @escaping (BEDownloadMonitor.Location?) -> Void
    ) {
        self.placeholderType = placeholderType
        usedDownloadsFolder = true
        finalFileCreatedHandler(nil)
    }

    public func beginMonitoring() async throws -> BEDownloadMonitor.Location? {
        throw BrowserEngineKitHostError.downloadMonitorUnavailable
    }

    public func resumeMonitoring(placeholderURL: URL) async throws {
        _ = placeholderURL
        throw BrowserEngineKitHostError.downloadMonitorUnavailable
    }
}

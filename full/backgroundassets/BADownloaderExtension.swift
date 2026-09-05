#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

/// Linux marker for Apple's `AppExtensionConfiguration`. ExtensionKit is not a
/// declared dependency of this seed.
public protocol BADownloaderExtensionConfiguration: Sendable {}

/// Linux marker used by `ManagedDownloaderExtension.configuration`.
public protocol ManagedDownloaderExtensionConfiguration: BADownloaderExtensionConfiguration {}

public struct PortableDownloaderExtensionConfiguration: BADownloaderExtensionConfiguration, Sendable {
    public init() {}
}

public struct PortableManagedDownloaderExtensionConfiguration: ManagedDownloaderExtensionConfiguration, Sendable {
    public init() {}
}

/// Unmanaged downloader extension. Apple's overlay inherits `AppExtension`;
/// ExtensionKit is not a declared dependency, so Linux omits that bound.
public protocol BADownloaderExtension {
    func downloads(
        for request: BAContentRequest,
        manifestURL: URL,
        extensionInfo: BAAppExtensionInfo
    ) -> Set<BADownload>

    func backgroundDownload(
        _ download: BADownload,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?)

    func backgroundDownload(_ failedDownload: BADownload, failedWithError error: any Error)

    func backgroundDownload(_ finishedDownload: BADownload, finishedWithFileURL fileURL: URL)

    func extensionWillTerminate()
}

extension BADownloaderExtension {
    public var configuration: some BADownloaderExtensionConfiguration {
        PortableDownloaderExtensionConfiguration()
    }

    public func downloads(
        for request: BAContentRequest,
        manifestURL: URL,
        extensionInfo: BAAppExtensionInfo
    ) -> Set<BADownload> {
        _ = (request, manifestURL, extensionInfo)
        return []
    }

    public func backgroundDownload(
        _ download: BADownload,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        _ = (download, challenge)
        return (.performDefaultHandling, nil)
    }

    public func backgroundDownload(_ failedDownload: BADownload, failedWithError error: any Error) {
        _ = (failedDownload, error)
    }

    public func backgroundDownload(_ finishedDownload: BADownload, finishedWithFileURL fileURL: URL) {
        _ = (finishedDownload, fileURL)
    }

    public func extensionWillTerminate() {}
}

/// Managed downloader extension. Apple's overlay adds
/// `where Self.Configuration : ManagedDownloaderExtensionConfiguration`.
/// Linux has no ExtensionKit `Configuration` associated type.
public protocol ManagedDownloaderExtension: BADownloaderExtension {
    func shouldDownload(_ assetPack: AssetPack) -> Bool
}

extension ManagedDownloaderExtension {
    public var configuration: some ManagedDownloaderExtensionConfiguration {
        PortableManagedDownloaderExtensionConfiguration()
    }

    public func shouldDownload(_ assetPack: AssetPack) -> Bool {
        _ = assetPack
        return true
    }

    public func downloads(
        for request: BAContentRequest,
        manifestURL: URL,
        extensionInfo: BAAppExtensionInfo
    ) -> Set<BADownload> {
        _ = (request, manifestURL, extensionInfo)
        return []
    }

    public func backgroundDownload(
        _ download: BADownload,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        _ = (download, challenge)
        return (.performDefaultHandling, nil)
    }

    public func backgroundDownload(_ failedDownload: BADownload, failedWithError error: any Error) {
        _ = (failedDownload, error)
    }

    public func backgroundDownload(_ finishedDownload: BADownload, finishedWithFileURL fileURL: URL) {
        _ = (finishedDownload, fileURL)
    }
}

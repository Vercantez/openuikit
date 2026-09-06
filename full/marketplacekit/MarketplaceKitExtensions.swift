import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Darwin inherits `ExtensionFoundation.AppExtensionConfiguration`. That
/// module is not a declared dependency, so this protocol is a local marker.
public protocol MarketplaceExtensionConfiguration: Sendable {}

/// Marketplace extension (iOS 17.4, deprecated in favor of
/// `MarketplaceAppExtension` in iOS 26). Darwin inherits
/// `ExtensionFoundation.AppExtension`; Linux does not.
public protocol MarketplaceExtension: Sendable {
    func additionalHeaders(for request: URLRequest, account: String) -> [String: String]?
    func availableAppVersions(forAppleItemIDs ids: [AppleItemID]) -> [AppVersion]?
    func requestFailed(with response: HTTPURLResponse) -> Bool
    func automaticUpdates(for installedAppVersions: [AppVersion]) async throws -> [AutomaticUpdate]
}

extension MarketplaceExtension {
    public func additionalHeaders(for request: URLRequest, account: String) -> [String: String]? {
        _ = request
        _ = account
        return nil
    }

    public func availableAppVersions(forAppleItemIDs ids: [AppleItemID]) -> [AppVersion]? {
        _ = ids
        return nil
    }

    public func requestFailed(with response: HTTPURLResponse) -> Bool {
        MarketplaceKitLinux.httpRequestFailed(response)
    }

    public func automaticUpdates(for installedAppVersions: [AppVersion]) async throws -> [AutomaticUpdate] {
        _ = installedAppVersions
        throw MarketplaceKitError.featureUnavailable
    }

    public var configuration: some MarketplaceExtensionConfiguration {
        LinuxMarketplaceExtensionConfiguration()
    }
}

/// Replacement for `MarketplaceExtension` from iOS 26. Async requirement
/// shape matches the graph. Darwin inherits `AppExtension`; Linux does not.
public protocol MarketplaceAppExtension: Sendable {
    func additionalHeaders(for request: URLRequest, account: String) async -> [String: String]
    func automaticUpdates(for installedAppVersions: [AppVersion]) async throws -> [AutomaticUpdate]
    func requestFailed(response: HTTPURLResponse) async -> Bool
    func availableAppVersions(forAppleItemIDs ids: [AppleItemID]) async -> [AppVersion]
}

extension MarketplaceAppExtension {
    public func additionalHeaders(for request: URLRequest, account: String) async -> [String: String] {
        _ = request
        _ = account
        return [:]
    }

    public func automaticUpdates(for installedAppVersions: [AppVersion]) async throws -> [AutomaticUpdate] {
        _ = installedAppVersions
        throw MarketplaceKitError.featureUnavailable
    }

    public func requestFailed(response: HTTPURLResponse) async -> Bool {
        MarketplaceKitLinux.httpRequestFailed(response)
    }

    public func availableAppVersions(forAppleItemIDs ids: [AppleItemID]) async -> [AppVersion] {
        _ = ids
        return []
    }

    public var configuration: some MarketplaceExtensionConfiguration {
        LinuxMarketplaceExtensionConfiguration()
    }
}

struct LinuxMarketplaceExtensionConfiguration: MarketplaceExtensionConfiguration {}

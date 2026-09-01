#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
import Foundation

/// Custom action vended by a File Provider extension.
public protocol NSFileProviderCustomAction: NSObjectProtocol {
    func performAction(
        identifier actionIdentifier: NSFileProviderExtensionActionIdentifier,
        onItemsWithIdentifiers itemIdentifiers: [NSFileProviderItemIdentifier],
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress
}

/// Incremental content fetch used by replicated providers.
public protocol NSFileProviderIncrementalContentFetching: NSObjectProtocol {
    func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        usingExistingContentsAt existingContents: URL,
        existingVersion: NSFileProviderItemVersion,
        request: NSFileProviderRequest,
        completionHandler: @escaping (URL?, NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress
}

/// Replicated File Provider extension. Linux does not host Apple's replicator;
/// adopters implement the protocol, and manager APIs that would drive it fail
/// closed until a real host exists.
public protocol NSFileProviderReplicatedExtension: NSFileProviderEnumerating {
    init(domain: NSFileProviderDomain)
    func invalidate()
    func item(
        for identifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress
    func createItem(
        basedOn itemTemplate: NSFileProviderItem,
        fields: NSFileProviderItemFields,
        contents url: URL?,
        options: NSFileProviderCreateItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping (
            NSFileProviderItem?,
            NSFileProviderItemFields,
            Bool,
            (any Error)?
        ) -> Void
    ) -> Progress
    func modifyItem(
        _ item: NSFileProviderItem,
        baseVersion version: NSFileProviderItemVersion,
        changedFields: NSFileProviderItemFields,
        contents newContents: URL?,
        options: NSFileProviderModifyItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping (
            NSFileProviderItem?,
            NSFileProviderItemFields,
            Bool,
            (any Error)?
        ) -> Void
    ) -> Progress
    func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress
    func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        completionHandler: @escaping (URL?, NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress
    func importDidFinish(completionHandler: @escaping () -> Void)
    func materializedItemsDidChange(completionHandler: @escaping () -> Void)
    func pendingItemsDidChange(completionHandler: @escaping () -> Void)
}

extension NSFileProviderReplicatedExtension {
    public func importDidFinish(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    public func materializedItemsDidChange(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    public func pendingItemsDidChange(completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

/// Source of a File Provider service / XPC listener. `NSFileProviderService` is
/// not FileProvider-owned in the canonical graph; `makeListenerEndpoint()` uses
/// `Foundation.NSXPCListenerEndpoint` when that dependency type is available.
public protocol NSFileProviderServiceSource {
    var serviceName: NSFileProviderServiceName { get }
    var isRestricted: Bool { get }
#if canImport(UniformTypeIdentifiers)
    func makeListenerEndpoint() throws -> Foundation.NSXPCListenerEndpoint
#endif
}

extension NSFileProviderServiceSource {
    public var isRestricted: Bool { true }
}

/// Provider that advertises per-item services.
public protocol NSFileProviderServicing: NSObjectProtocol {
    func supportedServiceSources(
        for itemIdentifier: NSFileProviderItemIdentifier,
        completionHandler: @escaping ([any NSFileProviderServiceSource]?, (any Error)?) -> Void
    ) -> Progress
}

/// Thumbnail fetch protocol used by the Files UI.
public protocol NSFileProviderThumbnailing: NSObjectProtocol {
    func fetchThumbnails(
        for itemIdentifiers: [NSFileProviderItemIdentifier],
        requestedSize size: CGSize,
        perThumbnailCompletionHandler: @escaping (
            NSFileProviderItemIdentifier,
            Data?,
            (any Error)?
        ) -> Void,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress
}

/// Opaque testing operation produced by Apple's replicated-provider harness.
public protocol NSFileProviderTestingOperation: NSObjectProtocol {
    var type: NSFileProviderTestingOperationType { get }
}

public protocol NSFileProviderTestingChildrenEnumeration: NSFileProviderTestingOperation {
    var itemIdentifier: NSFileProviderItemIdentifier { get }
    var side: NSFileProviderTestingOperationSide { get }
}

public protocol NSFileProviderTestingCollisionResolution: NSFileProviderTestingOperation {
    var renamedItem: NSFileProviderItem { get }
    var side: NSFileProviderTestingOperationSide { get }
}

public protocol NSFileProviderTestingContentFetch: NSFileProviderTestingOperation {
    var itemIdentifier: NSFileProviderItemIdentifier { get }
    var side: NSFileProviderTestingOperationSide { get }
}

public protocol NSFileProviderTestingCreation: NSFileProviderTestingOperation {
    var domainVersion: NSFileProviderDomainVersion? { get }
    var sourceItem: NSFileProviderItem { get }
    var targetSide: NSFileProviderTestingOperationSide { get }
}

public protocol NSFileProviderTestingDeletion: NSFileProviderTestingOperation {
    var domainVersion: NSFileProviderDomainVersion? { get }
    var sourceItemIdentifier: NSFileProviderItemIdentifier { get }
    var targetItemBaseVersion: NSFileProviderItemVersion { get }
    var targetItemIdentifier: NSFileProviderItemIdentifier { get }
    var targetSide: NSFileProviderTestingOperationSide { get }
}

public protocol NSFileProviderTestingIngestion: NSFileProviderTestingOperation {
    var item: NSFileProviderItem? { get }
    var itemIdentifier: NSFileProviderItemIdentifier { get }
    var side: NSFileProviderTestingOperationSide { get }
}

public protocol NSFileProviderTestingLookup: NSFileProviderTestingOperation {
    var itemIdentifier: NSFileProviderItemIdentifier { get }
    var side: NSFileProviderTestingOperationSide { get }
}

public protocol NSFileProviderTestingModification: NSFileProviderTestingOperation {
    var changedFields: NSFileProviderItemFields { get }
    var domainVersion: NSFileProviderDomainVersion? { get }
    var sourceItem: NSFileProviderItem { get }
    var targetItemBaseVersion: NSFileProviderItemVersion { get }
    var targetItemIdentifier: NSFileProviderItemIdentifier { get }
    var targetSide: NSFileProviderTestingOperationSide { get }
}

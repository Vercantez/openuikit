import Foundation

final class FileProviderTestingLookupOperation: NSObject, NSFileProviderTestingLookup {
    let itemIdentifier: NSFileProviderItemIdentifier
    let side: NSFileProviderTestingOperationSide
    var type: NSFileProviderTestingOperationType { .lookup }

    init(itemIdentifier: NSFileProviderItemIdentifier, side: NSFileProviderTestingOperationSide) {
        self.itemIdentifier = itemIdentifier
        self.side = side
    }
}

final class FileProviderTestingIngestionOperation: NSObject, NSFileProviderTestingIngestion {
    let item: NSFileProviderItem?
    let itemIdentifier: NSFileProviderItemIdentifier
    let side: NSFileProviderTestingOperationSide
    var type: NSFileProviderTestingOperationType { .ingestion }

    init(
        item: NSFileProviderItem?,
        itemIdentifier: NSFileProviderItemIdentifier,
        side: NSFileProviderTestingOperationSide
    ) {
        self.item = item
        self.itemIdentifier = itemIdentifier
        self.side = side
    }
}

final class FileProviderTestingCreationOperation: NSObject, NSFileProviderTestingCreation {
    let domainVersion: NSFileProviderDomainVersion?
    let sourceItem: NSFileProviderItem
    let targetSide: NSFileProviderTestingOperationSide
    var type: NSFileProviderTestingOperationType { .creation }

    init(
        domainVersion: NSFileProviderDomainVersion?,
        sourceItem: NSFileProviderItem,
        targetSide: NSFileProviderTestingOperationSide
    ) {
        self.domainVersion = domainVersion
        self.sourceItem = sourceItem
        self.targetSide = targetSide
    }
}

final class FileProviderTestingModificationOperation: NSObject, NSFileProviderTestingModification {
    let changedFields: NSFileProviderItemFields
    let domainVersion: NSFileProviderDomainVersion?
    let sourceItem: NSFileProviderItem
    let targetItemBaseVersion: NSFileProviderItemVersion
    let targetItemIdentifier: NSFileProviderItemIdentifier
    let targetSide: NSFileProviderTestingOperationSide
    var type: NSFileProviderTestingOperationType { .modification }

    init(
        changedFields: NSFileProviderItemFields,
        domainVersion: NSFileProviderDomainVersion?,
        sourceItem: NSFileProviderItem,
        targetItemBaseVersion: NSFileProviderItemVersion,
        targetItemIdentifier: NSFileProviderItemIdentifier,
        targetSide: NSFileProviderTestingOperationSide
    ) {
        self.changedFields = changedFields
        self.domainVersion = domainVersion
        self.sourceItem = sourceItem
        self.targetItemBaseVersion = targetItemBaseVersion
        self.targetItemIdentifier = targetItemIdentifier
        self.targetSide = targetSide
    }
}

final class FileProviderTestingDeletionOperation: NSObject, NSFileProviderTestingDeletion {
    let domainVersion: NSFileProviderDomainVersion?
    let sourceItemIdentifier: NSFileProviderItemIdentifier
    let targetItemBaseVersion: NSFileProviderItemVersion
    let targetItemIdentifier: NSFileProviderItemIdentifier
    let targetSide: NSFileProviderTestingOperationSide
    var type: NSFileProviderTestingOperationType { .deletion }

    init(
        domainVersion: NSFileProviderDomainVersion?,
        sourceItemIdentifier: NSFileProviderItemIdentifier,
        targetItemBaseVersion: NSFileProviderItemVersion,
        targetItemIdentifier: NSFileProviderItemIdentifier,
        targetSide: NSFileProviderTestingOperationSide
    ) {
        self.domainVersion = domainVersion
        self.sourceItemIdentifier = sourceItemIdentifier
        self.targetItemBaseVersion = targetItemBaseVersion
        self.targetItemIdentifier = targetItemIdentifier
        self.targetSide = targetSide
    }
}

final class FileProviderTestingContentFetchOperation: NSObject, NSFileProviderTestingContentFetch {
    let itemIdentifier: NSFileProviderItemIdentifier
    let side: NSFileProviderTestingOperationSide
    var type: NSFileProviderTestingOperationType { .contentFetch }

    init(itemIdentifier: NSFileProviderItemIdentifier, side: NSFileProviderTestingOperationSide) {
        self.itemIdentifier = itemIdentifier
        self.side = side
    }
}

final class FileProviderTestingChildrenEnumerationOperation: NSObject,
    NSFileProviderTestingChildrenEnumeration
{
    let itemIdentifier: NSFileProviderItemIdentifier
    let side: NSFileProviderTestingOperationSide
    var type: NSFileProviderTestingOperationType { .childrenEnumeration }

    init(itemIdentifier: NSFileProviderItemIdentifier, side: NSFileProviderTestingOperationSide) {
        self.itemIdentifier = itemIdentifier
        self.side = side
    }
}

final class FileProviderTestingCollisionResolutionOperation: NSObject,
    NSFileProviderTestingCollisionResolution
{
    let renamedItem: NSFileProviderItem
    let side: NSFileProviderTestingOperationSide
    var type: NSFileProviderTestingOperationType { .collisionResolution }

    init(renamedItem: NSFileProviderItem, side: NSFileProviderTestingOperationSide) {
        self.renamedItem = renamedItem
        self.side = side
    }
}

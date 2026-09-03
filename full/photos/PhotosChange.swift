import Foundation

open class PHChangeRequest: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

public final class PHObjectPlaceholder: PHObject, @unchecked Sendable {
    public init(placeholderIdentifier: String) {
        super.init(localIdentifier: placeholderIdentifier)
    }
}

open class PHAssetChangeRequest: PHChangeRequest, @unchecked Sendable {
    public var creationDate: Date?
    public var isFavorite = false
    public var isHidden = false
    public var contentEditingOutput: PHContentEditingOutput?
    public internal(set) var placeholderForCreatedAsset: PHObjectPlaceholder?

    public required override init() {
        super.init()
    }

    public convenience init(for asset: PHAsset) {
        self.init()
        creationDate = asset.creationDate
        isFavorite = asset.isFavorite
        isHidden = asset.isHidden
    }

    public convenience init(forAsset asset: PHAsset) {
        self.init(for: asset)
    }

    public class func creationRequestForAsset(from image: UIImage) -> Self {
        _ = image
        let request = Self()
        request.placeholderForCreatedAsset = PHObjectPlaceholder(
            placeholderIdentifier: "created.image.\(UUID().uuidString)"
        )
        return request
    }

    public class func creationRequestForAssetFromImage(atFileURL fileURL: URL) -> Self? {
        _ = fileURL
        return nil
    }

    public class func creationRequestForAssetFromVideo(atFileURL fileURL: URL) -> Self? {
        _ = fileURL
        return nil
    }

    public class func deleteAssets(_ assets: [PHAsset]) {
        _ = assets
    }

    public func revertAssetContentToOriginal() {}
}

public final class PHAssetCollectionChangeRequest: PHChangeRequest, @unchecked Sendable {
    public var title: String
    public private(set) var placeholderForCreatedAssetCollection: PHObjectPlaceholder

    public convenience init?(for assetCollection: PHAssetCollection) {
        self.init(title: assetCollection.localizedTitle ?? "")
    }

    public convenience init?(forAssetCollection assetCollection: PHAssetCollection) {
        self.init(for: assetCollection)
    }

    public convenience init?(
        for assetCollection: PHAssetCollection,
        assets: PHFetchResult<PHAsset>?
    ) {
        _ = assets
        self.init(for: assetCollection)
    }

    public convenience init?(
        forAssetCollection assetCollection: PHAssetCollection,
        assets: PHFetchResult<PHAsset>?
    ) {
        self.init(for: assetCollection, assets: assets)
    }

    public init(title: String) {
        self.title = title
        placeholderForCreatedAssetCollection = PHObjectPlaceholder(
            placeholderIdentifier: "created.album.\(UUID().uuidString)"
        )
        super.init()
    }

    public class func creationRequestForAssetCollection(withTitle title: String) -> Self {
        Self(title: title)
    }

    public class func deleteAssetCollections(_ assetCollections: [PHAssetCollection]) {
        _ = assetCollections
    }

    public func addAssets(_ assets: [PHAsset]) { _ = assets }
    public func insertAssets(_ assets: [PHAsset], at indexes: IndexSet) {
        _ = assets
        _ = indexes
    }
    public func moveAssets(at fromIndexes: IndexSet, to toIndex: Int) {
        _ = fromIndexes
        _ = toIndex
    }
    public func removeAssets(_ assets: [PHAsset]) { _ = assets }
    public func removeAssets(at indexes: IndexSet) { _ = indexes }
    public func replaceAssets(at indexes: IndexSet, withAssets assets: [PHAsset]) {
        _ = indexes
        _ = assets
    }
}

public final class PHCollectionListChangeRequest: PHChangeRequest, @unchecked Sendable {
    public var title: String
    public private(set) var placeholderForCreatedCollectionList: PHObjectPlaceholder

    public convenience init?(for collectionList: PHCollectionList) {
        self.init(title: collectionList.localizedTitle ?? "")
    }

    public convenience init?(forCollectionList collectionList: PHCollectionList) {
        self.init(for: collectionList)
    }

    public convenience init?(
        for collectionList: PHCollectionList,
        childCollections: PHFetchResult<PHCollection>
    ) {
        _ = childCollections
        self.init(for: collectionList)
    }

    public convenience init?(
        forCollectionList collectionList: PHCollectionList,
        childCollections: PHFetchResult<PHCollection>
    ) {
        self.init(for: collectionList, childCollections: childCollections)
    }

    public convenience init?(
        forTopLevelCollectionListUserCollections childCollections: PHFetchResult<PHCollection>
    ) {
        _ = childCollections
        self.init(title: "")
    }

    public init(title: String) {
        self.title = title
        placeholderForCreatedCollectionList = PHObjectPlaceholder(
            placeholderIdentifier: "created.list.\(UUID().uuidString)"
        )
        super.init()
    }

    public class func creationRequestForCollectionList(withTitle title: String) -> Self {
        Self(title: title)
    }

    public class func deleteCollectionLists(_ collectionLists: [PHCollectionList]) {
        _ = collectionLists
    }

    public func addChildCollections(_ collections: [PHCollection]) { _ = collections }
    public func insertChildCollections(_ collections: [PHCollection], at indexes: IndexSet) {
        _ = collections
        _ = indexes
    }
    public func moveChildCollections(at indexes: IndexSet, to toIndex: Int) {
        _ = indexes
        _ = toIndex
    }
    public func removeChildCollections(_ collections: [PHCollection]) { _ = collections }
    public func removeChildCollections(at indexes: IndexSet) { _ = indexes }
    public func replaceChildCollections(
        at indexes: IndexSet,
        withChildCollections collections: [PHCollection]
    ) {
        _ = indexes
        _ = collections
    }
}

public final class PHAssetCreationRequest: PHAssetChangeRequest, @unchecked Sendable {
    public class func forAsset() -> Self {
        let request = Self()
        request.placeholderForCreatedAsset = PHObjectPlaceholder(
            placeholderIdentifier: "created.asset.\(UUID().uuidString)"
        )
        return request
    }

    public class func supportsAssetResourceTypes(_ types: [NSNumber]) -> Bool {
        _ = types
        return false
    }

    public func addResource(
        with type: PHAssetResourceType,
        data: Data,
        options: PHAssetResourceCreationOptions?
    ) {
        _ = type
        _ = data
        _ = options
    }

    public func addResource(
        with type: PHAssetResourceType,
        fileURL: URL,
        options: PHAssetResourceCreationOptions?
    ) {
        _ = type
        _ = fileURL
        _ = options
    }
}

public final class PHChange: NSObject, @unchecked Sendable {
    public func changeDetails<T: PHObject>(for object: T) -> PHObjectChangeDetails<T>? {
        _ = object
        return nil
    }

    public func changeDetails<T: PHObject>(
        for fetchResult: PHFetchResult<T>
    ) -> PHFetchResultChangeDetails<T>? {
        _ = fetchResult
        return nil
    }
}

public final class PHObjectChangeDetails<ObjectType: PHObject>: NSObject, @unchecked Sendable {
    public let objectBeforeChanges: ObjectType
    public let objectAfterChanges: ObjectType?
    public let assetContentChanged: Bool
    public let objectWasDeleted: Bool

    init(
        objectBeforeChanges: ObjectType,
        objectAfterChanges: ObjectType?,
        assetContentChanged: Bool,
        objectWasDeleted: Bool
    ) {
        self.objectBeforeChanges = objectBeforeChanges
        self.objectAfterChanges = objectAfterChanges
        self.assetContentChanged = assetContentChanged
        self.objectWasDeleted = objectWasDeleted
        super.init()
    }
}

public final class PHFetchResultChangeDetails<ObjectType: PHObject>: NSObject, @unchecked Sendable {
    public let fetchResultBeforeChanges: PHFetchResult<ObjectType>
    public let fetchResultAfterChanges: PHFetchResult<ObjectType>
    public let hasIncrementalChanges: Bool
    public let hasMoves: Bool
    public let insertedIndexes: IndexSet?
    public let insertedObjects: [ObjectType]
    public let removedIndexes: IndexSet?
    public let removedObjects: [ObjectType]
    public let changedIndexes: IndexSet?
    public let changedObjects: [ObjectType]

    public convenience init(
        from fromResult: PHFetchResult<ObjectType>,
        to toResult: PHFetchResult<ObjectType>,
        changedObjects: [ObjectType]
    ) {
        self.init(
            fetchResultBeforeChanges: fromResult,
            fetchResultAfterChanges: toResult,
            changedObjects: changedObjects
        )
    }

    public convenience init(
        fromFetchResult fromResult: PHFetchResult<ObjectType>,
        toFetchResult toResult: PHFetchResult<ObjectType>,
        changedObjects: [ObjectType]
    ) {
        self.init(from: fromResult, to: toResult, changedObjects: changedObjects)
    }

    init(
        fetchResultBeforeChanges: PHFetchResult<ObjectType>,
        fetchResultAfterChanges: PHFetchResult<ObjectType>,
        changedObjects: [ObjectType]
    ) {
        self.fetchResultBeforeChanges = fetchResultBeforeChanges
        self.fetchResultAfterChanges = fetchResultAfterChanges
        self.changedObjects = changedObjects
        hasIncrementalChanges = false
        hasMoves = false
        insertedIndexes = nil
        insertedObjects = []
        removedIndexes = nil
        removedObjects = []
        changedIndexes = changedObjects.isEmpty ? nil : IndexSet()
        super.init()
    }

    public func enumerateMoves(_ handler: @escaping (Int, Int) -> Void) {
        _ = handler
    }
}

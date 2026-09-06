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
    var targetAssetIdentifier: String?
    var pendingData: Data?
    var pendingFileURL: URL?
    var pendingImage: UIImage?
    var pendingMediaType: PHAssetMediaType = .image
    var pendingFilename = "payload.bin"
    var pendingUTI = "public.png"

    public required override init() {
        super.init()
    }

    public convenience init(for asset: PHAsset) {
        self.init()
        creationDate = asset.creationDate
        isFavorite = asset.isFavorite
        isHidden = asset.isHidden
        targetAssetIdentifier = asset.localIdentifier
        PhotosChangeSession.record(.updateAsset(self))
    }

    public convenience init(forAsset asset: PHAsset) {
        self.init(for: asset)
    }

    public class func creationRequestForAsset(from image: UIImage) -> Self {
        let identifier = photosNewLocalIdentifier()
        let request = Self()
        request.placeholderForCreatedAsset = PHObjectPlaceholder(
            placeholderIdentifier: identifier
        )
        request.pendingImage = image
        request.pendingData = PhotosEmbeddedPNG.oneByOne
        request.pendingFilename = "image.png"
        request.pendingUTI = "public.png"
        PhotosChangeSession.record(.createAsset(request))
        return request
    }

    public class func creationRequestForAssetFromImage(atFileURL fileURL: URL) -> Self? {
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            return nil
        }
        guard let data = try? Data(contentsOf: fileURL), data.isEmpty == false else {
            return nil
        }
        let identifier = photosNewLocalIdentifier()
        let request = Self()
        request.placeholderForCreatedAsset = PHObjectPlaceholder(
            placeholderIdentifier: identifier
        )
        request.pendingFileURL = fileURL
        request.pendingData = data
        request.pendingFilename = fileURL.lastPathComponent
        request.pendingUTI = photosUTI(forFilename: fileURL.lastPathComponent)
        PhotosChangeSession.record(.createAsset(request))
        return request
    }

    public class func creationRequestForAssetFromVideo(atFileURL fileURL: URL) -> Self? {
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            return nil
        }
        guard let data = try? Data(contentsOf: fileURL), data.isEmpty == false else {
            return nil
        }
        let identifier = photosNewLocalIdentifier()
        let request = Self()
        request.placeholderForCreatedAsset = PHObjectPlaceholder(
            placeholderIdentifier: identifier
        )
        request.pendingFileURL = fileURL
        request.pendingData = data
        request.pendingFilename = fileURL.lastPathComponent
        request.pendingUTI = photosUTI(forFilename: fileURL.lastPathComponent)
        request.pendingMediaType = .video
        PhotosChangeSession.record(.createAsset(request))
        return request
    }

    public class func deleteAssets(_ assets: [PHAsset]) {
        PhotosChangeSession.record(.deleteAssets(assets.map(\.localIdentifier)))
    }

    public func revertAssetContentToOriginal() {}
}

public final class PHAssetCollectionChangeRequest: PHChangeRequest, @unchecked Sendable {
    public var title: String
    public private(set) var placeholderForCreatedAssetCollection: PHObjectPlaceholder
    var targetCollectionIdentifier: String?
    var pendingAssetIdentifiers: [String] = []
    var isCreation = false

    public convenience init?(for assetCollection: PHAssetCollection) {
        self.init(title: assetCollection.localizedTitle ?? "")
        targetCollectionIdentifier = assetCollection.localIdentifier
        pendingAssetIdentifiers = assetCollection.transientAssetIdentifiers
        PhotosChangeSession.record(.updateAlbum(self))
    }

    public convenience init?(forAssetCollection assetCollection: PHAssetCollection) {
        self.init(for: assetCollection)
    }

    public convenience init?(
        for assetCollection: PHAssetCollection,
        assets: PHFetchResult<PHAsset>?
    ) {
        self.init(for: assetCollection)
        if let assets {
            pendingAssetIdentifiers = assets.objects.map(\.localIdentifier)
        }
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
            placeholderIdentifier: photosNewLocalIdentifier()
        )
        super.init()
    }

    public class func creationRequestForAssetCollection(withTitle title: String) -> Self {
        let request = Self(title: title)
        request.isCreation = true
        PhotosChangeSession.record(.createAlbum(request))
        return request
    }

    public class func deleteAssetCollections(_ assetCollections: [PHAssetCollection]) {
        PhotosChangeSession.record(
            .deleteAlbums(assetCollections.map(\.localIdentifier))
        )
    }

    public func addAssets(_ assets: [PHAsset]) {
        pendingAssetIdentifiers.append(contentsOf: assets.map(\.localIdentifier))
    }

    public func insertAssets(_ assets: [PHAsset], at indexes: IndexSet) {
        let identifiers = assets.map(\.localIdentifier)
        var cursor = 0
        for index in indexes.sorted() {
            if cursor < identifiers.count, index <= pendingAssetIdentifiers.count {
                pendingAssetIdentifiers.insert(identifiers[cursor], at: index)
                cursor += 1
            }
        }
    }

    public func moveAssets(at fromIndexes: IndexSet, to toIndex: Int) {
        let moving = fromIndexes.sorted().reversed().compactMap { index -> String? in
            guard pendingAssetIdentifiers.indices.contains(index) else { return nil }
            return pendingAssetIdentifiers.remove(at: index)
        }.reversed()
        var insertAt = min(max(toIndex, 0), pendingAssetIdentifiers.count)
        for identifier in moving {
            pendingAssetIdentifiers.insert(identifier, at: insertAt)
            insertAt += 1
        }
    }

    public func removeAssets(_ assets: [PHAsset]) {
        let unwanted = Set(assets.map(\.localIdentifier))
        pendingAssetIdentifiers.removeAll { unwanted.contains($0) }
    }

    public func removeAssets(at indexes: IndexSet) {
        for index in indexes.sorted().reversed() {
            if pendingAssetIdentifiers.indices.contains(index) {
                pendingAssetIdentifiers.remove(at: index)
            }
        }
    }

    public func replaceAssets(at indexes: IndexSet, withAssets assets: [PHAsset]) {
        let identifiers = assets.map(\.localIdentifier)
        var cursor = 0
        for index in indexes.sorted() {
            if cursor < identifiers.count, pendingAssetIdentifiers.indices.contains(index) {
                pendingAssetIdentifiers[index] = identifiers[cursor]
                cursor += 1
            }
        }
    }
}

public final class PHCollectionListChangeRequest: PHChangeRequest, @unchecked Sendable {
    public var title: String
    public private(set) var placeholderForCreatedCollectionList: PHObjectPlaceholder
    var targetListIdentifier: String?
    var pendingChildIdentifiers: [String] = []
    var isCreation = false

    public convenience init?(for collectionList: PHCollectionList) {
        self.init(title: collectionList.localizedTitle ?? "")
        targetListIdentifier = collectionList.localIdentifier
        pendingChildIdentifiers = collectionList.childIdentifiers
        PhotosChangeSession.record(.updateList(self))
    }

    public convenience init?(forCollectionList collectionList: PHCollectionList) {
        self.init(for: collectionList)
    }

    public convenience init?(
        for collectionList: PHCollectionList,
        childCollections: PHFetchResult<PHCollection>
    ) {
        self.init(for: collectionList)
        pendingChildIdentifiers = childCollections.objects.map(\.localIdentifier)
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
        self.init(title: "")
        pendingChildIdentifiers = childCollections.objects.map(\.localIdentifier)
        PhotosChangeSession.record(.replaceTopLevel(self))
    }

    public init(title: String) {
        self.title = title
        placeholderForCreatedCollectionList = PHObjectPlaceholder(
            placeholderIdentifier: photosNewLocalIdentifier()
        )
        super.init()
    }

    public class func creationRequestForCollectionList(withTitle title: String) -> Self {
        let request = Self(title: title)
        request.isCreation = true
        PhotosChangeSession.record(.createList(request))
        return request
    }

    public class func deleteCollectionLists(_ collectionLists: [PHCollectionList]) {
        PhotosChangeSession.record(
            .deleteLists(collectionLists.map(\.localIdentifier))
        )
    }

    public func addChildCollections(_ collections: [PHCollection]) {
        pendingChildIdentifiers.append(contentsOf: collections.map(\.localIdentifier))
    }

    public func insertChildCollections(_ collections: [PHCollection], at indexes: IndexSet) {
        let identifiers = collections.map(\.localIdentifier)
        var cursor = 0
        for index in indexes.sorted() {
            if cursor < identifiers.count, index <= pendingChildIdentifiers.count {
                pendingChildIdentifiers.insert(identifiers[cursor], at: index)
                cursor += 1
            }
        }
    }

    public func moveChildCollections(at indexes: IndexSet, to toIndex: Int) {
        let moving = indexes.sorted().reversed().compactMap { index -> String? in
            guard pendingChildIdentifiers.indices.contains(index) else { return nil }
            return pendingChildIdentifiers.remove(at: index)
        }.reversed()
        var insertAt = min(max(toIndex, 0), pendingChildIdentifiers.count)
        for identifier in moving {
            pendingChildIdentifiers.insert(identifier, at: insertAt)
            insertAt += 1
        }
    }

    public func removeChildCollections(_ collections: [PHCollection]) {
        let unwanted = Set(collections.map(\.localIdentifier))
        pendingChildIdentifiers.removeAll { unwanted.contains($0) }
    }

    public func removeChildCollections(at indexes: IndexSet) {
        for index in indexes.sorted().reversed() {
            if pendingChildIdentifiers.indices.contains(index) {
                pendingChildIdentifiers.remove(at: index)
            }
        }
    }

    public func replaceChildCollections(
        at indexes: IndexSet,
        withChildCollections collections: [PHCollection]
    ) {
        let identifiers = collections.map(\.localIdentifier)
        var cursor = 0
        for index in indexes.sorted() {
            if cursor < identifiers.count, pendingChildIdentifiers.indices.contains(index) {
                pendingChildIdentifiers[index] = identifiers[cursor]
                cursor += 1
            }
        }
    }
}

public final class PHAssetCreationRequest: PHAssetChangeRequest, @unchecked Sendable {
    public class func forAsset() -> Self {
        let request = Self()
        request.placeholderForCreatedAsset = PHObjectPlaceholder(
            placeholderIdentifier: photosNewLocalIdentifier()
        )
        PhotosChangeSession.record(.createAsset(request))
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
        pendingMediaType = type == .video ? .video : .image
        pendingData = data
        if let filename = options?.originalFilename {
            pendingFilename = filename
            pendingUTI = photosUTI(forFilename: filename)
        }
    }

    public func addResource(
        with type: PHAssetResourceType,
        fileURL: URL,
        options: PHAssetResourceCreationOptions?
    ) {
        pendingMediaType = type == .video ? .video : .image
        pendingFileURL = fileURL
        pendingData = try? Data(contentsOf: fileURL)
        pendingFilename = options?.originalFilename ?? fileURL.lastPathComponent
        pendingUTI = options?.uniformTypeIdentifier
            ?? photosUTI(forFilename: pendingFilename)
    }
}

public final class PHChange: NSObject, @unchecked Sendable {
    let applied: PhotosAppliedChange

    init(applied: PhotosAppliedChange) {
        self.applied = applied
        super.init()
    }

    public override init() {
        applied = PhotosAppliedChange(
            insertedAssetIdentifiers: [],
            removedAssetIdentifiers: [],
            changedAssetIdentifiers: [],
            insertedAlbumIdentifiers: [],
            removedAlbumIdentifiers: [],
            changedAlbumIdentifiers: [],
            insertedListIdentifiers: [],
            removedListIdentifiers: [],
            changedListIdentifiers: [],
            token: 0
        )
        super.init()
    }

    public func changeDetails<T: PHObject>(for object: T) -> PHObjectChangeDetails<T>? {
        let identifier = object.localIdentifier
        if applied.removedAssetIdentifiers.contains(identifier)
            || applied.removedAlbumIdentifiers.contains(identifier)
        {
            return PHObjectChangeDetails(
                objectBeforeChanges: object,
                objectAfterChanges: nil,
                assetContentChanged: false,
                objectWasDeleted: true
            )
        }
        if applied.changedAssetIdentifiers.contains(identifier),
            let after = PhotosLibraryStore.asset(identifier: identifier) as? T
        {
            return PHObjectChangeDetails(
                objectBeforeChanges: object,
                objectAfterChanges: after,
                assetContentChanged: true,
                objectWasDeleted: false
            )
        }
        if applied.changedAlbumIdentifiers.contains(identifier),
            let after = PhotosLibraryStore.album(identifier: identifier) as? T
        {
            return PHObjectChangeDetails(
                objectBeforeChanges: object,
                objectAfterChanges: after,
                assetContentChanged: false,
                objectWasDeleted: false
            )
        }
        if applied.removedListIdentifiers.contains(identifier) {
            return PHObjectChangeDetails(
                objectBeforeChanges: object,
                objectAfterChanges: nil,
                assetContentChanged: false,
                objectWasDeleted: true
            )
        }
        if applied.changedListIdentifiers.contains(identifier),
            let after = PhotosLibraryStore.list(identifier: identifier) as? T
        {
            return PHObjectChangeDetails(
                objectBeforeChanges: object,
                objectAfterChanges: after,
                assetContentChanged: false,
                objectWasDeleted: false
            )
        }
        return nil
    }

    public func changeDetails<T: PHObject>(
        for fetchResult: PHFetchResult<T>
    ) -> PHFetchResultChangeDetails<T>? {
        let afterObjects: [T]
        if let refetch = fetchResult.refetch {
            afterObjects = refetch()
        } else {
            afterObjects = fetchResult.objects
        }
        let after = PHFetchResult(afterObjects, refetch: fetchResult.refetch)
        let changedIDs = Set(
            applied.changedAssetIdentifiers
                + applied.changedAlbumIdentifiers
                + applied.changedListIdentifiers
        )
        let changed = afterObjects.filter { changedIDs.contains($0.localIdentifier) }
        let details = PHFetchResultChangeDetails(
            fetchResultBeforeChanges: fetchResult,
            fetchResultAfterChanges: after,
            changedObjects: changed
        )
        if details.insertedIndexes == nil,
            details.removedIndexes == nil,
            details.changedIndexes == nil,
            details.hasMoves == false
        {
            return nil
        }
        return details
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
        let beforeIDs = fetchResultBeforeChanges.objects.map(\.localIdentifier)
        let afterIDs = fetchResultAfterChanges.objects.map(\.localIdentifier)
        let beforeSet = Set(beforeIDs)
        let afterSet = Set(afterIDs)
        var inserted = IndexSet()
        var insertedObjs: [ObjectType] = []
        for (index, identifier) in afterIDs.enumerated() {
            if beforeSet.contains(identifier) == false {
                inserted.insert(index)
                insertedObjs.append(fetchResultAfterChanges.objects[index])
            }
        }
        var removed = IndexSet()
        var removedObjs: [ObjectType] = []
        for (index, identifier) in beforeIDs.enumerated() {
            if afterSet.contains(identifier) == false {
                removed.insert(index)
                removedObjs.append(fetchResultBeforeChanges.objects[index])
            }
        }
        let changedIDs = Set(changedObjects.map(\.localIdentifier))
        var changed = IndexSet()
        for (index, identifier) in afterIDs.enumerated() {
            if changedIDs.contains(identifier) {
                changed.insert(index)
            }
        }
        let remainingBefore = beforeIDs.filter { afterSet.contains($0) }
        let remainingAfter = afterIDs.filter { beforeSet.contains($0) }
        hasMoves = remainingBefore != remainingAfter
        hasIncrementalChanges = true
        insertedIndexes = inserted.isEmpty ? nil : inserted
        insertedObjects = insertedObjs
        removedIndexes = removed.isEmpty ? nil : removed
        removedObjects = removedObjs
        changedIndexes = changed.isEmpty ? nil : changed
        super.init()
    }

    public func enumerateMoves(_ handler: @escaping (Int, Int) -> Void) {
        let beforeIDs = fetchResultBeforeChanges.objects.map(\.localIdentifier)
        let afterIDs = fetchResultAfterChanges.objects.map(\.localIdentifier)
        var afterIndex: [String: Int] = [:]
        for (index, identifier) in afterIDs.enumerated() {
            if afterIndex[identifier] == nil {
                afterIndex[identifier] = index
            }
        }
        for (from, identifier) in beforeIDs.enumerated() {
            guard let to = afterIndex[identifier], from != to else { continue }
            handler(from, to)
        }
    }
}

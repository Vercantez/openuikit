import Foundation

open class PHCollection: PHObject, @unchecked Sendable {
    public let localizedTitle: String?
    public let canContainAssets: Bool
    public let canContainCollections: Bool

    init(
        localIdentifier: String,
        localizedTitle: String?,
        canContainAssets: Bool,
        canContainCollections: Bool
    ) {
        self.localizedTitle = localizedTitle
        self.canContainAssets = canContainAssets
        self.canContainCollections = canContainCollections
        super.init(localIdentifier: localIdentifier)
    }

    public func canPerform(_ anOperation: PHCollectionEditOperation) -> Bool {
        _ = anOperation
        return photosReadAccessGranted()
    }

    public static func fetchCollections(
        in collectionList: PHCollectionList,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHCollection> {
        _ = options
        guard photosReadAccessGranted() else {
            return PHFetchResult([])
        }
        let wanted = collectionList.childIdentifiers
        let rank = Dictionary(uniqueKeysWithValues: wanted.enumerated().map { ($1, $0) })
        let albums: [PHCollection] = PhotosLibraryStore.userAlbums().filter {
            rank[$0.localIdentifier] != nil
        }
        let lists: [PHCollection] = PhotosLibraryStore.userLists().filter {
            rank[$0.localIdentifier] != nil
        }
        let combined = (albums + lists).sorted {
            (rank[$0.localIdentifier] ?? Int.max) < (rank[$1.localIdentifier] ?? Int.max)
        }
        return PHFetchResult(combined)
    }

    public static func fetchTopLevelUserCollections(
        with options: PHFetchOptions?
    ) -> PHFetchResult<PHCollection> {
        _ = options
        guard photosReadAccessGranted() else {
            return PHFetchResult([])
        }
        return PHFetchResult(PhotosLibraryStore.topLevelCollections())
    }
}

public final class PHAssetCollection: PHCollection, @unchecked Sendable {
    public let assetCollectionType: PHAssetCollectionType
    public let assetCollectionSubtype: PHAssetCollectionSubtype
    public let estimatedAssetCount: Int
    public let startDate: Date?
    public let endDate: Date?
    public let localizedLocationNames: [String]
    let transientAssetIdentifiers: [String]

    @_spi(OpenUIKitHost)
    public init(
        localIdentifier: String,
        title: String?,
        type: PHAssetCollectionType,
        subtype: PHAssetCollectionSubtype,
        estimatedAssetCount: Int = 0,
        startDate: Date? = nil,
        endDate: Date? = nil,
        assetIdentifiers: [String] = []
    ) {
        assetCollectionType = type
        assetCollectionSubtype = subtype
        self.estimatedAssetCount = estimatedAssetCount
        self.startDate = startDate
        self.endDate = endDate
        localizedLocationNames = []
        transientAssetIdentifiers = assetIdentifiers
        super.init(
            localIdentifier: localIdentifier,
            localizedTitle: title,
            canContainAssets: true,
            canContainCollections: false
        )
    }

    public static func fetchAssetCollections(
        with type: PHAssetCollectionType,
        subtype: PHAssetCollectionSubtype,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetCollection> {
        _ = options
        guard photosReadAccessGranted() else {
            return PHFetchResult([])
        }
        if type == .smartAlbum {
            let albums = photosSmartAlbumSubtypes().map(photosMakeSmartAlbum)
            let filtered = albums.filter { collection in
                subtype == .any || collection.assetCollectionSubtype == subtype
            }
            return PHFetchResult(filtered)
        }
        let collections = PhotosLibraryStore.userAlbums().filter { collection in
            if type != collection.assetCollectionType {
                return false
            }
            if subtype == .any {
                return true
            }
            return collection.assetCollectionSubtype == subtype
        }
        return PHFetchResult(collections)
    }

    public static func fetchAssetCollections(
        withLocalIdentifiers identifiers: [String],
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetCollection> {
        _ = options
        guard photosReadAccessGranted() else {
            return PHFetchResult([])
        }
        let wanted = Set(identifiers)
        let collections = PhotosLibraryStore.userAlbums().filter {
            wanted.contains($0.localIdentifier)
        }
        return PHFetchResult(collections)
    }

    public static func fetchAssetCollectionsContaining(
        _ asset: PHAsset,
        with type: PHAssetCollectionType,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetCollection> {
        _ = options
        guard photosReadAccessGranted() else {
            return PHFetchResult([])
        }
        let collections = PhotosLibraryStore.userAlbums().filter { collection in
            collection.assetCollectionType == type
                && collection.transientAssetIdentifiers.contains(asset.localIdentifier)
        }
        return PHFetchResult(collections)
    }

    public static func fetchAssetCollections(
        withALAssetGroupURLs assetGroupURLs: [URL],
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetCollection> {
        _ = assetGroupURLs
        _ = options
        return PHFetchResult([])
    }

    public static func fetchMoments(
        inMomentList momentList: PHCollectionList,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetCollection> {
        _ = momentList
        _ = options
        return PHFetchResult([])
    }

    public static func fetchMoments(with options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        _ = options
        return PHFetchResult([])
    }

    public static func transientAssetCollection(
        with assets: [PHAsset],
        title: String?
    ) -> PHAssetCollection {
        PHAssetCollection(
            localIdentifier: "transient.assets.\(UUID().uuidString)",
            title: title,
            type: .album,
            subtype: .albumRegular,
            estimatedAssetCount: assets.count,
            assetIdentifiers: assets.map(\.localIdentifier)
        )
    }

    public static func transientAssetCollection(
        withAssetFetchResult fetchResult: PHFetchResult<PHAsset>,
        title: String?
    ) -> PHAssetCollection {
        transientAssetCollection(with: fetchResult.objects, title: title)
    }
}

public final class PHCollectionList: PHCollection, @unchecked Sendable {
    public let collectionListType: PHCollectionListType
    public let collectionListSubtype: PHCollectionListSubtype
    public let startDate: Date?
    public let endDate: Date?
    public let localizedLocationNames: [String]
    let childIdentifiers: [String]

    init(
        localIdentifier: String,
        title: String?,
        type: PHCollectionListType,
        subtype: PHCollectionListSubtype,
        startDate: Date? = nil,
        endDate: Date? = nil,
        childIdentifiers: [String] = []
    ) {
        collectionListType = type
        collectionListSubtype = subtype
        self.startDate = startDate
        self.endDate = endDate
        localizedLocationNames = []
        self.childIdentifiers = childIdentifiers
        super.init(
            localIdentifier: localIdentifier,
            localizedTitle: title,
            canContainAssets: false,
            canContainCollections: true
        )
    }

    public static func fetchCollectionLists(
        with collectionListType: PHCollectionListType,
        subtype: PHCollectionListSubtype,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHCollectionList> {
        _ = options
        guard photosReadAccessGranted() else {
            return PHFetchResult([])
        }
        let lists = PhotosLibraryStore.userLists().filter { list in
            if list.collectionListType != collectionListType {
                return false
            }
            if subtype == .any {
                return true
            }
            return list.collectionListSubtype == subtype
        }
        return PHFetchResult(lists)
    }

    public static func fetchCollectionLists(
        withLocalIdentifiers identifiers: [String],
        options: PHFetchOptions?
    ) -> PHFetchResult<PHCollectionList> {
        _ = options
        guard photosReadAccessGranted() else {
            return PHFetchResult([])
        }
        let wanted = Set(identifiers)
        let lists = PhotosLibraryStore.userLists().filter {
            wanted.contains($0.localIdentifier)
        }
        return PHFetchResult(lists)
    }

    public static func fetchCollectionListsContaining(
        _ collection: PHCollection,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHCollectionList> {
        _ = options
        guard photosReadAccessGranted() else {
            return PHFetchResult([])
        }
        let lists = PhotosLibraryStore.userLists().filter {
            $0.childIdentifiers.contains(collection.localIdentifier)
        }
        return PHFetchResult(lists)
    }

    public static func fetchMomentLists(
        with momentListSubtype: PHCollectionListSubtype,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHCollectionList> {
        _ = momentListSubtype
        _ = options
        return PHFetchResult([])
    }

    public static func fetchMomentLists(
        with momentListSubtype: PHCollectionListSubtype,
        containingMoment moment: PHAssetCollection,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHCollectionList> {
        _ = momentListSubtype
        _ = moment
        _ = options
        return PHFetchResult([])
    }

    public static func transientCollectionList(
        with collections: [PHCollection],
        title: String?
    ) -> PHCollectionList {
        PHCollectionList(
            localIdentifier: "transient.list.\(UUID().uuidString)",
            title: title,
            type: .folder,
            subtype: .regularFolder,
            childIdentifiers: collections.map(\.localIdentifier)
        )
    }

    public static func transientCollectionList(
        withCollectionsFetchResult fetchResult: PHFetchResult<PHCollection>,
        title: String?
    ) -> PHCollectionList {
        transientCollectionList(with: fetchResult.objects, title: title)
    }
}

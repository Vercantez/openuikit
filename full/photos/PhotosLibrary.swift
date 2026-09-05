import Foundation

/// 1×1 sRGB PNG (IHDR 1×1, color type 2). MEASURED by generating a zlib-compressed
/// IDAT and reading width/height from bytes 16..<24: both are `1`.
enum PhotosEmbeddedPNG {
    static let oneByOne: Data = Data([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x03, 0x01, 0x01, 0x00, 0xF7, 0x03, 0x41, 0x43, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ])
}

/// On-disk photo library under the process documents directory
/// (`Documents/OpenUIKitPhotoLibrary`). Isolated tests call
/// `PHPhotoLibraryPortable._reset()` which deletes that directory.
enum PhotosLibraryStore {
    static let lock = NSLock()
    static let callbackQueue = DispatchQueue(label: "org.openuikit.Photos.host-callback")

    struct AssetRecord {
        var localIdentifier: String
        var mediaType: PHAssetMediaType
        var creationDate: Date?
        var addedDate: Date
        var modificationDate: Date?
        var duration: TimeInterval
        var pixelWidth: Int
        var pixelHeight: Int
        var isFavorite: Bool
        var isHidden: Bool
        var hasAdjustments: Bool
        var representsBurst: Bool
        var burstIdentifier: String?
        var burstSelectionTypes: PHAssetBurstSelectionType
        var mediaSubtypes: PHAssetMediaSubtype
        var sourceType: PHAssetSourceType
        var playbackStyle: PHAsset.PlaybackStyle
        var adjustmentFormatIdentifier: String?
        var filename: String
        var uniformTypeIdentifier: String
        var resourcePath: String?
        var storedData: Data?
        var portableImage: UIImage?
    }

    struct AlbumRecord {
        var localIdentifier: String
        var title: String
        var type: PHAssetCollectionType
        var subtype: PHAssetCollectionSubtype
        var assetIdentifiers: [String]
        var startDate: Date?
        var endDate: Date?
    }

    struct ListRecord {
        var localIdentifier: String
        var title: String
        var type: PHCollectionListType
        var subtype: PHCollectionListSubtype
        var childIdentifiers: [String]
    }

    struct Snapshot {
        var statuses: [PHAccessLevel: PHAuthorizationStatus] = [:]
        var authorizationHandler: PHPhotoLibraryPortable.AuthorizationHandler?
        var assets: [String: AssetRecord] = [:]
        var assetOrder: [String] = []
        var albums: [String: AlbumRecord] = [:]
        var albumOrder: [String] = []
        var lists: [String: ListRecord] = [:]
        var listOrder: [String] = []
        var changeObservers: [ObjectIdentifier: PHPhotoLibraryChangeObserver] = [:]
        var availabilityObservers: [ObjectIdentifier: PHPhotoLibraryAvailabilityObserver] = [:]
        var uploadJobExtensionEnabled = false
        var changeToken = 0
        var persistentChanges: [PHPersistentChange] = []
    }

    nonisolated(unsafe) static var state = Snapshot()

    static func libraryRoot() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
                .appendingPathComponent("Documents", isDirectory: true)
        return docs.appendingPathComponent("OpenUIKitPhotoLibrary", isDirectory: true)
    }

    static func manifestURL() -> URL {
        libraryRoot().appendingPathComponent("library.json")
    }

    static func assetsDirectory() -> URL {
        libraryRoot().appendingPathComponent("assets", isDirectory: true)
    }

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        state = Snapshot()
        try? FileManager.default.removeItem(at: libraryRoot())
    }

    static func status(for level: PHAccessLevel) -> PHAuthorizationStatus {
        lock.withLock { state.statuses[level] ?? .notDetermined }
    }

    static func store(_ status: PHAuthorizationStatus, for level: PHAccessLevel) {
        lock.withLock { state.statuses[level] = status }
    }

    static func handler() -> PHPhotoLibraryPortable.AuthorizationHandler? {
        lock.withLock { state.authorizationHandler }
    }

    static func setHandler(_ handler: PHPhotoLibraryPortable.AuthorizationHandler?) {
        lock.withLock { state.authorizationHandler = handler }
    }

    static func isUploadJobExtensionEnabled() -> Bool {
        lock.withLock { state.uploadJobExtensionEnabled }
    }

    static func setUploadJobExtensionEnabled(_ enable: Bool) {
        lock.withLock { state.uploadJobExtensionEnabled = enable }
    }

    static func currentChangeToken() -> PHPersistentChangeToken {
        lock.withLock { PHPersistentChangeToken(tokenValue: state.changeToken) }
    }

    static func registerChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        lock.withLock {
            state.changeObservers[ObjectIdentifier(observer)] = observer
        }
    }

    static func unregisterChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        lock.withLock {
            _ = state.changeObservers.removeValue(forKey: ObjectIdentifier(observer))
        }
    }

    static func registerAvailabilityObserver(_ observer: PHPhotoLibraryAvailabilityObserver) {
        lock.withLock {
            state.availabilityObservers[ObjectIdentifier(observer)] = observer
        }
    }

    static func unregisterAvailabilityObserver(_ observer: PHPhotoLibraryAvailabilityObserver) {
        lock.withLock {
            _ = state.availabilityObservers.removeValue(forKey: ObjectIdentifier(observer))
        }
    }

    static func changeObservers() -> [PHPhotoLibraryChangeObserver] {
        lock.withLock { Array(state.changeObservers.values) }
    }

    static func installAssets(_ assets: [PHAsset]) {
        lock.lock()
        defer { lock.unlock() }
        state.assets = [:]
        state.assetOrder = []
        for asset in assets {
            let record = AssetRecord(
                localIdentifier: asset.localIdentifier,
                mediaType: asset.mediaType,
                creationDate: asset.creationDate,
                addedDate: asset.addedDate,
                modificationDate: asset.modificationDate,
                duration: asset.duration,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                isFavorite: asset.isFavorite,
                isHidden: asset.isHidden,
                hasAdjustments: asset.hasAdjustments,
                representsBurst: asset.representsBurst,
                burstIdentifier: asset.burstIdentifier,
                burstSelectionTypes: asset.burstSelectionTypes,
                mediaSubtypes: asset.mediaSubtypes,
                sourceType: asset.sourceType,
                playbackStyle: asset.playbackStyle,
                adjustmentFormatIdentifier: asset.adjustmentFormatIdentifier,
                filename: asset.originalFilename,
                uniformTypeIdentifier: asset.uniformTypeIdentifier,
                resourcePath: nil,
                storedData: asset.portableData,
                portableImage: asset.portableImage
            )
            state.assets[asset.localIdentifier] = record
            state.assetOrder.append(asset.localIdentifier)
        }
        persistLocked()
    }

    static func installCollections(_ collections: [PHAssetCollection]) {
        lock.lock()
        defer { lock.unlock() }
        state.albums = [:]
        state.albumOrder = []
        for collection in collections {
            let record = AlbumRecord(
                localIdentifier: collection.localIdentifier,
                title: collection.localizedTitle ?? "",
                type: collection.assetCollectionType,
                subtype: collection.assetCollectionSubtype,
                assetIdentifiers: collection.transientAssetIdentifiers,
                startDate: collection.startDate,
                endDate: collection.endDate
            )
            state.albums[collection.localIdentifier] = record
            state.albumOrder.append(collection.localIdentifier)
        }
        persistLocked()
    }

    static func allAssets() -> [PHAsset] {
        lock.withLock {
            state.assetOrder.compactMap { identifier in
                state.assets[identifier].map(makeAsset)
            }
        }
    }

    static func asset(identifier: String) -> PHAsset? {
        lock.withLock {
            state.assets[identifier].map(makeAsset)
        }
    }

    static func userAlbums() -> [PHAssetCollection] {
        lock.withLock {
            state.albumOrder.compactMap { identifier in
                state.albums[identifier].map(makeAlbum)
            }
        }
    }

    static func userLists() -> [PHCollectionList] {
        lock.withLock {
            state.listOrder.compactMap { identifier in
                state.lists[identifier].map(makeList)
            }
        }
    }

    static func album(identifier: String) -> PHAssetCollection? {
        lock.withLock {
            state.albums[identifier].map(makeAlbum)
        }
    }

    static func list(identifier: String) -> PHCollectionList? {
        lock.withLock {
            state.lists[identifier].map(makeList)
        }
    }

    static func resourceData(forAssetIdentifier identifier: String) -> Data? {
        lock.withLock {
            guard let record = state.assets[identifier] else { return nil }
            if let stored = record.storedData {
                return stored
            }
            if let relative = record.resourcePath {
                let url = libraryRoot().appendingPathComponent(relative)
                return try? Data(contentsOf: url)
            }
            return nil
        }
    }

    static func apply(_ operations: [PhotosPendingOperation]) throws -> PhotosAppliedChange {
        lock.lock()
        defer { lock.unlock() }
        var insertedAssets: [String] = []
        var removedAssets: [String] = []
        var changedAssets: [String] = []
        var insertedAlbums: [String] = []
        var removedAlbums: [String] = []
        var changedAlbums: [String] = []

        for operation in operations {
            switch operation {
            case .createAsset(let request):
                let identifier = request.placeholderForCreatedAsset?.localIdentifier
                    ?? photosNewLocalIdentifier()
                var data = request.pendingData
                if data == nil, let fileURL = request.pendingFileURL {
                    data = try? Data(contentsOf: fileURL)
                }
                if data == nil {
                    data = PhotosEmbeddedPNG.oneByOne
                }
                let size = data.flatMap(photosImagePixelSize)
                    ?? (1, 1)
                let now = Date()
                var record = AssetRecord(
                    localIdentifier: identifier,
                    mediaType: request.pendingMediaType,
                    creationDate: request.creationDate ?? now,
                    addedDate: now,
                    modificationDate: now,
                    duration: 0,
                    pixelWidth: size.0,
                    pixelHeight: size.1,
                    isFavorite: request.isFavorite,
                    isHidden: request.isHidden,
                    hasAdjustments: false,
                    representsBurst: false,
                    burstIdentifier: nil,
                    burstSelectionTypes: [],
                    mediaSubtypes: [],
                    sourceType: .typeUserLibrary,
                    playbackStyle: photosPlaybackStyle(for: request.pendingMediaType),
                    adjustmentFormatIdentifier: nil,
                    filename: request.pendingFilename,
                    uniformTypeIdentifier: request.pendingUTI,
                    resourcePath: nil,
                    storedData: data,
                    portableImage: request.pendingImage
                )
                record.resourcePath = persistAssetDataLocked(identifier: identifier, data: data)
                state.assets[identifier] = record
                state.assetOrder.append(identifier)
                insertedAssets.append(identifier)
            case .updateAsset(let request):
                guard let identifier = request.targetAssetIdentifier,
                    var record = state.assets[identifier]
                else { continue }
                record.isFavorite = request.isFavorite
                record.isHidden = request.isHidden
                if let creationDate = request.creationDate {
                    record.creationDate = creationDate
                }
                record.modificationDate = Date()
                state.assets[identifier] = record
                changedAssets.append(identifier)
            case .deleteAssets(let identifiers):
                for identifier in identifiers {
                    if state.assets.removeValue(forKey: identifier) != nil {
                        state.assetOrder.removeAll { $0 == identifier }
                        removedAssets.append(identifier)
                        for albumIdentifier in state.albumOrder {
                            guard var album = state.albums[albumIdentifier] else { continue }
                            let before = album.assetIdentifiers.count
                            album.assetIdentifiers.removeAll { $0 == identifier }
                            if album.assetIdentifiers.count != before {
                                state.albums[albumIdentifier] = album
                                changedAlbums.append(albumIdentifier)
                            }
                        }
                        let folder = assetsDirectory().appendingPathComponent(identifier, isDirectory: true)
                        try? FileManager.default.removeItem(at: folder)
                    }
                }
            case .createAlbum(let request):
                let identifier = request.placeholderForCreatedAssetCollection.localIdentifier
                let record = AlbumRecord(
                    localIdentifier: identifier,
                    title: request.title,
                    type: .album,
                    subtype: .albumRegular,
                    assetIdentifiers: request.pendingAssetIdentifiers,
                    startDate: nil,
                    endDate: nil
                )
                state.albums[identifier] = record
                state.albumOrder.append(identifier)
                insertedAlbums.append(identifier)
            case .updateAlbum(let request):
                guard let identifier = request.targetCollectionIdentifier,
                    var record = state.albums[identifier]
                else { continue }
                record.title = request.title
                record.assetIdentifiers = request.pendingAssetIdentifiers
                state.albums[identifier] = record
                changedAlbums.append(identifier)
            case .deleteAlbums(let identifiers):
                for identifier in identifiers {
                    if state.albums.removeValue(forKey: identifier) != nil {
                        state.albumOrder.removeAll { $0 == identifier }
                        removedAlbums.append(identifier)
                    }
                }
            case .createList(let request):
                let identifier = request.placeholderForCreatedCollectionList.localIdentifier
                let record = ListRecord(
                    localIdentifier: identifier,
                    title: request.title,
                    type: .folder,
                    subtype: .regularFolder,
                    childIdentifiers: request.pendingChildIdentifiers
                )
                state.lists[identifier] = record
                state.listOrder.append(identifier)
            case .updateList(let request):
                guard let identifier = request.targetListIdentifier,
                    var record = state.lists[identifier]
                else { continue }
                record.title = request.title
                record.childIdentifiers = request.pendingChildIdentifiers
                state.lists[identifier] = record
            case .deleteLists(let identifiers):
                for identifier in identifiers {
                    if state.lists.removeValue(forKey: identifier) != nil {
                        state.listOrder.removeAll { $0 == identifier }
                    }
                }
            }
        }

        let mutated = !(
            insertedAssets.isEmpty && removedAssets.isEmpty && changedAssets.isEmpty
                && insertedAlbums.isEmpty && removedAlbums.isEmpty && changedAlbums.isEmpty
        )
        if mutated {
            state.changeToken += 1
            let token = PHPersistentChangeToken(tokenValue: state.changeToken)
            let persistent = PHPersistentChange(changeToken: token)
            persistent.assetDetails = PHPersistentObjectChangeDetails(
                objectType: .asset,
                insertedLocalIdentifiers: Set(insertedAssets),
                updatedLocalIdentifiers: Set(changedAssets),
                deletedLocalIdentifiers: Set(removedAssets)
            )
            persistent.collectionDetails = PHPersistentObjectChangeDetails(
                objectType: .assetCollection,
                insertedLocalIdentifiers: Set(insertedAlbums),
                updatedLocalIdentifiers: Set(changedAlbums),
                deletedLocalIdentifiers: Set(removedAlbums)
            )
            state.persistentChanges.append(persistent)
            persistLocked()
        }

        return PhotosAppliedChange(
            insertedAssetIdentifiers: insertedAssets,
            removedAssetIdentifiers: removedAssets,
            changedAssetIdentifiers: changedAssets,
            insertedAlbumIdentifiers: insertedAlbums,
            removedAlbumIdentifiers: removedAlbums,
            changedAlbumIdentifiers: changedAlbums,
            token: state.changeToken
        )
    }

    static func persistentChanges(since token: PHPersistentChangeToken) throws -> [PHPersistentChange] {
        lock.lock()
        defer { lock.unlock() }
        if token.tokenValue > state.changeToken {
            throw PHPhotosError(.persistentChangeTokenExpired)
        }
        return state.persistentChanges.filter { $0.changeToken.tokenValue > token.tokenValue }
    }

    static func makeAsset(_ record: AssetRecord) -> PHAsset {
        var data = record.storedData
        if data == nil, let relative = record.resourcePath {
            let url = libraryRoot().appendingPathComponent(relative)
            data = try? Data(contentsOf: url)
        }
        return PHAsset(
            localIdentifier: record.localIdentifier,
            mediaType: record.mediaType,
            creationDate: record.creationDate,
            addedDate: record.addedDate,
            modificationDate: record.modificationDate,
            duration: record.duration,
            pixelWidth: record.pixelWidth,
            pixelHeight: record.pixelHeight,
            isFavorite: record.isFavorite,
            isHidden: record.isHidden,
            hasAdjustments: record.hasAdjustments,
            representsBurst: record.representsBurst,
            burstIdentifier: record.burstIdentifier,
            burstSelectionTypes: record.burstSelectionTypes,
            mediaSubtypes: record.mediaSubtypes,
            sourceType: record.sourceType,
            playbackStyle: record.playbackStyle,
            adjustmentFormatIdentifier: record.adjustmentFormatIdentifier,
            data: data,
            image: record.portableImage,
            originalFilename: record.filename,
            uniformTypeIdentifier: record.uniformTypeIdentifier
        )
    }

    static func makeAlbum(_ record: AlbumRecord) -> PHAssetCollection {
        PHAssetCollection(
            localIdentifier: record.localIdentifier,
            title: record.title,
            type: record.type,
            subtype: record.subtype,
            estimatedAssetCount: record.assetIdentifiers.count,
            startDate: record.startDate,
            endDate: record.endDate,
            assetIdentifiers: record.assetIdentifiers
        )
    }

    static func makeList(_ record: ListRecord) -> PHCollectionList {
        PHCollectionList(
            localIdentifier: record.localIdentifier,
            title: record.title,
            type: record.type,
            subtype: record.subtype,
            childIdentifiers: record.childIdentifiers
        )
    }

    private static func persistAssetDataLocked(identifier: String, data: Data?) -> String? {
        guard let data else { return nil }
        let folder = assetsDirectory().appendingPathComponent(identifier, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let file = folder.appendingPathComponent("payload.bin")
            try data.write(to: file, options: .atomic)
            return "assets/\(identifier)/payload.bin"
        } catch {
            return nil
        }
    }

    private static func persistLocked() {
        do {
            try FileManager.default.createDirectory(at: libraryRoot(), withIntermediateDirectories: true)
            let payload = serializeLocked()
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            try data.write(to: manifestURL(), options: .atomic)
        } catch {
            return
        }
    }

    private static func serializeLocked() -> [String: Any] {
        var assets: [[String: Any]] = []
        for identifier in state.assetOrder {
            guard let record = state.assets[identifier] else { continue }
            var row: [String: Any] = [
                "localIdentifier": record.localIdentifier,
                "mediaType": record.mediaType.rawValue,
                "addedDate": record.addedDate.timeIntervalSince1970,
                "duration": record.duration,
                "pixelWidth": record.pixelWidth,
                "pixelHeight": record.pixelHeight,
                "isFavorite": record.isFavorite,
                "isHidden": record.isHidden,
                "hasAdjustments": record.hasAdjustments,
                "representsBurst": record.representsBurst,
                "burstSelectionTypes": Int(record.burstSelectionTypes.rawValue),
                "mediaSubtypes": Int(record.mediaSubtypes.rawValue),
                "sourceType": Int(record.sourceType.rawValue),
                "playbackStyle": record.playbackStyle.rawValue,
                "filename": record.filename,
                "uniformTypeIdentifier": record.uniformTypeIdentifier,
            ]
            if let creationDate = record.creationDate {
                row["creationDate"] = creationDate.timeIntervalSince1970
            }
            if let modificationDate = record.modificationDate {
                row["modificationDate"] = modificationDate.timeIntervalSince1970
            }
            if let burstIdentifier = record.burstIdentifier {
                row["burstIdentifier"] = burstIdentifier
            }
            if let adjustment = record.adjustmentFormatIdentifier {
                row["adjustmentFormatIdentifier"] = adjustment
            }
            if let resourcePath = record.resourcePath {
                row["resourcePath"] = resourcePath
            }
            assets.append(row)
        }
        var albums: [[String: Any]] = []
        for identifier in state.albumOrder {
            guard let record = state.albums[identifier] else { continue }
            var row: [String: Any] = [
                "localIdentifier": record.localIdentifier,
                "title": record.title,
                "type": record.type.rawValue,
                "subtype": record.subtype.rawValue,
                "assetIdentifiers": record.assetIdentifiers,
            ]
            if let startDate = record.startDate {
                row["startDate"] = startDate.timeIntervalSince1970
            }
            if let endDate = record.endDate {
                row["endDate"] = endDate.timeIntervalSince1970
            }
            albums.append(row)
        }
        var lists: [[String: Any]] = []
        for identifier in state.listOrder {
            guard let record = state.lists[identifier] else { continue }
            lists.append([
                "localIdentifier": record.localIdentifier,
                "title": record.title,
                "type": record.type.rawValue,
                "subtype": record.subtype.rawValue,
                "childIdentifiers": record.childIdentifiers,
            ])
        }
        return [
            "version": 1,
            "changeToken": state.changeToken,
            "assets": assets,
            "albums": albums,
            "lists": lists,
        ]
    }
}

struct PhotosAppliedChange {
    var insertedAssetIdentifiers: [String]
    var removedAssetIdentifiers: [String]
    var changedAssetIdentifiers: [String]
    var insertedAlbumIdentifiers: [String]
    var removedAlbumIdentifiers: [String]
    var changedAlbumIdentifiers: [String]
    var token: Int

    var isEmpty: Bool {
        insertedAssetIdentifiers.isEmpty && removedAssetIdentifiers.isEmpty
            && changedAssetIdentifiers.isEmpty && insertedAlbumIdentifiers.isEmpty
            && removedAlbumIdentifiers.isEmpty && changedAlbumIdentifiers.isEmpty
    }
}

enum PhotosPendingOperation {
    case createAsset(PHAssetChangeRequest)
    case updateAsset(PHAssetChangeRequest)
    case deleteAssets([String])
    case createAlbum(PHAssetCollectionChangeRequest)
    case updateAlbum(PHAssetCollectionChangeRequest)
    case deleteAlbums([String])
    case createList(PHCollectionListChangeRequest)
    case updateList(PHCollectionListChangeRequest)
    case deleteLists([String])
}

final class PhotosChangeSessionState: NSObject {
    var operations: [PhotosPendingOperation] = []
}

enum PhotosChangeSession {
    private static let key = "org.openuikit.Photos.changeSession"

    static var current: PhotosChangeSessionState? {
        Thread.current.threadDictionary[key] as? PhotosChangeSessionState
    }

    static func begin(allowsDelete: Bool) {
        _ = allowsDelete
        Thread.current.threadDictionary[key] = PhotosChangeSessionState()
    }

    static func record(_ operation: PhotosPendingOperation) {
        current?.operations.append(operation)
    }

    static func take() -> [PhotosPendingOperation] {
        let operations = current?.operations ?? []
        Thread.current.threadDictionary[key] = nil
        return operations
    }
}

func photosReadAccessGranted() -> Bool {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    return status == .authorized || status == .limited
}

func photosWriteAccessGranted() -> Bool {
    if photosReadAccessGranted() {
        return true
    }
    let addOnly = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    return addOnly == .authorized || addOnly == .limited
}

func photosNewLocalIdentifier() -> String {
    "\(UUID().uuidString)/L0/001"
}

func photosPlaybackStyle(for mediaType: PHAssetMediaType) -> PHAsset.PlaybackStyle {
    switch mediaType {
    case .video:
        return .video
    case .image:
        return .image
    default:
        return .unsupported
    }
}

func photosUTI(forFilename name: String) -> String {
    let lower = name.lowercased()
    if lower.hasSuffix(".png") { return "public.png" }
    if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") { return "public.jpeg" }
    if lower.hasSuffix(".heic") { return "public.heic" }
    if lower.hasSuffix(".mov") { return "com.apple.quicktime-movie" }
    if lower.hasSuffix(".mp4") { return "public.mpeg-4" }
    if lower.hasSuffix(".m4v") { return "com.apple.m4v-video" }
    return "public.data"
}

func photosImagePixelSize(from data: Data) -> (Int, Int)? {
    let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    if data.count >= 24 {
        var isPNG = true
        for index in pngSignature.indices {
            if data[index] != pngSignature[index] {
                isPNG = false
                break
            }
        }
        if isPNG {
            let width = photosReadUInt32BE(data, offset: 16)
            let height = photosReadUInt32BE(data, offset: 20)
            return (Int(width), Int(height))
        }
    }
    if data.count >= 4, data[0] == 0xFF, data[1] == 0xD8 {
        var offset = 2
        while offset + 9 < data.count {
            guard data[offset] == 0xFF else { return nil }
            let marker = data[offset + 1]
            if marker == 0xD9 || marker == 0xDA {
                break
            }
            let length = Int(photosReadUInt16BE(data, offset: offset + 2))
            if marker == 0xC0 || marker == 0xC1 || marker == 0xC2 {
                if offset + 8 < data.count {
                    let height = Int(photosReadUInt16BE(data, offset: offset + 5))
                    let width = Int(photosReadUInt16BE(data, offset: offset + 7))
                    return (width, height)
                }
                return nil
            }
            if length < 2 {
                return nil
            }
            offset += 2 + length
        }
    }
    return nil
}

func photosReadUInt32BE(_ data: Data, offset: Int) -> UInt32 {
    UInt32(data[offset]) << 24
        | UInt32(data[offset + 1]) << 16
        | UInt32(data[offset + 2]) << 8
        | UInt32(data[offset + 3])
}

func photosReadUInt16BE(_ data: Data, offset: Int) -> UInt16 {
    UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
}

func photosSmartAlbumSubtypes() -> [PHAssetCollectionSubtype] {
    [
        .smartAlbumGeneric,
        .smartAlbumPanoramas,
        .smartAlbumVideos,
        .smartAlbumFavorites,
        .smartAlbumTimelapses,
        .smartAlbumAllHidden,
        .smartAlbumRecentlyAdded,
        .smartAlbumBursts,
        .smartAlbumSlomoVideos,
        .smartAlbumUserLibrary,
        .smartAlbumSelfPortraits,
        .smartAlbumScreenshots,
        .smartAlbumDepthEffect,
        .smartAlbumLivePhotos,
        .smartAlbumAnimated,
        .smartAlbumLongExposures,
        .smartAlbumUnableToUpload,
        .smartAlbumRAW,
        .smartAlbumCinematic,
        .smartAlbumSpatial,
        .smartAlbumScreenRecordings,
    ]
}

func photosSmartAlbumTitle(_ subtype: PHAssetCollectionSubtype) -> String {
    switch subtype {
    case .smartAlbumUserLibrary: return "Recents"
    case .smartAlbumFavorites: return "Favorites"
    case .smartAlbumVideos: return "Videos"
    case .smartAlbumAllHidden: return "Hidden"
    case .smartAlbumPanoramas: return "Panoramas"
    case .smartAlbumTimelapses: return "Timelapses"
    case .smartAlbumRecentlyAdded: return "Recently Added"
    case .smartAlbumBursts: return "Bursts"
    case .smartAlbumSlomoVideos: return "Slo-mo"
    case .smartAlbumSelfPortraits: return "Selfies"
    case .smartAlbumScreenshots: return "Screenshots"
    case .smartAlbumDepthEffect: return "Portrait"
    case .smartAlbumLivePhotos: return "Live Photos"
    case .smartAlbumAnimated: return "Animated"
    case .smartAlbumLongExposures: return "Long Exposure"
    case .smartAlbumUnableToUpload: return "Unable to Upload"
    case .smartAlbumRAW: return "RAW"
    case .smartAlbumCinematic: return "Cinematic"
    case .smartAlbumSpatial: return "Spatial"
    case .smartAlbumScreenRecordings: return "Screen Recordings"
    case .smartAlbumGeneric: return "Generic"
    default: return "Smart Album"
    }
}

func photosAssetMatchesSmartAlbum(_ asset: PHAsset, subtype: PHAssetCollectionSubtype) -> Bool {
    switch subtype {
    case .smartAlbumUserLibrary:
        return asset.sourceType.contains(.typeUserLibrary) && !asset.isHidden
    case .smartAlbumFavorites:
        return asset.isFavorite && !asset.isHidden
    case .smartAlbumVideos:
        return asset.mediaType == .video && !asset.isHidden
    case .smartAlbumAllHidden:
        return asset.isHidden
    case .smartAlbumPanoramas:
        return asset.mediaSubtypes.contains(.photoPanorama)
    case .smartAlbumTimelapses:
        return asset.mediaSubtypes.contains(.videoTimelapse)
    case .smartAlbumBursts:
        return asset.representsBurst
    case .smartAlbumSlomoVideos:
        return asset.mediaSubtypes.contains(.videoHighFrameRate)
    case .smartAlbumScreenshots:
        return asset.mediaSubtypes.contains(.photoScreenshot)
    case .smartAlbumDepthEffect:
        return asset.mediaSubtypes.contains(.photoDepthEffect)
    case .smartAlbumLivePhotos:
        return asset.mediaSubtypes.contains(.photoLive)
    case .smartAlbumAnimated:
        return asset.playbackStyle == .imageAnimated
    case .smartAlbumCinematic:
        return asset.mediaSubtypes.contains(.videoCinematic)
    case .smartAlbumSpatial:
        return asset.mediaSubtypes.contains(.spatialMedia)
    case .smartAlbumScreenRecordings:
        return asset.mediaSubtypes.contains(.videoScreenRecording)
    case .smartAlbumRecentlyAdded,
        .smartAlbumSelfPortraits,
        .smartAlbumLongExposures,
        .smartAlbumUnableToUpload,
        .smartAlbumRAW,
        .smartAlbumGeneric:
        // Darwin membership for these subtypes is unobserved on this host.
        return false
    default:
        return false
    }
}

func photosMakeSmartAlbum(_ subtype: PHAssetCollectionSubtype) -> PHAssetCollection {
    let assets = PhotosLibraryStore.allAssets().filter { photosAssetMatchesSmartAlbum($0, subtype: subtype) }
    return PHAssetCollection(
        localIdentifier: "openuikit.smart.\(subtype.rawValue)",
        title: photosSmartAlbumTitle(subtype),
        type: .smartAlbum,
        subtype: subtype,
        estimatedAssetCount: assets.count,
        assetIdentifiers: assets.map(\.localIdentifier)
    )
}

func photosPredicateObject(for asset: PHAsset) -> NSMutableDictionary {
    let object = NSMutableDictionary()
    object["mediaType"] = NSNumber(value: asset.mediaType.rawValue)
    object["mediaSubtypes"] = NSNumber(value: asset.mediaSubtypes.rawValue)
    object["pixelWidth"] = NSNumber(value: asset.pixelWidth)
    object["pixelHeight"] = NSNumber(value: asset.pixelHeight)
    object["duration"] = NSNumber(value: asset.duration)
    object["isFavorite"] = NSNumber(value: asset.isFavorite)
    object["isHidden"] = NSNumber(value: asset.isHidden)
    object["representsBurst"] = NSNumber(value: asset.representsBurst)
    object["localIdentifier"] = asset.localIdentifier
    if let creationDate = asset.creationDate {
        object["creationDate"] = creationDate
    }
    if let modificationDate = asset.modificationDate {
        object["modificationDate"] = modificationDate
    }
    if let burstIdentifier = asset.burstIdentifier {
        object["burstIdentifier"] = burstIdentifier
    }
    return object
}

#if !os(Linux)
func photosAssetValue(_ asset: PHAsset, key: String) -> Any? {
    switch key {
    case "mediaType": return asset.mediaType.rawValue
    case "mediaSubtypes": return asset.mediaSubtypes.rawValue
    case "pixelWidth": return asset.pixelWidth
    case "pixelHeight": return asset.pixelHeight
    case "duration": return asset.duration
    case "isFavorite": return asset.isFavorite
    case "isHidden": return asset.isHidden
    case "representsBurst": return asset.representsBurst
    case "localIdentifier": return asset.localIdentifier
    case "creationDate": return asset.creationDate
    case "modificationDate": return asset.modificationDate
    case "burstIdentifier": return asset.burstIdentifier
    case "addedDate": return asset.addedDate
    default: return nil
    }
}

func photosCompareAssets(_ left: PHAsset, _ right: PHAsset, key: String, ascending: Bool) -> Bool {
    let leftValue = photosAssetValue(left, key: key)
    let rightValue = photosAssetValue(right, key: key)
    let ordered: ComparisonResult
    switch (leftValue, rightValue) {
    case let (l as Date, r as Date):
        ordered = l.compare(r)
    case let (l as String, r as String):
        ordered = (l as NSString).compare(r)
    case let (l as Int, r as Int):
        ordered = l < r ? .orderedAscending : (l > r ? .orderedDescending : .orderedSame)
    case let (l as TimeInterval, r as TimeInterval):
        ordered = l < r ? .orderedAscending : (l > r ? .orderedDescending : .orderedSame)
    case let (l as Bool, r as Bool):
        ordered = (l ? 1 : 0) < (r ? 1 : 0) ? .orderedAscending
            : ((l ? 1 : 0) > (r ? 1 : 0) ? .orderedDescending : .orderedSame)
    case let (l as UInt, r as UInt):
        ordered = l < r ? .orderedAscending : (l > r ? .orderedDescending : .orderedSame)
    default:
        return false
    }
    if ordered == .orderedSame {
        return false
    }
    return ascending ? ordered == .orderedAscending : ordered == .orderedDescending
}
#endif

func photosMatchesPredicate(_ asset: PHAsset, _ predicate: NSPredicate?) -> Bool {
    guard let predicate else { return true }
    return predicate.evaluate(with: photosPredicateObject(for: asset))
}

func photosApplyFetch(
    matching predicate: (PHAsset) -> Bool,
    options: PHFetchOptions?
) -> [PHAsset] {
    guard photosReadAccessGranted() else { return [] }
    var assets = PhotosLibraryStore.allAssets().filter(predicate)
    if options?.includeHiddenAssets != true {
        assets = assets.filter { !$0.isHidden }
    }
    if let sourceTypes = options?.includeAssetSourceTypes, sourceTypes.rawValue != 0 {
        assets = assets.filter { !$0.sourceType.intersection(sourceTypes).isEmpty }
    }
    if let hostPredicate = options?.hostPredicateEvaluates {
        assets = assets.filter(hostPredicate)
    } else if let predicate = options?.predicate {
        assets = assets.filter { photosMatchesPredicate($0, predicate) }
    }
    if let ascending = options?.hostSortsByCreationDateAscending {
        assets.sort {
            let left = $0.creationDate ?? .distantPast
            let right = $1.creationDate ?? .distantPast
            return ascending ? left < right : left > right
        }
    } else if let descriptors = options?.sortDescriptors {
        #if os(Linux)
        _ = descriptors
        #else
        assets.sort { left, right in
            for descriptor in descriptors {
                guard let key = descriptor.key, !key.isEmpty else { continue }
                if photosCompareAssets(left, right, key: key, ascending: descriptor.ascending) {
                    return true
                }
                if photosCompareAssets(right, left, key: key, ascending: descriptor.ascending) {
                    return false
                }
            }
            return false
        }
        #endif
    }
    if let limit = options?.fetchLimit, limit > 0, assets.count > limit {
        assets.removeLast(assets.count - limit)
    }
    return assets
}

func photosFetchAssets(
    matching predicate: @escaping (PHAsset) -> Bool,
    options: PHFetchOptions?
) -> PHFetchResult<PHAsset> {
    let objects = photosApplyFetch(matching: predicate, options: options)
    return PHFetchResult(objects) {
        photosApplyFetch(matching: predicate, options: options)
    }
}

func photosNotifyObservers(_ applied: PhotosAppliedChange) {
    guard !applied.isEmpty else { return }
    let change = PHChange(applied: applied)
    let observers = PhotosLibraryStore.changeObservers()
    PhotosLibraryStore.callbackQueue.async {
        for observer in observers {
            observer.photoLibraryDidChange(change)
        }
    }
}

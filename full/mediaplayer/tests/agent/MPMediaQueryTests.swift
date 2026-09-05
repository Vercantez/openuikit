import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

func testLibraryAuthorization() {
    MPMediaLibrary.openuikit_resetLibrary()
    precondition(MPMediaLibrary.authorizationStatus() == .denied)
    precondition(MPMediaLibrary.default() === MPMediaLibrary.default())
    precondition(MPMediaLibrary.supportsSecureCoding)
    precondition(MPMediaLibrary.default().lastModifiedDate == Date(timeIntervalSince1970: 0))
    MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()
    MPMediaLibrary.default().endGeneratingLibraryChangeNotifications()
    precondition(MPMediaQuery.songs().items == nil)

    let sem = DispatchSemaphore(value: 0)
    var seen: MPMediaLibraryAuthorizationStatus?
    var returned = false
    MPMediaLibrary.requestAuthorization { status in
        precondition(returned)
        seen = status
        sem.signal()
    }
    returned = true
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(seen == .denied)

    let addSem = DispatchSemaphore(value: 0)
    var addErr = false
    Task {
        do {
            _ = try await MPMediaLibrary.default().addItem(withProductID: "x")
            fatalError("addItem should fail")
        } catch {
            addErr = MPError.notSupported ~= error
            addSem.signal()
        }
    }
    precondition(addSem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(addErr)
}

func testQueryPredicateGroupingFixture() {
    MPMediaLibrary.openuikit_resetLibrary()
    precondition(MPMediaQuery().groupingType == .title)
    precondition(MPMediaQuery.songs().groupingType == .title)
    precondition(MPMediaQuery.albums().groupingType == .album)
    precondition(MPMediaQuery.artists().groupingType == .artist)
    precondition(MPMediaQuery.composers().groupingType == .composer)
    precondition(MPMediaQuery.genres().groupingType == .genre)
    precondition(MPMediaQuery.playlists().groupingType == .playlist)
    precondition(MPMediaQuery.podcasts().groupingType == .podcastTitle)
    precondition(MPMediaQuery.songs().items == nil)

    let a = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Karma Police",
        MPMediaItemPropertyArtist: "Radiohead",
        MPMediaItemPropertyAlbumTitle: "OK Computer",
        MPMediaItemPropertyPersistentID: UInt64(11),
        MPMediaItemPropertyMediaType: MPMediaType.music,
        MPMediaItemPropertyPlayCount: 4,
        MPMediaItemPropertyGenre: "Rock",
    ])
    let b = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Paranoid Android",
        MPMediaItemPropertyArtist: "Radiohead",
        MPMediaItemPropertyAlbumTitle: "OK Computer",
        MPMediaItemPropertyPersistentID: UInt64(12),
        MPMediaItemPropertyMediaType: MPMediaType.music,
        MPMediaItemPropertyGenre: "Rock",
    ])
    let c = MPMediaItem(hostProperties: [
        MPMediaItemPropertyTitle: "Yesterday",
        MPMediaItemPropertyArtist: "The Beatles",
        MPMediaItemPropertyAlbumTitle: "Help!",
        MPMediaItemPropertyPersistentID: UInt64(21),
        MPMediaItemPropertyMediaType: MPMediaType.music,
        MPMediaItemPropertyGenre: "Pop",
        MPMediaItemPropertyIsCompilation: false,
    ])
    MPMediaLibrary.openuikit_loadFixtureLibrary([a, b, c])
    precondition(MPMediaLibrary.authorizationStatus() == .authorized)
    precondition(MPMediaQuery.songs().items?.count == 3)

    let equal = MPMediaPropertyPredicate(value: "Radiohead", forProperty: MPMediaItemPropertyArtist)
    precondition(equal.property == MPMediaItemPropertyArtist)
    precondition(equal.comparisonType == .equalTo)
    let byArtist = MPMediaQuery(filterPredicates: [equal])
    precondition(byArtist.items?.count == 2)
    precondition(byArtist.filterPredicates?.contains(equal) == true)

    let contains = MPMediaPropertyPredicate(
        value: "Police",
        forProperty: MPMediaItemPropertyTitle,
        comparisonType: .contains
    )
    precondition(contains.comparisonType == .contains)
    let byTitle = MPMediaQuery(filterPredicates: [contains])
    precondition(byTitle.items?.count == 1)
    precondition(byTitle.items?.first?.title == "Karma Police")

    let albums = MPMediaQuery.albums()
    precondition(albums.collections?.count == 2)
    precondition(albums.itemSections == nil)
    precondition(albums.collectionSections == nil)

    let audiobooks = MPMediaQuery.audiobooks()
    precondition(audiobooks.filterPredicates?.isEmpty == false)
    let compilations = MPMediaQuery.compilations()
    precondition(compilations.filterPredicates?.isEmpty == false)
    audiobooks.addFilterPredicate(contains)
    audiobooks.removeFilterPredicate(contains)
    let copied = byArtist.copy() as! MPMediaQuery
    precondition(copied.groupingType == byArtist.groupingType)
    precondition(copied.filterPredicates?.count == byArtist.filterPredicates?.count)
    precondition(MPMediaQuery.supportsSecureCoding)
    precondition(MPMediaPredicate.supportsSecureCoding)

    MPMediaLibrary.openuikit_resetLibrary()
    precondition(MPMediaLibrary.authorizationStatus() == .denied)
    precondition(MPMediaQuery.songs().items == nil)
}

func testPlaylistFailClosed() {
    let meta = MPMediaPlaylistCreationMetadata(name: "Mix")
    meta.descriptionText = "x"
    meta.authorDisplayName = "me"
    precondition(meta.name == "Mix")
    precondition(meta.descriptionText == "x")
    precondition(meta.authorDisplayName == "me")
    let item = MPMediaItem(hostProperties: [MPMediaItemPropertyTitle: "A"])
    let playlist = MPMediaPlaylist(items: [item])
    precondition(playlist.count == 1)
    precondition(playlist.name == nil)
    precondition(playlist.authorDisplayName == nil)
    precondition(playlist.cloudGlobalID == nil)
    precondition(playlist.descriptionText == nil)
    precondition(playlist.seedItems == nil)
    precondition(playlist.playlistAttributes.isEmpty)
    let addSem = DispatchSemaphore(value: 0)
    var addFailed = false
    Task {
        do {
            try await playlist.addItem(withProductID: "x")
            fatalError("playlist addItem should fail")
        } catch {
            addFailed = MPError.notSupported ~= error
        }
        do {
            try await playlist.add([item])
            fatalError("playlist add should fail")
        } catch {
            addFailed = addFailed && (MPError.notSupported ~= error)
            addSem.signal()
        }
    }
    precondition(addSem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(addFailed)

    let getSem = DispatchSemaphore(value: 0)
    var getFailed = false
    Task {
        do {
            _ = try await MPMediaLibrary.default().getPlaylist(
                with: UUID(),
                creationMetadata: meta
            )
            fatalError("getPlaylist should fail")
        } catch {
            getFailed = MPError.notSupported ~= error
            getSem.signal()
        }
    }
    precondition(getSem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(getFailed)
}

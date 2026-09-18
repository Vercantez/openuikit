import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MusicKit

func testAsyncDataRequest() async {
    do {
        _ = try await MusicDataRequest.currentCountryCode
        preconditionFailure("currentCountryCode should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    let request = MusicDataRequest(urlRequest: URLRequest(url: URL(string: "https://example.com")!))
    do {
        _ = try await request.response()
        preconditionFailure("data response should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAsyncCatalogResponses() async {
    do {
        _ = try await MusicCatalogSearchRequest(term: "Fleet Foxes", types: [Song.self]).response()
        preconditionFailure("catalog search response should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicCatalogChartsRequest(types: [Song.self]).response()
        preconditionFailure("charts response should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicCatalogResourceRequest<Song>().response()
        preconditionFailure("resource response should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicRecentlyPlayedRequest<Song>().response()
        preconditionFailure("recently played response should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicPersonalRecommendationsRequest().response()
        preconditionFailure("recommendations response should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicCatalogSearchSuggestionsRequest(term: "Fleet").response()
        preconditionFailure("suggestions response should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAsyncLibraryResponses() async {
    do {
        _ = try await MusicLibraryRequest<Song>().response()
        preconditionFailure("library response should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicLibrarySectionedRequest<Genre, Song>().response()
        preconditionFailure("sectioned response should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicLibrarySearchRequest(term: "Fleet", types: [Song.self]).response()
        preconditionFailure("library search response should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAsyncPlayerControls() async {
    let player = ApplicationMusicPlayer.shared
    do {
        try await player.prepareToPlay()
        preconditionFailure("prepareToPlay should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .playbackUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await player.skipToNextEntry()
        preconditionFailure("skipToNextEntry should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .playbackUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await player.skipToPreviousEntry()
        preconditionFailure("skipToPreviousEntry should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .playbackUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await player.play()
        preconditionFailure("play should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .playbackUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAsyncQueueInsert() async throws {
    let song = Song(id: "1", title: "One")
    let other = Song(id: "2", title: "Two")
    let queue = MusicPlayer.Queue([] as [MusicPlayer.Queue.Entry])
    precondition(queue.currentEntry == nil)
    try await queue.insert(MusicPlayer.Queue.Entry(other), position: .tail)
    precondition(queue.currentEntry != nil)
    try await queue.insert(song, position: .afterCurrentEntry)
    try await queue.insert([song, other], position: .tail)
    try await queue.insert([MusicPlayer.Queue.Entry(song)], position: .afterCurrentEntry)
    precondition(queue.currentEntry != nil)
}

func testAsyncLibraryMutations() async {
    let song = Song(id: "1", title: "One")
    let playlist = Playlist(id: "p", name: "P")
    do {
        _ = try await MusicLibrary.shared.createPlaylist(name: "New")
        preconditionFailure("createPlaylist should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicLibrary.shared.createPlaylist(name: "New", items: [song])
        preconditionFailure("createPlaylist with items should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await MusicLibrary.shared.add(song)
        preconditionFailure("add should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicLibrary.shared.add(song, to: playlist)
        preconditionFailure("add to playlist should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicLibrary.shared.edit(playlist, name: "Renamed")
        preconditionFailure("edit should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicLibrary.shared.edit(playlist, name: "Renamed", items: [song])
        preconditionFailure("edit with items should throw")
    } catch let error as MusicLibrary.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAsyncTokenProviders() async {
    do {
        _ = try await DefaultMusicTokenProvider().developerToken(options: [])
        preconditionFailure("developerToken should throw")
    } catch let error as MusicTokenRequestError {
        precondition(error == .developerTokenRequestFailed)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    let provider: any MusicDeveloperTokenProvider = DefaultMusicTokenProvider()
    do {
        _ = try await provider.developerToken(options: [])
        preconditionFailure("protocol developerToken should throw")
    } catch let error as MusicTokenRequestError {
        precondition(error == .developerTokenRequestFailed)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await MusicUserTokenProvider().userToken(for: "dev-token", options: [])
        preconditionFailure("userToken should throw")
    } catch let error as MusicTokenRequestError {
        precondition(error == .userNotSignedIn)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAsyncAuthorizationSubscription() async {
    MusicAuthorization._openuikit_setCurrentStatus(.notDetermined)
    let status = await MusicAuthorization.request()
    precondition(status == .denied)
    MusicAuthorization._openuikit_setCurrentStatus(.notDetermined)
    do {
        _ = try await MusicSubscription.current
        preconditionFailure("subscription current should throw")
    } catch let error as MusicSubscription.Error {
        precondition(error == .permissionDenied)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    var iterator = MusicSubscription.Updates.Iterator()
    let next = await iterator.next()
    precondition(next == nil)
    let collection = MusicItemCollection<Song>(items: [Song(id: "1", title: "One")])
    do {
        _ = try await collection.nextBatch()
        preconditionFailure("nextBatch should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try await collection.nextBatch(limit: 10)
        preconditionFailure("nextBatch with limit should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

private func expectWithThrows(_ body: () async throws -> Void) async {
    do {
        try await body()
        preconditionFailure("with should throw")
    } catch let error as MusicKitPortableError {
        precondition(error == .catalogUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAsyncWithBatchA() async {
    let song = Song(id: "1", title: "One")
    await expectWithThrows { _ = try await song.with(PartialMusicAsyncProperty<Song>(property: "title")) }
    await expectWithThrows { _ = try await song.with([PartialMusicAsyncProperty<Song>(property: "title")]) }
    await expectWithThrows {
        _ = try await song.with(
            PartialMusicAsyncProperty<Song>(property: "title"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await song.with(
            [PartialMusicAsyncProperty<Song>(property: "title")],
            preferredSource: .library
        )
    }
    let album = Album(id: "a", title: "A")
    await expectWithThrows { _ = try await album.with(PartialMusicAsyncProperty<Album>(property: "title")) }
    await expectWithThrows { _ = try await album.with([PartialMusicAsyncProperty<Album>(property: "title")]) }
    await expectWithThrows {
        _ = try await album.with(
            PartialMusicAsyncProperty<Album>(property: "title"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await album.with(
            [PartialMusicAsyncProperty<Album>(property: "title")],
            preferredSource: .library
        )
    }
    let artist = Artist(id: "ar", name: "R")
    await expectWithThrows { _ = try await artist.with(PartialMusicAsyncProperty<Artist>(property: "name")) }
    await expectWithThrows { _ = try await artist.with([PartialMusicAsyncProperty<Artist>(property: "name")]) }
    await expectWithThrows {
        _ = try await artist.with(
            PartialMusicAsyncProperty<Artist>(property: "name"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await artist.with(
            [PartialMusicAsyncProperty<Artist>(property: "name")],
            preferredSource: .library
        )
    }
    let genre = Genre(id: "g", name: "G")
    await expectWithThrows { _ = try await genre.with(PartialMusicAsyncProperty<Genre>(property: "name")) }
    await expectWithThrows { _ = try await genre.with([PartialMusicAsyncProperty<Genre>(property: "name")]) }
    await expectWithThrows {
        _ = try await genre.with(
            PartialMusicAsyncProperty<Genre>(property: "name"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await genre.with(
            [PartialMusicAsyncProperty<Genre>(property: "name")],
            preferredSource: .library
        )
    }
}

func testAsyncWithBatchB() async {
    let station = Station(id: "s", name: "S")
    await expectWithThrows { _ = try await station.with(PartialMusicAsyncProperty<Station>(property: "name")) }
    await expectWithThrows { _ = try await station.with([PartialMusicAsyncProperty<Station>(property: "name")]) }
    await expectWithThrows {
        _ = try await station.with(
            PartialMusicAsyncProperty<Station>(property: "name"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await station.with(
            [PartialMusicAsyncProperty<Station>(property: "name")],
            preferredSource: .library
        )
    }
    let playlist = Playlist(id: "p", name: "P")
    await expectWithThrows { _ = try await playlist.with(PartialMusicAsyncProperty<Playlist>(property: "name")) }
    await expectWithThrows { _ = try await playlist.with([PartialMusicAsyncProperty<Playlist>(property: "name")]) }
    await expectWithThrows {
        _ = try await playlist.with(
            PartialMusicAsyncProperty<Playlist>(property: "name"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await playlist.with(
            [PartialMusicAsyncProperty<Playlist>(property: "name")],
            preferredSource: .library
        )
    }
    let entry = Playlist.Entry(
        id: "e",
        title: "E",
        item: .song(Song(id: "1", title: "One"))
    )
    await expectWithThrows {
        _ = try await entry.with(PartialMusicAsyncProperty<Playlist.Entry>(property: "title"))
    }
    await expectWithThrows {
        _ = try await entry.with([PartialMusicAsyncProperty<Playlist.Entry>(property: "title")])
    }
    await expectWithThrows {
        _ = try await entry.with(
            PartialMusicAsyncProperty<Playlist.Entry>(property: "title"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await entry.with(
            [PartialMusicAsyncProperty<Playlist.Entry>(property: "title")],
            preferredSource: .library
        )
    }
    let entryItem = Playlist.Entry.Item.song(Song(id: "1", title: "One"))
    await expectWithThrows {
        _ = try await entryItem.with(PartialMusicAsyncProperty<Playlist.Entry.Item>(property: "title"))
    }
    await expectWithThrows {
        _ = try await entryItem.with([PartialMusicAsyncProperty<Playlist.Entry.Item>(property: "title")])
    }
    await expectWithThrows {
        _ = try await entryItem.with(
            PartialMusicAsyncProperty<Playlist.Entry.Item>(property: "title"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await entryItem.with(
            [PartialMusicAsyncProperty<Playlist.Entry.Item>(property: "title")],
            preferredSource: .library
        )
    }
    let video = MusicVideo(id: "v", title: "V")
    await expectWithThrows {
        _ = try await video.with(PartialMusicAsyncProperty<MusicVideo>(property: "title"))
    }
    await expectWithThrows {
        _ = try await video.with([PartialMusicAsyncProperty<MusicVideo>(property: "title")])
    }
    await expectWithThrows {
        _ = try await video.with(
            PartialMusicAsyncProperty<MusicVideo>(property: "title"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await video.with(
            [PartialMusicAsyncProperty<MusicVideo>(property: "title")],
            preferredSource: .library
        )
    }
}

func testAsyncWithBatchC() async {
    let curator = Curator(id: "c", name: "C")
    await expectWithThrows { _ = try await curator.with(PartialMusicAsyncProperty<Curator>(property: "name")) }
    await expectWithThrows { _ = try await curator.with([PartialMusicAsyncProperty<Curator>(property: "name")]) }
    await expectWithThrows {
        _ = try await curator.with(
            PartialMusicAsyncProperty<Curator>(property: "name"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await curator.with(
            [PartialMusicAsyncProperty<Curator>(property: "name")],
            preferredSource: .library
        )
    }
    let label = RecordLabel(id: "r", name: "R")
    await expectWithThrows {
        _ = try await label.with(PartialMusicAsyncProperty<RecordLabel>(property: "name"))
    }
    await expectWithThrows {
        _ = try await label.with([PartialMusicAsyncProperty<RecordLabel>(property: "name")])
    }
    await expectWithThrows {
        _ = try await label.with(
            PartialMusicAsyncProperty<RecordLabel>(property: "name"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await label.with(
            [PartialMusicAsyncProperty<RecordLabel>(property: "name")],
            preferredSource: .library
        )
    }
    let show = RadioShow(id: "rs", name: "RS")
    await expectWithThrows {
        _ = try await show.with(PartialMusicAsyncProperty<RadioShow>(property: "name"))
    }
    await expectWithThrows {
        _ = try await show.with([PartialMusicAsyncProperty<RadioShow>(property: "name")])
    }
    await expectWithThrows {
        _ = try await show.with(
            PartialMusicAsyncProperty<RadioShow>(property: "name"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await show.with(
            [PartialMusicAsyncProperty<RadioShow>(property: "name")],
            preferredSource: .library
        )
    }
    let track = Track.song(Song(id: "1", title: "One"))
    await expectWithThrows { _ = try await track.with(PartialMusicAsyncProperty<Track>(property: "title")) }
    await expectWithThrows { _ = try await track.with([PartialMusicAsyncProperty<Track>(property: "title")]) }
    await expectWithThrows {
        _ = try await track.with(
            PartialMusicAsyncProperty<Track>(property: "title"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await track.with(
            [PartialMusicAsyncProperty<Track>(property: "title")],
            preferredSource: .library
        )
    }
    let queueItem = MusicPlayer.Queue.Entry.Item.song(Song(id: "1", title: "One"))
    await expectWithThrows {
        _ = try await queueItem.with(
            PartialMusicAsyncProperty<MusicPlayer.Queue.Entry.Item>(property: "title")
        )
    }
    await expectWithThrows {
        _ = try await queueItem.with(
            [PartialMusicAsyncProperty<MusicPlayer.Queue.Entry.Item>(property: "title")]
        )
    }
    await expectWithThrows {
        _ = try await queueItem.with(
            PartialMusicAsyncProperty<MusicPlayer.Queue.Entry.Item>(property: "title"),
            preferredSource: .catalog
        )
    }
    await expectWithThrows {
        _ = try await queueItem.with(
            [PartialMusicAsyncProperty<MusicPlayer.Queue.Entry.Item>(property: "title")],
            preferredSource: .library
        )
    }
}

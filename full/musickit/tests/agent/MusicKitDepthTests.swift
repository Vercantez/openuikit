import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MusicKit

func testCatalogSearchResponse() {
    let json = """
    {"results":{"songs":{"data":[{"id":"1","type":"songs","attributes":{"name":"Helplessness Blues","artistName":"Fleet Foxes"}}]},"albums":{"data":[{"id":"2","type":"albums","attributes":{"name":"Helplessness Blues","artistName":"Fleet Foxes"}}]},"artists":{"data":[{"id":"3","type":"artists","attributes":{"name":"Fleet Foxes"}}]},"playlists":{"data":[{"id":"4","type":"playlists","attributes":{"name":"Favorites"}}]},"music-videos":{"data":[{"id":"5","type":"music-videos","attributes":{"name":"White Winter Hymnal","artistName":"Fleet Foxes"}}]},"stations":{"data":[{"id":"6","type":"stations","attributes":{"name":"Apple Music 1"}}]},"record-labels":{"data":[{"id":"7","type":"record-labels","attributes":{"name":"Sub Pop"}}]},"apple-curators":{"data":[{"id":"8","type":"apple-curators","attributes":{"name":"Apple Music"}}]},"radio-shows":{"data":[{"id":"9","type":"radio-shows","attributes":{"name":"The Show"}}]},"top":{"data":[{"id":"1","type":"songs","attributes":{"name":"Helplessness Blues","artistName":"Fleet Foxes"}}]}}}
    """
    let decoded = try! JSONDecoder().decode(MusicCatalogSearchResponse.self, from: Data(json.utf8))
    precondition(decoded.songs.count == 1)
    precondition(decoded.songs[0].title == "Helplessness Blues")
    precondition(decoded.albums.count == 1)
    precondition(decoded.artists[0].name == "Fleet Foxes")
    precondition(decoded.playlists[0].name == "Favorites")
    precondition(decoded.musicVideos[0].title == "White Winter Hymnal")
    precondition(decoded.stations[0].name == "Apple Music 1")
    precondition(decoded.recordLabels[0].name == "Sub Pop")
    precondition(decoded.curators[0].name == "Apple Music")
    precondition(decoded.radioShows[0].name == "The Show")
    precondition(decoded.topResults.count == 1)
    precondition(decoded.description.contains("songs: 1"))
    precondition(decoded.debugDescription == decoded.description)
    precondition(decoded == decoded)
    var hasher = Hasher()
    decoded.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicCatalogSearchResponse.self, from: encoded)
    precondition(roundTrip.songs.count == 1)
    let empty = MusicCatalogSearchResponse()
    precondition(empty.songs.isEmpty)
}

func testCatalogSearchTopResults() {
    let song = MusicCatalogSearchResponse.TopResult.song(Song(id: "1", title: "S", artistName: "A"))
    let album = MusicCatalogSearchResponse.TopResult.album(Album(id: "2", title: "L", artistName: "A"))
    let artist = MusicCatalogSearchResponse.TopResult.artist(Artist(id: "3", name: "A"))
    let playlist = MusicCatalogSearchResponse.TopResult.playlist(Playlist(id: "4", name: "P"))
    let video = MusicCatalogSearchResponse.TopResult.musicVideo(MusicVideo(id: "5", title: "V", artistName: "A"))
    let station = MusicCatalogSearchResponse.TopResult.station(Station(id: "6", name: "St"))
    let curator = MusicCatalogSearchResponse.TopResult.curator(Curator(id: "7", name: "C"))
    let label = MusicCatalogSearchResponse.TopResult.recordLabel(RecordLabel(id: "8", name: "L"))
    let show = MusicCatalogSearchResponse.TopResult.radioShow(RadioShow(id: "9", name: "R"))
    let id: MusicCatalogSearchResponse.TopResult.ID = song.id
    precondition(id.rawValue == "1")
    precondition(song.title == "S")
    precondition(album.title == "L")
    precondition(artist.title == "A")
    precondition(playlist.title == "P")
    precondition(video.title == "V")
    precondition(station.title == "St")
    precondition(curator.title == "C")
    precondition(label.title == "L")
    precondition(show.title == "R")
    precondition(song.artwork == nil)
    precondition(song.description == "S")
    precondition(song.debugDescription == "S")
    precondition(song == song)
    var hasher = Hasher()
    song.hash(into: &hasher)
    let payload = Data(#"{"id":"1","type":"songs","attributes":{"name":"S","artistName":"A"}}"#.utf8)
    let decoded = try! JSONDecoder().decode(MusicCatalogSearchResponse.TopResult.self, from: payload)
    precondition(decoded.id.rawValue == "1")
    let encoded = try! JSONEncoder().encode(decoded)
    precondition(!encoded.isEmpty)
}

func testPersonalRecommendation() {
    let json = """
    {"id":"rec-1","type":"personal-recommendation","attributes":{"title":{"stringForDisplay":"Made for You"},"reason":{"stringForDisplay":"Because you listened to Fleet Foxes"},"nextRefreshDate":"2020-01-15T12:00:00Z"},"relationships":{"contents":{"data":[{"id":"2","type":"albums","attributes":{"name":"Helplessness Blues","artistName":"Fleet Foxes"}},{"id":"4","type":"playlists","attributes":{"name":"Favorites"}},{"id":"6","type":"stations","attributes":{"name":"Apple Music 1"}}]}}}
    """
    let decoded = try! JSONDecoder().decode(MusicPersonalRecommendation.self, from: Data(json.utf8))
    let recID: MusicPersonalRecommendation.ID = decoded.id
    precondition(recID.rawValue == "rec-1")
    precondition(decoded.title == "Made for You")
    precondition(decoded.reason == "Because you listened to Fleet Foxes")
    precondition(decoded.nextRefreshDate != nil)
    precondition(decoded.items.count == 3)
    precondition(decoded.albums.count == 1)
    precondition(decoded.albums[0].title == "Helplessness Blues")
    precondition(decoded.playlists.count == 1)
    precondition(decoded.stations.count == 1)
    precondition(decoded.types.count == 3)
    precondition(decoded.description == "Made for You")
    precondition(decoded.debugDescription == decoded.description)
    precondition(decoded == decoded)
    var hasher = Hasher()
    decoded.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicPersonalRecommendation.self, from: encoded)
    precondition(roundTrip.id.rawValue == "rec-1")
    let constructed = MusicPersonalRecommendation(id: "x", title: "T", reason: "R")
    precondition(constructed.items.isEmpty)
    precondition(constructed.types.count == 3)
}

func testPersonalRecommendationItems() {
    let albumItem = MusicPersonalRecommendation.Item.album(Album(id: "2", title: "HB", artistName: "FF"))
    let stationItem = MusicPersonalRecommendation.Item.station(Station(id: "6", name: "Live"))
    let playlistItem = MusicPersonalRecommendation.Item.playlist(Playlist(id: "4", name: "Mix"))
    let songItem = MusicPersonalRecommendation.Item.song(Song(id: "1", title: "S", artistName: "FF"))
    let itemID: MusicPersonalRecommendation.Item.ID = albumItem.id
    precondition(itemID.rawValue == "2")
    precondition(albumItem.title == "HB")
    precondition(albumItem.subtitle == "FF")
    precondition(stationItem.title == "Live")
    precondition(stationItem.subtitle == nil)
    precondition(playlistItem.title == "Mix")
    precondition(songItem.title == "S")
    precondition(songItem.subtitle == "FF")
    precondition(albumItem.artwork == nil)
    precondition(albumItem.description == "HB")
    precondition(albumItem.debugDescription == "HB")
    precondition(albumItem == albumItem)
    var hasher = Hasher()
    albumItem.hash(into: &hasher)
    let payload = Data(#"{"id":"2","type":"albums","attributes":{"name":"HB","artistName":"FF"}}"#.utf8)
    let decoded = try! JSONDecoder().decode(MusicPersonalRecommendation.Item.self, from: payload)
    precondition(decoded.title == "HB")
    let encoded = try! JSONEncoder().encode(decoded)
    precondition(!encoded.isEmpty)
    let mixed = MusicPersonalRecommendation(
        id: "mix",
        items: MusicItemCollection([albumItem, songItem])
    )
    precondition(mixed.types.count == 2)
}

func testPersonalRecommendationsRequest() {
    let seed = MusicPersonalRecommendation(id: "rec-1", title: "Made for You")
    var request = MusicPersonalRecommendationsRequest(refreshing: [seed])
    request.limit = 10
    request.offset = 2
    precondition(request.limit == 10)
    precondition(request.offset == 2)
    let copy = MusicPersonalRecommendationsRequest(refreshing: [seed])
    var other = copy
    other.limit = 10
    other.offset = 2
    precondition(request == other)
    precondition(request != MusicPersonalRecommendationsRequest())
    var hasher = Hasher()
    request.hash(into: &hasher)
    let empty = MusicPersonalRecommendationsRequest()
    precondition(empty.limit == nil)
    _ = MusicPersonalRecommendationItem.self
}

func testPersonalRecommendationsResponse() {
    let rec = MusicPersonalRecommendation(id: "rec-1", title: "Made for You")
    let response = MusicPersonalRecommendationsResponse(
        recommendations: MusicItemCollection([rec])
    )
    precondition(response.recommendations.count == 1)
    precondition(response.description.contains("1"))
    precondition(response.debugDescription == response.description)
    precondition(response == response)
    var hasher = Hasher()
    response.hash(into: &hasher)
    let json = """
    {"data":[{"id":"rec-1","type":"personal-recommendation","attributes":{"title":"Made for You"}}]}
    """
    let decoded = try! JSONDecoder().decode(MusicPersonalRecommendationsResponse.self, from: Data(json.utf8))
    precondition(decoded.recommendations[0].id.rawValue == "rec-1")
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicPersonalRecommendationsResponse.self, from: encoded)
    precondition(roundTrip.recommendations.count == 1)
}

func testLibrarySearchResponse() {
    let json = """
    {"results":{"songs":{"data":[{"id":"1","type":"songs","attributes":{"name":"S","artistName":"A"}}]},"albums":{"data":[{"id":"2","type":"albums","attributes":{"name":"L","artistName":"A"}}]},"artists":{"data":[{"id":"3","type":"artists","attributes":{"name":"A"}}]},"playlists":{"data":[{"id":"4","type":"playlists","attributes":{"name":"P"}}]},"music-videos":{"data":[{"id":"5","type":"music-videos","attributes":{"name":"V","artistName":"A"}}]},"top":{"data":[{"id":"1","type":"songs","attributes":{"name":"S","artistName":"A"}}]}}}
    """
    let decoded = try! JSONDecoder().decode(MusicLibrarySearchResponse.self, from: Data(json.utf8))
    precondition(decoded.songs.count == 1)
    precondition(decoded.albums.count == 1)
    precondition(decoded.artists.count == 1)
    precondition(decoded.playlists.count == 1)
    precondition(decoded.musicVideos.count == 1)
    precondition(decoded.topResults.count == 1)
    precondition(decoded.description.contains("songs: 1"))
    precondition(decoded.debugDescription == decoded.description)
    precondition(decoded == decoded)
    var hasher = Hasher()
    decoded.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicLibrarySearchResponse.self, from: encoded)
    precondition(roundTrip.playlists[0].name == "P")
    let empty = MusicLibrarySearchResponse()
    precondition(empty.songs.isEmpty)
}

func testLibrarySearchTopResults() {
    let song = MusicLibrarySearchResponse.TopResult.song(Song(id: "1", title: "S", artistName: "A"))
    let album = MusicLibrarySearchResponse.TopResult.album(Album(id: "2", title: "L", artistName: "A"))
    let artist = MusicLibrarySearchResponse.TopResult.artist(Artist(id: "3", name: "A"))
    let playlist = MusicLibrarySearchResponse.TopResult.playlist(Playlist(id: "4", name: "P"))
    let video = MusicLibrarySearchResponse.TopResult.musicVideo(MusicVideo(id: "5", title: "V", artistName: "A"))
    let id: MusicLibrarySearchResponse.TopResult.ID = song.id
    precondition(id.rawValue == "1")
    precondition(song.title == "S")
    precondition(album.title == "L")
    precondition(artist.title == "A")
    precondition(playlist.title == "P")
    precondition(video.title == "V")
    precondition(song.artwork == nil)
    precondition(song.description == "S")
    precondition(song.debugDescription == "S")
    precondition(song == song)
    var hasher = Hasher()
    song.hash(into: &hasher)
    let payload = Data(#"{"id":"5","type":"music-videos","attributes":{"name":"V","artistName":"A"}}"#.utf8)
    let decoded = try! JSONDecoder().decode(MusicLibrarySearchResponse.TopResult.self, from: payload)
    precondition(decoded.id.rawValue == "5")
    let encoded = try! JSONEncoder().encode(decoded)
    precondition(!encoded.isEmpty)
}

func testSectionedRequestFilters() {
    var request = MusicLibrarySectionedRequest<Album, Song>()
    request.limit = 20
    request.offset = 4
    request.includeOnlyDownloadedContent = true
    request.filterItems(text: "helpless")
    precondition(request._openuikit_itemFilterText == "helpless")
    request.filterItems(matching: \LibrarySongFilter.title, equalTo: "Helplessness Blues")
    precondition(request._openuikit_itemFilterText == "Helplessness Blues")
    request.filterItems(matching: \LibrarySongFilter.albumTitle, equalTo: Optional("HB"))
    request.filterItems(matching: \LibrarySongFilter.title, contains: "Blue")
    request.filterItems(matching: \LibrarySongFilter.albumTitle, contains: "Help")
    let album = Album(id: "2", title: "HB", artistName: "FF")
    request.filterItems(matching: \LibrarySongFilter.albums, contains: album)
    request.filterItems(matching: \LibrarySongFilter.id, memberOf: [MusicItemID("1")])
    request.filterItems(matching: \LibrarySongFilter.albumTitle, memberOf: [Optional("HB")])
    request.sortItems(by: \LibrarySongSortProperties.title, ascending: false)
    precondition(request._openuikit_itemSortAscending == false)
    request.filterSections(text: "folk")
    request.filterSections(matching: \LibraryAlbumFilter.title, equalTo: "HB")
    request.filterSections(matching: \LibraryAlbumFilter.isCompilation, equalTo: Optional(false))
    request.filterSections(matching: \LibraryAlbumFilter.title, contains: "Help")
    request.filterSections(matching: \LibraryAlbumFilter.artistName, contains: "Fleet")
    request.filterSections(matching: \LibraryAlbumFilter.id, memberOf: [MusicItemID("2")])
    request.filterSections(matching: \LibraryAlbumFilter.isCompilation, memberOf: [Optional(false)])
    request.sortSections(by: \LibraryAlbumSortProperties.title, ascending: true)
    precondition(request.limit == 20)
    precondition(request.offset == 4)
    precondition(request.includeOnlyDownloadedContent)
    precondition(request._openuikit_sectionFilterText != nil)
    precondition(request._openuikit_sectionSortAscending)
    let blank = MusicLibrarySectionedRequest<Album, Song>()
    precondition(blank.limit == 0)
}

func testLibrarySection() {
    let genre = Genre(id: "g1", name: "Folk")
    let song = Song(id: "1", title: "S", artistName: "A")
    let section = MusicLibrarySection(id: "g1", section: genre, items: MusicItemCollection([song]))
    let sectionID: MusicLibrarySection<Genre, Song>.ID = section.id
    precondition(sectionID.rawValue == "g1")
    precondition(section.items.count == 1)
    precondition(section.name == "Folk")
    precondition(section.description.contains("g1"))
    precondition(section.debugDescription == section.description)
    precondition(section == section)
    var hasher = Hasher()
    section.hash(into: &hasher)
    let response = MusicLibrarySectionedResponse(sections: [section])
    precondition(response.sections.count == 1)
    precondition(response.description.contains("1"))
    precondition(response.debugDescription == response.description)
    precondition(response == response)
    response.hash(into: &hasher)
    _ = MusicLibrarySectionRequestable.self
}

func testSuggestionsResponse() {
    let json = """
    {"results":{"suggestions":[{"displayTerm":"Fleet Foxes","searchTerm":"fleet foxes"}],"topResults":{"data":[{"id":"1","type":"songs","attributes":{"name":"S","artistName":"A"}}]}}}
    """
    let decoded = try! JSONDecoder().decode(MusicCatalogSearchSuggestionsResponse.self, from: Data(json.utf8))
    precondition(decoded.suggestions.count == 1)
    let suggestion = decoded.suggestions[0]
    let suggestionID: MusicCatalogSearchSuggestionsResponse.Suggestion.ID = suggestion.id
    precondition(suggestionID == "fleet foxes")
    precondition(suggestion.displayTerm == "Fleet Foxes")
    precondition(suggestion.searchTerm == "fleet foxes")
    precondition(suggestion.description == "Fleet Foxes")
    precondition(suggestion.debugDescription == "Fleet Foxes")
    precondition(suggestion == suggestion)
    var hasher = Hasher()
    suggestion.hash(into: &hasher)
    let encodedSuggestion = try! JSONEncoder().encode(suggestion)
    let roundSuggestion = try! JSONDecoder().decode(
        MusicCatalogSearchSuggestionsResponse.Suggestion.self,
        from: encodedSuggestion
    )
    precondition(roundSuggestion.searchTerm == "fleet foxes")
    precondition(decoded.topResults.count == 1)
    let alias: MusicCatalogSearchSuggestionsResponse.TopResult = decoded.topResults[0]
    precondition(alias.title == "S")
    precondition(decoded.description.contains("1"))
    precondition(decoded.debugDescription == decoded.description)
    precondition(decoded == decoded)
    decoded.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicCatalogSearchSuggestionsResponse.self, from: encoded)
    precondition(roundTrip.suggestions[0].displayTerm == "Fleet Foxes")
    let constructed = MusicCatalogSearchSuggestionsResponse.Suggestion(displayTerm: "A", searchTerm: "a")
    precondition(constructed.id == "a")
}

func testMusicDataError() {
    let url = URL(string: "https://api.music.apple.com/v1/catalog/us/search")!
    let http = HTTPURLResponse(
        url: url,
        statusCode: 401,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
    )!
    let original = MusicDataResponse(data: Data(#"{"errors":[]}"#.utf8), urlResponse: http)
    let error = MusicDataRequest.Error(
        id: "err.auth",
        title: "Unauthorized",
        detailText: "Missing developer token",
        code: 40101,
        status: 401,
        source: .parameter("term"),
        originalResponse: original
    )
    precondition(error.id == "err.auth")
    precondition(error.title == "Unauthorized")
    precondition(error.detailText == "Missing developer token")
    precondition(error.code == 40101)
    precondition(error.status == 401)
    precondition(error.description == "Unauthorized")
    if case .parameter(let name) = error.source {
        precondition(name == "term")
    } else {
        precondition(false)
    }
    precondition(error.originalResponse.statusCodeMatches(401))
}

func testMusicDataResponse() {
    let url = URL(string: "https://api.music.apple.com/v1/me/library")!
    let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
    let payload = Data(#"{"data":[]}"#.utf8)
    let response = MusicDataResponse(data: payload, urlResponse: http)
    precondition(response.data == payload)
    precondition(response.urlResponse.statusCode == 200)
    precondition(response.description.contains("200"))
    precondition(response.debugDescription == response.description)
    precondition(response == response)
    var hasher = Hasher()
    response.hash(into: &hasher)
}

func testChartsResponse() {
    let json = """
    {"results":{"songs":[{"id":"most-played","chart":"most-played","name":"Top Songs","data":[{"id":"1","type":"songs","attributes":{"name":"S","artistName":"A"}}]}],"albums":[{"chart":"city-top","name":"City Top Albums","data":[{"id":"2","type":"albums","attributes":{"name":"L","artistName":"A"}}]}],"playlists":[{"chart":"daily-global-top","name":"Daily Global Top","data":[{"id":"4","type":"playlists","attributes":{"name":"P"}}]}],"music-videos":[{"chart":"most-played","name":"Top Videos","data":[{"id":"5","type":"music-videos","attributes":{"name":"V","artistName":"A"}}]}]}}
    """
    let decoded = try! JSONDecoder().decode(MusicCatalogChartsResponse.self, from: Data(json.utf8))
    precondition(decoded.songCharts.count == 1)
    let chart = decoded.songCharts[0]
    let chartID: MusicCatalogChart<Song>.ID = chart.id
    precondition(chartID == "most-played")
    precondition(chart.kind == .mostPlayed)
    precondition(chart.title == "Top Songs")
    precondition(chart.items.count == 1)
    precondition(chart.description == "Top Songs")
    precondition(chart.debugDescription == "Top Songs")
    precondition(chart == chart)
    var hasher = Hasher()
    chart.hash(into: &hasher)
    precondition(decoded.albumCharts[0].kind == .cityTop)
    precondition(decoded.playlistCharts[0].kind == .dailyGlobalTop)
    precondition(decoded.musicVideoCharts[0].title == "Top Videos")
    precondition(decoded.description.contains("songs: 1"))
    precondition(decoded.debugDescription == decoded.description)
    precondition(decoded == decoded)
    decoded.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicCatalogChartsResponse.self, from: encoded)
    precondition(roundTrip.songCharts[0].kind == .mostPlayed)
    let encodedChart = try! JSONEncoder().encode(chart)
    let roundChart = try! JSONDecoder().decode(MusicCatalogChart<Song>.self, from: encodedChart)
    precondition(roundChart.title == "Top Songs")
    let constructed = MusicCatalogChart<Song>(id: "x", kind: .mostPlayed, title: "T")
    precondition(constructed.items.isEmpty)
}

func testLibrarySongSortAndFilter() {
    let albums = MusicItemCollection([Album(id: "2", title: "HB", artistName: "FF")])
    let genres = MusicItemCollection([Genre(id: "g", name: "Folk")])
    let artists = MusicItemCollection([Artist(id: "3", name: "Fleet Foxes")])
    let probe = LibrarySongProbe(
        id: "1",
        title: "Helplessness Blues",
        albumTitle: "Helplessness Blues",
        artistName: "Fleet Foxes",
        composerName: "Robin Pecknold",
        discNumber: 1,
        trackNumber: 2,
        duration: 303,
        playCount: 9,
        lastPlayedDate: Date(timeIntervalSince1970: 1_600_000_000),
        libraryAddedDate: Date(timeIntervalSince1970: 1_500_000_000),
        albums: albums,
        genres: genres,
        artists: artists
    )
    inspectLibrarySongFilter(probe)
    inspectLibrarySongSort(probe)
}

func testLibraryTrackSort() {
    let played = Date(timeIntervalSince1970: 1_700_000_000)
    let added = Date(timeIntervalSince1970: 1_600_000_000)
    let probe = LibraryTrackProbe(
        title: "S",
        albumTitle: "HB",
        artistName: "FF",
        discNumber: 1,
        trackNumber: 3,
        lastPlayedDate: played,
        libraryAddedDate: added,
        duration: 200,
        playCount: 4
    )
    inspectLibraryTrackSort(probe)
}

func testLibraryMusicVideoSortAndFilter() {
    let albums = MusicItemCollection([Album(id: "2", title: "HB", artistName: "FF")])
    let genres = MusicItemCollection([Genre(id: "g", name: "Folk")])
    let artists = MusicItemCollection([Artist(id: "3", name: "Fleet Foxes")])
    let probe = LibraryMusicVideoProbe(
        id: "v1",
        title: "White Winter Hymnal",
        albumTitle: "HB",
        artistName: "Fleet Foxes",
        trackNumber: 1,
        duration: 180,
        playCount: 2,
        lastPlayedDate: Date(timeIntervalSince1970: 1_600_000_000),
        libraryAddedDate: Date(timeIntervalSince1970: 1_500_000_000),
        albums: albums,
        genres: genres,
        artists: artists
    )
    inspectLibraryMusicVideoFilter(probe)
    inspectLibraryMusicVideoSort(probe)
}

func testSubscriptionUpdates() {
    let updates = MusicSubscription.subscriptionUpdates
    let iterator = updates.makeAsyncIterator()
    let asyncIterator: MusicSubscription.Updates.AsyncIterator = iterator
    _ = asyncIterator
    let elementType: MusicSubscription.Updates.Element.Type = MusicSubscription.self
    let iteratorElement: MusicSubscription.Updates.Iterator.Element.Type = MusicSubscription.self
    precondition(elementType == MusicSubscription.self)
    precondition(iteratorElement == MusicSubscription.self)
    _ = MusicSubscription.Updates()
    _ = MusicSubscription.Updates.Iterator()
}

func testMusicPlayerClass() {
    let player: MusicPlayer = ApplicationMusicPlayer.shared
    precondition(player.state.playbackStatus == .stopped || player.state.playbackStatus == .paused
        || player.state.playbackStatus == .playing || player.state.playbackStatus == .interrupted
        || player.state.playbackStatus == .seekingForward || player.state.playbackStatus == .seekingBackward)
    player.pause()
    player.stop()
}

private struct LibrarySongProbe: LibrarySongFilter, LibrarySongSortProperties {
    var id: MusicItemID
    var title: String
    var albumTitle: String?
    var artistName: String?
    var composerName: String?
    var discNumber: Int?
    var trackNumber: Int?
    var duration: TimeInterval?
    var playCount: Int?
    var lastPlayedDate: Date?
    var libraryAddedDate: Date?
    var albums: MusicItemCollection<Album>?
    var genres: MusicItemCollection<Genre>?
    var artists: MusicItemCollection<Artist>?
}

private struct LibraryTrackProbe: LibraryTrackSortProperties {
    var title: String
    var albumTitle: String?
    var artistName: String?
    var discNumber: Int?
    var trackNumber: Int?
    var lastPlayedDate: Date?
    var libraryAddedDate: Date?
    var duration: TimeInterval?
    var playCount: Int?
}

private struct LibraryMusicVideoProbe: LibraryMusicVideoFilter, LibraryMusicVideoSortProperties {
    var id: MusicItemID
    var title: String
    var albumTitle: String?
    var artistName: String?
    var trackNumber: Int?
    var duration: TimeInterval?
    var playCount: Int?
    var lastPlayedDate: Date?
    var libraryAddedDate: Date?
    var albums: MusicItemCollection<Album>?
    var genres: MusicItemCollection<Genre>?
    var artists: MusicItemCollection<Artist>?
}

private func inspectLibrarySongFilter(_ item: some LibrarySongFilter) {
    precondition(item.title == "Helplessness Blues")
    precondition(item.albumTitle == "Helplessness Blues")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.composerName == "Robin Pecknold")
    precondition(item.id.rawValue == "1")
    precondition(item.albums?.count == 1)
    precondition(item.genres?.count == 1)
    precondition(item.artists?.count == 1)
}

private func inspectLibrarySongSort(_ item: some LibrarySongSortProperties) {
    precondition(item.title == "Helplessness Blues")
    precondition(item.albumTitle == "Helplessness Blues")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.composerName == "Robin Pecknold")
    precondition(item.discNumber == 1)
    precondition(item.trackNumber == 2)
    precondition(item.duration == 303)
    precondition(item.playCount == 9)
    precondition(item.lastPlayedDate != nil)
    precondition(item.libraryAddedDate != nil)
}

private func inspectLibraryTrackSort(_ item: some LibraryTrackSortProperties) {
    precondition(item.title == "S")
    precondition(item.albumTitle == "HB")
    precondition(item.artistName == "FF")
    precondition(item.discNumber == 1)
    precondition(item.trackNumber == 3)
    precondition(item.duration == 200)
    precondition(item.playCount == 4)
    precondition(item.lastPlayedDate != nil)
    precondition(item.libraryAddedDate != nil)
}

private func inspectLibraryMusicVideoFilter(_ item: some LibraryMusicVideoFilter) {
    precondition(item.id.rawValue == "v1")
    precondition(item.title == "White Winter Hymnal")
    precondition(item.albumTitle == "HB")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.albums?.count == 1)
    precondition(item.genres?.count == 1)
    precondition(item.artists?.count == 1)
}

private func inspectLibraryMusicVideoSort(_ item: some LibraryMusicVideoSortProperties) {
    precondition(item.title == "White Winter Hymnal")
    precondition(item.albumTitle == "HB")
    precondition(item.artistName == "Fleet Foxes")
    precondition(item.trackNumber == 1)
    precondition(item.duration == 180)
    precondition(item.playCount == 2)
    precondition(item.lastPlayedDate != nil)
    precondition(item.libraryAddedDate != nil)
}

private extension MusicDataResponse {
    func statusCodeMatches(_ code: Int) -> Bool {
        urlResponse.statusCode == code
    }
}

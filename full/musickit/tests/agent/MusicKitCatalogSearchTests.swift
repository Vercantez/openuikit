import Foundation
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
    _ = decoded.hashValue
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
    _ = song.hashValue
    let payload = Data(#"{"id":"1","type":"songs","attributes":{"name":"S","artistName":"A"}}"#.utf8)
    let decoded = try! JSONDecoder().decode(MusicCatalogSearchResponse.TopResult.self, from: payload)
    precondition(decoded.id.rawValue == "1")
    let encoded = try! JSONEncoder().encode(decoded)
    precondition(!encoded.isEmpty)
}

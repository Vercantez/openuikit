import Foundation
import MusicKit

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
    _ = decoded.hashValue
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
    _ = song.hashValue
    let payload = Data(#"{"id":"5","type":"music-videos","attributes":{"name":"V","artistName":"A"}}"#.utf8)
    let decoded = try! JSONDecoder().decode(MusicLibrarySearchResponse.TopResult.self, from: payload)
    precondition(decoded.id.rawValue == "5")
    let encoded = try! JSONEncoder().encode(decoded)
    precondition(!encoded.isEmpty)
}

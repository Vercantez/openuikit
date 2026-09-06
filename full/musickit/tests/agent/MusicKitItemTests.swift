import Foundation
import MusicKit

func testSongDecoding() {
    let json = """
    {"id":"1440742676","type":"songs","attributes":{"name":"Helplessness Blues","artistName":"Fleet Foxes","albumName":"Helplessness Blues","durationInMillis":303000,"isrc":"USUM71106461","hasLyrics":true,"trackNumber":1,"discNumber":1,"releaseDate":"2011-05-03","genreNames":["Alternative"],"contentRating":"clean","artwork":{"url":"https://ex/{w}x{h}.jpg","width":3000,"height":3000}}}
    """
    let song = try! JSONDecoder().decode(Song.self, from: Data(json.utf8))
    precondition(song.id.rawValue == "1440742676")
    precondition(song.title == "Helplessness Blues")
    precondition(song.artistName == "Fleet Foxes")
    precondition(song.albumTitle == "Helplessness Blues")
    precondition(song.duration == 303)
    precondition(song.isrc == "USUM71106461")
    precondition(song.hasLyrics == true)
    precondition(song.trackNumber == 1)
    precondition(song.discNumber == 1)
    precondition(song.genreNames == ["Alternative"])
    precondition(song.contentRating == .clean)
    precondition(song.artwork?.url(width: 10, height: 10) != nil)
    precondition(song.description == song.title)
    precondition(song.debugDescription.contains("1440742676"))
    let portable = Song(id: "1", title: "A", artistName: "B", duration: 12, isrc: "X", hasLyrics: true)
    precondition(portable.playParameters != nil)
    precondition(portable == portable)
    var hasher = Hasher()
    portable.hash(into: &hasher)
    _ = portable.hashValue
    let encoded = try! JSONEncoder().encode(song)
    let roundTrip = try! JSONDecoder().decode(Song.self, from: encoded)
    precondition(roundTrip.title == "Helplessness Blues")
}

func testAlbumDecoding() {
    let json = """
    {"id":"1440742675","type":"albums","attributes":{"name":"Helplessness Blues","artistName":"Fleet Foxes","trackCount":12,"upc":"00602527708414","isCompilation":false,"isSingle":false}}
    """
    let album = try! JSONDecoder().decode(Album.self, from: Data(json.utf8))
    precondition(album.id.rawValue == "1440742675")
    precondition(album.title == "Helplessness Blues")
    precondition(album.artistName == "Fleet Foxes")
    precondition(album.trackCount == 12)
    precondition(album.upc == "00602527708414")
    precondition(album.isCompilation == false)
    precondition(album.isSingle == false)
    let constructed = Album(id: "9", title: "T", artistName: "A", trackCount: 8)
    precondition(constructed.playParameters != nil)
    precondition(constructed.description == "T")
    precondition(constructed == constructed)
    var hasher = Hasher()
    constructed.hash(into: &hasher)
    _ = constructed.hashValue
}

func testArtistGenreStation() {
    let artist = Artist(id: "a1", name: "Fleet Foxes")
    precondition(artist.name == "Fleet Foxes")
    precondition(artist.description == "Fleet Foxes")
    let genre = Genre(id: "g1", name: "Folk", parent: Genre(id: "g0", name: "Root"))
    precondition(genre.parent?.name == "Root")
    let station = Station(id: "s1", name: "Apple Music 1", isLive: true)
    precondition(station.isLive)
    precondition(artist == artist)
    precondition(genre == genre)
    precondition(station == station)
    var hasher = Hasher()
    artist.hash(into: &hasher)
    genre.hash(into: &hasher)
    station.hash(into: &hasher)
    _ = artist.hashValue
    _ = genre.hashValue
    _ = station.hashValue
}

func testPlaylistAndVideo() {
    let playlist = Playlist(id: "p1", name: "Favorites", kind: .userShared)
    precondition(playlist.kind == .userShared)
    let entry = Playlist.Entry(id: "e1", title: "Track", artistName: "Art", position: 3)
    precondition(entry.position == 3)
    let video = MusicVideo(id: "v1", title: "White Winter Hymnal", artistName: "Fleet Foxes")
    precondition(video.title == "White Winter Hymnal")
    let track = Track.song(Song(id: "1", title: "Song", artistName: "Art"))
    precondition(track.title == "Song")
    precondition(track.artistName == "Art")
    let entryItem = Playlist.Entry.Item.song(Song(id: "1", title: "Song", artistName: "Art"))
    precondition(entryItem.artistName == "Art")
    precondition(playlist == playlist)
    precondition(entry == entry)
    precondition(video == video)
    precondition(track == track)
    precondition(entryItem == entryItem)
    var hasher = Hasher()
    playlist.hash(into: &hasher)
    entry.hash(into: &hasher)
    video.hash(into: &hasher)
    track.hash(into: &hasher)
    entryItem.hash(into: &hasher)
    _ = playlist.hashValue
    _ = entry.hashValue
    _ = video.hashValue
    _ = track.hashValue
    _ = entryItem.hashValue
}

func testCuratorLabelShow() {
    let curator = Curator(id: "c1", name: "Apple Music", kind: .editorial)
    precondition(curator.kind == .editorial)
    let label = RecordLabel(id: "l1", name: "Sub Pop")
    precondition(label.name == "Sub Pop")
    let show = RadioShow(id: "r1", name: "The Show", hostName: "Zane")
    precondition(show.hostName == "Zane")
    let recent = RecentlyPlayedMusicItem.album(Album(id: "9", title: "HB", artistName: "FF"))
    precondition(recent.title == "HB")
    precondition(recent.subtitle == "FF")
    precondition(curator == curator)
    precondition(label == label)
    precondition(show == show)
    precondition(recent == recent)
    var hasher = Hasher()
    curator.hash(into: &hasher)
    label.hash(into: &hasher)
    show.hash(into: &hasher)
    recent.hash(into: &hasher)
    _ = curator.hashValue
    _ = label.hashValue
    _ = show.hashValue
    _ = recent.hashValue
}

func testMusicItemCollection() {
    let songs = [
        Song(id: "1", title: "A", artistName: "X"),
        Song(id: "2", title: "B", artistName: "Y")
    ]
    var collection = MusicItemCollection(songs)
    precondition(collection.count == 2)
    precondition(collection.startIndex == 0)
    precondition(collection.endIndex == 2)
    precondition(collection[0].title == "A")
    precondition(collection.index(after: 0) == 1)
    precondition(collection.index(before: 1) == 0)
    precondition(collection.index(0, offsetBy: 1) == 1)
    precondition(collection.index(0, offsetBy: 5, limitedBy: 2) == nil)
    precondition(collection.distance(from: 0, to: 2) == 2)
    var i = 0
    collection.formIndex(after: &i)
    precondition(i == 1)
    collection.formIndex(before: &i)
    precondition(i == 0)
    let slice = collection[0..<1]
    precondition(slice.count == 1)
    collection += MusicItemCollection([Song(id: "3", title: "C", artistName: "Z")])
    precondition(collection.count == 3)
    precondition(collection == collection)
    collection.title = "Hits"
    precondition(collection.description.contains("Hits"))
    var hasher = Hasher()
    collection.hash(into: &hasher)
    _ = collection.hashValue
}

func testSupportingTypes() {
    let notes = EditorialNotes(name: "N", short: "S", tagline: "T", standard: "Long")
    precondition(notes.description == "Long")
    precondition(notes.debugDescription == "Long")
    let preview = PreviewAsset(url: URL(string: "https://example.com/p.m4a"))
    precondition(preview.description.contains("example.com"))
    let params = PlayParameters(id: "99", kind: "song")
    precondition(params == params)
    let titled = TitledSection(id: "sec", title: "New")
    precondition(titled.title == "New")
    precondition(PartialMusicProperty<Song>.albums.name == "albums")
    precondition(PartialMusicProperty<Album>.tracks.name == "tracks")
    precondition(PartialMusicProperty<Artist>.topSongs.name == "top-songs")
    let property: AnyMusicProperty = PartialMusicProperty<Song>.albums
    precondition(notes == notes)
    precondition(preview == preview)
    precondition(titled == titled)
    precondition(property == property)
    var hasher = Hasher()
    notes.hash(into: &hasher)
    preview.hash(into: &hasher)
    params.hash(into: &hasher)
    titled.hash(into: &hasher)
    property.hash(into: &hasher)
    _ = notes.hashValue
    _ = preview.hashValue
    _ = params.hashValue
    _ = titled.hashValue
    _ = property.hashValue
}

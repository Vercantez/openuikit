import Foundation
import MusicKit

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
    _ = decoded.hashValue
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
    _ = albumItem.hashValue
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
    _ = request.hashValue
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
    _ = response.hashValue
    let json = """
    {"data":[{"id":"rec-1","type":"personal-recommendation","attributes":{"title":"Made for You"}}]}
    """
    let decoded = try! JSONDecoder().decode(MusicPersonalRecommendationsResponse.self, from: Data(json.utf8))
    precondition(decoded.recommendations[0].id.rawValue == "rec-1")
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicPersonalRecommendationsResponse.self, from: encoded)
    precondition(roundTrip.recommendations.count == 1)
}

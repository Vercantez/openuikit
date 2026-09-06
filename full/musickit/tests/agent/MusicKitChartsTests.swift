import Foundation
import MusicKit

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
    _ = chart.hashValue
    precondition(decoded.albumCharts[0].kind == .cityTop)
    precondition(decoded.playlistCharts[0].kind == .dailyGlobalTop)
    precondition(decoded.musicVideoCharts[0].title == "Top Videos")
    precondition(decoded.description.contains("songs: 1"))
    precondition(decoded.debugDescription == decoded.description)
    precondition(decoded == decoded)
    decoded.hash(into: &hasher)
    _ = decoded.hashValue
    let encoded = try! JSONEncoder().encode(decoded)
    let roundTrip = try! JSONDecoder().decode(MusicCatalogChartsResponse.self, from: encoded)
    precondition(roundTrip.songCharts[0].kind == .mostPlayed)
    let encodedChart = try! JSONEncoder().encode(chart)
    let roundChart = try! JSONDecoder().decode(MusicCatalogChart<Song>.self, from: encodedChart)
    precondition(roundChart.title == "Top Songs")
    let constructed = MusicCatalogChart<Song>(id: "x", kind: .mostPlayed, title: "T")
    precondition(constructed.items.isEmpty)
}

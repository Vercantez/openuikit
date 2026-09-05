import Foundation
import ShazamKit

func testSHMediaItemType() {
    let item = SHMediaItem(properties: [:])
    precondition(type(of: item) == SHMediaItem.self)
}

func testSHMediaItemInitProperties() {
    let item = SHMediaItem(properties: [
        .title: "Song",
        .artist: "Artist",
    ])
    precondition(item.title == "Song")
    precondition(item.artist == "Artist")
}

func testSHMediaItemSubscript() {
    let item = SHMediaItem(properties: [.title: "Indexed"])
    let value = item[.title]
    precondition(value as? String == "Indexed")
    precondition(item[.artist] is NSNull)
}

func testSHMediaItemShazamID() {
    let item = SHMediaItem(properties: [.shazamID: "shazam-1"])
    precondition(item.shazamID == "shazam-1")
}

func testSHMediaItemTitle() {
    precondition(SHMediaItem(properties: [.title: "Hello"]).title == "Hello")
}

func testSHMediaItemSubtitle() {
    precondition(SHMediaItem(properties: [.subtitle: "Sub"]).subtitle == "Sub")
}

func testSHMediaItemArtist() {
    precondition(SHMediaItem(properties: [.artist: "Ada"]).artist == "Ada")
}

func testSHMediaItemAppleMusicID() {
    precondition(SHMediaItem(properties: [.appleMusicID: "amp-1"]).appleMusicID == "amp-1")
}

func testSHMediaItemISRC() {
    precondition(SHMediaItem(properties: [.ISRC: "USRC17607839"]).isrc == "USRC17607839")
}

func testSHMediaItemWebURL() {
    let url = URL(string: "https://example.com/track")!
    precondition(SHMediaItem(properties: [.webURL: url]).webURL == url)
}

func testSHMediaItemAppleMusicURL() {
    let url = URL(string: "https://music.apple.com/x")!
    precondition(SHMediaItem(properties: [.appleMusicURL: url]).appleMusicURL == url)
}

func testSHMediaItemArtworkURL() {
    let url = URL(string: "https://example.com/art.png")!
    precondition(SHMediaItem(properties: [.artworkURL: url]).artworkURL == url)
}

func testSHMediaItemVideoURL() {
    let url = URL(string: "https://example.com/video")!
    precondition(SHMediaItem(properties: [.videoURL: url]).videoURL == url)
}

func testSHMediaItemExplicitContent() {
    precondition(SHMediaItem(properties: [:]).explicitContent == false)
    precondition(SHMediaItem(properties: [.explicitContent: true]).explicitContent == true)
}

func testSHMediaItemGenres() {
    precondition(SHMediaItem(properties: [:]).genres.isEmpty)
    precondition(SHMediaItem(properties: [.genres: ["Pop", "Rock"]]).genres == ["Pop", "Rock"])
}

func testSHMediaItemCreationDate() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    precondition(SHMediaItem(properties: [.creationDate: date]).creationDate == date)
}

func testSHMediaItemTimeRanges() {
    let ranges: [Range<TimeInterval>] = [1.0..<2.5]
    precondition(SHMediaItem(properties: [.timeRanges: ranges]).timeRanges == ranges)
}

func testSHMediaItemFrequencySkewRanges() {
    let ranges: [Range<Float>] = [0.1..<0.2]
    precondition(SHMediaItem(properties: [.frequencySkewRanges: ranges]).frequencySkewRanges == ranges)
}

func testSHMediaItemIDTypealias() {
    precondition(SHMediaItem.ID.self == UUID.self)
}

func testSHMediaItemUUID() {
    let item = SHMediaItem(properties: [:])
    precondition(item.id != UUID())
}

func testSHMediaItemInitCoder() {
    precondition(SHMediaItem(coder: NSCoder()) == nil)
}

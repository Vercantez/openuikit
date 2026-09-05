import Foundation
import ShazamKit

func testSHMediaItemPropertyType() {
    precondition(type(of: SHMediaItemProperty.title) == SHMediaItemProperty.self)
}

func testSHMediaItemPropertyConstants() {
    let constants: [(SHMediaItemProperty, String)] = [
        (.shazamID, "SHMediaItemShazamID"),
        (.title, "SHMediaItemTitle"),
        (.subtitle, "SHMediaItemSubtitle"),
        (.artist, "SHMediaItemArtist"),
        (.webURL, "SHMediaItemWebURL"),
        (.appleMusicID, "SHMediaItemAppleMusicID"),
        (.appleMusicURL, "SHMediaItemAppleMusicURL"),
        (.artworkURL, "SHMediaItemArtworkURL"),
        (.videoURL, "SHMediaItemVideoURL"),
        (.explicitContent, "SHMediaItemExplicitContent"),
        (.genres, "SHMediaItemGenres"),
        (.ISRC, "SHMediaItemISRC"),
        (.matchOffset, "SHMediaItemMatchOffset"),
        (.frequencySkew, "SHMediaItemFrequencySkew"),
        (.timeRanges, "SHMediaItemTimeRanges"),
        (.frequencySkewRanges, "SHMediaItemFrequencySkewRanges"),
        (.creationDate, "SHMediaItemCreationDate"),
        (.confidence, "SHMediaItemConfidence"),
    ]
    for (property, raw) in constants {
        precondition(property.rawValue == raw)
        precondition(SHMediaItemProperty(rawValue: raw) == property)
        precondition(SHMediaItemProperty(raw) == property)
    }
}

func testSHMediaItemPropertyInitRawValue() {
    let property = SHMediaItemProperty(rawValue: "custom.key")
    precondition(property.rawValue == "custom.key")
}

func testSHMediaItemPropertyInitString() {
    let property = SHMediaItemProperty("another.key")
    precondition(property.rawValue == "another.key")
}

func testSHMediaItemPropertyInequality() {
    precondition(SHMediaItemProperty.title != SHMediaItemProperty.artist)
    precondition(!(SHMediaItemProperty.title != SHMediaItemProperty.title))
}

func testSHMediaItemPropertyHashValue() {
    _ = SHMediaItemProperty.title.hashValue
    precondition(SHMediaItemProperty.title.hashValue == SHMediaItemProperty(rawValue: "SHMediaItemTitle").hashValue)
}

func testSHMediaItemPropertyHashInto() {
    var hasher = Hasher()
    SHMediaItemProperty.artist.hash(into: &hasher)
    _ = hasher.finalize()
}

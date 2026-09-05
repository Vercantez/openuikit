import Foundation
import MusicKit

func testMusicItemID() {
    let id = MusicItemID("154321")
    precondition(id.rawValue == "154321")
    precondition(id.description == "154321")
    let copy = MusicItemID(rawValue: "154321")
    precondition(copy == id)
    let literal: MusicItemID = "154321"
    precondition(literal == id)
    let decoded = try! JSONDecoder().decode(MusicItemID.self, from: Data("\"154321\"".utf8))
    precondition(decoded == id)
    let encoded = try! JSONEncoder().encode(id)
    precondition(String(data: encoded, encoding: .utf8) == "\"154321\"")
    var hasher = Hasher()
    id.hash(into: &hasher)
    _ = id.hashValue
}

func testArtworkURLAndColors() {
    let artwork = Artwork(
        urlTemplate: "https://is1-ssl.mzstatic.com/image/thumb/Music/{w}x{h}bb.jpg",
        maximumWidth: 3000,
        maximumHeight: 2000,
        alternateText: "Cover",
        backgroundColor: CGColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1),
        primaryTextColor: CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    )
    let url = artwork.url(width: 200, height: 100)
    precondition(url?.absoluteString == "https://is1-ssl.mzstatic.com/image/thumb/Music/200x100bb.jpg")
    precondition(artwork.maximumWidth == 3000)
    precondition(artwork.maximumHeight == 2000)
    precondition(artwork.alternateText == "Cover")
    precondition(artwork.backgroundColor?.red == 0.1)
    precondition(artwork.primaryTextColor?.green == 1)
    precondition(artwork.description.contains("mzstatic"))
    precondition(artwork.debugDescription == artwork.description)
    precondition(artwork == artwork)
    var hasher = Hasher()
    artwork.hash(into: &hasher)
    _ = artwork.hashValue
}

func testArtworkCodable() {
    let json = """
    {"url":"https://example.com/{w}x{h}.jpg","width":1400,"height":1400,"bgColor":"aabbcc","textColor1":"ffffff","textColor2":"eeeeee","textColor3":"dddddd","textColor4":"cccccc","text":"Art"}
    """
    let artwork = try! JSONDecoder().decode(Artwork.self, from: Data(json.utf8))
    precondition(artwork.maximumWidth == 1400)
    precondition(artwork.maximumHeight == 1400)
    precondition(artwork.alternateText == "Art")
    precondition(abs((artwork.backgroundColor?.red ?? 0) - 170.0 / 255.0) < 0.001)
    precondition(artwork.url(width: 40, height: 40)?.absoluteString == "https://example.com/40x40.jpg")
    let encoded = try! JSONEncoder().encode(artwork)
    let roundTrip = try! JSONDecoder().decode(Artwork.self, from: encoded)
    precondition(roundTrip.maximumWidth == 1400)
}

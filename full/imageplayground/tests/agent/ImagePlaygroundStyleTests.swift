import Foundation
@_spi(OpenUIKitHost) import ImagePlayground

/// Table-driven catalog of the four graph statics plus `all` / `id` / `ID`.
func testStyleCatalog() {
    let expected: [(ImagePlaygroundStyle, String)] = [
        (.animation, "animation"),
        (.illustration, "illustration"),
        (.sketch, "sketch"),
        (.externalProvider, "externalProvider"),
    ]
    for (style, token) in expected {
        precondition(style.id == token)
        precondition(style.id == ImagePlaygroundStyle.ID(token))
    }
    let all = ImagePlaygroundStyle.all
    precondition(all.count == 4)
    precondition(all.map(\.id) == expected.map(\.1))
    precondition(Set(all.map(\.id)) == Set(expected.map(\.1)))
}

func testStyleEqualityAndHashing() {
    let a = ImagePlaygroundStyle.animation
    let b = ImagePlaygroundStyle.illustration
    precondition(a == ImagePlaygroundStyle.animation)
    precondition(a != b)
    precondition(!(a == b))
    precondition(!(a != ImagePlaygroundStyle.animation))
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    ImagePlaygroundStyle.animation.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == ImagePlaygroundStyle.animation.hashValue)
    precondition(Set([a, b, .sketch, .externalProvider]).count == 4)
}

func testStyleCodableRoundTrip() {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for style in ImagePlaygroundStyle.all {
        let data = try! encoder.encode(style)
        let decoded = try! decoder.decode(ImagePlaygroundStyle.self, from: data)
        precondition(decoded == style)
        let token = try! decoder.decode(String.self, from: data)
        precondition(token == style.id)
    }
    do {
        _ = try decoder.decode(ImagePlaygroundStyle.self, from: Data("\"\"".utf8))
        preconditionFailure("empty ImagePlaygroundStyle id must fail to decode")
    } catch is DecodingError {
    } catch {
        preconditionFailure("unexpected decode error \(error)")
    }
}

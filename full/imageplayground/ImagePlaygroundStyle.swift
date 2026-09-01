/// Style options that determine the appearance of generated images.
///
/// Identifiers are the public case names from the Xcode 26.1 symbol graph.
/// Apple's exact `id` strings and Codable layout are not in the pinned
/// public inputs; see `oracle-questions.tsv`.
public struct ImagePlaygroundStyle: Hashable, Codable, Identifiable, Sendable {
    public typealias ID = String

    public let id: String

    init(id: String) {
        self.id = id
    }

    /// Images in a 2D cartoon style.
    public static let illustration = ImagePlaygroundStyle(id: "illustration")
    /// Images in the style of a hand-drawn sketch.
    public static let sketch = ImagePlaygroundStyle(id: "sketch")
    /// Animated images.
    public static let animation = ImagePlaygroundStyle(id: "animation")
    /// A style supplied by an external provider.
    public static let externalProvider = ImagePlaygroundStyle(id: "externalProvider")

    /// Every publicly named style in this starting point.
    public static var all: [ImagePlaygroundStyle] {
        [.illustration, .sketch, .animation, .externalProvider]
    }

    public static func == (a: ImagePlaygroundStyle, b: ImagePlaygroundStyle) -> Bool {
        a.id == b.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        id = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

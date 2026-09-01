/// Style options that determine the appearance of generated images.
///
/// The four public static styles are distinct identities from the Xcode 26.1
/// graph. `id` strings and the Codable layout are local stand-ins; Apple's
/// exact tokens are not in the pinned public inputs.
public struct ImagePlaygroundStyle: Hashable, Codable, Identifiable, Sendable {
    public typealias ID = String

    public let id: String

    init(id: String) {
        self.id = id
    }

    @_spi(OpenUIKitHost)
    public init(_hostID id: String) {
        self.init(id: id)
    }

    public static let illustration = ImagePlaygroundStyle(id: "illustration")
    public static let sketch = ImagePlaygroundStyle(id: "sketch")
    public static let animation = ImagePlaygroundStyle(id: "animation")
    public static let externalProvider = ImagePlaygroundStyle(id: "externalProvider")

    /// The publicly named styles. Order is not recorded in the public graph.
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

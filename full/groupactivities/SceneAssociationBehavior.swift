import Foundation

/// How a group activity should associate with a scene.
public struct SceneAssociationBehavior: Hashable, Sendable, Codable {
    enum Kind: Hashable, Sendable, Codable {
        case none
        case `default`
        case content(String)
    }

    let kind: Kind

    private init(kind: Kind) {
        self.kind = kind
    }

    public static let none = SceneAssociationBehavior(kind: .none)
    public static let `default` = SceneAssociationBehavior(kind: .default)

    public static func content(_ contentIdentifier: String) -> SceneAssociationBehavior {
        SceneAssociationBehavior(kind: .content(contentIdentifier))
    }
}

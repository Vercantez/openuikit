@_exported import Foundation

// Module-local stand-ins for types owned by undeclared modules
// (UniformTypeIdentifiers, Combine). Isolated Linux host sources may import
// Foundation only. Real modules are imported by
// tests/agent/CoreTransferableDependencyIdentity.swift for the later EC2
// integration build. These lookalikes compile only when those modules are
// absent. They are not public substitutes for Foundation-owned types.

#if !canImport(UniformTypeIdentifiers)
public struct UTType: Hashable, Sendable {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    public static let item = UTType(identifier: "public.item")
    public static let data = UTType(identifier: "public.data")
    public static let text = UTType(identifier: "public.text")
    public static let plainText = UTType(identifier: "public.plain-text")
    public static let utf8PlainText = UTType(identifier: "public.utf8-plain-text")
    public static let rtf = UTType(identifier: "public.rtf")
    public static let json = UTType(identifier: "public.json")
    public static let url = UTType(identifier: "public.url")
    public static let fileURL = UTType(identifier: "public.file-url")
    public static let image = UTType(identifier: "public.image")
    public static let jpeg = UTType(identifier: "public.jpeg")
    public static let png = UTType(identifier: "public.png")
    public static let movie = UTType(identifier: "public.movie")
    public static let video = UTType(identifier: "public.video")

    public func conforms(to type: UTType) -> Bool {
        if identifier == type.identifier {
            return true
        }
        return _hostUTTypeParents(identifier).contains(type.identifier)
    }
}

private func _hostUTTypeParents(_ identifier: String) -> [String] {
    switch identifier {
    case "public.jpeg", "public.png":
        return ["public.image", "public.data", "public.item"]
    case "public.image":
        return ["public.data", "public.item"]
    case "public.utf8-plain-text":
        return ["public.plain-text", "public.text", "public.data", "public.item"]
    case "public.plain-text", "public.rtf", "public.json":
        return ["public.text", "public.data", "public.item"]
    case "public.text":
        return ["public.data", "public.item"]
    case "public.video":
        return ["public.movie", "public.audiovisual-content", "public.data", "public.item"]
    case "public.movie":
        return ["public.audiovisual-content", "public.data", "public.item"]
    case "public.file-url":
        return ["public.url", "public.data", "public.item"]
    case "public.url":
        return ["public.data", "public.item"]
    case "public.data":
        return ["public.item"]
    default:
        return ["public.item"]
    }
}
#endif

#if !canImport(Combine)
public protocol TopLevelEncoder: Sendable {
    associatedtype Output
    func encode<T: Encodable>(_ value: T) throws -> Output
}

public protocol TopLevelDecoder: Sendable {
    associatedtype Input
    func decode<T: Decodable>(_ type: T.Type, from: Input) throws -> T
}

extension JSONEncoder: TopLevelEncoder {}
extension JSONDecoder: TopLevelDecoder {}
#endif

func _hostUTType(_ have: UTType, matches want: UTType) -> Bool {
    have.identifier == want.identifier || have.conforms(to: want)
}

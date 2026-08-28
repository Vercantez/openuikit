// A Fuzi stub. Fuzi is a libxml2 wrapper; focus-ios uses it in ONE file,
// Search/OpenSearchParser.swift, to parse an OpenSearch description XML into a
// search engine definition.
//
// EVERY MEMBER HERE DIES LOUDLY, and that is the right call rather than a
// convenience. This type's entire job is to RETURN PARSED CONTENT. An empty
// document would make OpenSearchParser produce a search engine with no name and
// no URL template, and the app would carry that broken engine into the URL bar
// as if it had parsed correctly -- a fabricated result, not a missing one.
//
// Not on the launch path: search engines are read from bundled plists at
// startup and this parser runs when a user ADDS a custom engine in settings.

import Foundation

public struct XMLError: Error { public let message: String }

public final class XMLDocument {
    public init(data: Data) throws {
        fatalError("Fuzi stub: XMLDocument(data:) is unimplemented. Returning an "
                 + "empty document would yield a search engine with no name and "
                 + "no URL template that the app would treat as valid.")
    }
    public var root: XMLElement? { nil }
    public func xpath(_ query: String) -> [XMLElement] { [] }
    public func firstChild(xpath: String) -> XMLElement? { nil }
}

public final class XMLElement {
    public var tag: String? { nil }
    public var stringValue: String { "" }
    public var attributes: [String: String] { [:] }
    public subscript(name: String) -> String? { nil }
    public func xpath(_ query: String) -> [XMLElement] { [] }
    public func firstChild(tag: String) -> XMLElement? { nil }
}

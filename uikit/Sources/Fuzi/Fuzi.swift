// Minimal Fuzi XML surface for Blockzilla/Search/OpenSearchParser.swift
// (one import in the a2832521 Blockzilla target). Parses the bytes with
// Foundation XMLParser so OpenSearchPlugin files in SearchPlugins/ are
// real engines, not invented ones. MEASURED Blockzilla
// SearchEngineManager.swift:113 Bundle.main SearchPlugins + plist;
// OpenSearchParser.swift:32 XMLDocument(data:).

import Foundation
#if canImport(FoundationXML)
// MEASURED swift:6.2-noble `swift build --build-tests`: XMLParser moved
// to FoundationXML (corelibs). Darwin keeps it in Foundation.
import FoundationXML
#endif

public enum XMLError: Error {
    case parserFailure
}

public final class XMLDocument {
    public let root: XMLElement?

    public init(data: Data) throws {
        let parser = _FuziParser()
        guard parser.parse(data: data), let root = parser.root else {
            throw XMLError.parserFailure
        }
        self.root = root
    }

    public func xpath(_ query: String) -> [XMLElement] {
        _ = query
        return []
    }
}

public final class XMLElement {
    public var stringValue: String
    public var attributes: [String: String]
    public private(set) var childElements: [XMLElement]
    public let localName: String

    init(localName: String, attributes: [String: String], stringValue: String, children: [XMLElement]) {
        self.localName = localName
        self.attributes = attributes
        self.stringValue = stringValue
        self.childElements = children
    }

    public func children(tag: String) -> [XMLElement] {
        childElements.filter { $0.localName == tag }
    }

    public func xpath(_ query: String) -> [XMLElement] {
        _ = query
        return []
    }

    public func attr(_ name: String) -> String? {
        attributes[name]
    }
}

private final class _FuziNode {
    var name: String
    var attrs: [String: String]
    var text: String
    var children: [XMLElement]
    init(name: String, attrs: [String: String]) {
        self.name = name
        self.attrs = attrs
        self.text = ""
        self.children = []
    }
}

private final class _FuziParser: NSObject, XMLParserDelegate {
    var root: XMLElement?
    private var stack: [_FuziNode] = []

    func parse(data: Data) -> Bool {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        return parser.parse()
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        _ = (namespaceURI, qName)
        stack.append(_FuziNode(name: elementName, attrs: attributeDict))
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        stack.last?.text += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        _ = (elementName, namespaceURI, qName)
        guard let finished = stack.popLast() else { return }
        let trimmed = finished.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let node = XMLElement(
            localName: finished.name,
            attributes: finished.attrs,
            stringValue: trimmed,
            children: finished.children
        )
        if stack.isEmpty {
            root = node
        } else {
            stack[stack.count - 1].children.append(node)
        }
    }
}

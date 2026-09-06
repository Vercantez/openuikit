import XCTest
import Fuzi

final class FuziOpenSearchTests: XCTestCase {
    func testParsesOpenSearchShortNameAndTemplate() throws {
        // Focus a2832521 Blockzilla/Search/OpenSearchParser.swift:32
        // `XMLDocument(data:)` + root.children(tag:) + attributes["type"].
        let xml = """
        <?xml version="1.0"?>
        <SearchPlugin>
          <ShortName>Example</ShortName>
          <Url type="text/html" template="https://example.test/search?q={searchTerms}"/>
        </SearchPlugin>
        """
        let doc = try XMLDocument(data: Data(xml.utf8))
        let root = try XCTUnwrap(doc.root)
        let names = root.children(tag: "ShortName")
        XCTAssertEqual(names.count, 1)
        XCTAssertEqual(names.first?.stringValue, "Example")
        let url = try XCTUnwrap(root.children(tag: "Url").first)
        XCTAssertEqual(url.attributes["type"], "text/html")
        XCTAssertEqual(url.attributes["template"], "https://example.test/search?q={searchTerms}")
    }
}

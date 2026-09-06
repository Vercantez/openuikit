import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

func testHighlightURL() {
    let url = swSampleURL("notes")
    let highlight = SharedWithYouHostControl.makeHighlight(url: url, identifier: "notes.id")
    swRequire(highlight.url == url, "url")
}

func testHighlightIdentifier() {
    let highlight = SharedWithYouHostControl.makeHighlight(
        url: swSampleURL("id"),
        identifier: "abc"
    )
    let stored = highlight.identifier as? NSString
    swRequire(stored as String? == "abc", "identifier")
}

func testHighlightCopy() {
    let highlight = swSampleHighlight("copy")
    let copied = highlight.copy() as? SWHighlight
    swRequire(copied?.url == highlight.url, "copy url")
}

func testHighlightCoderRoundTrip() {
    let highlight = swSampleHighlight("archive")
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: highlight,
            requiringSecureCoding: true
        )
        let decoded = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: SWHighlight.self,
            from: data
        )
        swRequire(decoded?.url == highlight.url, "decoded url")
    } catch {
        fatalError("archive failed: \(error)")
    }
}

func testHighlightCoderRejectsEmpty() {
    let decoded = SWHighlight(coder: swMismatchedCoder())
    swRequire(decoded == nil, "empty coder")
}

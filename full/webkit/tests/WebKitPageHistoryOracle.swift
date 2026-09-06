import Foundation
import WebKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// This executable consumes asynchronous events with a real async main. The
// sealed evidence tests remain top-level synchronous functions with no waits.
@main struct WebKitPageHistoryOracle {
    @MainActor static func finished<S: AsyncSequence>(_ events: S) async throws
        where S.Element == WebPage.NavigationEvent {
        var received: [WebPage.NavigationEvent] = []
        for try await event in events { received.append(event) }
        precondition(received == [.startedProvisionalNavigation, .committed, .finished])
    }

    @MainActor static func main() async throws {
        let a = URL(string: "https://example.invalid/a")!
        let b = URL(string: "https://example.invalid/b")!
        let c = URL(string: "https://example.invalid/c")!
        let page = WebPage()
        let empty = page.backForwardList
        precondition(page.url == nil && page.title == "" && page.estimatedProgress == 0)
        precondition(!page.isLoading && !page.hasOnlySecureContent)
        precondition(empty == WebPage().backForwardList)
        try await finished(page.load(simulatedRequest: URLRequest(url: a), responseHTML: "<title>A</title>"))
        let live = page.backForwardList
        let saved = live.currentItem!
        let copy = saved
        let fresh = live.currentItem!
        precondition(saved == copy && saved != fresh)
        precondition(saved.id == copy.id && saved.id != fresh.id)
        precondition(saved.id.hashValue == copy.id.hashValue)
        var h1 = Hasher(), h2 = h1
        saved.id.hash(into: &h1)
        copy.id.hash(into: &h2)
        precondition(h1.finalize() == h2.finalize())
        let map = [saved.id: "saved", fresh.id: "fresh"]
        precondition(map.count == 2 && map[copy.id] == "saved")
        precondition(saved.url == a && saved.initialURL == a && saved.title == "A")
        precondition(page.hasOnlySecureContent && page.estimatedProgress == 1 && !page.isLoading)
        precondition(empty.currentItem == nil && empty != live)
        print("history identity: empty sentinel; copied item equal; fresh item and ID unequal")

        try await finished(page.load(simulatedRequest: URLRequest(url: b), responseHTML: "<title>B</title>"))
        try await finished(page.load(simulatedRequest: URLRequest(url: c), responseHTML: "<title>C</title>"))
        precondition(live == page.backForwardList && !(live != page.backForwardList))
        precondition(live.backList.map(\.url) == [a, b] && live.currentItem!.url == c)
        precondition(live[-2]!.url == a && live[-1]!.url == b && live[0]!.url == c)
        precondition(live[-3] == nil && live[1] == nil && live.forwardList.isEmpty)
        let other = WebPage()
        try await finished(other.load(simulatedRequest: URLRequest(url: c), responseHTML: "<title>C</title>"))
        precondition(live != other.backForwardList)
        print("history lists: live A/B/C; offsets -2/-1/0; separate page unequal")

        try await finished(page.load(saved))
        precondition(page.title == "A" && page.url == a)
        precondition(live.backList.isEmpty && live.forwardList.map(\.url) == [b, c])
        precondition(live.currentItem! != saved && live.currentItem!.id != saved.id)
        try await finished(page.load(simulatedRequest: URLRequest(url: b), responseHTML: "<title>Branch</title>"))
        precondition(live.backList.map(\.url) == [a] && live.forwardList.isEmpty)
        precondition(page.title == "Branch")
        print("history revisit: saved item selects A; new B truncates two forward entries")

        try await finished(page.load(saved))
        try await finished(page.load(html: "<title>Replacement</title>", baseURL: c))
        precondition(page.title == "Replacement" && page.url == c)
        precondition(live.currentItem!.url == a && live.currentItem!.title == "Replacement")
        precondition(live.forwardList.map(\.url) == [b] && saved.title == "A")
        try await finished(page.load(live.forwardList[0]))
        try await finished(page.load(live.backList[0]))
        precondition(page.title == "A" && page.url == a)
        let html = WebPage()
        try await finished(html.load(html: "<title>Local</title>", baseURL: a))
        precondition(html.title == "Local" && html.backForwardList.currentItem == nil)
        print("HTML: fresh history empty; replacement preserves entry URL; revisit restores original")

        let repeated = WebPage()
        try await finished(repeated.load(simulatedRequest: URLRequest(url: a), responseHTML: "<title>A</title>"))
        let original = repeated.backForwardList.currentItem!
        try await finished(repeated.load(simulatedRequest: URLRequest(url: a), responseHTML: "<title>A2</title>"))
        precondition(repeated.backForwardList.backList.isEmpty)
        try await finished(repeated.load(simulatedRequest: URLRequest(url: b), responseHTML: "<title>B</title>"))
        try await finished(repeated.load(original))
        precondition(repeated.title == "A2")
        try await finished(repeated.load(simulatedRequest: URLRequest(url: a), responseHTML: "<title>A3</title>"))
        precondition(repeated.backForwardList.backList.isEmpty)
        precondition(repeated.backForwardList.forwardList.map(\.url) == [b])
        print("same URL: replaces entry; saved token restores latest document; forward list preserved")

        let data = Data("<title>Response</title>".utf8)
        let response = WebPage()
        try await finished(response.load(data, mimeType: "text/html", characterEncoding: .utf8, baseURL: b))
        precondition(response.title == "Response" && response.backForwardList.currentItem == nil)
        try await finished(response.load(simulatedRequest: URLRequest(url: a),
                                         response: URLResponse(url: b, mimeType: "text/html",
                                                               expectedContentLength: data.count, textEncodingName: "utf-8"),
                                         responseData: data))
        precondition(response.url == a && response.title == "Response")
        precondition(response.backForwardList.currentItem!.url == a)
        precondition(response.backForwardList.currentItem!.initialURL == a)
        let utf16 = "<title>Café</title>".data(using: .utf16)!
        try await finished(response.load(utf16, mimeType: "text/html", characterEncoding: .utf16, baseURL: c))
        precondition(response.title == "Café")
        print("data: UTF-8 and UTF-16 decoded; response URL B retains request/initial URL A")

        var legacy = Data("<title>".utf8)
        legacy.append(contentsOf: UInt8(0x80)...UInt8(0x9f))
        legacy.append(Data("</title>".utf8))
        let expected: [UInt32] = [8364,129,8218,402,8222,8230,8224,8225,
            710,8240,352,8249,338,141,381,143,144,8216,8217,8220,8221,
            8226,8211,8212,732,8482,353,8250,339,157,382,376]
        for name: String? in [nil, "iso-8859-1", "windows-1252"] {
            try await finished(response.load(simulatedRequest: URLRequest(url: a),
                                             response: URLResponse(url: a, mimeType: "text/html",
                                                                   expectedContentLength: legacy.count, textEncodingName: name),
                                             responseData: legacy))
            precondition(response.title.unicodeScalars.map(\.value) == expected)
        }
        try await finished(response.load(legacy, mimeType: "text/html", characterEncoding: .isoLatin1, baseURL: a))
        precondition(response.title.unicodeScalars.map(\.value) == expected)
        print("legacy decoding: 32 C1 scalars agree for absent, Latin-1 and Windows-1252 labels")

        let plain = WebPage()
        try await finished(plain.load(simulatedRequest: URLRequest(url: URL(string: "http://example.invalid/plain")!),
                                      responseHTML: "<p>Body</p>"))
        precondition(plain.title == "" && plain.backForwardList.currentItem!.title == nil)
        precondition(!plain.hasOnlySecureContent)
        let invalid = WebPage()
        do {
            for try await _ in invalid.load(nil as URL?) { preconditionFailure("invalid URL emitted an event") }
            preconditionFailure("nil URL succeeded")
        } catch WebPage.NavigationError.invalidURL {}
        precondition(invalid.url == nil && invalid.estimatedProgress == 0 && !invalid.isLoading)
        print("empty title: nil item title; nil URL: invalidURL and unchanged initial state")

        #if os(Linux)
        // Host policy, not an assertion about Apple's network/renderer behavior.
        do {
            for try await _ in page.load(URLRequest(url: c)) { preconditionFailure("network emitted success") }
            preconditionFailure("host fetched network data")
        } catch WebPage.NavigationError.failedProvisionalNavigation(let error) {
            precondition((error as NSError).domain == WKError.errorDomain)
            precondition((error as NSError).code == WKError.unknown.rawValue)
        }
        precondition(page.title == "A" && page.url == a)
        do {
            for try await _ in page.reload(fromOrigin: true) { preconditionFailure("reload emitted success") }
            preconditionFailure("host reloaded through a renderer")
        } catch WebPage.NavigationError.failedProvisionalNavigation {}
        do {
            for try await _ in page.load(Data(), mimeType: "image/png", characterEncoding: .utf8, baseURL: c) {
                preconditionFailure("unsupported MIME emitted success")
            }
            preconditionFailure("host decoded an image")
        } catch WebPage.NavigationError.failedProvisionalNavigation {}
        precondition(page.title == "A" && page.url == a)
        do {
            for try await _ in page.load(other.backForwardList.currentItem!) { preconditionFailure("foreign item loaded") }
            preconditionFailure("host accepted foreign entry")
        } catch WebPage.NavigationError.invalidURL {}
        #endif
        print("WEBKIT_PAGE_HISTORY_ORACLE_OK")
    }
}

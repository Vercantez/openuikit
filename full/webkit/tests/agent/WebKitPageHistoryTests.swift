import Foundation
import WebKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private func historyURL(_ name: String) -> URL {
    URL(string: "https://example.invalid/" + name)!
}

func testPageHistoryInitialAndLocalDocumentState() {
    MainActor.assumeIsolated {
        let page = WebPage(configuration: WebPage.Configuration())
        let empty = page.backForwardList
        precondition(page.url == nil && page.title == "" && !page.isLoading)
        precondition(page.estimatedProgress == 0 && !page.hasOnlySecureContent)
        precondition(empty == WebPage().backForwardList)
        page.load(html: "<title>Local</title>", baseURL: historyURL("local"))
        precondition(page.title == "Local" && page.url == historyURL("local"))
        precondition(page.estimatedProgress == 1 && !page.isLoading)
        precondition(page.hasOnlySecureContent)
        precondition(page.backForwardList.currentItem == nil)
        precondition(empty.backList.isEmpty && empty.forwardList.isEmpty)
        precondition(empty == page.backForwardList)
    }
}

func testPageHistorySimulatedResponsePayload() {
    MainActor.assumeIsolated {
        let page = WebPage()
        page.load(simulatedRequest: URLRequest(url: historyURL("alpha")), responseHTML: "<title>Alpha</title>")
        let item: WebPage.BackForwardList.Item = page.backForwardList.currentItem!
        precondition(page.title == "Alpha" && page.url == historyURL("alpha"))
        precondition(item.title == "Alpha" && item.url == historyURL("alpha"))
        precondition(item.initialURL == historyURL("alpha"))
        for title in ["Alpha2", "Alpha3"] {
            page.load(simulatedRequest: URLRequest(url: historyURL("alpha")),
                      responseHTML: "<title>" + title + "</title>")
            precondition(page.backForwardList.backList.isEmpty)
            precondition(page.backForwardList.currentItem!.title == title)
        }
        page.load(simulatedRequest: URLRequest(url: historyURL("untitled")), responseHTML: "<p>Body</p>")
        precondition(page.title == "" && page.backForwardList.currentItem!.title == nil)
        precondition(item.title == "Alpha" && item.url == historyURL("alpha"))
    }
}

func testPageHistoryLiveListsAndRelativeIndices() {
    MainActor.assumeIsolated {
        let page = WebPage()
        let empty = page.backForwardList
        page.load(simulatedRequest: URLRequest(url: historyURL("a")), responseHTML: "<title>A</title>")
        let live = page.backForwardList
        page.load(simulatedRequest: URLRequest(url: historyURL("b")), responseHTML: "<title>B</title>")
        page.load(simulatedRequest: URLRequest(url: historyURL("c")), responseHTML: "<title>C</title>")
        precondition(empty.currentItem == nil && empty != live)
        precondition(live == page.backForwardList && !(live != page.backForwardList))
        precondition(live.backList.map(\.url) == [historyURL("a"), historyURL("b")])
        precondition(live.currentItem!.url == historyURL("c") && live.forwardList.isEmpty)
        precondition(live[-2]!.url == historyURL("a") && live[-1]!.url == historyURL("b"))
        precondition(live[0]!.url == historyURL("c"))
        for index in [-3, 1, Int.min, Int.max] { precondition(live[index] == nil) }
        let other = WebPage()
        other.load(simulatedRequest: URLRequest(url: historyURL("c")), responseHTML: "<title>C</title>")
        precondition(live != other.backForwardList)
    }
}

func testPageHistoryItemCopiesAndFreshIDs() {
    MainActor.assumeIsolated {
        let page = WebPage()
        page.load(simulatedRequest: URLRequest(url: historyURL("a")), responseHTML: "<title>A</title>")
        let item = page.backForwardList.currentItem!
        let copy = item
        let fresh = page.backForwardList.currentItem!
        precondition(item == copy && !(item != copy))
        precondition(item != fresh && !(item == fresh))
        let id: WebPage.BackForwardList.Item.ID = item.id
        precondition(id == copy.id && !(id != copy.id))
        precondition(id != fresh.id && !(id == fresh.id))
        precondition(id.hashValue == copy.id.hashValue)
        var first = Hasher(), second = first
        id.hash(into: &first)
        copy.id.hash(into: &second)
        precondition(first.finalize() == second.finalize())
        let keyed = [id: "saved", fresh.id: "fresh"]
        precondition(keyed.count == 2 && keyed[copy.id] == "saved")
        precondition(Set([item.id, copy.id, fresh.id]).count == 2)
    }
}

func testPageHistoryRevisitAndForwardTruncation() {
    MainActor.assumeIsolated {
        let page = WebPage()
        page.load(simulatedRequest: URLRequest(url: historyURL("a")), responseHTML: "<title>A</title>")
        let saved = page.backForwardList.currentItem!
        let live = page.backForwardList
        page.load(simulatedRequest: URLRequest(url: historyURL("b")), responseHTML: "<title>B</title>")
        let removed = live.currentItem!
        page.load(saved)
        precondition(page.title == "A" && live.backList.isEmpty)
        precondition(live.forwardList.map(\.url) == [historyURL("b")])
        precondition(live[1]!.url == historyURL("b"))
        precondition(live.currentItem! != saved && live.currentItem!.id != saved.id)
        page.load(simulatedRequest: URLRequest(url: historyURL("c")), responseHTML: "<title>C</title>")
        precondition(live.backList.map(\.url) == [historyURL("a")])
        precondition(live.forwardList.isEmpty && live.currentItem!.url == historyURL("c"))
        // Linux fail-closed policy: discarded/foreign entries cannot navigate.
        page.load(removed)
        precondition(page.title == "C" && live.currentItem!.url == historyURL("c"))
    }
}

func testPageHistoryHTMLReplacementPreservesEntry() {
    MainActor.assumeIsolated {
        let page = WebPage()
        page.load(simulatedRequest: URLRequest(url: historyURL("a")), responseHTML: "<title>A</title>")
        let saved = page.backForwardList.currentItem!
        page.load(simulatedRequest: URLRequest(url: historyURL("b")), responseHTML: "<title>B</title>")
        page.load(saved)
        page.load(html: "<title>Replacement</title>", baseURL: historyURL("replacement"))
        precondition(page.title == "Replacement" && page.url == historyURL("replacement"))
        precondition(page.backForwardList.currentItem!.url == historyURL("a"))
        precondition(page.backForwardList.currentItem!.title == "Replacement")
        precondition(page.backForwardList.forwardList.map(\.url) == [historyURL("b")])
        precondition(saved.title == "A")
        page.load(page.backForwardList.forwardList[0])
        page.load(page.backForwardList.backList[0])
        precondition(page.title == "A" && page.url == historyURL("a"))
    }
}

func testPageHistoryDataLoadAndResponseURL() {
    MainActor.assumeIsolated {
        let page = WebPage()
        let data = Data("<title>Response</title>".utf8)
        page.load(data, mimeType: "text/html", characterEncoding: .utf8, baseURL: historyURL("data"))
        precondition(page.title == "Response" && page.backForwardList.currentItem == nil)
        page.load(simulatedRequest: URLRequest(url: historyURL("request")),
                  response: URLResponse(url: historyURL("response"), mimeType: "text/html",
                                        expectedContentLength: data.count, textEncodingName: "utf-8"),
                  responseData: data)
        precondition(page.title == "Response" && page.url == historyURL("request"))
        precondition(page.backForwardList.currentItem!.url == historyURL("request"))
        precondition(page.backForwardList.currentItem!.initialURL == historyURL("request"))
        // The native oracle measures all 32 C1 bytes, including undefined
        // Windows-1252 positions that strict Foundation decoding rejects.
        var legacy = Data("<title>".utf8)
        legacy.append(contentsOf: UInt8(0x80)...UInt8(0x9f))
        legacy.append(Data("</title>".utf8))
        let expected: [UInt32] = [8364,129,8218,402,8222,8230,8224,8225,
            710,8240,352,8249,338,141,381,143,144,8216,8217,8220,8221,
            8226,8211,8212,732,8482,353,8250,339,157,382,376]
        for name: String? in [nil, "iso-8859-1", "windows-1252"] {
            page.load(simulatedRequest: URLRequest(url: historyURL("encoding")),
                      response: URLResponse(url: historyURL("encoding"), mimeType: "text/html",
                                            expectedContentLength: legacy.count, textEncodingName: name),
                      responseData: legacy)
            precondition(page.title.unicodeScalars.map(\.value) == expected)
        }
        page.load(legacy, mimeType: "text/html", characterEncoding: .isoLatin1, baseURL: historyURL("encoding"))
        precondition(page.title.unicodeScalars.map(\.value) == expected)

    }
}

func testPageHistoryUnavailableLoadPreservesCommittedState() {
    MainActor.assumeIsolated {
        let page = WebPage()
        page.load(simulatedRequest: URLRequest(url: historyURL("local")), responseHTML: "<title>Kept</title>")
        page.load(URLRequest(url: historyURL("network")))
        page.load(nil as URL?)
        page.load(historyURL("network"))
        page.reload(fromOrigin: true)
        precondition(page.url == historyURL("local") && page.title == "Kept")
        precondition(page.backForwardList.backList.isEmpty && !page.isLoading)
        precondition(page.backForwardList.currentItem!.url == historyURL("local"))
    }
}

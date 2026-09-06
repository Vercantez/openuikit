import Foundation
import BrowserEngineKit

func testBEDownloadMonitorStoresURLsAndProgress() {
    let source = URL(string: "https://example.test/file.bin")!
    let destination = URL(string: "file:///tmp/file.bin")!
    let progress = Progress(totalUnitCount: 10)
    let token = Data([0xAA])
    let monitor = BEDownloadMonitor(
        sourceURL: source,
        destinationURL: destination,
        observedProgress: progress,
        liveActivityAccessToken: token
    )
    precondition(monitor.sourceURL == source)
    precondition(monitor.destinationURL == destination)
    precondition(monitor.observedProgress === progress)
    precondition(monitor.liveActivityAccessToken == token)
    precondition(monitor.id.uuidString.count == 36)
}

func testBEDownloadMonitorCreateAccessTokenNil() {
    precondition(BEDownloadMonitor.createAccessToken() == nil)
}

func testBEDownloadMonitorUseDownloadsFolderCallsHandlerNil() {
    let monitor = BEDownloadMonitor(
        sourceURL: URL(string: "https://example.test/a")!,
        destinationURL: URL(string: "file:///tmp/a")!,
        observedProgress: Progress(totalUnitCount: 1),
        liveActivityAccessToken: Data()
    )
    var received: BEDownloadMonitor.Location? = BEDownloadMonitor.Location.host_make(
        url: URL(string: "file:///tmp/placeholder")!,
        bookmarkData: Data([1])
    )
    monitor.useDownloadsFolder(placeholderType: UTType(identifier: "public.data")) { location in
        received = location
    }
    precondition(received == nil)
    precondition(monitor.usedDownloadsFolder)
    precondition(monitor.placeholderType?.identifier == "public.data")
}

func testBEDownloadMonitorLocationHostMake() {
    let url = URL(string: "file:///tmp/final")!
    let bookmark = Data([0x01, 0x02])
    let location = BEDownloadMonitor.Location.host_make(url: url, bookmarkData: bookmark)
    precondition(location.url == url)
    precondition(location.bookmarkData == bookmark)
}

func testBEDownloadMonitorIDTypealias() {
    let monitor = BEDownloadMonitor(
        sourceURL: URL(string: "https://example.test")!,
        destinationURL: URL(string: "file:///tmp/x")!,
        observedProgress: Progress(totalUnitCount: 1),
        liveActivityAccessToken: Data()
    )
    let typed: BEDownloadMonitor.ID = monitor.id
    precondition(typed == monitor.id)
}

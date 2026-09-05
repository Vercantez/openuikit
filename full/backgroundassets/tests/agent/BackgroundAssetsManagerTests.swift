@_spi(OpenUIKitHost) import BackgroundAssets
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class RecordingDownloadDelegate: NSObject, BADownloadManagerDelegate {
    var began = 0
    var paused = 0
    var bytes: Int64 = 0
    var failed = 0
    var finished = 0

    func downloadDidBegin(_ download: BADownload) {
        _ = download
        began += 1
    }

    func downloadDidPause(_ download: BADownload) {
        _ = download
        paused += 1
    }

    func download(
        _ download: BADownload,
        didWriteBytes bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite totalExpectedBytes: Int64
    ) {
        _ = (download, totalBytesWritten, totalExpectedBytes)
        bytes += bytesWritten
    }

    func download(_ download: BADownload, failedWithError error: any Error) {
        _ = (download, error)
        failed += 1
    }

    func download(_ download: BADownload, finishedWithFileURL fileURL: URL) {
        _ = (download, fileURL)
        finished += 1
    }
}

func testDownloadManagerShared() {
    precondition(BADownloadManager.shared === BADownloadManager.shared)
}

func testFetchCurrentDownloadsEmpty() {
    let downloads = try! BADownloadManager.shared.fetchCurrentDownloads()
    precondition(downloads.isEmpty)
}

func testFetchCurrentDownloadsCompletionSynchronous() {
    var seen: [BADownload]?
    var error: (any Error)?
    var called = false
    BADownloadManager.shared.fetchCurrentDownloads { list, failure in
        seen = list
        error = failure
        called = true
    }
    precondition(called)
    precondition(seen?.isEmpty == true)
    precondition(error == nil)
}

func testScheduleDownloadFailsClosed() {
    let download = BAURLDownload(
        identifier: "s",
        request: URLRequest(url: URL(string: "https://cdn.example/s.bin")!),
        applicationGroupIdentifier: "group.s"
    )
    do {
        try BADownloadManager.shared.scheduleDownload(download)
        preconditionFailure("scheduleDownload must fail closed")
    } catch let code as BAErrorCode {
        precondition(code == .callerConnectionInvalid)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testScheduleHTTPRejectedAsInvalid() {
    let download = BAURLDownload(
        identifier: "h",
        request: URLRequest(url: URL(string: "http://cdn.example/s.bin")!),
        applicationGroupIdentifier: "group.h"
    )
    do {
        try BADownloadManager.shared.scheduleDownload(download)
        preconditionFailure("http schedule must fail")
    } catch let code as BAErrorCode {
        precondition(code == .downloadInvalid)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testStartForegroundDownloadFailsClosed() {
    let download = BAURLDownload(
        identifier: "fg",
        request: URLRequest(url: URL(string: "https://cdn.example/fg.bin")!),
        applicationGroupIdentifier: "group.fg"
    )
    do {
        try BADownloadManager.shared.startForegroundDownload(download)
        preconditionFailure("startForegroundDownload must fail closed")
    } catch let code as BAErrorCode {
        precondition(code == .downloadFailedToStart)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testCancelUnscheduled() {
    let download = BAURLDownload(
        identifier: "c",
        request: URLRequest(url: URL(string: "https://cdn.example/c.bin")!),
        applicationGroupIdentifier: "group.c"
    )
    do {
        try BADownloadManager.shared.cancel(download)
        preconditionFailure("cancel must fail closed")
    } catch let code as BAErrorCode {
        precondition(code == .downloadNotScheduled)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testExclusiveControlFailsClosed() {
    var granted: Bool?
    var error: (any Error)?
    BADownloadManager.shared.withExclusiveControl { ok, failure in
        granted = ok
        error = failure
    }
    precondition(granted == false)
    precondition((error as? BAErrorCode) == .callerConnectionInvalid)

    var grantedBefore: Bool?
    BADownloadManager.shared.withExclusiveControl(
        beforeDate: Date(timeIntervalSince1970: 1)
    ) { ok, failure in
        grantedBefore = ok
        _ = failure
    }
    precondition(grantedBefore == false)
}

func testDelegateAssignmentAndCallbacks() {
    let manager = BADownloadManager.shared
    let delegate = RecordingDownloadDelegate()
    manager.delegate = delegate
    precondition(manager.delegate === delegate)

    let download = BAURLDownload(
        identifier: "d",
        request: URLRequest(url: URL(string: "https://cdn.example/d.bin")!),
        applicationGroupIdentifier: "group.d"
    )
    delegate.downloadDidBegin(download)
    delegate.downloadDidPause(download)
    delegate.download(download, didWriteBytes: 4, totalBytesWritten: 4, totalBytesExpectedToWrite: 10)
    delegate.download(download, failedWithError: BAErrorCode.downloadAlreadyFailed)
    delegate.download(download, finishedWithFileURL: URL(fileURLWithPath: "/tmp/done.bin"))
    precondition(delegate.began == 1)
    precondition(delegate.paused == 1)
    precondition(delegate.bytes == 4)
    precondition(delegate.failed == 1)
    precondition(delegate.finished == 1)

    manager.delegate = nil
    precondition(manager.delegate == nil)
}

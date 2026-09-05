@_spi(OpenUIKitHost) import BackgroundAssets
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func testContentRequestRawValues() {
    precondition(BAContentRequest.install.rawValue == 1)
    precondition(BAContentRequest.update.rawValue == 2)
    precondition(BAContentRequest.periodic.rawValue == 3)
    precondition(BAContentRequest(rawValue: 1) == .install)
    precondition(BAContentRequest(rawValue: 2) == .update)
    precondition(BAContentRequest(rawValue: 3) == .periodic)
    precondition(BAContentRequest(rawValue: 0) == nil)
    precondition(BAContentRequest.install != .update)
    precondition(BAContentRequest.periodic != .install)
}

func testDownloadStateRawValues() {
    precondition(BADownload.State.failed.rawValue == -1)
    precondition(BADownload.State.created.rawValue == 0)
    precondition(BADownload.State.waiting.rawValue == 1)
    precondition(BADownload.State.downloading.rawValue == 2)
    precondition(BADownload.State.finished.rawValue == 3)
    precondition(BADownload.State(rawValue: -1) == .failed)
    precondition(BADownload.State(rawValue: 0) == .created)
    precondition(BADownload.State(rawValue: 4) == nil)
    precondition(BADownload.State.created != .finished)
}

func testErrorCodeRawValues() {
    typealias Code = BAErrorCode
    precondition(Code.downloadInvalid.rawValue == 0)
    precondition(Code.callFromExtensionNotAllowed.rawValue == 50)
    precondition(Code.callFromInactiveProcessNotAllowed.rawValue == 51)
    precondition(Code.callerConnectionNotAccepted.rawValue == 55)
    precondition(Code.callerConnectionInvalid.rawValue == 56)
    precondition(Code.downloadAlreadyScheduled.rawValue == 100)
    precondition(Code.downloadNotScheduled.rawValue == 101)
    precondition(Code.downloadFailedToStart.rawValue == 102)
    precondition(Code.downloadAlreadyFailed.rawValue == 103)
    precondition(Code.downloadEssentialDownloadNotPermitted.rawValue == 109)
    precondition(Code.downloadBackgroundActivityProhibited.rawValue == 111)
    precondition(Code.downloadWouldExceedAllowance.rawValue == 112)
    precondition(Code.downloadDoesNotExist.rawValue == 113)
    precondition(Code.sessionDownloadDisallowedByDomain.rawValue == 202)
    precondition(Code.sessionDownloadDisallowedByAllowance.rawValue == 203)
    precondition(Code.sessionDownloadAllowanceExceeded.rawValue == 204)
    precondition(Code.sessionDownloadNotPermittedBeforeAppLaunch.rawValue == 206)
    precondition(Code(rawValue: 0) == .downloadInvalid)
    precondition(Code(rawValue: 56) == .callerConnectionInvalid)
    precondition(Code(rawValue: 1) == nil)
    precondition(Code.downloadInvalid != .downloadNotScheduled)
}

func testErrorDomainAndNSError() {
    precondition(BAErrorDomain == "BAErrorDomain")
    precondition(BAErrorCode.errorDomain == BAErrorDomain)
    let nsError = BAErrorCode.callerConnectionInvalid as NSError
    precondition(nsError.domain == BAErrorDomain)
    precondition(nsError.code == 56)
    precondition(BAErrorCode.downloadInvalid.errorCode == 0)
    precondition(BAErrorCode.downloadInvalid.errorUserInfo.isEmpty)
}

func testPriorityConstants() {
    precondition(BADownload.Priority.min.rawValue == 0)
    precondition(BADownload.Priority.default.rawValue == 5)
    precondition(BADownload.Priority.max.rawValue == 10)
    precondition(BADownload.Priority.min != .max)
    precondition(BADownload.Priority(rawValue: 7).rawValue == 7)
    precondition(BADownload.Priority(3).rawValue == 3)
    precondition(BADownload.Priority.min.rawValue < BADownload.Priority.default.rawValue)
    precondition(BADownload.Priority.default.rawValue < BADownload.Priority.max.rawValue)
}

func testEnumHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    BAContentRequest.install.hash(into: &hasherA)
    BAContentRequest.install.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(BAContentRequest.install.hashValue == BAContentRequest.install.hashValue)
    precondition(BADownload.State.failed.hashValue == BADownload.State.failed.hashValue)
    var stateHasher = Hasher()
    BADownload.State.waiting.hash(into: &stateHasher)
    _ = stateHasher.finalize()
    precondition(BAErrorCode.downloadInvalid.hashValue == BAErrorCode.downloadInvalid.hashValue)
    var codeHasher = Hasher()
    BAErrorCode.downloadFailedToStart.hash(into: &codeHasher)
    _ = codeHasher.finalize()
    var priorityHasher = Hasher()
    BADownload.Priority.default.hash(into: &priorityHasher)
    _ = priorityHasher.finalize()
    precondition(BADownload.Priority.min.hashValue == BADownload.Priority.min.hashValue)
    precondition(BADownload.Priority.min != .max)
}

func testManagedErrorCases() {
    let missing = ManagedBackgroundAssetsError.assetPackNotFound(withID: "pack.one")
    let file = ManagedBackgroundAssetsError.fileNotFound(at: FilePath("Textures/a.png"))
    precondition(missing.description.contains("pack.one"))
    precondition(file.description.contains("Textures/a.png"))
    precondition(missing.errorDescription == missing.description)
    precondition(file.errorDescription == file.description)
    precondition(missing.failureReason != nil)
    precondition(file.failureReason != nil)
    precondition(missing.recoverySuggestion != nil)
    precondition(missing.helpAnchor == nil)
    precondition(!missing.localizedDescription.isEmpty)
    precondition(String(describing: file).contains("fileNotFound"))
}

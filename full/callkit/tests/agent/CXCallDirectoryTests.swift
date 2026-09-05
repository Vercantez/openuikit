@_spi(OpenUIKitHost) import CallKit
import Foundation

private final class DirectoryDelegate: NSObject, CXCallDirectoryExtensionContextDelegate {
    var lastError: (any Error)?
    var count = 0

    func requestFailed(
        for extensionContext: CXCallDirectoryExtensionContext,
        withError error: any Error
    ) {
        _ = extensionContext
        lastError = error
        count += 1
    }
}

func testCXCallDirectoryExtensionContextSequentialStore() {
    let directory = CXCallDirectoryExtensionContext(incremental: true)
    precondition(directory.isIncremental)
    directory.addBlockingEntry(withNextSequentialPhoneNumber: 1_555_1212)
    directory.addBlockingEntry(withNextSequentialPhoneNumber: 1_555_1212)
    directory.addBlockingEntry(withNextSequentialPhoneNumber: 1_555_9999)
    precondition(directory.hostBlockingEntries() == [1_555_1212, 1_555_9999])
    directory.addIdentificationEntry(withNextSequentialPhoneNumber: 1_555_0001, label: "Bank")
    precondition(directory.hostIdentificationEntries().first?.1 == "Bank")
    directory.removeBlockingEntry(withPhoneNumber: 1_555_1212)
    precondition(directory.hostBlockingEntries() == [1_555_9999])
    directory.removeAllBlockingEntries()
    directory.removeAllIdentificationEntries()
    precondition(directory.hostBlockingEntries().isEmpty)
    precondition(type(of: directory) == CXCallDirectoryExtensionContext.self)
}

func testCXCallDirectoryCompleteRequestFailClosed() {
    let directory = CXCallDirectoryExtensionContext(incremental: true)
    let delegate = DirectoryDelegate()
    directory.delegate = delegate
    precondition(directory.delegate === delegate)
    var completeFlag = true
    var count = 0
    directory.completeRequest { ok in
        completeFlag = ok
        count += 1
    }
    precondition(count == 1)
    precondition(!completeFlag)
    precondition(delegate.count == 1)
    precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= delegate.lastError!)
}

func testCXCallDirectoryProviderBeginRequest() {
    let provider = CXCallDirectoryProvider()
    precondition(type(of: provider) == CXCallDirectoryProvider.self)
    provider.beginRequest(with: CXCallDirectoryExtensionContext())
}

func testCXCallDirectoryManagerSharedAndFailClosed() {
    precondition(CXCallDirectoryManager.sharedInstance === CXCallDirectoryManager.sharedInstance)
    precondition(type(of: CXCallDirectoryManager.sharedInstance) == CXCallDirectoryManager.self)

    var settingsError: (any Error)?
    var settingsCount = 0
    CXCallDirectoryManager.sharedInstance.openSettings { error in
        settingsError = error
        settingsCount += 1
    }
    precondition(settingsCount == 1)
    precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= settingsError!)

    var reloadError: (any Error)?
    var reloadCount = 0
    CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "com.example.spam") { error in
        reloadError = error
        reloadCount += 1
    }
    precondition(reloadCount == 1)
    precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= reloadError!)

    var statusError: (any Error)?
    var status: CXCallDirectoryManager.EnabledStatus?
    var statusCount = 0
    CXCallDirectoryManager.sharedInstance.enabledStatusForExtension(withIdentifier: "com.example.spam") { value, error in
        status = value
        statusError = error
        statusCount += 1
    }
    precondition(statusCount == 1)
    precondition(status == .unknown)
    precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound ~= statusError!)
}

func testCXCallDirectoryNonIncrementalIgnoresRemoval() {
    let directory = CXCallDirectoryExtensionContext()
    directory.addBlockingEntry(withNextSequentialPhoneNumber: 42)
    directory.removeBlockingEntry(withPhoneNumber: 42)
    directory.removeAllBlockingEntries()
    precondition(directory.hostBlockingEntries() == [42])
}

func testCXCallDirectoryExtensionContextDelegateIdentity() {
    let delegate: any CXCallDirectoryExtensionContextDelegate = DirectoryDelegate()
    _ = delegate
}

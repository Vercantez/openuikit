import CallKit
import Foundation

func testCallDirectoryManagerErrorCodeRawValues() {
    typealias Code = CXErrorCodeCallDirectoryManagerError.Code
    precondition(Code.unknown.rawValue == 0)
    precondition(Code.noExtensionFound.rawValue == 1)
    precondition(Code.loadingInterrupted.rawValue == 2)
    precondition(Code.entriesOutOfOrder.rawValue == 3)
    precondition(Code.duplicateEntries.rawValue == 4)
    precondition(Code.maximumEntriesExceeded.rawValue == 5)
    precondition(Code.extensionDisabled.rawValue == 6)
    precondition(Code.currentlyLoading.rawValue == 7)
    precondition(Code.unexpectedIncrementalRemoval.rawValue == 8)
    precondition(Code.noExtensionFound != .duplicateEntries)
    var hasher = Hasher()
    Code.entriesOutOfOrder.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Code.currentlyLoading.hashValue != Code.unknown.hashValue)
}

func testCallDirectoryManagerErrorCodeRawValueInit() {
    typealias Code = CXErrorCodeCallDirectoryManagerError.Code
    precondition(Code(rawValue: 1) == .noExtensionFound)
    precondition(Code(rawValue: 8) == .unexpectedIncrementalRemoval)
    precondition(Code(rawValue: 9) == nil)
}

func testCallDirectoryManagerErrorStaticAliases() {
    precondition(CXErrorCodeCallDirectoryManagerError.unknown == .unknown)
    precondition(CXErrorCodeCallDirectoryManagerError.noExtensionFound == .noExtensionFound)
    precondition(CXErrorCodeCallDirectoryManagerError.loadingInterrupted == .loadingInterrupted)
    precondition(CXErrorCodeCallDirectoryManagerError.entriesOutOfOrder == .entriesOutOfOrder)
    precondition(CXErrorCodeCallDirectoryManagerError.duplicateEntries == .duplicateEntries)
    precondition(CXErrorCodeCallDirectoryManagerError.maximumEntriesExceeded == .maximumEntriesExceeded)
    precondition(CXErrorCodeCallDirectoryManagerError.extensionDisabled == .extensionDisabled)
    precondition(CXErrorCodeCallDirectoryManagerError.currentlyLoading == .currentlyLoading)
    precondition(CXErrorCodeCallDirectoryManagerError.unexpectedIncrementalRemoval == .unexpectedIncrementalRemoval)
}

func testCallDirectoryManagerErrorInitUserInfoAndCustomNSError() {
    let error = CXErrorCodeCallDirectoryManagerError(.noExtensionFound, userInfo: ["id": "ext"])
    precondition(error.code == .noExtensionFound)
    precondition(error.errorCode == 1)
    precondition(error.userInfo["id"] as? String == "ext")
    precondition(error.errorUserInfo["id"] as? String == "ext")
    precondition(CXErrorCodeCallDirectoryManagerError.errorDomain == CXErrorDomainCallDirectoryManager)
    precondition(CXErrorDomainCallDirectoryManager == "CXErrorDomainCallDirectoryManager")
}

func testCallDirectoryManagerErrorEqualityAndHash() {
    let left = CXErrorCodeCallDirectoryManagerError(.duplicateEntries)
    let right = CXErrorCodeCallDirectoryManagerError(.duplicateEntries)
    precondition(left == right)
    precondition(!(left != right))
    precondition(left != CXErrorCodeCallDirectoryManagerError(.entriesOutOfOrder))
    precondition(left.hashValue == right.hashValue)
    var hasher = Hasher()
    left.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCallDirectoryManagerErrorPatternMatchAndLocalizedDescription() {
    let typed: any Error = CXErrorCodeCallDirectoryManagerError(.extensionDisabled)
    precondition(CXErrorCodeCallDirectoryManagerError.extensionDisabled ~= typed)
    precondition(!(CXErrorCodeCallDirectoryManagerError.currentlyLoading ~= typed))
    precondition(!CXErrorCodeCallDirectoryManagerError(.unknown).localizedDescription.isEmpty)
}

func testCallDirectoryManagerErrorStructIdentity() {
    let error = CXErrorCodeCallDirectoryManagerError(.maximumEntriesExceeded)
    precondition(type(of: error) == CXErrorCodeCallDirectoryManagerError.self)
}

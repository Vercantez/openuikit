// Foundation owns Swift.Error's conformance for the Clang-imported CFErrorRef
// identity.  The portable runtime represents a CFError by the same Objective-C
// object as NSError, matching Core Foundation's toll-free bridge contract.
// Access through that object identity deliberately avoids eager references to
// CFErrorGetDomain, CFErrorGetCode, or CFErrorCopyUserInfo: those entry points
// are not part of the current portable CoreFoundation runtime image.

@_exported import COpenFoundationCore

extension CFError: Error, @unchecked Sendable {
    private var _foundationNSError: NSError {
        unsafeBitCast(self, to: NSError.self)
    }

    public var _domain: String { _foundationNSError.domain }
    public var _code: Int { _foundationNSError.code }
    public var _userInfo: AnyObject? { _foundationNSError.userInfo as AnyObject }

    public func _getEmbeddedNSError() -> AnyObject? { self }
}

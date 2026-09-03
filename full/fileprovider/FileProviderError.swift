import Foundation

/// Bridged File Provider error, matching Apple's `NS_ERROR_ENUM` overlay.
public struct NSFileProviderError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case notAuthenticated = -1000
        case filenameCollision = -1001
        case syncAnchorExpired = -1002
        case insufficientQuota = -1003
        case serverUnreachable = -1004
        case noSuchItem = -1005
        case deletionRejected = -1006
        case directoryNotEmpty = -1007
        case providerNotFound = -1008
        case providerDomainNotFound = -1009
        case cannotSynchronize = -1010
        case nonEvictableChildren = -1011
        case unsyncedEdits = -1012
        case nonEvictable = -1013
        case excludedFromSync = -1015
        case domainDisabled = -1016
        case providerDomainTemporarilyUnavailable = -1017
        case localVersionConflictingWithServer = -1018
        case applicationExtensionNotFound = -1019

        public static var pageExpired: Code { .syncAnchorExpired }

        public static func ~= (match: Code, error: any Error) -> Bool {
            (error as? NSFileProviderError)?.code == match
        }
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { NSFileProviderErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let notAuthenticated = Code.notAuthenticated
    public static let filenameCollision = Code.filenameCollision
    public static let syncAnchorExpired = Code.syncAnchorExpired
    public static let pageExpired = Code.pageExpired
    public static let insufficientQuota = Code.insufficientQuota
    public static let serverUnreachable = Code.serverUnreachable
    public static let noSuchItem = Code.noSuchItem
    public static let deletionRejected = Code.deletionRejected
    public static let directoryNotEmpty = Code.directoryNotEmpty
    public static let providerNotFound = Code.providerNotFound
    public static let providerDomainNotFound = Code.providerDomainNotFound
    public static let cannotSynchronize = Code.cannotSynchronize
    public static let nonEvictableChildren = Code.nonEvictableChildren
    public static let unsyncedEdits = Code.unsyncedEdits
    public static let nonEvictable = Code.nonEvictable
    public static let excludedFromSync = Code.excludedFromSync
    public static let domainDisabled = Code.domainDisabled
    public static let providerDomainTemporarilyUnavailable =
        Code.providerDomainTemporarilyUnavailable
    public static let localVersionConflictingWithServer =
        Code.localVersionConflictingWithServer
    public static let applicationExtensionNotFound = Code.applicationExtensionNotFound

    public static func == (lhs: NSFileProviderError, rhs: NSFileProviderError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension NSError {
    private class func fileProviderTypedError(
        code: NSFileProviderError.Code,
        userInfo: [String: Any]
    ) -> Self {
        let error = NSError(
            domain: NSFileProviderErrorDomain,
            code: code.rawValue,
            userInfo: userInfo
        )
        guard let typed = error as? Self else {
            fatalError("NSError File Provider factory must produce Self")
        }
        return typed
    }

    public class func fileProviderErrorForCollision(
        with existingItem: NSFileProviderItem
    ) -> Self {
        fileProviderTypedError(
            code: .filenameCollision,
            userInfo: [
                NSFileProviderErrorCollidingItemKey: existingItem,
                NSFileProviderErrorItemKey: existingItem,
            ]
        )
    }

    public class func fileProviderErrorForNonExistentItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier
    ) -> Self {
        fileProviderTypedError(
            code: .noSuchItem,
            userInfo: [
                NSFileProviderErrorNonExistentItemIdentifierKey: itemIdentifier.rawValue
            ]
        )
    }

    public class func fileProviderErrorForRejectedDeletion(
        of updatedVersion: NSFileProviderItem
    ) -> Self {
        fileProviderTypedError(
            code: .deletionRejected,
            userInfo: [NSFileProviderErrorItemKey: updatedVersion]
        )
    }
}

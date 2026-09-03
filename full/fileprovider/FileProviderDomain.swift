import Foundation

/// A File Provider domain registered with the (on Linux, process-local) manager.
open class NSFileProviderDomain: NSObject, @unchecked Sendable {
    public struct TestingModes: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let alwaysEnabled = TestingModes(rawValue: 1 << 0)
        public static let interactive = TestingModes(rawValue: 1 << 1)
    }

    public let identifier: NSFileProviderDomainIdentifier
    public let displayName: String
    public let pathRelativeToDocumentStorage: String
    public var backingStoreIdentity: Data?
    public var isReplicated: Bool
    public var supportsSyncingTrash: Bool
    public var testingModes: TestingModes
    public var userEnabled: Bool

    public init(identifier: NSFileProviderDomainIdentifier, displayName: String) {
        self.identifier = identifier
        self.displayName = displayName
        self.pathRelativeToDocumentStorage = identifier.rawValue
        self.backingStoreIdentity = nil
        self.isReplicated = false
        self.supportsSyncingTrash = true
        self.testingModes = []
        self.userEnabled = true
        super.init()
    }

    public init(
        identifier: NSFileProviderDomainIdentifier,
        displayName: String,
        pathRelativeToDocumentStorage: String
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.pathRelativeToDocumentStorage = pathRelativeToDocumentStorage
        self.backingStoreIdentity = nil
        self.isReplicated = false
        self.supportsSyncingTrash = true
        self.testingModes = []
        self.userEnabled = true
        super.init()
    }
}

/// Monotonic domain version used as a change token.
open class NSFileProviderDomainVersion: NSObject, NSSecureCoding, Comparable, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let generation: Int64

    public override init() {
        self.generation = 0
        super.init()
    }

    public init(generation: Int64) {
        self.generation = generation
        super.init()
    }

    public required init?(coder: NSCoder) {
        if coder.containsValue(forKey: "generation") {
            self.generation = coder.decodeInt64(forKey: "generation")
        } else {
            return nil
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(generation, forKey: "generation")
    }

    public func next() -> NSFileProviderDomainVersion {
        NSFileProviderDomainVersion(generation: generation + 1)
    }

    public static func < (
        lhs: NSFileProviderDomainVersion,
        rhs: NSFileProviderDomainVersion
    ) -> Bool {
        lhs.generation < rhs.generation
    }
}

/// Request context passed to replicated-extension callbacks.
open class NSFileProviderRequest: NSObject, @unchecked Sendable {
    public let domainVersion: NSFileProviderDomainVersion?
    public let isFileViewerRequest: Bool
    public let isSystemRequest: Bool

    public init(
        domainVersion: NSFileProviderDomainVersion? = nil,
        isFileViewerRequest: Bool = false,
        isSystemRequest: Bool = false
    ) {
        self.domainVersion = domainVersion
        self.isFileViewerRequest = isFileViewerRequest
        self.isSystemRequest = isSystemRequest
        super.init()
    }
}

/// Provider-reported domain version and user-info snapshot.
public protocol NSFileProviderDomainState: NSObjectProtocol {
    var domainVersion: NSFileProviderDomainVersion { get }
    var userInfo: [AnyHashable: Any] { get }
}

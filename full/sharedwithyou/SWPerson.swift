import Foundation

/// Person record used by mention events and the remove-participant alert.
/// Darwin fills these from CloudKit collaboration participants. Linux
/// stores the fields supplied by the caller and never contacts iCloud.
open class SWPerson: NSObject, NSSecureCoding {
    /// CloudKit share identity for a collaborator.
    open class Identity: NSObject, NSCopying, NSSecureCoding {
        public let rootHash: Data

        public init(rootHash: Data) {
            self.rootHash = rootHash
            super.init()
        }

        public func copy(with zone: NSZone? = nil) -> Any {
            Identity(rootHash: rootHash)
        }

        public static var supportsSecureCoding: Bool { true }

        public required init?(coder: NSCoder) {
            guard let rootHash = coder.decodeObject(of: NSData.self, forKey: "rootHash") as Data?
            else {
                return nil
            }
            self.rootHash = rootHash
            super.init()
        }

        public func encode(with coder: NSCoder) {
            coder.encode(rootHash as NSData, forKey: "rootHash")
        }
    }

    /// Signed identity proof. Linux never produces a cryptographic proof;
    /// the type exists so fail-closed highlight-center callbacks type-check.
    open class SignedIdentityProof: NSObject, NSCopying, NSSecureCoding {
        public let signatureData: Data
        public let inclusionHashes: [Data]
        public let publicKey: Data
        public let publicKeyIndex: Int

        public init(
            signatureData: Data,
            inclusionHashes: [Data] = [],
            publicKey: Data = Data(),
            publicKeyIndex: Int = 0
        ) {
            self.signatureData = signatureData
            self.inclusionHashes = inclusionHashes
            self.publicKey = publicKey
            self.publicKeyIndex = publicKeyIndex
            super.init()
        }

        public func copy(with zone: NSZone? = nil) -> Any {
            SignedIdentityProof(
                signatureData: signatureData,
                inclusionHashes: inclusionHashes,
                publicKey: publicKey,
                publicKeyIndex: publicKeyIndex
            )
        }

        public static var supportsSecureCoding: Bool { true }

        public required init?(coder: NSCoder) {
            guard let signatureData = coder.decodeObject(
                of: NSData.self,
                forKey: "signatureData"
            ) as Data? else {
                return nil
            }
            self.signatureData = signatureData
            self.inclusionHashes = []
            self.publicKey = Data()
            self.publicKeyIndex = 0
            super.init()
        }

        public func encode(with coder: NSCoder) {
            coder.encode(signatureData as NSData, forKey: "signatureData")
        }
    }

    public let handle: String?
    public let identity: Identity?
    public let displayName: String
    public let thumbnailImageData: Data?

    public init(
        handle: String?,
        identity: Identity?,
        displayName: String,
        thumbnailImageData: Data?
    ) {
        self.handle = handle
        self.identity = identity
        self.displayName = displayName
        self.thumbnailImageData = thumbnailImageData
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.handle = coder.decodeObject(of: NSString.self, forKey: "handle") as String?
        self.identity = coder.decodeObject(of: Identity.self, forKey: "identity")
        self.displayName = coder.decodeObject(of: NSString.self, forKey: "displayName") as String? ?? ""
        self.thumbnailImageData = coder.decodeObject(of: NSData.self, forKey: "thumbnail") as Data?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(handle as NSString?, forKey: "handle")
        coder.encode(identity, forKey: "identity")
        coder.encode(displayName as NSString, forKey: "displayName")
        coder.encode(thumbnailImageData as NSData?, forKey: "thumbnail")
    }
}

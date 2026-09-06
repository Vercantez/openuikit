import Foundation

/// CloudKit share identity for a collaborator, keyed by a root hash.
///
/// Darwin overlays this as `SWPerson.Identity`. Linux uses a top-level
/// class so `NSKeyedArchiver` can form a class name (`NSStringFromClass`
/// requires a top-level type on this Foundation).
open class SWPersonIdentity: NSObject, NSCopying, NSSecureCoding {
    public let rootHash: Data

    public static var supportsSecureCoding: Bool { true }

    public init(rootHash: Data) {
        self.rootHash = rootHash
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let rootHash = swcDecodeObject(NSData.self, from: coder, key: "rootHash") as Data?
        else {
            return nil
        }
        self.rootHash = rootHash
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(rootHash as NSData, forKey: "rootHash")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        SWPersonIdentity(rootHash: rootHash)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SWPersonIdentity else { return false }
        return rootHash == other.rootHash
    }

    public override var hash: Int {
        rootHash.hashValue
    }
}

/// Cryptographic inclusion proof for a person identity.
///
/// Darwin has no public designated initializer. Linux constructs proofs
/// through `@_spi(OpenUIKitHost)` and never verifies signatures.
open class SWPersonIdentityProof: NSObject, NSCopying, NSSecureCoding {
    public let inclusionHashes: [Data]
    public let publicKey: Data
    public let publicKeyIndex: Int

    public static var supportsSecureCoding: Bool { true }

    internal init(inclusionHashes: [Data], publicKey: Data, publicKeyIndex: Int) {
        self.inclusionHashes = inclusionHashes
        self.publicKey = publicKey
        self.publicKeyIndex = publicKeyIndex
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let inclusionHashes = swcDecodeDataArray(from: coder, key: "inclusionHashes"),
              let publicKey = swcDecodeObject(NSData.self, from: coder, key: "publicKey") as Data?
        else {
            return nil
        }
        self.inclusionHashes = inclusionHashes
        self.publicKey = publicKey
        self.publicKeyIndex = coder.decodeInteger(forKey: "publicKeyIndex")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        swcEncodeDataArray(inclusionHashes, to: coder, key: "inclusionHashes")
        coder.encode(publicKey as NSData, forKey: "publicKey")
        coder.encode(publicKeyIndex, forKey: "publicKeyIndex")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        SWPersonIdentityProof(
            inclusionHashes: inclusionHashes,
            publicKey: publicKey,
            publicKeyIndex: publicKeyIndex
        )
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SWPersonIdentityProof else { return false }
        return inclusionHashes == other.inclusionHashes
            && publicKey == other.publicKey
            && publicKeyIndex == other.publicKeyIndex
    }
}

/// Identity proof plus a signature blob. Linux stores the signature
/// bytes and does not perform cryptographic verification.
open class SWSignedPersonIdentityProof: SWPersonIdentityProof {
    public let signatureData: Data

    public init(personIdentityProof: SWPersonIdentityProof, signatureData data: Data) {
        self.signatureData = data
        super.init(
            inclusionHashes: personIdentityProof.inclusionHashes,
            publicKey: personIdentityProof.publicKey,
            publicKeyIndex: personIdentityProof.publicKeyIndex
        )
    }

    public required init?(coder: NSCoder) {
        guard let signatureData = swcDecodeObject(
            NSData.self,
            from: coder,
            key: "signatureData"
        ) as Data? else {
            return nil
        }
        self.signatureData = signatureData
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(signatureData as NSData, forKey: "signatureData")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        SWSignedPersonIdentityProof(personIdentityProof: self, signatureData: signatureData)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SWSignedPersonIdentityProof else { return false }
        return super.isEqual(other) && signatureData == other.signatureData
    }
}

/// A collaboration participant. Darwin fills these from CloudKit; Linux
/// stores the fields supplied to `init` and never contacts iCloud.
open class SWPerson: NSObject, NSSecureCoding {
    public typealias Identity = SWPersonIdentity
    public typealias IdentityProof = SWPersonIdentityProof
    public typealias SignedIdentityProof = SWSignedPersonIdentityProof

    internal let handle: String?
    internal let identity: Identity?
    internal let displayName: String
    internal let thumbnailImageData: Data?

    public static var supportsSecureCoding: Bool { true }

    public init(
        handle: String?,
        identity: Identity?,
        displayName: String,
        thumbnailImageData: Data?
    ) {
        self.handle = handle
        self.identity = identity.flatMap { $0.copy() as? Identity } ?? identity
        self.displayName = displayName
        self.thumbnailImageData = thumbnailImageData
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let displayName = swcDecodeObject(NSString.self, from: coder, key: "displayName") as String?
        else {
            return nil
        }
        self.handle = swcDecodeObject(NSString.self, from: coder, key: "handle") as String?
        self.identity = swcDecodeObject(Identity.self, from: coder, key: "identity")
        self.displayName = displayName
        self.thumbnailImageData = swcDecodeObject(NSData.self, from: coder, key: "thumbnailImageData") as Data?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        if let handle {
            coder.encode(handle as NSString, forKey: "handle")
        }
        if let identity {
            coder.encode(identity, forKey: "identity")
        }
        coder.encode(displayName as NSString, forKey: "displayName")
        if let thumbnailImageData {
            coder.encode(thumbnailImageData as NSData, forKey: "thumbnailImageData")
        }
    }
}

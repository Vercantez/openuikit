import Foundation

private enum THCredentialsCodingKey {
    static let networkName = "networkName"
    static let extendedPANID = "extendedPANID"
    static let borderAgentID = "borderAgentID"
    static let activeOperationalDataSet = "activeOperationalDataSet"
    static let networkKey = "networkKey"
    static let pskc = "PSKC"
    static let channel = "channel"
    static let panID = "panID"
    static let creationDate = "creationDate"
    static let lastModificationDate = "lastModificationDate"
}

private func thDecodeString(_ coder: NSCoder, key: String) -> String? {
    coder.decodeObject(of: NSString.self, forKey: key) as String?
}

private func thDecodeData(_ coder: NSCoder, key: String) -> Data? {
    guard let data = coder.decodeObject(of: NSData.self, forKey: key) else {
        return nil
    }
    return data as Data
}

private func thDecodeDate(_ coder: NSCoder, key: String) -> Date? {
    guard let date = coder.decodeObject(of: NSDate.self, forKey: key) else {
        return nil
    }
    return date as Date
}

/// Thread network credentials delivered by Apple's Thread daemon.
///
/// Apple publishes no public designated initializer (`DisableDefaultCtor` in
/// the pinned macios bindings). Linux constructs instances for host tests via
/// `THCredentials.hostCredentials` and `init(coder:)`. Property storage,
/// `channel` mutation, and `NSSecureCoding` round-trips are real. A decoded or
/// host-built record is not a live Border Agent session.
open class THCredentials: NSObject, NSSecureCoding {
    private var storedNetworkName: String?
    private var storedExtendedPANID: Data?
    private var storedBorderAgentID: Data?
    private var storedActiveOperationalDataSet: Data?
    private var storedNetworkKey: Data?
    private var storedPSKC: Data?
    private var storedChannel: UInt8
    private var storedPANID: Data?
    private var storedCreationDate: Date?
    private var storedLastModificationDate: Date?

    public static var supportsSecureCoding: Bool { true }

    open var networkName: String? { storedNetworkName }
    open var extendedPANID: Data? { storedExtendedPANID }
    open var borderAgentID: Data? { storedBorderAgentID }
    open var activeOperationalDataSet: Data? { storedActiveOperationalDataSet }
    open var networkKey: Data? { storedNetworkKey }
    open var pskc: Data? { storedPSKC }
    open var panID: Data? { storedPANID }
    open var creationDate: Date? { storedCreationDate }
    open var lastModificationDate: Date? { storedLastModificationDate }

    /// IEEE 802.15.4 channel byte stored on the credentials record.
    ///
    /// Linux stores the value as-is. The Thread 2.4 GHz range (11...26) is
    /// not enforced: Apple's setter validation is unobserved.
    open var channel: UInt8 {
        get { storedChannel }
        set { storedChannel = newValue }
    }

    init(
        networkName: String?,
        extendedPANID: Data?,
        borderAgentID: Data?,
        activeOperationalDataSet: Data?,
        networkKey: Data?,
        pskc: Data?,
        channel: UInt8,
        panID: Data?,
        creationDate: Date?,
        lastModificationDate: Date?
    ) {
        self.storedNetworkName = networkName
        self.storedExtendedPANID = extendedPANID
        self.storedBorderAgentID = borderAgentID
        self.storedActiveOperationalDataSet = activeOperationalDataSet
        self.storedNetworkKey = networkKey
        self.storedPSKC = pskc
        self.storedChannel = channel
        self.storedPANID = panID
        self.storedCreationDate = creationDate
        self.storedLastModificationDate = lastModificationDate
        super.init()
    }

    /// Host-only constructor. Apple does not publish a public `THCredentials()`
    /// (`DisableDefaultCtor`).
    @_spi(OpenUIKitHost)
    public static func hostCredentials(
        networkName: String? = nil,
        extendedPANID: Data? = nil,
        borderAgentID: Data? = nil,
        activeOperationalDataSet: Data? = nil,
        networkKey: Data? = nil,
        pskc: Data? = nil,
        channel: UInt8 = 0,
        panID: Data? = nil,
        creationDate: Date? = nil,
        lastModificationDate: Date? = nil
    ) -> THCredentials {
        THCredentials(
            networkName: networkName,
            extendedPANID: extendedPANID,
            borderAgentID: borderAgentID,
            activeOperationalDataSet: activeOperationalDataSet,
            networkKey: networkKey,
            pskc: pskc,
            channel: channel,
            panID: panID,
            creationDate: creationDate,
            lastModificationDate: lastModificationDate
        )
    }

    public required init?(coder: NSCoder) {
        self.storedNetworkName = thDecodeString(coder, key: THCredentialsCodingKey.networkName)
        self.storedExtendedPANID = thDecodeData(coder, key: THCredentialsCodingKey.extendedPANID)
        self.storedBorderAgentID = thDecodeData(coder, key: THCredentialsCodingKey.borderAgentID)
        self.storedActiveOperationalDataSet = thDecodeData(
            coder,
            key: THCredentialsCodingKey.activeOperationalDataSet
        )
        self.storedNetworkKey = thDecodeData(coder, key: THCredentialsCodingKey.networkKey)
        self.storedPSKC = thDecodeData(coder, key: THCredentialsCodingKey.pskc)
        if coder.containsValue(forKey: THCredentialsCodingKey.channel) {
            let encoded = coder.decodeInt32(forKey: THCredentialsCodingKey.channel)
            self.storedChannel = UInt8(truncatingIfNeeded: encoded)
        } else {
            self.storedChannel = 0
        }
        self.storedPANID = thDecodeData(coder, key: THCredentialsCodingKey.panID)
        self.storedCreationDate = thDecodeDate(coder, key: THCredentialsCodingKey.creationDate)
        self.storedLastModificationDate = thDecodeDate(
            coder,
            key: THCredentialsCodingKey.lastModificationDate
        )
        super.init()
    }

    open func encode(with coder: NSCoder) {
        if let networkName = storedNetworkName {
            coder.encode(networkName as NSString, forKey: THCredentialsCodingKey.networkName)
        }
        if let extendedPANID = storedExtendedPANID {
            coder.encode(extendedPANID as NSData, forKey: THCredentialsCodingKey.extendedPANID)
        }
        if let borderAgentID = storedBorderAgentID {
            coder.encode(borderAgentID as NSData, forKey: THCredentialsCodingKey.borderAgentID)
        }
        if let activeOperationalDataSet = storedActiveOperationalDataSet {
            coder.encode(
                activeOperationalDataSet as NSData,
                forKey: THCredentialsCodingKey.activeOperationalDataSet
            )
        }
        if let networkKey = storedNetworkKey {
            coder.encode(networkKey as NSData, forKey: THCredentialsCodingKey.networkKey)
        }
        if let pskc = storedPSKC {
            coder.encode(pskc as NSData, forKey: THCredentialsCodingKey.pskc)
        }
        coder.encode(Int32(storedChannel), forKey: THCredentialsCodingKey.channel)
        if let panID = storedPANID {
            coder.encode(panID as NSData, forKey: THCredentialsCodingKey.panID)
        }
        if let creationDate = storedCreationDate {
            coder.encode(creationDate as NSDate, forKey: THCredentialsCodingKey.creationDate)
        }
        if let lastModificationDate = storedLastModificationDate {
            coder.encode(
                lastModificationDate as NSDate,
                forKey: THCredentialsCodingKey.lastModificationDate
            )
        }
    }
}

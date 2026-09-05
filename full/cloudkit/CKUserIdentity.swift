import Foundation

open class CKUserIdentity: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    open private(set) var contactIdentifiers: [String]
    open private(set) var hasiCloudAccount: Bool
    open private(set) var lookupInfo: CKUserIdentity.LookupInfo?
    open private(set) var nameComponents: PersonNameComponents?
    open private(set) var userRecordID: CKRecord.ID?

    public static var supportsSecureCoding: Bool { true }

    init(
        lookupInfo: CKUserIdentity.LookupInfo?,
        userRecordID: CKRecord.ID?,
        nameComponents: PersonNameComponents?,
        hasiCloudAccount: Bool,
        contactIdentifiers: [String]
    ) {
        self.lookupInfo = lookupInfo
        self.userRecordID = userRecordID
        self.nameComponents = nameComponents
        self.hasiCloudAccount = hasiCloudAccount
        self.contactIdentifiers = contactIdentifiers
        super.init()
    }

    static func unresolved() -> CKUserIdentity {
        CKUserIdentity(
            lookupInfo: nil,
            userRecordID: nil,
            nameComponents: nil,
            hasiCloudAccount: false,
            contactIdentifiers: []
        )
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        CKUserIdentity(
            lookupInfo: lookupInfo,
            userRecordID: userRecordID,
            nameComponents: nameComponents,
            hasiCloudAccount: hasiCloudAccount,
            contactIdentifiers: contactIdentifiers
        )
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(userRecordID?.hash ?? 0)
        hasher.combine(lookupInfo?.hash ?? 0)
        hasher.combine(hasiCloudAccount)
        return hasher.finalize()
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKUserIdentity else { return false }
        return userRecordID?.isEqual(other.userRecordID) ?? (other.userRecordID == nil)
            && lookupInfo?.isEqual(other.lookupInfo) ?? (other.lookupInfo == nil)
            && hasiCloudAccount == other.hasiCloudAccount
    }

    @objc(CKUserIdentityLookupInfo)
    open class LookupInfo: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        open private(set) var emailAddress: String?
        open private(set) var phoneNumber: String?
        open private(set) var userRecordID: CKRecord.ID?

        public static var supportsSecureCoding: Bool { true }

        public init(emailAddress: String) {
            self.emailAddress = emailAddress
            super.init()
        }

        public init(phoneNumber: String) {
            self.phoneNumber = phoneNumber
            super.init()
        }

        public init(userRecordID: CKRecord.ID) {
            self.userRecordID = userRecordID
            super.init()
        }

        public required init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            if let emailAddress {
                return CKUserIdentity.LookupInfo(emailAddress: emailAddress)
            }
            if let phoneNumber {
                return CKUserIdentity.LookupInfo(phoneNumber: phoneNumber)
            }
            if let userRecordID {
                return CKUserIdentity.LookupInfo(userRecordID: userRecordID)
            }
            return CKUserIdentity.LookupInfo(emailAddress: "")
        }

        open class func lookupInfos(withEmails emails: [String]) -> [CKUserIdentity.LookupInfo] {
            emails.map { CKUserIdentity.LookupInfo(emailAddress: $0) }
        }

        open class func lookupInfos(withPhoneNumbers phoneNumbers: [String]) -> [CKUserIdentity.LookupInfo] {
            phoneNumbers.map { CKUserIdentity.LookupInfo(phoneNumber: $0) }
        }

        open class func lookupInfos(with recordIDs: [CKRecord.ID]) -> [CKUserIdentity.LookupInfo] {
            recordIDs.map { CKUserIdentity.LookupInfo(userRecordID: $0) }
        }

        open override var hash: Int {
            var hasher = Hasher()
            hasher.combine(emailAddress)
            hasher.combine(phoneNumber)
            hasher.combine(userRecordID?.hash ?? 0)
            return hasher.finalize()
        }

        open override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? CKUserIdentity.LookupInfo else { return false }
            return emailAddress == other.emailAddress
                && phoneNumber == other.phoneNumber
                && (userRecordID?.isEqual(other.userRecordID) ?? (other.userRecordID == nil))
        }
    }
}

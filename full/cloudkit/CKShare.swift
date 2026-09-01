import Foundation

public struct CKSharingParticipantAccessOption: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let anyoneWithLink = CKSharingParticipantAccessOption(rawValue: 1 << 0)
    public static let specifiedRecipientsOnly = CKSharingParticipantAccessOption(rawValue: 1 << 1)
    public static let any: CKSharingParticipantAccessOption = [.anyoneWithLink, .specifiedRecipientsOnly]
}

public struct CKSharingParticipantPermissionOption: OptionSet, Sendable, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let readOnly = CKSharingParticipantPermissionOption(rawValue: 1 << 0)
    public static let readWrite = CKSharingParticipantPermissionOption(rawValue: 1 << 1)
    public static let any: CKSharingParticipantPermissionOption = [.readOnly, .readWrite]
}

open class CKAllowedSharingOptions: NSObject, @unchecked Sendable {
    open var allowedParticipantAccessOptions: CKSharingParticipantAccessOption
    open var allowedParticipantPermissionOptions: CKSharingParticipantPermissionOption
    open var allowsAccessRequests: Bool = false
    open var allowsParticipantsToInviteOthers: Bool = false

    open class var standard: CKAllowedSharingOptions {
        CKAllowedSharingOptions(
            allowedParticipantPermissionOptions: .any,
            allowedParticipantAccessOptions: .any
        )
    }

    public init(
        allowedParticipantPermissionOptions: CKSharingParticipantPermissionOption,
        allowedParticipantAccessOptions: CKSharingParticipantAccessOption
    ) {
        self.allowedParticipantPermissionOptions = allowedParticipantPermissionOptions
        self.allowedParticipantAccessOptions = allowedParticipantAccessOptions
        super.init()
    }
}

open class CKShare: CKRecord, @unchecked Sendable {
    public enum ParticipantAcceptanceStatus: Int, Sendable, Hashable {
        case unknown = 0
        case pending = 1
        case accepted = 2
        case removed = 3
    }

    public enum ParticipantPermission: Int, Sendable, Hashable {
        case unknown = 0
        case none = 1
        case readOnly = 2
        case readWrite = 3
    }

    public enum ParticipantRole: Int, Sendable, Hashable {
        case unknown = 0
        case owner = 1
        case administrator = 2
        case privateUser = 3
        case publicUser = 4
    }

    public enum SystemFieldKey {
        public static let title: CKRecord.FieldKey = CKShareTitleKey
        public static let shareType: CKRecord.FieldKey = CKShareTypeKey
        public static let thumbnailImageData: CKRecord.FieldKey = CKShareThumbnailImageDataKey
    }

    open private(set) var url: URL?
    open var allowsAccessRequests: Bool = false
    open private(set) var blockedIdentities: [CKShare.BlockedIdentity] = []
    open private(set) var currentUserParticipant: CKShare.Participant?
    open private(set) var owner: CKShare.Participant
    open private(set) var participants: [CKShare.Participant]
    open var publicPermission: CKShare.ParticipantPermission = .none
    open private(set) var requesters: [CKShare.AccessRequester] = []

    public convenience init(rootRecord: CKRecord) {
        self.init(
            rootRecord: rootRecord,
            shareID: CKRecord.ID(
                recordName: CKRecordNameZoneWideShare,
                zoneID: rootRecord.recordID.zoneID
            )
        )
    }

    public init(rootRecord: CKRecord, shareID: CKRecord.ID) {
        let owner = CKShare.Participant.makeLocalPlaceholderParticipant()
        self.owner = owner
        self.participants = [owner]
        super.init(_recordType: CKRecordTypeShare, recordID: shareID)
        _ = rootRecord
    }

    public init(rootRecord: CKRecord, share shareID: CKRecord.ID) {
        let owner = CKShare.Participant.makeLocalPlaceholderParticipant()
        self.owner = owner
        self.participants = [owner]
        super.init(_recordType: CKRecordTypeShare, recordID: shareID)
        _ = rootRecord
    }

    public init(recordZoneID: CKRecordZone.ID) {
        let owner = CKShare.Participant.makeLocalPlaceholderParticipant()
        self.owner = owner
        self.participants = [owner]
        super.init(
            _recordType: CKRecordTypeShare,
            recordID: CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: recordZoneID)
        )
    }

    public required init?(coder aDecoder: NSCoder) {
        _ = aDecoder
        return nil
    }

    open func addParticipant(_ participant: CKShare.Participant) {
        if !participants.contains(where: { $0 === participant }) {
            participants.append(participant)
        }
    }

    open func removeParticipant(_ participant: CKShare.Participant) {
        participants.removeAll { $0 === participant }
    }

    open func blockRequesters(_ requesters: [CKShare.AccessRequester]) {
        _ = requesters
    }

    open func denyRequesters(_ requesters: [CKShare.AccessRequester]) {
        _ = requesters
    }

    open func unblockIdentities(_ blockedIdentities: [CKShare.BlockedIdentity]) {
        _ = blockedIdentities
    }

    open func oneTimeURL(for participantID: CKShare.Participant.ID) -> URL? {
        _ = participantID
        return nil
    }

    open class AccessRequester: NSObject, NSSecureCoding, @unchecked Sendable {
        open private(set) var participantLookupInfo: CKUserIdentity.LookupInfo
        open private(set) var userIdentity: CKUserIdentity

        public static var supportsSecureCoding: Bool { true }

        init(userIdentity: CKUserIdentity, lookupInfo: CKUserIdentity.LookupInfo) {
            self.userIdentity = userIdentity
            self.participantLookupInfo = lookupInfo
            super.init()
        }

        public required init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }
    }

    open class BlockedIdentity: NSObject, NSSecureCoding, @unchecked Sendable {
        open private(set) var userIdentity: CKUserIdentity

        public static var supportsSecureCoding: Bool { true }

        init(userIdentity: CKUserIdentity) {
            self.userIdentity = userIdentity
            super.init()
        }

        public required init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }
    }

    open class Metadata: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        open private(set) var containerIdentifier: String
        open private(set) var hierarchicalRootRecordID: CKRecord.ID?
        open private(set) var ownerIdentity: CKUserIdentity
        open private(set) var participantPermission: CKShare.ParticipantPermission
        open private(set) var participantRole: CKShare.ParticipantRole
        open private(set) var participantStatus: CKShare.ParticipantAcceptanceStatus
        open private(set) var rootRecord: CKRecord?
        open private(set) var rootRecordID: CKRecord.ID
        open private(set) var share: CKShare

        public static var supportsSecureCoding: Bool { true }

        public required init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            self
        }
    }

    open class Participant: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        public typealias Permission = CKShare.ParticipantPermission
        public typealias AcceptanceStatus = CKShare.ParticipantAcceptanceStatus
        public typealias ID = String
        public typealias Role = CKShare.ParticipantRole

        open private(set) var acceptanceStatus: CKShare.ParticipantAcceptanceStatus
        open private(set) var dateAddedToShare: Date?
        open private(set) var isApprovedRequester: Bool
        open var permission: CKShare.ParticipantPermission
        open var role: CKShare.ParticipantRole
        open private(set) var userIdentity: CKUserIdentity
        open private(set) var participantID: CKShare.Participant.ID

        public static var supportsSecureCoding: Bool { true }

        public required init(
            userIdentity: CKUserIdentity,
            role: CKShare.ParticipantRole,
            permission: CKShare.ParticipantPermission,
            acceptanceStatus: CKShare.ParticipantAcceptanceStatus
        ) {
            self.userIdentity = userIdentity
            self.role = role
            self.permission = permission
            self.acceptanceStatus = acceptanceStatus
            self.isApprovedRequester = false
            self.participantID = UUID().uuidString
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
            self
        }

        open class func oneTimeURLParticipant() -> Self {
            Self.init(
                userIdentity: CKUserIdentity.unresolved(),
                role: .unknown,
                permission: .none,
                acceptanceStatus: .unknown
            )
        }

        static func makeLocalPlaceholderParticipant() -> CKShare.Participant {
            CKShare.Participant(
                userIdentity: CKUserIdentity.unresolved(),
                role: .unknown,
                permission: .none,
                acceptanceStatus: .unknown
            )
        }
    }
}

import CloudKit
import Foundation

func testCKNotificationParseAndTypes() {
    precondition(CKNotification.NotificationType.query.rawValue == 1)
    precondition(CKNotification.NotificationType.recordZone.rawValue == 2)
    precondition(CKNotification.NotificationType.readNotification.rawValue == 3)
    precondition(CKNotification.NotificationType.database.rawValue == 4)
    precondition(CKQueryNotification.Reason.recordCreated.rawValue == 1)
    precondition(CKQueryNotification.Reason.recordUpdated.rawValue == 2)
    precondition(CKQueryNotification.Reason.recordDeleted.rawValue == 3)

    let parsedNil = CKNotification(fromRemoteNotificationDictionary: ["ck-missing": "value"])
    precondition(parsedNil == nil)
    let parsed = CKNotification(fromRemoteNotificationDictionary: [
        "ck": [
            "t": 1,
            "cid": "iCloud.com.example.news",
            "sid": "sub-articles",
            "nid": "n-1",
            "fet": 0,
        ] as [String: Any],
        "aps": [
            "alert": "Hello",
            "badge": 2,
            "sound": "default",
            "category": "cat",
        ] as [String: Any],
    ])
    precondition(parsed != nil)
    precondition(parsed?.notificationType == .query)
    precondition(parsed?.containerIdentifier == "iCloud.com.example.news")
    precondition(parsed?.subscriptionID == "sub-articles")
    precondition(parsed?.alertBody == "Hello")
    precondition(parsed?.soundName == "default")
    precondition(parsed?.badge?.intValue == 2)
    precondition(parsed?.category == "cat")
    precondition(parsed?.isPruned == false)
    _ = parsed?.notificationID
    _ = parsed?.alertActionLocalizationKey
    _ = parsed?.alertLaunchImage
    _ = parsed?.alertLocalizationArgs
    _ = parsed?.alertLocalizationKey
    _ = parsed?.title
    _ = parsed?.titleLocalizationKey
    _ = parsed?.titleLocalizationArgs
    _ = parsed?.subtitle
    _ = parsed?.subtitleLocalizationKey
    _ = parsed?.subtitleLocalizationArgs
    precondition(parsed?.subscriptionOwnerUserRecordID == nil || parsed?.subscriptionOwnerUserRecordID != nil)
}

func testCKQueryZoneAndDatabaseNotificationTypes() {
    precondition(CKQueryNotification.Reason.recordCreated.rawValue == 1)
    precondition(CKQueryNotification.Reason.recordUpdated.rawValue == 2)
    precondition(CKQueryNotification.Reason.recordDeleted.rawValue == 3)
    precondition(CKNotification.ID.supportsSecureCoding)
    _ = CKNotification.ID()

    let recordID = CKRecord.ID(recordName: "n1")
    let zoneID = CKRecordZone.ID(zoneName: "Articles")
    let created = CKQueryNotification(reason: .recordCreated, databaseScope: .private, recordID: recordID)
    precondition(created.queryNotificationReason == .recordCreated)
    precondition(created.databaseScope == .private)
    precondition(created.recordID?.isEqual(recordID) == true)
    _ = created.recordFields
    _ = CKQueryNotification(reason: .recordUpdated, databaseScope: .public, recordID: nil)
    _ = CKQueryNotification(reason: .recordDeleted, databaseScope: .shared, recordID: nil)
    let zoneNote = CKRecordZoneNotification(databaseScope: .private, recordZoneID: zoneID)
    _ = zoneNote.recordZoneID
    let dbNote = CKDatabaseNotification(databaseScope: .private)
    precondition(dbNote.databaseScope == .private)
}

func testCKShareValueSemanticsAndFailClosedURL() {
    let record = CKRecord(recordType: "Article")
    let share = CKShare(rootRecord: record)
    precondition(share.recordType == CKRecordTypeShare)
    precondition(share.url == nil)
    precondition(share.owner.role == .unknown)
    precondition(share.owner.permission == CKShare.ParticipantPermission.none)
    precondition(share.owner.acceptanceStatus == .unknown)
    precondition(share.owner.userIdentity.hasiCloudAccount == false)
    precondition(share.oneTimeURL(for: share.owner.participantID) == nil)
    share.publicPermission = .readOnly
    share.allowsAccessRequests = true
    precondition(share.publicPermission == .readOnly)
    precondition(share.allowsAccessRequests)
    _ = share.blockedIdentities
    _ = share.currentUserParticipant
    _ = share.requesters
    share.blockRequesters([])
    share.denyRequesters([])
    share.unblockIdentities([])

    let guest = CKShare.Participant(
        userIdentity: share.owner.userIdentity,
        role: .privateUser,
        permission: .readWrite,
        acceptanceStatus: .pending
    )
    share.addParticipant(guest)
    precondition(share.participants.count == 2)
    share.removeParticipant(guest)
    precondition(share.participants.count == 1)
    _ = CKShare.Participant.oneTimeURLParticipant()
    _ = CKShare(recordZoneID: CKRecordZone.ID(zoneName: "Articles"))
    _ = CKShare(rootRecord: record, shareID: CKRecord.ID(recordName: CKRecordNameZoneWideShare))
    _ = CKShare(rootRecord: record, share: CKRecord.ID(recordName: "share-2"))
    precondition(CKRecordNameZoneWideShare == "cloudkit.zoneshare")
    precondition(CKShare.SystemFieldKey.title == CKShareTitleKey)
    precondition(CKShare.SystemFieldKey.shareType == CKShareTypeKey)
    precondition(CKShare.SystemFieldKey.thumbnailImageData == CKShareThumbnailImageDataKey)
    precondition(CKShareTitleKey == "cloudkit.share.title")
    precondition(CKShareTypeKey == "cloudkit.share.type")
    precondition(CKShareThumbnailImageDataKey == "cloudkit.share.thumbnailImageData")
    _ = CKShare_Participant_AcceptanceStatus.unknown
    _ = CKShare_Participant_Permission.none
    _ = CKShare_Participant_Role.owner
    _ = CKShare.Participant.Permission.readOnly
    _ = CKShare.Participant.AcceptanceStatus.accepted
    _ = CKShare.Participant.Role.administrator
    _ = CKShare.Participant.ID.self
}

func testCKShareMetadataAndAccessTypes() {
    precondition(CKShare.Metadata.supportsSecureCoding)
    precondition(CKShare.AccessRequester.supportsSecureCoding)
    precondition(CKShare.BlockedIdentity.supportsSecureCoding)
    let named = isolatedContainer("share-meta")
    _ = named
}

func testCKShareParticipantEnums() {
    precondition(CKShare.ParticipantAcceptanceStatus.unknown.rawValue == 0)
    precondition(CKShare.ParticipantAcceptanceStatus.pending.rawValue == 1)
    precondition(CKShare.ParticipantAcceptanceStatus.accepted.rawValue == 2)
    precondition(CKShare.ParticipantAcceptanceStatus.removed.rawValue == 3)
    precondition(CKShare.ParticipantAcceptanceStatus(rawValue: 2) == .accepted)
    precondition(CKShare.ParticipantPermission.unknown.rawValue == 0)
    precondition(CKShare.ParticipantPermission.none.rawValue == 1)
    precondition(CKShare.ParticipantPermission.readOnly.rawValue == 2)
    precondition(CKShare.ParticipantPermission.readWrite.rawValue == 3)
    precondition(CKShare.ParticipantPermission(rawValue: 3) == .readWrite)
    precondition(CKShare.ParticipantRole.unknown.rawValue == 0)
    precondition(CKShare.ParticipantRole.owner.rawValue == 1)
    precondition(CKShare.ParticipantRole.administrator.rawValue == 2)
    precondition(CKShare.ParticipantRole.privateUser.rawValue == 3)
    precondition(CKShare.ParticipantRole.publicUser.rawValue == 4)
    precondition(CKShare.ParticipantRole(rawValue: 1) == .owner)
    _ = CKShare_Participant_AcceptanceStatus.unknown
    _ = CKShare_Participant_Permission.none
    _ = CKShare_Participant_Role.owner
    _ = CKShare.Participant.Permission.readOnly
    _ = CKShare.Participant.AcceptanceStatus.accepted
    _ = CKShare.Participant.Role.administrator
}

func testCKSharingOptions() {
    precondition(CKSharingParticipantAccessOption.anyoneWithLink.rawValue == 1)
    precondition(CKSharingParticipantAccessOption.specifiedRecipientsOnly.rawValue == 2)
    precondition(CKSharingParticipantAccessOption.any.contains(.anyoneWithLink))
    precondition(CKSharingParticipantPermissionOption.readOnly.rawValue == 1)
    precondition(CKSharingParticipantPermissionOption.readWrite.rawValue == 2)
    precondition(CKSharingParticipantPermissionOption.any.contains(.readWrite))
    let options = CKAllowedSharingOptions.standard
    precondition(options.allowedParticipantAccessOptions.contains(.anyoneWithLink))
    options.allowsAccessRequests = true
    options.allowsParticipantsToInviteOthers = true
    _ = CKAllowedSharingOptions(
        allowedParticipantPermissionOptions: .readOnly,
        allowedParticipantAccessOptions: .specifiedRecipientsOnly
    )
    precondition(CKAllowedSharingOptions.supportsSecureCoding)
}

func testCKUserIdentityLookupInfo() {
    let recordID = CKRecord.ID(recordName: "user-1")
    let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
    precondition(lookup.emailAddress == "user@example.com")
    let phoneLookup = CKUserIdentity.LookupInfo(phoneNumber: "+15555550100")
    precondition(phoneLookup.phoneNumber == "+15555550100")
    let idLookup = CKUserIdentity.LookupInfo(userRecordID: recordID)
    precondition(idLookup.userRecordID?.isEqual(recordID) == true)
    let lookups = CKUserIdentity.LookupInfo.lookupInfos(withEmails: ["a@b.c"])
    precondition(lookups.count == 1)
    precondition(lookups[0].emailAddress == "a@b.c")
    _ = CKUserIdentity.LookupInfo.lookupInfos(withPhoneNumbers: ["+1"])
    _ = CKUserIdentity.LookupInfo.lookupInfos(with: [recordID])
    _ = lookup.copy() as! CKUserIdentity.LookupInfo
    precondition(CKUserIdentity.LookupInfo.supportsSecureCoding)
    precondition(CKUserIdentity.supportsSecureCoding)
}

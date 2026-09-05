import CloudKit
import Foundation

func testCKSubscriptionValueStoreAndPersistence() async throws {
    let named = isolatedContainer("subs")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)

    precondition(CKSubscription.SubscriptionType.query.rawValue == 1)
    precondition(CKSubscription.SubscriptionType.recordZone.rawValue == 2)
    precondition(CKSubscription.SubscriptionType.database.rawValue == 3)
    precondition(CKSubscription.SubscriptionType(rawValue: 1) == .query)
    precondition(CKQuerySubscription.Options.firesOnRecordCreation.rawValue == 1)
    precondition(CKQuerySubscription.Options.firesOnRecordUpdate.rawValue == 2)
    precondition(CKQuerySubscription.Options.firesOnRecordDeletion.rawValue == 4)
    precondition(CKQuerySubscription.Options.firesOnce.rawValue == 8)
    _ = CKQuerySubscription.Options(rawValue: 1)

    let info = CKSubscription.NotificationInfo(alertBody: "changed", shouldBadge: true)
    let subscription = CKQuerySubscription(
        recordType: "Article",
        predicate: NSPredicate(value: true),
        subscriptionID: "sub-articles",
        options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion, .firesOnce]
    )
    subscription.zoneID = zone.zoneID
    subscription.notificationInfo = info
    precondition(subscription.subscriptionType == .query)
    precondition(subscription.subscriptionID == "sub-articles")
    precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordCreation))
    precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordUpdate))
    precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordDeletion))
    precondition(subscription.querySubscriptionOptions.contains(.firesOnce))
    precondition(subscription.recordType == "Article")
    precondition(subscription.predicate == NSPredicate(value: true))
    _ = CKQuerySubscription(
        recordType: "Article",
        predicate: NSPredicate(value: true),
        options: [.firesOnRecordCreation]
    )
    let savedSub = try await db.save(subscription)
    precondition(savedSub.subscriptionID == "sub-articles")

    let zoneSub = CKRecordZoneSubscription(zoneID: zone.zoneID, subscriptionID: "sub-zone")
    zoneSub.recordType = "Article"
    precondition(zoneSub.subscriptionType == .recordZone)
    precondition(zoneSub.zoneID.isEqual(zone.zoneID))
    _ = CKRecordZoneSubscription(zoneID: zone.zoneID)
    _ = try await db.save(zoneSub)

    let dbSub = CKDatabaseSubscription(subscriptionID: "sub-db")
    dbSub.recordType = "Article"
    precondition(dbSub.subscriptionType == .database)
    precondition(CKDatabaseSubscription().subscriptionType == .database)
    _ = try await db.save(dbSub)

    _ = CKSubscription.ID.self
    _ = CKSubscription.supportsSecureCoding
}

func testCKSubscriptionDatabaseFetchAndDelete() async throws {
    let named = isolatedContainer("subs-fetch")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let zoneSub = CKRecordZoneSubscription(zoneID: zone.zoneID, subscriptionID: "sub-zone-fetch")
    _ = try await db.save(zoneSub)
    let fetchedSub = try await db.subscription(for: "sub-zone-fetch")
    precondition(fetchedSub.subscriptionID == "sub-zone-fetch")
    let allSubs = try await db.allSubscriptions()
    precondition(allSubs.contains { $0.subscriptionID == "sub-zone-fetch" })
    let byIDs = try await db.subscriptions(for: ["sub-zone-fetch"])
    precondition((try? byIDs["sub-zone-fetch"]?.get()) != nil)
    _ = try await db.deleteSubscription(withID: "sub-zone-fetch")
}

func testCKSubscriptionNotificationInfo() {
    let info = CKSubscription.NotificationInfo(
        alertBody: "changed",
        alertLocalizationKey: "loc",
        alertLocalizationArgs: ["title"],
        title: "T",
        titleLocalizationKey: "tk",
        titleLocalizationArgs: ["title"],
        subtitle: "S",
        subtitleLocalizationKey: "sk",
        subtitleLocalizationArgs: ["title"],
        alertActionLocalizationKey: "act",
        alertLaunchImage: "img",
        soundName: "default",
        desiredKeys: ["title"],
        shouldBadge: true,
        shouldSendContentAvailable: true,
        shouldSendMutableContent: false,
        category: "cat",
        collapseIDKey: "collapse"
    )
    precondition(info.alertBody == "changed")
    precondition(info.alertLocalizationKey == "loc")
    precondition(info.alertLocalizationArgs == ["title"])
    precondition(info.shouldBadge)
    precondition(info.shouldSendContentAvailable)
    precondition(info.shouldSendMutableContent == false)
    precondition(info.title == "T")
    precondition(info.titleLocalizationKey == "tk")
    precondition(info.subtitle == "S")
    precondition(info.subtitleLocalizationKey == "sk")
    precondition(info.soundName == "default")
    precondition(info.category == "cat")
    precondition(info.collapseIDKey == "collapse")
    precondition(info.alertActionLocalizationKey == "act")
    precondition(info.alertLaunchImage == "img")
    _ = info.copy() as! CKSubscription.NotificationInfo
    precondition(CKSubscription.NotificationInfo.supportsSecureCoding)
    _ = CKSubscription.NotificationInfo()
}

func testCKSubscriptionOperations() async throws {
    let named = isolatedContainer("sub-ops")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let zoneSub = CKRecordZoneSubscription(zoneID: zone.zoneID, subscriptionID: "sub-zone")
    zoneSub.recordType = "Article"
    _ = try await db.save(zoneSub)

    let modifySubs = CKModifySubscriptionsOperation(
        subscriptionsToSave: [
            CKQuerySubscription(
                recordType: "Article",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation]
            )
        ],
        subscriptionIDsToDelete: []
    )
    modifySubs.perSubscriptionSaveBlock = { _, _ in }
    modifySubs.perSubscriptionDeleteBlock = { _, _ in }
    let subModify = await awaitValue { done in
        modifySubs.modifySubscriptionsCompletionBlock = { _, _, error in
            done(error)
        }
        modifySubs.modifySubscriptionsResultBlock = { _ in }
        db.add(modifySubs)
    }
    precondition(subModify == nil)
    _ = CKModifySubscriptionsOperation()
    _ = try await db.modifySubscriptions(saving: [], deleting: [])

    let fetchSubs = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
    fetchSubs.perSubscriptionResultBlock = { _, _ in }
    fetchSubs.fetchSubscriptionsResultBlock = { _ in }
    let subMap = await awaitValue { done in
        fetchSubs.fetchSubscriptionCompletionBlock = { map, error in
            done((map, error))
        }
        db.add(fetchSubs)
    }
    precondition(subMap.1 == nil)
    _ = CKFetchSubscriptionsOperation(subscriptionIDs: ["sub-zone"])
    _ = CKFetchSubscriptionsOperation()
}

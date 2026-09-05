import Foundation
import CoreData
func testFailClosedSurfaces() {
    do {
            let model = makeNoteModel()
            let history = NSPersistentHistoryChangeRequest.fetchHistory(after: nil as NSPersistentHistoryToken?)
            history.resultType = .statusOnly
            _ = history.token
            _ = NSPersistentHistoryChange.entityDescription
            _ = NSPersistentHistoryTransaction.fetchRequest
            _ = NSPersistentHistoryChangeRequest.fetchHistory(after: Date())

            let cloud = NSPersistentCloudKitContainer(name: "Cloud2", managedObjectModel: model)
            cloud.persistentStoreDescriptions[0].cloudKitContainerOptions =
                NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.example")
            do {
                try cloud.initializeCloudKitSchema(options: [.dryRun, .printSchema])
                throw ProbeFailure.message("CloudKit schema init must fail closed")
            } catch is ProbeFailure {
                throw ProbeFailure.message("CloudKit schema init must fail closed")
            } catch {
                let ns = error as NSError
                guard ns.code == NSPersistentStoreOperationError else {
                    throw ProbeFailure.message("CloudKit fail-closed should use NSPersistentStoreOperationError")
                }
            }

            do {
                _ = try NSMigrationManager(sourceModel: model, destinationModel: model).migrateStore(
                    from: URL(fileURLWithPath: "/tmp/src.sqlite"),
                    sourceType: NSSQLiteStoreType,
                    with: nil,
                    toDestinationURL: URL(fileURLWithPath: "/tmp/dst.sqlite"),
                    destinationType: NSSQLiteStoreType
                )
                throw ProbeFailure.message("migrateStore must fail closed")
            } catch is ProbeFailure {
                throw ProbeFailure.message("migrateStore must fail closed")
            } catch {
                let ns = error as NSError
                guard ns.code == NSMigrationError else {
                    throw ProbeFailure.message("migrateStore should use NSMigrationError")
                }
            }

            let mapping = NSEntityMapping()
            mapping.mappingType = .addEntityMappingType
            let propertyMapping = NSPropertyMapping()
            propertyMapping.name = "title"
            mapping.attributeMappings = [propertyMapping]
            _ = NSMappingModel()
            _ = NSEntityMigrationPolicy()
            _ = NSStagedMigrationManager([NSLightweightMigrationStage([])])
            _ = NSManagedObjectModelReference(model: model, versionChecksum: "x")

            let token = NSQueryGenerationToken.current
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            try context.setQueryGenerationFrom(token)
            _ = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSInMemoryStoreType,
                at: URL(string: "x-coredata-in-memory://m")!
            )
            do {
                _ = try NSPersistentStore.metadataForPersistentStore(with: URL(fileURLWithPath: "/tmp/nope.sqlite"))
                throw ProbeFailure.message("SQLite metadata must fail closed")
            } catch is ProbeFailure {
                throw ProbeFailure.message("SQLite metadata must fail closed")
            } catch {
                // expected
            }

            let spotlight = NSCoreDataCoreSpotlightDelegate(
                forStoreWith: NSPersistentStoreDescription(url: URL(fileURLWithPath: "/tmp/x")),
                coordinator: NSPersistentStoreCoordinator(managedObjectModel: model)
            )
            spotlight.startSpotlightIndexing()
            guard spotlight.isIndexingEnabled == false else {
                throw ProbeFailure.message("spotlight indexing must stay disabled")
            }
            do {
                try NSPersistentStoreCoordinator.removeUbiquitousContentAndPersistentStore(
                    at: URL(fileURLWithPath: "/tmp/ubiquity.sqlite"),
                    options: nil
                )
                throw ProbeFailure.message("ubiquity remove must fail closed")
            } catch is ProbeFailure {
                throw ProbeFailure.message("ubiquity remove must fail closed")
            } catch {
                // expected
            }

            let fetchExpr = NSFetchRequestExpression.expression(countOnly: true)
            guard fetchExpr.isCountOnlyRequest,
                  NSFetchRequestExpressionType.rawValue == 50 else {
                throw ProbeFailure.message("NSFetchRequestExpressionType was measured as 50")
            }
    } catch {
        fatalError("testFailClosedSurfaces failed: \(error)")
    }
}


import Foundation
import CoreData
func testSQLiteCRUDAndFaulting() {
    do {
            try withUniqueTempDirectory { directory in
                let model = makeNoteModel()
                let container = try makeLoadedSQLiteContainer(model, directory: directory, name: "SQLiteCRUD")
                let context = container.viewContext
                guard NSPersistentStoreCoordinator.registeredStoreTypes[NSSQLiteStoreType] != nil else {
                    throw ProbeFailure.message("NSSQLiteStoreType must be registered")
                }
                let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                note.setValue("sqlite-hello", forKey: "title")
                note.setValue(4, forKey: "count")
                guard note.objectID.isTemporaryID else {
                    throw ProbeFailure.message("inserted SQLite objectID must start temporary")
                }
                context.assign(note, to: container.persistentStoreCoordinator.persistentStores[0])
                try context.obtainPermanentIDs(for: [note])
                guard !note.objectID.isTemporaryID else {
                    throw ProbeFailure.message("obtainPermanentIDs must promote a temporary SQLite objectID")
                }
                try context.save()
                guard FileManager.default.fileExists(atPath: directory.appendingPathComponent("SQLiteCRUD.sqlite").path) else {
                    throw ProbeFailure.message("SQLite save must create a store file")
                }

                let reopened = try makeLoadedSQLiteContainer(model, directory: directory, name: "SQLiteCRUD")
                let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
                request.returnsObjectsAsFaults = true
                let fetched = try reopened.viewContext.fetch(request)
                guard fetched.count == 1 else {
                    throw ProbeFailure.message("reopened SQLite store must fetch the saved row")
                }
                guard fetched[0].isFault else {
                    throw ProbeFailure.message("returnsObjectsAsFaults must yield a fault from SQLite")
                }
                guard fetched[0].value(forKey: "title") as? String == "sqlite-hello",
                      cdInt(fetched[0], "count") == 4 else {
                    throw ProbeFailure.message("fault fulfillment must read SQLite attribute values")
                }
                fetched[0].setValue("sqlite-updated", forKey: "title")
                try reopened.viewContext.save()
                reopened.viewContext.delete(fetched[0])
                try reopened.viewContext.save()
                guard try reopened.viewContext.count(for: request) == 0 else {
                    throw ProbeFailure.message("SQLite delete/save did not remove the row")
                }
            }
    } catch {
        fatalError("testSQLiteCRUDAndFaulting failed: \(error)")
    }
}

func testSQLiteFetchLimitOffsetAndPredicate() {
    do {
            try withUniqueTempDirectory { directory in
                let container = try makeLoadedSQLiteContainer(makeNoteModel(), directory: directory, name: "SQLitePage")
                let context = container.viewContext
                for title in ["c", "a", "b"] {
                    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                    note.setValue(title, forKey: "title")
                }
                try context.save()
                let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
                request.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
                request.predicate = NSPredicate { object, _ in
                    (object as? NSManagedObject)?.value(forKey: "title") as? String != "c"
                }
                request.fetchOffset = 1
                request.fetchLimit = 1
                let page = try context.fetch(request)
                guard page.count == 1, page[0].value(forKey: "title") as? String == "b" else {
                    throw ProbeFailure.message("SQLite predicate/sort/offset/limit mismatch")
                }
            }
    } catch {
        fatalError("testSQLiteFetchLimitOffsetAndPredicate failed: \(error)")
    }
}

func testSQLiteIncompatibleSchemaAndMigrationFailClosed() {
    do {
            try withUniqueTempDirectory { directory in
                let garbage = directory.appendingPathComponent("garbage.sqlite")
                try "not-a-database".write(to: garbage, atomically: true, encoding: .utf8)
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeNoteModel())
                do {
                    _ = try coordinator.addPersistentStore(
                        ofType: NSSQLiteStoreType,
                        configurationName: nil,
                        at: garbage,
                        options: nil
                    )
                    throw ProbeFailure.message("garbage SQLite bytes must not open as a store")
                } catch is ProbeFailure {
                    throw ProbeFailure.message("garbage SQLite bytes must not open as a store")
                } catch {
                    let ns = error as NSError
                    guard ns.code == NSPersistentStoreIncompatibleSchemaError
                            || ns.code == NSPersistentStoreOpenError
                            || ns.code == NSSQLiteError else {
                        throw ProbeFailure.message("garbage file should use schema/open/sqlite error, got \(ns.code)")
                    }
                }

                let storeURL = directory.appendingPathComponent("version.sqlite")
                _ = try coordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: storeURL,
                    options: nil
                )
                let otherModel = NSManagedObjectModel()
                let entity = NSEntityDescription()
                entity.name = "Other"
                entity.managedObjectClassName = "NSManagedObject"
                let attr = NSAttributeDescription()
                attr.name = "value"
                attr.attributeType = .stringAttributeType
                entity.properties = [attr]
                otherModel.entities = [entity]
                let other = NSPersistentStoreCoordinator(managedObjectModel: otherModel)
                do {
                    _ = try other.addPersistentStore(
                        ofType: NSSQLiteStoreType,
                        configurationName: nil,
                        at: storeURL,
                        options: [
                            NSMigratePersistentStoresAutomaticallyOption: true as NSNumber,
                            NSInferMappingModelAutomaticallyOption: true as NSNumber
                        ]
                    )
                    throw ProbeFailure.message("model hash mismatch must fail closed instead of migrating")
                } catch is ProbeFailure {
                    throw ProbeFailure.message("model hash mismatch must fail closed instead of migrating")
                } catch {
                    let ns = error as NSError
                    guard ns.code == NSPersistentStoreIncompatibleVersionHashError
                            || ns.code == NSMigrationError else {
                        throw ProbeFailure.message("hash mismatch should be version-hash or migration error, got \(ns.code)")
                    }
                }
            }
    } catch {
        fatalError("testSQLiteIncompatibleSchemaAndMigrationFailClosed failed: \(error)")
    }
}

func testSQLiteDestroyAndMetadata() {
    do {
            try withUniqueTempDirectory { directory in
                let url = directory.appendingPathComponent("meta.sqlite")
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeNoteModel())
                coordinator.name = "sqlite-meta"
                _ = coordinator.managedObjectModel
                _ = coordinator.tryLock()
                coordinator.unlock()
                coordinator.performAndWait {
                    _ = coordinator.persistentStores
                }
                let store = try coordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: url,
                    options: [NSSQLitePragmasOption: ["journal_mode": "DELETE"] as NSDictionary]
                )
                guard store.type == NSSQLiteStoreType,
                      store.url == url,
                      coordinator.url(for: store) == url,
                      coordinator.persistentStores.contains(where: { $0 === store }) else {
                    throw ProbeFailure.message("SQLite store identity/url mismatch")
                }
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: NSSQLiteStoreType,
                    at: url,
                    options: nil
                )
                guard metadata[NSStoreTypeKey] as? String == NSSQLiteStoreType else {
                    throw ProbeFailure.message("SQLite metadata must report NSSQLiteStoreType")
                }
                try NSPersistentStoreCoordinator.setMetadata(
                    [NSStoreTypeKey: NSSQLiteStoreType, "extra": "1"],
                    forPersistentStoreOfType: NSSQLiteStoreType,
                    at: url,
                    options: nil
                )
                try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType)
                guard !FileManager.default.fileExists(atPath: url.path) else {
                    throw ProbeFailure.message("destroyPersistentStore must remove the SQLite file")
                }
            }
    } catch {
        fatalError("testSQLiteDestroyAndMetadata failed: \(error)")
    }
}

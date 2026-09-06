import Foundation
import CoreData
func testInMemoryCRUDAndFailClosed() {
    do {
            let model = makeNoteModel()
            let container = try makeLoadedContainer(model)

            try withUniqueTempDirectory { directory in
                let binaryURL = directory.appendingPathComponent("should-not-open.binary")
                let binary = NSPersistentStoreDescription(url: binaryURL)
                binary.type = NSBinaryStoreType
                var binaryFailed = false
                container.persistentStoreCoordinator.addPersistentStore(with: binary) { _, error in
                    binaryFailed = error != nil
                }
                guard binaryFailed else {
                    throw ProbeFailure.message("binary addPersistentStore must fail closed on Linux")
                }
                guard !FileManager.default.fileExists(atPath: binaryURL.path) else {
                    throw ProbeFailure.message("fail-closed binary open must not create \(binaryURL.path)")
                }
            }

            let context = container.viewContext
            final class SaveFlag: @unchecked Sendable {
                var value = false
            }
            let didSave = SaveFlag()
            let observer = NotificationCenter.default.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: context,
                queue: nil
            ) { _ in
                didSave.value = true
            }
            defer { NotificationCenter.default.removeObserver(observer) }

            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("hello", forKey: "title")
            note.setValue(3, forKey: "count")
            guard context.hasChanges else {
                throw ProbeFailure.message("context.hasChanges should be true after insert")
            }
            try context.save()
            guard !context.hasChanges else {
                throw ProbeFailure.message("context.hasChanges should be false after save")
            }
            guard didSave.value else {
                throw ProbeFailure.message("save must post NSManagedObjectContextDidSave")
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
            request.predicate = NSPredicate { object, _ in
                (object as? NSManagedObject)?.value(forKey: "title") as? String == "hello"
            }
            let fetched = try context.fetch(request)
            guard fetched.count == 1,
                  fetched[0].value(forKey: "title") as? String == "hello" else {
                throw ProbeFailure.message("fetch did not return the saved note")
            }

            fetched[0].setValue("updated", forKey: "title")
            try context.save()

            let countRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
            guard try context.count(for: countRequest) == 1 else {
                throw ProbeFailure.message("count mismatch")
            }

            request.predicate = nil
            let frc = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            try frc.performFetch()
            guard frc.fetchedObjects?.count == 1 else {
                throw ProbeFailure.message("NSFetchedResultsController did not fetch saved objects")
            }

            let background = container.newBackgroundContext()
            var backgroundCount = 0
            background.performAndWait {
                let notes = (try? background.fetch(NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? []
                backgroundCount = notes.count
            }
            guard backgroundCount == 1 else {
                throw ProbeFailure.message("background context did not see saved in-memory rows")
            }

            context.delete(fetched[0])
            try context.save()
            guard try context.count(for: countRequest) == 0 else {
                throw ProbeFailure.message("delete/save did not remove the object")
            }

            do {
                _ = try NSMappingModel.inferredMappingModel(forSourceModel: model, destinationModel: model)
                throw ProbeFailure.message("inferred mapping must fail closed")
            } catch is ProbeFailure {
                throw ProbeFailure.message("inferred mapping must fail closed")
            } catch {
                // expected fail-closed mapping error
            }

            let cloud = NSPersistentCloudKitContainer(name: "Cloud", managedObjectModel: model)
            do {
                try cloud.initializeCloudKitSchema()
                throw ProbeFailure.message("CloudKit schema init must fail closed")
            } catch is ProbeFailure {
                throw ProbeFailure.message("CloudKit schema init must fail closed")
            } catch {
                // expected
            }

            guard NSInMemoryStoreType == "InMemory",
                  NSSQLiteStoreType == "SQLite",
                  NSMergePolicy.error.mergeType == .errorMergePolicyType,
                  CocoaError.Code.persistentStoreOpenError.rawValue == NSPersistentStoreOpenError else {
                throw ProbeFailure.message("constants mismatch")
            }
    } catch {
        fatalError("testInMemoryCRUDAndFailClosed failed: \(error)")
    }
}

func testContextInsertSaveFetch() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "InsertSaveFetch")
            let context = container.viewContext
            guard context.hasChanges == false else {
                throw ProbeFailure.message("fresh context should have no changes")
            }
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("insert-save-fetch", forKey: "title")
            note.setValue(7, forKey: "count")
            guard context.hasChanges, context.insertedObjects.contains(note) else {
                throw ProbeFailure.message("insert must register the object and mark hasChanges")
            }
            try context.save()
            guard !context.hasChanges, context.insertedObjects.isEmpty else {
                throw ProbeFailure.message("save must clear insertedObjects/hasChanges")
            }
            let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
            let fetched = try context.fetch(request)
            guard fetched.count == 1,
                  fetched[0].value(forKey: "title") as? String == "insert-save-fetch",
                  fetched[0].value(forKey: "count") as? Int == 7 else {
                throw ProbeFailure.message("fetch did not return the saved insert")
            }
            guard try context.count(for: request) == 1 else {
                throw ProbeFailure.message("count(for:) mismatch after insert/save")
            }
            context.delete(fetched[0])
            try context.save()
            guard try context.count(for: request) == 0 else {
                throw ProbeFailure.message("delete/save did not remove the object")
            }
            let saveRequest = NSSaveChangesRequest(
                inserted: nil,
                updated: nil,
                deleted: nil,
                locked: nil
            )
            guard saveRequest.requestType == .saveRequestType,
                  saveRequest.insertedObjects == nil,
                  saveRequest.updatedObjects == nil,
                  saveRequest.deletedObjects == nil,
                  saveRequest.lockedObjects == nil else {
                throw ProbeFailure.message("NSSaveChangesRequest stores the object sets it was given")
            }
            _ = NSSaveChangesRequest(insertedObjects: nil, updatedObjects: nil, deletedObjects: nil, lockedObjects: nil)
    } catch {
        fatalError("testContextInsertSaveFetch failed: \(error)")
    }
}


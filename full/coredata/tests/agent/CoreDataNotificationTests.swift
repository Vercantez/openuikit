import Foundation
import CoreData
func testDidSaveAndObjectsDidChangeUserInfoKeys() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "NotifyKeys")
            let context = container.viewContext
            final class Capture: @unchecked Sendable {
                var change: [AnyHashable: Any]?
                var save: [AnyHashable: Any]?
            }
            let capture = Capture()
            let changeObs = NotificationCenter.default.addObserver(
                forName: .NSManagedObjectContextObjectsDidChange,
                object: context,
                queue: nil
            ) { note in
                capture.change = note.userInfo
            }
            let saveObs = NotificationCenter.default.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: context,
                queue: nil
            ) { note in
                capture.save = note.userInfo
            }
            defer {
                NotificationCenter.default.removeObserver(changeObs)
                NotificationCenter.default.removeObserver(saveObs)
            }
            let note = NSManagedObject(
                entity: context.persistentStoreCoordinator!.managedObjectModel.entitiesByName["Note"]!,
                insertInto: context
            )
            note.setValue("notify", forKey: "title")
            context.processPendingChanges()
            guard let change = capture.change else {
                throw ProbeFailure.message("insert must post NSManagedObjectContextObjectsDidChange")
            }
            guard change[NSInsertedObjectsKey] is Set<NSManagedObject>,
                  change[NSUpdatedObjectsKey] is Set<NSManagedObject>,
                  change[NSDeletedObjectsKey] is Set<NSManagedObject>,
                  change[NSRefreshedObjectsKey] is Set<NSManagedObject>,
                  change[NSInvalidatedObjectsKey] is Set<NSManagedObject> else {
                throw ProbeFailure.message("objects-did-change userInfo keys must be exact")
            }
            try context.save()
            guard let save = capture.save else {
                throw ProbeFailure.message("save must post NSManagedObjectContextDidSave")
            }
            guard save[NSInsertedObjectsKey] is Set<NSManagedObject>,
                  save[NSUpdatedObjectsKey] is Set<NSManagedObject>,
                  save[NSDeletedObjectsKey] is Set<NSManagedObject>,
                  save[NSInsertedObjectIDsKey] is Set<NSManagedObjectID>,
                  save[NSUpdatedObjectIDsKey] is Set<NSManagedObjectID>,
                  save[NSDeletedObjectIDsKey] is Set<NSManagedObjectID> else {
                throw ProbeFailure.message("did-save userInfo keys must be exact")
            }
            let registered = context.registeredObject(for: note.objectID)
            guard registered === note else {
                throw ProbeFailure.message("registeredObject(for:) must return the inserted instance")
            }
            _ = context.object(with: note.objectID)
            context.detectConflicts(for: note)
            _ = context.tryLock()
            context.unlock()
            context.reset()
            guard context.registeredObjects.isEmpty else {
                throw ProbeFailure.message("reset must drop registered objects")
            }
    } catch {
        fatalError("testDidSaveAndObjectsDidChangeUserInfoKeys failed: \(error)")
    }
}

func testPropertiesToGroupBy() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "GroupBy")
            let context = container.viewContext
            for title in ["x", "x", "y"] {
                let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                note.setValue(title, forKey: "title")
            }
            try context.save()
            let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["title"]
            request.propertiesToGroupBy = ["title"]
            request.havingPredicate = NSPredicate { object, _ in
                ((object as? NSManagedObject)?.value(forKey: "title") as? String) != nil
            }
            let grouped = try context.fetch(request)
            guard grouped.count == 2,
                  grouped.allSatisfy({ $0 is NSDictionary }) else {
                throw ProbeFailure.message("propertiesToGroupBy must collapse duplicate titles into two dictionaries")
            }
            let titles = Set(grouped.compactMap { ($0 as? NSDictionary)?["title"] as? String })
            guard titles == ["x", "y"] else {
                throw ProbeFailure.message("grouped titles mismatch: \(titles)")
            }
    } catch {
        fatalError("testPropertiesToGroupBy failed: \(error)")
    }
}

func testManagedObjectKVCAccessors() {
    do {
            let container = try makeLoadedContainer(makeAuthorNoteModel(), name: "KVC")
            let context = container.viewContext
            let entity = context.persistentStoreCoordinator!.managedObjectModel.entitiesByName["Note"]!
            let note = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context)
            note.setPrimitiveValue("kvc", forKey: "title")
            guard note.primitiveValue(forKey: "title") as? String == "kvc" else {
                throw ProbeFailure.message("primitiveValue/setPrimitiveValue round-trip failed")
            }
            note.willAccessValue(forKey: "title")
            note.didAccessValue(forKey: "title")
            note.willChangeValue(forKey: "title")
            note.setValue("kvc-2", forKey: "title")
            note.didChangeValue(forKey: "title")
            guard note.value(forKey: "title") as? String == "kvc-2" else {
                throw ProbeFailure.message("value(forKey:)/setValue mismatch")
            }
            _ = note.changedValuesForCurrentEvent()
            try note.validateForInsert()
            try note.validateValue("kvc-2" as NSString, forKey: "title")
            try context.save()
            _ = note.hasFault(forRelationshipNamed: "author")
            _ = note.objectIDs(forRelationshipNamed: "author")
            context.refresh(note, mergeChanges: false)
            guard note.isFault else {
                throw ProbeFailure.message("refresh(mergeChanges: false) must turn the object into a fault")
            }
            let existing = try context.existingObject(with: note.objectID)
            _ = existing
            context.refreshAllObjects()
            try note.validateForUpdate()
            try note.validateForDelete()
    } catch {
        fatalError("testManagedObjectKVCAccessors failed: \(error)")
    }
}

func testConstraintConflictOnSave() {
    do {
            let model = makeNoteModel()
            model.entitiesByName["Note"]?.uniquenessConstraints = [["title"]]
            let container = try makeLoadedContainer(model, name: "Constraint")
            let context = container.viewContext
            context.mergePolicy = NSMergePolicy.error
            let first = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            first.setValue("dup", forKey: "title")
            let second = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            second.setValue("dup", forKey: "title")
            do {
                try context.save()
                throw ProbeFailure.message("duplicate uniqueness constraint must fail save")
            } catch is ProbeFailure {
                throw ProbeFailure.message("duplicate uniqueness constraint must fail save")
            } catch {
                let ns = error as NSError
                guard ns.code == NSManagedObjectConstraintMergeError || ns.code == NSManagedObjectMergeError else {
                    throw ProbeFailure.message("constraint save should use constraint/merge error, got \(ns.code)")
                }
                let conflicts = ns.userInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSConstraintConflict]
                if let conflict = conflicts?.first {
                    guard conflict.constraint == ["title"],
                          !conflict.conflictingObjects.isEmpty,
                          conflict.constraintValues["title"] as? String == "dup" else {
                        throw ProbeFailure.message("NSConstraintConflict did not capture title uniqueness")
                    }
                    _ = conflict.databaseObject
                    _ = conflict.databaseSnapshot
                    _ = conflict.conflictingSnapshots
                }
            }
            let constructed = NSConstraintConflict(
                constraint: ["title"],
                databaseObject: first,
                databaseSnapshot: ["title": "dup"],
                conflictingObjects: [first, second],
                conflictingSnapshots: [["title": "dup"], ["title": "dup"]]
            )
            guard constructed.constraint == ["title"],
                  constructed.conflictingObjects.count == 2 else {
                throw ProbeFailure.message("NSConstraintConflict designated initializer mismatch")
            }
    } catch {
        fatalError("testConstraintConflictOnSave failed: \(error)")
    }
}

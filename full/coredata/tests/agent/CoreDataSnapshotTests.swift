import Foundation
import CoreData
func testCommittedSnapshotsAndChangedBack() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "Snapshots")
            let context = container.viewContext
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("hello", forKey: "title")
            try context.save()

            note.setValue("world", forKey: "title")
            guard note.hasPersistentChangedValues else {
                throw ProbeFailure.message("hasPersistentChangedValues must be true after a persistent edit")
            }
            guard note.changedValues()["title"] as? String == "world" else {
                throw ProbeFailure.message("changedValues must report the new title")
            }
            let committed = note.committedValues(forKeys: ["title"])
            guard committed["title"] as? String == "hello" else {
                throw ProbeFailure.message("committedValues must keep the last saved title")
            }

            note.setValue("hello", forKey: "title")
            guard note.changedValues()["title"] == nil else {
                throw ProbeFailure.message("changedValues must clear a key that returned to its original value")
            }
            guard !note.hasPersistentChangedValues else {
                throw ProbeFailure.message("hasPersistentChangedValues must be false after reverting to the committed value")
            }
            guard !context.hasChanges else {
                throw ProbeFailure.message("context.hasChanges must be false after reverting all persistent diffs")
            }
    } catch {
        fatalError("testCommittedSnapshotsAndChangedBack failed: \(error)")
    }
}

func testOldNilCommittedValues() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "OldNil")
            let context = container.viewContext
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("nil-body", forKey: "title")
            try context.save()

            let committed = note.committedValues(forKeys: ["body"])
            guard committed["body"] is NSNull else {
                throw ProbeFailure.message("committedValues must represent a committed nil explicitly as NSNull")
            }
            note.setValue("text", forKey: "body")
            guard note.hasPersistentChangedValues else {
                throw ProbeFailure.message("setting a previously nil attribute must count as a persistent change")
            }
            note.setValue(nil, forKey: "body")
            guard note.changedValues()["body"] == nil else {
                throw ProbeFailure.message("changing a value back to the original nil must clear changedValues")
            }
            guard !note.hasPersistentChangedValues else {
                throw ProbeFailure.message("hasPersistentChangedValues must be false after restoring the original nil")
            }
    } catch {
        fatalError("testOldNilCommittedValues failed: \(error)")
    }
}

func testRollbackRestoresCommitted() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "Rollback")
            let context = container.viewContext
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("saved", forKey: "title")
            try context.save()

            note.setValue("dirty", forKey: "title")
            context.rollback()
            guard note.value(forKey: "title") as? String == "saved" else {
                throw ProbeFailure.message("rollback must restore committed attribute values")
            }
            guard !context.hasChanges else {
                throw ProbeFailure.message("rollback must clear context changes")
            }

            let extra = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            extra.setValue("unsaved", forKey: "title")
            context.rollback()
            guard extra.managedObjectContext == nil else {
                throw ProbeFailure.message("rollback must detach unsaved inserts")
            }
            guard try context.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note")) == 1 else {
                throw ProbeFailure.message("rollback must discard unsaved inserts")
            }
    } catch {
        fatalError("testRollbackRestoresCommitted failed: \(error)")
    }
}


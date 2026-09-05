import Foundation
import CoreData
func testMergePolicies() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "MergePolicies")
            let parent = container.viewContext
            parent.mergePolicy = NSMergePolicy.rollback
            let child = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            child.parent = parent
            child.automaticallyMergesChangesFromParent = true
            child.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: parent)
            note.setValue("root", forKey: "title")
            try parent.save()

            let childView = try child.existingObject(with: note.objectID)
            childView.setValue("child-edit", forKey: "title")
            note.setValue("parent-edit", forKey: "title")
            try parent.save()
            guard childView.value(forKey: "title") as? String == "child-edit" else {
                throw ProbeFailure.message("object-trump merge should keep the child's in-memory title")
            }

            child.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
            childView.setValue("child-again", forKey: "title")
            note.setValue("store-wins", forKey: "title")
            try parent.save()

            guard NSMergePolicy.error.mergeType == .errorMergePolicyType,
                  NSMergePolicy.rollback.mergeType == .rollbackMergePolicyType,
                  NSMergePolicy.overwrite.mergeType == .overwriteMergePolicyType,
                  NSMergePolicy.mergeByPropertyStoreTrump.mergeType == .mergeByPropertyStoreTrumpMergePolicyType,
                  NSMergePolicy.mergeByPropertyObjectTrump.mergeType == .mergeByPropertyObjectTrumpMergePolicyType,
                  NSErrorMergePolicy === NSMergePolicy.error,
                  NSRollbackMergePolicy === NSMergePolicy.rollback,
                  NSOverwriteMergePolicy === NSMergePolicy.overwrite,
                  NSMergeByPropertyStoreTrumpMergePolicy === NSMergePolicy.mergeByPropertyStoreTrump,
                  NSMergeByPropertyObjectTrumpMergePolicy === NSMergePolicy.mergeByPropertyObjectTrump else {
                throw ProbeFailure.message("NSMergePolicy constants mismatch")
            }
    } catch {
        fatalError("testMergePolicies failed: \(error)")
    }
}

func testMergePolicyAndParentMerge() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "Merge")
            let parent = container.viewContext
            parent.mergePolicy = NSMergePolicy.rollback
            let child = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            child.parent = parent
            child.automaticallyMergesChangesFromParent = true
            child.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: parent)
            note.setValue("root", forKey: "title")
            try parent.save()

            let childView = try child.existingObject(with: note.objectID)
            childView.setValue("child-edit", forKey: "title")
            note.setValue("parent-edit", forKey: "title")
            try parent.save()
            guard childView.value(forKey: "title") as? String == "child-edit" else {
                throw ProbeFailure.message("object-trump merge should keep the child's in-memory title")
            }

            let errorPolicy = NSMergePolicy(merge: .errorMergePolicyType)
            do {
                try errorPolicy.resolve(mergeConflicts: [
                    NSMergeConflict(
                        source: childView,
                        newVersion: 2,
                        oldVersion: 1,
                        cachedSnapshot: ["title": "root"],
                        persistedSnapshot: ["title": "parent-edit"]
                    )
                ])
                throw ProbeFailure.message("error merge policy must throw on conflicts")
            } catch is ProbeFailure {
                throw ProbeFailure.message("error merge policy must throw on conflicts")
            } catch {
                let ns = error as NSError
                guard ns.code == NSManagedObjectMergeError else {
                    throw ProbeFailure.message("error merge policy must use NSManagedObjectMergeError")
                }
            }

            guard NSMergePolicy.error.mergeType == .errorMergePolicyType,
                  NSMergePolicy.rollback.mergeType == .rollbackMergePolicyType,
                  NSMergePolicy.overwrite.mergeType == .overwriteMergePolicyType,
                  NSMergePolicy.mergeByPropertyStoreTrump.mergeType == .mergeByPropertyStoreTrumpMergePolicyType,
                  NSMergePolicy.mergeByPropertyObjectTrump.mergeType == .mergeByPropertyObjectTrumpMergePolicyType else {
                throw ProbeFailure.message("NSMergePolicy constants mismatch")
            }
    } catch {
        fatalError("testMergePolicyAndParentMerge failed: \(error)")
    }
}


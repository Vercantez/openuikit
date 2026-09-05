import Foundation
import CoreData
func testChildIsolation() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "ChildIsolation")
            let parent = container.viewContext
            let child = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            child.parent = parent

            var childObject: NSManagedObject?
            child.performAndWait {
                let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: child)
                note.setValue("from-child", forKey: "title")
                childObject = note
                try? child.save()
            }
            guard let childObject else {
                throw ProbeFailure.message("child insert did not retain the child object")
            }
            guard childObject.managedObjectContext === child else {
                throw ProbeFailure.message("child save must not change the child object's managedObjectContext")
            }

            let parentNotes = try parent.fetch(NSFetchRequest<NSManagedObject>(entityName: "Note"))
            guard let parentObject = parentNotes.first(where: { $0.value(forKey: "title") as? String == "from-child" }) else {
                throw ProbeFailure.message("child save must apply a value snapshot into the parent context")
            }
            guard parentObject !== childObject else {
                throw ProbeFailure.message("child save must not insert the same NSManagedObject instance into the parent")
            }
            guard parentObject.managedObjectContext === parent else {
                throw ProbeFailure.message("parent snapshot instance must belong to the parent context")
            }
            guard parentObject.objectID.isEqual(childObject.objectID) else {
                throw ProbeFailure.message("parent clone must share the child's objectID identity")
            }

            child.performAndWait {
                let childView = try? child.existingObject(with: parentObject.objectID)
                childView?.setValue("child-updated", forKey: "title")
                try? child.save()
                if childView?.managedObjectContext !== child {
                    childObject.setValue("context-lost", forKey: "title")
                }
            }
            guard childObject.managedObjectContext === child else {
                throw ProbeFailure.message("child update save must not move the object onto the parent context")
            }
            guard parentObject.value(forKey: "title") as? String == "child-updated" else {
                throw ProbeFailure.message("child update save must copy values onto the distinct parent instance")
            }
            guard parentObject !== childObject else {
                throw ProbeFailure.message("parent and child instances must remain distinct after update save")
            }
    } catch {
        fatalError("testChildIsolation failed: \(error)")
    }
}


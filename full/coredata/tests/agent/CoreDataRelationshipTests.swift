import Foundation
import CoreData
func testRelationshipsFaultingAndInverses() {
    do {
            let container = try makeLoadedContainer(makeAuthorNoteModel(), name: "RelNotes")
            let context = container.viewContext
            let author = NSEntityDescription.insertNewObject(forEntityName: "Author", into: context)
            author.setValue("Ada", forKey: "name")
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("hello", forKey: "title")
            note.setValue(author, forKey: "author")
            let notes = author.value(forKey: "notes") as? Set<NSManagedObject>
            guard notes?.contains(note) == true else {
                throw ProbeFailure.message("setting Note.author must maintain Author.notes inverse")
            }
            guard note.objectID.isTemporaryID else {
                throw ProbeFailure.message("unsaved insert must have a temporary objectID")
            }
            try context.save()
            guard !note.objectID.isTemporaryID, !author.objectID.isTemporaryID else {
                throw ProbeFailure.message("save must promote temporary objectIDs to permanent")
            }
            guard note.objectID.uriRepresentation().scheme == "x-coredata" else {
                throw ProbeFailure.message("permanent objectID uriRepresentation must use x-coredata")
            }

            let background = container.newBackgroundContext()
            var relatedName: String?
            background.performAndWait {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
                request.returnsObjectsAsFaults = true
                let fetched = (try? background.fetch(request)) ?? []
                guard let fetchedNote = fetched.first else { return }
                relatedName = (fetchedNote.value(forKey: "author") as? NSManagedObject)?.value(forKey: "name") as? String
            }
            guard relatedName == "Ada" else {
                throw ProbeFailure.message("relationship faulting must materialize Author.name, got \(String(describing: relatedName))")
            }
    } catch {
        fatalError("testRelationshipsFaultingAndInverses failed: \(error)")
    }
}

func testDeleteRules() {
    do {
            let container = try makeLoadedContainer(makeAuthorNoteModel(), name: "DeleteRules")
            let context = container.viewContext
            let author = NSEntityDescription.insertNewObject(forEntityName: "Author", into: context)
            author.setValue("Grace", forKey: "name")
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("cascade-me", forKey: "title")
            note.setValue(author, forKey: "author")
            try context.save()
            context.delete(author)
            try context.save()
            guard try context.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note")) == 0 else {
                throw ProbeFailure.message("cascade delete rule must delete related notes")
            }

            let denyModel = makeAuthorNoteModel()
            denyModel.entitiesByName["Note"]?.relationshipsByName["author"]?.deleteRule = .denyDeleteRule
            let denyContainer = try makeLoadedContainer(denyModel, name: "DenyRules")
            let denyContext = denyContainer.viewContext
            let owner = NSEntityDescription.insertNewObject(forEntityName: "Author", into: denyContext)
            owner.setValue("Denied", forKey: "name")
            let kept = NSEntityDescription.insertNewObject(forEntityName: "Note", into: denyContext)
            kept.setValue("keep", forKey: "title")
            kept.setValue(owner, forKey: "author")
            try denyContext.save()
            denyContext.delete(kept)
            do {
                try denyContext.save()
                throw ProbeFailure.message("deny delete rule must throw when the inverse is non-empty")
            } catch is ProbeFailure {
                throw ProbeFailure.message("deny delete rule must throw when the inverse is non-empty")
            } catch {
                let ns = error as NSError
                guard ns.code == NSValidationRelationshipDeniedDeleteError else {
                    throw ProbeFailure.message("deny delete must use NSValidationRelationshipDeniedDeleteError, got \(ns.code)")
                }
            }
    } catch {
        fatalError("testDeleteRules failed: \(error)")
    }
}


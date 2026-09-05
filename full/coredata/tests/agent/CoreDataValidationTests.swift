import Foundation
import CoreData
func testValidationAndUndoDisabled() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "Validation")
            let context = container.viewContext
            context.undoManager = NSObject()
            guard context.undoManager == nil else {
                throw ProbeFailure.message("undo stays disabled: setter must not attach a manager")
            }
            context.undo()
            context.redo()

            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            do {
                try context.save()
                throw ProbeFailure.message("missing required title must fail validateForInsert")
            } catch is ProbeFailure {
                throw ProbeFailure.message("missing required title must fail validateForInsert")
            } catch {
                let ns = error as NSError
                guard ns.code == NSValidationMissingMandatoryPropertyError else {
                    throw ProbeFailure.message("expected NSValidationMissingMandatoryPropertyError, got \(ns.code)")
                }
                guard ns.userInfo[NSValidationKeyErrorKey] as? String == "title" else {
                    throw ProbeFailure.message("validation userInfo must name the title key")
                }
            }

            note.setValue("ok", forKey: "title")
            try note.validateValue(nil, forKey: "body")
            note.willChangeValue(forKey: "title", withSetMutation: .union, using: [])
            note.didChangeValue(forKey: "title", withSetMutation: .union, using: [])
            try context.save()
            context.refresh(note, mergeChanges: true)
            context.refreshAllObjects()
            context.processPendingChanges()
            _ = context.withLock { context.hasChanges }
    } catch {
        fatalError("testValidationAndUndoDisabled failed: \(error)")
    }
}


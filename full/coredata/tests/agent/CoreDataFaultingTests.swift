import Foundation
import CoreData
func testFaulting() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "Faulting")
            let context = container.viewContext
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("fault-me", forKey: "title")
            try context.save()

            let background = container.newBackgroundContext()
            var wasFault = false
            var afterAccess = true
            var title: String?
            background.performAndWait {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
                request.returnsObjectsAsFaults = true
                request.resultType = .managedObjectResultType
                let fetched = (try? background.fetch(request)) ?? []
                guard let faulted = fetched.first else { return }
                wasFault = faulted.isFault
                title = faulted.value(forKey: "title") as? String
                afterAccess = faulted.isFault
            }
            guard wasFault else {
                throw ProbeFailure.message("returnsObjectsAsFaults fetch must yield isFault == true")
            }
            guard title == "fault-me" else {
                throw ProbeFailure.message("firing a fault must materialize title, got \(String(describing: title))")
            }
            guard afterAccess == false else {
                throw ProbeFailure.message("value(forKey:) must fire the fault and clear isFault")
            }
    } catch {
        fatalError("testFaulting failed: \(error)")
    }
}


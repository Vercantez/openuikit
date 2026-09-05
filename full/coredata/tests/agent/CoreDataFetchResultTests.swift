import Foundation
import CoreData
func testSortLimitResultTypes() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "SortLimit")
            let context = container.viewContext
            for title in ["c", "a", "b"] {
                let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                note.setValue(title, forKey: "title")
            }
            try context.save()

            let sorted = NSFetchRequest<NSManagedObject>(entityName: "Note")
            sorted.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
            let ascending = try context.fetch(sorted).compactMap { $0.value(forKey: "title") as? String }
            guard ascending == ["a", "b", "c"] else {
                throw ProbeFailure.message("ascending sort mismatch: \(ascending)")
            }
            sorted.sortDescriptors = [cdSortDescriptor(key: "title", ascending: false)]
            let descending = try context.fetch(sorted).compactMap { $0.value(forKey: "title") as? String }
            guard descending == ["c", "b", "a"] else {
                throw ProbeFailure.message("descending sort mismatch: \(descending)")
            }

            let sliced = NSFetchRequest<NSManagedObject>(entityName: "Note")
            sliced.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
            sliced.fetchOffset = 1
            sliced.fetchLimit = 1
            let page = try context.fetch(sliced)
            guard page.first?.value(forKey: "title") as? String == "b" else {
                throw ProbeFailure.message("fetchOffset/fetchLimit mismatch")
            }

            let countRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
            countRequest.resultType = .countResultType
            guard try context.count(for: countRequest) == 3 else {
                throw ProbeFailure.message("count(for:) must return 3")
            }

            let ids = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
            ids.resultType = .managedObjectIDResultType
            let idResults = try context.fetch(ids)
            guard idResults.count == 3, idResults.allSatisfy({ $0 is NSManagedObjectID }) else {
                throw ProbeFailure.message("managedObjectIDResultType must return NSManagedObjectID values")
            }

            let dicts = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
            dicts.resultType = .dictionaryResultType
            dicts.propertiesToFetch = ["title"]
            let dictResults = try context.fetch(dicts)
            guard dictResults.count == 3, dictResults.first is NSDictionary else {
                throw ProbeFailure.message("dictionaryResultType must return NSDictionary values")
            }

            let objects = NSFetchRequest<NSManagedObject>(entityName: "Note")
            objects.resultType = .managedObjectResultType
            guard try context.fetch(objects).count == 3 else {
                throw ProbeFailure.message("managedObjectResultType must return objects")
            }
    } catch {
        fatalError("testSortLimitResultTypes failed: \(error)")
    }
}


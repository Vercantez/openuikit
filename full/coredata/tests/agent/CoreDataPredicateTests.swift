import Foundation
import CoreData
func testPredicatesByOperator() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "PredicateOps")
            let context = container.viewContext
            for (title, count) in [("alpha", 1), ("beta", 2), ("alphabet", 10)] {
                let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                note.setValue(title, forKey: "title")
                note.setValue(count, forKey: "count")
            }
            try context.save()

            func titles(_ predicate: NSPredicate) throws -> [String] {
                let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
                request.predicate = predicate
                return try context.fetch(request).compactMap { $0.value(forKey: "title") as? String }.sorted()
            }

            guard try titles(NSPredicate { object, _ in cdString(object, "title") == "beta" }) == ["beta"] else {
                throw ProbeFailure.message("== predicate failed")
            }
            guard try titles(NSPredicate { object, _ in cdString(object, "title") != "beta" }) == ["alpha", "alphabet"] else {
                throw ProbeFailure.message("!= predicate failed")
            }
            guard try titles(NSPredicate { object, _ in (cdInt(object, "count") ?? 0) > 2 }) == ["alphabet"] else {
                throw ProbeFailure.message("> predicate failed")
            }
            guard try titles(NSPredicate { object, _ in (cdInt(object, "count") ?? 0) < 2 }) == ["alpha"] else {
                throw ProbeFailure.message("< predicate failed")
            }
            guard try titles(NSPredicate { object, _ in (cdInt(object, "count") ?? 0) >= 2 }) == ["alphabet", "beta"] else {
                throw ProbeFailure.message(">= predicate failed")
            }
            guard try titles(NSPredicate { object, _ in (cdInt(object, "count") ?? 0) <= 2 }) == ["alpha", "beta"] else {
                throw ProbeFailure.message("<= predicate failed")
            }
            guard try titles(NSPredicate { object, _ in cdString(object, "title")?.contains("lph") == true }) == ["alpha", "alphabet"] else {
                throw ProbeFailure.message("CONTAINS predicate failed")
            }
            guard try titles(NSPredicate { object, _ in cdString(object, "title")?.hasPrefix("be") == true }) == ["beta"] else {
                throw ProbeFailure.message("BEGINSWITH predicate failed")
            }
            guard try titles(NSPredicate { object, _ in cdString(object, "title")?.hasSuffix("et") == true }) == ["alphabet"] else {
                throw ProbeFailure.message("ENDSWITH predicate failed")
            }
            guard try titles(NSPredicate { object, _ in ["beta", "missing"].contains(cdString(object, "title") ?? "") }) == ["beta"] else {
                throw ProbeFailure.message("IN predicate failed")
            }
            guard try titles(NSPredicate { object, _ in cdString(object, "title") == "alpha" && cdInt(object, "count") == 1 }) == ["alpha"] else {
                throw ProbeFailure.message("AND predicate failed")
            }
            guard try titles(NSPredicate { object, _ in cdString(object, "title") == "alpha" || cdString(object, "title") == "beta" }) == ["alpha", "beta"] else {
                throw ProbeFailure.message("OR predicate failed")
            }
            guard try titles(NSPredicate { object, _ in cdString(object, "title") != "beta" }) == ["alpha", "alphabet"] else {
                throw ProbeFailure.message("NOT predicate failed")
            }
    } catch {
        fatalError("testPredicatesByOperator failed: \(error)")
    }
}

func testPredicateFormatsAndResultTypes() {
    do {
            let container = try makeLoadedContainer(makeAuthorNoteModel(), name: "Predicates")
            let context = container.viewContext
            let author = NSEntityDescription.insertNewObject(forEntityName: "Author", into: context)
            author.setValue("Ada", forKey: "name")
            for title in ["alpha", "beta", "alphabet"] {
                let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                note.setValue(title, forKey: "title")
                note.setValue(author, forKey: "author")
            }
            try context.save()

            let contains = NSFetchRequest<NSManagedObject>(entityName: "Note")
            contains.predicate = NSPredicate { object, _ in cdString(object, "title")?.contains("lph") == true }
            contains.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
            let contained = try context.fetch(contains)
            guard contained.map({ $0.value(forKey: "title") as? String }) == ["alpha", "alphabet"] else {
                throw ProbeFailure.message("CONTAINS/sort mismatch: \(contained.map { $0.value(forKey: "title") as? String })")
            }

            let begins = NSFetchRequest<NSManagedObject>(entityName: "Note")
            begins.predicate = NSPredicate { object, _ in cdString(object, "title")?.hasPrefix("be") == true }
            guard try context.fetch(begins).count == 1 else {
                throw ProbeFailure.message("BEGINSWITH should match beta")
            }

            let compound = NSFetchRequest<NSManagedObject>(entityName: "Note")
            compound.predicate = NSPredicate { object, _ in
                let author = (object as? NSManagedObject)?.value(forKey: "author") as? NSManagedObject
                return cdString(object, "title") == "alpha" && (author?.value(forKey: "name") as? String) == "Ada"
            }
            guard try context.fetch(compound).count == 1 else {
                throw ProbeFailure.message("compound AND + relationship key path failed")
            }

            let membership = NSFetchRequest<NSManagedObject>(entityName: "Note")
            membership.predicate = NSPredicate { object, _ in ["beta", "missing"].contains(cdString(object, "title") ?? "") }
            guard try context.fetch(membership).count == 1 else {
                throw ProbeFailure.message("IN predicate failed")
            }

            let limited = NSFetchRequest<NSManagedObject>(entityName: "Note")
            limited.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
            limited.fetchOffset = 1
            limited.fetchLimit = 1
            let sliced = try context.fetch(limited)
            guard sliced.first?.value(forKey: "title") as? String == "alphabet" else {
                throw ProbeFailure.message("fetchOffset/fetchLimit mismatch")
            }

            let countRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
            countRequest.resultType = .countResultType
            guard try context.count(for: countRequest) == 3 else {
                throw ProbeFailure.message("count(for:) must ignore resultType and return 3")
            }

            let ids = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
            ids.resultType = .managedObjectIDResultType
            let idResults = try context.fetch(ids)
            guard idResults.count == 3, idResults.first is NSManagedObjectID else {
                throw ProbeFailure.message("managedObjectIDResultType must return NSManagedObjectID values")
            }

            let dicts = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
            dicts.resultType = .dictionaryResultType
            dicts.propertiesToFetch = ["title"]
            let dictResults = try context.fetch(dicts)
            guard dictResults.count == 3, dictResults.first is NSDictionary else {
                throw ProbeFailure.message("dictionaryResultType must return NSDictionary values")
            }

            let faults = NSFetchRequest<NSManagedObject>(entityName: "Note")
            faults.returnsObjectsAsFaults = true
            faults.resultType = .managedObjectResultType
            let faulted = try context.fetch(faults)
            guard let first = faulted.first else {
                throw ProbeFailure.message("managedObjectResultType returned nothing")
            }
            _ = first.value(forKey: "title")
    } catch {
        fatalError("testPredicateFormatsAndResultTypes failed: \(error)")
    }
}


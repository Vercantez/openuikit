import Foundation
import CoreData
func testFRCSectionsAndChangeNotifications() {
    do {
            final class SectionProbe: NSObject, NSFetchedResultsControllerDelegate {
                var events: [String] = []
                func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
                    events.append("will")
                }
                func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
                    events.append("did")
                }
                func controller(
                    _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?
                ) {
                    switch type {
                    case .insert: events.append("insert")
                    case .delete: events.append("delete")
                    case .move: events.append("move")
                    case .update: events.append("update")
                    }
                }
                func controller(
                    _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                    didChange sectionInfo: any NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType
                ) {
                    events.append(type == .insert ? "section-insert" : "section-delete")
                }
            }

            let container = try makeLoadedContainer(makeNoteModel(), name: "FRCSections")
            let context = container.viewContext
            let first = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            first.setValue("alpha", forKey: "title")
            try context.save()

            let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
            request.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
            let frc = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: "title",
                cacheName: "section-cache"
            )
            let probe = SectionProbe()
            frc.delegate = probe
            try frc.performFetch()
            guard frc.sections?.count == 1,
                  frc.sections?.first?.name == "alpha",
                  frc.sections?.first?.numberOfObjects == 1,
                  (frc.object(at: IndexPath(indexes: [0, 0])) as? NSManagedObject)?.value(forKey: "title") as? String == "alpha" else {
                throw ProbeFailure.message("FRC initial section state mismatch")
            }
            _ = frc.sectionIndexTitles
            _ = frc.section(forSectionIndexTitle: "a", at: 0)
            NSFetchedResultsController<any NSFetchRequestResult>.deleteCache(withName: "section-cache")

            let second = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            second.setValue("beta", forKey: "title")
            try context.save()
            guard frc.sections?.count == 2,
                  probe.events.contains("section-insert"),
                  probe.events.contains("insert"),
                  probe.events.first == "will",
                  probe.events.last == "did" else {
                throw ProbeFailure.message("FRC section insert notifications mismatch: \(probe.events) sections=\(frc.sections?.count ?? -1)")
            }

            context.delete(second)
            try context.save()
            guard frc.sections?.count == 1,
                  probe.events.contains("section-delete"),
                  probe.events.contains("delete") else {
                throw ProbeFailure.message("FRC section delete notifications mismatch: \(probe.events)")
            }
    } catch {
        fatalError("testFRCSectionsAndChangeNotifications failed: \(error)")
    }
}

func testFetchedResultsControllerDelegateOrder() {
    do {
            final class ProbeDelegate: NSObject, NSFetchedResultsControllerDelegate {
                var events: [String] = []
                func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
                    events.append("will")
                }
                func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
                    events.append("did")
                }
                func controller(
                    _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?
                ) {
                    switch type {
                    case .insert: events.append("insert")
                    case .delete: events.append("delete")
                    case .move: events.append("move")
                    case .update: events.append("update")
                    }
                }
                func controller(
                    _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                    didChange sectionInfo: any NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType
                ) {
                    events.append(type == .insert ? "section-insert" : "section-delete")
                }
            }

            let container = try makeLoadedContainer(makeNoteModel(), name: "FRCDelegate")
            let context = container.viewContext
            let first = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            first.setValue("one", forKey: "title")
            try context.save()

            let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
            request.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
            let frc = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: "title",
                cacheName: "notes-cache"
            )
            let probe = ProbeDelegate()
            frc.delegate = probe
            try frc.performFetch()
            guard frc.fetchedObjects?.count == 1,
                  frc.sections?.count == 1,
                  (frc.object(at: IndexPath(indexes: [0, 0])) as? NSManagedObject)?.value(forKey: "title") as? String == "one" else {
                throw ProbeFailure.message("FRC initial fetch/section lookup failed")
            }
            guard frc.indexPath(forObject: first) != nil else {
                throw ProbeFailure.message("FRC indexPath(forObject:) missed the saved note")
            }
            _ = frc.sectionIndexTitles
            _ = frc.section(forSectionIndexTitle: "o", at: 0)
            NSFetchedResultsController<any NSFetchRequestResult>.deleteCache(withName: "notes-cache")

            let second = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            second.setValue("two", forKey: "title")
            try context.save()
            guard probe.events.first == "will", probe.events.contains("insert"), probe.events.last == "did" else {
                throw ProbeFailure.message("FRC delegate order mismatch: \(probe.events)")
            }
            guard let willIndex = probe.events.firstIndex(of: "will"),
                  let insertIndex = probe.events.firstIndex(of: "insert"),
                  let didIndex = probe.events.lastIndex(of: "did"),
                  willIndex < insertIndex, insertIndex < didIndex else {
                throw ProbeFailure.message("FRC will/insert/did order mismatch: \(probe.events)")
            }
    } catch {
        fatalError("testFetchedResultsControllerDelegateOrder failed: \(error)")
    }
}


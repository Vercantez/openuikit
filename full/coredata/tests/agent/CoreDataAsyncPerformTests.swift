import Foundation
import CoreData

func testAsyncContextPerformSchedule() async throws {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "AsyncPerformSchedule")
        let context = container.viewContext
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("async-schedule", forKey: "title")
        try context.save()
        let title: String = try await context.perform(schedule: .immediate) {
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "Note")
            let rows = try context.fetch(fetch)
            guard let first = rows.first,
                  let value = first.value(forKey: "title") as? String else {
                throw ProbeFailure.message("async perform(schedule:) fetch missed the saved note")
            }
            return value
        }
        guard title == "async-schedule" else {
            throw ProbeFailure.message("async perform(schedule:) returned \(title)")
        }
        let enqueued: Int = try await context.perform(schedule: .enqueued) { 7 }
        guard enqueued == 7 else {
            throw ProbeFailure.message("async perform(schedule:.enqueued) returned \(enqueued)")
        }
    } catch {
        fatalError("testAsyncContextPerformSchedule failed: \(error)")
    }
}

func testAsyncCoordinatorPerform() async {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "AsyncCoordinatorPerform")
        let coordinator = container.persistentStoreCoordinator
        let value = await coordinator.perform { 42 }
        guard value == 42 else {
            fatalError("async coordinator perform returned \(value)")
        }
        let stores = await coordinator.perform { coordinator.persistentStores.count }
        guard stores == 1 else {
            fatalError("async coordinator perform saw \(stores) stores")
        }
    } catch {
        fatalError("testAsyncCoordinatorPerform failed: \(error)")
    }
}

func testAsyncContainerBackgroundTask() async throws {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "AsyncBackgroundTask")
        let title: String = try await container.performBackgroundTask { (context: NSManagedObjectContext) throws -> String in
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("bg-async", forKey: "title")
            try context.save()
            return "bg-async"
        }
        guard title == "bg-async" else {
            throw ProbeFailure.message("async performBackgroundTask returned \(title)")
        }
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Note")
        let rows = try container.viewContext.fetch(fetch)
        guard rows.contains(where: { $0.value(forKey: "title") as? String == "bg-async" }) else {
            throw ProbeFailure.message("async background task save did not reach the store")
        }
    } catch {
        fatalError("testAsyncContainerBackgroundTask failed: \(error)")
    }
}

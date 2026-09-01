import Foundation
import CoreData

enum ProbeFailure: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let text): return text
        }
    }
}

func runCoreDataRuntimeProbe() throws {
    let model = NSManagedObjectModel()
    let entity = NSEntityDescription()
    entity.name = "Note"
    entity.managedObjectClassName = "NSManagedObject"

    let title = NSAttributeDescription()
    title.name = "title"
    title.attributeType = .stringAttributeType
    title.isOptional = false

    let count = NSAttributeDescription()
    count.name = "count"
    count.attributeType = .integer64AttributeType
    count.isOptional = true
    count.defaultValue = 0

    entity.properties = [title, count]
    model.entities = [entity]

    let container = NSPersistentContainer(name: "RuntimeNotes", managedObjectModel: model)
    let description = NSPersistentStoreDescription(url: URL(string: "x-coredata-in-memory://runtime")!)
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]

    var loadError: (any Error)?
    container.loadPersistentStores { _, error in
        loadError = error
    }
    if let loadError {
        throw ProbeFailure.message("loadPersistentStores failed: \(loadError)")
    }

    let sqlite = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/tmp/should-not-open.sqlite"))
    sqlite.type = NSSQLiteStoreType
    var sqliteFailed = false
    container.persistentStoreCoordinator.addPersistentStore(with: sqlite) { _, error in
        sqliteFailed = error != nil
    }
    guard sqliteFailed else {
        throw ProbeFailure.message("SQLite addPersistentStore must fail closed on Linux")
    }

    let context = container.viewContext
    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
    note.setValue("hello", forKey: "title")
    note.setValue(3, forKey: "count")
    guard context.hasChanges else {
        throw ProbeFailure.message("context.hasChanges should be true after insert")
    }
    try context.save()
    guard !context.hasChanges else {
        throw ProbeFailure.message("context.hasChanges should be false after save")
    }

    let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
    request.predicate = NSPredicate { object, _ in
        (object as? NSManagedObject)?.value(forKey: "title") as? String == "hello"
    }
    let fetched = try context.fetch(request)
    guard fetched.count == 1,
          fetched[0].value(forKey: "title") as? String == "hello" else {
        throw ProbeFailure.message("fetch did not return the saved note")
    }

    fetched[0].setValue("updated", forKey: "title")
    try context.save()

    let countRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
    guard try context.count(for: countRequest) == 1 else {
        throw ProbeFailure.message("count mismatch")
    }

    request.predicate = nil
    let frc = NSFetchedResultsController(
        fetchRequest: request,
        managedObjectContext: context,
        sectionNameKeyPath: nil,
        cacheName: nil
    )
    try frc.performFetch()
    guard frc.fetchedObjects?.count == 1 else {
        throw ProbeFailure.message("NSFetchedResultsController did not fetch saved objects")
    }

    let background = container.newBackgroundContext()
    var backgroundCount = 0
    background.performAndWait {
        let notes = (try? background.fetch(NSFetchRequest<NSManagedObject>(entityName: "Note"))) ?? []
        backgroundCount = notes.count
    }
    guard backgroundCount == 1 else {
        throw ProbeFailure.message("background context did not see saved in-memory rows")
    }

    context.delete(fetched[0])
    try context.save()
    guard try context.count(for: countRequest) == 0 else {
        throw ProbeFailure.message("delete/save did not remove the object")
    }

    do {
        _ = try NSMappingModel.inferredMappingModel(forSourceModel: model, destinationModel: model)
        throw ProbeFailure.message("inferred mapping must fail closed")
    } catch is ProbeFailure {
        throw ProbeFailure.message("inferred mapping must fail closed")
    } catch {
        // expected fail-closed mapping error
    }

    let cloud = NSPersistentCloudKitContainer(name: "Cloud", managedObjectModel: model)
    do {
        try cloud.initializeCloudKitSchema()
        throw ProbeFailure.message("CloudKit schema init must fail closed")
    } catch is ProbeFailure {
        throw ProbeFailure.message("CloudKit schema init must fail closed")
    } catch {
        // expected
    }

    guard NSInMemoryStoreType == "InMemory",
          NSSQLiteStoreType == "SQLite",
          NSMergePolicy.error.mergeType == .errorMergePolicyType,
          CocoaError.Code.persistentStoreOpenError.rawValue == NSPersistentStoreOpenError else {
        throw ProbeFailure.message("constants mismatch")
    }

    print("COREDATA_AGENT_RUNTIME_OK")
}

try runCoreDataRuntimeProbe()

import Foundation
import Dispatch
import CoreData

// Future clean EC2 dependency-identity client for CoreData.
//
// This file is not compiled by the isolated host gate (`tests/acceptance/test_host.sh`).
// A future EC2 run must:
//   1. Build the real guest Foundation and Dispatch modules/dylibs first.
//   2. Build this framework with those -I/-L paths (SQLite is not a dependency:
//      this PR does not implement NSSQLiteStoreType).
//   3. Link a client that imports CoreData plus those dependencies.
//   4. Run with LD_LIBRARY_PATH so libCoreData.dylib loads.
//   5. Pass real Foundation predicates, notifications, URLs, Data, and Dispatch
//      queue types through public CoreData APIs.
//   6. Confirm context queue identity, child isolation, the exact marker below,
//      and that libCoreData.dylib is loaded.
// Isolated-gate success is not integrated Linux success.

enum DependencyIdentityFailure: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let text): return text
        }
    }
}

func runCoreDataDependencyIdentity() throws {
    let model = NSManagedObjectModel()
    let entity = NSEntityDescription()
    entity.name = "IdentityNote"
    entity.managedObjectClassName = "NSManagedObject"

    let title = NSAttributeDescription()
    title.name = "title"
    title.attributeType = .stringAttributeType
    title.isOptional = false

    let payload = NSAttributeDescription()
    payload.name = "payload"
    payload.attributeType = .binaryDataAttributeType
    payload.isOptional = true

    entity.properties = [title, payload]
    model.entities = [entity]

    let storeURL = URL(string: "x-coredata-in-memory://dependency-identity")!
    let container = NSPersistentContainer(name: "DependencyIdentity", managedObjectModel: model)
    let description = NSPersistentStoreDescription(url: storeURL)
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]

    var loadError: (any Error)?
    container.loadPersistentStores { _, error in
        loadError = error
    }
    if let loadError {
        throw DependencyIdentityFailure.message("loadPersistentStores failed: \(loadError)")
    }

    let mainContext = container.viewContext
    guard mainContext.concurrencyType == .mainQueueConcurrencyType else {
        throw DependencyIdentityFailure.message("viewContext must be a main-queue context")
    }

    final class SaveFlag: @unchecked Sendable {
        var value = false
    }
    let didSave = SaveFlag()
    let observer = NotificationCenter.default.addObserver(
        forName: NSManagedObjectContext.didSaveObjectsNotification,
        object: mainContext,
        queue: nil
    ) { notification in
        _ = notification.name
        didSave.value = true
    }
    defer { NotificationCenter.default.removeObserver(observer) }

    let blob = Data([0xC0, 0xDA, 0x7A])
    var mainOnMain = false
    mainContext.performAndWait {
        mainOnMain = Thread.isMainThread
        let note = NSEntityDescription.insertNewObject(forEntityName: "IdentityNote", into: mainContext)
        note.setValue("identity", forKey: "title")
        note.setValue(blob, forKey: "payload")
        try? mainContext.save()
    }
    guard mainOnMain else {
        throw DependencyIdentityFailure.message("mainQueueConcurrencyType must use the main executor")
    }
    guard didSave.value else {
        throw DependencyIdentityFailure.message("Foundation NotificationCenter did not observe a CoreData save")
    }

    let request = NSFetchRequest<NSManagedObject>(entityName: "IdentityNote")
    request.predicate = NSPredicate { object, _ in
        (object as? NSManagedObject)?.value(forKey: "title") as? String == "identity"
    }
    let fetched = try mainContext.fetch(request)
    guard fetched.count == 1,
          fetched[0].value(forKey: "payload") as? Data == blob else {
        throw DependencyIdentityFailure.message("Foundation NSPredicate/Data did not round-trip through CoreData")
    }
    guard fetched[0].objectID.uriRepresentation().scheme == "x-coredata" else {
        throw DependencyIdentityFailure.message("Foundation URL uriRepresentation was not produced")
    }

    let privateContext = container.newBackgroundContext()
    guard privateContext.concurrencyType == .privateQueueConcurrencyType else {
        throw DependencyIdentityFailure.message("background context must be a private-queue context")
    }
    var privateOnMain = true
    let privateDone = DispatchSemaphore(value: 0)
    privateContext.perform {
        privateOnMain = Thread.isMainThread
        privateDone.signal()
    }
    guard privateDone.wait(timeout: .now() + 5) == .success, privateOnMain == false else {
        throw DependencyIdentityFailure.message("privateQueueConcurrencyType must use a dedicated serial executor")
    }

    let child = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    child.parent = mainContext
    var childObject: NSManagedObject?
    child.performAndWait {
        let note = NSEntityDescription.insertNewObject(forEntityName: "IdentityNote", into: child)
        note.setValue("child-identity", forKey: "title")
        note.setValue(Data([0x11]), forKey: "payload")
        childObject = note
        try? child.save()
    }
    guard let childObject, childObject.managedObjectContext === child else {
        throw DependencyIdentityFailure.message("child save must not change the child object's context")
    }
    let parentNotes = try mainContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "IdentityNote"))
    guard let parentClone = parentNotes.first(where: { $0.value(forKey: "title") as? String == "child-identity" }) else {
        throw DependencyIdentityFailure.message("child save must snapshot values into the parent context")
    }
    guard parentClone !== childObject, parentClone.managedObjectContext === mainContext else {
        throw DependencyIdentityFailure.message("child isolation failed: parent reused the child NSManagedObject")
    }

    print("COREDATA_DEPENDENCY_IDENTITY_OK")
}

try runCoreDataDependencyIdentity()

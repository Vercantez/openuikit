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

final class AgentProbePersistentStore: NSPersistentStore {
    override var type: String { "AgentProbeStoreType" }
}

func runCoreDataRuntimeProbe() throws {
    try testInMemoryCRUDAndFailClosed()
    try testQueueIdentity()
    try testQueueSerialization()
    try testQueueReentrancy()
    try testPerformOrdering()
    try testGenericPerformOverloads()
    try testCommittedSnapshotsAndChangedBack()
    try testOldNilCommittedValues()
    try testRollbackRestoresCommitted()
    try testChildIsolation()
    try testRegisteredStoreClass()
    try testDefaultDirectoryURLHasNoEagerFilesystemSideEffects()
    try testUnknownVersionNumberIsNotFabricated()
    print("COREDATA_AGENT_RUNTIME_OK")
}

func makeNoteModel() -> NSManagedObjectModel {
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

    let body = NSAttributeDescription()
    body.name = "body"
    body.attributeType = .stringAttributeType
    body.isOptional = true

    entity.properties = [title, count, body]
    model.entities = [entity]
    return model
}

func makeLoadedContainer(_ model: NSManagedObjectModel, name: String = "RuntimeNotes") throws -> NSPersistentContainer {
    let container = NSPersistentContainer(name: name, managedObjectModel: model)
    let description = NSPersistentStoreDescription(url: URL(string: "x-coredata-in-memory://\(name)")!)
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]

    var loadError: (any Error)?
    container.loadPersistentStores { _, error in
        loadError = error
    }
    if let loadError {
        throw ProbeFailure.message("loadPersistentStores failed: \(loadError)")
    }
    return container
}

func withUniqueTempDirectory(_ body: (URL) throws -> Void) throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("coredata-agent-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    try body(directory)
}

func waitUntil(_ timeout: TimeInterval, _ predicate: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !predicate(), Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }
    return predicate()
}

func testInMemoryCRUDAndFailClosed() throws {
    let model = makeNoteModel()
    let container = try makeLoadedContainer(model)

    try withUniqueTempDirectory { directory in
        let sqliteURL = directory.appendingPathComponent("should-not-open.sqlite")
        let sqlite = NSPersistentStoreDescription(url: sqliteURL)
        sqlite.type = NSSQLiteStoreType
        var sqliteFailed = false
        container.persistentStoreCoordinator.addPersistentStore(with: sqlite) { _, error in
            sqliteFailed = error != nil
        }
        guard sqliteFailed else {
            throw ProbeFailure.message("SQLite addPersistentStore must fail closed on Linux")
        }
        guard !FileManager.default.fileExists(atPath: sqliteURL.path) else {
            throw ProbeFailure.message("fail-closed SQLite open must not create \(sqliteURL.path)")
        }
    }

    let context = container.viewContext
    final class SaveFlag: @unchecked Sendable {
        var value = false
    }
    let didSave = SaveFlag()
    let observer = NotificationCenter.default.addObserver(
        forName: .NSManagedObjectContextDidSave,
        object: context,
        queue: nil
    ) { _ in
        didSave.value = true
    }
    defer { NotificationCenter.default.removeObserver(observer) }

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
    guard didSave.value else {
        throw ProbeFailure.message("save must post NSManagedObjectContextDidSave")
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
}

func testQueueIdentity() throws {
    let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    var mainWaitOnMain = false
    mainContext.performAndWait {
        mainWaitOnMain = Thread.isMainThread
    }
    guard mainWaitOnMain else {
        throw ProbeFailure.message("mainQueueConcurrencyType performAndWait must run on the main executor")
    }

    var mainAsyncOnMain = false
    var mainAsyncRan = false
    mainContext.perform {
        mainAsyncOnMain = Thread.isMainThread
        mainAsyncRan = true
    }
    guard waitUntil(2, { mainAsyncRan }), mainAsyncOnMain else {
        throw ProbeFailure.message("mainQueueConcurrencyType perform must run on the main executor")
    }

    let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    var privateAsyncOnMain = true
    let signal = DispatchSemaphore(value: 0)
    privateContext.perform {
        privateAsyncOnMain = Thread.isMainThread
        signal.signal()
    }
    guard signal.wait(timeout: .now() + 5) == .success, privateAsyncOnMain == false else {
        throw ProbeFailure.message("privateQueueConcurrencyType perform must use a dedicated serial executor")
    }
}

func testQueueSerialization() throws {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    var overlapping = 0
    var maxOverlap = 0
    let spin = NSLock()
    let group = DispatchGroup()
    for _ in 0..<6 {
        group.enter()
        context.perform {
            spin.lock()
            overlapping += 1
            maxOverlap = max(maxOverlap, overlapping)
            spin.unlock()
            Thread.sleep(forTimeInterval: 0.02)
            spin.lock()
            overlapping -= 1
            spin.unlock()
            group.leave()
        }
    }
    guard group.wait(timeout: .now() + 5) == .success, maxOverlap == 1 else {
        throw ProbeFailure.message("private-queue work must be serialized, maxOverlap=\(maxOverlap)")
    }
}

func testQueueReentrancy() throws {
    let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    var mainNested = false
    mainContext.performAndWait {
        mainContext.performAndWait {
            mainNested = Thread.isMainThread
        }
    }
    guard mainNested else {
        throw ProbeFailure.message("main-queue performAndWait must be reentrant")
    }

    let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    var privateNested = false
    privateContext.performAndWait {
        privateContext.performAndWait {
            privateNested = true
        }
    }
    guard privateNested else {
        throw ProbeFailure.message("private-queue performAndWait must be reentrant and must not deadlock")
    }
}

func testPerformOrdering() throws {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    let lock = NSLock()
    var order: [String] = []
    func append(_ value: String) {
        lock.lock()
        order.append(value)
        lock.unlock()
    }
    let outerDone = DispatchSemaphore(value: 0)
    let enqueuedDone = DispatchSemaphore(value: 0)
    context.perform {
        append("outer-start")
        context.performAndWait {
            append("immediate")
        }
        context.perform {
            append("enqueued")
            enqueuedDone.signal()
        }
        append("outer-end")
        outerDone.signal()
    }
    guard outerDone.wait(timeout: .now() + 5) == .success,
          enqueuedDone.wait(timeout: .now() + 5) == .success,
          order == ["outer-start", "immediate", "outer-end", "enqueued"] else {
        throw ProbeFailure.message("perform immediate versus enqueued ordering mismatch: \(order)")
    }

    var scheduled: [String] = []
    let scheduleDone = DispatchSemaphore(value: 0)
    var scheduleError: String?
    Task {
        do {
            _ = try await context.perform(schedule: .enqueued) { () -> Int in
                scheduled.append("enqueued")
                return 1
            }
            _ = try await context.perform(schedule: .immediate) { () -> Int in
                scheduled.append("immediate")
                return 2
            }
        } catch {
            scheduleError = String(describing: error)
        }
        scheduleDone.signal()
    }
    guard scheduleDone.wait(timeout: .now() + 5) == .success else {
        throw ProbeFailure.message("async perform(schedule:) timed out")
    }
    if let scheduleError {
        throw ProbeFailure.message("async perform(schedule:) failed: \(scheduleError)")
    }
    guard scheduled == ["enqueued", "immediate"] else {
        throw ProbeFailure.message("async perform(schedule:) ordering mismatch: \(scheduled)")
    }
}

func testGenericPerformOverloads() throws {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    let value: Int = context.performAndWait { 7 }
    guard value == 7 else {
        throw ProbeFailure.message("generic performAndWait did not return the block result")
    }

    enum Token: Error { case boom }
    do {
        _ = try context.performAndWait { () throws -> Int in
            throw Token.boom
        }
        throw ProbeFailure.message("generic performAndWait must rethrow")
    } catch is Token {
        // expected
    } catch {
        throw ProbeFailure.message("generic performAndWait threw an unexpected error: \(error)")
    }

    let asyncDone = DispatchSemaphore(value: 0)
    var asyncValue = 0
    Task {
        asyncValue = (try? await context.perform(schedule: .immediate) { 11 }) ?? 0
        asyncDone.signal()
    }
    guard asyncDone.wait(timeout: .now() + 5) == .success, asyncValue == 11 else {
        throw ProbeFailure.message("generic perform(schedule:) did not return the block result")
    }
}

func testCommittedSnapshotsAndChangedBack() throws {
    let container = try makeLoadedContainer(makeNoteModel(), name: "Snapshots")
    let context = container.viewContext
    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
    note.setValue("hello", forKey: "title")
    try context.save()

    note.setValue("world", forKey: "title")
    guard note.hasPersistentChangedValues else {
        throw ProbeFailure.message("hasPersistentChangedValues must be true after a persistent edit")
    }
    guard note.changedValues()["title"] as? String == "world" else {
        throw ProbeFailure.message("changedValues must report the new title")
    }
    let committed = note.committedValues(forKeys: ["title"])
    guard committed["title"] as? String == "hello" else {
        throw ProbeFailure.message("committedValues must keep the last saved title")
    }

    note.setValue("hello", forKey: "title")
    guard note.changedValues()["title"] == nil else {
        throw ProbeFailure.message("changedValues must clear a key that returned to its original value")
    }
    guard !note.hasPersistentChangedValues else {
        throw ProbeFailure.message("hasPersistentChangedValues must be false after reverting to the committed value")
    }
    guard !context.hasChanges else {
        throw ProbeFailure.message("context.hasChanges must be false after reverting all persistent diffs")
    }
}

func testOldNilCommittedValues() throws {
    let container = try makeLoadedContainer(makeNoteModel(), name: "OldNil")
    let context = container.viewContext
    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
    note.setValue("nil-body", forKey: "title")
    try context.save()

    let committed = note.committedValues(forKeys: ["body"])
    guard committed["body"] is NSNull else {
        throw ProbeFailure.message("committedValues must represent a committed nil explicitly as NSNull")
    }
    note.setValue("text", forKey: "body")
    guard note.hasPersistentChangedValues else {
        throw ProbeFailure.message("setting a previously nil attribute must count as a persistent change")
    }
    note.setValue(nil, forKey: "body")
    guard note.changedValues()["body"] == nil else {
        throw ProbeFailure.message("changing a value back to the original nil must clear changedValues")
    }
    guard !note.hasPersistentChangedValues else {
        throw ProbeFailure.message("hasPersistentChangedValues must be false after restoring the original nil")
    }
}

func testRollbackRestoresCommitted() throws {
    let container = try makeLoadedContainer(makeNoteModel(), name: "Rollback")
    let context = container.viewContext
    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
    note.setValue("saved", forKey: "title")
    try context.save()

    note.setValue("dirty", forKey: "title")
    context.rollback()
    guard note.value(forKey: "title") as? String == "saved" else {
        throw ProbeFailure.message("rollback must restore committed attribute values")
    }
    guard !context.hasChanges else {
        throw ProbeFailure.message("rollback must clear context changes")
    }

    let extra = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
    extra.setValue("unsaved", forKey: "title")
    context.rollback()
    guard extra.managedObjectContext == nil else {
        throw ProbeFailure.message("rollback must detach unsaved inserts")
    }
    guard try context.count(for: NSFetchRequest<NSManagedObject>(entityName: "Note")) == 1 else {
        throw ProbeFailure.message("rollback must discard unsaved inserts")
    }
}

func testChildIsolation() throws {
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
}

func testRegisteredStoreClass() throws {
    let typeName = "AgentProbeStoreType"
    NSPersistentStoreCoordinator.registerStoreClass(AgentProbePersistentStore.self, forStoreType: typeName)
    defer { NSPersistentStoreCoordinator.registerStoreClass(nil, forStoreType: typeName) }

    let registered = NSPersistentStoreCoordinator.registeredStoreTypes
    guard registered[typeName] != nil else {
        throw ProbeFailure.message("registeredStoreTypes must include a registered custom store type")
    }
    guard registered[NSInMemoryStoreType] != nil else {
        throw ProbeFailure.message("registeredStoreTypes must include the built-in in-memory store")
    }

    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeNoteModel())
    let store = try coordinator.addPersistentStore(
        ofType: typeName,
        configurationName: nil,
        at: URL(string: "x-coredata-agent-probe://store")!,
        options: nil
    )
    guard store is AgentProbePersistentStore else {
        throw ProbeFailure.message("addPersistentStore must instantiate the registered custom store class")
    }

    try withUniqueTempDirectory { directory in
        do {
            _ = try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: directory.appendingPathComponent("unregistered.sqlite"),
                options: nil
            )
            throw ProbeFailure.message("unregistered SQLite store type must stay unsupported")
        } catch is ProbeFailure {
            throw ProbeFailure.message("unregistered SQLite store type must stay unsupported")
        } catch {
            // expected platform blocker
        }
    }
}

func testDefaultDirectoryURLHasNoEagerFilesystemSideEffects() throws {
    let directory = NSPersistentContainer.defaultDirectoryURL()
    guard directory.isFileURL else {
        throw ProbeFailure.message("defaultDirectoryURL must return a file URL")
    }
    let uniqueName = "NoEager-\(UUID().uuidString)"
    _ = NSPersistentContainer(name: uniqueName, managedObjectModel: makeNoteModel())
    let sqliteURL = directory.appendingPathComponent("\(uniqueName).sqlite")
    guard !FileManager.default.fileExists(atPath: sqliteURL.path) else {
        throw ProbeFailure.message("container init must not eagerly create \(sqliteURL.path)")
    }
}

func testUnknownVersionNumberIsNotFabricated() throws {
    guard NSCoreDataVersionNumber == 0 else {
        throw ProbeFailure.message("NSCoreDataVersionNumber must stay unknown (0) until an Apple-oracle value exists")
    }
}

try runCoreDataRuntimeProbe()

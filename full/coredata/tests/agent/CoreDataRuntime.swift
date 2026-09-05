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
    try testModelConstruction()
    try testEntityAttributeRelationshipDescriptions()
    try testContextInsertSaveFetch()
    try testFaulting()
    try testRelationshipsFaultingAndInverses()
    try testDeleteRules()
    try testPredicatesByOperator()
    try testSortLimitResultTypes()
    try testPredicateFormatsAndResultTypes()
    try testFRCSectionsAndChangeNotifications()
    try testFetchedResultsControllerDelegateOrder()
    try testBatchRequests()
    try testMergePolicies()
    try testMergePolicyAndParentMerge()
    try testErrorCodes()
    try testValidationAndUndoDisabled()
    try testModelMetadataAndStoreCoordinator()
    try testFailClosedSurfaces()
    try testPublicConstantsCatalog()
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

/// Linux Foundation has no KVC `NSSortDescriptor(key:)`. Comparators still
/// sort in-memory objects by attribute name.
func cdSortDescriptor(key: String, ascending: Bool) -> NSSortDescriptor {
    _CDAttributeSortDescriptor(attributeKey: key, ascending: ascending)
}

func cdInt(_ object: Any?, _ key: String) -> Int? {
    let value = (object as? NSManagedObject)?.value(forKey: key)
    if let number = value as? Int { return number }
    if let number = value as? NSNumber { return number.intValue }
    return nil
}

func cdString(_ object: Any?, _ key: String) -> String? {
    (object as? NSManagedObject)?.value(forKey: key) as? String
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

func makeAuthorNoteModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    let author = NSEntityDescription()
    author.name = "Author"
    author.managedObjectClassName = "NSManagedObject"
    let authorName = NSAttributeDescription()
    authorName.name = "name"
    authorName.attributeType = .stringAttributeType
    authorName.isOptional = false
    let notesRel = NSRelationshipDescription()
    notesRel.name = "notes"
    notesRel.minCount = 0
    notesRel.maxCount = 0
    notesRel.deleteRule = .cascadeDeleteRule
    notesRel.isOrdered = false

    let note = NSEntityDescription()
    note.name = "Note"
    note.managedObjectClassName = "NSManagedObject"
    let title = NSAttributeDescription()
    title.name = "title"
    title.attributeType = .stringAttributeType
    title.isOptional = false
    let body = NSAttributeDescription()
    body.name = "body"
    body.attributeType = .stringAttributeType
    body.isOptional = true
    let starred = NSAttributeDescription()
    starred.name = "starred"
    starred.attributeType = .booleanAttributeType
    starred.isOptional = true
    starred.defaultValue = false
    let authorRel = NSRelationshipDescription()
    authorRel.name = "author"
    authorRel.maxCount = 1
    authorRel.minCount = 0
    authorRel.deleteRule = .nullifyDeleteRule
    authorRel.destinationEntity = author
    notesRel.destinationEntity = note
    authorRel.inverseRelationship = notesRel
    notesRel.inverseRelationship = authorRel
    author.properties = [authorName, notesRel]
    note.properties = [title, body, starred, authorRel]
    model.entities = [author, note]
    return model
}

func testModelConstruction() throws {
    let model = makeAuthorNoteModel()
    guard model.entities.count == 2,
          model.entitiesByName["Author"] != nil,
          model.entitiesByName["Note"] != nil else {
        throw ProbeFailure.message("programmatic model must expose Author and Note entities")
    }
    model.setEntities(model.entities, forConfigurationName: "Default")
    model.setFetchRequestTemplate(NSFetchRequest<any NSFetchRequestResult>(entityName: "Note"), forName: "allNotes")
    model.versionIdentifiers = ["v-depth"]
    model.localizationDictionary = ["Note": "Note"]
    guard model.entities(forConfigurationName: "Default")?.count == 2,
          model.fetchRequestTemplate(forName: "allNotes") != nil,
          model.fetchRequestFromTemplate(withName: "allNotes", substitutionVariables: [:]) != nil,
          !model.versionChecksum.isEmpty,
          model.isConfiguration(withName: "Default", compatibleWithStoreMetadata: [:]) else {
        throw ProbeFailure.message("model configuration/template/checksum construction failed")
    }
    guard NSManagedObjectModel(contentsOf: URL(fileURLWithPath: "/tmp/missing-depth.momd")) == nil else {
        throw ProbeFailure.message("compiled momd loading must fail closed")
    }
    guard NSManagedObjectModel(byMerging: [model]) != nil else {
        throw ProbeFailure.message("byMerging a constructed model should succeed")
    }
    guard NSManagedObjectModel.mergedModel(from: nil) == nil else {
        throw ProbeFailure.message("mergedModel(from bundles:) must stay fail-closed without momd bytes")
    }
    let empty = NSManagedObjectModel()
    guard empty.entities.isEmpty else {
        throw ProbeFailure.message("empty model must start with no entities")
    }
}

func testEntityAttributeRelationshipDescriptions() throws {
    let model = makeAuthorNoteModel()
    guard let author = model.entitiesByName["Author"],
          let note = model.entitiesByName["Note"] else {
        throw ProbeFailure.message("entitiesByName missing Author/Note")
    }
    guard let name = author.attributesByName["name"],
          name.attributeType == .stringAttributeType,
          name.isOptional == false,
          author.propertiesByName["name"] != nil else {
        throw ProbeFailure.message("Author.name attribute description mismatch")
    }
    guard let title = note.attributesByName["title"],
          title.attributeType == .stringAttributeType,
          let starred = note.attributesByName["starred"],
          starred.attributeType == .booleanAttributeType,
          starred.defaultValue as? Bool == false else {
        throw ProbeFailure.message("Note attribute descriptions mismatch")
    }
    guard let notesRel = author.relationshipsByName["notes"],
          let authorRel = note.relationshipsByName["author"],
          notesRel.isToMany,
          notesRel.maxCount == 0,
          notesRel.deleteRule == .cascadeDeleteRule,
          authorRel.maxCount == 1,
          authorRel.isToMany == false,
          authorRel.deleteRule == .nullifyDeleteRule,
          notesRel.inverseRelationship === authorRel,
          authorRel.inverseRelationship === notesRel,
          notesRel.destinationEntity === note,
          authorRel.destinationEntity === author else {
        throw ProbeFailure.message("relationship description inverse/cardinality/delete-rule mismatch")
    }
    guard note.properties.contains(where: { $0.name == "title" }),
          author.propertiesByName["notes"] is NSRelationshipDescription else {
        throw ProbeFailure.message("properties/propertiesByName did not surface relationship descriptions")
    }
}

func testContextInsertSaveFetch() throws {
    let container = try makeLoadedContainer(makeNoteModel(), name: "InsertSaveFetch")
    let context = container.viewContext
    guard context.hasChanges == false else {
        throw ProbeFailure.message("fresh context should have no changes")
    }
    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
    note.setValue("insert-save-fetch", forKey: "title")
    note.setValue(7, forKey: "count")
    guard context.hasChanges, context.insertedObjects.contains(note) else {
        throw ProbeFailure.message("insert must register the object and mark hasChanges")
    }
    try context.save()
    guard !context.hasChanges, context.insertedObjects.isEmpty else {
        throw ProbeFailure.message("save must clear insertedObjects/hasChanges")
    }
    let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
    let fetched = try context.fetch(request)
    guard fetched.count == 1,
          fetched[0].value(forKey: "title") as? String == "insert-save-fetch",
          fetched[0].value(forKey: "count") as? Int == 7 else {
        throw ProbeFailure.message("fetch did not return the saved insert")
    }
    guard try context.count(for: request) == 1 else {
        throw ProbeFailure.message("count(for:) mismatch after insert/save")
    }
    context.delete(fetched[0])
    try context.save()
    guard try context.count(for: request) == 0 else {
        throw ProbeFailure.message("delete/save did not remove the object")
    }
    let saveRequest = NSSaveChangesRequest(
        inserted: nil,
        updated: nil,
        deleted: nil,
        locked: nil
    )
    guard saveRequest.requestType == .saveRequestType,
          saveRequest.insertedObjects == nil,
          saveRequest.updatedObjects == nil,
          saveRequest.deletedObjects == nil,
          saveRequest.lockedObjects == nil else {
        throw ProbeFailure.message("NSSaveChangesRequest stores the object sets it was given")
    }
    _ = NSSaveChangesRequest(insertedObjects: nil, updatedObjects: nil, deletedObjects: nil, lockedObjects: nil)
}

func testFaulting() throws {
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
}

func testPredicatesByOperator() throws {
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
}

func testSortLimitResultTypes() throws {
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
}

func testFRCSectionsAndChangeNotifications() throws {
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
}

func testMergePolicies() throws {
    let container = try makeLoadedContainer(makeNoteModel(), name: "MergePolicies")
    let parent = container.viewContext
    parent.mergePolicy = NSMergePolicy.rollback
    let child = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    child.parent = parent
    child.automaticallyMergesChangesFromParent = true
    child.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: parent)
    note.setValue("root", forKey: "title")
    try parent.save()

    let childView = try child.existingObject(with: note.objectID)
    childView.setValue("child-edit", forKey: "title")
    note.setValue("parent-edit", forKey: "title")
    try parent.save()
    guard childView.value(forKey: "title") as? String == "child-edit" else {
        throw ProbeFailure.message("object-trump merge should keep the child's in-memory title")
    }

    child.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    childView.setValue("child-again", forKey: "title")
    note.setValue("store-wins", forKey: "title")
    try parent.save()

    guard NSMergePolicy.error.mergeType == .errorMergePolicyType,
          NSMergePolicy.rollback.mergeType == .rollbackMergePolicyType,
          NSMergePolicy.overwrite.mergeType == .overwriteMergePolicyType,
          NSMergePolicy.mergeByPropertyStoreTrump.mergeType == .mergeByPropertyStoreTrumpMergePolicyType,
          NSMergePolicy.mergeByPropertyObjectTrump.mergeType == .mergeByPropertyObjectTrumpMergePolicyType,
          NSErrorMergePolicy === NSMergePolicy.error,
          NSRollbackMergePolicy === NSMergePolicy.rollback,
          NSOverwriteMergePolicy === NSMergePolicy.overwrite,
          NSMergeByPropertyStoreTrumpMergePolicy === NSMergePolicy.mergeByPropertyStoreTrump,
          NSMergeByPropertyObjectTrumpMergePolicy === NSMergePolicy.mergeByPropertyObjectTrump else {
        throw ProbeFailure.message("NSMergePolicy constants mismatch")
    }
}

func testErrorCodes() throws {
    func eq(_ got: Int, _ expected: Int, _ name: String) throws {
        guard got == expected else {
            throw ProbeFailure.message("\(name) raw value \(got) != \(expected)")
        }
    }
    try eq(NSManagedObjectValidationError, 1550, "NSManagedObjectValidationError")
    try eq(NSValidationMultipleErrorsError, 1560, "NSValidationMultipleErrorsError")
    try eq(NSValidationMissingMandatoryPropertyError, 1570, "NSValidationMissingMandatoryPropertyError")
    try eq(NSValidationRelationshipLacksMinimumCountError, 1580, "NSValidationRelationshipLacksMinimumCountError")
    try eq(NSValidationRelationshipExceedsMaximumCountError, 1590, "NSValidationRelationshipExceedsMaximumCountError")
    try eq(NSValidationRelationshipDeniedDeleteError, 1600, "NSValidationRelationshipDeniedDeleteError")
    try eq(NSValidationNumberTooLargeError, 1610, "NSValidationNumberTooLargeError")
    try eq(NSValidationNumberTooSmallError, 1620, "NSValidationNumberTooSmallError")
    try eq(NSValidationDateTooLateError, 1630, "NSValidationDateTooLateError")
    try eq(NSValidationDateTooSoonError, 1640, "NSValidationDateTooSoonError")
    try eq(NSValidationInvalidDateError, 1650, "NSValidationInvalidDateError")
    try eq(NSValidationStringTooLongError, 1660, "NSValidationStringTooLongError")
    try eq(NSValidationStringTooShortError, 1670, "NSValidationStringTooShortError")
    try eq(NSValidationStringPatternMatchingError, 1680, "NSValidationStringPatternMatchingError")
    try eq(NSValidationInvalidURIError, 1690, "NSValidationInvalidURIError")
    try eq(NSManagedObjectContextLockingError, 132000, "NSManagedObjectContextLockingError")
    try eq(NSPersistentStoreCoordinatorLockingError, 132010, "NSPersistentStoreCoordinatorLockingError")
    try eq(NSManagedObjectReferentialIntegrityError, 133000, "NSManagedObjectReferentialIntegrityError")
    try eq(NSManagedObjectExternalRelationshipError, 133010, "NSManagedObjectExternalRelationshipError")
    try eq(NSManagedObjectMergeError, 133020, "NSManagedObjectMergeError")
    try eq(NSManagedObjectConstraintMergeError, 133021, "NSManagedObjectConstraintMergeError")
    try eq(NSPersistentStoreInvalidTypeError, 134000, "NSPersistentStoreInvalidTypeError")
    try eq(NSPersistentStoreTypeMismatchError, 134010, "NSPersistentStoreTypeMismatchError")
    try eq(NSPersistentStoreIncompatibleSchemaError, 134020, "NSPersistentStoreIncompatibleSchemaError")
    try eq(NSPersistentStoreSaveError, 134030, "NSPersistentStoreSaveError")
    try eq(NSPersistentStoreIncompleteSaveError, 134040, "NSPersistentStoreIncompleteSaveError")
    try eq(NSPersistentStoreSaveConflictsError, 134050, "NSPersistentStoreSaveConflictsError")
    try eq(NSCoreDataError, 134060, "NSCoreDataError")
    try eq(NSPersistentStoreOperationError, 134070, "NSPersistentStoreOperationError")
    try eq(NSPersistentStoreOpenError, 134080, "NSPersistentStoreOpenError")
    try eq(NSPersistentStoreTimeoutError, 134090, "NSPersistentStoreTimeoutError")
    try eq(NSPersistentStoreUnsupportedRequestTypeError, 134091, "NSPersistentStoreUnsupportedRequestTypeError")
    try eq(NSPersistentStoreIncompatibleVersionHashError, 134100, "NSPersistentStoreIncompatibleVersionHashError")
    try eq(NSMigrationError, 134110, "NSMigrationError")
    try eq(NSMigrationConstraintViolationError, 134111, "NSMigrationConstraintViolationError")
    try eq(NSMigrationCancelledError, 134120, "NSMigrationCancelledError")
    try eq(NSMigrationMissingSourceModelError, 134130, "NSMigrationMissingSourceModelError")
    try eq(NSMigrationMissingMappingModelError, 134140, "NSMigrationMissingMappingModelError")
    try eq(NSMigrationManagerSourceStoreError, 134150, "NSMigrationManagerSourceStoreError")
    try eq(NSMigrationManagerDestinationStoreError, 134160, "NSMigrationManagerDestinationStoreError")
    try eq(NSEntityMigrationPolicyError, 134170, "NSEntityMigrationPolicyError")
    try eq(NSSQLiteError, 134180, "NSSQLiteError")
    try eq(NSInferredMappingModelError, 134190, "NSInferredMappingModelError")
    try eq(NSExternalRecordImportError, 134200, "NSExternalRecordImportError")
    try eq(NSPersistentHistoryTokenExpiredError, 134301, "NSPersistentHistoryTokenExpiredError")
    try eq(NSManagedObjectConstraintValidationError, 134400, "NSManagedObjectConstraintValidationError")
    try eq(NSManagedObjectModelReferenceNotFoundError, 134510, "NSManagedObjectModelReferenceNotFoundError")
    try eq(NSStagedMigrationFrameworkVersionMismatchError, 134520, "NSStagedMigrationFrameworkVersionMismatchError")
    try eq(NSStagedMigrationBackwardMigrationError, 134530, "NSStagedMigrationBackwardMigrationError")

    try eq(CocoaError.Code.managedObjectValidationError.rawValue, 1550, "CocoaError.Code.managedObjectValidationError")
    try eq(CocoaError.managedObjectValidation.rawValue, 1550, "CocoaError.managedObjectValidation")
    try eq(CocoaError.Code.validationMultipleErrorsError.rawValue, 1560, "validationMultipleErrorsError")
    try eq(CocoaError.validationMissingMandatoryProperty.rawValue, 1570, "validationMissingMandatoryProperty")
    try eq(CocoaError.Code.validationRelationshipDeniedDeleteError.rawValue, 1600, "validationRelationshipDeniedDeleteError")
    try eq(CocoaError.Code.managedObjectMergeError.rawValue, 133020, "managedObjectMergeError")
    try eq(CocoaError.Code.persistentStoreOpenError.rawValue, 134080, "persistentStoreOpenError")
    try eq(CocoaError.Code.persistentStoreSaveError.rawValue, 134030, "persistentStoreSaveError")
    try eq(CocoaError.Code.migrationError.rawValue, 134110, "migrationError")
    try eq(CocoaError.Code.sqliteError.rawValue, 134180, "sqliteError")
    try eq(CocoaError.Code.inferredMappingModelError.rawValue, 134190, "inferredMappingModelError")
    try eq(CocoaError.Code.persistentStoreOperationError.rawValue, 134070, "persistentStoreOperationError")
    try eq(CocoaError.Code.validationRelationshipLacksMinimumCountError.rawValue, 1580, "lacksMinimum")
    try eq(CocoaError.Code.validationRelationshipExceedsMaximumCountError.rawValue, 1590, "exceedsMaximum")
    try eq(CocoaError.Code.validationNumberTooLargeError.rawValue, 1610, "numberTooLarge")
    try eq(CocoaError.Code.validationNumberTooSmallError.rawValue, 1620, "numberTooSmall")
    try eq(CocoaError.Code.validationDateTooLateError.rawValue, 1630, "dateTooLate")
    try eq(CocoaError.Code.validationDateTooSoonError.rawValue, 1640, "dateTooSoon")
    try eq(CocoaError.Code.validationInvalidDateError.rawValue, 1650, "invalidDate")
    try eq(CocoaError.Code.validationStringTooLongError.rawValue, 1660, "stringTooLong")
    try eq(CocoaError.Code.validationStringTooShortError.rawValue, 1670, "stringTooShort")
    try eq(CocoaError.Code.validationStringPatternMatchingError.rawValue, 1680, "stringPattern")
    try eq(CocoaError.Code.managedObjectContextLockingError.rawValue, 132000, "contextLocking")
    try eq(CocoaError.Code.persistentStoreCoordinatorLockingError.rawValue, 132010, "coordinatorLocking")
    try eq(CocoaError.Code.managedObjectReferentialIntegrityError.rawValue, 133000, "referentialIntegrity")
    try eq(CocoaError.Code.managedObjectExternalRelationshipError.rawValue, 133010, "externalRelationship")
    try eq(CocoaError.Code.managedObjectConstraintMergeError.rawValue, 133021, "constraintMerge")
    try eq(CocoaError.Code.persistentStoreInvalidTypeError.rawValue, 134000, "invalidType")
    try eq(CocoaError.Code.persistentStoreTypeMismatchError.rawValue, 134010, "typeMismatch")
    try eq(CocoaError.Code.persistentStoreIncompatibleSchemaError.rawValue, 134020, "incompatibleSchema")
    try eq(CocoaError.Code.persistentStoreIncompleteSaveError.rawValue, 134040, "incompleteSave")
    try eq(CocoaError.Code.persistentStoreSaveConflictsError.rawValue, 134050, "saveConflicts")
    try eq(CocoaError.Code.coreDataError.rawValue, 134060, "coreDataError")
    try eq(CocoaError.Code.persistentStoreTimeoutError.rawValue, 134090, "timeout")
    try eq(CocoaError.Code.persistentStoreUnsupportedRequestTypeError.rawValue, 134091, "unsupportedRequest")
    try eq(CocoaError.Code.persistentStoreIncompatibleVersionHashError.rawValue, 134100, "incompatibleHash")
    try eq(CocoaError.Code.migrationCancelledError.rawValue, 134120, "migrationCancelled")
    try eq(CocoaError.Code.migrationMissingSourceModelError.rawValue, 134130, "missingSource")
    try eq(CocoaError.Code.migrationMissingMappingModelError.rawValue, 134140, "missingMapping")
    try eq(CocoaError.Code.migrationManagerSourceStoreError.rawValue, 134150, "migrationSourceStore")
    try eq(CocoaError.Code.migrationManagerDestinationStoreError.rawValue, 134160, "migrationDestStore")
    try eq(CocoaError.Code.entityMigrationPolicyError.rawValue, 134170, "entityMigrationPolicy")
    try eq(CocoaError.Code.externalRecordImportError.rawValue, 134200, "externalRecordImport")

    let container = try makeLoadedContainer(makeNoteModel(), name: "ErrorCodes")
    let context = container.viewContext
    _ = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
    do {
        try context.save()
        throw ProbeFailure.message("missing required title must fail with NSValidationMissingMandatoryPropertyError")
    } catch is ProbeFailure {
        throw ProbeFailure.message("missing required title must fail with NSValidationMissingMandatoryPropertyError")
    } catch {
        let ns = error as NSError
        guard ns.code == NSValidationMissingMandatoryPropertyError else {
            throw ProbeFailure.message("expected NSValidationMissingMandatoryPropertyError, got \(ns.code)")
        }
        guard ns.userInfo[NSValidationKeyErrorKey] as? String == "title" else {
            throw ProbeFailure.message("validation userInfo must name the title key")
        }
    }

    let model = makeNoteModel()
    do {
        try NSPersistentCloudKitContainer(name: "ErrCloud", managedObjectModel: model)
            .initializeCloudKitSchema(options: [])
        throw ProbeFailure.message("CloudKit schema init must fail closed")
    } catch is ProbeFailure {
        throw ProbeFailure.message("CloudKit schema init must fail closed")
    } catch {
        let ns = error as NSError
        guard ns.code == NSPersistentStoreOperationError else {
            throw ProbeFailure.message("CloudKit fail-closed should use NSPersistentStoreOperationError")
        }
    }

    do {
        _ = try NSMigrationManager(sourceModel: model, destinationModel: model).migrateStore(
            from: URL(fileURLWithPath: "/tmp/src.sqlite"),
            sourceType: NSSQLiteStoreType,
            with: nil,
            toDestinationURL: URL(fileURLWithPath: "/tmp/dst.sqlite"),
            destinationType: NSSQLiteStoreType
        )
        throw ProbeFailure.message("migrateStore must fail closed")
    } catch is ProbeFailure {
        throw ProbeFailure.message("migrateStore must fail closed")
    } catch {
        let ns = error as NSError
        guard ns.code == NSMigrationError else {
            throw ProbeFailure.message("migrateStore should use NSMigrationError")
        }
    }
}

func testRelationshipsFaultingAndInverses() throws {
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
}

func testDeleteRules() throws {
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
}

func testPredicateFormatsAndResultTypes() throws {
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
}

func testFetchedResultsControllerDelegateOrder() throws {
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
}

func testBatchRequests() throws {
    let container = try makeLoadedContainer(makeNoteModel(), name: "Batch")
    let context = container.viewContext
    let entity = context.persistentStoreCoordinator!.managedObjectModel.entitiesByName["Note"]!
    let insert = NSBatchInsertRequest(entity: entity, objects: [
        ["title": "b1"],
        ["title": "b2"],
        ["title": "b3"]
    ])
    insert.resultType = .count
    let inserted = try context.execute(insert) as? NSBatchInsertResult
    guard inserted?.result as? Int == 3 else {
        throw ProbeFailure.message("batch insert count should be 3")
    }

    let update = NSBatchUpdateRequest(entity: entity)
    update.propertiesToUpdate = ["title": "updated"]
    update.resultType = .updatedObjectsCountResultType
    let updated = try context.execute(update) as? NSBatchUpdateResult
    guard updated?.result as? Int == 3 else {
        throw ProbeFailure.message("batch update count should be 3")
    }

    let deleteFetch = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
    let delete = NSBatchDeleteRequest(fetchRequest: deleteFetch)
    delete.resultType = .resultTypeCount
    let deleted = try context.execute(delete) as? NSBatchDeleteResult
    guard deleted?.result as? Int == 3 else {
        throw ProbeFailure.message("batch delete count should be 3")
    }

    let insertIDs = NSBatchInsertRequest(entity: entity, objects: [["title": "id1"], ["title": "id2"]])
    insertIDs.resultType = .objectIDs
    let insertedIDs = try context.execute(insertIDs) as? NSBatchInsertResult
    guard let ids = insertedIDs?.result as? [NSManagedObjectID], ids.count == 2 else {
        throw ProbeFailure.message("batch insert objectIDs should return two NSManagedObjectID values")
    }

    let updateIDs = NSBatchUpdateRequest(entity: entity)
    updateIDs.propertiesToUpdate = ["title": "id-updated"]
    updateIDs.resultType = .updatedObjectIDsResultType
    let updatedIDs = try context.execute(updateIDs) as? NSBatchUpdateResult
    guard let updatedIDList = updatedIDs?.result as? [NSManagedObjectID], updatedIDList.count == 2 else {
        throw ProbeFailure.message("batch update objectIDs should return two NSManagedObjectID values")
    }

    let statusInsert = NSBatchInsertRequest(entityName: "Note", objects: [["title": "status"]])
    statusInsert.resultType = .statusOnly
    let statusInserted = try context.execute(statusInsert) as? NSBatchInsertResult
    guard statusInserted?.result as? Bool == true else {
        throw ProbeFailure.message("batch insert statusOnly should return true")
    }

    let statusDelete = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<any NSFetchRequestResult>(entityName: "Note"))
    statusDelete.resultType = .resultTypeStatusOnly
    let statusDeleted = try context.execute(statusDelete) as? NSBatchDeleteResult
    guard statusDeleted?.result as? Bool == true else {
        throw ProbeFailure.message("batch delete statusOnly should return true")
    }
}

func testMergePolicyAndParentMerge() throws {
    let container = try makeLoadedContainer(makeNoteModel(), name: "Merge")
    let parent = container.viewContext
    parent.mergePolicy = NSMergePolicy.rollback
    let child = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    child.parent = parent
    child.automaticallyMergesChangesFromParent = true
    child.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: parent)
    note.setValue("root", forKey: "title")
    try parent.save()

    let childView = try child.existingObject(with: note.objectID)
    childView.setValue("child-edit", forKey: "title")
    note.setValue("parent-edit", forKey: "title")
    try parent.save()
    guard childView.value(forKey: "title") as? String == "child-edit" else {
        throw ProbeFailure.message("object-trump merge should keep the child's in-memory title")
    }

    let errorPolicy = NSMergePolicy(merge: .errorMergePolicyType)
    do {
        try errorPolicy.resolve(mergeConflicts: [
            NSMergeConflict(
                source: childView,
                newVersion: 2,
                oldVersion: 1,
                cachedSnapshot: ["title": "root"],
                persistedSnapshot: ["title": "parent-edit"]
            )
        ])
        throw ProbeFailure.message("error merge policy must throw on conflicts")
    } catch is ProbeFailure {
        throw ProbeFailure.message("error merge policy must throw on conflicts")
    } catch {
        let ns = error as NSError
        guard ns.code == NSManagedObjectMergeError else {
            throw ProbeFailure.message("error merge policy must use NSManagedObjectMergeError")
        }
    }

    guard NSMergePolicy.error.mergeType == .errorMergePolicyType,
          NSMergePolicy.rollback.mergeType == .rollbackMergePolicyType,
          NSMergePolicy.overwrite.mergeType == .overwriteMergePolicyType,
          NSMergePolicy.mergeByPropertyStoreTrump.mergeType == .mergeByPropertyStoreTrumpMergePolicyType,
          NSMergePolicy.mergeByPropertyObjectTrump.mergeType == .mergeByPropertyObjectTrumpMergePolicyType else {
        throw ProbeFailure.message("NSMergePolicy constants mismatch")
    }
}

func testValidationAndUndoDisabled() throws {
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
}

func testModelMetadataAndStoreCoordinator() throws {
    let model = makeAuthorNoteModel()
    let entity = model.entitiesByName["Note"]!
    let title = entity.attributesByName["title"]!
    title.setValidationPredicates([NSPredicate { value, _ in ((value as? String)?.isEmpty == false) }], withValidationWarnings: ["empty"])
    let indexElement = NSFetchIndexElementDescription(property: title, collationType: .binary)
    indexElement.isAscending = true
    let index = NSFetchIndexDescription(name: "byTitle", elements: [indexElement])
    entity.indexes = [index]
    entity.uniquenessConstraints = [["title"]]
    entity.compoundIndexes = [["title"]]
    entity.renamingIdentifier = "NoteOld"
    entity.userInfo = ["k": "v"]
    entity.versionHashModifier = "m1"
    entity.isAbstract = false
    title.type = .string
    title.allowsExternalBinaryDataStorage = false
    title.allowsCloudEncryption = false
    title.preservesValueInHistoryOnDeletion = false
    title.valueTransformerName = nil
    title.attributeValueClassName = "NSString"
    let fetched = NSFetchedPropertyDescription()
    fetched.name = "allNotes"
    fetched.fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
    entity.properties.append(fetched)
    let composite = NSCompositeAttributeDescription()
    composite.name = "composite"
    composite.elements = [title]
    let derived = NSDerivedAttributeDescription()
    derived.name = "derived"
    let expression = NSExpressionDescription()
    expression.name = "countExpr"
    expression.expressionResultType = .integer64AttributeType
    expression.resultType = .integer64
    _ = (composite, derived, expression)

    model.setEntities(model.entities, forConfigurationName: "Default")
    model.setFetchRequestTemplate(NSFetchRequest<any NSFetchRequestResult>(entityName: "Note"), forName: "all")
    model.versionIdentifiers = ["v1"]
    model.localizationDictionary = ["Note": "Note"]
    guard model.entities(forConfigurationName: "Default")?.count == 2,
          model.fetchRequestTemplate(forName: "all") != nil,
          model.fetchRequestFromTemplate(withName: "all", substitutionVariables: [:]) != nil,
          !model.versionChecksum.isEmpty,
          model.isConfiguration(withName: nil, compatibleWithStoreMetadata: [:]) else {
        throw ProbeFailure.message("model configuration/template/checksum failed")
    }
    guard NSManagedObjectModel(contentsOf: URL(fileURLWithPath: "/tmp/missing.momd")) == nil else {
        throw ProbeFailure.message("compiled momd loading must fail closed")
    }
    let merged = NSManagedObjectModel(byMerging: [model, NSManagedObjectModel()])
    guard merged != nil else {
        throw ProbeFailure.message("byMerging models should succeed")
    }
    guard NSManagedObjectModel.mergedModel(from: nil) == nil else {
        throw ProbeFailure.message("mergedModel(from bundles:) must stay fail-closed without momd bytes")
    }

    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    coordinator.name = "coord"
    _ = coordinator.withLock { coordinator.name }
    let store = try coordinator.addPersistentStore(
        type: .inMemory,
        configuration: nil,
        at: URL(string: "x-coredata-in-memory://meta")!,
        options: [NSReadOnlyPersistentStoreOption: false as NSNumber]
    )
    guard coordinator.persistentStore(for: store.url!) != nil else {
        throw ProbeFailure.message("persistentStore(for:) should find the added store")
    }
    guard coordinator.setURL(store.url!, for: store) else {
        throw ProbeFailure.message("setURL should succeed for in-memory stores")
    }
    _ = coordinator.metadata(for: store)
    coordinator.setMetadata(store.metadata, for: store)
    try coordinator.destroyPersistentStore(at: store.url!, type: .inMemory)
}

func testFailClosedSurfaces() throws {
    let model = makeNoteModel()
    let history = NSPersistentHistoryChangeRequest.fetchHistory(after: nil as NSPersistentHistoryToken?)
    history.resultType = .statusOnly
    _ = history.token
    _ = NSPersistentHistoryChange.entityDescription
    _ = NSPersistentHistoryTransaction.fetchRequest
    _ = NSPersistentHistoryChangeRequest.fetchHistory(after: Date())

    let cloud = NSPersistentCloudKitContainer(name: "Cloud2", managedObjectModel: model)
    cloud.persistentStoreDescriptions[0].cloudKitContainerOptions =
        NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.example")
    do {
        try cloud.initializeCloudKitSchema(options: [.dryRun, .printSchema])
        throw ProbeFailure.message("CloudKit schema init must fail closed")
    } catch is ProbeFailure {
        throw ProbeFailure.message("CloudKit schema init must fail closed")
    } catch {
        let ns = error as NSError
        guard ns.code == NSPersistentStoreOperationError else {
            throw ProbeFailure.message("CloudKit fail-closed should use NSPersistentStoreOperationError")
        }
    }

    do {
        _ = try NSMigrationManager(sourceModel: model, destinationModel: model).migrateStore(
            from: URL(fileURLWithPath: "/tmp/src.sqlite"),
            sourceType: NSSQLiteStoreType,
            with: nil,
            toDestinationURL: URL(fileURLWithPath: "/tmp/dst.sqlite"),
            destinationType: NSSQLiteStoreType
        )
        throw ProbeFailure.message("migrateStore must fail closed")
    } catch is ProbeFailure {
        throw ProbeFailure.message("migrateStore must fail closed")
    } catch {
        let ns = error as NSError
        guard ns.code == NSMigrationError else {
            throw ProbeFailure.message("migrateStore should use NSMigrationError")
        }
    }

    let mapping = NSEntityMapping()
    mapping.mappingType = .addEntityMappingType
    let propertyMapping = NSPropertyMapping()
    propertyMapping.name = "title"
    mapping.attributeMappings = [propertyMapping]
    _ = NSMappingModel()
    _ = NSEntityMigrationPolicy()
    _ = NSStagedMigrationManager([NSLightweightMigrationStage([])])
    _ = NSManagedObjectModelReference(model: model, versionChecksum: "x")

    let token = NSQueryGenerationToken.current
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    try context.setQueryGenerationFrom(token)
    _ = try NSPersistentStoreCoordinator.metadataForPersistentStore(
        ofType: NSInMemoryStoreType,
        at: URL(string: "x-coredata-in-memory://m")!
    )
    do {
        _ = try NSPersistentStore.metadataForPersistentStore(with: URL(fileURLWithPath: "/tmp/nope.sqlite"))
        throw ProbeFailure.message("SQLite metadata must fail closed")
    } catch is ProbeFailure {
        throw ProbeFailure.message("SQLite metadata must fail closed")
    } catch {
        // expected
    }

    let spotlight = NSCoreDataCoreSpotlightDelegate(
        forStoreWith: NSPersistentStoreDescription(url: URL(fileURLWithPath: "/tmp/x")),
        coordinator: NSPersistentStoreCoordinator(managedObjectModel: model)
    )
    spotlight.startSpotlightIndexing()
    guard spotlight.isIndexingEnabled == false else {
        throw ProbeFailure.message("spotlight indexing must stay disabled")
    }
    do {
        try NSPersistentStoreCoordinator.removeUbiquitousContentAndPersistentStore(
            at: URL(fileURLWithPath: "/tmp/ubiquity.sqlite"),
            options: nil
        )
        throw ProbeFailure.message("ubiquity remove must fail closed")
    } catch is ProbeFailure {
        throw ProbeFailure.message("ubiquity remove must fail closed")
    } catch {
        // expected
    }

    let fetchExpr = NSFetchRequestExpression.expression(countOnly: true)
    guard fetchExpr.isCountOnlyRequest,
          NSFetchRequestExpressionType.rawValue == 50 else {
        throw ProbeFailure.message("NSFetchRequestExpressionType was measured as 50")
    }
}

func testPublicConstantsCatalog() throws {
    func eq(_ got: Int, _ expected: Int, _ name: String) throws {
        guard got == expected else {
            throw ProbeFailure.message("\(name) raw value \(got) != \(expected)")
        }
    }
    try eq(NSManagedObjectValidationError, 1550, "NSManagedObjectValidationError")
    try eq(NSValidationMultipleErrorsError, 1560, "NSValidationMultipleErrorsError")
    try eq(NSValidationMissingMandatoryPropertyError, 1570, "NSValidationMissingMandatoryPropertyError")
    try eq(NSValidationRelationshipLacksMinimumCountError, 1580, "NSValidationRelationshipLacksMinimumCountError")
    try eq(NSValidationRelationshipExceedsMaximumCountError, 1590, "NSValidationRelationshipExceedsMaximumCountError")
    try eq(NSValidationRelationshipDeniedDeleteError, 1600, "NSValidationRelationshipDeniedDeleteError")
    try eq(NSValidationNumberTooLargeError, 1610, "NSValidationNumberTooLargeError")
    try eq(NSValidationNumberTooSmallError, 1620, "NSValidationNumberTooSmallError")
    try eq(NSValidationDateTooLateError, 1630, "NSValidationDateTooLateError")
    try eq(NSValidationDateTooSoonError, 1640, "NSValidationDateTooSoonError")
    try eq(NSValidationInvalidDateError, 1650, "NSValidationInvalidDateError")
    try eq(NSValidationStringTooLongError, 1660, "NSValidationStringTooLongError")
    try eq(NSValidationStringTooShortError, 1670, "NSValidationStringTooShortError")
    try eq(NSValidationStringPatternMatchingError, 1680, "NSValidationStringPatternMatchingError")
    try eq(NSValidationInvalidURIError, 1690, "NSValidationInvalidURIError")
    try eq(NSManagedObjectContextLockingError, 132000, "NSManagedObjectContextLockingError")
    try eq(NSPersistentStoreCoordinatorLockingError, 132010, "NSPersistentStoreCoordinatorLockingError")
    try eq(NSManagedObjectReferentialIntegrityError, 133000, "NSManagedObjectReferentialIntegrityError")
    try eq(NSManagedObjectExternalRelationshipError, 133010, "NSManagedObjectExternalRelationshipError")
    try eq(NSManagedObjectMergeError, 133020, "NSManagedObjectMergeError")
    try eq(NSManagedObjectConstraintMergeError, 133021, "NSManagedObjectConstraintMergeError")
    try eq(NSPersistentStoreInvalidTypeError, 134000, "NSPersistentStoreInvalidTypeError")
    try eq(NSPersistentStoreTypeMismatchError, 134010, "NSPersistentStoreTypeMismatchError")
    try eq(NSPersistentStoreIncompatibleSchemaError, 134020, "NSPersistentStoreIncompatibleSchemaError")
    try eq(NSPersistentStoreSaveError, 134030, "NSPersistentStoreSaveError")
    try eq(NSPersistentStoreIncompleteSaveError, 134040, "NSPersistentStoreIncompleteSaveError")
    try eq(NSPersistentStoreSaveConflictsError, 134050, "NSPersistentStoreSaveConflictsError")
    try eq(NSCoreDataError, 134060, "NSCoreDataError")
    try eq(NSPersistentStoreOperationError, 134070, "NSPersistentStoreOperationError")
    try eq(NSPersistentStoreOpenError, 134080, "NSPersistentStoreOpenError")
    try eq(NSPersistentStoreTimeoutError, 134090, "NSPersistentStoreTimeoutError")
    try eq(NSPersistentStoreUnsupportedRequestTypeError, 134091, "NSPersistentStoreUnsupportedRequestTypeError")
    try eq(NSPersistentStoreIncompatibleVersionHashError, 134100, "NSPersistentStoreIncompatibleVersionHashError")
    try eq(NSMigrationError, 134110, "NSMigrationError")
    try eq(NSMigrationConstraintViolationError, 134111, "NSMigrationConstraintViolationError")
    try eq(NSMigrationCancelledError, 134120, "NSMigrationCancelledError")
    try eq(NSMigrationMissingSourceModelError, 134130, "NSMigrationMissingSourceModelError")
    try eq(NSMigrationMissingMappingModelError, 134140, "NSMigrationMissingMappingModelError")
    try eq(NSMigrationManagerSourceStoreError, 134150, "NSMigrationManagerSourceStoreError")
    try eq(NSMigrationManagerDestinationStoreError, 134160, "NSMigrationManagerDestinationStoreError")
    try eq(NSEntityMigrationPolicyError, 134170, "NSEntityMigrationPolicyError")
    try eq(NSSQLiteError, 134180, "NSSQLiteError")
    try eq(NSInferredMappingModelError, 134190, "NSInferredMappingModelError")
    try eq(NSExternalRecordImportError, 134200, "NSExternalRecordImportError")
    try eq(NSPersistentHistoryTokenExpiredError, 134301, "NSPersistentHistoryTokenExpiredError")
    try eq(NSManagedObjectConstraintValidationError, 134400, "NSManagedObjectConstraintValidationError")
    try eq(NSManagedObjectModelReferenceNotFoundError, 134510, "NSManagedObjectModelReferenceNotFoundError")
    try eq(NSStagedMigrationFrameworkVersionMismatchError, 134520, "NSStagedMigrationFrameworkVersionMismatchError")
    try eq(NSStagedMigrationBackwardMigrationError, 134530, "NSStagedMigrationBackwardMigrationError")

    try eq(CocoaError.Code.managedObjectValidationError.rawValue, 1550, "CocoaError.Code.managedObjectValidationError")
    try eq(CocoaError.managedObjectValidation.rawValue, 1550, "CocoaError.managedObjectValidation")
    try eq(CocoaError.Code.validationMultipleErrorsError.rawValue, 1560, "validationMultipleErrorsError")
    try eq(CocoaError.validationMissingMandatoryProperty.rawValue, 1570, "validationMissingMandatoryProperty")
    try eq(CocoaError.Code.validationRelationshipDeniedDeleteError.rawValue, 1600, "validationRelationshipDeniedDeleteError")
    try eq(CocoaError.Code.managedObjectMergeError.rawValue, 133020, "managedObjectMergeError")
    try eq(CocoaError.Code.persistentStoreOpenError.rawValue, 134080, "persistentStoreOpenError")
    try eq(CocoaError.Code.persistentStoreSaveError.rawValue, 134030, "persistentStoreSaveError")
    try eq(CocoaError.Code.migrationError.rawValue, 134110, "migrationError")
    try eq(CocoaError.Code.sqliteError.rawValue, 134180, "sqliteError")
    try eq(CocoaError.Code.inferredMappingModelError.rawValue, 134190, "inferredMappingModelError")
    try eq(CocoaError.Code.persistentStoreOperationError.rawValue, 134070, "persistentStoreOperationError")
    try eq(CocoaError.Code.validationRelationshipLacksMinimumCountError.rawValue, 1580, "lacksMinimum")
    try eq(CocoaError.Code.validationRelationshipExceedsMaximumCountError.rawValue, 1590, "exceedsMaximum")
    try eq(CocoaError.Code.validationNumberTooLargeError.rawValue, 1610, "numberTooLarge")
    try eq(CocoaError.Code.validationNumberTooSmallError.rawValue, 1620, "numberTooSmall")
    try eq(CocoaError.Code.validationDateTooLateError.rawValue, 1630, "dateTooLate")
    try eq(CocoaError.Code.validationDateTooSoonError.rawValue, 1640, "dateTooSoon")
    try eq(CocoaError.Code.validationInvalidDateError.rawValue, 1650, "invalidDate")
    try eq(CocoaError.Code.validationStringTooLongError.rawValue, 1660, "stringTooLong")
    try eq(CocoaError.Code.validationStringTooShortError.rawValue, 1670, "stringTooShort")
    try eq(CocoaError.Code.validationStringPatternMatchingError.rawValue, 1680, "stringPattern")
    try eq(CocoaError.Code.managedObjectContextLockingError.rawValue, 132000, "contextLocking")
    try eq(CocoaError.Code.persistentStoreCoordinatorLockingError.rawValue, 132010, "coordinatorLocking")
    try eq(CocoaError.Code.managedObjectReferentialIntegrityError.rawValue, 133000, "referentialIntegrity")
    try eq(CocoaError.Code.managedObjectExternalRelationshipError.rawValue, 133010, "externalRelationship")
    try eq(CocoaError.Code.managedObjectConstraintMergeError.rawValue, 133021, "constraintMerge")
    try eq(CocoaError.Code.persistentStoreInvalidTypeError.rawValue, 134000, "invalidType")
    try eq(CocoaError.Code.persistentStoreTypeMismatchError.rawValue, 134010, "typeMismatch")
    try eq(CocoaError.Code.persistentStoreIncompatibleSchemaError.rawValue, 134020, "incompatibleSchema")
    try eq(CocoaError.Code.persistentStoreIncompleteSaveError.rawValue, 134040, "incompleteSave")
    try eq(CocoaError.Code.persistentStoreSaveConflictsError.rawValue, 134050, "saveConflicts")
    try eq(CocoaError.Code.coreDataError.rawValue, 134060, "coreDataError")
    try eq(CocoaError.Code.persistentStoreTimeoutError.rawValue, 134090, "timeout")
    try eq(CocoaError.Code.persistentStoreUnsupportedRequestTypeError.rawValue, 134091, "unsupportedRequest")
    try eq(CocoaError.Code.persistentStoreIncompatibleVersionHashError.rawValue, 134100, "incompatibleHash")
    try eq(CocoaError.Code.migrationCancelledError.rawValue, 134120, "migrationCancelled")
    try eq(CocoaError.Code.migrationMissingSourceModelError.rawValue, 134130, "missingSource")
    try eq(CocoaError.Code.migrationMissingMappingModelError.rawValue, 134140, "missingMapping")
    try eq(CocoaError.Code.migrationManagerSourceStoreError.rawValue, 134150, "migrationSourceStore")
    try eq(CocoaError.Code.migrationManagerDestinationStoreError.rawValue, 134160, "migrationDestStore")
    try eq(CocoaError.Code.entityMigrationPolicyError.rawValue, 134170, "entityMigrationPolicy")
    try eq(CocoaError.Code.externalRecordImportError.rawValue, 134200, "externalRecordImport")

    guard NSSQLiteStoreType == "SQLite",
          NSBinaryStoreType == "Binary",
          NSInMemoryStoreType == "InMemory",
          NSStoreTypeKey == "NSStoreTypeKey",
          NSInsertedObjectsKey == "NSInsertedObjectsKey",
          NSUpdatedObjectsKey == "NSUpdatedObjectsKey",
          NSDeletedObjectsKey == "NSDeletedObjectsKey",
          NSValidationKeyErrorKey == "NSValidationKeyErrorKey",
          NSPersistentStoreSaveConflictsErrorKey == "NSPersistentStoreSaveConflictsErrorKey",
          NSErrorMergePolicy === NSMergePolicy.error,
          NSRollbackMergePolicy === NSMergePolicy.rollback,
          NSOverwriteMergePolicy === NSMergePolicy.overwrite,
          NSMergeByPropertyStoreTrumpMergePolicy === NSMergePolicy.mergeByPropertyStoreTrump,
          NSMergeByPropertyObjectTrumpMergePolicy === NSMergePolicy.mergeByPropertyObjectTrump else {
        throw ProbeFailure.message("store-type/notification/merge-policy constants mismatch")
    }

    guard NSAttributeType.stringAttributeType.rawValue == 700,
          NSAttributeType.integer64AttributeType.rawValue == 300,
          NSAttributeType.booleanAttributeType.rawValue == 800,
          NSAttributeType.dateAttributeType.rawValue == 900,
          NSAttributeType.binaryDataAttributeType.rawValue == 1000,
          NSAttributeType.UUIDAttributeType.rawValue == 1100,
          NSAttributeType.URIAttributeType.rawValue == 1200,
          NSAttributeType.transformableAttributeType.rawValue == 1800,
          NSAttributeType.objectIDAttributeType.rawValue == 2000,
          NSAttributeType.compositeAttributeType.rawValue == 2100,
          NSDeleteRule.cascadeDeleteRule.rawValue == 2,
          NSDeleteRule.denyDeleteRule.rawValue == 3,
          NSDeleteRule.nullifyDeleteRule.rawValue == 1,
          NSSnapshotEventType.refresh.rawValue == 1 << 5,
          NSFetchRequestResultType.managedObjectResultType.rawValue == 0,
          NSFetchRequestResultType.countResultType.rawValue == 4,
          NSPersistentStoreRequestType.fetchRequestType.rawValue == 1,
          NSPersistentStoreRequestType.batchDeleteRequestType.rawValue == 7,
          NSFetchedResultsChangeType.insert.rawValue == 1,
          NSCoreDataVersionNumber10_4 == 185.0,
          NSCoreDataVersionNumber_iPhoneOS_9_0 == 640.0,
          NSFetchRequestExpressionType.rawValue == 50 else {
        throw ProbeFailure.message("enum/option-set/version catalog mismatch")
    }
    var snapshot: NSSnapshotEventType = [.refresh, .rollback]
    snapshot.formUnion(.mergePolicy)
    guard snapshot.contains(.refresh),
          snapshot.union(.undoInsertion).contains(.undoInsertion),
          !snapshot.intersection(.refresh).isEmpty,
          snapshot.isSuperset(of: .refresh),
          !snapshot.isDisjoint(with: .rollback) else {
        throw ProbeFailure.message("NSSnapshotEventType OptionSet operations failed")
    }

    _ = [
        NSAddedPersistentStoresKey, NSRemovedPersistentStoresKey, NSUUIDChangedPersistentStoresKey,
        NSInsertedObjectIDsKey, NSUpdatedObjectIDsKey, NSDeletedObjectIDsKey,
        NSRefreshedObjectsKey, NSRefreshedObjectIDsKey, NSInvalidatedObjectsKey,
        NSInvalidatedObjectIDsKey, NSInvalidatedAllObjectsKey,
        NSAffectedObjectsErrorKey, NSAffectedStoresErrorKey, NSDetailedErrorsKey,
        NSValidationObjectErrorKey, NSValidationPredicateErrorKey, NSValidationValueErrorKey,
        NSPersistentStoreURLKey, NSPersistentStoreTimeoutOption, NSReadOnlyPersistentStoreOption,
        NSIgnorePersistentStoreVersioningOption, NSMigratePersistentStoresAutomaticallyOption,
        NSInferMappingModelAutomaticallyOption, NSSQLitePragmasOption, NSSQLiteAnalyzeOption,
        NSSQLiteManualVacuumOption, NSPersistentStoreFileProtectionKey, NSPersistentStoreForceDestroyOption,
        NSPersistentStoreConnectionPoolMaxSizeKey, NSPersistentStoreModelVersionChecksumKey,
        NSPersistentStoreOSCompatibility, NSPersistentStoreDeferredLightweightMigrationOptionKey,
        NSPersistentStoreStagedMigrationManagerOptionKey, NSPersistentStoreRemoteChangeNotificationPostOptionKey,
        NSPersistentHistoryTrackingKey, NSPersistentHistoryTokenKey,
        NSBinaryStoreSecureDecodingClasses, NSBinaryStoreInsecureDecodingCompatibilityOption,
        NSCoreDataCoreSpotlightExporter, NSStoreUUIDKey, NSStoreModelVersionHashesKey,
        NSStoreModelVersionIdentifiersKey, NSSQLiteErrorDomain,
        NSMigrationManagerKey, NSMigrationSourceObjectKey, NSMigrationDestinationObjectKey,
        NSMigrationEntityMappingKey, NSMigrationPropertyMappingKey, NSMigrationEntityPolicyKey,
        NSManagedObjectContextQueryGenerationKey
    ]
    _ = NSPersistentStore.StoreType.sqlite
    _ = NSPersistentStore.StoreType.binary
    _ = NSPersistentStore.StoreType.inMemory
    _ = NSManagedObjectContext.ConcurrencyType.mainQueue
    _ = NSManagedObjectContext.ConcurrencyType.privateQueue
    _ = NSManagedObjectContext.NotificationKey.insertedObjects
    _ = NSManagedObjectContext.NotificationKey.updatedObjects
    _ = NSManagedObjectContext.NotificationKey.deletedObjects
    _ = NSManagedObjectContext.didSaveObjectsNotification
    _ = NSManagedObjectContext.willSaveObjectsNotification
    _ = NSManagedObjectContext.didChangeObjectsNotification
    _ = NSManagedObjectContext.didSaveObjectIDsNotification
    _ = NSManagedObjectContext.didMergeChangesObjectIDsNotification
    _ = NSAttributeDescription.AttributeType.integer16
    _ = NSAttributeDescription.AttributeType.integer32
    _ = NSAttributeDescription.AttributeType.decimal
    _ = NSAttributeDescription.AttributeType.double
    _ = NSAttributeDescription.AttributeType.float
    _ = NSAttributeDescription.AttributeType.undefined
    _ = NSSnapshotEventType.undoInsertion
    _ = NSSnapshotEventType.undoDeletion
    _ = NSSnapshotEventType.undoUpdate
    _ = NSSnapshotEventType.rollback
    _ = NSSnapshotEventType.mergePolicy
    _ = NSPersistentCloudKitContainerSchemaInitializationOptions.dryRun.union(.printSchema)
    _ = NSFetchRequestResultType.managedObjectIDResultType.union(.dictionaryResultType)
    _ = NSPersistentHistoryChangeType.insert
    _ = NSPersistentHistoryResultType.transactionsAndChanges
    _ = NSPersistentCloudKitContainer.EventType.setup
    _ = NSPersistentCloudKitContainerEventResult.ResultType.events
    _ = NSEntityMappingType.transformEntityMappingType
    _ = NSFetchIndexElementType.rTree
    _ = NSBatchDeleteRequestResultType.resultTypeObjectIDs
    _ = NSBatchInsertRequestResultType.objectIDs
    _ = NSBatchUpdateRequestResultType.updatedObjectIDsResultType
    _ = NSManagedObject.contextShouldIgnoreUnmodeledPropertyChanges
    _ = NSManagedObject.fetchRequest()
    _ = NSEntityDescription()
    _ = NSConstraintConflict(
        constraint: ["title"],
        databaseObject: nil,
        databaseSnapshot: nil,
        conflictingObjects: [],
        conflictingSnapshots: []
    )
}

try runCoreDataRuntimeProbe()


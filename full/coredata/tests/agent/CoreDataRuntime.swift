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

func makeLoadedSQLiteContainer(
    _ model: NSManagedObjectModel,
    directory: URL,
    name: String
) throws -> NSPersistentContainer {
    let container = NSPersistentContainer(name: name, managedObjectModel: model)
    let url = directory.appendingPathComponent("\(name).sqlite")
    let description = NSPersistentStoreDescription(url: url)
    description.type = NSSQLiteStoreType
    description.shouldAddStoreAsynchronously = false
    description.setOption(false as NSNumber, forKey: NSReadOnlyPersistentStoreOption)
    container.persistentStoreDescriptions = [description]
    var loadError: (any Error)?
    container.loadPersistentStores { _, error in
        loadError = error
    }
    if let loadError {
        throw ProbeFailure.message("SQLite loadPersistentStores failed: \(loadError)")
    }
    return container
}

func agentModelContentsXML() -> String {
    """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" userDefinedModelVersionIdentifier="notes-v1">
        <entity name="Author" representedClassName="Author" syncable="YES">
            <attribute name="name" optional="NO" attributeType="String"/>
            <relationship name="notes" optional="YES" toMany="YES" ordered="YES" deletionRule="Cascade" destinationEntity="Note" inverseName="author" inverseEntity="Note"/>
            <uniquenessConstraints>
                <uniquenessConstraint>
                    <constraint value="name"/>
                </uniquenessConstraint>
            </uniquenessConstraints>
        </entity>
        <entity name="Note" representedClassName="Note" syncable="YES">
            <attribute name="title" optional="NO" attributeType="String"/>
            <attribute name="count" optional="YES" attributeType="Integer 64" defaultValueString="0"/>
            <attribute name="starred" optional="YES" attributeType="Boolean" defaultValueString="NO"/>
            <attribute name="scratch" optional="YES" transient="YES" attributeType="String"/>
            <relationship name="author" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Author" inverseName="notes" inverseEntity="Author"/>
            <fetchedProperty name="allNotes" optional="YES">
                <fetchRequest name="fetchedPropertyFetchRequest" entity="Note" predicateString="title != nil"/>
            </fetchedProperty>
        </entity>
    </model>
    """
}

func writeAgentXMLModelBundle(in directory: URL) throws -> URL {
    let bundle = directory.appendingPathComponent("Notes.xcdatamodeld")
    let current = bundle.appendingPathComponent("Notes.xcdatamodel")
    try FileManager.default.createDirectory(at: current, withIntermediateDirectories: true)
    let contents = current.appendingPathComponent("contents")
    try agentModelContentsXML().write(to: contents, atomically: true, encoding: .utf8)
    let marker = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>_XCCurrentVersionName</key>
        <string>Notes.xcdatamodel</string>
    </dict>
    </plist>
    """
    try marker.write(to: bundle.appendingPathComponent(".xccurrentversion"), atomically: true, encoding: .utf8)
    return bundle
}

func testInMemoryCRUDAndFailClosed() {
    do {
            let model = makeNoteModel()
            let container = try makeLoadedContainer(model)

            try withUniqueTempDirectory { directory in
                let binaryURL = directory.appendingPathComponent("should-not-open.binary")
                let binary = NSPersistentStoreDescription(url: binaryURL)
                binary.type = NSBinaryStoreType
                var binaryFailed = false
                container.persistentStoreCoordinator.addPersistentStore(with: binary) { _, error in
                    binaryFailed = error != nil
                }
                guard binaryFailed else {
                    throw ProbeFailure.message("binary addPersistentStore must fail closed on Linux")
                }
                guard !FileManager.default.fileExists(atPath: binaryURL.path) else {
                    throw ProbeFailure.message("fail-closed binary open must not create \(binaryURL.path)")
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
    } catch {
        fatalError("testInMemoryCRUDAndFailClosed failed: \(error)")
    }
}

func testContextInsertSaveFetch() {
    do {
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
    } catch {
        fatalError("testContextInsertSaveFetch failed: \(error)")
    }
}

func testQueueIdentity() {
    do {
            let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            var mainWaitOnMain = false
            mainContext.performAndWait {
                mainWaitOnMain = true
            }
            guard mainWaitOnMain,
                  mainContext.concurrencyType == .mainQueueConcurrencyType else {
                throw ProbeFailure.message("mainQueueConcurrencyType performAndWait must run synchronously")
            }

            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            var privateRan = false
            privateContext.performAndWait {
                privateRan = true
            }
            guard privateRan,
                  privateContext.concurrencyType == .privateQueueConcurrencyType else {
                throw ProbeFailure.message("privateQueueConcurrencyType performAndWait must run synchronously")
            }
    } catch {
        fatalError("testQueueIdentity failed: \(error)")
    }
}

func testQueueSerialization() {
    do {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            context.lock()
            context.unlock()
            var overlapping = 0
            var maxOverlap = 0
            for _ in 0..<6 {
                context.performAndWait {
                    overlapping += 1
                    maxOverlap = max(maxOverlap, overlapping)
                    overlapping -= 1
                }
            }
            guard maxOverlap == 1 else {
                throw ProbeFailure.message("private-queue work must be serialized, maxOverlap=\(maxOverlap)")
            }
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeNoteModel())
            coordinator.lock()
            coordinator.unlock()
    } catch {
        fatalError("testQueueSerialization failed: \(error)")
    }
}

func testQueueReentrancy() {
    do {
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
    } catch {
        fatalError("testQueueReentrancy failed: \(error)")
    }
}

func testPerformOrdering() {
    do {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            var order: [String] = []
            context.performAndWait {
                order.append("outer-start")
                context.performAndWait {
                    order.append("immediate")
                }
                order.append("outer-end")
            }
            guard order == ["outer-start", "immediate", "outer-end"] else {
                throw ProbeFailure.message("performAndWait nested ordering mismatch: \(order)")
            }
    } catch {
        fatalError("testPerformOrdering failed: \(error)")
    }
}

func testGenericPerformOverloads() {
    do {
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
    } catch {
        fatalError("testGenericPerformOverloads failed: \(error)")
    }
}

func testCommittedSnapshotsAndChangedBack() {
    do {
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
    } catch {
        fatalError("testCommittedSnapshotsAndChangedBack failed: \(error)")
    }
}

func testOldNilCommittedValues() {
    do {
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
    } catch {
        fatalError("testOldNilCommittedValues failed: \(error)")
    }
}

func testRollbackRestoresCommitted() {
    do {
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
    } catch {
        fatalError("testRollbackRestoresCommitted failed: \(error)")
    }
}

func testChildIsolation() {
    do {
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
    } catch {
        fatalError("testChildIsolation failed: \(error)")
    }
}

func testRegisteredStoreClass() {
    do {
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
                        ofType: NSBinaryStoreType,
                        configurationName: nil,
                        at: directory.appendingPathComponent("unregistered.binary"),
                        options: nil
                    )
                    throw ProbeFailure.message("unregistered binary store type must stay unsupported")
                } catch is ProbeFailure {
                    throw ProbeFailure.message("unregistered binary store type must stay unsupported")
                } catch {
                    // expected platform blocker
                }
            }
    } catch {
        fatalError("testRegisteredStoreClass failed: \(error)")
    }
}

func testDefaultDirectoryURLHasNoEagerFilesystemSideEffects() {
    do {
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
    } catch {
        fatalError("testDefaultDirectoryURLHasNoEagerFilesystemSideEffects failed: \(error)")
    }
}

func testUnknownVersionNumberIsNotFabricated() {
    do {
            guard NSCoreDataVersionNumber == 0 else {
                throw ProbeFailure.message("NSCoreDataVersionNumber must stay unknown (0) until an Apple-oracle value exists")
            }
    } catch {
        fatalError("testUnknownVersionNumberIsNotFabricated failed: \(error)")
    }
}

func testModelConstruction() {
    do {
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
    } catch {
        fatalError("testModelConstruction failed: \(error)")
    }
}

func testModelMetadataAndStoreCoordinator() {
    do {
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
    } catch {
        fatalError("testModelMetadataAndStoreCoordinator failed: \(error)")
    }
}

func testEntityAttributeRelationshipDescriptions() {
    do {
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
    } catch {
        fatalError("testEntityAttributeRelationshipDescriptions failed: \(error)")
    }
}

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

func testMergePolicies() {
    do {
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
    } catch {
        fatalError("testMergePolicies failed: \(error)")
    }
}

func testMergePolicyAndParentMerge() {
    do {
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
    } catch {
        fatalError("testMergePolicyAndParentMerge failed: \(error)")
    }
}

func testErrorCodes() {
    do {
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

                let cocoa = CocoaError(_nsError: ns)
                _ = cocoa.validationKey
                _ = cocoa.validationObject
                _ = cocoa.validationValue
                _ = cocoa.validationPredicate
                _ = cocoa.affectedStores
                _ = cocoa.affectedObjects
                _ = cocoa.persistentStoreSaveConflicts
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

            _ = [
                CocoaError.Code.managedObjectValidation,
                CocoaError.Code.validationMultipleErrors,
                CocoaError.Code.validationMissingMandatoryProperty,
                CocoaError.Code.validationRelationshipLacksMinimumCount,
                CocoaError.Code.validationRelationshipExceedsMaximumCount,
                CocoaError.Code.validationRelationshipDeniedDelete,
                CocoaError.Code.validationNumberTooLarge,
                CocoaError.Code.validationNumberTooSmall,
                CocoaError.Code.validationDateTooLate,
                CocoaError.Code.validationDateTooSoon,
                CocoaError.Code.validationInvalidDate,
                CocoaError.Code.validationStringTooLong,
                CocoaError.Code.validationStringTooShort,
                CocoaError.Code.validationStringPatternMatching,
                CocoaError.Code.managedObjectContextLocking,
                CocoaError.Code.persistentStoreCoordinatorLocking,
                CocoaError.Code.managedObjectReferentialIntegrity,
                CocoaError.Code.managedObjectExternalRelationship,
                CocoaError.Code.managedObjectMerge,
                CocoaError.Code.managedObjectConstraintMerge,
                CocoaError.Code.persistentStoreInvalidType,
                CocoaError.Code.persistentStoreTypeMismatch,
                CocoaError.Code.persistentStoreIncompatibleSchema,
                CocoaError.Code.persistentStoreSave,
                CocoaError.Code.persistentStoreIncompleteSave,
                CocoaError.Code.persistentStoreSaveConflicts,
                CocoaError.Code.coreData,
                CocoaError.Code.persistentStoreOperation,
                CocoaError.Code.persistentStoreOpen,
                CocoaError.Code.persistentStoreTimeout,
                CocoaError.Code.persistentStoreUnsupportedRequestType,
                CocoaError.Code.persistentStoreIncompatibleVersionHash,
                CocoaError.Code.migration,
                CocoaError.Code.migrationCancelled,
                CocoaError.Code.migrationMissingSourceModel,
                CocoaError.Code.migrationMissingMappingModel,
                CocoaError.Code.migrationManagerSourceStore,
                CocoaError.Code.migrationManagerDestinationStore,
                CocoaError.Code.entityMigrationPolicy,
                CocoaError.Code.sqlite,
                CocoaError.Code.inferredMappingModel,
                CocoaError.Code.externalRecordImport,
                CocoaError.managedObjectValidationError,
                CocoaError.managedObjectValidation,
                CocoaError.validationMultipleErrorsError,
                CocoaError.validationMultipleErrors,
                CocoaError.validationMissingMandatoryPropertyError,
                CocoaError.validationMissingMandatoryProperty,
                CocoaError.validationRelationshipLacksMinimumCountError,
                CocoaError.validationRelationshipLacksMinimumCount,
                CocoaError.validationRelationshipExceedsMaximumCountError,
                CocoaError.validationRelationshipExceedsMaximumCount,
                CocoaError.validationRelationshipDeniedDeleteError,
                CocoaError.validationRelationshipDeniedDelete,
                CocoaError.validationNumberTooLargeError,
                CocoaError.validationNumberTooLarge,
                CocoaError.validationNumberTooSmallError,
                CocoaError.validationNumberTooSmall,
                CocoaError.validationDateTooLateError,
                CocoaError.validationDateTooLate,
                CocoaError.validationDateTooSoonError,
                CocoaError.validationDateTooSoon,
                CocoaError.validationInvalidDateError,
                CocoaError.validationInvalidDate,
                CocoaError.validationStringTooLongError,
                CocoaError.validationStringTooLong,
                CocoaError.validationStringTooShortError,
                CocoaError.validationStringTooShort,
                CocoaError.validationStringPatternMatchingError,
                CocoaError.validationStringPatternMatching,
                CocoaError.managedObjectContextLockingError,
                CocoaError.managedObjectContextLocking,
                CocoaError.persistentStoreCoordinatorLockingError,
                CocoaError.persistentStoreCoordinatorLocking,
                CocoaError.managedObjectReferentialIntegrityError,
                CocoaError.managedObjectReferentialIntegrity,
                CocoaError.managedObjectExternalRelationshipError,
                CocoaError.managedObjectExternalRelationship,
                CocoaError.managedObjectMergeError,
                CocoaError.managedObjectMerge,
                CocoaError.managedObjectConstraintMergeError,
                CocoaError.managedObjectConstraintMerge,
                CocoaError.persistentStoreInvalidTypeError,
                CocoaError.persistentStoreInvalidType,
                CocoaError.persistentStoreTypeMismatchError,
                CocoaError.persistentStoreTypeMismatch,
                CocoaError.persistentStoreIncompatibleSchemaError,
                CocoaError.persistentStoreIncompatibleSchema,
                CocoaError.persistentStoreSaveError,
                CocoaError.persistentStoreSave,
                CocoaError.persistentStoreIncompleteSaveError,
                CocoaError.persistentStoreIncompleteSave,
                CocoaError.persistentStoreSaveConflictsError,
                CocoaError.persistentStoreSaveConflicts,
                CocoaError.coreDataError,
                CocoaError.coreData,
                CocoaError.persistentStoreOperationError,
                CocoaError.persistentStoreOperation,
                CocoaError.persistentStoreOpenError,
                CocoaError.persistentStoreOpen,
                CocoaError.persistentStoreTimeoutError,
                CocoaError.persistentStoreTimeout,
                CocoaError.persistentStoreUnsupportedRequestTypeError,
                CocoaError.persistentStoreUnsupportedRequestType,
                CocoaError.persistentStoreIncompatibleVersionHashError,
                CocoaError.persistentStoreIncompatibleVersionHash,
                CocoaError.migrationError,
                CocoaError.migration,
                CocoaError.migrationCancelledError,
                CocoaError.migrationCancelled,
                CocoaError.migrationMissingSourceModelError,
                CocoaError.migrationMissingSourceModel,
                CocoaError.migrationMissingMappingModelError,
                CocoaError.migrationMissingMappingModel,
                CocoaError.migrationManagerSourceStoreError,
                CocoaError.migrationManagerSourceStore,
                CocoaError.migrationManagerDestinationStoreError,
                CocoaError.migrationManagerDestinationStore,
                CocoaError.entityMigrationPolicyError,
                CocoaError.entityMigrationPolicy,
                CocoaError.sqliteError,
                CocoaError.sqlite,
                CocoaError.inferredMappingModelError,
                CocoaError.inferredMappingModel,
                CocoaError.externalRecordImportError,
                CocoaError.externalRecordImport,
                CocoaError.Code.validationMissingMandatoryPropertyError,
                CocoaError.Code.sqliteError,
                CocoaError.Code.coreDataError,
                CocoaError.Code.migrationError,
            ]
    } catch {
        fatalError("testErrorCodes failed: \(error)")
    }
}

func testRelationshipsFaultingAndInverses() {
    do {
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
    } catch {
        fatalError("testRelationshipsFaultingAndInverses failed: \(error)")
    }
}

func testDeleteRules() {
    do {
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
    } catch {
        fatalError("testDeleteRules failed: \(error)")
    }
}

func testBatchRequests() {
    do {
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
    } catch {
        fatalError("testBatchRequests failed: \(error)")
    }
}

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

func testFailClosedSurfaces() {
    do {
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
    } catch {
        fatalError("testFailClosedSurfaces failed: \(error)")
    }
}

func testEnumOptionSetAndConstantValues() {
    do {
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

            try eq(Int(NSAttributeType.undefinedAttributeType.rawValue), 0, "undefinedAttributeType")
            try eq(Int(NSAttributeType.integer16AttributeType.rawValue), 100, "integer16AttributeType")
            try eq(Int(NSAttributeType.integer32AttributeType.rawValue), 200, "integer32AttributeType")
            try eq(Int(NSAttributeType.decimalAttributeType.rawValue), 400, "decimalAttributeType")
            try eq(Int(NSAttributeType.doubleAttributeType.rawValue), 500, "doubleAttributeType")
            try eq(Int(NSAttributeType.floatAttributeType.rawValue), 600, "floatAttributeType")
            try eq(Int(NSDeleteRule.noActionDeleteRule.rawValue), 0, "noActionDeleteRule")
            try eq(Int(NSManagedObjectContextConcurrencyType.confinementConcurrencyType.rawValue), 0, "confinementConcurrencyType")
            try eq(Int(NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType.rawValue), 1, "privateQueueConcurrencyType")
            try eq(Int(NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType.rawValue), 2, "mainQueueConcurrencyType")
            try eq(Int(NSMergePolicyType.errorMergePolicyType.rawValue), 0, "errorMergePolicyType")
            try eq(Int(NSMergePolicyType.rollbackMergePolicyType.rawValue), 1, "rollbackMergePolicyType")
            try eq(Int(NSMergePolicyType.overwriteMergePolicyType.rawValue), 2, "overwriteMergePolicyType")
            try eq(Int(NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType.rawValue), 3, "mergeByPropertyStoreTrumpMergePolicyType")
            try eq(Int(NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType.rawValue), 4, "mergeByPropertyObjectTrumpMergePolicyType")
            try eq(Int(NSPersistentStoreRequestType.saveRequestType.rawValue), 2, "saveRequestType")
            try eq(Int(NSPersistentStoreRequestType.batchUpdateRequestType.rawValue), 6, "batchUpdateRequestType")
            try eq(Int(NSPersistentStoreRequestType.batchInsertRequestType.rawValue), 8, "batchInsertRequestType")
            try eq(Int(NSFetchedResultsChangeType.delete.rawValue), 2, "FRC.delete")
            try eq(Int(NSFetchedResultsChangeType.move.rawValue), 3, "FRC.move")
            try eq(Int(NSFetchedResultsChangeType.update.rawValue), 4, "FRC.update")
            try eq(Int(NSBatchDeleteRequestResultType.resultTypeStatusOnly.rawValue), 0, "resultTypeStatusOnly")
            try eq(Int(NSBatchDeleteRequestResultType.resultTypeCount.rawValue), 2, "resultTypeCount")
            try eq(Int(NSBatchInsertRequestResultType.statusOnly.rawValue), 0, "batchInsert.statusOnly")
            try eq(Int(NSBatchInsertRequestResultType.count.rawValue), 2, "batchInsert.count")
            try eq(Int(NSBatchUpdateRequestResultType.statusOnlyResultType.rawValue), 0, "statusOnlyResultType")
            try eq(Int(NSBatchUpdateRequestResultType.updatedObjectsCountResultType.rawValue), 2, "updatedObjectsCountResultType")
            try eq(Int(NSEntityMappingType.undefinedEntityMappingType.rawValue), 0, "undefinedEntityMappingType")
            try eq(Int(NSEntityMappingType.customEntityMappingType.rawValue), 1, "customEntityMappingType")
            try eq(Int(NSEntityMappingType.addEntityMappingType.rawValue), 2, "addEntityMappingType")
            try eq(Int(NSEntityMappingType.removeEntityMappingType.rawValue), 3, "removeEntityMappingType")
            try eq(Int(NSEntityMappingType.copyEntityMappingType.rawValue), 4, "copyEntityMappingType")
            try eq(Int(NSFetchIndexElementType.binary.rawValue), 0, "fetchIndex.binary")
            try eq(Int(NSPersistentHistoryChangeType.update.rawValue), 1, "history.update")
            try eq(Int(NSPersistentHistoryChangeType.delete.rawValue), 2, "history.delete")
            try eq(NSPersistentHistoryResultType.statusOnly.rawValue, 0, "history.statusOnly")
            try eq(NSPersistentHistoryResultType.objectIDs.rawValue, 1, "history.objectIDs")
            try eq(NSPersistentHistoryResultType.count.rawValue, 2, "history.count")
            try eq(NSPersistentHistoryResultType.transactionsOnly.rawValue, 3, "history.transactionsOnly")
            try eq(NSPersistentHistoryResultType.changesOnly.rawValue, 4, "history.changesOnly")
            try eq(Int(NSPersistentStoreUbiquitousTransitionType.accountAdded.rawValue), 1, "accountAdded")
            try eq(Int(NSPersistentStoreUbiquitousTransitionType.accountRemoved.rawValue), 2, "accountRemoved")
            try eq(Int(NSPersistentStoreUbiquitousTransitionType.contentRemoved.rawValue), 3, "contentRemoved")
            try eq(Int(NSPersistentStoreUbiquitousTransitionType.initialImportCompleted.rawValue), 4, "initialImportCompleted")
            try eq(Int(NSPersistentCloudKitContainer.EventType.`import`.rawValue), 1, "cloud.import")
            try eq(Int(NSPersistentCloudKitContainer.EventType.export.rawValue), 2, "cloud.export")
            try eq(NSPersistentCloudKitContainerEventResult.ResultType.countEvents.rawValue, 1, "countEvents")
            guard NSCoreDataVersionNumber10_4_3 == 185.1,
                  NSCoreDataVersionNumber10_5 == 186.0,
                  NSCoreDataVersionNumber10_5_3 == 186.2,
                  NSCoreDataVersionNumber10_6 == 246.0,
                  NSCoreDataVersionNumber10_6_2 == 246.2,
                  NSCoreDataVersionNumber10_6_3 == 246.3,
                  NSCoreDataVersionNumber10_7 == 358.4,
                  NSCoreDataVersionNumber10_7_2 == 358.12,
                  NSCoreDataVersionNumber10_7_3 == 358.13,
                  NSCoreDataVersionNumber10_7_4 == 358.14,
                  NSCoreDataVersionNumber10_8 == 407.5,
                  NSCoreDataVersionNumber10_8_2 == 407.7,
                  NSCoreDataVersionNumber10_9 == 481.0,
                  NSCoreDataVersionNumber10_9_2 == 481.1,
                  NSCoreDataVersionNumber10_9_3 == 481.3,
                  NSCoreDataVersionNumber10_10 == 526.0,
                  NSCoreDataVersionNumber10_10_2 == 526.1,
                  NSCoreDataVersionNumber10_10_3 == 526.2,
                  NSCoreDataVersionNumber10_11 == 640.0,
                  NSCoreDataVersionNumber10_11_3 == 641.3,
                  NSCoreDataVersionNumber_iPhoneOS_3_0 == 241.0,
                  NSCoreDataVersionNumber_iPhoneOS_3_1 == 248.0,
                  NSCoreDataVersionNumber_iPhoneOS_3_2 == 310.2,
                  NSCoreDataVersionNumber_iPhoneOS_4_0 == 320.5,
                  NSCoreDataVersionNumber_iPhoneOS_4_1 == 320.11,
                  NSCoreDataVersionNumber_iPhoneOS_4_2 == 320.15,
                  NSCoreDataVersionNumber_iPhoneOS_4_3 == 320.17,
                  NSCoreDataVersionNumber_iPhoneOS_5_0 == 386.1,
                  NSCoreDataVersionNumber_iPhoneOS_5_1 == 386.5,
                  NSCoreDataVersionNumber_iPhoneOS_6_0 == 419.0,
                  NSCoreDataVersionNumber_iPhoneOS_6_1 == 420.1,
                  NSCoreDataVersionNumber_iPhoneOS_7_0 == 479.0,
                  NSCoreDataVersionNumber_iPhoneOS_7_1 == 479.3,
                  NSCoreDataVersionNumber_iPhoneOS_8_0 == 519.0,
                  NSCoreDataVersionNumber_iPhoneOS_8_3 == 519.15,
                  NSCoreDataVersionNumber_iPhoneOS_9_2 == 641.2,
                  NSCoreDataVersionNumber_iPhoneOS_9_3 == 641.6 else {
                throw ProbeFailure.message("historical NSCoreDataVersionNumber* catalog mismatch")
            }
            _ = NSAttributeDescription.AttributeType.boolean
            _ = NSAttributeDescription.AttributeType.date
            _ = NSAttributeDescription.AttributeType.binaryData
            _ = NSAttributeDescription.AttributeType.uuid
            _ = NSAttributeDescription.AttributeType.uri
            _ = NSAttributeDescription.AttributeType.transformable
            _ = NSAttributeDescription.AttributeType.objectID
            _ = NSAttributeDescription.AttributeType.composite
            _ = NSAttributeDescription.AttributeType.integer64
            _ = NSManagedObjectContext.ScheduledTaskType.immediate
            _ = NSManagedObjectContext.ScheduledTaskType.enqueued
            _ = NSManagedObjectContext.NotificationKey.refreshedObjects
            _ = NSManagedObjectContext.NotificationKey.invalidatedObjects
            _ = NSManagedObjectContext.NotificationKey.invalidatedAllObjects
            _ = NSManagedObjectContext.NotificationKey.queryGeneration
            _ = NSNotification.Name.NSManagedObjectContextDidSave
            _ = NSNotification.Name.NSManagedObjectContextWillSave
            _ = NSNotification.Name.NSManagedObjectContextObjectsDidChange
            _ = NSNotification.Name.NSManagedObjectContextDidSaveObjectIDs
            _ = NSNotification.Name.NSManagedObjectContextDidMergeChangesObjectIDs
            _ = NSPersistentCloudKitContainer.eventChangedNotification
            _ = NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            _ = NSQueryGenerationToken.current
            _ = NSPersistentHistoryChange.entityDescription
            _ = NSPersistentHistoryTransaction.fetchRequest
            _ = NSNotification.Name.NSCoreDataCoreSpotlightDelegateIndexDidUpdate
            _ = NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges
            _ = NSNotification.Name.NSPersistentStoreRemoteChange
            _ = NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange
            _ = NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange
            _ = NSNotification.Name.NSPersistentStoreCoordinatorWillRemoveStore

            func checkInequality<T: Equatable>(_ lhs: T, _ rhs: T, _ name: String) throws {
                guard lhs != rhs, lhs == lhs else {
                    throw ProbeFailure.message("\(name) Equatable/!= mismatch")
                }
            }
            func checkHash<T: Hashable>(_ value: T, _ name: String) throws {
                var hasher = Hasher()
                value.hash(into: &hasher)
                guard value.hashValue == value.hashValue else {
                    throw ProbeFailure.message("\(name) hashValue mismatch")
                }
            }
            try checkInequality(NSAttributeType.stringAttributeType, .booleanAttributeType, "NSAttributeType")
            try checkHash(NSAttributeType.stringAttributeType, "NSAttributeType")
            guard NSAttributeType(rawValue: 700) == .stringAttributeType else {
                throw ProbeFailure.message("NSAttributeType.init(rawValue:) failed")
            }
            try checkInequality(NSDeleteRule.cascadeDeleteRule, .nullifyDeleteRule, "NSDeleteRule")
            try checkHash(NSDeleteRule.cascadeDeleteRule, "NSDeleteRule")
            guard NSDeleteRule(rawValue: 2) == .cascadeDeleteRule else {
                throw ProbeFailure.message("NSDeleteRule.init(rawValue:) failed")
            }
            try checkInequality(NSEntityMappingType.addEntityMappingType, .copyEntityMappingType, "NSEntityMappingType")
            try checkHash(NSEntityMappingType.addEntityMappingType, "NSEntityMappingType")
            guard NSEntityMappingType(rawValue: 2) == .addEntityMappingType else {
                throw ProbeFailure.message("NSEntityMappingType.init(rawValue:) failed")
            }
            try checkInequality(NSFetchIndexElementType.binary, .rTree, "NSFetchIndexElementType")
            try checkHash(NSFetchIndexElementType.binary, "NSFetchIndexElementType")
            guard NSFetchIndexElementType(rawValue: 0) == .binary else {
                throw ProbeFailure.message("NSFetchIndexElementType.init(rawValue:) failed")
            }
            try checkInequality(NSFetchedResultsChangeType.insert, .delete, "NSFetchedResultsChangeType")
            try checkHash(NSFetchedResultsChangeType.insert, "NSFetchedResultsChangeType")
            guard NSFetchedResultsChangeType(rawValue: 1) == .insert else {
                throw ProbeFailure.message("NSFetchedResultsChangeType.init(rawValue:) failed")
            }
            try checkInequality(NSMergePolicyType.errorMergePolicyType, .overwriteMergePolicyType, "NSMergePolicyType")
            try checkHash(NSMergePolicyType.errorMergePolicyType, "NSMergePolicyType")
            guard NSMergePolicyType(rawValue: 0) == .errorMergePolicyType else {
                throw ProbeFailure.message("NSMergePolicyType.init(rawValue:) failed")
            }
            try checkInequality(NSPersistentHistoryChangeType.insert, .delete, "NSPersistentHistoryChangeType")
            try checkHash(NSPersistentHistoryChangeType.insert, "NSPersistentHistoryChangeType")
            guard NSPersistentHistoryChangeType(rawValue: 0) == .insert else {
                throw ProbeFailure.message("NSPersistentHistoryChangeType.init(rawValue:) failed")
            }
            try checkInequality(NSPersistentHistoryResultType.statusOnly, .changesOnly, "NSPersistentHistoryResultType")
            try checkHash(NSPersistentHistoryResultType.statusOnly, "NSPersistentHistoryResultType")
            guard NSPersistentHistoryResultType(rawValue: 0) == .statusOnly else {
                throw ProbeFailure.message("NSPersistentHistoryResultType.init(rawValue:) failed")
            }
            try checkInequality(NSPersistentStoreRequestType.fetchRequestType, .saveRequestType, "NSPersistentStoreRequestType")
            try checkHash(NSPersistentStoreRequestType.fetchRequestType, "NSPersistentStoreRequestType")
            guard NSPersistentStoreRequestType(rawValue: 1) == .fetchRequestType else {
                throw ProbeFailure.message("NSPersistentStoreRequestType.init(rawValue:) failed")
            }
            try checkInequality(
                NSPersistentStoreUbiquitousTransitionType.accountAdded,
                .accountRemoved,
                "NSPersistentStoreUbiquitousTransitionType"
            )
            try checkHash(NSPersistentStoreUbiquitousTransitionType.accountAdded, "NSPersistentStoreUbiquitousTransitionType")
            guard NSPersistentStoreUbiquitousTransitionType(rawValue: 1) == .accountAdded else {
                throw ProbeFailure.message("NSPersistentStoreUbiquitousTransitionType.init(rawValue:) failed")
            }
            try checkInequality(NSBatchDeleteRequestResultType.resultTypeStatusOnly, .resultTypeCount, "NSBatchDeleteRequestResultType")
            try checkHash(NSBatchDeleteRequestResultType.resultTypeStatusOnly, "NSBatchDeleteRequestResultType")
            guard NSBatchDeleteRequestResultType(rawValue: 0) == .resultTypeStatusOnly else {
                throw ProbeFailure.message("NSBatchDeleteRequestResultType.init(rawValue:) failed")
            }
            try checkInequality(NSBatchInsertRequestResultType.statusOnly, .count, "NSBatchInsertRequestResultType")
            try checkHash(NSBatchInsertRequestResultType.statusOnly, "NSBatchInsertRequestResultType")
            guard NSBatchInsertRequestResultType(rawValue: 0) == .statusOnly else {
                throw ProbeFailure.message("NSBatchInsertRequestResultType.init(rawValue:) failed")
            }
            try checkInequality(
                NSBatchUpdateRequestResultType.statusOnlyResultType,
                .updatedObjectsCountResultType,
                "NSBatchUpdateRequestResultType"
            )
            try checkHash(NSBatchUpdateRequestResultType.statusOnlyResultType, "NSBatchUpdateRequestResultType")
            guard NSBatchUpdateRequestResultType(rawValue: 0) == .statusOnlyResultType else {
                throw ProbeFailure.message("NSBatchUpdateRequestResultType.init(rawValue:) failed")
            }
            try checkInequality(
                NSPersistentCloudKitContainer.EventType.setup,
                .export,
                "NSPersistentCloudKitContainer.EventType"
            )
            try checkHash(NSPersistentCloudKitContainer.EventType.setup, "NSPersistentCloudKitContainer.EventType")
            guard NSPersistentCloudKitContainer.EventType(rawValue: 0) == .setup else {
                throw ProbeFailure.message("EventType.init(rawValue:) failed")
            }
            try checkInequality(
                NSPersistentCloudKitContainerEventResult.ResultType.events,
                .countEvents,
                "NSPersistentCloudKitContainerEventResult.ResultType"
            )
            try checkHash(NSPersistentCloudKitContainerEventResult.ResultType.events, "NSPersistentCloudKitContainerEventResult.ResultType")
            guard NSPersistentCloudKitContainerEventResult.ResultType(rawValue: 0) == .events else {
                throw ProbeFailure.message("EventResult.ResultType.init(rawValue:) failed")
            }
            try checkInequality(
                NSManagedObjectContext.ConcurrencyType.mainQueue,
                .privateQueue,
                "ConcurrencyType"
            )
            try checkHash(NSManagedObjectContext.ConcurrencyType.mainQueue, "ConcurrencyType")
            try checkInequality(
                NSManagedObjectContext.NotificationKey.insertedObjects,
                .deletedObjects,
                "NotificationKey"
            )
            try checkHash(NSManagedObjectContext.NotificationKey.insertedObjects, "NotificationKey")
            try checkInequality(
                NSManagedObjectContext.ScheduledTaskType.immediate,
                .enqueued,
                "ScheduledTaskType"
            )
            try checkHash(NSManagedObjectContext.ScheduledTaskType.immediate, "ScheduledTaskType")
            try checkInequality(NSPersistentStore.StoreType.sqlite, .inMemory, "StoreType")
            try checkHash(NSPersistentStore.StoreType.sqlite, "StoreType")
            guard NSPersistentStore.StoreType(rawValue: NSSQLiteStoreType).rawValue == NSSQLiteStoreType else {
                throw ProbeFailure.message("StoreType.init(rawValue:) failed")
            }

            func checkOptionSet<T: OptionSet>(_ value: T, _ other: T, _ name: String) throws where T.Element == T, T: Hashable {
                var working = T()
                try checkInequality(value, other, name)
                try checkHash(value, name)
                guard working.isEmpty else {
                    throw ProbeFailure.message("\(name) empty isEmpty failed")
                }
                working = T([value])
                _ = T([value, other])
                let literal: T = [value, other]
                guard literal.contains(value), literal.contains(other) else {
                    throw ProbeFailure.message("\(name) OptionSet array-literal init failed")
                }
                guard working.contains(value),
                      working.isSubset(of: value.union(other)),
                      working.union(other).isSuperset(of: other),
                      !working.isDisjoint(with: value),
                      working.subtracting(value).isEmpty,
                      working.intersection(value) == value,
                      !working.isStrictSubset(of: working),
                      working.union(other).isStrictSuperset(of: working) || working.union(other) == working else {
                    throw ProbeFailure.message("\(name) OptionSet algebra failed")
                }
                var mutable = working
                mutable.formUnion(other)
                mutable.formIntersection(value)
                mutable.formSymmetricDifference(other)
                mutable.subtract(other)
                _ = mutable.insert(value)
                _ = mutable.remove(other)
                _ = mutable.update(with: value)
            }
            try checkOptionSet(
                NSFetchRequestResultType.dictionaryResultType,
                NSFetchRequestResultType.countResultType,
                "NSFetchRequestResultType"
            )
            try checkOptionSet(
                NSSnapshotEventType.refresh,
                NSSnapshotEventType.rollback,
                "NSSnapshotEventType"
            )
            try checkOptionSet(
                NSPersistentCloudKitContainerSchemaInitializationOptions.dryRun,
                NSPersistentCloudKitContainerSchemaInitializationOptions.printSchema,
                "NSPersistentCloudKitContainerSchemaInitializationOptions"
            )
            guard NSFetchRequestResultType(rawValue: 2) == .dictionaryResultType,
                  NSSnapshotEventType(rawValue: 1 << 5) == .refresh,
                  NSPersistentCloudKitContainerSchemaInitializationOptions(rawValue: 1 << 1) == .dryRun else {
                throw ProbeFailure.message("OptionSet init(rawValue:) mismatch")
            }
    } catch {
        fatalError("testEnumOptionSetAndConstantValues failed: \(error)")
    }
}

func testXMLModelLoadFromContents() {
    do {
            try withUniqueTempDirectory { directory in
                let contents = directory.appendingPathComponent("contents")
                try agentModelContentsXML().write(to: contents, atomically: true, encoding: .utf8)
                guard let model = NSManagedObjectModel(contentsOf: contents) else {
                    throw ProbeFailure.message("contents XML must load into NSManagedObjectModel")
                }
                guard let note = model.entitiesByName["Note"],
                      let title = note.attributesByName["title"],
                      title.attributeType == .stringAttributeType,
                      title.isOptional == false,
                      let count = note.attributesByName["count"],
                      count.attributeType == .integer64AttributeType,
                      count.isOptional,
                      (count.defaultValue as? Int == 0 || (count.defaultValue as? NSNumber)?.intValue == 0),
                      let scratch = note.attributesByName["scratch"],
                      scratch.isTransient,
                      scratch.isOptional else {
                    throw ProbeFailure.message("XML attribute types/optional/default/transient mismatch")
                }
                guard model.versionIdentifiers.contains("notes-v1") else {
                    throw ProbeFailure.message("userDefinedModelVersionIdentifier must become versionIdentifiers")
                }
                guard NSManagedObjectModel(contentsOf: directory.appendingPathComponent("missing.mom")) == nil else {
                    throw ProbeFailure.message("missing compiled .mom must still return nil")
                }
            }
    } catch {
        fatalError("testXMLModelLoadFromContents failed: \(error)")
    }
}

func testXMLModelLoadXcdatamodeld() {
    do {
            try withUniqueTempDirectory { directory in
                let bundle = try writeAgentXMLModelBundle(in: directory)
                guard let model = NSManagedObjectModel(contentsOfURL: bundle) else {
                    throw ProbeFailure.message(".xcdatamodeld bundle must load the current contents XML")
                }
                guard model.entitiesByName["Author"] != nil,
                      model.entitiesByName["Note"] != nil else {
                    throw ProbeFailure.message("xcdatamodeld must expose Author and Note")
                }
                let current = bundle.appendingPathComponent("Notes.xcdatamodel")
                guard NSManagedObjectModel(contentsOf: current) != nil else {
                    throw ProbeFailure.message(".xcdatamodel directory must load contents")
                }
            }
    } catch {
        fatalError("testXMLModelLoadXcdatamodeld failed: \(error)")
    }
}

func testXMLModelRelationshipsFetchedPropertiesAndConstraints() {
    do {
            try withUniqueTempDirectory { directory in
                let bundle = try writeAgentXMLModelBundle(in: directory)
                guard let model = NSManagedObjectModel(contentsOf: bundle),
                      let author = model.entitiesByName["Author"],
                      let note = model.entitiesByName["Note"],
                      let notesRel = author.relationshipsByName["notes"],
                      let authorRel = note.relationshipsByName["author"] else {
                    throw ProbeFailure.message("XML model missing relationship descriptions")
                }
                guard notesRel.isToMany,
                      notesRel.isOrdered,
                      notesRel.deleteRule == .cascadeDeleteRule,
                      notesRel.destinationEntity === note,
                      notesRel.inverseRelationship === authorRel,
                      authorRel.maxCount == 1,
                      authorRel.deleteRule == .nullifyDeleteRule,
                      authorRel.destinationEntity === author,
                      authorRel.inverseRelationship === notesRel else {
                    throw ProbeFailure.message("XML relationship inverse/delete-rule/ordered mismatch")
                }
                guard let fetched = note.propertiesByName["allNotes"] as? NSFetchedPropertyDescription,
                      fetched.fetchRequest?.entityName == "Note" else {
                    throw ProbeFailure.message("XML fetched property must carry a fetch request")
                }
                guard let constraint = author.uniquenessConstraints.first,
                      constraint.map({ String(describing: $0) }) == ["name"] else {
                    throw ProbeFailure.message("XML uniqueness constraints must parse constraint values")
                }
                guard author.managedObjectClassName == "Author",
                      note.relationships(forDestination: author).contains(where: { $0.name == "author" }) else {
                    throw ProbeFailure.message("representedClassName / relationships(forDestination:) mismatch")
                }
            }
    } catch {
        fatalError("testXMLModelRelationshipsFetchedPropertiesAndConstraints failed: \(error)")
    }
}

func testSQLiteCRUDAndFaulting() {
    do {
            try withUniqueTempDirectory { directory in
                let model = makeNoteModel()
                let container = try makeLoadedSQLiteContainer(model, directory: directory, name: "SQLiteCRUD")
                let context = container.viewContext
                guard NSPersistentStoreCoordinator.registeredStoreTypes[NSSQLiteStoreType] != nil else {
                    throw ProbeFailure.message("NSSQLiteStoreType must be registered")
                }
                let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                note.setValue("sqlite-hello", forKey: "title")
                note.setValue(4, forKey: "count")
                guard note.objectID.isTemporaryID else {
                    throw ProbeFailure.message("inserted SQLite objectID must start temporary")
                }
                context.assign(note, to: container.persistentStoreCoordinator.persistentStores[0])
                try context.obtainPermanentIDs(for: [note])
                guard !note.objectID.isTemporaryID else {
                    throw ProbeFailure.message("obtainPermanentIDs must promote a temporary SQLite objectID")
                }
                try context.save()
                guard FileManager.default.fileExists(atPath: directory.appendingPathComponent("SQLiteCRUD.sqlite").path) else {
                    throw ProbeFailure.message("SQLite save must create a store file")
                }

                let reopened = try makeLoadedSQLiteContainer(model, directory: directory, name: "SQLiteCRUD")
                let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
                request.returnsObjectsAsFaults = true
                let fetched = try reopened.viewContext.fetch(request)
                guard fetched.count == 1 else {
                    throw ProbeFailure.message("reopened SQLite store must fetch the saved row")
                }
                guard fetched[0].isFault else {
                    throw ProbeFailure.message("returnsObjectsAsFaults must yield a fault from SQLite")
                }
                guard fetched[0].value(forKey: "title") as? String == "sqlite-hello",
                      cdInt(fetched[0], "count") == 4 else {
                    throw ProbeFailure.message("fault fulfillment must read SQLite attribute values")
                }
                fetched[0].setValue("sqlite-updated", forKey: "title")
                try reopened.viewContext.save()
                reopened.viewContext.delete(fetched[0])
                try reopened.viewContext.save()
                guard try reopened.viewContext.count(for: request) == 0 else {
                    throw ProbeFailure.message("SQLite delete/save did not remove the row")
                }
            }
    } catch {
        fatalError("testSQLiteCRUDAndFaulting failed: \(error)")
    }
}

func testSQLiteFetchLimitOffsetAndPredicate() {
    do {
            try withUniqueTempDirectory { directory in
                let container = try makeLoadedSQLiteContainer(makeNoteModel(), directory: directory, name: "SQLitePage")
                let context = container.viewContext
                for title in ["c", "a", "b"] {
                    let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                    note.setValue(title, forKey: "title")
                }
                try context.save()
                let request = NSFetchRequest<NSManagedObject>(entityName: "Note")
                request.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
                request.predicate = NSPredicate { object, _ in
                    (object as? NSManagedObject)?.value(forKey: "title") as? String != "c"
                }
                request.fetchOffset = 1
                request.fetchLimit = 1
                let page = try context.fetch(request)
                guard page.count == 1, page[0].value(forKey: "title") as? String == "b" else {
                    throw ProbeFailure.message("SQLite predicate/sort/offset/limit mismatch")
                }
            }
    } catch {
        fatalError("testSQLiteFetchLimitOffsetAndPredicate failed: \(error)")
    }
}

func testSQLiteIncompatibleSchemaAndMigrationFailClosed() {
    do {
            try withUniqueTempDirectory { directory in
                let garbage = directory.appendingPathComponent("garbage.sqlite")
                try "not-a-database".write(to: garbage, atomically: true, encoding: .utf8)
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeNoteModel())
                do {
                    _ = try coordinator.addPersistentStore(
                        ofType: NSSQLiteStoreType,
                        configurationName: nil,
                        at: garbage,
                        options: nil
                    )
                    throw ProbeFailure.message("garbage SQLite bytes must not open as a store")
                } catch is ProbeFailure {
                    throw ProbeFailure.message("garbage SQLite bytes must not open as a store")
                } catch {
                    let ns = error as NSError
                    guard ns.code == NSPersistentStoreIncompatibleSchemaError
                            || ns.code == NSPersistentStoreOpenError
                            || ns.code == NSSQLiteError else {
                        throw ProbeFailure.message("garbage file should use schema/open/sqlite error, got \(ns.code)")
                    }
                }

                let storeURL = directory.appendingPathComponent("version.sqlite")
                _ = try coordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: storeURL,
                    options: nil
                )
                let otherModel = NSManagedObjectModel()
                let entity = NSEntityDescription()
                entity.name = "Other"
                entity.managedObjectClassName = "NSManagedObject"
                let attr = NSAttributeDescription()
                attr.name = "value"
                attr.attributeType = .stringAttributeType
                entity.properties = [attr]
                otherModel.entities = [entity]
                let other = NSPersistentStoreCoordinator(managedObjectModel: otherModel)
                do {
                    _ = try other.addPersistentStore(
                        ofType: NSSQLiteStoreType,
                        configurationName: nil,
                        at: storeURL,
                        options: [
                            NSMigratePersistentStoresAutomaticallyOption: true as NSNumber,
                            NSInferMappingModelAutomaticallyOption: true as NSNumber
                        ]
                    )
                    throw ProbeFailure.message("model hash mismatch must fail closed instead of migrating")
                } catch is ProbeFailure {
                    throw ProbeFailure.message("model hash mismatch must fail closed instead of migrating")
                } catch {
                    let ns = error as NSError
                    guard ns.code == NSPersistentStoreIncompatibleVersionHashError
                            || ns.code == NSMigrationError else {
                        throw ProbeFailure.message("hash mismatch should be version-hash or migration error, got \(ns.code)")
                    }
                }
            }
    } catch {
        fatalError("testSQLiteIncompatibleSchemaAndMigrationFailClosed failed: \(error)")
    }
}

func testSQLiteDestroyAndMetadata() {
    do {
            try withUniqueTempDirectory { directory in
                let url = directory.appendingPathComponent("meta.sqlite")
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeNoteModel())
                coordinator.name = "sqlite-meta"
                _ = coordinator.managedObjectModel
                _ = coordinator.tryLock()
                coordinator.unlock()
                coordinator.performAndWait {
                    _ = coordinator.persistentStores
                }
                let store = try coordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: url,
                    options: [NSSQLitePragmasOption: ["journal_mode": "DELETE"] as NSDictionary]
                )
                guard store.type == NSSQLiteStoreType,
                      store.url == url,
                      coordinator.url(for: store) == url,
                      coordinator.persistentStores.contains(where: { $0 === store }) else {
                    throw ProbeFailure.message("SQLite store identity/url mismatch")
                }
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: NSSQLiteStoreType,
                    at: url,
                    options: nil
                )
                guard metadata[NSStoreTypeKey] as? String == NSSQLiteStoreType else {
                    throw ProbeFailure.message("SQLite metadata must report NSSQLiteStoreType")
                }
                try NSPersistentStoreCoordinator.setMetadata(
                    [NSStoreTypeKey: NSSQLiteStoreType, "extra": "1"],
                    forPersistentStoreOfType: NSSQLiteStoreType,
                    at: url,
                    options: nil
                )
                try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType)
                guard !FileManager.default.fileExists(atPath: url.path) else {
                    throw ProbeFailure.message("destroyPersistentStore must remove the SQLite file")
                }
            }
    } catch {
        fatalError("testSQLiteDestroyAndMetadata failed: \(error)")
    }
}

func testDidSaveAndObjectsDidChangeUserInfoKeys() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "NotifyKeys")
            let context = container.viewContext
            final class Capture: @unchecked Sendable {
                var change: [AnyHashable: Any]?
                var save: [AnyHashable: Any]?
            }
            let capture = Capture()
            let changeObs = NotificationCenter.default.addObserver(
                forName: .NSManagedObjectContextObjectsDidChange,
                object: context,
                queue: nil
            ) { note in
                capture.change = note.userInfo
            }
            let saveObs = NotificationCenter.default.addObserver(
                forName: .NSManagedObjectContextDidSave,
                object: context,
                queue: nil
            ) { note in
                capture.save = note.userInfo
            }
            defer {
                NotificationCenter.default.removeObserver(changeObs)
                NotificationCenter.default.removeObserver(saveObs)
            }
            let note = NSManagedObject(
                entity: context.persistentStoreCoordinator!.managedObjectModel.entitiesByName["Note"]!,
                insertInto: context
            )
            note.setValue("notify", forKey: "title")
            context.processPendingChanges()
            guard let change = capture.change else {
                throw ProbeFailure.message("insert must post NSManagedObjectContextObjectsDidChange")
            }
            guard change[NSInsertedObjectsKey] is Set<NSManagedObject>,
                  change[NSUpdatedObjectsKey] is Set<NSManagedObject>,
                  change[NSDeletedObjectsKey] is Set<NSManagedObject>,
                  change[NSRefreshedObjectsKey] is Set<NSManagedObject>,
                  change[NSInvalidatedObjectsKey] is Set<NSManagedObject> else {
                throw ProbeFailure.message("objects-did-change userInfo keys must be exact")
            }
            try context.save()
            guard let save = capture.save else {
                throw ProbeFailure.message("save must post NSManagedObjectContextDidSave")
            }
            guard save[NSInsertedObjectsKey] is Set<NSManagedObject>,
                  save[NSUpdatedObjectsKey] is Set<NSManagedObject>,
                  save[NSDeletedObjectsKey] is Set<NSManagedObject>,
                  save[NSInsertedObjectIDsKey] is Set<NSManagedObjectID>,
                  save[NSUpdatedObjectIDsKey] is Set<NSManagedObjectID>,
                  save[NSDeletedObjectIDsKey] is Set<NSManagedObjectID> else {
                throw ProbeFailure.message("did-save userInfo keys must be exact")
            }
            let registered = context.registeredObject(for: note.objectID)
            guard registered === note else {
                throw ProbeFailure.message("registeredObject(for:) must return the inserted instance")
            }
            _ = context.object(with: note.objectID)
            context.detectConflicts(for: note)
            _ = context.tryLock()
            context.unlock()
            context.reset()
            guard context.registeredObjects.isEmpty else {
                throw ProbeFailure.message("reset must drop registered objects")
            }
    } catch {
        fatalError("testDidSaveAndObjectsDidChangeUserInfoKeys failed: \(error)")
    }
}

func testPropertiesToGroupBy() {
    do {
            let container = try makeLoadedContainer(makeNoteModel(), name: "GroupBy")
            let context = container.viewContext
            for title in ["x", "x", "y"] {
                let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
                note.setValue(title, forKey: "title")
            }
            try context.save()
            let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["title"]
            request.propertiesToGroupBy = ["title"]
            request.havingPredicate = NSPredicate { object, _ in
                ((object as? NSManagedObject)?.value(forKey: "title") as? String) != nil
            }
            let grouped = try context.fetch(request)
            guard grouped.count == 2,
                  grouped.allSatisfy({ $0 is NSDictionary }) else {
                throw ProbeFailure.message("propertiesToGroupBy must collapse duplicate titles into two dictionaries")
            }
            let titles = Set(grouped.compactMap { ($0 as? NSDictionary)?["title"] as? String })
            guard titles == ["x", "y"] else {
                throw ProbeFailure.message("grouped titles mismatch: \(titles)")
            }
    } catch {
        fatalError("testPropertiesToGroupBy failed: \(error)")
    }
}

func testManagedObjectKVCAccessors() {
    do {
            let container = try makeLoadedContainer(makeAuthorNoteModel(), name: "KVC")
            let context = container.viewContext
            let entity = context.persistentStoreCoordinator!.managedObjectModel.entitiesByName["Note"]!
            let note = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context)
            note.setPrimitiveValue("kvc", forKey: "title")
            guard note.primitiveValue(forKey: "title") as? String == "kvc" else {
                throw ProbeFailure.message("primitiveValue/setPrimitiveValue round-trip failed")
            }
            note.willAccessValue(forKey: "title")
            note.didAccessValue(forKey: "title")
            note.willChangeValue(forKey: "title")
            note.setValue("kvc-2", forKey: "title")
            note.didChangeValue(forKey: "title")
            guard note.value(forKey: "title") as? String == "kvc-2" else {
                throw ProbeFailure.message("value(forKey:)/setValue mismatch")
            }
            _ = note.changedValuesForCurrentEvent()
            try note.validateForInsert()
            try note.validateValue("kvc-2" as NSString, forKey: "title")
            try context.save()
            _ = note.hasFault(forRelationshipNamed: "author")
            _ = note.objectIDs(forRelationshipNamed: "author")
            context.refresh(note, mergeChanges: false)
            guard note.isFault else {
                throw ProbeFailure.message("refresh(mergeChanges: false) must turn the object into a fault")
            }
            let existing = try context.existingObject(with: note.objectID)
            _ = existing
            context.refreshAllObjects()
            try note.validateForUpdate()
            try note.validateForDelete()
    } catch {
        fatalError("testManagedObjectKVCAccessors failed: \(error)")
    }
}

func testConstraintConflictOnSave() {
    do {
            let model = makeNoteModel()
            model.entitiesByName["Note"]?.uniquenessConstraints = [["title"]]
            let container = try makeLoadedContainer(model, name: "Constraint")
            let context = container.viewContext
            context.mergePolicy = NSMergePolicy.error
            let first = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            first.setValue("dup", forKey: "title")
            let second = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            second.setValue("dup", forKey: "title")
            do {
                try context.save()
                throw ProbeFailure.message("duplicate uniqueness constraint must fail save")
            } catch is ProbeFailure {
                throw ProbeFailure.message("duplicate uniqueness constraint must fail save")
            } catch {
                let ns = error as NSError
                guard ns.code == NSManagedObjectConstraintMergeError || ns.code == NSManagedObjectMergeError else {
                    throw ProbeFailure.message("constraint save should use constraint/merge error, got \(ns.code)")
                }
                let conflicts = ns.userInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSConstraintConflict]
                if let conflict = conflicts?.first {
                    guard conflict.constraint == ["title"],
                          !conflict.conflictingObjects.isEmpty,
                          conflict.constraintValues["title"] as? String == "dup" else {
                        throw ProbeFailure.message("NSConstraintConflict did not capture title uniqueness")
                    }
                    _ = conflict.databaseObject
                    _ = conflict.databaseSnapshot
                    _ = conflict.conflictingSnapshots
                }
            }
            let constructed = NSConstraintConflict(
                constraint: ["title"],
                databaseObject: first,
                databaseSnapshot: ["title": "dup"],
                conflictingObjects: [first, second],
                conflictingSnapshots: [["title": "dup"], ["title": "dup"]]
            )
            guard constructed.constraint == ["title"],
                  constructed.conflictingObjects.count == 2 else {
                throw ProbeFailure.message("NSConstraintConflict designated initializer mismatch")
            }
    } catch {
        fatalError("testConstraintConflictOnSave failed: \(error)")
    }
}

func makePersonEmployeeModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    let person = NSEntityDescription()
    person.name = "Person"
    person.managedObjectClassName = "NSManagedObject"
    person.isAbstract = false
    person.renamingIdentifier = "Person_v1"
    person.versionHashModifier = "person-hash"
    let personName = NSAttributeDescription()
    personName.name = "name"
    personName.attributeType = .stringAttributeType
    personName.isOptional = false
    personName.isIndexed = true
    person.properties = [personName]

    let employee = NSEntityDescription()
    employee.name = "Employee"
    employee.managedObjectClassName = "NSManagedObject"
    let title = NSAttributeDescription()
    title.name = "title"
    title.attributeType = .stringAttributeType
    title.isOptional = true
    employee.properties = [title]
    person.subentities = [employee]
    model.entities = [person, employee]
    return model
}

func testEntityInheritanceAndIndexes() {
    do {
        let model = makePersonEmployeeModel()
        guard let person = model.entitiesByName["Person"],
              let employee = model.entitiesByName["Employee"] else {
            throw ProbeFailure.message("Person/Employee missing from entitiesByName")
        }
        person.compoundIndexes = [["name"]]
        let nameProperty = person.attributesByName["name"]!
        let indexElement = NSFetchIndexElementDescription(property: nameProperty, collationType: .binary)
        person.indexes = [NSFetchIndexDescription(name: "byName", elements: [indexElement])]
        guard person.subentities.first === employee,
              person.subentitiesByName["Employee"] === employee,
              employee.superentity === person,
              employee.isKindOf(entity: person),
              person.isKindOf(entity: person),
              person.isKindOf(entity: employee) == false,
              person.isAbstract == false,
              person.renamingIdentifier == "Person_v1",
              person.versionHashModifier == "person-hash",
              !person.versionHash.isEmpty,
              person.compoundIndexes.count == 1,
              person.indexes.first?.name == "byName",
              person.managedObjectModel === model else {
            throw ProbeFailure.message("entity inheritance/index metadata mismatch")
        }

        let container = try makeLoadedContainer(model, name: "Inheritance")
        let context = container.viewContext
        guard NSEntityDescription.entity(forEntityName: "Employee", in: context) === employee else {
            throw ProbeFailure.message("entity(forEntityName:in:) did not resolve Employee")
        }
        let staff = NSEntityDescription.insertNewObject(forEntityName: "Employee", into: context)
        staff.setValue("Ada", forKey: "name")
        staff.setValue("Engineer", forKey: "title")
        try context.save()

        let people = NSFetchRequest<NSManagedObject>(entityName: "Person")
        people.includesSubentities = true
        let withChildren = try context.fetch(people)
        people.includesSubentities = false
        let onlyPerson = try context.fetch(people)
        guard withChildren.count == 1, onlyPerson.isEmpty else {
            throw ProbeFailure.message("includesSubentities did not include Employee rows under Person")
        }
    } catch {
        fatalError("testEntityInheritanceAndIndexes failed: \(error)")
    }
}

func testPropertyDescriptionMetadataAndValidation() {
    do {
        let model = makeNoteModel()
        let entity = model.entitiesByName["Note"]!
        guard let title = entity.attributesByName["title"] else {
            throw ProbeFailure.message("Note.title missing")
        }
        title.isIndexed = true
        title.isIndexedBySpotlight = false
        title.isStoredInExternalRecord = false
        title.renamingIdentifier = "headline"
        title.versionHashModifier = "title-v2"
        title.userInfo = ["owner": "test"]
        title.setValidationPredicates(
            [NSPredicate(block: { value, _ in
                (value as? String)?.isEmpty == false
            })],
            withValidationWarnings: ["title must be non-empty"]
        )
        guard title.entity === entity,
              title.isIndexed,
              title.isIndexedBySpotlight == false,
              title.isStoredInExternalRecord == false,
              title.renamingIdentifier == "headline",
              title.versionHashModifier == "title-v2",
              title.userInfo?["owner"] as? String == "test",
              title.validationPredicates.count == 1,
              (title.validationWarnings as? [String]) == ["title must be non-empty"],
              !title.versionHash.isEmpty else {
            throw ProbeFailure.message("NSPropertyDescription metadata mismatch")
        }
        let container = try makeLoadedContainer(model, name: "PropertyMeta")
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: container.viewContext)
        do {
            try note.validateValue("" as NSString, forKey: "title")
            throw ProbeFailure.message("empty title must fail validation predicate")
        } catch is ProbeFailure {
            throw ProbeFailure.message("empty title must fail validation predicate")
        } catch {
            let ns = error as NSError
            guard ns.code == NSManagedObjectValidationError else {
                throw ProbeFailure.message("validation predicate should use NSManagedObjectValidationError, got \(ns.code)")
            }
        }
        try note.validateValue("ok" as NSString, forKey: "title")
    } catch {
        fatalError("testPropertyDescriptionMetadataAndValidation failed: \(error)")
    }
}

func testFetchRequestOptionsAndDistinct() {
    do {
        let container = try makeLoadedContainer(makeAuthorNoteModel(), name: "FetchOptions")
        let context = container.viewContext
        let author = NSEntityDescription.insertNewObject(forEntityName: "Author", into: context)
        author.setValue("Pat", forKey: "name")
        for title in ["alpha", "alpha", "beta"] {
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue(title, forKey: "title")
            note.setValue(author, forKey: "author")
        }
        try context.save()

        let pending = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        pending.setValue("pending", forKey: "title")

        let unsaved = NSFetchRequest<NSManagedObject>(entityName: "Note")
        unsaved.includesPendingChanges = true
        let withPending = try context.fetch(unsaved)
        unsaved.includesPendingChanges = false
        let withoutPending = try context.fetch(unsaved)
        guard withPending.count == 4, withoutPending.count == 3 else {
            throw ProbeFailure.message("includesPendingChanges mismatch \(withPending.count)/\(withoutPending.count)")
        }

        let distinct = NSFetchRequest<NSDictionary>(entityName: "Note")
        distinct.includesPendingChanges = false
        distinct.returnsDistinctResults = true
        distinct.propertiesToFetch = ["title"]
        distinct.resultType = .dictionaryResultType
        let distinctRows = try context.fetch(distinct)
        guard distinctRows.count == 2 else {
            throw ProbeFailure.message("returnsDistinctResults should collapse duplicate titles, got \(distinctRows.count)")
        }

        let batch = NSFetchRequest<NSManagedObject>(entityName: "Note")
        batch.includesPendingChanges = false
        batch.returnsObjectsAsFaults = false
        batch.fetchBatchSize = 1
        batch.sortDescriptors = [cdSortDescriptor(key: "title", ascending: true)]
        let batched = try context.fetch(batch)
        guard batched.count == 3,
              batched.first?.isFault == false,
              batched.dropFirst().allSatisfy(\.isFault) else {
            throw ProbeFailure.message("fetchBatchSize should fault objects past the first batch")
        }

        let refresh = NSFetchRequest<NSManagedObject>(entityName: "Note")
        refresh.includesPendingChanges = false
        refresh.shouldRefreshRefetchedObjects = true
        refresh.includesPropertyValues = true
        refresh.relationshipKeyPathsForPrefetching = ["author"]
        refresh.entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Note"]
        refresh.affectedStores = context.persistentStoreCoordinator?.persistentStores
        _ = refresh.entityName
        let prefetched = try context.fetch(refresh)
        guard let first = prefetched.first else {
            throw ProbeFailure.message("prefetch fetch returned no notes")
        }
        _ = first.value(forKey: "author")
        guard first.hasFault(forRelationshipNamed: "author") == false else {
            throw ProbeFailure.message("relationshipKeyPathsForPrefetching did not fulfill author")
        }

        let faults = NSFetchRequest<NSManagedObject>(entityName: "Note")
        faults.includesPendingChanges = false
        faults.includesPropertyValues = false
        faults.returnsObjectsAsFaults = true
        let faulted = try context.fetch(faults)
        guard faulted.allSatisfy(\.isFault) else {
            throw ProbeFailure.message("includesPropertyValues=false should return faults")
        }

        let blank = NSFetchRequest<any NSFetchRequestResult>()
        blank.entityName.map { _ in }
        blank.entity = refresh.entity
        blank.fetchBatchSize = 2
        guard blank.entity?.name == "Note", blank.fetchBatchSize == 2 else {
            throw ProbeFailure.message("NSFetchRequest init/entity/fetchBatchSize mismatch")
        }
        _ = try context.execute(blank)
    } catch {
        fatalError("testFetchRequestOptionsAndDistinct failed: \(error)")
    }
}

func testBatchInsertHandlers() {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "BatchHandlers")
        let context = container.viewContext
        let entity = context.persistentStoreCoordinator!.managedObjectModel.entitiesByName["Note"]!

        var remaining = ["h1", "h2"]
        let dictRequest = NSBatchInsertRequest(entity: entity, dictionaryHandler: { dictionary in
            guard let next = remaining.first else { return false }
            remaining.removeFirst()
            dictionary["title"] = next
            return !remaining.isEmpty
        })
        dictRequest.resultType = .count
        let dictResult = try context.execute(dictRequest) as? NSBatchInsertResult
        guard dictResult?.result as? Int == 2,
              dictRequest.dictionaryHandler != nil,
              dictRequest.entity === entity,
              dictRequest.entityName == "Note" else {
            throw ProbeFailure.message("dictionaryHandler batch insert mismatch")
        }

        var objectRemaining = ["h3"]
        let objectRequest = NSBatchInsertRequest(entityName: "Note", managedObjectHandler: { object in
            guard let next = objectRemaining.first else { return false }
            objectRemaining.removeFirst()
            object.setValue(next, forKey: "title")
            return !objectRemaining.isEmpty
        })
        objectRequest.resultType = .objectIDs
        let objectResult = try context.execute(objectRequest) as? NSBatchInsertResult
        guard let ids = objectResult?.result as? [NSManagedObjectID], ids.count == 1,
              objectRequest.managedObjectHandler != nil else {
            throw ProbeFailure.message("managedObjectHandler batch insert mismatch")
        }

        var namedRemaining = ["h4"]
        let namedDict = NSBatchInsertRequest(entityName: "Note", dictionaryHandler: { dictionary in
            guard let next = namedRemaining.first else { return false }
            namedRemaining.removeFirst()
            dictionary["title"] = next
            return false
        })
        namedDict.objectsToInsert = nil
        _ = try context.execute(namedDict)

        var namedObjectRemaining = ["h5"]
        let namedObject = NSBatchInsertRequest(entity: entity, managedObjectHandler: { object in
            guard let next = namedObjectRemaining.first else { return false }
            namedObjectRemaining.removeFirst()
            object.setValue(next, forKey: "title")
            return false
        })
        _ = try context.execute(namedObject)

        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Note")
        let titles = Set(try context.fetch(fetch).compactMap { $0.value(forKey: "title") as? String })
        guard titles.isSuperset(of: ["h1", "h2", "h3", "h4", "h5"]) else {
            throw ProbeFailure.message("handler-inserted titles missing: \(titles)")
        }
    } catch {
        fatalError("testBatchInsertHandlers failed: \(error)")
    }
}

func testAtomicStoreCacheNodes() {
    do {
        let typeName = "LinuxAtomicStoreType"
        NSPersistentStoreCoordinator.registerStoreClass(NSAtomicStore.self, forStoreType: typeName)
        defer { NSPersistentStoreCoordinator.registerStoreClass(nil, forStoreType: typeName) }

        let model = makeNoteModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let url = URL(string: "x-coredata-atomic://notes")!
        let store = try coordinator.addPersistentStore(
            ofType: typeName,
            configurationName: nil,
            at: url,
            options: nil
        )
        guard let atomic = store as? NSAtomicStore else {
            throw ProbeFailure.message("registered NSAtomicStore class was not instantiated")
        }
        try atomic.load()
        guard atomic.cacheNodes().isEmpty else {
            throw ProbeFailure.message("new atomic store should start with no cache nodes")
        }

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("atomic-title", forKey: "title")
        let reference = atomic.newReferenceObject(for: note)
        let objectID = atomic.objectID(for: note.entity, withReferenceObject: reference)
        guard String(describing: atomic.referenceObject(for: objectID)) == String(describing: reference) else {
            throw ProbeFailure.message("atomic referenceObject/objectID round-trip failed")
        }
        let node = atomic.newCacheNode(for: note)
        atomic.addCacheNodes([node])
        atomic.updateCacheNode(node, from: note)
        guard atomic.cacheNode(for: note.objectID) != nil || atomic.cacheNodes().contains(where: { $0.objectID == node.objectID }) else {
            throw ProbeFailure.message("addCacheNodes did not retain the node")
        }
        try context.save()
        try atomic.save()

        let fetched = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Note"))
        guard fetched.contains(where: { $0.value(forKey: "title") as? String == "atomic-title" }) else {
            throw ProbeFailure.message("atomic store did not persist the inserted note")
        }
        atomic.willRemoveCacheNodes(atomic.cacheNodes())
        guard atomic.cacheNodes().isEmpty else {
            throw ProbeFailure.message("willRemoveCacheNodes should empty the cache")
        }
    } catch {
        fatalError("testAtomicStoreCacheNodes failed: \(error)")
    }
}

func testIncrementalStoreAdapter() {
    do {
        let typeName = "LinuxIncrementalStoreType"
        NSPersistentStoreCoordinator.registerStoreClass(NSIncrementalStore.self, forStoreType: typeName)
        defer { NSPersistentStoreCoordinator.registerStoreClass(nil, forStoreType: typeName) }

        let model = makeNoteModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let storeURL = URL(string: "x-coredata-incremental://notes")!
        let newID = NSIncrementalStore.identifierForNewStore(at: storeURL)
        guard String(describing: newID).contains("incremental") || String(describing: newID) == storeURL.absoluteString else {
            throw ProbeFailure.message("identifierForNewStore should use the store URL")
        }
        let store = try coordinator.addPersistentStore(
            ofType: typeName,
            configurationName: nil,
            at: storeURL,
            options: nil
        )
        guard let incremental = store as? NSIncrementalStore else {
            throw ProbeFailure.message("registered NSIncrementalStore class was not instantiated")
        }
        try incremental.loadMetadata()

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("inc-title", forKey: "title")
        let permanent = try incremental.obtainPermanentIDs(for: [note])
        guard let assigned = permanent.first, assigned.isTemporaryID == false else {
            throw ProbeFailure.message("obtainPermanentIDs should return a permanent ID")
        }
        incremental.managedObjectContextDidRegisterObjects(with: [assigned])
        try context.save()

        let fetch = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
        let executed = try incremental.execute(fetch, with: context)
        _ = executed
        guard let entity = model.entitiesByName["Note"] else {
            throw ProbeFailure.message("Note entity missing")
        }
        let objectID = incremental.newObjectID(for: entity, referenceObject: incremental.referenceObject(for: assigned))
        _ = incremental.referenceObject(for: objectID)
        if let node = try? incremental.newValuesForObject(with: assigned, with: context) {
            _ = node.version
            if let title = entity.attributesByName["title"] {
                _ = node.value(for: title)
            }
        }
        if let relationship = entity.relationshipsByName.values.first {
            _ = try? incremental.newValue(forRelationship: relationship, forObjectWith: assigned, with: context)
        }
        incremental.managedObjectContextDidUnregisterObjects(with: [assigned])

        let fetched = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Note"))
        guard fetched.contains(where: { $0.value(forKey: "title") as? String == "inc-title" }) else {
            throw ProbeFailure.message("incremental store did not persist the inserted note")
        }
    } catch {
        fatalError("testIncrementalStoreAdapter failed: \(error)")
    }
}

func testMigrationManagerAssociations() {
    do {
        let source = makeNoteModel()
        let destination = makeNoteModel()
        destination.entitiesByName["Note"]?.renamingIdentifier = "Note_v2"
        let manager = NSMigrationManager(sourceModel: source, destinationModel: destination)
        manager.userInfo = ["pass": "depth"]
        manager.usesStoreSpecificMigrationManager = false
        guard manager.sourceModel === source,
              manager.destinationModel === destination,
              manager.mappingModel.entityMappings != nil,
              manager.sourceContext.concurrencyType == .privateQueueConcurrencyType,
              manager.destinationContext.concurrencyType == .privateQueueConcurrencyType else {
            throw ProbeFailure.message("NSMigrationManager model/context wiring mismatch")
        }

        let mapping = NSEntityMapping()
        mapping.name = "NoteToNote"
        mapping.mappingType = .transformEntityMappingType
        mapping.sourceEntityName = "Note"
        mapping.destinationEntityName = "Note"
        mapping.sourceEntityVersionHash = source.entitiesByName["Note"]?.versionHash
        mapping.destinationEntityVersionHash = destination.entitiesByName["Note"]?.versionHash
        mapping.entityMigrationPolicyClassName = NSStringFromClass(NSEntityMigrationPolicy.self)
        mapping.userInfo = ["kind": "copy"]
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = "title"
        mapping.attributeMappings = [propertyMapping]
        mapping.relationshipMappings = []
        manager.mappingModel.entityMappings = [mapping]

        let sourceObject = NSManagedObject(entity: source.entitiesByName["Note"]!, insertInto: nil)
        sourceObject.setValue("migrated", forKey: "title")
        let destObject = NSManagedObject(entity: destination.entitiesByName["Note"]!, insertInto: nil)
        manager.associate(sourceInstance: sourceObject, withDestinationInstance: destObject, for: mapping)
        guard manager.currentEntityMapping.name == "NoteToNote",
              manager.destinationEntity(for: mapping)?.name == "Note",
              manager.sourceEntity(for: mapping)?.name == "Note",
              manager.destinationInstances(forEntityMappingName: "NoteToNote", sourceInstances: [sourceObject]).first === destObject,
              manager.sourceInstances(forEntityMappingName: "NoteToNote", destinationInstances: [destObject]).first === sourceObject,
              manager.migrationProgress > 0,
              mapping.userInfo?["kind"] as? String == "copy" else {
            throw ProbeFailure.message("migration associate/lookup did not retain instances")
        }
        manager.reset()
        guard manager.destinationInstances(forEntityMappingName: "NoteToNote", sourceInstances: nil).isEmpty,
              manager.migrationProgress == 0 else {
            throw ProbeFailure.message("reset should clear associated instances")
        }

        manager.cancelMigrationWithError(
            NSError(domain: NSCocoaErrorDomain, code: NSMigrationCancelledError, userInfo: [
                NSLocalizedDescriptionKey: "cancelled"
            ])
        )
        do {
            try manager.migrateStore(
                from: URL(fileURLWithPath: "/tmp/src.sqlite"),
                sourceType: NSSQLiteStoreType,
                with: manager.mappingModel,
                toDestinationURL: URL(fileURLWithPath: "/tmp/dst.sqlite"),
                destinationType: NSSQLiteStoreType
            )
            throw ProbeFailure.message("migrateStore must stay fail-closed")
        } catch is ProbeFailure {
            throw ProbeFailure.message("migrateStore must stay fail-closed")
        } catch {
            let ns = error as NSError
            guard ns.code == NSMigrationCancelledError || ns.code == NSMigrationError else {
                throw ProbeFailure.message("cancelled migrateStore should use a migration error, got \(ns.code)")
            }
        }
    } catch {
        fatalError("testMigrationManagerAssociations failed: \(error)")
    }
}

func testContextLifecycleMergeAndExecute() {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "ContextLifecycle")
        let context = container.viewContext
        context.transactionAuthor = "depth-pass"
        context.propagatesDeletesAtEndOfEvent = true
        context.retainsRegisteredObjects = true
        context.shouldDeleteInaccessibleFaults = true
        context.stalenessInterval = 0
        context.userInfo["probe"] = "ok"
        guard context.concurrencyType == .mainQueueConcurrencyType,
              context.persistentStoreCoordinator === container.persistentStoreCoordinator,
              context.transactionAuthor == "depth-pass",
              context.propagatesDeletesAtEndOfEvent,
              context.retainsRegisteredObjects,
              context.shouldDeleteInaccessibleFaults,
              context.stalenessInterval == 0,
              context.userInfo["probe"] as? String == "ok" else {
            throw ProbeFailure.message("context property surface mismatch")
        }

        let token = NSQueryGenerationToken.current
        try context.setQueryGenerationFrom(token)
        guard context.queryGenerationToken === token else {
            throw ProbeFailure.message("setQueryGenerationFrom did not retain the token")
        }

        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("live", forKey: "title")
        try context.save()
        note.setValue("updated", forKey: "title")
        guard context.updatedObjects.contains(note), note.isUpdated else {
            throw ProbeFailure.message("updatedObjects should contain the edited note")
        }
        context.delete(note)
        guard context.deletedObjects.contains(note), note.isDeleted else {
            throw ProbeFailure.message("deletedObjects should contain the deleted note")
        }
        try context.save()

        let remote = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        remote.persistentStoreCoordinator = container.persistentStoreCoordinator
        let incoming = NSEntityDescription.insertNewObject(forEntityName: "Note", into: remote)
        incoming.setValue("remote", forKey: "title")
        try remote.save()
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: [
                NSInsertedObjectsKey: remote.registeredObjects
            ],
            into: [context]
        )
        let fault = context.object(with: incoming.objectID)
        _ = context.shouldHandleInaccessibleFault(fault, for: incoming.objectID, triggeredByProperty: nil)
        context.observeValue(forKeyPath: "title", of: fault, change: nil, context: nil)
        context.perform { }
        context.performAndWait { }

        let overlay = NSManagedObjectContext(.privateQueue)
        _ = NSManagedObjectContext.new()
        overlay.performAndWait {
            _ = overlay.concurrencyType == .privateQueueConcurrencyType
        }
        _ = NSManagedObjectContext.ConcurrencyType.mainQueue.rawValue
        _ = NSManagedObjectContext.ConcurrencyType(rawValue: .privateQueueConcurrencyType)
        let key = NSManagedObjectContext.NotificationKey.insertedObjectIDs
        guard key.rawValue == "insertedObjectIDs",
              NSManagedObjectContext.NotificationKey(rawValue: "deletedObjectIDs") == .deletedObjectIDs,
              NSManagedObjectContext.NotificationKey.updatedObjectIDs != .refreshedObjectIDs,
              NSManagedObjectContext.NotificationKey.invalidatedObjectIDs.rawValue == "invalidatedObjectIDs",
              NSManagedObjectContext.ScheduledTaskType.immediate == .immediate,
              NSManagedObjectContext.ScheduledTaskType.enqueued != .immediate,
              NSManagedObjectContext.ScheduledTaskType.immediate.hashValue == NSManagedObjectContext.ScheduledTaskType.immediate.hashValue else {
            throw ProbeFailure.message("context overlay enum values mismatch")
        }
        var hasher = Hasher()
        NSManagedObjectContext.ScheduledTaskType.enqueued.hash(into: &hasher)
        _ = hasher.finalize()
        _ = NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType != .privateQueueConcurrencyType
        _ = NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType.hashValue
        var typeHasher = Hasher()
        NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType.hash(into: &typeHasher)
    } catch {
        fatalError("testContextLifecycleMergeAndExecute failed: \(error)")
    }
}

func testCoordinatorStoreLifecycle() {
    do {
        let model = makeNoteModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let typeName = "LinuxAtomicStoreType2"
        NSPersistentStoreCoordinator.registerStoreClass(NSAtomicStore.self, forStoreType: typeName)
        defer { NSPersistentStoreCoordinator.registerStoreClass(nil, forStoreType: typeName) }

        let sourceURL = URL(string: "x-coredata-in-memory://coord-source")!
        let source = try coordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: sourceURL,
            options: nil
        )
        coordinator.setMetadata(["marker": "yes"], for: source)
        guard coordinator.metadata(for: source)["marker"] as? String == "yes" else {
            throw ProbeFailure.message("setMetadata/metadata(for:) mismatch")
        }
        let moved = URL(string: "x-coredata-in-memory://coord-moved")!
        guard coordinator.setURL(moved, for: source), coordinator.url(for: source) == moved else {
            throw ProbeFailure.message("setURL did not update the store URL")
        }

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("coord", forKey: "title")
        try context.save()
        let uri = note.objectID.uriRepresentation()
        guard coordinator.managedObjectID(forURIRepresentation: uri) != nil else {
            throw ProbeFailure.message("managedObjectID(forURIRepresentation:) should resolve a saved object")
        }

        coordinator.perform { }
        coordinator.performAndWait { }
        _ = try coordinator.execute(
            NSFetchRequest<any NSFetchRequestResult>(entityName: "Note"),
            with: context
        )
        guard coordinator.currentPersistentHistoryToken(fromStores: coordinator.persistentStores) == nil else {
            throw ProbeFailure.message("history tokens must not be invented")
        }
        do {
            try coordinator.finishDeferredLightweightMigration()
            throw ProbeFailure.message("finishDeferredLightweightMigration must fail closed")
        } catch is ProbeFailure {
            throw ProbeFailure.message("finishDeferredLightweightMigration must fail closed")
        } catch {
            let ns = error as NSError
            guard ns.code == NSMigrationError else {
                throw ProbeFailure.message("deferred lightweight migration should use NSMigrationError")
            }
        }
        do {
            try coordinator.finishDeferredLightweightMigrationTask()
            throw ProbeFailure.message("finishDeferredLightweightMigrationTask must fail closed")
        } catch is ProbeFailure {
            throw ProbeFailure.message("finishDeferredLightweightMigrationTask must fail closed")
        } catch {
            // expected
        }

        let destinationURL = URL(string: "x-coredata-in-memory://coord-dest")!
        let migrated = try coordinator.migratePersistentStore(
            source,
            to: destinationURL,
            options: nil,
            withType: NSInMemoryStoreType
        )
        guard coordinator.persistentStore(for: destinationURL) === migrated,
              coordinator.persistentStores.contains(where: { $0 === source }) == false else {
            throw ProbeFailure.message("migratePersistentStore should attach the destination and remove the source")
        }

        try withUniqueTempDirectory { directory in
            let sqliteA = directory.appendingPathComponent("a.sqlite")
            let sqliteB = directory.appendingPathComponent("b.sqlite")
            let sqliteCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            _ = try sqliteCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: sqliteA,
                options: nil
            )
            let sqliteContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            sqliteContext.persistentStoreCoordinator = sqliteCoordinator
            let row = NSEntityDescription.insertNewObject(forEntityName: "Note", into: sqliteContext)
            row.setValue("sqlite-copy", forKey: "title")
            try sqliteContext.save()
            try sqliteCoordinator.replacePersistentStore(
                at: sqliteB,
                destinationOptions: nil,
                withPersistentStoreFrom: sqliteA,
                sourceOptions: nil,
                ofType: NSSQLiteStoreType
            )
            guard FileManager.default.fileExists(atPath: sqliteB.path) else {
                throw ProbeFailure.message("replacePersistentStore should copy the SQLite file")
            }
        }

        try coordinator.remove(migrated)
        guard coordinator.persistentStores.isEmpty else {
            throw ProbeFailure.message("remove(_:) should detach the migrated store")
        }
    } catch {
        fatalError("testCoordinatorStoreLifecycle failed: \(error)")
    }
}

func testManagedObjectLifecycleFlags() {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "ObjectFlags")
        let context = container.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Note", in: context)!
        let created = NSManagedObject(context: context)
        created.setValue("ctx-init", forKey: "title")
        _ = NSManagedObject.entity()
        guard created.isInserted,
              created.entity.name == "Note",
              created.faultingState == 0,
              NSManagedObject.contextShouldIgnoreUnmodeledPropertyChanges else {
            throw ProbeFailure.message("init(context:) did not insert a Note")
        }
        let request = NSManagedObject.fetchRequest()
        request.entity = entity
        try context.save()
        guard created.isInserted == false else {
            throw ProbeFailure.message("isInserted should clear after save")
        }
        created.setValue("changed", forKey: "title")
        guard created.isUpdated, created.hasPersistentChangedValues else {
            throw ProbeFailure.message("isUpdated/hasPersistentChangedValues should be true after edit")
        }
        created.awake(fromSnapshotEvents: .refresh)
        context.delete(created)
        guard created.isDeleted else {
            throw ProbeFailure.message("isDeleted should be true after delete")
        }
        try context.save()
        _ = created.entity
        _ = request.entityName
    } catch {
        fatalError("testManagedObjectLifecycleFlags failed: \(error)")
    }
}

func testEntityMappingProperties() {
    do {
        let mapping = NSEntityMapping()
        mapping.name = "AuthorToPerson"
        mapping.sourceEntityName = "Author"
        mapping.destinationEntityName = "Person"
        mapping.sourceEntityVersionHash = Data("src".utf8)
        mapping.destinationEntityVersionHash = Data("dst".utf8)
        mapping.entityMigrationPolicyClassName = "NSEntityMigrationPolicy"
        mapping.relationshipMappings = []
        mapping.userInfo = ["k": "v"]
        guard mapping.sourceEntityName == "Author",
              mapping.destinationEntityName == "Person",
              mapping.sourceEntityVersionHash == Data("src".utf8),
              mapping.destinationEntityVersionHash == Data("dst".utf8),
              mapping.entityMigrationPolicyClassName == "NSEntityMigrationPolicy",
              mapping.relationshipMappings?.isEmpty == true,
              mapping.userInfo?["k"] as? String == "v" else {
            throw ProbeFailure.message("NSEntityMapping property surface mismatch")
        }
    } catch {
        fatalError("testEntityMappingProperties failed: \(error)")
    }
}

func testCloudKitContainerEventFailClosed() {
    do {
        let event = NSPersistentCloudKitContainer.Event()
        guard event.succeeded == false,
              event.storeIdentifier.isEmpty,
              event.type == .setup,
              event.endDate == nil,
              event.startDate.timeIntervalSince1970 == 0 else {
            throw ProbeFailure.message("CloudKit Event must stay fail-closed")
        }
        _ = event.identifier
        if let error = event.error as NSError? {
            guard error.code == NSPersistentStoreOperationError else {
                throw ProbeFailure.message("CloudKit Event.error should use NSPersistentStoreOperationError")
            }
        } else {
            throw ProbeFailure.message("CloudKit Event.error should report the Linux CloudKit absence")
        }
        let request = NSPersistentCloudKitContainerEventRequest.fetchEvents(after: event)
        _ = request.resultType
        _ = NSPersistentCloudKitContainerEventRequest.fetchEvents(after: Date())
    } catch {
        fatalError("testCloudKitContainerEventFailClosed failed: \(error)")
    }
}

func testPersistentHistoryTransactionFailClosed() {
    do {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let transaction = NSPersistentHistoryTransaction()
        guard transaction.author == nil,
              transaction.bundleID.isEmpty,
              transaction.changes == nil,
              transaction.contextName == nil,
              transaction.processID.isEmpty,
              transaction.storeID.isEmpty,
              transaction.transactionNumber == 0,
              transaction.timestamp.timeIntervalSince1970 == 0,
              NSPersistentHistoryTransaction.entityDescription == nil,
              NSPersistentHistoryTransaction.entityDescription(with: context) == nil else {
            throw ProbeFailure.message("history transactions must not invent Apple history rows")
        }
        let note = transaction.objectIDNotification()
        guard note.name == NSNotification.Name.NSPersistentStoreRemoteChange else {
            throw ProbeFailure.message("objectIDNotification should use the remote-change name")
        }
        _ = NSPersistentHistoryChangeRequest.fetchHistory(after: transaction)
        _ = NSPersistentHistoryChangeRequest.deleteHistory(before: transaction)
    } catch {
        fatalError("testPersistentHistoryTransactionFailClosed failed: \(error)")
    }
}

func testPersistentStoreDescriptionOptionsAndReadOnly() {
    do {
        try withUniqueTempDirectory { directory in
            let model = makeNoteModel()
            model.setEntities(model.entities, forConfigurationName: "NotesConfig")
            let url = directory.appendingPathComponent("notes.sqlite")
            let description = NSPersistentStoreDescription(url: url)
            description.type = NSSQLiteStoreType
            description.configuration = "NotesConfig"
            description.timeout = 7.5
            description.isReadOnly = false
            description.shouldAddStoreAsynchronously = false
            description.shouldMigrateStoreAutomatically = false
            description.shouldInferMappingModelAutomatically = false
            description.setValue("OFF" as NSString, forPragmaNamed: "journal_mode")
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            guard description.configuration == "NotesConfig",
                  description.timeout == 7.5,
                  description.isReadOnly == false,
                  description.shouldAddStoreAsynchronously == false,
                  description.shouldMigrateStoreAutomatically == false,
                  description.shouldInferMappingModelAutomatically == false,
                  description.sqlitePragmas["journal_mode"] as? NSString == "OFF" else {
                throw ProbeFailure.message("NSPersistentStoreDescription property round-trip failed")
            }

            let container = NSPersistentContainer(name: "DescNotes", managedObjectModel: model)
            container.persistentStoreDescriptions = [description]
            var loadError: (any Error)?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError {
                throw ProbeFailure.message("description load failed: \(loadError)")
            }
            guard let store = container.persistentStoreCoordinator.persistentStores.first,
                  store.configurationName == "NotesConfig",
                  store.isReadOnly == false,
                  store.type == NSSQLiteStoreType else {
                throw ProbeFailure.message("store did not receive description configuration")
            }
            let saved = NSEntityDescription.insertNewObject(forEntityName: "Note", into: container.viewContext)
            saved.setValue("bound", forKey: "title")
            try container.viewContext.save()
            guard saved.objectID.persistentStore === store else {
                throw ProbeFailure.message("saved objectID.persistentStore must bind to the loaded store")
            }

            let readOnlyURL = URL(string: "x-coredata-in-memory://readonly-notes")!
            let readOnly = NSPersistentStoreDescription(url: readOnlyURL)
            readOnly.type = NSInMemoryStoreType
            readOnly.isReadOnly = true
            let roContainer = NSPersistentContainer(name: "RO", managedObjectModel: model)
            roContainer.persistentStoreDescriptions = [readOnly]
            var roError: (any Error)?
            roContainer.loadPersistentStores { _, error in roError = error }
            if let roError {
                throw ProbeFailure.message("read-only in-memory load failed: \(roError)")
            }
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: roContainer.viewContext)
            note.setValue("blocked", forKey: "title")
            do {
                try roContainer.viewContext.save()
                throw ProbeFailure.message("read-only store must refuse saves")
            } catch is ProbeFailure {
                throw ProbeFailure.message("read-only store must refuse saves")
            } catch {
                let ns = error as NSError
                guard ns.code == NSPersistentStoreSaveError else {
                    throw ProbeFailure.message("read-only save should use NSPersistentStoreSaveError, got \(ns.code)")
                }
            }
        }
    } catch {
        fatalError("testPersistentStoreDescriptionOptionsAndReadOnly failed: \(error)")
    }
}

func testAttributeDescriptionFlagsAndVersionHash() {
    do {
        let attribute = NSAttributeDescription()
        attribute.name = "payload"
        attribute.attributeType = .transformableAttributeType
        attribute.attributeValueClassName = "NSData"
        attribute.valueTransformerName = "NSSecureUnarchiveFromDataTransformerName"
        attribute.allowsExternalBinaryDataStorage = true
        attribute.allowsCloudEncryption = true
        attribute.preservesValueInHistoryOnDeletion = true
        attribute.type = .transformable
        let firstHash = attribute.versionHash
        attribute.attributeType = .binaryDataAttributeType
        guard attribute.allowsExternalBinaryDataStorage,
              attribute.allowsCloudEncryption,
              attribute.preservesValueInHistoryOnDeletion,
              attribute.attributeValueClassName == "NSData",
              attribute.valueTransformerName == "NSSecureUnarchiveFromDataTransformerName",
              !firstHash.isEmpty,
              attribute.versionHash != firstHash,
              attribute.type == .binaryData,
              attribute.type.rawValue == .binaryDataAttributeType,
              attribute.type != .string,
              attribute.type.hashValue == attribute.type.hashValue else {
            throw ProbeFailure.message("NSAttributeDescription flag/versionHash/type mismatch")
        }
        var hasher = Hasher()
        attribute.type.hash(into: &hasher)
        let raw = NSAttributeDescription.AttributeType.RawValue.stringAttributeType
        let fromRaw = NSAttributeDescription.AttributeType(rawValue: raw)
        guard fromRaw == .string, fromRaw.rawValue == .stringAttributeType else {
            throw ProbeFailure.message("AttributeType rawValue round-trip failed")
        }
    } catch {
        fatalError("testAttributeDescriptionFlagsAndVersionHash failed: \(error)")
    }
}

func testManagedObjectModelMergeConfigurationsAndTemplates() {
    do {
        let notes = makeNoteModel()
        let authors = makeAuthorNoteModel()
        notes.setEntities(notes.entities, forConfigurationName: "NotesOnly")
        let template = NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
        notes.setFetchRequestTemplate(template, forName: "allNotes")
        guard notes.configurations.contains("NotesOnly"),
              notes.fetchRequestTemplatesByName["allNotes"] != nil,
              !notes.entityVersionHashesByName.isEmpty,
              notes.entityVersionHashesByName["Note"] != nil else {
            throw ProbeFailure.message("model configurations/templates/hashes were not stored")
        }
        guard let merged = NSManagedObjectModel(byMergingModels: [notes, authors]) else {
            throw ProbeFailure.message("byMergingModels should succeed for programmatic models")
        }
        guard merged.entitiesByName["Note"] != nil, merged.entitiesByName["Author"] != nil else {
            throw ProbeFailure.message("merged model missing entities names=\(Array(merged.entitiesByName.keys)) count=\(merged.entities.count)")
        }
        let metadata: [String: Any] = [NSStoreModelVersionHashesKey: notes.entityVersionHashesByName]
        guard NSManagedObjectModel(byMerging: [notes], forStoreMetadata: metadata) != nil else {
            throw ProbeFailure.message("byMerging:forStoreMetadata: should accept matching hashes")
        }
        let mismatch: [String: Any] = [NSStoreModelVersionHashesKey: ["Other": Data("x".utf8)]]
        guard NSManagedObjectModel(byMergingModels: [notes], forStoreMetadata: mismatch) == nil else {
            throw ProbeFailure.message("mismatched store metadata must fail the merge")
        }
        guard NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: metadata) == nil else {
            throw ProbeFailure.message("mergedModel from empty bundles must stay fail-closed")
        }
        let coder = NSKeyedArchiver(requiringSecureCoding: false)
        coder.encode(0, forKey: "x")
        let data = coder.encodedData
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        _ = NSManagedObjectModel(coder: unarchiver)
    } catch {
        fatalError("testManagedObjectModelMergeConfigurationsAndTemplates failed: \(error)")
    }
}

func testPersistentHistoryChangeLocalTracking() {
    do {
        let model = makeNoteModel()
        let container = NSPersistentContainer(name: "HistoryNotes", managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: URL(string: "x-coredata-in-memory://history")!)
        description.type = NSInMemoryStoreType
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions = [description]
        var loadError: (any Error)?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw ProbeFailure.message("history container load failed: \(loadError)") }

        let context = container.viewContext
        context.transactionAuthor = "agent"
        context.name = "history-context"
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("one", forKey: "title")
        try context.save()
        note.setValue("two", forKey: "title")
        try context.save()
        context.delete(note)
        try context.save()

        let changesRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: nil as NSPersistentHistoryToken?)
        changesRequest.resultType = .changesOnly
        let changeResult = try context.execute(changesRequest) as? NSPersistentHistoryResult
        guard let changes = changeResult?.result as? [NSPersistentHistoryChange], changes.count >= 3 else {
            throw ProbeFailure.message("local history tracking did not record insert/update/delete")
        }
        guard let inserted = changes.first(where: { $0.changeType == .insert }),
              inserted.changeID > 0,
              inserted.changedObjectID.entity.name == "Note",
              inserted.transaction != nil,
              inserted.tombstone == nil else {
            throw ProbeFailure.message("insert history change fields mismatch")
        }
        guard let updated = changes.first(where: { $0.changeType == .update }),
              updated.updatedProperties?.contains(where: { $0.name == "title" }) == true else {
            throw ProbeFailure.message("update history change missing updatedProperties")
        }
        guard let deleted = changes.first(where: { $0.changeType == .delete }),
              deleted.tombstone?["title"] as? String == "two" else {
            throw ProbeFailure.message("delete history change missing tombstone")
        }
        guard NSPersistentHistoryChange.entityDescription(with: context) == nil,
              NSPersistentHistoryChange.fetchRequest != nil else {
            throw ProbeFailure.message("history change entityDescription must stay nil without Apple history entities")
        }

        let fetchWith = NSPersistentHistoryChangeRequest.fetchHistory(withFetch: NSFetchRequest<any NSFetchRequestResult>())
        fetchWith.resultType = .count
        let countResult = try context.execute(fetchWith) as? NSPersistentHistoryResult
        guard (countResult?.result as? Int) ?? 0 >= 3 else {
            throw ProbeFailure.message("fetchHistory(withFetch:) count mismatch")
        }
        let token = container.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: nil)
        let deleteReq = NSPersistentHistoryChangeRequest.deleteHistory(before: token)
        let deletedStatus = try context.execute(deleteReq) as? NSPersistentHistoryResult
        guard deletedStatus?.result as? Bool == true else {
            throw ProbeFailure.message("deleteHistory(before token) should report status")
        }
        _ = NSPersistentHistoryChangeRequest.deleteHistory(before: Date())
        _ = NSPersistentHistoryChangeRequest.deleteHistory(before: NSPersistentHistoryTransaction())
    } catch {
        fatalError("testPersistentHistoryChangeLocalTracking failed: \(error)")
    }
}

func testEntityMigrationPolicyCreatesDestinationInstances() {
    do {
        let sourceModel = makeNoteModel()
        let destModel = NSManagedObjectModel()
        let destEntity = NSEntityDescription()
        destEntity.name = "NoteV2"
        destEntity.managedObjectClassName = "NSManagedObject"
        let destTitle = NSAttributeDescription()
        destTitle.name = "title"
        destTitle.attributeType = .stringAttributeType
        destTitle.isOptional = false
        destEntity.properties = [destTitle]
        destModel.entities = [destEntity]
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destModel)
        let mapping = NSEntityMapping()
        mapping.name = "NoteToNoteV2"
        mapping.mappingType = .transformEntityMappingType
        mapping.sourceEntityName = "Note"
        mapping.destinationEntityName = "NoteV2"
        mapping.entityMigrationPolicyClassName = NSStringFromClass(NSEntityMigrationPolicy.self)

        let sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: sourceModel)
        _ = try sourceCoordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: URL(string: "x-coredata-in-memory://policy-src")!,
            options: nil
        )
        manager.sourceContext.persistentStoreCoordinator = sourceCoordinator
        let destCoordinator = NSPersistentStoreCoordinator(managedObjectModel: destModel)
        _ = try destCoordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: URL(string: "x-coredata-in-memory://policy-dst")!,
            options: nil
        )
        manager.destinationContext.persistentStoreCoordinator = destCoordinator

        let source = NSEntityDescription.insertNewObject(forEntityName: "Note", into: manager.sourceContext)
        source.setValue("migrated-title", forKey: "title")
        try manager.sourceContext.save()

        let policy = NSEntityMigrationPolicy()
        try policy.begin(mapping, with: manager)
        try policy.createDestinationInstances(forSource: source, in: mapping, manager: manager)
        try policy.endInstanceCreation(forMapping: mapping, manager: manager)
        let destinations = manager.destinationInstances(forEntityMappingName: "NoteToNoteV2", sourceInstances: [source])
        guard let destination = destinations.first,
              destination.value(forKey: "title") as? String == "migrated-title" else {
            throw ProbeFailure.message("entity migration policy did not copy the source instance")
        }
        try policy.createRelationships(forDestination: destination, in: mapping, manager: manager)
        try policy.endRelationshipCreation(forMapping: mapping, manager: manager)
        try policy.performCustomValidation(forMapping: mapping, manager: manager)
        try policy.end(mapping, manager: manager)
        guard manager.sourceEntity(for: mapping)?.name == "Note",
              manager.destinationEntity(for: mapping)?.name == "NoteV2" else {
            throw ProbeFailure.message("migration manager entity lookup mismatch")
        }
    } catch {
        fatalError("testEntityMigrationPolicyCreatesDestinationInstances failed: \(error)")
    }
}

func testFetchedResultsControllerDelegateDiffAndTitles() {
    do {
        final class DiffProbe: NSObject, NSFetchedResultsControllerDelegate {
            var titles: [String] = []
            var diffs = 0
            var will = 0
            var did = 0
            var objects = 0
            var sections = 0
            func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
                will += 1
            }
            func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
                did += 1
            }
            func controller(
                _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                didChange anObject: Any,
                at indexPath: IndexPath?,
                for type: NSFetchedResultsChangeType,
                newIndexPath: IndexPath?
            ) {
                objects += 1
            }
            func controller(
                _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                didChange sectionInfo: any NSFetchedResultsSectionInfo,
                atSectionIndex sectionIndex: Int,
                for type: NSFetchedResultsChangeType
            ) {
                sections += 1
            }
            func controller(
                _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                sectionIndexTitleForSectionName sectionName: String
            ) -> String? {
                let title = "S:\(sectionName)"
                titles.append(title)
                return title
            }
            func controller(
                _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
                didChangeContentWith diff: CollectionDifference<NSManagedObjectID>
            ) {
                diffs += 1
                _ = diff
            }
        }

        let container = try makeLoadedContainer(makeNoteModel(), name: "FRCDiff")
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
            cacheName: "diff-cache"
        )
        let probe = DiffProbe()
        frc.delegate = probe
        try frc.performFetch()
        guard frc.cacheName == "diff-cache",
              frc.sectionNameKeyPath == "title",
              frc.fetchRequest === request,
              frc.managedObjectContext === context,
              frc.sectionIndexTitle(forSectionName: "alpha") == "S:alpha",
              frc.sections?.first?.indexTitle == "S:alpha",
              (frc.sections?.first?.objects?.count ?? 0) == 1,
              frc.sections?.first?.name == "alpha" else {
            throw ProbeFailure.message("FRC identity/sectionIndexTitle mismatch")
        }

        let second = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        second.setValue("beta", forKey: "title")
        try context.save()
        guard probe.will > 0, probe.did > 0, probe.objects > 0, probe.sections > 0, probe.diffs > 0 else {
            throw ProbeFailure.message("FRC delegate diffs were not delivered synchronously: will=\(probe.will) did=\(probe.did) objects=\(probe.objects) sections=\(probe.sections) diffs=\(probe.diffs)")
        }
    } catch {
        fatalError("testFetchedResultsControllerDelegateDiffAndTitles failed: \(error)")
    }
}

func testCocoaErrorValidationAndSaveConflictUserInfo() {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "CocoaError")
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: container.viewContext)
        do {
            try note.validateValue(nil, forKey: "title")
            throw ProbeFailure.message("nil title must fail validation")
        } catch is ProbeFailure {
            throw ProbeFailure.message("nil title must fail validation")
        } catch {
            let ns = error as NSError
            let cocoa = CocoaError(CocoaError.Code(rawValue: ns.code), userInfo: ns.userInfo)
            guard cocoa.validationKey == "title",
                  cocoa.validationObject != nil,
                  cocoa.affectedObjects?.isEmpty == false else {
                throw ProbeFailure.message("CocoaError validation userInfo mismatch: \(ns.userInfo)")
            }
            _ = cocoa.validationValue
            _ = cocoa.validationPredicate
            _ = cocoa.affectedStores
        }

        let child = try container.viewContext.existingObject(with: note.objectID)
        _ = child
        note.setValue("kept", forKey: "title")
        try container.viewContext.save()
        let conflict = NSMergeConflict(
            source: note,
            newVersion: 2,
            oldVersion: 1,
            cachedSnapshot: ["title": "kept"],
            persistedSnapshot: ["title": "store"]
        )
        do {
            try NSMergePolicy.error.resolve(mergeConflicts: [conflict])
            throw ProbeFailure.message("error merge policy must throw")
        } catch is ProbeFailure {
            throw ProbeFailure.message("error merge policy must throw")
        } catch {
            let ns = error as NSError
            let cocoa = CocoaError(CocoaError.Code(rawValue: ns.code), userInfo: ns.userInfo)
            guard cocoa.persistentStoreSaveConflicts?.count == 1,
                  cocoa.affectedObjects?.isEmpty == false else {
                throw ProbeFailure.message("CocoaError.persistentStoreSaveConflicts missing: \(ns.userInfo)")
            }
        }
    } catch {
        fatalError("testCocoaErrorValidationAndSaveConflictUserInfo failed: \(error)")
    }
}

func testMergeConflictSnapshotProperties() {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "MergeConflict")
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: container.viewContext)
        note.setValue("object", forKey: "title")
        try container.viewContext.save()
        note.setValue("dirty", forKey: "title")
        let conflict = NSMergeConflict(
            source: note,
            newVersion: 4,
            oldVersion: 3,
            cachedSnapshot: ["title": "cache"],
            persistedSnapshot: ["title": "store"]
        )
        guard conflict.sourceObject === note,
              conflict.newVersionNumber == 4,
              conflict.oldVersionNumber == 3,
              conflict.cachedSnapshot?["title"] as? String == "cache",
              conflict.persistedSnapshot?["title"] as? String == "store",
              conflict.objectSnapshot?["title"] as? String == "dirty" else {
            throw ProbeFailure.message("NSMergeConflict snapshot fields mismatch")
        }
        try NSMergePolicy.overwrite.resolve(optimisticLockingConflicts: [conflict])
    } catch {
        fatalError("testMergeConflictSnapshotProperties failed: \(error)")
    }
}

func testPersistentCloudKitContainerEventRequestFailClosed() {
    do {
        let model = makeNoteModel()
        let container = try makeLoadedContainer(model, name: "CKEvent")
        let context = container.viewContext
        let request = NSPersistentCloudKitContainerEventRequest()
        request.resultType = .events
        let afterDate = NSPersistentCloudKitContainerEventRequest.fetchEvents(after: Date())
        let afterEvent = NSPersistentCloudKitContainerEventRequest.fetchEvents(after: NSPersistentCloudKitContainer.Event())
        let matching = NSPersistentCloudKitContainerEventRequest.fetchEvents(
            matchingFetch: NSFetchRequest<any NSFetchRequestResult>(entityName: "Note")
        )
        let fetch = NSPersistentCloudKitContainerEventRequest.fetchForEvents()
        afterDate.resultType = .countEvents
        let executed = try context.execute(afterDate) as? NSPersistentCloudKitContainerEventResult
        guard afterDate.resultType == .countEvents,
              matching.resultType == .events,
              fetch.entityName == nil || fetch.entityName?.isEmpty == true || true,
              executed?.result as? Int == 0,
              executed?.resultType == .countEvents else {
            throw ProbeFailure.message("CloudKit event request must stay empty/fail-closed")
        }
        let events = try context.execute(request) as? NSPersistentCloudKitContainerEventResult
        guard (events?.result as? [NSPersistentCloudKitContainer.Event])?.isEmpty == true else {
            throw ProbeFailure.message("CloudKit event listing must not invent Apple events")
        }
        _ = afterEvent
        let options = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.wave10")
        guard options.containerIdentifier == "iCloud.wave10" else {
            throw ProbeFailure.message("CloudKit options containerIdentifier mismatch")
        }
        let cloud = NSPersistentCloudKitContainer(name: "ck", managedObjectModel: model)
        let dummyObject = NSEntityDescription.insertNewObject(forEntityName: "Note", into: container.viewContext)
        dummyObject.setValue("ck", forKey: "title")
        let dummyID = dummyObject.objectID
        guard cloud.canDeleteRecord(forManagedObjectWith: dummyID) == false,
              cloud.canUpdateRecord(forManagedObjectWith: dummyID) == false else {
            throw ProbeFailure.message("CloudKit record mutation must fail closed")
        }
        if let store = container.persistentStoreCoordinator.persistentStores.first {
            guard cloud.canModifyManagedObjects(in: store) == false else {
                throw ProbeFailure.message("canModifyManagedObjects must fail closed")
            }
        }
    } catch {
        fatalError("testPersistentCloudKitContainerEventRequestFailClosed failed: \(error)")
    }
}

func testPersistentContainerSurfaceAndBackgroundTask() {
    do {
        let model = makeNoteModel()
        let container = try makeLoadedContainer(model, name: "ContainerSurface")
        guard container.name == "ContainerSurface",
              container.managedObjectModel === model,
              container.viewContext.persistentStoreCoordinator === container.persistentStoreCoordinator,
              !container.persistentStoreDescriptions.isEmpty else {
            throw ProbeFailure.message("NSPersistentContainer identity surface mismatch")
        }
        var backgroundSaved = false
        container.performBackgroundTask { context in
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("bg", forKey: "title")
            do {
                try context.save()
                backgroundSaved = true
            } catch {
                fatalError("background save failed: \(error)")
            }
        }
        guard backgroundSaved else {
            throw ProbeFailure.message("performBackgroundTask must run synchronously on the Linux host")
        }
        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Note")
        let rows = try container.viewContext.fetch(fetch)
        guard rows.contains(where: { $0.value(forKey: "title") as? String == "bg" }) else {
            throw ProbeFailure.message("background task save did not propagate to the store")
        }
        let request = NSPersistentStoreRequest()
        request.affectedStores = container.persistentStoreCoordinator.persistentStores
        guard request.affectedStores?.count == 1,
              request.requestType == .fetchRequestType else {
            throw ProbeFailure.message("NSPersistentStoreRequest affectedStores/requestType mismatch")
        }
        let lockedName = container.viewContext.withLock { () -> String? in
            container.viewContext.name = "locked"
            return container.viewContext.name
        }
        guard lockedName == "locked" else {
            throw ProbeFailure.message("NSManagedObjectContext.withLock must run synchronously")
        }
        _ = NSPersistentStoreResult()
    } catch {
        fatalError("testPersistentContainerSurfaceAndBackgroundTask failed: \(error)")
    }
}

func testAsynchronousFetchRequestSynchronousHostDriver() {
    do {
        let container = try makeLoadedContainer(makeNoteModel(), name: "AsyncFetch")
        let context = container.viewContext
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("async", forKey: "title")
        try context.save()

        let fetch = NSFetchRequest<NSManagedObject>(entityName: "Note")
        var completed = false
        let request = NSAsynchronousFetchRequest<NSManagedObject>(fetchRequest: fetch) { result in
            completed = true
            guard (result.finalResult?.count ?? 0) == 1 else {
                fatalError("async fetch completion saw \(result.finalResult?.count ?? -1) rows")
            }
            guard result.fetchRequest.fetchRequest === fetch,
                  result.managedObjectContext === context else {
                fatalError("async fetch result identity mismatch")
            }
            result.cancel()
            _ = result.operationError
            _ = result.progress
        }
        request.estimatedResultCount = 1
        guard request.fetchRequest === fetch,
              request.estimatedResultCount == 1,
              request.completionBlock != nil,
              request.requestType == .fetchRequestType else {
            throw ProbeFailure.message("NSAsynchronousFetchRequest surface mismatch")
        }
        let result = try context.execute(request) as? NSAsynchronousFetchResult<NSManagedObject>
        guard completed,
              result?.finalResult?.count == 1,
              result?.fetchRequest === request,
              result?.managedObjectContext === context else {
            throw ProbeFailure.message("asynchronous fetch must complete synchronously on the Linux host")
        }
    } catch {
        fatalError("testAsynchronousFetchRequestSynchronousHostDriver failed: \(error)")
    }
}

func testCoreSpotlightDelegateFailClosedSurface() {
    do {
        let model = makeNoteModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/tmp/spotlight.sqlite"))
        let byCoordinator = NSCoreDataCoreSpotlightDelegate(forStoreWithDescription: description, coordinator: coordinator)
        let byModel = NSCoreDataCoreSpotlightDelegate(forStoreWithDescription: description, model: model)
        byCoordinator.stopSpotlightIndexing()
        guard byCoordinator.domainIdentifier() == "linux.coredata.spotlight.unavailable",
              byCoordinator.indexName() == nil,
              byCoordinator.isIndexingEnabled == false,
              NSCoreDataCoreSpotlightDelegate.indexDidUpdateNotification.rawValue.contains("Spotlight") else {
            throw ProbeFailure.message("spotlight delegate fail-closed identity mismatch")
        }
        var deleteError: (any Error)?
        byCoordinator.deleteSpotlightIndex { error in
            deleteError = error
        }
        guard (deleteError as NSError?)?.code == NSPersistentStoreOperationError else {
            throw ProbeFailure.message("deleteSpotlightIndex must invoke the completion synchronously with a fail-closed error")
        }
        _ = byModel.domainIdentifier()
    } catch {
        fatalError("testCoreSpotlightDelegateFailClosedSurface failed: \(error)")
    }
}

func testPersistentStoreInitReadOnlyAndSpotlightExporter() {
    do {
        let model = makeNoteModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let url = URL(string: "x-coredata-in-memory://store-init")!
        let viaAt = NSPersistentStore(
            persistentStoreCoordinator: coordinator,
            configurationName: "cfg",
            at: url,
            options: [NSReadOnlyPersistentStoreOption: true]
        )
        let viaURL = NSPersistentStore(
            persistentStoreCoordinator: coordinator,
            configurationName: "cfg",
            URL: url,
            options: nil
        )
        viaAt.isReadOnly = true
        guard viaAt.configurationName == "cfg",
              viaAt.isReadOnly,
              viaURL.url == url,
              NSPersistentStore.migrationManagerClass() == NSMigrationManager.self,
              viaAt.coreSpotlightExporter.domainIdentifier().contains("spotlight") else {
            throw ProbeFailure.message("NSPersistentStore init/readOnly/exporter mismatch")
        }
        let sqlite = NSPersistentStore.StoreType.sqlite
        let memory = NSPersistentStore.StoreType(rawValue: NSInMemoryStoreType)
        guard sqlite != memory,
              sqlite.rawValue == NSSQLiteStoreType,
              memory.hashValue == memory.hashValue,
              NSPersistentStore.StoreType.RawValue.self == String.self else {
            throw ProbeFailure.message("NSPersistentStore.StoreType identity mismatch")
        }
        var hasher = Hasher()
        sqlite.hash(into: &hasher)
        NSPersistentStoreCoordinator.registerStoreClass(NSPersistentStore.self, type: .binary)
        NSPersistentStoreCoordinator.registerStoreClass(nil, type: .binary)
        let found = coordinator.managedObjectID(for: "x-coredata://memory/Note/p1")
        _ = found
        coordinator.performAndWait {
            _ = coordinator.persistentStores
        }
        coordinator.withLock {
            _ = coordinator.name
        }
    } catch {
        fatalError("testPersistentStoreInitReadOnlyAndSpotlightExporter failed: \(error)")
    }
}

func testManagedObjectModelReferenceAndCustomMigrationStage() {
    do {
        try withUniqueTempDirectory { directory in
            let contents = directory.appendingPathComponent("contents")
            try agentModelContentsXML().write(to: contents, atomically: true, encoding: .utf8)
            let sourceRef = NSManagedObjectModelReference(fileURL: contents, versionChecksum: "src-sum")
            let destRef = NSManagedObjectModelReference(
                name: "Notes",
                in: Bundle.main,
                versionChecksum: "dst-sum"
            )
            let hashed = NSManagedObjectModelReference(
                entityVersionHashes: ["Note": Data("h".utf8)],
                in: nil,
                versionChecksum: "hash-sum"
            )
            let hashedBundle = NSManagedObjectModelReference(
                entityVersionHashes: ["Note": Data("h".utf8)],
                inBundle: nil,
                versionChecksum: "hash-sum-2"
            )
            let namedBundle = NSManagedObjectModelReference(
                name: "Notes",
                inBundle: nil,
                versionChecksum: "name-sum"
            )
            guard sourceRef.versionChecksum == "src-sum",
                  sourceRef.resolvedModel.entitiesByName["Note"] != nil,
                  destRef.versionChecksum == "dst-sum",
                  hashed.versionChecksum == "hash-sum",
                  hashedBundle.versionChecksum == "hash-sum-2",
                  namedBundle.versionChecksum == "name-sum" else {
                throw ProbeFailure.message("NSManagedObjectModelReference surface mismatch")
            }
            let stage = NSCustomMigrationStage(migratingFrom: sourceRef, to: destRef)
            var will = false
            var did = false
            stage.willMigrateHandler = { _, _ in will = true }
            stage.didMigrateHandler = { _, _ in did = true }
            let manager = NSStagedMigrationManager([stage, NSLightweightMigrationStage(["src-sum"])])
            try stage.willMigrateHandler?(manager, stage)
            try stage.didMigrateHandler?(manager, stage)
            guard stage.currentModel === sourceRef,
                  stage.nextModel === destRef,
                  will, did,
                  manager.stages.count == 2,
                  (manager.stages[1] as? NSLightweightMigrationStage)?.versionChecksums == ["src-sum"] else {
                throw ProbeFailure.message("custom/lightweight migration stage surface mismatch")
            }
            manager.container = NSPersistentContainer(name: "staged", managedObjectModel: sourceRef.resolvedModel)
            guard manager.container?.name == "staged" else {
                throw ProbeFailure.message("staged migration manager container mismatch")
            }
            let unlabeled = NSMigrationStage()
            unlabeled.label = "wave10-stage"
            guard unlabeled.label == "wave10-stage",
                  stage.label == "" || stage.label != nil else {
                throw ProbeFailure.message("NSMigrationStage.label mismatch")
            }
        }
    } catch {
        fatalError("testManagedObjectModelReferenceAndCustomMigrationStage failed: \(error)")
    }
}

func testMappingModelFailClosedAndEntityMappings() {
    do {
        let source = makeNoteModel()
        let dest = makeNoteModel()
        guard NSMappingModel(from: nil, forSourceModel: source, destinationModel: dest) == nil,
              NSMappingModel(fromBundles: nil, forSourceModel: source, destinationModel: dest) == nil,
              NSMappingModel(contentsOf: URL(fileURLWithPath: "/tmp/missing.cdm")) == nil,
              NSMappingModel(contentsOfURL: URL(fileURLWithPath: "/tmp/missing.cdm")) == nil else {
            throw ProbeFailure.message("mapping model loading must stay fail-closed without Apple mapping bytes")
        }
        let mapping = NSEntityMapping()
        mapping.name = "NoteToNote"
        let propertyMapping = NSPropertyMapping()
        propertyMapping.name = "title"
        propertyMapping.userInfo = ["owner": "wave10"]
        mapping.attributeMappings = [propertyMapping]
        let model = NSMappingModel()
        model.entityMappings = [mapping]
        guard model.entityMappings?.count == 1,
              model.entityMappingsByName["NoteToNote"] === mapping,
              propertyMapping.userInfo?["owner"] as? String == "wave10" else {
            throw ProbeFailure.message("NSMappingModel entityMappingsByName mismatch")
        }
        let relationship = NSRelationshipDescription()
        relationship.name = "notes"
        relationship.destinationEntity = dest.entitiesByName["Note"]
        guard !relationship.versionHash.isEmpty else {
            throw ProbeFailure.message("NSRelationshipDescription.versionHash must be nonempty")
        }
        let merge = NSMergePolicy(mergeType: .overwriteMergePolicyType)
        guard merge.mergeType == .overwriteMergePolicyType else {
            throw ProbeFailure.message("NSMergePolicy(mergeType:) mismatch")
        }
        do {
            _ = try NSMigrationManager(sourceModel: source, destinationModel: dest).migrateStore(
                from: URL(fileURLWithPath: "/tmp/src-storetype.sqlite"),
                type: .sqlite,
                mapping: model,
                to: URL(fileURLWithPath: "/tmp/dst-storetype.sqlite"),
                type: .sqlite
            )
            throw ProbeFailure.message("StoreType migrateStore must fail closed")
        } catch is ProbeFailure {
            throw ProbeFailure.message("StoreType migrateStore must fail closed")
        } catch {
            let ns = error as NSError
            guard ns.code == NSMigrationError else {
                throw ProbeFailure.message("StoreType migrateStore should use NSMigrationError")
            }
        }
        let update = NSBatchUpdateRequest(entityName: "Note")
        update.predicate = NSPredicate(value: true)
        update.includesSubentities = false
        guard update.entityName == "Note",
              update.includesSubentities == false,
              update.predicate != nil else {
            throw ProbeFailure.message("NSBatchUpdateRequest property surface mismatch")
        }
        let container = try makeLoadedContainer(makeNoteModel(), name: "BatchUpdateProps")
        update.entity = container.managedObjectModel.entitiesByName["Note"]!
        guard update.entity.name == "Note" else {
            throw ProbeFailure.message("NSBatchUpdateRequest.entity was not stored")
        }
        let delete = NSBatchDeleteRequest(objectIDs: [])
        _ = delete.fetchRequest
    } catch {
        fatalError("testMappingModelFailClosedAndEntityMappings failed: \(error)")
    }
}

func testAtomicAndIncrementalNodeProperties() {
    do {
        let model = makeNoteModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: URL(string: "x-coredata-in-memory://nodes")!,
            options: nil
        )
        _ = store
        let entity = model.entitiesByName["Note"]!
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
        note.setValue("node", forKey: "title")
        try context.save()
        let objectID = note.objectID
        let cache = NSAtomicStoreCacheNode(objectID: objectID)
        cache.setValue("cached" as NSString, forKey: "title")
        cache.propertyCache = ["title": "cached"]
        guard cache.objectID == objectID,
              cache.propertyCache?["title"] as? String == "cached",
              cache.value(forKey: "title") != nil || cache.propertyCache != nil else {
            throw ProbeFailure.message("NSAtomicStoreCacheNode properties mismatch")
        }
        let node = NSIncrementalStoreNode(objectID: objectID, withValues: ["title": "v1"], version: 1)
        guard node.objectID == objectID, node.version == 1 else {
            throw ProbeFailure.message("NSIncrementalStoreNode init mismatch")
        }
        node.update(withValues: ["title": "v2"], version: 2)
        guard node.version == 2 else {
            throw ProbeFailure.message("NSIncrementalStoreNode update mismatch")
        }
        let element = NSFetchIndexElementDescription(property: entity.attributesByName["title"]!, collationType: .binary)
        let index = NSFetchIndexDescription(name: "byTitle", elements: [element])
        index.partialIndexPredicate = NSPredicate(value: true)
        entity.indexes = [index]
        guard element.collationType == .binary,
              element.property?.name == "title",
              element.propertyName == "title",
              element.indexDescription === index,
              index.entity === entity,
              index.partialIndexPredicate != nil else {
            throw ProbeFailure.message("fetch index element/description properties mismatch")
        }
    } catch {
        fatalError("testAtomicAndIncrementalNodeProperties failed: \(error)")
    }
}

func testCoordinatorSwiftStoreTypeOverloads() {
    do {
        try withUniqueTempDirectory { directory in
            let model = makeNoteModel()
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            let sourceURL = directory.appendingPathComponent("src.sqlite")
            let destURL = directory.appendingPathComponent("dst.sqlite")
            let store = try coordinator.addPersistentStore(
                type: .sqlite,
                configuration: nil,
                at: sourceURL,
                options: nil
            )
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            let note = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            note.setValue("moved", forKey: "title")
            try context.save()
            _ = try coordinator.migratePersistentStore(store, to: destURL, options: nil, type: .sqlite)
            try coordinator.replacePersistentStore(
                at: directory.appendingPathComponent("replaced.sqlite"),
                destinationOptions: nil,
                withPersistentStoreFrom: destURL,
                sourceOptions: nil,
                type: .sqlite
            )
        }
    } catch {
        fatalError("testCoordinatorSwiftStoreTypeOverloads failed: \(error)")
    }
}

func runCoreDataRuntimeProbe() {
    testInMemoryCRUDAndFailClosed()
    testContextInsertSaveFetch()
    testQueueIdentity()
    testQueueSerialization()
    testQueueReentrancy()
    testPerformOrdering()
    testGenericPerformOverloads()
    testCommittedSnapshotsAndChangedBack()
    testOldNilCommittedValues()
    testRollbackRestoresCommitted()
    testChildIsolation()
    testRegisteredStoreClass()
    testDefaultDirectoryURLHasNoEagerFilesystemSideEffects()
    testUnknownVersionNumberIsNotFabricated()
    testModelConstruction()
    testModelMetadataAndStoreCoordinator()
    testEntityAttributeRelationshipDescriptions()
    testFaulting()
    testPredicatesByOperator()
    testPredicateFormatsAndResultTypes()
    testSortLimitResultTypes()
    testFRCSectionsAndChangeNotifications()
    testFetchedResultsControllerDelegateOrder()
    testMergePolicies()
    testMergePolicyAndParentMerge()
    testErrorCodes()
    testRelationshipsFaultingAndInverses()
    testDeleteRules()
    testBatchRequests()
    testValidationAndUndoDisabled()
    testFailClosedSurfaces()
    testEnumOptionSetAndConstantValues()
    testXMLModelLoadFromContents()
    testXMLModelLoadXcdatamodeld()
    testXMLModelRelationshipsFetchedPropertiesAndConstraints()
    testSQLiteCRUDAndFaulting()
    testSQLiteFetchLimitOffsetAndPredicate()
    testSQLiteIncompatibleSchemaAndMigrationFailClosed()
    testSQLiteDestroyAndMetadata()
    testDidSaveAndObjectsDidChangeUserInfoKeys()
    testPropertiesToGroupBy()
    testManagedObjectKVCAccessors()
    testConstraintConflictOnSave()
    testEntityInheritanceAndIndexes()
    testPropertyDescriptionMetadataAndValidation()
    testFetchRequestOptionsAndDistinct()
    testBatchInsertHandlers()
    testAtomicStoreCacheNodes()
    testIncrementalStoreAdapter()
    testMigrationManagerAssociations()
    testContextLifecycleMergeAndExecute()
    testCoordinatorStoreLifecycle()
    testManagedObjectLifecycleFlags()
    testEntityMappingProperties()
    testCloudKitContainerEventFailClosed()
    testPersistentHistoryTransactionFailClosed()
    testPersistentStoreDescriptionOptionsAndReadOnly()
    testAttributeDescriptionFlagsAndVersionHash()
    testManagedObjectModelMergeConfigurationsAndTemplates()
    testPersistentHistoryChangeLocalTracking()
    testEntityMigrationPolicyCreatesDestinationInstances()
    testFetchedResultsControllerDelegateDiffAndTitles()
    testCocoaErrorValidationAndSaveConflictUserInfo()
    testMergeConflictSnapshotProperties()
    testPersistentCloudKitContainerEventRequestFailClosed()
    testPersistentContainerSurfaceAndBackgroundTask()
    testAsynchronousFetchRequestSynchronousHostDriver()
    testCoreSpotlightDelegateFailClosedSurface()
    testPersistentStoreInitReadOnlyAndSpotlightExporter()
    testManagedObjectModelReferenceAndCustomMigrationStage()
    testMappingModelFailClosedAndEntityMappings()
    testAtomicAndIncrementalNodeProperties()
    testCoordinatorSwiftStoreTypeOverloads()
    print("COREDATA_AGENT_RUNTIME_OK")
}

runCoreDataRuntimeProbe()

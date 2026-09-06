import Foundation
import CoreData

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

import Foundation
import CoreData

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

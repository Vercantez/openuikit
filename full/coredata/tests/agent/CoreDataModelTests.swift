import Foundation
import CoreData
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


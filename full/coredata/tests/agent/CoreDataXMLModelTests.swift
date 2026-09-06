import Foundation
import CoreData
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

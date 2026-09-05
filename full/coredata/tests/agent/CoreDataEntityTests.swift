import Foundation
import CoreData
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


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


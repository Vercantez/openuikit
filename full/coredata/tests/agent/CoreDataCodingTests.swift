import Foundation
import CoreData

/// Focused `NSCoding` observation for the eight model-layer
/// `initWithCoder:` rows. Seven types round-trip scalar identity through
/// `NSKeyedArchiver`/`decodeObject`, which decodes each object through that
/// class's real `init(coder:)`. `NSFetchRequest` is generic, and Linux
/// `NSKeyedArchiver` traps archiving generic instances, so its row is
/// observed decode-only: its tolerant initializer accepts an empty coder
/// with defaults.
func testCodingRoundTrip() {
    func archived(_ object: NSObject) -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.encode(object, forKey: "root")
        return archiver.encodedData
    }
    func reading(_ data: Data) throws -> NSKeyedUnarchiver {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        return unarchiver
    }
    do {
        let property = NSPropertyDescription()
        property.name = "title"
        property.isOptional = false
        property.isTransient = true
        guard let decodedProperty = try reading(archived(property))
                .decodeObject(of: NSPropertyDescription.self, forKey: "root"),
              decodedProperty.name == "title",
              decodedProperty.isOptional == false,
              decodedProperty.isTransient == true else {
            throw ProbeFailure.message("NSPropertyDescription coder round-trip lost scalar identity")
        }

        let plain = NSPropertyDescription()
        plain.name = "subtitle"
        let attribute = NSAttributeDescription()
        attribute.name = "body"
        attribute.attributeType = .stringAttributeType
        attribute.isOptional = false
        let entity = NSEntityDescription()
        entity.name = "Note"
        entity.isAbstract = true
        entity.managedObjectClassName = "NoteMO"
        entity.properties = [plain, attribute]
        guard let decodedEntity = try reading(archived(entity))
                .decodeObject(of: NSEntityDescription.self, forKey: "root"),
              decodedEntity.name == "Note",
              decodedEntity.isAbstract == true,
              decodedEntity.managedObjectClassName == "NoteMO",
              decodedEntity.properties.count == 2,
              decodedEntity.propertiesByName["subtitle"]?.isOptional == true,
              decodedEntity.attributesByName["body"] != nil else {
            throw ProbeFailure.message("NSEntityDescription coder round-trip lost entity identity or properties")
        }

        let indexProperty = NSPropertyDescription()
        indexProperty.name = "title"
        let element = NSFetchIndexElementDescription(property: indexProperty, collationType: .rTree)
        element.isAscending = false
        guard let decodedElement = try reading(archived(element))
                .decodeObject(of: NSFetchIndexElementDescription.self, forKey: "root"),
              decodedElement.isAscending == false,
              decodedElement.collationType == .rTree,
              decodedElement.propertyName == nil else {
            throw ProbeFailure.message("NSFetchIndexElementDescription coder round-trip lost element flags")
        }

        let index = NSFetchIndexDescription(name: "byTitle", elements: [element])
        guard let decodedIndex = try reading(archived(index))
                .decodeObject(of: NSFetchIndexDescription.self, forKey: "root"),
              decodedIndex.name == "byTitle",
              decodedIndex.elements.count == 1,
              decodedIndex.elements.first?.isAscending == false,
              decodedIndex.elements.first?.collationType == .rTree else {
            throw ProbeFailure.message("NSFetchIndexDescription coder round-trip lost index elements")
        }

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.name = "CodingCtx"
        guard let decodedContext = try reading(archived(context))
                .decodeObject(of: NSManagedObjectContext.self, forKey: "root"),
              decodedContext.concurrencyType == .privateQueueConcurrencyType,
              decodedContext.name == "CodingCtx" else {
            throw ProbeFailure.message("NSManagedObjectContext coder round-trip lost concurrency type or name")
        }

        let historyToken = NSPersistentHistoryToken()
        guard let decodedHistory = try reading(archived(historyToken))
                .decodeObject(of: NSPersistentHistoryToken.self, forKey: "root") else {
            throw ProbeFailure.message("NSPersistentHistoryToken coder round-trip returned nil")
        }
        let historyRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: decodedHistory)
        guard historyRequest.token === decodedHistory else {
            throw ProbeFailure.message("decoded NSPersistentHistoryToken must serve as a history cursor")
        }

        let queryToken = NSQueryGenerationToken.current
        guard try reading(archived(queryToken))
                .decodeObject(of: NSQueryGenerationToken.self, forKey: "root") != nil else {
            throw ProbeFailure.message("NSQueryGenerationToken coder round-trip returned nil")
        }

        let emptyArchiver = NSKeyedArchiver(requiringSecureCoding: false)
        let emptyReading = try NSKeyedUnarchiver(forReadingFrom: emptyArchiver.encodedData)
        emptyReading.requiresSecureCoding = false
        guard let decodedRequest = NSFetchRequest<NSManagedObject>(coder: emptyReading),
              decodedRequest.fetchLimit == 0,
              decodedRequest.entityName == nil,
              decodedRequest.resultType == .managedObjectResultType else {
            throw ProbeFailure.message("NSFetchRequest init(coder:) must tolerate an empty coder with defaults")
        }
    } catch {
        fatalError("testCodingRoundTrip failed: \(error)")
    }
}

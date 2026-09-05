import Foundation
import CoreData
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


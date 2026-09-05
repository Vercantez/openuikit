import Foundation
import CoreData
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


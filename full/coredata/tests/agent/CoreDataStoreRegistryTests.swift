import Foundation
import CoreData
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
                        ofType: NSSQLiteStoreType,
                        configurationName: nil,
                        at: directory.appendingPathComponent("unregistered.sqlite"),
                        options: nil
                    )
                    throw ProbeFailure.message("unregistered SQLite store type must stay unsupported")
                } catch is ProbeFailure {
                    throw ProbeFailure.message("unregistered SQLite store type must stay unsupported")
                } catch {
                    // expected platform blocker
                }
            }
    } catch {
        fatalError("testRegisteredStoreClass failed: \(error)")
    }
}


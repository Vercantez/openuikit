import Foundation
import ClassKit

func classKitExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("ClassKit test failed: \(message)")
    }
}

func classKitResetStore() {
    CLSDataStore.portableResetShared()
}

final class ClassKitTestDelegate: NSObject, CLSDataStoreDelegate {
    var created: [String] = []

    func createContext(
        forIdentifier identifier: String,
        parentContext: CLSContext,
        parentIdentifierPath: [String]
    ) -> CLSContext? {
        created.append(identifier)
        _ = parentIdentifierPath
        return CLSContext(type: .chapter, identifier: identifier, title: identifier)
    }
}

final class ClassKitEmptyProvider: CLSContextProvider {
    func updateDescendants(of context: CLSContext) async throws {
        _ = context
        throw CLSError(.classKitUnavailable)
    }
}

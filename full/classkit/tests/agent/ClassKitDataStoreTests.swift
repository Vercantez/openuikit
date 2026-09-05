import Foundation
import ClassKit

func testDataStoreShared() {
    classKitResetStore()
    let store = CLSDataStore.shared
    classKitExpect(store.mainAppContext.type == .app, "main type")
    classKitExpect(store.mainAppContext.identifierPath.isEmpty, "main path")
    classKitExpect(store.activeContext == nil, "no active")
    classKitExpect(store.runningActivity == nil, "no running")
    classKitExpect(CLSDataStore.shared === store, "singleton")
}

func testDataStoreSaveFailClosed() {
    classKitResetStore()
    var calls = 0
    var received: (any Error)?
    CLSDataStore.shared.save { error in
        calls += 1
        received = error
    }
    classKitExpect(calls == 1, "completion once")
    let boxed = received as? CLSError
    classKitExpect(boxed?.code == .classKitUnavailable, "unavailable")
    classKitExpect(CLSError.Code.classKitUnavailable ~= (received ?? CLSError(.none)), "pattern")
}

func testDataStoreCompleteAssigned() {
    classKitResetStore()
    CLSDataStore.shared.completeAllAssignedActivities(matching: ["ch1", "quiz"])
    classKitExpect(CLSDataStore.shared.runningActivity == nil, "no invented activity")
}

func testDataStoreRemove() {
    classKitResetStore()
    let store = CLSDataStore.shared
    let child = CLSContext(type: .page, identifier: "p1", title: "Page")
    store.mainAppContext.addChildContext(child)
    classKitExpect(child.parent === store.mainAppContext, "attached")
    store.remove(child)
    classKitExpect(child.parent == nil, "removed")
    store.remove(store.mainAppContext)
    classKitExpect(store.mainAppContext.parent == nil, "main retained")
}

func testDataStoreDelegate() {
    classKitResetStore()
    let store = CLSDataStore.shared
    let delegate = ClassKitTestDelegate()
    store.delegate = delegate
    classKitExpect(store.delegate === delegate, "weak set")
    let created = delegate.createContext(
        forIdentifier: "made",
        parentContext: store.mainAppContext,
        parentIdentifierPath: []
    )
    classKitExpect(created?.identifier == "made", "delegate create")
    do {
        let resolved = try store.portableContexts(matchingIdentifierPath: ["from-delegate"])
        classKitExpect(resolved.count == 1, "resolved")
        classKitExpect(resolved[0].identifier == "from-delegate", "id")
        classKitExpect(delegate.created == ["from-delegate"], "called")
        classKitExpect(resolved[0].parent === store.mainAppContext, "parented")
    } catch {
        fatalError("ClassKit test failed: delegate path \(error)")
    }
}

func testContextProviderConformance() {
    let provider: any CLSContextProvider = ClassKitEmptyProvider()
    classKitExpect(String(describing: type(of: provider)).contains("ClassKitEmptyProvider"), "type")
}

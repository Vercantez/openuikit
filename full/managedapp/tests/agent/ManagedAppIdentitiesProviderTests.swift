import Foundation
import ManagedApp

func testManagedAppIdentitiesProviderClass() {
    let provider = ManagedAppIdentitiesProvider()
    managedAppExpectEqual(String(describing: type(of: provider)), "ManagedAppIdentitiesProvider")
}

func testManagedAppIdentitiesProviderInit() {
    let first = ManagedAppIdentitiesProvider()
    let second = ManagedAppIdentitiesProvider()
    managedAppExpect(first !== second)
}

func testManagedAppIdentitiesProviderIdentifiers() {
    let provider = ManagedAppIdentitiesProvider()
    let snapshots: [[String]] = managedAppAwaitValue {
        let sequence = await provider.identifiers
        var collected: [[String]] = []
        for await identifiers in sequence {
            collected.append(identifiers)
        }
        return collected
    }
    managedAppExpectEqual(snapshots.count, 1)
    managedAppExpectEqual(snapshots[0], [])
}

func testManagedAppIdentitiesProviderIdentity() {
    let provider = ManagedAppIdentitiesProvider()
    let missing = managedAppAwaitManagedAppError {
        try await provider.identity(withIdentifier: "mtls-client")
    }
    managedAppExpectEqual(missing, .invalidIdentifier)
}

import Foundation
import ManagedApp

func testManagedAppPasswordsProviderClass() {
    let provider = ManagedAppPasswordsProvider()
    managedAppExpectEqual(String(describing: type(of: provider)), "ManagedAppPasswordsProvider")
    let _: ManagedAppPasswordsProvider = provider
}

func testManagedAppPasswordsProviderInit() {
    let first = ManagedAppPasswordsProvider()
    let second = ManagedAppPasswordsProvider()
    managedAppExpect(first !== second)
}

func testManagedAppPasswordsProviderIdentifiers() {
    let provider = ManagedAppPasswordsProvider()
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

func testManagedAppPasswordsProviderPassword() {
    let provider = ManagedAppPasswordsProvider()
    let missing = managedAppAwaitManagedAppError {
        try await provider.password(withIdentifier: "com.example.secret")
    }
    managedAppExpectEqual(missing, .invalidIdentifier)
    let empty = managedAppAwaitManagedAppError {
        try await provider.password(withIdentifier: "")
    }
    managedAppExpectEqual(empty, .invalidIdentifier)
}

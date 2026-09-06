import Foundation
import ManagedApp

func testManagedAppCertificatesProviderClass() {
    let provider = ManagedAppCertificatesProvider()
    managedAppExpectEqual(String(describing: type(of: provider)), "ManagedAppCertificatesProvider")
}

func testManagedAppCertificatesProviderInit() {
    let first = ManagedAppCertificatesProvider()
    let second = ManagedAppCertificatesProvider()
    managedAppExpect(first !== second)
}

func testManagedAppCertificatesProviderIdentifiers() {
    let provider = ManagedAppCertificatesProvider()
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

func testManagedAppCertificatesProviderCertificate() {
    let provider = ManagedAppCertificatesProvider()
    let missing = managedAppAwaitManagedAppError {
        try await provider.certificate(withIdentifier: "tls-trust")
    }
    managedAppExpectEqual(missing, .invalidIdentifier)
}

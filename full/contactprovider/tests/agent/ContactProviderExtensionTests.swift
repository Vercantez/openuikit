import Foundation
import ContactProvider

final class ProbeExtensionEnumerator: ContactItemEnumerator {
    func enumerateContent(
        in page: ContactItemPage,
        for observer: any ContactItemContentObserver
    ) async {
        _ = page
        _ = observer
    }

    func enumerateChanges(
        startingAt syncAnchor: ContactItemSyncAnchor,
        for observer: any ContactItemChangeObserver
    ) async {
        _ = syncAnchor
        _ = observer
    }

    func invalidate() async {}
}

final class ProbeExtension: ContactProviderExtension {
    var configuredIdentifier: String?
    let boxed = ProbeExtensionEnumerator()

    func configure(for domain: any ContactProviderDomain) {
        configuredIdentifier = domain.identifier
    }

    func enumerator(for collection: ContactItem.Identifier) -> any ContactItemEnumerator {
        _ = collection
        return boxed
    }

    func invalidate() async throws {}
}

func testExtensionConformance() {
    let ext: any ContactProviderExtension = ProbeExtension()
    precondition(ext is ProbeExtension)
    let enumerating: any ContactItemEnumerating = ext
    _ = enumerating.enumerator(for: .rootContainer)
}

func testExtensionConfigure() {
    let ext = ProbeExtension()
    let domain = DefaultContactProviderDomain()
    ext.configure(for: domain)
    precondition(ext.configuredIdentifier == DefaultContactProviderDomain.identifier)
    precondition(ext.configuredIdentifier == domain.identifier)
}

func testExtensionConfiguration() {
    let ext = ProbeExtension()
    let configuration = ext.configuration
    precondition(type(of: configuration) == ContactProviderExtensionConfiguration.self)
    let again = ext.configuration
    _ = again
}

import CoreGraphics
import FileProvider
import Foundation
import UniformTypeIdentifiers

/// Future clean EC2 dependency-identity probe.
///
/// Isolated `tests/acceptance/test_host.sh` does not compile this file. A later
/// EC2 run must build guest Foundation, CoreGraphics, and UniformTypeIdentifiers
/// first, compile FileProvider against those `-I`/`-L` paths, then link and run
/// this client with `LD_LIBRARY_PATH` so `libFileProvider.dylib` is loaded.
private func requireCode(_ error: any Error, _ code: NSFileProviderError.Code) {
    guard let typed = error as? NSFileProviderError else {
        fatalError("expected NSFileProviderError, got \(error)")
    }
    precondition(typed.code == code)
}

private func waitOnce(_ work: (@escaping () -> Void) -> Void) {
    let gate = DispatchSemaphore(value: 0)
    work { gate.signal() }
    gate.wait()
}

private final class IdentityItem: NSObject, NSFileProviderItemProtocol {
    let itemIdentifier: NSFileProviderItemIdentifier
    let parentItemIdentifier: NSFileProviderItemIdentifier
    let filename: String
    var contentType: UTType?

    init(
        itemIdentifier: NSFileProviderItemIdentifier,
        parentItemIdentifier: NSFileProviderItemIdentifier,
        filename: String,
        contentType: UTType?
    ) {
        self.itemIdentifier = itemIdentifier
        self.parentItemIdentifier = parentItemIdentifier
        self.filename = filename
        self.contentType = contentType
    }
}

private final class IdentityServiceSource: NSObject, NSFileProviderServiceSource {
    let serviceName: NSFileProviderServiceName
    let isRestricted = true

    init(serviceName: NSFileProviderServiceName) {
        self.serviceName = serviceName
    }

    func makeListenerEndpoint() throws -> Foundation.NSXPCListenerEndpoint {
        Foundation.NSXPCListenerEndpoint()
    }
}

private final class IdentityObserver: NSObject, NSFileProviderEnumerationObserver {
    var items: [any NSFileProviderItemProtocol] = []
    var finished = false

    func didEnumerate(_ updatedItems: [any NSFileProviderItemProtocol]) {
        items.append(contentsOf: updatedItems)
    }

    func finishEnumerating(upTo nextPage: NSFileProviderPage?) {
        _ = nextPage
        finished = true
    }

    func finishEnumeratingWithError(_ error: any Error) {
        _ = error
        finished = true
    }
}

private final class IdentityEnumerator: NSObject, NSFileProviderEnumerator {
    let stored: [any NSFileProviderItemProtocol]

    init(items: [any NSFileProviderItemProtocol]) {
        self.stored = items
    }

    func invalidate() {}

    func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        _ = page
        observer.didEnumerate(stored)
        observer.finishEnumerating(upTo: nil)
    }
}

enum FileProviderDependencyIdentity {
    static func main() async {
        let size = CoreGraphics.CGSize(width: 48, height: 48)
        let utType = UniformTypeIdentifiers.UTType.plainText
        let item = IdentityItem(
            itemIdentifier: NSFileProviderItemIdentifier("identity"),
            parentItemIdentifier: .rootContainer,
            filename: "Identity.txt",
            contentType: utType
        )
        let existentialItem: any NSFileProviderItemProtocol = item
        precondition(existentialItem.contentType == utType)
        precondition(existentialItem.filename == "Identity.txt")

        let source = IdentityServiceSource(serviceName: NSFileProviderServiceName("identity.svc"))
        let existentialSource: any NSFileProviderServiceSource = source
        let endpoint = try! existentialSource.makeListenerEndpoint()
        precondition(type(of: endpoint) == Foundation.NSXPCListenerEndpoint.self)
        _ = endpoint

        let enumerator = IdentityEnumerator(items: [existentialItem])
        let existentialEnumerator: any NSFileProviderEnumerator = enumerator
        let observer = IdentityObserver()
        let existentialObserver: any NSFileProviderEnumerationObserver = observer
        existentialEnumerator.enumerateItems(
            for: existentialObserver,
            startingAt: NSFileProviderPage.sortedByName
        )
        precondition(observer.items.count == 1)
        precondition(observer.finished)

        precondition(NSFileProviderManager(for: NSFileProviderDomain(
            identifier: NSFileProviderDomainIdentifier("identity-domain"),
            displayName: "Identity"
        )) == nil)
        try await NSFileProviderManager.add(
            NSFileProviderDomain(
                identifier: NSFileProviderDomainIdentifier("identity-domain"),
                displayName: "Identity"
            )
        )
        precondition(NSFileProviderManager(for: NSFileProviderDomain(
            identifier: NSFileProviderDomainIdentifier("identity-domain"),
            displayName: "Identity"
        )) != nil)

        let manager = NSFileProviderManager.default
        var serviceCalls = 0
        var sawSynchronousNestedService = false
        waitOnce { done in
            manager.getService(
                named: NSFileProviderServiceName("identity.svc"),
                for: .rootContainer
            ) { service, error in
                serviceCalls += 1
                precondition(service == nil)
                requireCode(error!, .providerNotFound)
                var nested = 0
                let nestedGate = DispatchSemaphore(value: 0)
                manager.getService(
                    named: NSFileProviderServiceName("identity.svc"),
                    for: .rootContainer
                ) { _, nestedError in
                    nested += 1
                    requireCode(nestedError!, .providerNotFound)
                    nestedGate.signal()
                }
                if nested != 0 {
                    sawSynchronousNestedService = true
                }
                nestedGate.wait()
                precondition(nested == 1)
                done()
            }
        }
        precondition(serviceCalls == 1)
        precondition(!sawSynchronousNestedService)

        var identityCalls = 0
        waitOnce { done in
            NSFileProviderManager.getIdentifierForUserVisibleFile(
                at: URL(fileURLWithPath: "/tmp")
            ) { itemID, domainID, error in
                identityCalls += 1
                precondition(itemID == nil)
                precondition(domainID == nil)
                requireCode(error!, .noSuchItem)
                done()
            }
        }
        precondition(identityCalls == 1)

        var stabilizeCalls = 0
        waitOnce { done in
            manager.waitForStabilization { error in
                stabilizeCalls += 1
                precondition(error == nil)
                done()
            }
        }
        precondition(stabilizeCalls == 1)

        var downloadCalls = 0
        waitOnce { done in
            manager.requestDownloadForItem(withIdentifier: .rootContainer) { error in
                downloadCalls += 1
                requireCode(error!, .providerNotFound)
                done()
            }
        }
        precondition(downloadCalls == 1)

        var removeAllCalls = 0
        waitOnce { done in
            NSFileProviderManager.removeAllDomains { error in
                removeAllCalls += 1
                precondition(error == nil)
                done()
            }
        }
        precondition(removeAllCalls == 1)

        let fileProviderExtension = NSFileProviderExtension()
        var thumbItems = 0
        var thumbFinish = 0
        var thumbSawSync = false
        waitOnce { done in
            _ = fileProviderExtension.fetchThumbnails(
                for: [existentialItem.itemIdentifier],
                requestedSize: size,
                perThumbnailCompletionHandler: { _, data, error in
                    thumbItems += 1
                    precondition(data == nil)
                    requireCode(error!, .providerNotFound)
                    precondition(thumbFinish == 0)
                },
                completionHandler: { error in
                    thumbFinish += 1
                    requireCode(error!, .providerNotFound)
                    precondition(thumbItems == 1)
                    done()
                }
            )
            if thumbItems != 0 || thumbFinish != 0 {
                thumbSawSync = true
            }
        }
        precondition(thumbItems == 1)
        precondition(thumbFinish == 1)
        precondition(!thumbSawSync)

        print("FILEPROVIDER_DEPENDENCY_IDENTITY_OK")
    }
}

let fileProviderIdentityGate = DispatchSemaphore(value: 0)
Task {
    await FileProviderDependencyIdentity.main()
    fileProviderIdentityGate.signal()
}
fileProviderIdentityGate.wait()

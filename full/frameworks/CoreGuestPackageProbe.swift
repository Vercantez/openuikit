// Project-owned runtime proof for the reusable core guest package. Application
// sources are deliberately absent: this executable proves that the packaged
// framework identities, resources, fonts, observation path, and loader closure
// survive outside the build directories that produced them.
import Foundation
import UIKit
import SwiftUI
import Combine

#if canImport(DeveloperToolsSupport)
@_spi(OpenUIKitPreview) import DeveloperToolsSupport

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
private struct CorePreviewRegistry: DeveloperToolsSupport.PreviewRegistry {
    static let fileID = "CoreGuestPackageProbe.swift"
    static let line = 1
    static let column = 1

    @MainActor static let retainedView = UIView()

    @MainActor
    static func makePreview() throws -> DeveloperToolsSupport.Preview {
        DeveloperToolsSupport.Preview(body: { retainedView })
    }
}
#endif

@main
struct CoreGuestPackageProbe {
    @MainActor
    static func main() {
        guard CommandLine.arguments.count == 4 else {
            fatalError(
                "usage: CoreGuestPackageProbe <resource-root> <system-font> <bold-font>"
            )
        }

        OpenUIKitRuntime.resourceRoot = CommandLine.arguments[1]
        OpenUIKitRuntime.fontPaths = [
            "system": CommandLine.arguments[2],
            "bold": CommandLine.arguments[3],
        ]

        let foundationNotification: Foundation.Notification.Type =
            Foundation.Notification.self
        let _: UIKit.Notification.Type = foundationNotification
        let foundationCenter: Foundation.NotificationCenter.Type =
            Foundation.NotificationCenter.self
        let _: UIKit.NotificationCenter.Type = foundationCenter
        let foundationQueue: Foundation.OperationQueue.Type =
            Foundation.OperationQueue.self
        let _: UIKit.OperationQueue.Type = foundationQueue

        let center = NotificationCenter()
        let name = Notification.Name("CoreGuestPackageProbe")
        var deliveries = 0
        let token = center.addObserver(
            forName: name,
            object: nil,
            queue: nil
        ) { _ in
            deliveries += 1
        }
        center.post(name: name, object: nil)
        center.removeObserver(token)
        precondition(deliveries == 1)

        let subject = PassthroughSubject<Int, Never>()
        var values: [Int] = []
        let cancellable = subject.sink { values.append($0) }
        subject.send(7)
        withExtendedLifetime(cancellable) {}
        precondition(values == [7])

        _ = Text("core-package")
        let label = UIColor.label
        let system = UIFont.systemFont(ofSize: 17)
        let bold = UIFont.boldSystemFont(ofSize: 17)
        precondition(system.pointSize == 17)
        precondition(bold.pointSize == 17)
        _ = label

        #if canImport(DeveloperToolsSupport)
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            let value = try! CorePreviewRegistry.makePreview()
            precondition(
                value._openUIKitBody() as AnyObject ===
                    CorePreviewRegistry.retainedView
            )
        }
        let preview = "enabled"
        #else
        let preview = "disabled"
        #endif
        print(
            "CORE_GUEST_PACKAGE_MACHO_OK "
                + "notification=shared combine=delivered resources=loaded "
                + "fonts=system,bold preview=\(preview)"
        )
    }
}

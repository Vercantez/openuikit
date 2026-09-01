import SwiftUI
import UIKit
import Foundation

private struct TrueIOSSwiftUIDylibView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("SwiftUI dynamic framework")
                .font(.headline)
            Button("Advance") {}
        }
        .padding(.all, 12)
    }
}

@MainActor
private func allDescendants(of root: UIView) -> [UIView] {
    root.subviews + root.subviews.flatMap(allDescendants)
}

@main
private enum TrueIOSSwiftUIDylibProbe {
    @MainActor
    static func main() {
        let controller = UIHostingController(rootView: TrueIOSSwiftUIDylibView())
        let host = controller.view!
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 120)
        host.layoutIfNeeded()

        let descendants = allDescendants(of: host)
        let renderedText = descendants
            .compactMap { $0 as? UILabel }
            .contains { $0.text == "SwiftUI dynamic framework" }
        let renderedButton = descendants
            .contains { $0.accessibilityIdentifier == "SwiftUI.Button" }
        precondition(renderedText && renderedButton)

        let cfSourceNSError = NSError(
            domain: "Portable.Domain",
            code: 42,
            userInfo: ["k": "v"]
        )
        let cfError = unsafeBitCast(cfSourceNSError, to: CFError.self)
        let cfErrorAsError: any Error = cfError
        precondition(cfErrorAsError._domain == "Portable.Domain")
        precondition(cfErrorAsError._code == 42)
        precondition(
            (cfErrorAsError._userInfo as? [String: Any])?["k"] as? String
                == "v"
        )
        precondition(cfErrorAsError._getEmbeddedNSError() === cfError)
        let cfBridgedNSError = cfErrorAsError as NSError
        precondition(cfBridgedNSError.domain == "Portable.Domain")
        precondition(cfBridgedNSError.code == 42)
        precondition(cfBridgedNSError.userInfo["k"] as? String == "v")

        print(
            "TRUE_IOS_SWIFTUI_DYLIB_RUNTIME_OK " +
            "descendants=\(descendants.count) text=rendered button=rendered"
        )
    }
}

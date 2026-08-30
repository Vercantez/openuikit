// App-shaped compile/link/runtime proof. The import line is intentionally the
// one unchanged iOS app source writes: UIKit alone must re-export both the
// portable UIKit surface and FoundationEssentials' canonical IndexPath.
import UIKit

#if canImport(Foundation)
#error("literal UIKit identity probe must not rely on a Foundation umbrella")
#endif

#if !canImport(FoundationEssentials)
#error("literal UIKit did not re-export FoundationEssentials")
#endif

private func acceptFoundationPath(_ path: FoundationEssentials.IndexPath) -> Int {
    path.count
}

private func acceptUIKitPath(_ path: OpenUIKit.IndexPath) -> Int {
    path.count
}

@main
struct LiteralUIKitIndexPathProbe {
    static func main() {
        let fromUIKit = IndexPath(item: 9, section: 3)
        let canonical: FoundationEssentials.IndexPath = fromUIKit
        let roundTrip: OpenUIKit.IndexPath = canonical

        precondition(acceptFoundationPath(fromUIKit) == 2)
        precondition(acceptUIKitPath(canonical) == 2)
        precondition(Array(canonical) == [3, 9])
        precondition(roundTrip.section == 3)
        precondition(roundTrip.row == 9)
        precondition(roundTrip.item == 9)

        let unqualified = IndexPath(row: 7, section: 4)
        precondition(acceptFoundationPath(unqualified) == 2)
        precondition(acceptUIKitPath(unqualified) == 2)
        precondition(Array(unqualified) == [4, 7])
        print("LITERAL_UIKIT_INDEXPATH_OK")
    }
}

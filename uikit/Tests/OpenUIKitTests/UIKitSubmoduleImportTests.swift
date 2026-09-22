// Unchanged app source imports UIKit submodules (Kickstarter Library
// UIStackView.swift:2 `import UIKit.UIStackView`; ten ladder-corpus files
// `import UIKit.UIGestureRecognizerSubclass`). This file compiles only if the
// `UIKit` module has those Clang submodules (Sources/UIKitClangModule); before
// that target existed the chain failed with "no such module
// 'UIKit.UIStackView'".
#if canImport(Darwin)
import UIKit.UIStackView
import UIKit.UIGestureRecognizerSubclass
import UIKit.UIActivity
import UIKit.UIFont
import UIKit.UIContextMenuConfiguration
import XCTest

@MainActor
final class UIKitSubmoduleImportTests: XCTestCase {
    func testSubmoduleImportsReachTheSwiftOverlay() {
        // Declarations still come from OpenUIKit through the Swift overlay.
        let stack = UIKit.UIStackView()
        XCTAssertEqual(stack.axis, .horizontal)
        XCTAssertEqual(UIKit.UIFont.systemFont(ofSize: 17).pointSize, 17)
    }
}
#endif

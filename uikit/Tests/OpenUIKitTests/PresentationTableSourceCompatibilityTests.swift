// Literal downstream-module gate: this file intentionally imports the public
// `UIKit` shim, never `@testable OpenUIKit`.

import XCTest
import UIKit

#if !os(Linux)
@MainActor
#endif
private final class ModalTransitionOverrideProbe: UIViewController {
    var setCount = 0

    override var modalTransitionStyle: UIModalTransitionStyle {
        get { super.modalTransitionStyle }
        set {
            setCount += 1
            super.modalTransitionStyle = newValue
        }
    }
}

#if !os(Linux)
@MainActor
#endif
private final class TableMoveOverrideProbe: UITableView {
    var observedMove: (source: IndexPath, destination: IndexPath)?

    override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        observedMove = (indexPath, newIndexPath)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class PopoverBackgroundOverrideProbe: UIPopoverPresentationController {
    var setCount = 0

    override var backgroundColor: UIColor? {
        get { super.backgroundColor }
        set {
            setCount += 1
            super.backgroundColor = newValue
        }
    }
}

#if !os(Linux)
@MainActor
#endif
private final class PopoverAccessorOverrideProbe: UIViewController {
    lazy var replacement = PopoverBackgroundOverrideProbe(
        presentedViewController: self,
        presenting: nil
    )

    override var popoverPresentationController: UIPopoverPresentationController? {
        replacement
    }
}

#if !os(Linux)
@MainActor
#endif
final class PresentationTableSourceCompatibilityTests: XCTestCase {
    func testModalTransitionStyleIsExternallyOverridableThroughLiteralUIKit() {
        let controller = ModalTransitionOverrideProbe()
        XCTAssertEqual(controller.modalTransitionStyle, .coverVertical)
        controller.modalTransitionStyle = .crossDissolve
        XCTAssertEqual(controller.modalTransitionStyle, .crossDissolve)
        XCTAssertEqual(controller.setCount, 1)
    }

    func testMoveRowIsExternallyOverridableThroughLiteralUIKit() throws {
        let table = TableMoveOverrideProbe(frame: .zero, style: .plain)
        let source = IndexPath(row: 3, section: 0)
        let destination = IndexPath(row: 1, section: 0)
        table.moveRow(at: source, to: destination)
        let observed = try XCTUnwrap(table.observedMove)
        XCTAssertEqual(observed.source, source)
        XCTAssertEqual(observed.destination, destination)
    }

    func testPopoverBackgroundColorIsExternallyOverridableThroughLiteralUIKit() {
        let presented = UIViewController()
        let popover = PopoverBackgroundOverrideProbe(
            presentedViewController: presented,
            presenting: nil
        )
        XCTAssertNil(popover.backgroundColor)
        popover.backgroundColor = .systemBackground
        XCTAssertEqual(popover.backgroundColor, .systemBackground)
        XCTAssertEqual(popover.setCount, 1)
    }

    func testPopoverAccessorIsExternallyOverridableThroughLiteralUIKit() {
        let controller = PopoverAccessorOverrideProbe()
        XCTAssertTrue(controller.popoverPresentationController === controller.replacement)
    }
}

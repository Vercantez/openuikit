import Foundation
import Accessibility

func testNameFromColorFailClosed() {
    let color = CGColor()
    precondition(AXNameFromColor(color).isEmpty)
}

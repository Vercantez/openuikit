import Foundation
import BrowserEngineKit

func testBEAccessibilityTextMarkerConstructible() {
    let marker = BEAccessibilityTextMarker()
    precondition(type(of: marker) == BEAccessibilityTextMarker.self)
    precondition(BEAccessibilityTextMarker.supportsSecureCoding)
    let copy = marker.copy() as! BEAccessibilityTextMarker
    precondition(copy !== marker)
}

func testBEAccessibilityTextMarkerInitCoder() {
    let marker = BEAccessibilityTextMarker(coder: NSKeyedArchiver(requiringSecureCoding: false))
    precondition(marker != nil)
}

func testBEAccessibilityTextMarkerRangeMarkers() {
    let range = BEAccessibilityTextMarker.Range()
    let start = BEAccessibilityTextMarker()
    let end = BEAccessibilityTextMarker()
    range.startMarker = start
    range.endMarker = end
    precondition(range.startMarker === start)
    precondition(range.endMarker === end)
    precondition(BEAccessibilityTextMarker.Range.supportsSecureCoding)
}

func testBEAccessibilityTextMarkerRangeInitCoder() {
    let range = BEAccessibilityTextMarker.Range(coder: NSKeyedArchiver(requiringSecureCoding: false))
    precondition(range != nil)
}

func testBEAccessibilityRemoteElementStoresIdentity() {
    let element = BEAccessibilityRemoteElement(identifier: "remote", hostPid: 42)
    precondition(element.identifier == "remote")
    precondition(element.hostPid == 42)
}

func testBEAccessibilityRemoteHostElementContainer() {
    let host = BEAccessibilityRemoteHostElement(identifier: "host", remotePid: 7)
    precondition(host.identifier == "host")
    precondition(host.remotePid == 7)
    precondition(host.accessibilityContainer == nil)
    let container = NSObject()
    host.accessibilityContainer = container
    precondition(host.accessibilityContainer === container)
}

func testNSObjectBrowserAccessibilityDefaults() {
    let object = NSObject()
    precondition(object.browserAccessibilityPressedState == .undefined)
    precondition(object.browserAccessibilityContainerType.isEmpty)
    precondition(object.browserAccessibilityCurrentStatus == nil)
    precondition(object.browserAccessibilitySortDirection == nil)
    precondition(object.browserAccessibilityRoleDescription == nil)
    precondition(!object.browserAccessibilityIsRequired)
    precondition(!object.browserAccessibilityHasDOMFocus)
}

func testNSObjectBrowserAccessibilityRoundTrip() {
    let object = NSObject()
    object.browserAccessibilityPressedState = .mixed
    object.browserAccessibilityContainerType = [.list, .table]
    object.browserAccessibilityCurrentStatus = "busy"
    object.browserAccessibilitySortDirection = "ascending"
    object.browserAccessibilityRoleDescription = "button"
    object.browserAccessibilityIsRequired = true
    object.browserAccessibilityHasDOMFocus = true
    precondition(object.browserAccessibilityPressedState == .mixed)
    precondition(object.browserAccessibilityContainerType.contains(.list))
    precondition(object.browserAccessibilityCurrentStatus == "busy")
    precondition(object.browserAccessibilitySortDirection == "ascending")
    precondition(object.browserAccessibilityRoleDescription == "button")
    precondition(object.browserAccessibilityIsRequired)
    precondition(object.browserAccessibilityHasDOMFocus)
}

func testNSObjectBrowserAccessibilitySelectedTextRange() {
    let object = NSObject()
    precondition(object.browserAccessibilitySelectedTextRange().location == 0)
    object.browserAccessibilitySetSelectedTextRange(NSRange(location: 3, length: 4))
    let range = object.browserAccessibilitySelectedTextRange()
    precondition(range.location == 3)
    precondition(range.length == 4)
}

func testNSObjectBrowserAccessibilityInsertDeleteValue() {
    let object = NSObject()
    object.browserAccessibilityInsertTextAtCursor(text: "abcd")
    precondition(object.browserAccessibilityValue(in: NSRange(location: 0, length: 4)) == "abcd")
    let attributed = object.browserAccessibilityAttributedValue(in: NSRange(location: 1, length: 2))
    precondition(attributed.string == "bc")
    object.browserAccessibilityDeleteTextAtCursor(numberOfCharacters: 2)
    precondition(object.browserAccessibilityValue(in: NSRange(location: 0, length: 2)) == "ab")
    object.browserAccessibilityDeleteTextAtCursor(numberOfCharacters: 99)
    precondition(object.browserAccessibilityValue(in: NSRange(location: 0, length: 1)) == "")
}

func testNSObjectAccessibilityLinePositionsFailClosed() {
    let object = NSObject()
    precondition(object.accessibilityLineStartPositionFromCurrentSelection() == NSNotFound)
    precondition(object.accessibilityLineEndPositionFromCurrentSelection() == NSNotFound)
    let range = object.accessibilityLineRange(forPosition: 3)
    precondition(range.location == NSNotFound)
}

private final class HostMarkerSupport: NSObject, BEAccessibilityTextMarkerSupport {
    func accessibilityBounds(for range: BEAccessibilityTextMarker.Range) -> CGRect {
        _ = range
        return CGRect(x: 1, y: 2, width: 3, height: 4)
    }

    func accessibilityContent(for range: BEAccessibilityTextMarker.Range) -> String? {
        _ = range
        return "content"
    }

    func accessibilityLineEndMarker(for marker: BEAccessibilityTextMarker) -> BEAccessibilityTextMarker? {
        marker
    }

    func accessibilityLineStartMarker(for marker: BEAccessibilityTextMarker) -> BEAccessibilityTextMarker? {
        marker
    }

    func accessibilityMarker(for point: CGPoint) -> BEAccessibilityTextMarker? {
        _ = point
        return BEAccessibilityTextMarker()
    }

    func accessibilityNextTextMarker(_ marker: BEAccessibilityTextMarker) -> BEAccessibilityTextMarker? {
        marker
    }

    func accessibilityPreviousTextMarker(_ marker: BEAccessibilityTextMarker) -> BEAccessibilityTextMarker? {
        marker
    }

    func accessibilityRange(for range: BEAccessibilityTextMarker.Range) -> NSRange {
        _ = range
        return NSRange(location: 1, length: 2)
    }

    func accessibilityTextMarker(forPosition position: Int) -> BEAccessibilityTextMarker? {
        _ = position
        return BEAccessibilityTextMarker()
    }

    func accessibilityTextMarkerRange() -> BEAccessibilityTextMarker.Range {
        BEAccessibilityTextMarker.Range()
    }

    func accessibilityTextMarkerRangeForCurrentSelection() -> BEAccessibilityTextMarker.Range? {
        nil
    }

    func accessibilityTextMarkerRange(for range: NSRange) -> BEAccessibilityTextMarker.Range? {
        _ = range
        return BEAccessibilityTextMarker.Range()
    }
}

func testBEAccessibilityTextMarkerSupportBounds() {
    let support = HostMarkerSupport()
    let range = BEAccessibilityTextMarker.Range()
    precondition(support.accessibilityBounds(for: range) == CGRect(x: 1, y: 2, width: 3, height: 4))
}

func testBEAccessibilityTextMarkerSupportContent() {
    precondition(HostMarkerSupport().accessibilityContent(for: BEAccessibilityTextMarker.Range()) == "content")
}

func testBEAccessibilityTextMarkerSupportLineMarkers() {
    let marker = BEAccessibilityTextMarker()
    let support = HostMarkerSupport()
    precondition(support.accessibilityLineEndMarker(for: marker) === marker)
    precondition(support.accessibilityLineStartMarker(for: marker) === marker)
}

func testBEAccessibilityTextMarkerSupportNavigation() {
    let marker = BEAccessibilityTextMarker()
    let support = HostMarkerSupport()
    precondition(support.accessibilityNextTextMarker(marker) === marker)
    precondition(support.accessibilityPreviousTextMarker(marker) === marker)
    precondition(support.accessibilityMarker(for: CGPoint(x: 1, y: 1)) != nil)
}

func testBEAccessibilityTextMarkerSupportRanges() {
    let support = HostMarkerSupport()
    precondition(support.accessibilityRange(for: BEAccessibilityTextMarker.Range()).location == 1)
    precondition(support.accessibilityTextMarker(forPosition: 0) != nil)
    precondition(type(of: support.accessibilityTextMarkerRange()) == BEAccessibilityTextMarker.Range.self)
    precondition(support.accessibilityTextMarkerRangeForCurrentSelection() == nil)
    precondition(support.accessibilityTextMarkerRange(for: NSRange(location: 0, length: 1)) != nil)
}

import Foundation
import Accessibility

func testAnnouncementNotification() {
    _ = AccessibilityNotification.self
    let fromString = AccessibilityNotification.Announcement("hello")
    precondition(String(fromString.announcement.characters) == "hello")
    let fromAttr = AccessibilityNotification.Announcement(AttributedString("attr"))
    precondition(String(fromAttr.announcement.characters) == "attr")
    let fromNS = AccessibilityNotification.Announcement(NSAttributedString(string: "ns"))
    precondition(String(fromNS.announcement.characters) == "ns")
    fromString.post()
}

func testPageScrolledNotification() {
    let fromString = AccessibilityNotification.PageScrolled("scrolled")
    precondition(String(fromString.announcement.characters) == "scrolled")
    let fromAttr = AccessibilityNotification.PageScrolled(AttributedString("attr"))
    precondition(String(fromAttr.announcement.characters) == "attr")
    let fromNS = AccessibilityNotification.PageScrolled(NSAttributedString(string: "ns"))
    precondition(String(fromNS.announcement.characters) == "ns")
    fromString.post()
}

func testLayoutChangedNotification() {
    let empty = AccessibilityNotification.LayoutChanged()
    precondition(empty.element == nil)
    let withElement = AccessibilityNotification.LayoutChanged("focus")
    precondition(withElement.element as? String == "focus")
    empty.post()
}

func testScreenChangedNotification() {
    let empty = AccessibilityNotification.ScreenChanged()
    precondition(empty.element == nil)
    let withElement = AccessibilityNotification.ScreenChanged(1)
    precondition(withElement.element as? Int == 1)
    empty.post()
}

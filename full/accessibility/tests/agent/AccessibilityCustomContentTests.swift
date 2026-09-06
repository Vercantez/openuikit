import Foundation
import Accessibility

private final class CustomHost: NSObject, AXCustomContentProvider {
    var accessibilityCustomContent: [AXCustomContent]!
    var accessibilityCustomContentBlock: AXCustomContentReturnBlock?
}

func testCustomContentConstruction() {
    let plain = AXCustomContent(label: "L", value: "V")
    precondition(plain.label == "L")
    precondition(plain.value == "V")
    precondition(plain.attributedLabel.string == "L")
    precondition(plain.attributedValue.string == "V")
    precondition(plain.importance == .default)
    plain.importance = .high
    precondition(plain.importance == .high)

    let attributed = AXCustomContent(
        attributedLabel: NSAttributedString(string: "AL"),
        attributedValue: NSAttributedString(string: "AV")
    )
    precondition(attributed.label == "AL")
    precondition(attributed.value == "AV")

    let copy = plain.copy() as! AXCustomContent
    precondition(copy.importance == .high)
    precondition(copy.label == "L")

    let data = try! NSKeyedArchiver.archivedData(withRootObject: plain, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: AXCustomContent.self, from: data)
    precondition(decoded?.label == "L")
    precondition(decoded?.importance == .high)
}

func testCustomContentProvider() {
    let host = CustomHost()
    precondition(host.accessibilityCustomContent == nil)
    let content = AXCustomContent(label: "a", value: "b")
    host.accessibilityCustomContent = [content]
    precondition(host.accessibilityCustomContent.count == 1)
    var blockCalled = false
    let block: AXCustomContentReturnBlock = {
        blockCalled = true
        return [content]
    }
    host.accessibilityCustomContentBlock = block
    let produced = host.accessibilityCustomContentBlock?()
    precondition(blockCalled)
    precondition(produced?.count == 1)
}

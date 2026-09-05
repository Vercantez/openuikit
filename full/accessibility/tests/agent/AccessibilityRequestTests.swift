import Foundation
import Accessibility

func testAccessibilityRequest() {
    precondition(AccessibilityRequest.current == nil)
    let request = AccessibilityRequest(technology: .voiceOver)
    precondition(request.technology == .voiceOver)
    let data = try! NSKeyedArchiver.archivedData(withRootObject: request, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: AccessibilityRequest.self, from: data)
    precondition(decoded?.technology == .voiceOver)
    let copy = request.copy() as! AccessibilityRequest
    precondition(copy.technology == .voiceOver)
}

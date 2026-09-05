import Foundation
import Accessibility

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public Accessibility APIs.
func accessibilityDependencyIdentityProbe() {
    let uuid = UUID()
    precondition(AXMFiHearingDevice.pairedDeviceIdentifiers().isEmpty)

    let attributed = NSAttributedString(string: "label-\(uuid.uuidString)")
    let content = AXCustomContent(
        attributedLabel: attributed,
        attributedValue: NSAttributedString(string: "value")
    )
    precondition(content.label.contains(uuid.uuidString))

    let data = try! NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: AXCustomContent.self, from: data)
    precondition(decoded?.label == content.label)

    let error = AXFeatureOverrideSessionError(.undefined, userInfo: ["foundation": uuid.uuidString])
    precondition(error.userInfo["foundation"] as? String == uuid.uuidString)
    let ns = error as NSError
    precondition(ns.domain == AXFeatureOverrideSessionErrorDomain)

    var attributedString = AttributedString("hello")
    attributedString.accessibilitySpeechSpellsOutCharacters = true
    precondition(attributedString.accessibilitySpeechSpellsOutCharacters == true)
}

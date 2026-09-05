import ClassKit
import Foundation

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation does not execute this file.
func classKitDependencyIdentityProbe() {
    let created = Date(timeIntervalSince1970: 1)
    _ = created
    let context = CLSContext(type: .lesson, identifier: "foundation", title: "Foundation")
    context.universalLinkURL = URL(fileURLWithPath: "/tmp/classkit-identity")
    context.suggestedAge = NSRange(location: 8, length: 3)
    context.summary = "Foundation identity"
    let item = CLSScoreItem(identifier: "score", title: "Score", score: 1, maxScore: 2)
    _ = item.score
    let error = CLSError(.classKitUnavailable, userInfo: ["when": created])
    _ = error.errorCode
    _ = CLSErrorCodeDomain
    _ = Data([0x4f, 0x4b])
    _ = NSPredicate { _, _ in true }
}

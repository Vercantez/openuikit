import Foundation
import SharedWithYouCore

func testUTCollaborationOptionsTypeIdentifier() {
    precondition(UTCollaborationOptionsTypeIdentifier == "com.apple.sharedwithyou.collaboration-options")
    precondition(!UTCollaborationOptionsTypeIdentifier.isEmpty)
    precondition(type(of: UTCollaborationOptionsTypeIdentifier) == String.self)
}

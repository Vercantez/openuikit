import Foundation
import SharedWithYouCore

func testSWCollaborationIdentifierType() {
    let identifier = SWCollaborationIdentifier("collab.alpha")
    precondition(identifier.rawValue == "collab.alpha")
}

func testSWCollaborationIdentifierInitRawValue() {
    let identifier = SWCollaborationIdentifier(rawValue: "raw.collab")
    precondition(identifier.rawValue == "raw.collab")
}

func testSWCollaborationIdentifierInitString() {
    let identifier = SWCollaborationIdentifier("wrapped.collab")
    precondition(identifier.rawValue == "wrapped.collab")
}

func testSWCollaborationIdentifierNotEqual() {
    let left = SWCollaborationIdentifier("a")
    let right = SWCollaborationIdentifier("b")
    precondition(left != right)
    precondition(!(left != SWCollaborationIdentifier("a")))
}

func testSWCollaborationIdentifierHashValue() {
    let identifier = SWCollaborationIdentifier("hash.collab")
    precondition(identifier.hashValue == SWCollaborationIdentifier("hash.collab").hashValue)
    precondition(identifier.hashValue != SWCollaborationIdentifier("other").hashValue)
}

func testSWCollaborationIdentifierHashInto() {
    var hasher = Hasher()
    SWCollaborationIdentifier("into.collab").hash(into: &hasher)
    let first = hasher.finalize()
    var hasherAgain = Hasher()
    SWCollaborationIdentifier("into.collab").hash(into: &hasherAgain)
    _ = first
    _ = hasherAgain.finalize()
}

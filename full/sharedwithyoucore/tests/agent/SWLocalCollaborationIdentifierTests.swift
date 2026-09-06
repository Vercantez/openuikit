import Foundation
import SharedWithYouCore

func testSWLocalCollaborationIdentifierType() {
    let identifier = SWLocalCollaborationIdentifier("local.alpha")
    precondition(identifier.rawValue == "local.alpha")
}

func testSWLocalCollaborationIdentifierInitRawValue() {
    let identifier = SWLocalCollaborationIdentifier(rawValue: "raw.local")
    precondition(identifier.rawValue == "raw.local")
}

func testSWLocalCollaborationIdentifierInitString() {
    let identifier = SWLocalCollaborationIdentifier("wrapped.local")
    precondition(identifier.rawValue == "wrapped.local")
}

func testSWLocalCollaborationIdentifierNotEqual() {
    let left = SWLocalCollaborationIdentifier("a")
    let right = SWLocalCollaborationIdentifier("b")
    precondition(left != right)
    precondition(!(left != SWLocalCollaborationIdentifier("a")))
}

func testSWLocalCollaborationIdentifierHashValue() {
    let identifier = SWLocalCollaborationIdentifier("hash.local")
    precondition(identifier.hashValue == SWLocalCollaborationIdentifier("hash.local").hashValue)
    precondition(identifier.hashValue != SWLocalCollaborationIdentifier("other").hashValue)
}

func testSWLocalCollaborationIdentifierHashInto() {
    var hasher = Hasher()
    SWLocalCollaborationIdentifier("into.local").hash(into: &hasher)
    let first = hasher.finalize()
    var hasherAgain = Hasher()
    SWLocalCollaborationIdentifier("into.local").hash(into: &hasherAgain)
    _ = first
    _ = hasherAgain.finalize()
}

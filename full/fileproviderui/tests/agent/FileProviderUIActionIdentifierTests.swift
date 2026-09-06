import Foundation
import FileProviderUI

func testActionIdentifierType() {
    let identifier = FPUIActionIdentifier("com.example.action")
    precondition(type(of: identifier) == FPUIActionIdentifier.self)
    precondition(identifier.rawValue == "com.example.action")
}

func testActionIdentifierInitRawValue() {
    let identifier = FPUIActionIdentifier(rawValue: "com.example.raw")
    precondition(identifier.rawValue == "com.example.raw")
    let empty = FPUIActionIdentifier(rawValue: "")
    precondition(empty.rawValue.isEmpty)
}

func testActionIdentifierInitString() {
    let identifier = FPUIActionIdentifier("com.example.string")
    precondition(identifier.rawValue == "com.example.string")
    let fromRaw = FPUIActionIdentifier(rawValue: "com.example.string")
    precondition(identifier == fromRaw)
}

func testActionIdentifierInequality() {
    let left = FPUIActionIdentifier("alpha")
    let right = FPUIActionIdentifier("beta")
    let same = FPUIActionIdentifier(rawValue: "alpha")
    precondition(left != right)
    precondition(right != left)
    precondition(!(left != same))
    precondition(left == same)
}

func testActionIdentifierHashValue() {
    let left = FPUIActionIdentifier("hash-me")
    let same = FPUIActionIdentifier(rawValue: "hash-me")
    let other = FPUIActionIdentifier("other")
    precondition(left.hashValue == same.hashValue)
    precondition(left.hashValue != other.hashValue)
    _ = left.hashValue
}

func testActionIdentifierHashInto() {
    let identifier = FPUIActionIdentifier("into")
    var hasherA = Hasher()
    identifier.hash(into: &hasherA)
    var hasherB = Hasher()
    identifier.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    var hasherOther = Hasher()
    FPUIActionIdentifier("other").hash(into: &hasherOther)
    var hasherAgain = Hasher()
    identifier.hash(into: &hasherAgain)
    precondition(hasherOther.finalize() != hasherAgain.finalize())
}

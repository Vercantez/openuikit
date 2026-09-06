import Foundation
@_spi(OpenUIKitHost) import ScreenTime

func testProfileIdentifierType() {
    let identifier = STWebHistory.ProfileIdentifier("Profile.Default")
    precondition(type(of: identifier) == STWebHistory.ProfileIdentifier.self)
    let boxed: Any = identifier
    precondition(boxed is STWebHistory.ProfileIdentifier)
}

func testProfileIdentifierInitRawValue() {
    let identifier = STWebHistory.ProfileIdentifier(rawValue: "raw.profile")
    precondition(identifier.rawValue == "raw.profile")
    let empty = STWebHistory.ProfileIdentifier(rawValue: "")
    precondition(empty.rawValue.isEmpty)
}

func testProfileIdentifierInitUnlabeled() {
    let identifier = STWebHistory.ProfileIdentifier("unlabeled")
    precondition(identifier.rawValue == "unlabeled")
    let viaRaw = STWebHistory.ProfileIdentifier(rawValue: "unlabeled")
    precondition(identifier == viaRaw)
}

func testProfileIdentifierInequality() {
    let left = STWebHistory.ProfileIdentifier("alpha")
    let right = STWebHistory.ProfileIdentifier("beta")
    let same = STWebHistory.ProfileIdentifier("alpha")
    precondition(left != right)
    precondition(!(left != same))
    precondition(left == same)
}

func testProfileIdentifierHashValue() {
    let left = STWebHistory.ProfileIdentifier("hash-me")
    let same = STWebHistory.ProfileIdentifier("hash-me")
    let other = STWebHistory.ProfileIdentifier("other")
    precondition(left.hashValue == same.hashValue)
    _ = other.hashValue
}

func testProfileIdentifierHashInto() {
    let identifier = STWebHistory.ProfileIdentifier("into")
    var hasher = Hasher()
    identifier.hash(into: &hasher)
    let first = hasher.finalize()
    var hasher2 = Hasher()
    STWebHistory.ProfileIdentifier("into").hash(into: &hasher2)
    precondition(first == hasher2.finalize())
}

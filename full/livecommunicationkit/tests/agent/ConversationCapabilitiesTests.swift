import Foundation
import LiveCommunicationKit

func testCapabilitiesMemberRawValues() {
    precondition(Conversation.Capabilities.pausing.rawValue == 1 << 0)
    precondition(Conversation.Capabilities.merging.rawValue == 1 << 1)
    precondition(Conversation.Capabilities.unmerging.rawValue == 1 << 2)
    precondition(Conversation.Capabilities.video.rawValue == 1 << 3)
    precondition(Conversation.Capabilities.playingTones.rawValue == 1 << 4)
    precondition(Conversation.Capabilities(rawValue: 1 << 0) == .pausing)
    precondition(Conversation.Capabilities.pausing != .video)
}

func testCapabilitiesRawValueTypealiases() {
    let raw: Conversation.Capabilities.RawValue = Conversation.Capabilities.video.rawValue
    precondition(raw == 8)
    let element: Conversation.Capabilities.Element = .merging
    precondition(element == .merging)
    let literal: Conversation.Capabilities.ArrayLiteralElement = .playingTones
    precondition(literal == .playingTones)
}

func testCapabilitiesEmptyInit() {
    let empty = Conversation.Capabilities()
    precondition(empty.isEmpty)
    precondition(empty.rawValue == 0)
    precondition(!empty.contains(.video))
}

func testCapabilitiesArrayLiteralInit() {
    let caps: Conversation.Capabilities = [.video, .pausing]
    precondition(caps.contains(.video))
    precondition(caps.contains(.pausing))
    precondition(!caps.contains(.merging))
}

func testCapabilitiesSequenceInit() {
    let caps = Conversation.Capabilities([.merging, .unmerging])
    precondition(caps.contains(.merging))
    precondition(caps.contains(.unmerging))
    precondition(!caps.contains(.playingTones))
}

func testCapabilitiesContainsAndUnion() {
    let combined = Conversation.Capabilities.video.union(.playingTones)
    precondition(combined.contains(.video))
    precondition(combined.contains(.playingTones))
    precondition(!combined.contains(.pausing))
    let again = Conversation.Capabilities.video.union(.video)
    precondition(again == .video)
}

func testCapabilitiesIntersectionAndSymmetricDifference() {
    let left: Conversation.Capabilities = [.video, .pausing, .merging]
    let right: Conversation.Capabilities = [.video, .unmerging]
    precondition(left.intersection(right) == .video)
    let symmetric = left.symmetricDifference(right)
    precondition(symmetric.contains(.pausing))
    precondition(symmetric.contains(.merging))
    precondition(symmetric.contains(.unmerging))
    precondition(!symmetric.contains(.video))
}

func testCapabilitiesSubtractingAndSubset() {
    let all: Conversation.Capabilities = [.pausing, .merging, .unmerging, .video, .playingTones]
    let videoOnly = all.subtracting(.pausing.union(.merging).union(.unmerging).union(.playingTones))
    precondition(videoOnly == .video)
    precondition(Conversation.Capabilities.video.isSubset(of: all))
    precondition(all.isSuperset(of: .merging))
    precondition(Conversation.Capabilities.video.isStrictSubset(of: all))
    precondition(all.isStrictSuperset(of: .video))
    precondition(!all.isDisjoint(with: .video))
    precondition(Conversation.Capabilities.pausing.isDisjoint(with: .video))
}

func testCapabilitiesMutatingInsertRemoveUpdate() {
    var caps = Conversation.Capabilities()
    let inserted = caps.insert(.video)
    precondition(inserted.inserted)
    precondition(inserted.memberAfterInsert == .video)
    precondition(caps.contains(.video))
    let duplicate = caps.insert(.video)
    precondition(!duplicate.inserted)
    let updated = caps.update(with: .playingTones)
    precondition(updated == nil)
    precondition(caps.contains(.playingTones))
    let removed = caps.remove(.video)
    precondition(removed == .video)
    precondition(!caps.contains(.video))
    precondition(caps.remove(.video) == nil)
}

func testCapabilitiesFormSetAlgebra() {
    var caps: Conversation.Capabilities = [.video]
    caps.formUnion(.pausing)
    precondition(caps.contains(.video) && caps.contains(.pausing))
    caps.formIntersection(.pausing)
    precondition(caps == .pausing)
    caps.formSymmetricDifference(.merging)
    precondition(caps.contains(.pausing))
    precondition(caps.contains(.merging))
    caps.subtract(.pausing)
    precondition(caps == .merging)
}

func testCapabilitiesInequality() {
    precondition(Conversation.Capabilities.video != .merging)
    precondition(!(Conversation.Capabilities.video != .video))
}

func testCapabilitiesHashableAndCodable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    Conversation.Capabilities.video.hash(into: &hasherA)
    Conversation.Capabilities.video.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(Conversation.Capabilities.merging.hashValue == Conversation.Capabilities.merging.hashValue)
    let original: Conversation.Capabilities = [.video, .playingTones]
    let data = try! JSONEncoder().encode(original)
    let restored = try! JSONDecoder().decode(Conversation.Capabilities.self, from: data)
    precondition(restored == original)
}

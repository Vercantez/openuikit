import Foundation
import CryptoTokenKit

private func tkEqMust(_ condition: Bool, _ message: String) {
    if !condition {
        preconditionFailure(message)
    }
}

func testTKPINCharsetEqualityHash() {
    let a = TKSmartCardPINFormat.Charset.numeric
    let b = TKSmartCardPINFormat.Charset.numeric
    let c = TKSmartCardPINFormat.Charset.alphanumeric
    tkEqMust(a == b, "charset ==")
    tkEqMust(a != c, "charset !=")
    tkEqMust(!(a == c), "charset neg")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(hasher.finalize() == { var h = Hasher(); b.hash(into: &h); return h.finalize() }(), "charset hash(into:)")
    tkEqMust(a.hashValue == b.hashValue, "charset hashValue")
    var set = Set<TKSmartCardPINFormat.Charset>()
    set.insert(a)
    tkEqMust(set.contains(b), "charset Set.insert")
    tkEqMust(!set.contains(c), "charset set miss")
}

func testTKPINEncodingEqualityHash() {
    let a = TKSmartCardPINFormat.Encoding.binary
    let b = TKSmartCardPINFormat.Encoding.binary
    let c = TKSmartCardPINFormat.Encoding.ascii
    tkEqMust(a == b, "encoding ==")
    tkEqMust(a != c, "encoding !=")
    tkEqMust(!(a == c), "encoding neg")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(hasher.finalize() == { var h = Hasher(); b.hash(into: &h); return h.finalize() }(), "encoding hash(into:)")
    tkEqMust(a.hashValue == b.hashValue, "encoding hashValue")
    var set = Set<TKSmartCardPINFormat.Encoding>()
    set.insert(a)
    tkEqMust(set.contains(b), "encoding Set.insert")
    tkEqMust(!set.contains(c), "encoding set miss")
}

func testTKPINJustificationEqualityHash() {
    let a = TKSmartCardPINFormat.Justification.left
    let b = TKSmartCardPINFormat.Justification.left
    let c = TKSmartCardPINFormat.Justification.right
    tkEqMust(a == b, "just ==")
    tkEqMust(a != c, "just !=")
    tkEqMust(!(a == c), "just neg")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(hasher.finalize() == { var h = Hasher(); b.hash(into: &h); return h.finalize() }(), "just hash(into:)")
    tkEqMust(a.hashValue == b.hashValue, "just hashValue")
    var set = Set<TKSmartCardPINFormat.Justification>()
    set.insert(a)
    tkEqMust(set.contains(b), "just Set.insert")
    tkEqMust(!set.contains(c), "just set miss")
}

func testTKSlotStateEqualityHash() {
    let a = TKSmartCardSlot.State.empty
    let b = TKSmartCardSlot.State.empty
    let c = TKSmartCardSlot.State.validCard
    tkEqMust(a == b, "state ==")
    tkEqMust(a != c, "state !=")
    tkEqMust(!(a == c), "state neg")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(hasher.finalize() == { var h = Hasher(); b.hash(into: &h); return h.finalize() }(), "state hash(into:)")
    tkEqMust(a.hashValue == b.hashValue, "state hashValue")
    var set = Set<TKSmartCardSlot.State>()
    set.insert(a)
    tkEqMust(set.contains(b), "state Set.insert")
    tkEqMust(!set.contains(c), "state set miss")
}

func testTKTokenOperationEqualityHash() {
    let a = TKTokenOperation.signData
    let b = TKTokenOperation.signData
    let c = TKTokenOperation.decryptData
    tkEqMust(a == b, "op ==")
    tkEqMust(a != c, "op !=")
    tkEqMust(!(a == c), "op neg")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(hasher.finalize() == { var h = Hasher(); b.hash(into: &h); return h.finalize() }(), "op hash(into:)")
    tkEqMust(a.hashValue == b.hashValue, "op hashValue")
    var set = Set<TKTokenOperation>()
    set.insert(a)
    tkEqMust(set.contains(b), "op Set.insert")
    tkEqMust(!set.contains(c), "op set miss")
}

func testTKErrorCodeHashWitnesses() {
    let a = TKError.Code.notImplemented
    let b = TKError.Code.notImplemented
    let c = TKError.Code.communicationError
    tkEqMust(a == b, "code ==")
    tkEqMust(a != c, "code !=")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(hasher.finalize() == { var h = Hasher(); b.hash(into: &h); return h.finalize() }(), "code hash(into:)")
    tkEqMust(a.hashValue == b.hashValue, "code hashValue")
    var set = Set<TKError.Code>()
    set.insert(a)
    tkEqMust(set.contains(b), "code Set.insert")
    tkEqMust(!set.contains(c), "code set miss")
}

func testTKPINCompletionEquality() {
    typealias Completion = TKSmartCardUserInteractionForPINOperation.Completion
    let a: Completion = .key
    let b: Completion = .key
    let c: Completion = .timeout
    tkEqMust(a == b, "completion ==")
    tkEqMust(a != c, "completion !=")
    tkEqMust(!(a == c), "completion neg")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(a.hashValue == b.hashValue, "completion hashValue")
    var set = Set<Completion>()
    set.insert(a)
    tkEqMust(set.contains(b), "completion Set.insert")
    tkEqMust(!set.contains(c), "completion set miss")
}

func testTKPINConfirmationEquality() {
    typealias Confirmation = TKSmartCardUserInteractionForSecurePINChange.Confirmation
    let a: Confirmation = .new
    let b: Confirmation = .new
    let c: Confirmation = .current
    tkEqMust(a == b, "confirmation ==")
    tkEqMust(a != c, "confirmation !=")
    tkEqMust(!(a == c), "confirmation neg")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(a.hashValue == b.hashValue, "confirmation hashValue")
    var set = Set<Confirmation>()
    set.insert(a)
    tkEqMust(set.contains(b), "confirmation Set.insert")
    tkEqMust(!set.contains(c), "confirmation set miss")
}

func testTKSmartCardProtocolEquality() {
    let a: TKSmartCardProtocol = .t0
    let b: TKSmartCardProtocol = .t0
    let c: TKSmartCardProtocol = .t1
    tkEqMust(a == b, "proto ==")
    tkEqMust(a != c, "proto !=")
    tkEqMust(!(a == c), "proto neg")
    var hasher = Hasher()
    a.hash(into: &hasher)
    tkEqMust(a.hashValue == b.hashValue, "proto hashValue")
    var set = Set<TKSmartCardProtocol>()
    set.insert(a)
    tkEqMust(set.contains(b), "proto Set.insert")
    tkEqMust(!set.contains(c), "proto set miss")
}

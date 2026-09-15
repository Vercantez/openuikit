import Foundation
import CryptoTokenKit

private func tkWitnessMust(_ condition: Bool, _ message: String) {
    if !condition {
        preconditionFailure(message)
    }
}

func testTKCompletionWitnessBatchA() {
    typealias C = TKSmartCardUserInteractionForPINOperation.Completion
    let lit: C = [.key, .timeout]
    tkWitnessMust(lit.contains(.key), "lit key")
    let fromSeq = C([.key, .timeout])
    tkWitnessMust(fromSeq == lit, "seq init")
    tkWitnessMust(lit != .maxLength, "neq")
    tkWitnessMust(C(rawValue: 2) == .key, "raw init")
    tkWitnessMust(lit.isDisjoint(with: .maxLength), "disjoint")
    tkWitnessMust(!lit.isDisjoint(with: .key), "not disjoint")
    tkWitnessMust(lit.isSuperset(of: .key), "superset")
    tkWitnessMust(C.key.isSubset(of: lit), "subset")
    tkWitnessMust(lit.subtracting(.key) == .timeout, "subtracting")
    tkWitnessMust(C.key.isStrictSubset(of: lit), "strict sub")
    tkWitnessMust(lit.isStrictSuperset(of: .key), "strict super")
    tkWitnessMust(!lit.isEmpty, "not empty")
    tkWitnessMust(C().isEmpty, "empty")
    var mutable: C = [.key, .timeout, .maxLength]
    mutable.subtract(.maxLength)
    tkWitnessMust(mutable == lit, "subtract")
    tkWitnessMust(mutable.intersection(.key) == .key, "intersection")
    tkWitnessMust(C.key.union(.timeout) == lit, "union")
    tkWitnessMust(C.key.symmetricDifference(.timeout) == lit, "symdiff")
    var forms: C = [.key]
    forms.formUnion(.timeout)
    tkWitnessMust(forms == lit, "formUnion")
    forms.formIntersection(.key)
    tkWitnessMust(forms == .key, "formIntersection")
    forms.formSymmetricDifference(.timeout)
    tkWitnessMust(forms == lit, "formSymdiff")
    var ins: C = []
    let inserted = ins.insert(.key)
    tkWitnessMust(inserted.inserted && ins.contains(.key), "insert")
    tkWitnessMust(ins.remove(.key) == .key, "remove")
    tkWitnessMust(ins.update(with: .timeout) == nil, "update")
}

func testTKCompletionWitnessBatchB() {
    typealias C = TKSmartCardUserInteractionForPINOperation.Completion
    let a: C = [.key]
    let b: C = [.timeout]
    tkWitnessMust(a != b, "neq b")
    tkWitnessMust(C([a, b]) == [.key, .timeout], "seq of sets")
    tkWitnessMust(a.isDisjoint(with: b), "disjoint b")
    tkWitnessMust((a.union(b)).isSuperset(of: a), "super b")
    tkWitnessMust((a.union(b)).subtracting(a) == b, "sub b")
    tkWitnessMust(a.isStrictSubset(of: a.union(b)), "strict sub b")
    tkWitnessMust((a.union(b)).isStrictSuperset(of: a), "strict super b")
    tkWitnessMust(a.isSubset(of: a.union(b)), "sub2 b")
    var m: C = [a, b].reduce(C()) { $0.union($1) }
    m.subtract(a)
    tkWitnessMust(m == b, "subtract b")
    tkWitnessMust(m.intersection(b) == b, "inter b")
    tkWitnessMust(a.union(b) == [.key, .timeout], "union b")
    tkWitnessMust(a.symmetricDifference(b) == [.key, .timeout], "symdiff b")
    m.formIntersection(b)
    tkWitnessMust(m == b, "formInter b")
    m.formSymmetricDifference(a)
    tkWitnessMust(m == [.key, .timeout], "formSymdiff b")
    m.formUnion(.maxLength)
    tkWitnessMust(m.contains(.maxLength), "formUnion b")
    var u: C = []
    tkWitnessMust(u.update(with: .key) == nil && u.contains(.key), "update b")
    tkWitnessMust(u.remove(.key) == .key && u.isEmpty, "remove b")
    tkWitnessMust(C(rawValue: 0).isEmpty, "raw empty")
}

func testTKConfirmationWitnessBatchA() {
    typealias C = TKSmartCardUserInteractionForSecurePINChange.Confirmation
    let lit: C = [.new, .current]
    tkWitnessMust(lit.contains(.new), "lit new")
    let fromSeq = C([.new, .current])
    tkWitnessMust(fromSeq == lit, "seq init")
    tkWitnessMust(lit != .new, "neq")
    tkWitnessMust(C(rawValue: 1) == .new, "raw init")
    tkWitnessMust(C.new.isDisjoint(with: .current), "disjoint")
    tkWitnessMust(!lit.isDisjoint(with: .new), "not disjoint")
    tkWitnessMust(lit.isSuperset(of: .new), "superset")
    tkWitnessMust(C.new.isSubset(of: lit), "subset")
    tkWitnessMust(lit.subtracting(.new) == .current, "subtracting")
    tkWitnessMust(C.new.isStrictSubset(of: lit), "strict sub")
    tkWitnessMust(lit.isStrictSuperset(of: .new), "strict super")
    tkWitnessMust(!lit.isEmpty, "not empty")
    tkWitnessMust(C().isEmpty, "empty")
    var mutable: C = [.new, .current]
    mutable.subtract(.new)
    tkWitnessMust(mutable == .current, "subtract")
    tkWitnessMust(mutable.intersection(.current) == .current, "intersection")
    tkWitnessMust(C.new.union(.current) == lit, "union")
    tkWitnessMust(C.new.symmetricDifference(.current) == lit, "symdiff")
    var forms: C = [.new]
    forms.formUnion(.current)
    tkWitnessMust(forms == lit, "formUnion")
    forms.formIntersection(.new)
    tkWitnessMust(forms == .new, "formIntersection")
    forms.formSymmetricDifference(.current)
    tkWitnessMust(forms == lit, "formSymdiff")
    var ins: C = []
    let inserted = ins.insert(.new)
    tkWitnessMust(inserted.inserted && ins.contains(.new), "insert")
    tkWitnessMust(ins.remove(.new) == .new, "remove")
    tkWitnessMust(ins.update(with: .current) == nil, "update")
}

func testTKConfirmationWitnessBatchB() {
    typealias C = TKSmartCardUserInteractionForSecurePINChange.Confirmation
    let a: C = [.new]
    let both: C = [.new, .current]
    tkWitnessMust(a != .current, "neq b")
    tkWitnessMust(C([.new, .current]) == both, "seq b")
    tkWitnessMust(a.isDisjoint(with: .current), "disjoint b")
    tkWitnessMust(both.isSuperset(of: a), "super b")
    tkWitnessMust(both.subtracting(a) == .current, "sub b")
    tkWitnessMust(a.isStrictSubset(of: both), "strict sub b")
    tkWitnessMust(both.isStrictSuperset(of: a), "strict super b")
    tkWitnessMust(a.isSubset(of: both), "sub2 b")
    tkWitnessMust(!both.isEmpty, "not empty b")
    var m: C = both
    m.subtract(a)
    tkWitnessMust(m == .current, "subtract b")
    tkWitnessMust(m.intersection(.current) == .current, "inter b")
    tkWitnessMust(a.union(.current) == both, "union b")
    tkWitnessMust(a.symmetricDifference(.current) == both, "symdiff b")
    m.formUnion(a)
    tkWitnessMust(m == both, "formUnion b")
    m.formIntersection(a)
    tkWitnessMust(m == a, "formInter b")
    m.formSymmetricDifference(.current)
    tkWitnessMust(m == both, "formSymdiff b")
    var u: C = []
    tkWitnessMust(u.update(with: .new) == nil && u.contains(.new), "update b")
    tkWitnessMust(u.remove(.new) == .new && u.isEmpty, "remove b")
    let v: C = [.current]
    tkWitnessMust(C(rawValue: v.rawValue) == v, "raw roundtrip")
}

func testTKCardProtocolWitnessBatchA() {
    let lit: TKSmartCardProtocol = [.t0, .t1]
    tkWitnessMust(lit.contains(.t0), "lit t0")
    let fromSeq = TKSmartCardProtocol([.t0, .t1])
    tkWitnessMust(fromSeq == lit, "seq init")
    tkWitnessMust(lit != .t0, "neq")
    tkWitnessMust(TKSmartCardProtocol(rawValue: 1) == .t0, "raw init")
    tkWitnessMust(TKSmartCardProtocol.t0.isDisjoint(with: .t1), "disjoint")
    tkWitnessMust(!lit.isDisjoint(with: .t0), "not disjoint")
    tkWitnessMust(lit.isSuperset(of: .t0), "superset")
    tkWitnessMust(TKSmartCardProtocol.t0.isSubset(of: lit), "subset")
    tkWitnessMust(lit.subtracting(.t0) == .t1, "subtracting")
    tkWitnessMust(TKSmartCardProtocol.t0.isStrictSubset(of: lit), "strict sub")
    tkWitnessMust(lit.isStrictSuperset(of: .t0), "strict super")
    tkWitnessMust(!lit.isEmpty, "not empty")
    var mutable: TKSmartCardProtocol = [.t0, .t1]
    mutable.subtract(.t0)
    tkWitnessMust(mutable == .t1, "subtract")
    tkWitnessMust(mutable.intersection(.t1) == .t1, "intersection")
    tkWitnessMust(TKSmartCardProtocol.t0.union(.t1) == lit, "union")
    tkWitnessMust(TKSmartCardProtocol.t0.symmetricDifference(.t1) == lit, "symdiff")
    var forms: TKSmartCardProtocol = [.t0]
    forms.formUnion(.t1)
    tkWitnessMust(forms == lit, "formUnion")
    forms.formIntersection(.t0)
    tkWitnessMust(forms == .t0, "formIntersection")
    forms.formSymmetricDifference(.t1)
    tkWitnessMust(forms == lit, "formSymdiff")
    var ins: TKSmartCardProtocol = []
    let inserted = ins.insert(.t0)
    tkWitnessMust(inserted.inserted && ins.contains(.t0), "insert")
    tkWitnessMust(ins.remove(.t0) == .t0, "remove")
    tkWitnessMust(ins.update(with: .t1) == nil, "update")
}

func testTKCardProtocolWitnessBatchB() {
    let a: TKSmartCardProtocol = [.t0]
    let both: TKSmartCardProtocol = [.t0, .t1]
    tkWitnessMust(a != .t1, "neq b")
    tkWitnessMust(TKSmartCardProtocol([.t0, .t1]) == both, "seq b")
    tkWitnessMust(a.isDisjoint(with: .t15), "disjoint b")
    tkWitnessMust(both.isSuperset(of: a), "super b")
    tkWitnessMust(both.subtracting(a) == .t1, "sub b")
    tkWitnessMust(a.isStrictSubset(of: both), "strict sub b")
    tkWitnessMust(both.isStrictSuperset(of: a), "strict super b")
    tkWitnessMust(a.isSubset(of: both), "sub2 b")
    var m: TKSmartCardProtocol = both
    m.subtract(a)
    tkWitnessMust(m == .t1, "subtract b")
    tkWitnessMust(m.intersection(.t1) == .t1, "inter b")
    tkWitnessMust(a.union(.t1) == both, "union b")
    tkWitnessMust(a.symmetricDifference(.t1) == both, "symdiff b")
    m.formUnion(a)
    tkWitnessMust(m == both, "formUnion b")
    m.formIntersection(a)
    tkWitnessMust(m == a, "formInter b")
    m.formSymmetricDifference(.t1)
    tkWitnessMust(m == both, "formSymdiff b")
    var u: TKSmartCardProtocol = []
    tkWitnessMust(u.update(with: .t0) == nil && u.contains(.t0), "update b")
    tkWitnessMust(u.remove(.t0) == .t0 && u.isEmpty, "remove b")
    tkWitnessMust(TKSmartCardProtocol(rawValue: 0).isEmpty, "raw empty")
}

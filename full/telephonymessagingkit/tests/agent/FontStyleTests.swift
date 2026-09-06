import Foundation
import TelephonyMessagingKit

func testFontStyleRawValues() {
    precondition(RCSService.Business.Card.FontStyle.bold.rawValue == 1 << 0)
    precondition(RCSService.Business.Card.FontStyle.italics.rawValue == 1 << 1)
    precondition(RCSService.Business.Card.FontStyle.underline.rawValue == 1 << 2)
    precondition(RCSService.Business.Card.FontStyle(rawValue: 1 << 0) == .bold)
    let empty = RCSService.Business.Card.FontStyle()
    precondition(empty.isEmpty)
    precondition(empty.rawValue == 0)
    tmkRoundTrip(RCSService.Business.Card.FontStyle.bold)
    tmkHash(RCSService.Business.Card.FontStyle.italics)
}

func testFontStyleAlgebra() {
    var style: RCSService.Business.Card.FontStyle = [.bold, .italics]
    precondition(style.contains(.bold))
    precondition(style.union(.underline).contains(.underline))
    precondition(style.intersection(.italics) == .italics)
    precondition(style.symmetricDifference(.italics).contains(.bold))
    style.formUnion(.underline)
    precondition(style.contains(.underline))
    style.formIntersection(.bold)
    precondition(style == .bold)
    var other: RCSService.Business.Card.FontStyle = .italics
    other.formSymmetricDifference(.bold)
    precondition(other.contains(.bold) && other.contains(.italics))
    var subtractable: RCSService.Business.Card.FontStyle = [.bold, .underline]
    subtractable.subtract(.bold)
    precondition(subtractable == .underline)
    precondition(RCSService.Business.Card.FontStyle.bold.subtracting(.bold).isEmpty)
    precondition(RCSService.Business.Card.FontStyle.bold.isSubset(of: [.bold, .italics]))
    precondition(RCSService.Business.Card.FontStyle.bold.isSuperset(of: .bold))
    precondition(RCSService.Business.Card.FontStyle.bold.isDisjoint(with: .italics))
    precondition((RCSService.Business.Card.FontStyle.bold.isStrictSubset(of: [.bold, .italics])))
    precondition((RCSService.Business.Card.FontStyle.bold.union(.italics)).isStrictSuperset(of: .bold))
    var inserted = RCSService.Business.Card.FontStyle()
    let result = inserted.insert(.bold)
    precondition(result.inserted)
    precondition(inserted.remove(.bold) == .bold)
    _ = inserted.update(with: .italics)
    let fromSequence = RCSService.Business.Card.FontStyle([.bold, .underline])
    precondition(fromSequence.contains(.underline))
}

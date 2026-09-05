import DataDetection
import Foundation

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

func testMatchTypeNamedCasesAndRawValues() {
    require(DataDetector.MatchType.RawValue.self == UInt64.self, "RawValue")
    require(DataDetector.MatchType.Element.self == DataDetector.MatchType.self, "Element")
    require(
        DataDetector.MatchType.ArrayLiteralElement.self == DataDetector.MatchType.self,
        "ArrayLiteralElement"
    )

    let named: [(DataDetector.MatchType, UInt64)] = [
        (.link, 1 << 0),
        (.emailAddress, 1 << 1),
        (.phoneNumber, 1 << 2),
        (.postalAddress, 1 << 3),
        (.calendarEvent, 1 << 4),
        (.moneyAmount, 1 << 5),
        (.measurement, 1 << 6),
        (.flightNumber, 1 << 7),
        (.shipmentTrackingNumber, 1 << 8),
        (.paymentIdentifier, 1 << 9),
    ]
    var seen: Set<UInt64> = []
    for (flag, raw) in named {
        require(flag.rawValue == raw, "named raw \(raw)")
        require(DataDetector.MatchType(rawValue: raw) == flag, "init(rawValue:)")
        require(seen.insert(raw).inserted, "unique raw")
    }
}

func testMatchTypeEmptyAndAll() {
    let empty = DataDetector.MatchType()
    require(empty.isEmpty, "empty init")
    require(empty.rawValue == 0, "empty raw")
    require(!DataDetector.MatchType.all.isEmpty, "all nonempty")
    for flag: DataDetector.MatchType in [
        .link, .emailAddress, .phoneNumber, .postalAddress, .calendarEvent,
        .moneyAmount, .measurement, .flightNumber, .shipmentTrackingNumber,
        .paymentIdentifier,
    ] {
        require(DataDetector.MatchType.all.contains(flag), "all contains \(flag.rawValue)")
    }
    require(DataDetector.MatchType.all != empty, "all !=")
}

func testMatchTypeSetAlgebraQueries() {
    let emailAndPhone: DataDetector.MatchType = [.emailAddress, .phoneNumber]
    require(emailAndPhone.contains(.emailAddress), "contains email")
    require(emailAndPhone.contains(.phoneNumber), "contains phone")
    require(!emailAndPhone.contains(.link), "does not contain link")
    require(emailAndPhone.isSuperset(of: .emailAddress), "superset")
    require(emailAndPhone.isSubset(of: .all), "subset of all")
    require(emailAndPhone.isDisjoint(with: .link), "disjoint link")
    require(!emailAndPhone.isDisjoint(with: .phoneNumber), "not disjoint phone")
    require(emailAndPhone.isStrictSubset(of: .all), "strict subset")
    require(DataDetector.MatchType.all.isStrictSuperset(of: emailAndPhone), "strict superset")
    require(!emailAndPhone.isStrictSubset(of: emailAndPhone), "not strict subset of self")
    require(!emailAndPhone.isEmpty, "combined nonempty")
}

func testMatchTypeMutatingSetAlgebra() {
    var flags: DataDetector.MatchType = [.link]
    let inserted = flags.insert(.emailAddress)
    require(inserted.inserted, "insert new")
    require(inserted.memberAfterInsert == .emailAddress, "member after insert")
    let again = flags.insert(.emailAddress)
    require(!again.inserted, "insert existing")
    let removed = flags.remove(.link)
    require(removed == .link, "remove link")
    require(!flags.contains(.link), "link gone")
    let missing = flags.remove(.flightNumber)
    require(missing == nil, "remove missing")
    let updated = flags.update(with: .phoneNumber)
    require(updated == nil, "update new")
    flags.formUnion(.measurement)
    require(flags.contains(.measurement), "formUnion")
    flags.formIntersection([.emailAddress, .measurement])
    require(flags.contains(.emailAddress) && flags.contains(.measurement), "formIntersection")
    flags.formSymmetricDifference(.emailAddress)
    require(!flags.contains(.emailAddress), "formSymmetricDifference dropped email")
    require(flags.contains(.measurement), "formSymmetricDifference kept measurement")
    flags.subtract(.measurement)
    require(flags.isEmpty, "subtract to empty")
}

func testMatchTypeNonmutatingSetAlgebra() {
    let left: DataDetector.MatchType = [.link, .emailAddress]
    let right: DataDetector.MatchType = [.emailAddress, .phoneNumber]
    require(left.union(right) == [.link, .emailAddress, .phoneNumber], "union")
    require(left.intersection(right) == .emailAddress, "intersection")
    require(left.symmetricDifference(right) == [.link, .phoneNumber], "symmetricDifference")
    require(left.subtracting(.emailAddress) == .link, "subtracting")
    let fromSequence = DataDetector.MatchType([.calendarEvent, .flightNumber])
    require(fromSequence.contains(.calendarEvent) && fromSequence.contains(.flightNumber), "init(_ sequence:)")
    let fromLiteral: DataDetector.MatchType = [.moneyAmount, .postalAddress]
    require(fromLiteral.contains(.moneyAmount) && fromLiteral.contains(.postalAddress), "array literal")
}

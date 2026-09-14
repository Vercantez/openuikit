#if NSPREDICATE_PORT
import NSPredicatePort
import Foundation
typealias TestPredicate = NSPredicatePort.NSPredicate
typealias TestCompoundPredicate = NSPredicatePort.NSCompoundPredicate
typealias TestExpression = NSPredicatePort.NSExpression
typealias TestSortDescriptor = NSPredicatePort.NSSortDescriptor
#else
import Foundation
typealias TestPredicate = NSPredicate
typealias TestCompoundPredicate = NSCompoundPredicate
typealias TestExpression = NSExpression
typealias TestSortDescriptor = NSSortDescriptor
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

final class Person: NSObject {
    @objc var name: String
    @objc var age: Int
    @objc var city: String
    @objc var tags: [String]
    @objc var score: Double
    @objc var active: Bool
    @objc var parent: Person?
    init(name: String, age: Int, city: String, tags: [String], score: Double, active: Bool, parent: Person? = nil) {
        self.name = name
        self.age = age
        self.city = city
        self.tags = tags
        self.score = score
        self.active = active
        self.parent = parent
        super.init()
    }
}

private func sortPeople(
    _ people: [Person],
    using descriptor: TestSortDescriptor
) -> [Person] {
    people.enumerated().sorted { lhs, rhs in
        let order = descriptor.compare(lhs.element, to: rhs.element)
        if order == .orderedSame {
            return lhs.offset < rhs.offset
        }
        return order == .orderedAscending
    }.map(\.element)
}

let alice = Person(name: "Alice", age: 30, city: "Austin", tags: ["ios", "swift"], score: 4.5, active: true)
let bob = Person(name: "Bob", age: 17, city: "Boston", tags: ["linux"], score: 3.0, active: false)
let carol = Person(name: "Carol", age: 30, city: "Austin", tags: ["ios", "ml"], score: 4.5, active: true, parent: alice)

emit("const.true", TestPredicate(value: true).evaluate(with: nil))
emit("const.false", TestPredicate(value: false).evaluate(with: nil))

let cases: [(String, Any?)] = [
    ("age == 30", alice),
    ("age == 30", bob),
    ("age != 30", bob),
    ("age > 18", alice),
    ("age >= 30", alice),
    ("age < 18", bob),
    ("age <= 17", bob),
    ("name == \"Alice\"", alice),
    ("name == 'Alice'", alice),
    ("name BEGINSWITH \"Al\"", alice),
    ("name BEGINSWITH[c] \"al\"", alice),
    ("name BEGINSWITH[c] \"al\"", bob),
    ("name ENDSWITH \"ice\"", alice),
    ("name CONTAINS \"lic\"", alice),
    ("name LIKE \"Al*\"", alice),
    ("name LIKE[c] \"al*\"", alice),
    ("name MATCHES \"A.*e\"", alice),
    ("city IN {\"Austin\", \"Dallas\"}", alice),
    ("city IN {\"Austin\", \"Dallas\"}", bob),
    ("\"ios\" IN tags", alice),
    ("\"linux\" IN tags", alice),
    ("age BETWEEN {18, 40}", alice),
    ("age BETWEEN {18, 40}", bob),
    ("active == YES", alice),
    ("active == NO", bob),
    ("active == TRUE", alice),
    ("active == 1", alice),
    ("score == 4.5", alice),
    ("score > 4", alice),
    ("name == $N", alice),
    ("age == $A", alice),
    ("age == 30 AND city == \"Austin\"", alice),
    ("age == 30 AND city == \"Austin\"", bob),
    ("age == 17 OR city == \"Austin\"", bob),
    ("NOT (age == 30)", bob),
    ("NOT age == 30", bob),
    ("parent.name == \"Alice\"", carol),
    ("parent.name == \"Alice\"", alice),
    ("SELF == 1", 1),
    ("SELF == \"x\"", "x"),
    ("SELF IN {1, 2, 3}", 2),
    ("SELF BEGINSWITH \"he\"", "hello"),
    ("SELF CONTAINS[c] \"EL\"", "hello"),
    ("1 == 1", nil),
    ("1 == 2", nil),
    ("TRUEPREDICATE", alice),
    ("FALSEPREDICATE", alice),
]

for (fmt, obj) in cases {
    let p = TestPredicate(format: fmt)
    let vars: [String: Any]?
    if fmt.contains("$N") { vars = ["N": "Alice"] }
    else if fmt.contains("$A") { vars = ["A": 30] }
    else { vars = nil }
    let ok = p.evaluate(with: obj, substitutionVariables: vars)
    emit("eval.\(fmt)", "\(ok)|parsed=\(p.predicateFormat)")
}

let block = TestPredicate { obj, _ in
    (obj as? Person)?.age ?? 0 >= 18
}
emit("block.alice", block.evaluate(with: alice))
emit("block.bob", block.evaluate(with: bob))

let c1 = TestPredicate(format: "age == 30")
let c2 = TestPredicate(format: "city == %@", "Austin")
let andP = TestCompoundPredicate(andPredicateWithSubpredicates: [c1, c2])
emit("compound.and.alice", andP.evaluate(with: alice))
emit("compound.and.bob", andP.evaluate(with: bob))
emit("compound.and.format", andP.predicateFormat)
let orP = TestCompoundPredicate(orPredicateWithSubpredicates: [c1, TestPredicate(format: "age == 17")])
emit("compound.or.bob", orP.evaluate(with: bob))
let notP = TestCompoundPredicate(notPredicateWithSubpredicate: c1)
emit("compound.not.bob", notP.evaluate(with: bob))

let e1 = TestExpression(forKeyPath: "age")
emit("expr.keypath", e1.keyPath)
let e2 = TestExpression(forConstantValue: 30)
emit("expr.const", e2.constantValue ?? "nil")
let add = TestExpression(forFunction: "add:to:", arguments: [
    TestExpression(forConstantValue: 2),
    TestExpression(forConstantValue: 3),
])
emit("expr.add", add.expressionValue(with: nil, context: nil) ?? "nil")

let sd = TestSortDescriptor(key: "age", ascending: true)
let people: [Person] = [alice, bob, carol]
let sorted = sortPeople(people, using: sd)
emit("sort.age.names", sorted.map(\.name).joined(separator: ","))
let sd2 = TestSortDescriptor(
    key: "name",
    ascending: false,
    selector: #selector(NSString.localizedStandardCompare(_:))
)
let sorted2 = sortPeople(people, using: sd2)
emit("sort.name.desc", sorted2.map(\.name).joined(separator: ","))

emit("oracle.done", 1)

import Foundation
import Assignables

func testStringUserIdentity() {
    let identity = StringUserIdentity(value: "student-1")
    assignablesExpect(identity.value == "student-1", "value")
    assignablesExpect(identity.stringRepresentation == "student-1", "repr")
    assignablesExpect(identity.typeID == StringUserIdentity.typeID, "type")
    assignablesExpect(StringUserIdentity.typeID == "Assignables.StringUserIdentity", "static type")
    assignablesExpect(identity == StringUserIdentity(value: "student-1"), "eq")
    assignablesExpect(identity != StringUserIdentity(value: "other"), "neq")
    _ = identity.hashValue
    var hasher = Hasher()
    identity.hash(into: &hasher)
    _ = hasher.finalize()

    let data = try! JSONEncoder().encode(identity)
    let decoded = try! JSONDecoder().decode(StringUserIdentity.self, from: data)
    assignablesExpect(decoded == identity, "codable")
}

func testAnonymousUserIdentity() {
    let first = AnonymousUserIdentity()
    let second = AnonymousUserIdentity()
    assignablesExpect(first == second, "all equal")
    assignablesExpect(!(first != second), "neq false")
    assignablesExpect(first.stringRepresentation == "anonymous", "repr")
    assignablesExpect(first.typeID == AnonymousUserIdentity.typeID, "type")
    assignablesExpect(AnonymousUserIdentity.typeID == "Assignables.AnonymousUserIdentity", "static")
    _ = first.hashValue
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = hasher.finalize()
    let data = try! JSONEncoder().encode(first)
    let decoded = try! JSONDecoder().decode(AnonymousUserIdentity.self, from: data)
    assignablesExpect(decoded == first, "codable")
}

func testAnyUserIdentityBoxing() {
    let string = StringUserIdentity(value: "boxed")
    let any = AnyUserIdentity(string)
    assignablesExpect(any.typeID == string.typeID, "type")
    assignablesExpect(any.stringRepresentation == "boxed", "repr")
    assignablesExpect(any == string.eraseToAnyUserIdentity(), "erase")
    assignablesExpect(any.eraseToAnyUserIdentity() == any, "erase any")
    assignablesExpect(AnyUserIdentity(any) == any, "rebox")
    assignablesExpect(any != AnyUserIdentity(AnonymousUserIdentity()), "neq")
    _ = any.hashValue
    var hasher = Hasher()
    any.hash(into: &hasher)
    _ = hasher.finalize()
    let _: UserIdentity.As.Type = StringUserIdentity.As.self
    let _: AnyUserIdentity.As.Type = AnyUserIdentity.As.self
    let _: AnonymousUserIdentity.As.Type = AnonymousUserIdentity.As.self
}

func testUserIdentityFactory() {
    let string = UserIdentityFactory.string("from-factory")
    assignablesExpect(string.value == "from-factory", "factory string")
    let anonymous = UserIdentityFactory.anonymous
    assignablesExpect(anonymous == AnonymousUserIdentity(), "factory anonymous")
}

func testUserIdentityScope() {
    let identity = StringUserIdentity(value: "scoped")
    var ran = false
    let result = identity.scope {
        ran = true
        return 7
    }
    assignablesExpect(ran, "ran")
    assignablesExpect(result == 7, "result")
    let boxed = AnyUserIdentity(identity)
    let boxedResult = boxed.scope { "ok" }
    assignablesExpect(boxedResult == "ok", "any scope")
    let anonResult = AnonymousUserIdentity().scope { 1 }
    assignablesExpect(anonResult == 1, "anon scope")
}

func testUserIdentityRegistry() {
    UserIdentityTypeRegistry.registerUserIdentityType(
        typeID: StringUserIdentity.typeID,
        type: StringUserIdentity.self
    )
    let original = AnyUserIdentity(StringUserIdentity(value: "registered"))
    let data = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(AnyUserIdentity.self, from: data)
    assignablesExpect(decoded == original, "round trip")
}

func testAnyUserIdentityCodable() {
    let original = AnyUserIdentity(AnonymousUserIdentity())
    let data = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(AnyUserIdentity.self, from: data)
    assignablesExpect(decoded.typeID == AnonymousUserIdentity.typeID, "anon decode")
    assignablesExpect(decoded.stringRepresentation == "anonymous", "anon repr")
}

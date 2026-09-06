import Foundation
import LightweightCodeRequirements

func testEntitlementsQueryKeyAndMatchBool() {
    let query = EntitlementsQuery.key("com.apple.security.app-sandbox").match(true)
    let data = try! JSONEncoder().encode(query)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let ops = object["entitlements"] as! [[String: Any]]
    precondition(ops.count == 2)
    precondition(ops[0]["opcode"] as! Int == 1)
    precondition(ops[0]["string"] as! String == "com.apple.security.app-sandbox")
    precondition(ops[1]["opcode"] as! Int == 5)
    precondition(ops[1]["boolean"] as! Bool == true)
}

func testEntitlementsQueryStaticKeyPrefix() {
    let query = EntitlementsQuery.keyPrefix("com.apple.")
    let data = try! JSONEncoder().encode(query)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let ops = object["entitlements"] as! [[String: Any]]
    precondition(ops[0]["opcode"] as! Int == 9)
    precondition(ops[0]["string"] as! String == "com.apple.")
}

func testEntitlementsQueryInstanceKeyAndKeyPrefix() {
    let query = EntitlementsQuery.key("outer").key("inner").keyPrefix("pre")
    let data = try! JSONEncoder().encode(query)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let ops = object["entitlements"] as! [[String: Any]]
    precondition(ops.count == 3)
    precondition(ops[0]["opcode"] as! Int == 1)
    precondition(ops[1]["opcode"] as! Int == 1)
    precondition(ops[1]["string"] as! String == "inner")
    precondition(ops[2]["opcode"] as! Int == 9)
}

func testEntitlementsQueryElementAtIndex() {
    let query = EntitlementsQuery
        .key("com.apple.developer.ubiquity-container-identifiers")
        .elementAtIndex(0)
        .matchSingle("com.apple.TextEdit")
    let data = try! JSONEncoder().encode(query)
    let object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    let ops = object["entitlements"] as! [[String: Any]]
    precondition(ops[1]["opcode"] as! Int == 2)
    precondition(ops[1]["integer"] as! Int == 0)
    precondition(ops[2]["opcode"] as! Int == 3)
    precondition(ops[2]["string"] as! String == "com.apple.TextEdit")
}

func testEntitlementsQueryMatchStringVariants() {
    let allowed = EntitlementsQuery.key("list").match("com.apple.TextEdit")
    let prefix = EntitlementsQuery.key("id").matchPrefix("com.apple.")
    let prefixSingle = EntitlementsQuery.key("id").matchPrefixSingle("com.")
    let dataAllowed = try! JSONEncoder().encode(allowed)
    let dataPrefix = try! JSONEncoder().encode(prefix)
    let dataPrefixSingle = try! JSONEncoder().encode(prefixSingle)
    let opsAllowed = (try! JSONSerialization.jsonObject(with: dataAllowed) as! [String: Any])["entitlements"] as! [[String: Any]]
    let opsPrefix = (try! JSONSerialization.jsonObject(with: dataPrefix) as! [String: Any])["entitlements"] as! [[String: Any]]
    let opsPrefixSingle = (try! JSONSerialization.jsonObject(with: dataPrefixSingle) as! [String: Any])["entitlements"] as! [[String: Any]]
    precondition(opsAllowed[1]["opcode"] as! Int == 6)
    precondition(opsPrefix[1]["opcode"] as! Int == 8)
    precondition(opsPrefixSingle[1]["opcode"] as! Int == 4)
}

func testEntitlementsQueryMatchIntegerVariants() {
    let exact = EntitlementsQuery.key("count").matchSingle(Int64(7))
    let allowed = EntitlementsQuery.key("count").match(Int64(7))
    let dataExact = try! JSONEncoder().encode(exact)
    let dataAllowed = try! JSONEncoder().encode(allowed)
    let opsExact = (try! JSONSerialization.jsonObject(with: dataExact) as! [String: Any])["entitlements"] as! [[String: Any]]
    let opsAllowed = (try! JSONSerialization.jsonObject(with: dataAllowed) as! [String: Any])["entitlements"] as! [[String: Any]]
    precondition(opsExact[1]["opcode"] as! Int == 7)
    precondition(opsExact[1]["integer"] as! Int == 7)
    precondition(opsAllowed[1]["opcode"] as! Int == 10)
}

func testEntitlementsQueryMatchType() {
    let query = EntitlementsQuery.key("payload").matchType(.array)
    let data = try! JSONEncoder().encode(query)
    let ops = (try! JSONSerialization.jsonObject(with: data) as! [String: Any])["entitlements"] as! [[String: Any]]
    precondition(ops[1]["opcode"] as! Int == 11)
    precondition(ops[1]["integer"] as! Int == 2)
}

func testEntitlementsQueryDataTypeRawValues() {
    precondition(EntitlementsQuery.DataType.dictionary.rawValue == 1)
    precondition(EntitlementsQuery.DataType.array.rawValue == 2)
    precondition(EntitlementsQuery.DataType.integer.rawValue == 3)
    precondition(EntitlementsQuery.DataType.string.rawValue == 4)
    precondition(EntitlementsQuery.DataType.boolean.rawValue == 5)
    precondition(EntitlementsQuery.DataType(rawValue: 1) == .dictionary)
    precondition(EntitlementsQuery.DataType(rawValue: 99) == nil)
    precondition(EntitlementsQuery.DataType.array != .string)
    var hasher = Hasher()
    EntitlementsQuery.DataType.boolean.hash(into: &hasher)
    precondition(EntitlementsQuery.DataType.boolean.hashValue == EntitlementsQuery.DataType.boolean.hashValue)
    let _: EntitlementsQuery.DataType.RawValue = EntitlementsQuery.DataType.integer.rawValue
}

func testEntitlementsQueryCodableRoundTrip() {
    let original = EntitlementsQuery
        .key("com.apple.application-identifier")
        .matchSingle("com.apple.TextEdit")
    let decoded = try! lcrRoundTrip(original)
    let data = try! JSONEncoder().encode(decoded)
    let ops = (try! JSONSerialization.jsonObject(with: data) as! [String: Any])["entitlements"] as! [[String: Any]]
    precondition(ops.count == 2)
    precondition(ops[0]["string"] as! String == "com.apple.application-identifier")
    precondition(ops[1]["opcode"] as! Int == 3)
}

func testEntitlementsQueryPresenceOnly() {
    let query = EntitlementsQuery.key("com.apple.private.hid.client.event-dispatch.internal")
    let data = try! JSONEncoder().encode(query)
    let ops = (try! JSONSerialization.jsonObject(with: data) as! [String: Any])["entitlements"] as! [[String: Any]]
    precondition(ops.count == 1)
    precondition(ops[0]["opcode"] as! Int == 1)
}

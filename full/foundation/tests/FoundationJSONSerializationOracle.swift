#if JSONSERIALIZATION_PORT
import JSONSerializationPort
import Foundation
private typealias TestJSONSerialization = JSONSerializationPort.JSONSerialization
#else
import Foundation
private typealias TestJSONSerialization = JSONSerialization
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

private func flatten(_ string: String) -> String {
    var output = ""
    for character in string {
        if character == "\n" {
            output.append("|")
        } else if character == " " {
            output.append("·")
        } else {
            output.append(character)
        }
    }
    return output
}

private func jsonText(_ data: Data) -> String {
    String(data: data, encoding: .utf8) ?? "nil"
}

do {
    let source = Data(
        "{\"s\":\"x\",\"i\":7,\"d\":1.25,\"b\":true,\"n\":null,\"a\":[1,\"z\"]}".utf8
    )
    let decoded = try TestJSONSerialization.jsonObject(with: source) as! [String: Any]
    emit("json.string", decoded["s"] as! String)
    emit("json.integer", decoded["i"] as! Int)
    emit("json.double", decoded["d"] as! Double)
    emit("json.bool", decoded["b"] as! Bool)
    emit("json.null", decoded["n"] is NSNull)
    let array = decoded["a"] as! [Any]
    emit("json.array", "\(array[0] as! Int):\(array[1] as! String)")

    let object: [String: Any] = [
        "z": "https://example.test/a/b",
        "a": [true, NSNull(), 2],
    ]
    let sorted = try TestJSONSerialization.data(
        withJSONObject: object,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    emit("json.sorted", jsonText(sorted))
    let pretty = try TestJSONSerialization.data(
        withJSONObject: ["b": 2, "a": 1],
        options: [.sortedKeys, .prettyPrinted]
    )
    emit("json.pretty", flatten(jsonText(pretty)))
    emit("json.valid.object", TestJSONSerialization.isValidJSONObject(object))
    emit("json.valid.scalar", TestJSONSerialization.isValidJSONObject("x"))
    emit("json.valid.nan", TestJSONSerialization.isValidJSONObject(["x": Double.nan]))
    emit("json.valid.inf", TestJSONSerialization.isValidJSONObject([Double.infinity]))

    let fragment = try TestJSONSerialization.jsonObject(
        with: Data("17".utf8),
        options: .fragmentsAllowed
    )
    emit("json.fragment", fragment as! Int)
    let writtenFragment = try TestJSONSerialization.data(
        withJSONObject: 17,
        options: .fragmentsAllowed
    )
    emit("json.fragment.write", jsonText(writtenFragment))
    let writtenString = try TestJSONSerialization.data(
        withJSONObject: "hi",
        options: .fragmentsAllowed
    )
    emit("json.fragment.str", jsonText(writtenString))

    do {
        _ = try TestJSONSerialization.jsonObject(with: Data("17".utf8))
        emit("json.fragment-error", "missing")
    } catch {
        let error = error as NSError
        emit("json.fragment-error", "\(error.domain):\(error.code)")
    }
    do {
        _ = try TestJSONSerialization.jsonObject(with: Data("{".utf8))
        emit("json.syntax-error", "missing")
    } catch {
        let error = error as NSError
        emit("json.syntax-error", "\(error.domain):\(error.code)")
        emit(
            "json.syntax-index",
            error.userInfo["NSJSONSerializationErrorIndex"] as? Int ?? -1
        )
        emit(
            "json.syntax-debug",
            error.userInfo[NSDebugDescriptionErrorKey] != nil
        )
    }
    do {
        _ = try TestJSONSerialization.jsonObject(with: Data("[1,2,]".utf8))
        emit("json.nested-ok", "yes")
    } catch {
        emit("json.nested-ok", "no")
    }

    let nested = try TestJSONSerialization.data(
        withJSONObject: ["outer": ["inner": [1, 2, 3]]] as [String: Any],
        options: .sortedKeys
    )
    emit("json.nested", jsonText(nested))
}

private let trailingDocuments = [
    #"{"a":1,}"#,
    #"[1,]"#,
    #"{"a":1, }"#,
    #"[1, ]"#,
    #"[1,2,]"#,
    #"{"a":1,"b":2,}"#,
    #"[[1,],]"#,
    #"[{"a":1,},]"#,
    #"[1,{"a":1,}]"#,
    #"{"a":[1,],}"#,
    #"{"a":{"b":1,},}"#,
    #"[1, 2, 3,]"#,
    #"[true,]"#,
    #"[null,]"#,
    #"["x",]"#,
    #"{"a":true,}"#,
]
for (index, document) in trailingDocuments.enumerated() {
    do {
        let value = try TestJSONSerialization.jsonObject(with: Data(document.utf8))
        let back = try TestJSONSerialization.data(
            withJSONObject: value,
            options: .sortedKeys
        )
        emit("trail.\(index).ok", jsonText(back))
    } catch {
        let error = error as NSError
        emit("trail.\(index).err", "\(error.domain):\(error.code)")
    }
}

private let rejectedDocuments = [
    #"{"a":1,,}"#,
    #"[1,,]"#,
    #"{,}"#,
    #"[,]"#,
]
for (index, document) in rejectedDocuments.enumerated() {
    do {
        _ = try TestJSONSerialization.jsonObject(with: Data(document.utf8))
        emit("trail-reject.\(index)", "accepted")
    } catch {
        let error = error as NSError
        emit("trail-reject.\(index)", "\(error.domain):\(error.code)")
    }
}

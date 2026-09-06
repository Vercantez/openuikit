import Foundation
import BusinessChat

func testParameterType() {
    let parameter = BCChatAction.Parameter("custom")
    precondition(type(of: parameter) == BCChatAction.Parameter.self)
    precondition(parameter.rawValue == "custom")
    var keyed: [BCChatAction.Parameter: String] = [:]
    keyed[parameter] = "value"
    precondition(keyed[BCChatAction.Parameter("custom")] == "value")
}

func testParameterIntent() {
    precondition(BCChatAction.Parameter.intent.rawValue == "BCParameterNameIntent")
    precondition(BCChatAction.Parameter.intent == BCChatAction.Parameter(rawValue: "BCParameterNameIntent"))
    precondition(BCChatAction.Parameter.intent != .group)
    precondition(BCChatAction.Parameter.intent != .body)
}

func testParameterGroup() {
    precondition(BCChatAction.Parameter.group.rawValue == "BCParameterNameGroup")
    precondition(BCChatAction.Parameter.group == BCChatAction.Parameter("BCParameterNameGroup"))
    precondition(BCChatAction.Parameter.group != .intent)
    precondition(BCChatAction.Parameter.group != .body)
}

func testParameterBody() {
    precondition(BCChatAction.Parameter.body.rawValue == "BCParameterNameBody")
    precondition(BCChatAction.Parameter.body == BCChatAction.Parameter(rawValue: "BCParameterNameBody"))
    precondition(BCChatAction.Parameter.body != .intent)
    precondition(BCChatAction.Parameter.body != .group)
}

func testParameterInitRawValue() {
    let parameter = BCChatAction.Parameter(rawValue: "com.example.raw")
    precondition(parameter.rawValue == "com.example.raw")
    let empty = BCChatAction.Parameter(rawValue: "")
    precondition(empty.rawValue.isEmpty)
    precondition(BCChatAction.Parameter(rawValue: "BCParameterNameIntent") == .intent)
}

func testParameterInitString() {
    let parameter = BCChatAction.Parameter("com.example.string")
    precondition(parameter.rawValue == "com.example.string")
    let fromRaw = BCChatAction.Parameter(rawValue: "com.example.string")
    precondition(parameter == fromRaw)
    precondition(BCChatAction.Parameter("BCParameterNameGroup") == .group)
}

func testParameterInequality() {
    let left = BCChatAction.Parameter("alpha")
    let right = BCChatAction.Parameter("beta")
    let same = BCChatAction.Parameter(rawValue: "alpha")
    precondition(left != right)
    precondition(right != left)
    precondition(!(left != same))
    precondition(left == same)
    precondition(BCChatAction.Parameter.intent != .body)
}

func testParameterHashValue() {
    let left = BCChatAction.Parameter("hash-me")
    let same = BCChatAction.Parameter(rawValue: "hash-me")
    let other = BCChatAction.Parameter("other")
    precondition(left.hashValue == same.hashValue)
    precondition(left.hashValue != other.hashValue)
    precondition(BCChatAction.Parameter.intent.hashValue == BCChatAction.Parameter.intent.hashValue)
    _ = left.hashValue
}

func testParameterHashInto() {
    let parameter = BCChatAction.Parameter("into")
    var hasherA = Hasher()
    parameter.hash(into: &hasherA)
    var hasherB = Hasher()
    parameter.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    var hasherOther = Hasher()
    BCChatAction.Parameter("other").hash(into: &hasherOther)
    var hasherAgain = Hasher()
    parameter.hash(into: &hasherAgain)
    precondition(hasherOther.finalize() != hasherAgain.finalize())
}

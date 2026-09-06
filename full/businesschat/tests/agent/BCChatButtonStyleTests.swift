import Foundation
import BusinessChat

func testStyleType() {
    let values: [BCChatButton.Style] = [.light, .dark]
    precondition(values.count == 2)
    precondition(type(of: BCChatButton.Style.light) == BCChatButton.Style.self)
    precondition(type(of: BCChatButton.Style.dark) == BCChatButton.Style.self)
}

func testStyleCases() {
    let table: [(BCChatButton.Style, Int)] = [
        (.light, 0),
        (.dark, 1),
    ]
    precondition(Set(table.map(\.0)).count == 2)
    precondition(Set(table.map(\.1)).count == 2)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(BCChatButton.Style(rawValue: raw) == value)
    }
}

func testStyleInitRawValue() {
    precondition(BCChatButton.Style(rawValue: 0) == .light)
    precondition(BCChatButton.Style(rawValue: 1) == .dark)
    precondition(BCChatButton.Style(rawValue: 2) == nil)
    precondition(BCChatButton.Style(rawValue: -1) == nil)
    precondition(BCChatButton.Style(rawValue: Int.max) == nil)
}

func testStyleInequality() {
    precondition(BCChatButton.Style.light != .dark)
    precondition(BCChatButton.Style.dark != .light)
    precondition(!(BCChatButton.Style.light != .light))
    precondition(!(BCChatButton.Style.dark != .dark))
    precondition(BCChatButton.Style.light == .light)
    precondition(BCChatButton.Style.dark == .dark)
}

func testStyleHashValue() {
    precondition(BCChatButton.Style.light.hashValue == BCChatButton.Style.light.hashValue)
    precondition(BCChatButton.Style.dark.hashValue == BCChatButton.Style.dark.hashValue)
    precondition(BCChatButton.Style.light.hashValue != BCChatButton.Style.dark.hashValue)
    _ = BCChatButton.Style.dark.hashValue
}

func testStyleHashInto() {
    var hasherA = Hasher()
    BCChatButton.Style.dark.hash(into: &hasherA)
    var hasherB = Hasher()
    BCChatButton.Style.dark.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    var hasherLight = Hasher()
    BCChatButton.Style.light.hash(into: &hasherLight)
    var hasherDark = Hasher()
    BCChatButton.Style.dark.hash(into: &hasherDark)
    precondition(hasherLight.finalize() != hasherDark.finalize())
}

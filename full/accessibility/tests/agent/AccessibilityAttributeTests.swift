import Foundation
import Accessibility

private struct AttributeBox: Encodable {
    let encodeValue: (any Encoder) throws -> Void
    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}

func testAccessibilityAttributeScope() {
    _ = AttributeScopes.AccessibilityAttributes.decodingConfiguration
    _ = AttributeScopes.AccessibilityAttributes.encodingConfiguration
    let keys = Array(AttributeScopes.AccessibilityAttributes.attributeKeys)
    precondition(keys.count == 9)
    _ = \AttributeScopes.AccessibilityAttributes.accessibilityTextCustom
    _ = \AttributeScopes.AccessibilityAttributes.accessibilityHeadingLevel
    _ = \AttributeScopes.AccessibilityAttributes.accessibilityTextualContext
    _ = \AttributeScopes.AccessibilityAttributes.accessibilitySpeechAdjustedPitch
    _ = \AttributeScopes.AccessibilityAttributes.accessibilitySpeechPhoneticNotation
    _ = \AttributeScopes.AccessibilityAttributes.accessibilitySpeechAnnouncementsQueued
    _ = \AttributeScopes.AccessibilityAttributes.accessibilitySpeechIncludesPunctuation
    _ = \AttributeScopes.AccessibilityAttributes.accessibilitySpeechSpellsOutCharacters
    _ = \AttributeScopes.AccessibilityAttributes.accessibilitySpeechAnnouncementPriority
    _ = \AttributeScopes.accessibility
}

func testTextCustomAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.TextCustomAttribute
    precondition(Key.name == "UIAccessibilityTextAttributeCustom")
    precondition(Key.markdownName == "accessibilityTextCustom")
    precondition(!Key.name.isEmpty)
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilityTextCustom = ["alt"]
    precondition(attributed.accessibilityTextCustom == ["alt"])
    attributed[Key.self] = ["viaKey"]
    precondition(attributed[Key.self] == ["viaKey"])
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode(["alt"], to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

func testIPANotationAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.IPANotationAttribute
    precondition(Key.name == "UIAccessibilitySpeechAttributeIPANotation")
    precondition(Key.markdownName == "accessibilitySpeechPhoneticNotation")
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilitySpeechPhoneticNotation = "həˈloʊ"
    precondition(attributed.accessibilitySpeechPhoneticNotation == "həˈloʊ")
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode("həˈloʊ", to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

func testHeadingLevelAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.HeadingLevelAttribute
    precondition(Key.name == "UIAccessibilityTextAttributeHeadingLevel")
    precondition(Key.markdownName == "accessibilityHeadingLevel")
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = Key.ObjectiveCValue.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilityHeadingLevel = .h2
    precondition(attributed.accessibilityHeadingLevel == .h2)
    let objc = try! Key.objectiveCValue(for: .h3)
    precondition(objc.intValue == 3)
    let back = try! Key.value(for: objc)
    precondition(back == .h3)
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode(.h1, to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

func testAdjustedPitchAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.AdjustedPitchAttribute
    precondition(Key.name == "UIAccessibilitySpeechAttributePitch")
    precondition(Key.markdownName == "accessibilitySpeechAdjustedPitch")
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = Key.ObjectiveCValue.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilitySpeechAdjustedPitch = 0.25
    precondition(attributed.accessibilitySpeechAdjustedPitch == 0.25)
    let objc = try! Key.objectiveCValue(for: 0.5)
    precondition(objc.doubleValue == 0.5)
    let back = try! Key.value(for: objc)
    precondition(back == 0.5)
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode(0.25, to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

func testTextualContextAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.TextualContextAttribute
    precondition(Key.name == "UIAccessibilityTextAttributeContext")
    precondition(Key.markdownName == "accessibilityTextualContext")
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = Key.ObjectiveCValue.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilityTextualContext = .sourceCode
    precondition(attributed.accessibilityTextualContext == .sourceCode)
    let objc = try! Key.objectiveCValue(for: .console)
    precondition((objc as String) == "console")
    let back = try! Key.value(for: objc)
    precondition(back == .console)
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode(.plain, to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

func testQueueAnnouncementAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.QueueAnnouncementAttribute
    precondition(Key.name == "UIAccessibilitySpeechAttributeQueueAnnouncement")
    precondition(Key.markdownName == "accessibilitySpeechAnnouncementsQueued")
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilitySpeechAnnouncementsQueued = true
    precondition(attributed.accessibilitySpeechAnnouncementsQueued == true)
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode(true, to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

func testIncludesPunctuationAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.IncludesPunctuationAttribute
    precondition(Key.name == "UIAccessibilitySpeechAttributePunctuation")
    precondition(Key.markdownName == "accessibilitySpeechIncludesPunctuation")
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilitySpeechIncludesPunctuation = true
    precondition(attributed.accessibilitySpeechIncludesPunctuation == true)
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode(false, to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

func testAnnouncementPriorityAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.AnnouncementPriorityAttribute
    precondition(Key.name == "UIAccessibilitySpeechAttributeAnnouncementPriority")
    precondition(Key.markdownName == "accessibilitySpeechAnnouncementPriority")
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = Key.ObjectiveCValue.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilitySpeechAnnouncementPriority = .high
    precondition(attributed.accessibilitySpeechAnnouncementPriority == .high)
    let objc = try! Key.objectiveCValue(for: .low)
    precondition((objc as String) == "low")
    let back = try! Key.value(for: objc)
    precondition(back == .low)
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode(.default, to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

func testSpellOutAttribute() {
    typealias Key = AttributeScopes.AccessibilityAttributes.SpellOutAttribute
    precondition(Key.name == "UIAccessibilitySpeechAttributeSpellOut")
    precondition(Key.markdownName == "accessibilitySpeechSpellsOutCharacters")
    _ = Key.runBoundaries
    _ = Key.inheritedByAddedText
    _ = Key.invalidationConditions
    _ = Key.Value.self
    _ = String(describing: Key.self)
    var attributed = AttributedString("hello")
    attributed.accessibilitySpeechSpellsOutCharacters = true
    precondition(attributed.accessibilitySpeechSpellsOutCharacters == true)
    let encoded = try! JSONEncoder().encode(AttributeBox(encodeValue: { encoder in
        try Key.encode(true, to: encoder)
    }))
    struct Probe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try Key.decode(from: decoder)
            _ = try Key.decodeMarkdown(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(Probe.self, from: encoded)
}

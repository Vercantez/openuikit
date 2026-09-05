@_spi(OpenUIKitHost) import Speech
import Foundation

private struct SpeechAttributeBox: Encodable {
    let encodeValue: (any Encoder) throws -> Void
    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}

func testSpeechAttributesScope() {
    let scope = AttributeScopes.SpeechAttributes()
    _ = scope.transcriptionConfidence
    _ = scope.audioTimeRange
}

func testSpeechConfidenceAttribute() {
    let key = AttributeScopes.SpeechAttributes.ConfidenceAttribute.self
    precondition(key.name.isEmpty == false)
    var attributed = AttributedString("hello")
    attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] = 0.9
    precondition(attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] == 0.9)
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.runBoundaries
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.inheritedByAddedText
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.invalidationConditions
    _ = String(describing: AttributeScopes.SpeechAttributes.ConfidenceAttribute.self)
    _ = AttributeScopes.SpeechAttributes.ConfidenceAttribute.Value.self
    let encoded = try! JSONEncoder().encode(
        SpeechAttributeBox(encodeValue: { encoder in
            try AttributeScopes.SpeechAttributes.ConfidenceAttribute.encode(0.9, to: encoder)
        })
    )
    struct ConfidenceProbe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try AttributeScopes.SpeechAttributes.ConfidenceAttribute.decode(from: decoder)
        }
    }
    _ = try? JSONDecoder().decode(ConfidenceProbe.self, from: encoded)
}

func testSpeechTimeRangeAttribute() {
    var timed = AttributedString("hello")
    let range = SpeechHostTimeRange(start: 0, duration: 0.4)
    timed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] = range
    precondition(timed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] == range)
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.name
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.runBoundaries
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.inheritedByAddedText
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.invalidationConditions
    _ = AttributeScopes.SpeechAttributes.TimeRangeAttribute.Value.self
    let encoded = try! JSONEncoder().encode(range)
    let decoded = try! JSONDecoder().decode(SpeechHostTimeRange.self, from: encoded)
    precondition(decoded == range)
    let boxed = try! JSONEncoder().encode(
        SpeechAttributeBox(encodeValue: { encoder in
            try AttributeScopes.SpeechAttributes.TimeRangeAttribute.encode(range, to: encoder)
        })
    )
    struct TimeRangeProbe: Decodable {
        init(from decoder: Decoder) throws {
            _ = try AttributeScopes.SpeechAttributes.TimeRangeAttribute.decode(from: decoder)
        }
    }
    let roundTrip = try? JSONDecoder().decode(TimeRangeProbe.self, from: boxed)
    _ = roundTrip
}

func testRangeOfAudioTimeRangeAttributes() {
    var timed = AttributedString("hello")
    let range = SpeechHostTimeRange(start: 0, duration: 0.4)
    timed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] = range
    let found = timed.rangeOfAudioTimeRangeAttributes(intersecting: SpeechHostTimeRange(start: 0.1, duration: 0.1))
    precondition(found != nil)
    let missed = timed.rangeOfAudioTimeRangeAttributes(intersecting: SpeechHostTimeRange(start: 9, duration: 1))
    precondition(missed == nil)
}

func testAttributeDynamicLookup() {
    var attributed = AttributedString("hello")
    attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] = 0.8
    precondition(attributed[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self] == 0.8)
    attributed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self] = SpeechHostTimeRange(
        start: 0,
        duration: 0.2
    )
    precondition(attributed[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self]?.start == 0)
    let keyPath = \AttributeScopes.SpeechAttributes.transcriptionConfidence
    precondition(type(of: keyPath) == KeyPath<AttributeScopes.SpeechAttributes, AttributeScopes.SpeechAttributes.ConfidenceAttribute>.self)
}

extension AttributeScopes {
    public struct SpeechAttributes: AttributeScope {
        public let transcriptionConfidence: ConfidenceAttribute
        public let audioTimeRange: TimeRangeAttribute

        public struct ConfidenceAttribute: CodableAttributedStringKey {
            public typealias Value = Double
            public static let name = "SwiftSpeech.transcriptionConfidence"
        }

        public struct TimeRangeAttribute: CodableAttributedStringKey {
            public typealias Value = CMTimeRange
            public static let name = "SwiftSpeech.audioTimeRange"

            public static func decode(from decoder: any Decoder) throws -> Value {
                try Value(from: decoder)
            }

            public static func encode(_ value: Value, to encoder: any Encoder) throws {
                try value.encode(to: encoder)
            }
        }
    }
}

extension AttributeDynamicLookup {
    public subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.SpeechAttributes, T>
    ) -> T {
        self[T.self]
    }
}

extension AttributedString {
    public func rangeOfAudioTimeRangeAttributes(
        intersecting timeRange: CMTimeRange
    ) -> Range<AttributedString.Index>? {
        var found: Range<AttributedString.Index>?
        for run in runs {
            if let runRange = run.audioTimeRange, runRange.intersects(timeRange) {
                if let existing = found {
                    found = existing.lowerBound..<run.range.upperBound
                } else {
                    found = run.range
                }
            }
        }
        return found
    }
}

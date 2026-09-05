import Foundation
#if canImport(CoreMedia)
import CoreMedia
#endif

extension AttributeScopes {
    public struct SpeechAttributes: AttributeScope {
        public let transcriptionConfidence: ConfidenceAttribute
        public let audioTimeRange: TimeRangeAttribute

        public init(
            transcriptionConfidence: ConfidenceAttribute = ConfidenceAttribute(),
            audioTimeRange: TimeRangeAttribute = TimeRangeAttribute()
        ) {
            self.transcriptionConfidence = transcriptionConfidence
            self.audioTimeRange = audioTimeRange
        }

        public struct ConfidenceAttribute: CodableAttributedStringKey {
            public typealias Value = Double
            public static let name = "SwiftUI.Speech.transcriptionConfidence"
            public init() {}
        }

        public struct TimeRangeAttribute: CodableAttributedStringKey {
            public typealias Value = SpeechTimeRange
            public static let name = "SwiftUI.Speech.audioTimeRange"

            public init() {}

            public static func decode(from decoder: any Decoder) throws -> Value {
                #if canImport(CoreMedia)
                _ = decoder
                throw speechFailClosedError(.internalServiceError)
                #else
                try SpeechHostTimeRange(from: decoder)
                #endif
            }

            public static func encode(_ value: Value, to encoder: any Encoder) throws {
                #if canImport(CoreMedia)
                _ = (value, encoder)
                throw speechFailClosedError(.internalServiceError)
                #else
                try value.encode(to: encoder)
                #endif
            }
        }
    }
}

extension AttributeDynamicLookup {
    public subscript<T>(dynamicMember keyPath: KeyPath<AttributeScopes.SpeechAttributes, T>) -> T
    where T: AttributedStringKey {
        self[T.self]
    }
}

extension AttributedString {
    public func rangeOfAudioTimeRangeAttributes(
        intersecting timeRange: SpeechTimeRange
    ) -> Range<AttributedString.Index>? {
        #if canImport(CoreMedia)
        _ = timeRange
        return nil
        #else
        for run in runs {
            if let stored = run[AttributeScopes.SpeechAttributes.TimeRangeAttribute.self],
               stored.intersects(timeRange) {
                return run.range
            }
        }
        return nil
        #endif
    }
}

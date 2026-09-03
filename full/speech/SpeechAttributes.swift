import Foundation
#if canImport(CoreMedia)
import CoreMedia
#endif

extension AttributeScopes {
    public struct SpeechAttributes: AttributeScope {
        public let transcriptionConfidence: ConfidenceAttribute

        public struct ConfidenceAttribute: CodableAttributedStringKey {
            public typealias Value = Double
            public static let name = "SwiftUI.Speech.transcriptionConfidence"
        }

#if canImport(CoreMedia)
        public let audioTimeRange: TimeRangeAttribute

        public struct TimeRangeAttribute: AttributedStringKey {
            public typealias Value = CMTimeRange
            public static let name = "SwiftUI.Speech.audioTimeRange"

            public static func decode(from decoder: any Decoder) throws -> Value {
                throw speechFailClosedError(.internalServiceError)
            }

            public static func encode(_ value: Value, to encoder: any Encoder) throws {
                _ = (value, encoder)
                throw speechFailClosedError(.internalServiceError)
            }
        }
#endif
    }
}

extension AttributeDynamicLookup {
    public subscript<T>(dynamicMember keyPath: KeyPath<AttributeScopes.SpeechAttributes, T>) -> T
    where T: AttributedStringKey {
        self[T.self]
    }
}

#if canImport(CoreMedia)
extension AttributedString {
    public func rangeOfAudioTimeRangeAttributes(
        intersecting timeRange: CMTimeRange
    ) -> Range<AttributedString.Index>? {
        _ = timeRange
        return nil
    }
}
#endif

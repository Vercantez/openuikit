import Foundation
import CoreMedia

extension AttributeScopes {
    public struct SpeechAttributes: AttributeScope {
        public let transcriptionConfidence: ConfidenceAttribute
        public let audioTimeRange: TimeRangeAttribute

        public struct ConfidenceAttribute: CodableAttributedStringKey {
            public typealias Value = Double
            public static let name = "SwiftSpeech.transcriptionConfidence"
        }

        public struct TimeRangeAttribute: AttributedStringKey, EncodableAttributedStringKey, DecodableAttributedStringKey {
            public typealias Value = CMTimeRange
            public static let name = "SwiftSpeech.audioTimeRange"

            public static func decode(from decoder: any Decoder) throws -> Value {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let start = try decodeTime(container.decode(TimePayload.self, forKey: .start))
                let duration = try decodeTime(container.decode(TimePayload.self, forKey: .duration))
                return CMTimeRange(start: start, duration: duration)
            }

            public static func encode(_ value: Value, to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(TimePayload(value.start), forKey: .start)
                try container.encode(TimePayload(value.duration), forKey: .duration)
            }

            private enum CodingKeys: String, CodingKey {
                case start
                case duration
            }

            private struct TimePayload: Codable {
                var value: Int64
                var timescale: Int32
                var flags: UInt32
                var epoch: Int64

                init(_ time: CMTime) {
                    value = time.value
                    timescale = time.timescale
                    flags = time.flags.rawValue
                    epoch = time.epoch
                }
            }

            private static func decodeTime(_ payload: TimePayload) throws -> CMTime {
                CMTime(
                    value: payload.value,
                    timescale: payload.timescale,
                    flags: CMTimeFlags(rawValue: payload.flags),
                    epoch: payload.epoch
                )
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
            if let runRange = run.audioTimeRange,
               speechTimeRangesIntersect(runRange, timeRange) {
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

private func speechTimeRangesIntersect(_ lhs: CMTimeRange, _ rhs: CMTimeRange) -> Bool {
    let intersection = CMTimeRangeGetIntersection(lhs, otherRange: rhs)
    return intersection.isValid && !intersection.isEmpty
}

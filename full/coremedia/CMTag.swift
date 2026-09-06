import CoreFoundation
import Foundation

/// Swift overlay of `CMTag` / `CMTypedTag`. Category FourCCs are Linux
/// stand-ins (`stvw`, `pack`, `pixf`, …); Apple's integers are unobserved
/// (see `oracle-questions.tsv`). Pixel-buffer tagged groups stay deferred
/// until CoreVideo supplies `CVPixelBuffer`.

public class CMTag: Hashable, CustomStringConvertible {
    public typealias RawCategory = FourCharCode

    public enum Value: Equatable, Hashable, Sendable {
        case flags(UInt64)
        case int64(Int64)
        case osType(UInt32)
        case float64(Float64)
    }

    public let rawCategory: RawCategory
    public let rawTagValue: Value

    public init(rawCategory: RawCategory, rawTagValue: Value) {
        self.rawCategory = rawCategory
        self.rawTagValue = rawTagValue
    }

    public var description: String {
        "CMTag(\(cmFourCCString(rawCategory)), \(rawTagValue))"
    }

    public static func == (lhs: CMTag, rhs: CMTag) -> Bool {
        lhs.rawCategory == rhs.rawCategory && lhs.rawTagValue == rhs.rawTagValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawCategory)
        hasher.combine(rawTagValue)
    }

    public func value<T>(onlyIfMatching category: CMTypedTag<T>.Category) -> T? where T: Sendable {
        guard rawCategory == category.rawCategory else { return nil }
        return category.value(for: rawTagValue)
    }

    public static func stereoView(_ value: CMStereoViewComponents) -> CMTypedTag<CMStereoViewComponents> {
        CMTypedTag(category: .stereoView, value: value)
    }

    public static func packingType(_ value: CMPackingType) -> CMTypedTag<CMPackingType> {
        CMTypedTag(category: .packingType, value: value)
    }

    public static func pixelFormat(_ value: UInt32) -> CMTypedTag<UInt32> {
        CMTypedTag(category: .pixelFormat, value: value)
    }

    public static func mediaSubType(
        _ value: CMFormatDescription.MediaSubType
    ) -> CMTypedTag<CMFormatDescription.MediaSubType> {
        CMTypedTag(category: .mediaSubType, value: value)
    }

    public static func videoLayerID(_ value: Int64) -> CMTypedTag<Int64> {
        CMTypedTag(category: .videoLayerID, value: value)
    }

    public static func projectionType(_ value: CMProjectionType) -> CMTypedTag<CMProjectionType> {
        CMTypedTag(category: .projectionType, value: value)
    }

    public static func stereoViewInterpretation(
        _ value: CMStereoViewInterpretationOptions
    ) -> CMTypedTag<CMStereoViewInterpretationOptions> {
        CMTypedTag(category: .stereoViewInterpretation, value: value)
    }

    public static func trackID(_ value: CMPersistentTrackID) -> CMTypedTag<CMPersistentTrackID> {
        CMTypedTag(category: .trackID, value: value)
    }

    public static func channelID(_ value: Int64) -> CMTypedTag<Int64> {
        CMTypedTag(category: .channelID, value: value)
    }

    public static func mediaType(
        _ value: CMFormatDescription.MediaType
    ) -> CMTypedTag<CMFormatDescription.MediaType> {
        CMTypedTag(category: .mediaType, value: value)
    }
}

public final class CMTypedTag<TypedValue: Sendable>: CMTag {
    public struct Category {
        public typealias RawCategory = FourCharCode
        public let rawCategory: RawCategory
        private let valueForTagValue: @Sendable (CMTag.Value) -> TypedValue?
        private let tagValueForValue: @Sendable (TypedValue) -> CMTag.Value

        public init(
            rawCategory: RawCategory,
            valueForTagValue: @escaping @Sendable (CMTag.Value) -> TypedValue?,
            tagValueForValue: @escaping @Sendable (TypedValue) -> CMTag.Value
        ) {
            self.rawCategory = rawCategory
            self.valueForTagValue = valueForTagValue
            self.tagValueForValue = tagValueForValue
        }

        public func value(for tagValue: CMTag.Value) -> TypedValue? {
            valueForTagValue(tagValue)
        }

        public func tagValue(for value: TypedValue) -> CMTag.Value {
            tagValueForValue(value)
        }
    }

    public let typedValue: TypedValue

    public init(category: Category, value: TypedValue) {
        self.typedValue = value
        super.init(rawCategory: category.rawCategory, rawTagValue: category.tagValue(for: value))
    }
}

extension CMTypedTag.Category where TypedValue == CMStereoViewComponents {
    public static var stereoView: CMTypedTag<CMStereoViewComponents>.Category {
        Self(
            rawCategory: cmFourCC("stvw"),
            valueForTagValue: { value in
                if case .flags(let bits) = value {
                    return CMStereoViewComponents(rawValue: bits)
                }
                return nil
            },
            tagValueForValue: { CMTag.Value.flags($0.rawValue) }
        )
    }
}

extension CMTypedTag.Category where TypedValue == CMPackingType {
    public static var packingType: CMTypedTag<CMPackingType>.Category {
        Self(
            rawCategory: cmFourCC("pack"),
            valueForTagValue: { value in
                if case .osType(let code) = value { return CMPackingType(rawValue: UInt64(code)) }
                return nil
            },
            tagValueForValue: { CMTag.Value.osType(UInt32(truncatingIfNeeded: $0.rawValue)) }
        )
    }
}

extension CMTypedTag.Category where TypedValue == UInt32 {
    public static var pixelFormat: CMTypedTag<UInt32>.Category {
        Self(
            rawCategory: cmFourCC("pixf"),
            valueForTagValue: { value in
                if case .osType(let code) = value { return code }
                return nil
            },
            tagValueForValue: { CMTag.Value.osType($0) }
        )
    }
}

extension CMTypedTag.Category where TypedValue == CMFormatDescription.MediaSubType {
    public static var mediaSubType: CMTypedTag<CMFormatDescription.MediaSubType>.Category {
        Self(
            rawCategory: cmFourCC("msub"),
            valueForTagValue: { value in
                if case .osType(let code) = value {
                    return CMFormatDescription.MediaSubType(rawValue: code)
                }
                return nil
            },
            tagValueForValue: { CMTag.Value.osType($0.rawValue) }
        )
    }
}

extension CMTypedTag.Category where TypedValue == Int64 {
    public static var videoLayerID: CMTypedTag<Int64>.Category {
        Self(
            rawCategory: cmFourCC("vlyr"),
            valueForTagValue: { value in
                if case .int64(let number) = value { return number }
                return nil
            },
            tagValueForValue: { CMTag.Value.int64($0) }
        )
    }

    public static var channelID: CMTypedTag<Int64>.Category {
        Self(
            rawCategory: cmFourCC("chnl"),
            valueForTagValue: { value in
                if case .int64(let number) = value { return number }
                return nil
            },
            tagValueForValue: { CMTag.Value.int64($0) }
        )
    }
}

extension CMTypedTag.Category where TypedValue == CMProjectionType {
    public static var projectionType: CMTypedTag<CMProjectionType>.Category {
        Self(
            rawCategory: cmFourCC("proj"),
            valueForTagValue: { value in
                if case .osType(let code) = value { return CMProjectionType(rawValue: UInt64(code)) }
                return nil
            },
            tagValueForValue: { CMTag.Value.osType(UInt32(truncatingIfNeeded: $0.rawValue)) }
        )
    }
}

extension CMTypedTag.Category where TypedValue == CMStereoViewInterpretationOptions {
    public static var stereoViewInterpretation: CMTypedTag<CMStereoViewInterpretationOptions>.Category {
        Self(
            rawCategory: cmFourCC("svi "),
            valueForTagValue: { value in
                if case .flags(let bits) = value {
                    return CMStereoViewInterpretationOptions(rawValue: bits)
                }
                return nil
            },
            tagValueForValue: { CMTag.Value.flags($0.rawValue) }
        )
    }
}

extension CMTypedTag.Category where TypedValue == CMPersistentTrackID {
    public static var trackID: CMTypedTag<CMPersistentTrackID>.Category {
        Self(
            rawCategory: cmFourCC("trak"),
            valueForTagValue: { value in
                if case .int64(let number) = value { return CMPersistentTrackID(number) }
                return nil
            },
            tagValueForValue: { CMTag.Value.int64(Int64($0)) }
        )
    }
}

extension CMTypedTag.Category where TypedValue == CMFormatDescription.MediaType {
    public static var mediaType: CMTypedTag<CMFormatDescription.MediaType>.Category {
        Self(
            rawCategory: cmFourCC("mdia"),
            valueForTagValue: { value in
                if case .osType(let code) = value {
                    return CMFormatDescription.MediaType(rawValue: code)
                }
                return nil
            },
            tagValueForValue: { CMTag.Value.osType($0.rawValue) }
        )
    }
}

public struct CMTaggedBuffer: CustomStringConvertible {
    public enum Buffer {
        case sampleBuffer(CMSampleBuffer)
    }

    public let tags: [CMTag]
    public let buffer: Buffer

    public init(tags: [CMTag], sampleBuffer: CMSampleBuffer) {
        self.tags = tags
        self.buffer = .sampleBuffer(sampleBuffer)
    }

    public init(tags: [CMTag], buffer: Buffer) {
        self.tags = tags
        self.buffer = buffer
    }

    public var description: String {
        "CMTaggedBuffer(tags: \(tags.count))"
    }
}

extension Sequence where Element == CMTag {
    public func first<T>(matchingCategory category: CMTypedTag<T>.Category) -> CMTypedTag<T>? where T: Sendable {
        for tag in self {
            if let typed = tag as? CMTypedTag<T>, typed.rawCategory == category.rawCategory {
                return typed
            }
            if tag.rawCategory == category.rawCategory, let value = category.value(for: tag.rawTagValue) {
                return CMTypedTag(category: category, value: value)
            }
        }
        return nil
    }

    public func firstValue<T>(matchingCategory category: CMTypedTag<T>.Category) -> T? where T: Sendable {
        first(matchingCategory: category)?.typedValue
    }

    public func filter<T>(matchingCategory category: CMTypedTag<T>.Category) -> [CMTypedTag<T>] where T: Sendable {
        var result: [CMTypedTag<T>] = []
        for tag in self {
            if let typed = tag as? CMTypedTag<T>, typed.rawCategory == category.rawCategory {
                result.append(typed)
            } else if tag.rawCategory == category.rawCategory,
                      let value = category.value(for: tag.rawTagValue) {
                result.append(CMTypedTag(category: category, value: value))
            }
        }
        return result
    }
}

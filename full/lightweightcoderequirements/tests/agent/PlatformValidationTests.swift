import Foundation
import LightweightCodeRequirements

func testPlatformTypeRawValues() {
    let pairs: [(PlatformType.Value, Int64)] = [
        (.macOS, 1),
        (.iOS, 2),
        (.tvOS, 3),
        (.watchOS, 4),
        (.macCatalyst, 6),
        (.iOSSimulator, 7),
        (.tvOSSimulator, 8),
        (.watchOSSimulator, 9),
        (.driverKit, 10),
        (.visionOS, 11),
        (.visionOSSimulator, 12),
    ]
    for (value, raw) in pairs {
        precondition(value.rawValue == raw)
        precondition(PlatformType.Value(rawValue: raw) == value)
    }
    precondition(PlatformType.Value(rawValue: 0) == nil)
    precondition(PlatformType.Value(rawValue: 5) == nil)
    precondition(PlatformType.Value.iOS != PlatformType.Value.macOS)
}

func testPlatformTypeHashable() {
    var hasher = Hasher()
    PlatformType.Value.iOS.hash(into: &hasher)
    precondition(PlatformType.Value.iOS.hashValue == PlatformType.Value.iOS.hashValue)
    precondition(PlatformType.Value.iOS.hashValue != PlatformType.Value.tvOS.hashValue)
}

func testPlatformTypeInitAndIn() {
    let single = PlatformType(.iOS)
    precondition(single.values == [.iOS])
    let variadic = PlatformType.in(.iOS, .macOS)
    precondition(variadic.values == [.iOS, .macOS])
    let arrayed = PlatformType.in([.tvOS, .watchOS])
    precondition(arrayed.values == [.tvOS, .watchOS])
    let _: PlatformType.OutType = single
    let _: PlatformType.DataType = .iOS
}

func testPlatformTypeCodable() {
    let original = PlatformType.in(.iOS, .iOSSimulator)
    let decoded = try! lcrRoundTrip(original)
    precondition(decoded.values == original.values)
    let value = try! lcrRoundTrip(PlatformType.Value.visionOS)
    precondition(value == .visionOS)
}

func testValidationCategoryRawValues() {
    let pairs: [(ValidationCategory.Value, Int64)] = [
        (.platform, 1),
        (.testflight, 2),
        (.development, 3),
        (.appStore, 4),
        (.enterprise, 5),
        (.developerID, 6),
        (.none, 10),
    ]
    for (value, raw) in pairs {
        precondition(value.rawValue == raw)
        precondition(ValidationCategory.Value(rawValue: raw) == value)
    }
    precondition(ValidationCategory.Value(rawValue: 0) == nil)
    precondition(ValidationCategory.Value(rawValue: 7) == nil)
    precondition(ValidationCategory.Value.platform != ValidationCategory.Value.none)
}

func testValidationCategoryHashable() {
    var hasher = Hasher()
    ValidationCategory.Value.appStore.hash(into: &hasher)
    precondition(ValidationCategory.Value.appStore.hashValue == ValidationCategory.Value.appStore.hashValue)
}

func testValidationCategoryInitAndIn() {
    let single = ValidationCategory(.development)
    precondition(single.values == [.development])
    let variadic = ValidationCategory.in(.appStore, .testflight)
    precondition(variadic.values == [.appStore, .testflight])
    let arrayed = ValidationCategory.in([.enterprise, .developerID])
    precondition(arrayed.values == [.enterprise, .developerID])
    let _: ValidationCategory.OutType = single
    let _: ValidationCategory.DataType = .platform
}

func testValidationCategoryCodable() {
    let original = ValidationCategory.in(.platform, .appStore)
    let decoded = try! lcrRoundTrip(original)
    precondition(decoded.values == original.values)
    let value = try! lcrRoundTrip(ValidationCategory.Value.none)
    precondition(value == .none)
}

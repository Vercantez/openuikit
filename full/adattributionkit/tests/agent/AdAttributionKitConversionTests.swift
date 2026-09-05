import AdAttributionKit
import Foundation

func testCoarseConversionValueCases() {
    let cases: [CoarseConversionValue] = [.low, .medium, .high]
    precondition(cases.count == 3)
    precondition(Set(cases).count == 3)
    _ = CoarseConversionValue.self
}

func testCoarseConversionValueRawValue() {
    precondition(CoarseConversionValue.RawValue.self == String.self)
    precondition(CoarseConversionValue.low.rawValue == "low")
    precondition(CoarseConversionValue.medium.rawValue == "medium")
    precondition(CoarseConversionValue.high.rawValue == "high")
    precondition(CoarseConversionValue(rawValue: "low") == .low)
    precondition(CoarseConversionValue(rawValue: "medium") == .medium)
    precondition(CoarseConversionValue(rawValue: "high") == .high)
    precondition(CoarseConversionValue(rawValue: "LOW") == nil)
    precondition(CoarseConversionValue(rawValue: "High") == nil)
    precondition(CoarseConversionValue(rawValue: "") == nil)
}

func testCoarseConversionValueEquatable() {
    precondition(CoarseConversionValue.low != .high)
    precondition(CoarseConversionValue.medium != .low)
    precondition(CoarseConversionValue.high != .medium)
    precondition(CoarseConversionValue.low == .low)
    precondition(!(CoarseConversionValue.low != .low))
}

func testCoarseConversionValueHashable() {
    var hasher = Hasher()
    CoarseConversionValue.high.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(CoarseConversionValue.low.hashValue == CoarseConversionValue.low.hashValue)
    precondition(Set([CoarseConversionValue.low, .medium, .high]).count == 3)
}

func testCoarseConversionValueCodable() {
    let encodedLow = try! JSONEncoder().encode(CoarseConversionValue.low)
    let decodedLow = try! JSONDecoder().decode(CoarseConversionValue.self, from: encodedLow)
    precondition(decodedLow == .low)
    let quotedMedium = try! JSONEncoder().encode(CoarseConversionValue.medium)
    precondition(String(data: quotedMedium, encoding: .utf8) == "\"medium\"")
    let quotedHigh = try! JSONEncoder().encode(CoarseConversionValue.high)
    precondition(String(data: quotedHigh, encoding: .utf8) == "\"high\"")
    let decodedHigh = try! JSONDecoder().decode(
        CoarseConversionValue.self,
        from: Data("\"high\"".utf8)
    )
    precondition(decodedHigh == .high)
}

func testConversionTypeCases() {
    let cases: [PostbackUpdate.ConversionType] = [.install, .reengagement]
    precondition(cases.count == 2)
    precondition(Set(cases).count == 2)
    _ = PostbackUpdate.ConversionType.self
}

func testConversionTypeRawValue() {
    precondition(PostbackUpdate.ConversionType.RawValue.self == String.self)
    precondition(PostbackUpdate.ConversionType.install.rawValue == "install")
    precondition(PostbackUpdate.ConversionType.reengagement.rawValue == "reengagement")
    precondition(PostbackUpdate.ConversionType(rawValue: "install") == .install)
    precondition(PostbackUpdate.ConversionType(rawValue: "reengagement") == .reengagement)
    precondition(PostbackUpdate.ConversionType(rawValue: "re-engagement") == nil)
    precondition(PostbackUpdate.ConversionType(rawValue: "download") == nil)
    precondition(PostbackUpdate.ConversionType(rawValue: "redownload") == nil)
}

func testConversionTypeEquatable() {
    precondition(PostbackUpdate.ConversionType.install != .reengagement)
    precondition(PostbackUpdate.ConversionType.install == .install)
    precondition(!(PostbackUpdate.ConversionType.reengagement != .reengagement))
}

func testConversionTypeHashable() {
    var hasher = Hasher()
    PostbackUpdate.ConversionType.install.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        PostbackUpdate.ConversionType.install.hashValue
            == PostbackUpdate.ConversionType.install.hashValue
    )
    precondition(Set([PostbackUpdate.ConversionType.install, .reengagement]).count == 2)
}

func testPostbackUpdateUntaggedInit() {
    let install = PostbackUpdate(
        fineConversionValue: 20,
        lockPostback: false,
        conversionTypes: [.install]
    )
    precondition(install.fineConversionValue == 20)
    precondition(install.lockPostback == false)
    precondition(install.coarseConversionValue == nil)
    precondition(install.conversionTypes == [.install])
    precondition(install.conversionTag == nil)

    let defaults = PostbackUpdate(fineConversionValue: 0, lockPostback: false)
    precondition(defaults.fineConversionValue == 0)
    precondition(defaults.lockPostback == false)
    precondition(defaults.coarseConversionValue == nil)
    precondition(defaults.conversionTypes == nil)
    precondition(defaults.conversionTag == nil)
    _ = PostbackUpdate.self
}

func testPostbackUpdateTaggedInit() {
    let tagged = PostbackUpdate(
        fineConversionValue: 12,
        lockPostback: true,
        conversionTag: "campaign-tag",
        coarseConversionValue: .high,
        conversionTypes: [.reengagement]
    )
    precondition(tagged.fineConversionValue == 12)
    precondition(tagged.lockPostback == true)
    precondition(tagged.conversionTag == "campaign-tag")
    precondition(tagged.coarseConversionValue == .high)
    precondition(tagged.conversionTypes == [.reengagement])
}

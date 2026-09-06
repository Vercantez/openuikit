import PaperKit
import Foundation

func testFeatureSetFeatureCases() {
    let expected: [FeatureSet.Feature] = [
        .images, .stickers, .loupes, .links, .shapeFills,
        .shapeStrokes, .shapeOpacity, .text, .drawing,
    ]
    precondition(FeatureSet.Feature.allCases == expected)
    let typed: FeatureSet.Feature.AllCases = FeatureSet.Feature.allCases
    precondition(typed.count == 9)
    precondition(FeatureSet.Feature.images == FeatureSet.Feature.images)
    precondition(FeatureSet.Feature.images != FeatureSet.Feature.stickers)
    var hasher = Hasher()
    FeatureSet.Feature.drawing.hash(into: &hasher)
    _ = FeatureSet.Feature.links.hashValue
}

func testFeatureSetEmpty() {
    let empty = FeatureSet.empty
    precondition(empty.features.isEmpty)
    precondition(empty.shapes.isEmpty)
    precondition(empty.inks.isEmpty)
    precondition(empty.lineMarkerPositions.isEmpty)
    precondition(empty.colorMaximumLinearExposure == 1.0)
    precondition(empty.contentVersion == .version1)
}

func testFeatureSetVersion1() {
    let version1 = FeatureSet.version1
    precondition(version1.features == Set(FeatureSet.Feature.allCases))
    precondition(version1.shapes == Set(ShapeConfiguration.Shape.allCases))
    precondition(version1.inks.count == 8)
    precondition(version1.lineMarkerPositions == .all)
    precondition(version1.colorMaximumLinearExposure == 1.0)
    precondition(version1.contentVersion == .version1)
}

func testFeatureSetLatestEqualsVersion1() {
    precondition(FeatureSet.latest == FeatureSet.version1)
    precondition(!(FeatureSet.latest != FeatureSet.version1))
}

func testFeatureSetContainsInsertRemove() {
    var set = FeatureSet.empty
    precondition(!set.contains(.text))
    set.insert(.text)
    precondition(set.contains(.text))
    set.remove(.text)
    precondition(!set.contains(.text))
}

func testFeatureSetIsSubset() {
    precondition(FeatureSet.empty.isSubset(of: FeatureSet.latest))
    precondition(FeatureSet.latest.isSubset(of: FeatureSet.latest))
    precondition(!FeatureSet.latest.isSubset(of: FeatureSet.empty))
    var reduced = FeatureSet.latest
    reduced.remove(.drawing)
    precondition(reduced.isSubset(of: FeatureSet.latest))
    precondition(!FeatureSet.latest.isSubset(of: reduced))
}

func testFeatureSetInksDefaultAll() {
    let inks = FeatureSet.latest.inks
    precondition(inks.contains(.pen))
    precondition(inks.contains(.reed))
    precondition(inks.contains(.watercolor))
    precondition(FeatureSet.empty.inks.isEmpty)
}

func testFeatureSetShapesDefaultAll() {
    precondition(FeatureSet.latest.shapes.contains(.star))
    precondition(FeatureSet.latest.shapes.contains(.arrowShape))
    var none = FeatureSet.latest
    none.shapes = []
    precondition(none.shapes.isEmpty)
}

func testFeatureSetColorMaximumLinearExposureDefault() {
    precondition(FeatureSet.latest.colorMaximumLinearExposure == 1.0)
    var hdr = FeatureSet.latest
    hdr.colorMaximumLinearExposure = 2.0
    precondition(!hdr.isSubset(of: FeatureSet.latest))
    precondition(FeatureSet.latest.isSubset(of: hdr))
}

func testFeatureSetLineMarkerPositionsDefaultAll() {
    precondition(FeatureSet.latest.lineMarkerPositions == .all)
}

func testFeatureSetContentVersionProperty() {
    var set = FeatureSet.empty
    precondition(set.contentVersion == .version1)
    set.contentVersion = .latest
    precondition(set.contentVersion == .version1)
}

func testFeatureSetContentVersionRawValues() {
    let version = FeatureSet.ContentVersion.version1
    precondition(version.rawValue == 1)
    precondition(FeatureSet.ContentVersion(rawValue: 1) == .version1)
    precondition(FeatureSet.ContentVersion(rawValue: 0) == nil)
    precondition(FeatureSet.ContentVersion(rawValue: 2) == nil)
    precondition(FeatureSet.ContentVersion.latest == .version1)
    let raw: FeatureSet.ContentVersion.RawValue = version.rawValue
    precondition(raw == 1)
    precondition(version.pencilKitContentVersion == PKContentVersion.latest)
    precondition(version != FeatureSet.ContentVersion(rawValue: 99) ?? .version1 || FeatureSet.ContentVersion(rawValue: 99) == nil)
    var hasher = Hasher()
    version.hash(into: &hasher)
    _ = version.hashValue
    precondition(FeatureSet.ContentVersion.version1 == FeatureSet.ContentVersion.latest)
}

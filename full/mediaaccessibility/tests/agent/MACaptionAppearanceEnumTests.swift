import Foundation
import MediaAccessibility

func testCaptionAppearanceBehaviorRawValues() {
    precondition(MACaptionAppearanceBehavior.useValue.rawValue == 0)
    precondition(MACaptionAppearanceBehavior.useContentIfAvailable.rawValue == 1)
    precondition(MACaptionAppearanceBehavior(rawValue: 0) == .useValue)
    precondition(MACaptionAppearanceBehavior(rawValue: 1) == .useContentIfAvailable)
    precondition(MACaptionAppearanceBehavior(rawValue: 2) == nil)
    precondition(MACaptionAppearanceBehavior.useValue != .useContentIfAvailable)

    var hasherA = Hasher()
    var hasherB = Hasher()
    MACaptionAppearanceBehavior.useValue.hash(into: &hasherA)
    MACaptionAppearanceBehavior.useValue.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(MACaptionAppearanceBehavior.useValue.hashValue == MACaptionAppearanceBehavior.useValue.hashValue)
}

func testCaptionAppearanceDisplayTypeRawValues() {
    precondition(MACaptionAppearanceDisplayType.forcedOnly.rawValue == 0)
    precondition(MACaptionAppearanceDisplayType.automatic.rawValue == 1)
    precondition(MACaptionAppearanceDisplayType.alwaysOn.rawValue == 2)
    precondition(MACaptionAppearanceDisplayType(rawValue: 0) == .forcedOnly)
    precondition(MACaptionAppearanceDisplayType(rawValue: 1) == .automatic)
    precondition(MACaptionAppearanceDisplayType(rawValue: 2) == .alwaysOn)
    precondition(MACaptionAppearanceDisplayType(rawValue: 9) == nil)
    precondition(MACaptionAppearanceDisplayType.forcedOnly != .alwaysOn)

    var hasherA = Hasher()
    var hasherB = Hasher()
    MACaptionAppearanceDisplayType.automatic.hash(into: &hasherA)
    MACaptionAppearanceDisplayType.automatic.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(MACaptionAppearanceDisplayType.alwaysOn.hashValue == MACaptionAppearanceDisplayType.alwaysOn.hashValue)
}

func testCaptionAppearanceDomainRawValues() {
    precondition(MACaptionAppearanceDomain.default.rawValue == 0)
    precondition(MACaptionAppearanceDomain.user.rawValue == 1)
    precondition(MACaptionAppearanceDomain(rawValue: 0) == .default)
    precondition(MACaptionAppearanceDomain(rawValue: 1) == .user)
    precondition(MACaptionAppearanceDomain(rawValue: -1) == nil)
    precondition(MACaptionAppearanceDomain.default != .user)

    var hasherA = Hasher()
    var hasherB = Hasher()
    MACaptionAppearanceDomain.user.hash(into: &hasherA)
    MACaptionAppearanceDomain.user.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(MACaptionAppearanceDomain.default.hashValue == MACaptionAppearanceDomain.default.hashValue)
}

func testCaptionAppearanceFontStyleRawValues() {
    precondition(MACaptionAppearanceFontStyle.default.rawValue == 0)
    precondition(MACaptionAppearanceFontStyle.monospacedWithSerif.rawValue == 1)
    precondition(MACaptionAppearanceFontStyle.proportionalWithSerif.rawValue == 2)
    precondition(MACaptionAppearanceFontStyle.monospacedWithoutSerif.rawValue == 3)
    precondition(MACaptionAppearanceFontStyle.proportionalWithoutSerif.rawValue == 4)
    precondition(MACaptionAppearanceFontStyle.casual.rawValue == 5)
    precondition(MACaptionAppearanceFontStyle.cursive.rawValue == 6)
    precondition(MACaptionAppearanceFontStyle.smallCapital.rawValue == 7)
    precondition(MACaptionAppearanceFontStyle(rawValue: 0) == .default)
    precondition(MACaptionAppearanceFontStyle(rawValue: 7) == .smallCapital)
    precondition(MACaptionAppearanceFontStyle(rawValue: 8) == nil)
    precondition(MACaptionAppearanceFontStyle.casual != .cursive)

    var hasherA = Hasher()
    var hasherB = Hasher()
    MACaptionAppearanceFontStyle.cursive.hash(into: &hasherA)
    MACaptionAppearanceFontStyle.cursive.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(MACaptionAppearanceFontStyle.smallCapital.hashValue == MACaptionAppearanceFontStyle.smallCapital.hashValue)
}

func testCaptionAppearanceTextEdgeStyleRawValues() {
    precondition(MACaptionAppearanceTextEdgeStyle.undefined.rawValue == 0)
    precondition(MACaptionAppearanceTextEdgeStyle.none.rawValue == 1)
    precondition(MACaptionAppearanceTextEdgeStyle.raised.rawValue == 2)
    precondition(MACaptionAppearanceTextEdgeStyle.depressed.rawValue == 3)
    precondition(MACaptionAppearanceTextEdgeStyle.uniform.rawValue == 4)
    precondition(MACaptionAppearanceTextEdgeStyle.dropShadow.rawValue == 5)
    precondition(MACaptionAppearanceTextEdgeStyle(rawValue: 0) == .undefined)
    precondition(MACaptionAppearanceTextEdgeStyle(rawValue: 5) == .dropShadow)
    precondition(MACaptionAppearanceTextEdgeStyle(rawValue: 6) == nil)
    precondition(MACaptionAppearanceTextEdgeStyle.raised != .depressed)

    var hasherA = Hasher()
    var hasherB = Hasher()
    MACaptionAppearanceTextEdgeStyle.uniform.hash(into: &hasherA)
    MACaptionAppearanceTextEdgeStyle.uniform.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(MACaptionAppearanceTextEdgeStyle.dropShadow.hashValue == MACaptionAppearanceTextEdgeStyle.dropShadow.hashValue)
}

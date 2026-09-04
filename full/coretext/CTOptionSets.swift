import CoreFoundation
import Foundation

public struct CTFontCollectionCopyOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let unique = CTFontCollectionCopyOptions(rawValue: 1 << 0)
    public static let standardSort = CTFontCollectionCopyOptions(rawValue: 1 << 1)
}

public struct CTFontOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let preventAutoActivation = CTFontOptions(rawValue: 1 << 0)
    public static let preventAutoDownload = CTFontOptions(rawValue: 1 << 1)
    public static let preferSystemFont = CTFontOptions(rawValue: 1 << 2)
}

public struct CTFontSymbolicTraits: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }

    public static let italicTrait = CTFontSymbolicTraits(rawValue: 1 << 0)
    public static let boldTrait = CTFontSymbolicTraits(rawValue: 1 << 1)
    public static let expandedTrait = CTFontSymbolicTraits(rawValue: 1 << 5)
    public static let condensedTrait = CTFontSymbolicTraits(rawValue: 1 << 6)
    public static let monoSpaceTrait = CTFontSymbolicTraits(rawValue: 1 << 10)
    public static let verticalTrait = CTFontSymbolicTraits(rawValue: 1 << 11)
    public static let uiOptimizedTrait = CTFontSymbolicTraits(rawValue: 1 << 12)
    public static let colorGlyphsTrait = CTFontSymbolicTraits(rawValue: 1 << 13)
    public static let compositeTrait = CTFontSymbolicTraits(rawValue: 1 << 14)
    public static let classMaskTrait = CTFontSymbolicTraits(rawValue: 15 << 28)

    public static var traitItalic: CTFontSymbolicTraits { italicTrait }
    public static var traitBold: CTFontSymbolicTraits { boldTrait }
    public static var traitExpanded: CTFontSymbolicTraits { expandedTrait }
    public static var traitCondensed: CTFontSymbolicTraits { condensedTrait }
    public static var traitMonoSpace: CTFontSymbolicTraits { monoSpaceTrait }
    public static var traitVertical: CTFontSymbolicTraits { verticalTrait }
    public static var traitUIOptimized: CTFontSymbolicTraits { uiOptimizedTrait }
    public static var traitColorGlyphs: CTFontSymbolicTraits { colorGlyphsTrait }
    public static var traitComposite: CTFontSymbolicTraits { compositeTrait }
    public static var traitClassMask: CTFontSymbolicTraits { classMaskTrait }
}

public struct CTFontStylisticClass: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }

    public static let oldStyleSerifsClass = CTFontStylisticClass(rawValue: 1 << 28)
    public static let transitionalSerifsClass = CTFontStylisticClass(rawValue: 2 << 28)
    public static let modernSerifsClass = CTFontStylisticClass(rawValue: 3 << 28)
    public static let clarendonSerifsClass = CTFontStylisticClass(rawValue: 4 << 28)
    public static let slabSerifsClass = CTFontStylisticClass(rawValue: 5 << 28)
    public static let freeformSerifsClass = CTFontStylisticClass(rawValue: 7 << 28)
    public static let sansSerifClass = CTFontStylisticClass(rawValue: 8 << 28)
    public static let ornamentalsClass = CTFontStylisticClass(rawValue: 9 << 28)
    public static let scriptsClass = CTFontStylisticClass(rawValue: 10 << 28)
    public static let symbolicClass = CTFontStylisticClass(rawValue: 12 << 28)

    public static var classOldStyleSerifs: CTFontStylisticClass { oldStyleSerifsClass }
    public static var classTransitionalSerifs: CTFontStylisticClass { transitionalSerifsClass }
    public static var classModernSerifs: CTFontStylisticClass { modernSerifsClass }
    public static var classClarendonSerifs: CTFontStylisticClass { clarendonSerifsClass }
    public static var classSlabSerifs: CTFontStylisticClass { slabSerifsClass }
    public static var classFreeformSerifs: CTFontStylisticClass { freeformSerifsClass }
    public static var classSansSerif: CTFontStylisticClass { sansSerifClass }
    public static var classOrnamentals: CTFontStylisticClass { ornamentalsClass }
    public static var classScripts: CTFontStylisticClass { scriptsClass }
    public static var classSymbolic: CTFontStylisticClass { symbolicClass }
}

public struct CTFontTableOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

public struct CTLineBoundsOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let excludeTypographicLeading = CTLineBoundsOptions(rawValue: 1 << 0)
    public static let excludeTypographicShifts = CTLineBoundsOptions(rawValue: 1 << 1)
    public static let useHangingPunctuation = CTLineBoundsOptions(rawValue: 1 << 2)
    public static let useGlyphPathBounds = CTLineBoundsOptions(rawValue: 1 << 3)
    public static let useOpticalBounds = CTLineBoundsOptions(rawValue: 1 << 4)
    public static let includeLanguageExtents = CTLineBoundsOptions(rawValue: 1 << 5)
}

public struct CTRunStatus: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let rightToLeft = CTRunStatus(rawValue: 1 << 0)
    public static let nonMonotonic = CTRunStatus(rawValue: 1 << 1)
    public static let hasNonIdentityMatrix = CTRunStatus(rawValue: 1 << 2)
}

public struct CTUnderlineStyle: OptionSet, Sendable, Hashable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public static let single = CTUnderlineStyle(rawValue: 0x01)
    public static let thick = CTUnderlineStyle(rawValue: 0x02)
    public static let double = CTUnderlineStyle(rawValue: 0x09)
}

public struct CTUnderlineStyleModifiers: OptionSet, Sendable, Hashable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public static var patternSolid: CTUnderlineStyleModifiers { [] }
    public static let patternDot = CTUnderlineStyleModifiers(rawValue: 0x0100)
    public static let patternDash = CTUnderlineStyleModifiers(rawValue: 0x0200)
    public static let patternDashDot = CTUnderlineStyleModifiers(rawValue: 0x0300)
    public static let patternDashDotDot = CTUnderlineStyleModifiers(rawValue: 0x0400)
}

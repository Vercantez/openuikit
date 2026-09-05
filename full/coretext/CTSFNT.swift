import CoreFoundation
import Foundation

// MacTypes.Fixed / FourCharCode are Darwin-owned. Isolated hosts (Linux and
// this module's Darwin compile without importing Darwin) use the 16.16 Int32
// layout and UInt32 FourCC. Do not `import Darwin` here: it is not a declared
// CoreText dependency.
public typealias Fixed = Int32
public typealias FourCharCode = UInt32

// MARK: - Scalar SFNT / CoreText C typealiases

public typealias ATSFontRef = UInt32
public typealias BslnBaselineClass = UInt32
public typealias BslnBaselineRecord = (Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed, Fixed)
public typealias BslnTableFormat = UInt16
public typealias CTFontCollectionSortDescriptorsCallback = (CTFontDescriptor, CTFontDescriptor, UnsafeMutableRawPointer) -> CFComparisonResult
public typealias CTFontDescriptorProgressHandler = (CTFontDescriptorMatchingState, CFDictionary) -> Bool
public typealias CTFontPriority = UInt32
public typealias CTFontTableTag = FourCharCode
public typealias CTRunDelegateDeallocateCallback = (UnsafeMutableRawPointer) -> Void
public typealias CTRunDelegateGetAscentCallback = (UnsafeMutableRawPointer) -> CGFloat
public typealias CTRunDelegateGetDescentCallback = (UnsafeMutableRawPointer) -> CGFloat
public typealias CTRunDelegateGetWidthCallback = (UnsafeMutableRawPointer) -> CGFloat
public typealias FontLanguageCode = UInt32
public typealias FontNameCode = UInt32
public typealias FontPlatformCode = UInt32
public typealias FontScriptCode = UInt32
public typealias JustPCActionType = UInt16
public typealias JustPCUnconditionalAddAction = UInt16
public typealias JustificationFlags = UInt16
public typealias KernArrayOffset = UInt16
public typealias KernKerningValue = Int16
public typealias KernSubtableInfo = UInt16
public typealias KernTableFormat = UInt8
public typealias KerxArrayOffset = UInt32
public typealias KerxSubtableCoverage = UInt32
public typealias MortLigatureActionEntry = UInt32
public typealias MortSubtableMaskFlags = UInt32
public typealias OpbdTableFormat = UInt16
public typealias PropCharProperties = UInt16
public typealias SFNTLookupKind = UInt32
public typealias SFNTLookupOffset = UInt16
public typealias SFNTLookupTableFormat = UInt16
public typealias SFNTLookupValue = UInt16
public typealias STClass = UInt8
public typealias STEntryIndex = UInt8
public typealias STXClass = UInt16
public typealias STXClassTable = SFNTLookupTable
public typealias STXEntryIndex = UInt16
public typealias STXStateIndex = UInt16
public typealias TrakValue = Int16

// MARK: - Imported C structs (names and fields from the exact graph)
// Linux stored-property layout is not claimed as Apple C union ABI.

public struct ALMXGlyphEntry: Sendable { 
    public var GlyphIndexOffset: Int16
    public var HorizontalAdvance: Int16
    public var VerticalAdvance: Int16
    public var XOffsetToHOrigin: Int16
    public var YOffsetToVOrigin: Int16
    public init() {
        self.GlyphIndexOffset = 0
        self.HorizontalAdvance = 0
        self.VerticalAdvance = 0
        self.XOffsetToHOrigin = 0
        self.YOffsetToVOrigin = 0
    }
    public init(GlyphIndexOffset: Int16, HorizontalAdvance: Int16, XOffsetToHOrigin: Int16, VerticalAdvance: Int16, YOffsetToVOrigin: Int16) {
        self.GlyphIndexOffset = GlyphIndexOffset
        self.HorizontalAdvance = HorizontalAdvance
        self.XOffsetToHOrigin = XOffsetToHOrigin
        self.VerticalAdvance = VerticalAdvance
        self.YOffsetToVOrigin = YOffsetToVOrigin
    }
}

public struct ALMXHeader: Sendable { 
    public var FirstGlyph: UInt16
    public var Flags: UInt16
    public var LastGlyph: UInt16
    public var NMasters: UInt16
    public var Version: Fixed
    public var lookup: SFNTLookupTable
    public init() {
        self.FirstGlyph = 0
        self.Flags = 0
        self.LastGlyph = 0
        self.NMasters = 0
        self.Version = 0
        self.lookup = SFNTLookupTable()
    }
    public init(Version: Fixed, Flags: UInt16, NMasters: UInt16, FirstGlyph: UInt16, LastGlyph: UInt16, lookup: SFNTLookupTable) {
        self.Version = Version
        self.Flags = Flags
        self.NMasters = NMasters
        self.FirstGlyph = FirstGlyph
        self.LastGlyph = LastGlyph
        self.lookup = lookup
    }
}

public struct AnchorPoint: Sendable { 
    public var x: Int16
    public var y: Int16
    public init() {
        self.x = 0
        self.y = 0
    }
    public init(x: Int16, y: Int16) {
        self.x = x
        self.y = y
    }
}

public struct AnchorPointTable: Sendable { 
    public var nPoints: UInt32
    public var points: AnchorPoint
    public init() {
        self.nPoints = 0
        self.points = AnchorPoint()
    }
    public init(nPoints: UInt32, points: AnchorPoint) {
        self.nPoints = nPoints
        self.points = points
    }
}

public struct AnkrTable: Sendable { 
    public var anchorPointTableOffset: UInt32
    public var flags: UInt16
    public var lookupTableOffset: UInt32
    public var version: UInt16
    public init() {
        self.anchorPointTableOffset = 0
        self.flags = 0
        self.lookupTableOffset = 0
        self.version = 0
    }
    public init(version: UInt16, flags: UInt16, lookupTableOffset: UInt32, anchorPointTableOffset: UInt32) {
        self.version = version
        self.flags = flags
        self.lookupTableOffset = lookupTableOffset
        self.anchorPointTableOffset = anchorPointTableOffset
    }
}

public struct BslnFormat0Part: Sendable { 
    public var deltas: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16)
    public init() {
        self.deltas = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }
    public init(deltas: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16)) {
        self.deltas = deltas
    }
}

public struct BslnFormat1Part: Sendable { 
    public var deltas: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16)
    public var mappingData: SFNTLookupTable
    public init() {
        self.deltas = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.mappingData = SFNTLookupTable()
    }
    public init(deltas: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16), mappingData: SFNTLookupTable) {
        self.deltas = deltas
        self.mappingData = mappingData
    }
}

public struct BslnFormat2Part: Sendable { 
    public var ctlPoints: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16)
    public var stdGlyph: UInt16
    public init() {
        self.ctlPoints = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.stdGlyph = 0
    }
    public init(stdGlyph: UInt16, ctlPoints: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16)) {
        self.stdGlyph = stdGlyph
        self.ctlPoints = ctlPoints
    }
}

public struct BslnFormat3Part: Sendable { 
    public var ctlPoints: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16)
    public var mappingData: SFNTLookupTable
    public var stdGlyph: UInt16
    public init() {
        self.ctlPoints = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.mappingData = SFNTLookupTable()
        self.stdGlyph = 0
    }
    public init(stdGlyph: UInt16, ctlPoints: (Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16, Int16), mappingData: SFNTLookupTable) {
        self.stdGlyph = stdGlyph
        self.ctlPoints = ctlPoints
        self.mappingData = mappingData
    }
}

public struct BslnFormatUnion: Sendable { 
    public var fmt0Part: BslnFormat0Part
    public var fmt1Part: BslnFormat1Part
    public var fmt2Part: BslnFormat2Part
    public var fmt3Part: BslnFormat3Part
    public init() {
        self.fmt0Part = BslnFormat0Part()
        self.fmt1Part = BslnFormat1Part()
        self.fmt2Part = BslnFormat2Part()
        self.fmt3Part = BslnFormat3Part()
    }
    public init(fmt0Part: BslnFormat0Part) {
        self.fmt0Part = fmt0Part
        self.fmt1Part = BslnFormat1Part()
        self.fmt2Part = BslnFormat2Part()
        self.fmt3Part = BslnFormat3Part()
    }
    public init(fmt1Part: BslnFormat1Part) {
        self.fmt1Part = fmt1Part
        self.fmt0Part = BslnFormat0Part()
        self.fmt2Part = BslnFormat2Part()
        self.fmt3Part = BslnFormat3Part()
    }
    public init(fmt2Part: BslnFormat2Part) {
        self.fmt2Part = fmt2Part
        self.fmt0Part = BslnFormat0Part()
        self.fmt1Part = BslnFormat1Part()
        self.fmt3Part = BslnFormat3Part()
    }
    public init(fmt3Part: BslnFormat3Part) {
        self.fmt3Part = fmt3Part
        self.fmt0Part = BslnFormat0Part()
        self.fmt1Part = BslnFormat1Part()
        self.fmt2Part = BslnFormat2Part()
    }
}

public struct BslnTable: Sendable { 
    public var defaultBaseline: UInt16
    public var format: BslnTableFormat
    public var parts: BslnFormatUnion
    public var version: Fixed
    public init() {
        self.defaultBaseline = 0
        self.format = 0
        self.parts = BslnFormatUnion()
        self.version = 0
    }
    public init(version: Fixed, format: BslnTableFormat, defaultBaseline: UInt16, parts: BslnFormatUnion) {
        self.version = version
        self.format = format
        self.defaultBaseline = defaultBaseline
        self.parts = parts
    }
}

public struct CTParagraphStyleSetting { 
    public var spec: CTParagraphStyleSpecifier
    public var value: UnsafeRawPointer
    public var valueSize: Int
    public init(spec: CTParagraphStyleSpecifier, valueSize: Int, value: UnsafeRawPointer) {
        self.spec = spec
        self.valueSize = valueSize
        self.value = value
    }
}

public struct CTRunDelegateCallbacks { 
    public var dealloc: CTRunDelegateDeallocateCallback
    public var getAscent: CTRunDelegateGetAscentCallback
    public var getDescent: CTRunDelegateGetDescentCallback
    public var getWidth: CTRunDelegateGetWidthCallback
    public var version: CFIndex
    public init(version: CFIndex, dealloc: @escaping CTRunDelegateDeallocateCallback, getAscent: @escaping CTRunDelegateGetAscentCallback, getDescent: @escaping CTRunDelegateGetDescentCallback, getWidth: @escaping CTRunDelegateGetWidthCallback) {
        self.version = version
        self.dealloc = dealloc
        self.getAscent = getAscent
        self.getDescent = getDescent
        self.getWidth = getWidth
    }
}

public struct FontVariation: Sendable { 
    public var name: FourCharCode
    public var value: Fixed
    public init() {
        self.name = 0
        self.value = 0
    }
    public init(name: FourCharCode, value: Fixed) {
        self.name = name
        self.value = value
    }
}

public struct JustDirectionTable: Sendable { 
    public var justClass: UInt16
    public var lookup: SFNTLookupTable
    public var postcomp: UInt16
    public var widthDeltaClusters: UInt16
    public init() {
        self.justClass = 0
        self.lookup = SFNTLookupTable()
        self.postcomp = 0
        self.widthDeltaClusters = 0
    }
    public init(justClass: UInt16, widthDeltaClusters: UInt16, postcomp: UInt16, lookup: SFNTLookupTable) {
        self.justClass = justClass
        self.widthDeltaClusters = widthDeltaClusters
        self.postcomp = postcomp
        self.lookup = lookup
    }
}

public struct JustPCAction: Sendable { 
    public var actionCount: UInt32
    public var actions: JustPCActionSubrecord
    public init() {
        self.actionCount = 0
        self.actions = JustPCActionSubrecord()
    }
    public init(actionCount: UInt32, actions: JustPCActionSubrecord) {
        self.actionCount = actionCount
        self.actions = actions
    }
}

public struct JustPCActionSubrecord: Sendable { 
    public var data: UInt32
    public var length: UInt32
    public var theClass: UInt16
    public var theType: JustPCActionType
    public init() {
        self.data = 0
        self.length = 0
        self.theClass = 0
        self.theType = 0
    }
    public init(theClass: UInt16, theType: JustPCActionType, length: UInt32, data: UInt32) {
        self.theClass = theClass
        self.theType = theType
        self.length = length
        self.data = data
    }
}

public struct JustPCConditionalAddAction: Sendable { 
    public var addGlyph: UInt16
    public var substGlyph: UInt16
    public var substThreshold: Fixed
    public init() {
        self.addGlyph = 0
        self.substGlyph = 0
        self.substThreshold = 0
    }
    public init(substThreshold: Fixed, addGlyph: UInt16, substGlyph: UInt16) {
        self.substThreshold = substThreshold
        self.addGlyph = addGlyph
        self.substGlyph = substGlyph
    }
}

public struct JustPCDecompositionAction: Sendable { 
    public var count: UInt16
    public var glyphs: UInt16
    public var lowerLimit: Fixed
    public var order: UInt16
    public var upperLimit: Fixed
    public init() {
        self.count = 0
        self.glyphs = 0
        self.lowerLimit = 0
        self.order = 0
        self.upperLimit = 0
    }
    public init(lowerLimit: Fixed, upperLimit: Fixed, order: UInt16, count: UInt16, glyphs: UInt16) {
        self.lowerLimit = lowerLimit
        self.upperLimit = upperLimit
        self.order = order
        self.count = count
        self.glyphs = glyphs
    }
}

public struct JustPCDuctilityAction: Sendable { 
    public var ductilityAxis: UInt32
    public var maximumLimit: Fixed
    public var minimumLimit: Fixed
    public var noStretchValue: Fixed
    public init() {
        self.ductilityAxis = 0
        self.maximumLimit = 0
        self.minimumLimit = 0
        self.noStretchValue = 0
    }
    public init(ductilityAxis: UInt32, minimumLimit: Fixed, noStretchValue: Fixed, maximumLimit: Fixed) {
        self.ductilityAxis = ductilityAxis
        self.minimumLimit = minimumLimit
        self.noStretchValue = noStretchValue
        self.maximumLimit = maximumLimit
    }
}

public struct JustPCGlyphRepeatAddAction: Sendable { 
    public var flags: UInt16
    public var glyph: UInt16
    public init() {
        self.flags = 0
        self.glyph = 0
    }
    public init(flags: UInt16, glyph: UInt16) {
        self.flags = flags
        self.glyph = glyph
    }
}

public struct JustPostcompTable: Sendable { 
    public var lookupTable: SFNTLookupTable
    public init() {
        self.lookupTable = SFNTLookupTable()
    }
    public init(lookupTable: SFNTLookupTable) {
        self.lookupTable = lookupTable
    }
}

public struct JustTable: Sendable { 
    public var format: UInt16
    public var horizHeaderOffset: UInt16
    public var version: Fixed
    public var vertHeaderOffset: UInt16
    public init() {
        self.format = 0
        self.horizHeaderOffset = 0
        self.version = 0
        self.vertHeaderOffset = 0
    }
    public init(version: Fixed, format: UInt16, horizHeaderOffset: UInt16, vertHeaderOffset: UInt16) {
        self.version = version
        self.format = format
        self.horizHeaderOffset = horizHeaderOffset
        self.vertHeaderOffset = vertHeaderOffset
    }
}

public struct JustWidthDeltaEntry: Sendable { 
    public var afterGrowLimit: Fixed
    public var afterShrinkLimit: Fixed
    public var beforeGrowLimit: Fixed
    public var beforeShrinkLimit: Fixed
    public var growFlags: JustificationFlags
    public var justClass: UInt32
    public var shrinkFlags: JustificationFlags
    public init() {
        self.afterGrowLimit = 0
        self.afterShrinkLimit = 0
        self.beforeGrowLimit = 0
        self.beforeShrinkLimit = 0
        self.growFlags = 0
        self.justClass = 0
        self.shrinkFlags = 0
    }
    public init(justClass: UInt32, beforeGrowLimit: Fixed, beforeShrinkLimit: Fixed, afterGrowLimit: Fixed, afterShrinkLimit: Fixed, growFlags: JustificationFlags, shrinkFlags: JustificationFlags) {
        self.justClass = justClass
        self.beforeGrowLimit = beforeGrowLimit
        self.beforeShrinkLimit = beforeShrinkLimit
        self.afterGrowLimit = afterGrowLimit
        self.afterShrinkLimit = afterShrinkLimit
        self.growFlags = growFlags
        self.shrinkFlags = shrinkFlags
    }
}

public struct JustWidthDeltaGroup: Sendable { 
    public var count: UInt32
    public var entries: JustWidthDeltaEntry
    public init() {
        self.count = 0
        self.entries = JustWidthDeltaEntry()
    }
    public init(count: UInt32, entries: JustWidthDeltaEntry) {
        self.count = count
        self.entries = entries
    }
}

public struct KernFormatSpecificHeader: Sendable { 
    public var indexArray: KernIndexArrayHeader
    public var orderedList: KernOrderedListHeader
    public var simpleArray: KernSimpleArrayHeader
    public var stateTable: KernStateHeader
    public init() {
        self.indexArray = KernIndexArrayHeader()
        self.orderedList = KernOrderedListHeader()
        self.simpleArray = KernSimpleArrayHeader()
        self.stateTable = KernStateHeader()
    }
    public init(indexArray: KernIndexArrayHeader) {
        self.indexArray = indexArray
        self.orderedList = KernOrderedListHeader()
        self.simpleArray = KernSimpleArrayHeader()
        self.stateTable = KernStateHeader()
    }
    public init(stateTable: KernStateHeader) {
        self.stateTable = stateTable
        self.indexArray = KernIndexArrayHeader()
        self.orderedList = KernOrderedListHeader()
        self.simpleArray = KernSimpleArrayHeader()
    }
    public init(orderedList: KernOrderedListHeader) {
        self.orderedList = orderedList
        self.indexArray = KernIndexArrayHeader()
        self.simpleArray = KernSimpleArrayHeader()
        self.stateTable = KernStateHeader()
    }
    public init(simpleArray: KernSimpleArrayHeader) {
        self.simpleArray = simpleArray
        self.indexArray = KernIndexArrayHeader()
        self.orderedList = KernOrderedListHeader()
        self.stateTable = KernStateHeader()
    }
}

public struct KernIndexArrayHeader: Sendable { 
    public var flags: UInt8
    public var glyphCount: UInt16
    public var kernIndex: UInt8
    public var kernValue: Int16
    public var kernValueCount: UInt8
    public var leftClass: UInt8
    public var leftClassCount: UInt8
    public var rightClass: UInt8
    public var rightClassCount: UInt8
    public init() {
        self.flags = 0
        self.glyphCount = 0
        self.kernIndex = 0
        self.kernValue = 0
        self.kernValueCount = 0
        self.leftClass = 0
        self.leftClassCount = 0
        self.rightClass = 0
        self.rightClassCount = 0
    }
    public init(glyphCount: UInt16, kernValueCount: UInt8, leftClassCount: UInt8, rightClassCount: UInt8, flags: UInt8, kernValue: Int16, leftClass: UInt8, rightClass: UInt8, kernIndex: UInt8) {
        self.glyphCount = glyphCount
        self.kernValueCount = kernValueCount
        self.leftClassCount = leftClassCount
        self.rightClassCount = rightClassCount
        self.flags = flags
        self.kernValue = kernValue
        self.leftClass = leftClass
        self.rightClass = rightClass
        self.kernIndex = kernIndex
    }
}

public struct KernKerningPair: Sendable { 
    public var `left`: UInt16
    public var `right`: UInt16
    public init() {
        self.`left` = 0
        self.`right` = 0
    }
    public init(`left`: UInt16, `right`: UInt16) {
        self.`left` = `left`
        self.`right` = `right`
    }
}

public struct KernOffsetTable: Sendable { 
    public var firstGlyph: UInt16
    public var nGlyphs: UInt16
    public var offsetTable: KernArrayOffset
    public init() {
        self.firstGlyph = 0
        self.nGlyphs = 0
        self.offsetTable = 0
    }
    public init(firstGlyph: UInt16, nGlyphs: UInt16, offsetTable: KernArrayOffset) {
        self.firstGlyph = firstGlyph
        self.nGlyphs = nGlyphs
        self.offsetTable = offsetTable
    }
}

public struct KernOrderedListEntry: Sendable { 
    public var pair: KernKerningPair
    public var value: KernKerningValue
    public init() {
        self.pair = KernKerningPair()
        self.value = 0
    }
    public init(pair: KernKerningPair, value: KernKerningValue) {
        self.pair = pair
        self.value = value
    }
}

public struct KernOrderedListHeader: Sendable { 
    public var entrySelector: UInt16
    public var nPairs: UInt16
    public var rangeShift: UInt16
    public var searchRange: UInt16
    public var table: UInt16
    public init() {
        self.entrySelector = 0
        self.nPairs = 0
        self.rangeShift = 0
        self.searchRange = 0
        self.table = 0
    }
    public init(nPairs: UInt16, searchRange: UInt16, entrySelector: UInt16, rangeShift: UInt16, table: UInt16) {
        self.nPairs = nPairs
        self.searchRange = searchRange
        self.entrySelector = entrySelector
        self.rangeShift = rangeShift
        self.table = table
    }
}

public struct KernSimpleArrayHeader: Sendable { 
    public var firstTable: UInt16
    public var leftOffsetTable: UInt16
    public var rightOffsetTable: UInt16
    public var rowWidth: UInt16
    public var theArray: KernArrayOffset
    public init() {
        self.firstTable = 0
        self.leftOffsetTable = 0
        self.rightOffsetTable = 0
        self.rowWidth = 0
        self.theArray = 0
    }
    public init(rowWidth: UInt16, leftOffsetTable: UInt16, rightOffsetTable: UInt16, theArray: KernArrayOffset, firstTable: UInt16) {
        self.rowWidth = rowWidth
        self.leftOffsetTable = leftOffsetTable
        self.rightOffsetTable = rightOffsetTable
        self.theArray = theArray
        self.firstTable = firstTable
    }
}

public struct KernStateEntry: Sendable { 
    public var flags: UInt16
    public var newState: UInt16
    public init() {
        self.flags = 0
        self.newState = 0
    }
    public init(newState: UInt16, flags: UInt16) {
        self.newState = newState
        self.flags = flags
    }
}

public struct KernStateHeader: Sendable { 
    public var firstTable: UInt8
    public var header: STHeader
    public var valueTable: UInt16
    public init() {
        self.firstTable = 0
        self.header = STHeader()
        self.valueTable = 0
    }
    public init(header: STHeader, valueTable: UInt16, firstTable: UInt8) {
        self.header = header
        self.valueTable = valueTable
        self.firstTable = firstTable
    }
}

public struct KernSubtableHeader: Sendable { 
    public var fsHeader: KernFormatSpecificHeader
    public var length: Int32
    public var stInfo: KernSubtableInfo
    public var tupleIndex: Int16
    public init() {
        self.fsHeader = KernFormatSpecificHeader()
        self.length = 0
        self.stInfo = 0
        self.tupleIndex = 0
    }
    public init(length: Int32, stInfo: KernSubtableInfo, tupleIndex: Int16, fsHeader: KernFormatSpecificHeader) {
        self.length = length
        self.stInfo = stInfo
        self.tupleIndex = tupleIndex
        self.fsHeader = fsHeader
    }
}

public struct KernTableHeader: Sendable { 
    public var firstSubtable: UInt16
    public var nTables: Int32
    public var version: Fixed
    public init() {
        self.firstSubtable = 0
        self.nTables = 0
        self.version = 0
    }
    public init(version: Fixed, nTables: Int32, firstSubtable: UInt16) {
        self.version = version
        self.nTables = nTables
        self.firstSubtable = firstSubtable
    }
}

public struct KernVersion0Header: Sendable { 
    public var firstSubtable: UInt16
    public var nTables: UInt16
    public var version: UInt16
    public init() {
        self.firstSubtable = 0
        self.nTables = 0
        self.version = 0
    }
    public init(version: UInt16, nTables: UInt16, firstSubtable: UInt16) {
        self.version = version
        self.nTables = nTables
        self.firstSubtable = firstSubtable
    }
}

public struct KernVersion0SubtableHeader: Sendable { 
    public var fsHeader: KernFormatSpecificHeader
    public var length: UInt16
    public var stInfo: KernSubtableInfo
    public var version: UInt16
    public init() {
        self.fsHeader = KernFormatSpecificHeader()
        self.length = 0
        self.stInfo = 0
        self.version = 0
    }
    public init(version: UInt16, length: UInt16, stInfo: KernSubtableInfo, fsHeader: KernFormatSpecificHeader) {
        self.version = version
        self.length = length
        self.stInfo = stInfo
        self.fsHeader = fsHeader
    }
}

public struct KerxAnchorPointAction: Sendable { 
    public var currAnchorPoint: UInt16
    public var markAnchorPoint: UInt16
    public init() {
        self.currAnchorPoint = 0
        self.markAnchorPoint = 0
    }
    public init(markAnchorPoint: UInt16, currAnchorPoint: UInt16) {
        self.markAnchorPoint = markAnchorPoint
        self.currAnchorPoint = currAnchorPoint
    }
}

public struct KerxControlPointAction: Sendable { 
    public var currControlPoint: UInt16
    public var markControlPoint: UInt16
    public init() {
        self.currControlPoint = 0
        self.markControlPoint = 0
    }
    public init(markControlPoint: UInt16, currControlPoint: UInt16) {
        self.markControlPoint = markControlPoint
        self.currControlPoint = currControlPoint
    }
}

public struct KerxControlPointEntry: Sendable { 
    public var actionIndex: UInt16
    public var flags: UInt16
    public var newState: UInt16
    public init() {
        self.actionIndex = 0
        self.flags = 0
        self.newState = 0
    }
    public init(newState: UInt16, flags: UInt16, actionIndex: UInt16) {
        self.newState = newState
        self.flags = flags
        self.actionIndex = actionIndex
    }
}

public struct KerxControlPointHeader: Sendable { 
    public var firstTable: UInt8
    public var flags: UInt32
    public var header: STXHeader
    public init() {
        self.firstTable = 0
        self.flags = 0
        self.header = STXHeader()
    }
    public init(header: STXHeader, flags: UInt32, firstTable: UInt8) {
        self.header = header
        self.flags = flags
        self.firstTable = firstTable
    }
}

public struct KerxCoordinateAction: Sendable { 
    public var currX: UInt16
    public var currY: UInt16
    public var markX: UInt16
    public var markY: UInt16
    public init() {
        self.currX = 0
        self.currY = 0
        self.markX = 0
        self.markY = 0
    }
    public init(markX: UInt16, markY: UInt16, currX: UInt16, currY: UInt16) {
        self.markX = markX
        self.markY = markY
        self.currX = currX
        self.currY = currY
    }
}

public struct KerxFormatSpecificHeader: Sendable { 
    public var controlPoint: KerxControlPointHeader
    public var indexArray: KerxIndexArrayHeader
    public var orderedList: KerxOrderedListHeader
    public var simpleArray: KerxSimpleArrayHeader
    public var stateTable: KerxStateHeader
    public init() {
        self.controlPoint = KerxControlPointHeader()
        self.indexArray = KerxIndexArrayHeader()
        self.orderedList = KerxOrderedListHeader()
        self.simpleArray = KerxSimpleArrayHeader()
        self.stateTable = KerxStateHeader()
    }
    public init(indexArray: KerxIndexArrayHeader) {
        self.indexArray = indexArray
        self.controlPoint = KerxControlPointHeader()
        self.orderedList = KerxOrderedListHeader()
        self.simpleArray = KerxSimpleArrayHeader()
        self.stateTable = KerxStateHeader()
    }
    public init(stateTable: KerxStateHeader) {
        self.stateTable = stateTable
        self.controlPoint = KerxControlPointHeader()
        self.indexArray = KerxIndexArrayHeader()
        self.orderedList = KerxOrderedListHeader()
        self.simpleArray = KerxSimpleArrayHeader()
    }
    public init(orderedList: KerxOrderedListHeader) {
        self.orderedList = orderedList
        self.controlPoint = KerxControlPointHeader()
        self.indexArray = KerxIndexArrayHeader()
        self.simpleArray = KerxSimpleArrayHeader()
        self.stateTable = KerxStateHeader()
    }
    public init(simpleArray: KerxSimpleArrayHeader) {
        self.simpleArray = simpleArray
        self.controlPoint = KerxControlPointHeader()
        self.indexArray = KerxIndexArrayHeader()
        self.orderedList = KerxOrderedListHeader()
        self.stateTable = KerxStateHeader()
    }
    public init(controlPoint: KerxControlPointHeader) {
        self.controlPoint = controlPoint
        self.indexArray = KerxIndexArrayHeader()
        self.orderedList = KerxOrderedListHeader()
        self.simpleArray = KerxSimpleArrayHeader()
        self.stateTable = KerxStateHeader()
    }
}

public struct KerxIndexArrayHeader: Sendable { 
    public var columnCount: UInt16
    public var columnIndexTableOffset: UInt32
    public var flags: UInt32
    public var kerningArrayOffset: UInt32
    public var kerningVectorOffset: UInt32
    public var rowCount: UInt16
    public var rowIndexTableOffset: UInt32
    public init() {
        self.columnCount = 0
        self.columnIndexTableOffset = 0
        self.flags = 0
        self.kerningArrayOffset = 0
        self.kerningVectorOffset = 0
        self.rowCount = 0
        self.rowIndexTableOffset = 0
    }
    public init(flags: UInt32, rowCount: UInt16, columnCount: UInt16, rowIndexTableOffset: UInt32, columnIndexTableOffset: UInt32, kerningArrayOffset: UInt32, kerningVectorOffset: UInt32) {
        self.flags = flags
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.rowIndexTableOffset = rowIndexTableOffset
        self.columnIndexTableOffset = columnIndexTableOffset
        self.kerningArrayOffset = kerningArrayOffset
        self.kerningVectorOffset = kerningVectorOffset
    }
}

public struct KerxKerningPair: Sendable { 
    public var `left`: UInt16
    public var `right`: UInt16
    public init() {
        self.`left` = 0
        self.`right` = 0
    }
    public init(`left`: UInt16, `right`: UInt16) {
        self.`left` = `left`
        self.`right` = `right`
    }
}

public struct KerxOrderedListEntry: Sendable { 
    public var pair: KerxKerningPair
    public var value: KernKerningValue
    public init() {
        self.pair = KerxKerningPair()
        self.value = 0
    }
    public init(pair: KerxKerningPair, value: KernKerningValue) {
        self.pair = pair
        self.value = value
    }
}

public struct KerxOrderedListHeader: Sendable { 
    public var entrySelector: UInt32
    public var nPairs: UInt32
    public var rangeShift: UInt32
    public var searchRange: UInt32
    public var table: UInt32
    public init() {
        self.entrySelector = 0
        self.nPairs = 0
        self.rangeShift = 0
        self.searchRange = 0
        self.table = 0
    }
    public init(nPairs: UInt32, searchRange: UInt32, entrySelector: UInt32, rangeShift: UInt32, table: UInt32) {
        self.nPairs = nPairs
        self.searchRange = searchRange
        self.entrySelector = entrySelector
        self.rangeShift = rangeShift
        self.table = table
    }
}

public struct KerxSimpleArrayHeader: Sendable { 
    public var firstTable: UInt32
    public var leftOffsetTable: UInt32
    public var rightOffsetTable: UInt32
    public var rowWidth: UInt32
    public var theArray: KerxArrayOffset
    public init() {
        self.firstTable = 0
        self.leftOffsetTable = 0
        self.rightOffsetTable = 0
        self.rowWidth = 0
        self.theArray = 0
    }
    public init(rowWidth: UInt32, leftOffsetTable: UInt32, rightOffsetTable: UInt32, theArray: KerxArrayOffset, firstTable: UInt32) {
        self.rowWidth = rowWidth
        self.leftOffsetTable = leftOffsetTable
        self.rightOffsetTable = rightOffsetTable
        self.theArray = theArray
        self.firstTable = firstTable
    }
}

public struct KerxStateEntry: Sendable { 
    public var flags: UInt16
    public var newState: UInt16
    public var valueIndex: UInt16
    public init() {
        self.flags = 0
        self.newState = 0
        self.valueIndex = 0
    }
    public init(newState: UInt16, flags: UInt16, valueIndex: UInt16) {
        self.newState = newState
        self.flags = flags
        self.valueIndex = valueIndex
    }
}

public struct KerxStateHeader: Sendable { 
    public var firstTable: UInt8
    public var header: STXHeader
    public var valueTable: UInt32
    public init() {
        self.firstTable = 0
        self.header = STXHeader()
        self.valueTable = 0
    }
    public init(header: STXHeader, valueTable: UInt32, firstTable: UInt8) {
        self.header = header
        self.valueTable = valueTable
        self.firstTable = firstTable
    }
}

public struct KerxSubtableHeader: Sendable { 
    public var fsHeader: KerxFormatSpecificHeader
    public var length: UInt32
    public var stInfo: KerxSubtableCoverage
    public var tupleCount: UInt32
    public init() {
        self.fsHeader = KerxFormatSpecificHeader()
        self.length = 0
        self.stInfo = 0
        self.tupleCount = 0
    }
    public init(length: UInt32, stInfo: KerxSubtableCoverage, tupleCount: UInt32, fsHeader: KerxFormatSpecificHeader) {
        self.length = length
        self.stInfo = stInfo
        self.tupleCount = tupleCount
        self.fsHeader = fsHeader
    }
}

public struct KerxTableHeader: Sendable { 
    public var firstSubtable: UInt32
    public var nTables: UInt32
    public var version: Fixed
    public init() {
        self.firstSubtable = 0
        self.nTables = 0
        self.version = 0
    }
    public init(version: Fixed, nTables: UInt32, firstSubtable: UInt32) {
        self.version = version
        self.nTables = nTables
        self.firstSubtable = firstSubtable
    }
}

public struct LcarCaretClassEntry: Sendable { 
    public var count: UInt16
    public var partials: UInt16
    public init() {
        self.count = 0
        self.partials = 0
    }
    public init(count: UInt16, partials: UInt16) {
        self.count = count
        self.partials = partials
    }
}

public struct LcarCaretTable: Sendable { 
    public var format: UInt16
    public var lookup: SFNTLookupTable
    public var version: Fixed
    public init() {
        self.format = 0
        self.lookup = SFNTLookupTable()
        self.version = 0
    }
    public init(version: Fixed, format: UInt16, lookup: SFNTLookupTable) {
        self.version = version
        self.format = format
        self.lookup = lookup
    }
}

public struct LtagStringRange: Sendable { 
    public var length: UInt16
    public var offset: UInt16
    public init() {
        self.length = 0
        self.offset = 0
    }
    public init(offset: UInt16, length: UInt16) {
        self.offset = offset
        self.length = length
    }
}

public struct LtagTable: Sendable { 
    public var flags: UInt32
    public var numTags: UInt32
    public var tagRange: LtagStringRange
    public var version: UInt32
    public init() {
        self.flags = 0
        self.numTags = 0
        self.tagRange = LtagStringRange()
        self.version = 0
    }
    public init(version: UInt32, flags: UInt32, numTags: UInt32, tagRange: LtagStringRange) {
        self.version = version
        self.flags = flags
        self.numTags = numTags
        self.tagRange = tagRange
    }
}

public struct MortChain: Sendable { 
    public var defaultFlags: MortSubtableMaskFlags
    public var featureEntries: MortFeatureEntry
    public var length: UInt32
    public var nFeatures: UInt16
    public var nSubtables: UInt16
    public init() {
        self.defaultFlags = 0
        self.featureEntries = MortFeatureEntry()
        self.length = 0
        self.nFeatures = 0
        self.nSubtables = 0
    }
    public init(defaultFlags: MortSubtableMaskFlags, length: UInt32, nFeatures: UInt16, nSubtables: UInt16, featureEntries: MortFeatureEntry) {
        self.defaultFlags = defaultFlags
        self.length = length
        self.nFeatures = nFeatures
        self.nSubtables = nSubtables
        self.featureEntries = featureEntries
    }
}

public struct MortContextualSubtable: Sendable { 
    public var header: STHeader
    public var substitutionTableOffset: UInt16
    public init() {
        self.header = STHeader()
        self.substitutionTableOffset = 0
    }
    public init(header: STHeader, substitutionTableOffset: UInt16) {
        self.header = header
        self.substitutionTableOffset = substitutionTableOffset
    }
}

public struct MortFeatureEntry: Sendable { 
    public var disableFlags: MortSubtableMaskFlags
    public var enableFlags: MortSubtableMaskFlags
    public var featureSelector: UInt16
    public var featureType: UInt16
    public init() {
        self.disableFlags = 0
        self.enableFlags = 0
        self.featureSelector = 0
        self.featureType = 0
    }
    public init(featureType: UInt16, featureSelector: UInt16, enableFlags: MortSubtableMaskFlags, disableFlags: MortSubtableMaskFlags) {
        self.featureType = featureType
        self.featureSelector = featureSelector
        self.enableFlags = enableFlags
        self.disableFlags = disableFlags
    }
}

public struct MortInsertionSubtable: Sendable { 
    public var header: STHeader
    public init() {
        self.header = STHeader()
    }
    public init(header: STHeader) {
        self.header = header
    }
}

public struct MortLigatureSubtable: Sendable { 
    public var componentTableOffset: UInt16
    public var header: STHeader
    public var ligatureActionTableOffset: UInt16
    public var ligatureTableOffset: UInt16
    public init() {
        self.componentTableOffset = 0
        self.header = STHeader()
        self.ligatureActionTableOffset = 0
        self.ligatureTableOffset = 0
    }
    public init(header: STHeader, ligatureActionTableOffset: UInt16, componentTableOffset: UInt16, ligatureTableOffset: UInt16) {
        self.header = header
        self.ligatureActionTableOffset = ligatureActionTableOffset
        self.componentTableOffset = componentTableOffset
        self.ligatureTableOffset = ligatureTableOffset
    }
}

public struct MortRearrangementSubtable: Sendable { 
    public var header: STHeader
    public init() {
        self.header = STHeader()
    }
    public init(header: STHeader) {
        self.header = header
    }
}

public struct MortSpecificSubtable: Sendable { 
    public var contextual: MortContextualSubtable
    public var insertion: MortInsertionSubtable
    public var ligature: MortLigatureSubtable
    public var rearrangement: MortRearrangementSubtable
    public var swash: MortSwashSubtable
    public init() {
        self.contextual = MortContextualSubtable()
        self.insertion = MortInsertionSubtable()
        self.ligature = MortLigatureSubtable()
        self.rearrangement = MortRearrangementSubtable()
        self.swash = MortSwashSubtable()
    }
    public init(contextual: MortContextualSubtable) {
        self.contextual = contextual
        self.insertion = MortInsertionSubtable()
        self.ligature = MortLigatureSubtable()
        self.rearrangement = MortRearrangementSubtable()
        self.swash = MortSwashSubtable()
    }
    public init(rearrangement: MortRearrangementSubtable) {
        self.rearrangement = rearrangement
        self.contextual = MortContextualSubtable()
        self.insertion = MortInsertionSubtable()
        self.ligature = MortLigatureSubtable()
        self.swash = MortSwashSubtable()
    }
    public init(swash: MortSwashSubtable) {
        self.swash = swash
        self.contextual = MortContextualSubtable()
        self.insertion = MortInsertionSubtable()
        self.ligature = MortLigatureSubtable()
        self.rearrangement = MortRearrangementSubtable()
    }
    public init(ligature: MortLigatureSubtable) {
        self.ligature = ligature
        self.contextual = MortContextualSubtable()
        self.insertion = MortInsertionSubtable()
        self.rearrangement = MortRearrangementSubtable()
        self.swash = MortSwashSubtable()
    }
    public init(insertion: MortInsertionSubtable) {
        self.insertion = insertion
        self.contextual = MortContextualSubtable()
        self.ligature = MortLigatureSubtable()
        self.rearrangement = MortRearrangementSubtable()
        self.swash = MortSwashSubtable()
    }
}

public struct MortSubtable: Sendable { 
    public var coverage: UInt16
    public var flags: MortSubtableMaskFlags
    public var length: UInt16
    public var u: MortSpecificSubtable
    public init() {
        self.coverage = 0
        self.flags = 0
        self.length = 0
        self.u = MortSpecificSubtable()
    }
    public init(length: UInt16, coverage: UInt16, flags: MortSubtableMaskFlags, u: MortSpecificSubtable) {
        self.length = length
        self.coverage = coverage
        self.flags = flags
        self.u = u
    }
}

public struct MortSwashSubtable: Sendable { 
    public var lookup: SFNTLookupTable
    public init() {
        self.lookup = SFNTLookupTable()
    }
    public init(lookup: SFNTLookupTable) {
        self.lookup = lookup
    }
}

public struct MortTable: Sendable { 
    public var chains: MortChain
    public var nChains: UInt32
    public var version: Fixed
    public init() {
        self.chains = MortChain()
        self.nChains = 0
        self.version = 0
    }
    public init(version: Fixed, nChains: UInt32, chains: MortChain) {
        self.version = version
        self.nChains = nChains
        self.chains = chains
    }
}

public struct MorxChain: Sendable { 
    public var defaultFlags: MortSubtableMaskFlags
    public var featureEntries: MortFeatureEntry
    public var length: UInt32
    public var nFeatures: UInt32
    public var nSubtables: UInt32
    public init() {
        self.defaultFlags = 0
        self.featureEntries = MortFeatureEntry()
        self.length = 0
        self.nFeatures = 0
        self.nSubtables = 0
    }
    public init(defaultFlags: MortSubtableMaskFlags, length: UInt32, nFeatures: UInt32, nSubtables: UInt32, featureEntries: MortFeatureEntry) {
        self.defaultFlags = defaultFlags
        self.length = length
        self.nFeatures = nFeatures
        self.nSubtables = nSubtables
        self.featureEntries = featureEntries
    }
}

public struct MorxContextualSubtable: Sendable { 
    public var header: STXHeader
    public var substitutionTableOffset: UInt32
    public init() {
        self.header = STXHeader()
        self.substitutionTableOffset = 0
    }
    public init(header: STXHeader, substitutionTableOffset: UInt32) {
        self.header = header
        self.substitutionTableOffset = substitutionTableOffset
    }
}

public struct MorxInsertionSubtable: Sendable { 
    public var header: STXHeader
    public var insertionGlyphTableOffset: UInt32
    public init() {
        self.header = STXHeader()
        self.insertionGlyphTableOffset = 0
    }
    public init(header: STXHeader, insertionGlyphTableOffset: UInt32) {
        self.header = header
        self.insertionGlyphTableOffset = insertionGlyphTableOffset
    }
}

public struct MorxLigatureSubtable: Sendable { 
    public var componentTableOffset: UInt32
    public var header: STXHeader
    public var ligatureActionTableOffset: UInt32
    public var ligatureTableOffset: UInt32
    public init() {
        self.componentTableOffset = 0
        self.header = STXHeader()
        self.ligatureActionTableOffset = 0
        self.ligatureTableOffset = 0
    }
    public init(header: STXHeader, ligatureActionTableOffset: UInt32, componentTableOffset: UInt32, ligatureTableOffset: UInt32) {
        self.header = header
        self.ligatureActionTableOffset = ligatureActionTableOffset
        self.componentTableOffset = componentTableOffset
        self.ligatureTableOffset = ligatureTableOffset
    }
}

public struct MorxRearrangementSubtable: Sendable { 
    public var header: STXHeader
    public init() {
        self.header = STXHeader()
    }
    public init(header: STXHeader) {
        self.header = header
    }
}

public struct MorxSpecificSubtable: Sendable { 
    public var contextual: MorxContextualSubtable
    public var insertion: MorxInsertionSubtable
    public var ligature: MorxLigatureSubtable
    public var rearrangement: MorxRearrangementSubtable
    public var swash: MortSwashSubtable
    public init() {
        self.contextual = MorxContextualSubtable()
        self.insertion = MorxInsertionSubtable()
        self.ligature = MorxLigatureSubtable()
        self.rearrangement = MorxRearrangementSubtable()
        self.swash = MortSwashSubtable()
    }
    public init(contextual: MorxContextualSubtable) {
        self.contextual = contextual
        self.insertion = MorxInsertionSubtable()
        self.ligature = MorxLigatureSubtable()
        self.rearrangement = MorxRearrangementSubtable()
        self.swash = MortSwashSubtable()
    }
    public init(rearrangement: MorxRearrangementSubtable) {
        self.rearrangement = rearrangement
        self.contextual = MorxContextualSubtable()
        self.insertion = MorxInsertionSubtable()
        self.ligature = MorxLigatureSubtable()
        self.swash = MortSwashSubtable()
    }
    public init(swash: MortSwashSubtable) {
        self.swash = swash
        self.contextual = MorxContextualSubtable()
        self.insertion = MorxInsertionSubtable()
        self.ligature = MorxLigatureSubtable()
        self.rearrangement = MorxRearrangementSubtable()
    }
    public init(ligature: MorxLigatureSubtable) {
        self.ligature = ligature
        self.contextual = MorxContextualSubtable()
        self.insertion = MorxInsertionSubtable()
        self.rearrangement = MorxRearrangementSubtable()
        self.swash = MortSwashSubtable()
    }
    public init(insertion: MorxInsertionSubtable) {
        self.insertion = insertion
        self.contextual = MorxContextualSubtable()
        self.ligature = MorxLigatureSubtable()
        self.rearrangement = MorxRearrangementSubtable()
        self.swash = MortSwashSubtable()
    }
}

public struct MorxSubtable: Sendable { 
    public var coverage: UInt32
    public var flags: MortSubtableMaskFlags
    public var length: UInt32
    public var u: MorxSpecificSubtable
    public init() {
        self.coverage = 0
        self.flags = 0
        self.length = 0
        self.u = MorxSpecificSubtable()
    }
    public init(length: UInt32, coverage: UInt32, flags: MortSubtableMaskFlags, u: MorxSpecificSubtable) {
        self.length = length
        self.coverage = coverage
        self.flags = flags
        self.u = u
    }
}

public struct MorxTable: Sendable { 
    public var chains: MorxChain
    public var nChains: UInt32
    public var version: Fixed
    public init() {
        self.chains = MorxChain()
        self.nChains = 0
        self.version = 0
    }
    public init(version: Fixed, nChains: UInt32, chains: MorxChain) {
        self.version = version
        self.nChains = nChains
        self.chains = chains
    }
}

public struct OpbdSideValues: Sendable { 
    public var bottomSideShift: Int16
    public var leftSideShift: Int16
    public var rightSideShift: Int16
    public var topSideShift: Int16
    public init() {
        self.bottomSideShift = 0
        self.leftSideShift = 0
        self.rightSideShift = 0
        self.topSideShift = 0
    }
    public init(leftSideShift: Int16, topSideShift: Int16, rightSideShift: Int16, bottomSideShift: Int16) {
        self.leftSideShift = leftSideShift
        self.topSideShift = topSideShift
        self.rightSideShift = rightSideShift
        self.bottomSideShift = bottomSideShift
    }
}

public struct OpbdTable: Sendable { 
    public var format: OpbdTableFormat
    public var lookupTable: SFNTLookupTable
    public var version: Fixed
    public init() {
        self.format = 0
        self.lookupTable = SFNTLookupTable()
        self.version = 0
    }
    public init(version: Fixed, format: OpbdTableFormat, lookupTable: SFNTLookupTable) {
        self.version = version
        self.format = format
        self.lookupTable = lookupTable
    }
}

public struct PropLookupSegment: Sendable { 
    public var firstGlyph: UInt16
    public var lastGlyph: UInt16
    public var value: UInt16
    public init() {
        self.firstGlyph = 0
        self.lastGlyph = 0
        self.value = 0
    }
    public init(lastGlyph: UInt16, firstGlyph: UInt16, value: UInt16) {
        self.lastGlyph = lastGlyph
        self.firstGlyph = firstGlyph
        self.value = value
    }
}

public struct PropLookupSingle: Sendable { 
    public var glyph: UInt16
    public var props: PropCharProperties
    public init() {
        self.glyph = 0
        self.props = 0
    }
    public init(glyph: UInt16, props: PropCharProperties) {
        self.glyph = glyph
        self.props = props
    }
}

public struct PropTable: Sendable { 
    public var defaultProps: PropCharProperties
    public var format: UInt16
    public var lookup: SFNTLookupTable
    public var version: Fixed
    public init() {
        self.defaultProps = 0
        self.format = 0
        self.lookup = SFNTLookupTable()
        self.version = 0
    }
    public init(version: Fixed, format: UInt16, defaultProps: PropCharProperties, lookup: SFNTLookupTable) {
        self.version = version
        self.format = format
        self.defaultProps = defaultProps
        self.lookup = lookup
    }
}

public struct ROTAGlyphEntry: Sendable { 
    public var GlyphIndexOffset: Int16
    public var HBaselineOffset: Int16
    public var VBaselineOffset: Int16
    public init() {
        self.GlyphIndexOffset = 0
        self.HBaselineOffset = 0
        self.VBaselineOffset = 0
    }
    public init(GlyphIndexOffset: Int16, HBaselineOffset: Int16, VBaselineOffset: Int16) {
        self.GlyphIndexOffset = GlyphIndexOffset
        self.HBaselineOffset = HBaselineOffset
        self.VBaselineOffset = VBaselineOffset
    }
}

public struct ROTAHeader: Sendable { 
    public var FirstGlyph: UInt16
    public var Flags: UInt16
    public var LastGlyph: UInt16
    public var NMasters: UInt16
    public var Version: Fixed
    public var lookup: SFNTLookupTable
    public init() {
        self.FirstGlyph = 0
        self.Flags = 0
        self.LastGlyph = 0
        self.NMasters = 0
        self.Version = 0
        self.lookup = SFNTLookupTable()
    }
    public init(Version: Fixed, Flags: UInt16, NMasters: UInt16, FirstGlyph: UInt16, LastGlyph: UInt16, lookup: SFNTLookupTable) {
        self.Version = Version
        self.Flags = Flags
        self.NMasters = NMasters
        self.FirstGlyph = FirstGlyph
        self.LastGlyph = LastGlyph
        self.lookup = lookup
    }
}

public struct SFNTLookupArrayHeader: Sendable { 
    public var lookupValues: SFNTLookupValue
    public init() {
        self.lookupValues = 0
    }
    public init(lookupValues: SFNTLookupValue) {
        self.lookupValues = lookupValues
    }
}

public struct SFNTLookupBinarySearchHeader: Sendable { 
    public var entrySelector: UInt16
    public var nUnits: UInt16
    public var rangeShift: UInt16
    public var searchRange: UInt16
    public var unitSize: UInt16
    public init() {
        self.entrySelector = 0
        self.nUnits = 0
        self.rangeShift = 0
        self.searchRange = 0
        self.unitSize = 0
    }
    public init(unitSize: UInt16, nUnits: UInt16, searchRange: UInt16, entrySelector: UInt16, rangeShift: UInt16) {
        self.unitSize = unitSize
        self.nUnits = nUnits
        self.searchRange = searchRange
        self.entrySelector = entrySelector
        self.rangeShift = rangeShift
    }
}

public struct SFNTLookupFormatSpecificHeader: Sendable { 
    public var segment: SFNTLookupSegmentHeader
    public var single: SFNTLookupSingleHeader
    public var theArray: SFNTLookupArrayHeader
    public var trimmedArray: SFNTLookupTrimmedArrayHeader
    public var vector: SFNTLookupVectorHeader
    public init() {
        self.segment = SFNTLookupSegmentHeader()
        self.single = SFNTLookupSingleHeader()
        self.theArray = SFNTLookupArrayHeader()
        self.trimmedArray = SFNTLookupTrimmedArrayHeader()
        self.vector = SFNTLookupVectorHeader()
    }
    public init(trimmedArray: SFNTLookupTrimmedArrayHeader) {
        self.trimmedArray = trimmedArray
        self.segment = SFNTLookupSegmentHeader()
        self.single = SFNTLookupSingleHeader()
        self.theArray = SFNTLookupArrayHeader()
        self.vector = SFNTLookupVectorHeader()
    }
    public init(single: SFNTLookupSingleHeader) {
        self.single = single
        self.segment = SFNTLookupSegmentHeader()
        self.theArray = SFNTLookupArrayHeader()
        self.trimmedArray = SFNTLookupTrimmedArrayHeader()
        self.vector = SFNTLookupVectorHeader()
    }
    public init(vector: SFNTLookupVectorHeader) {
        self.vector = vector
        self.segment = SFNTLookupSegmentHeader()
        self.single = SFNTLookupSingleHeader()
        self.theArray = SFNTLookupArrayHeader()
        self.trimmedArray = SFNTLookupTrimmedArrayHeader()
    }
    public init(segment: SFNTLookupSegmentHeader) {
        self.segment = segment
        self.single = SFNTLookupSingleHeader()
        self.theArray = SFNTLookupArrayHeader()
        self.trimmedArray = SFNTLookupTrimmedArrayHeader()
        self.vector = SFNTLookupVectorHeader()
    }
    public init(theArray: SFNTLookupArrayHeader) {
        self.theArray = theArray
        self.segment = SFNTLookupSegmentHeader()
        self.single = SFNTLookupSingleHeader()
        self.trimmedArray = SFNTLookupTrimmedArrayHeader()
        self.vector = SFNTLookupVectorHeader()
    }
}

public struct SFNTLookupSegment: Sendable { 
    public var firstGlyph: UInt16
    public var lastGlyph: UInt16
    public var value: UInt16
    public init() {
        self.firstGlyph = 0
        self.lastGlyph = 0
        self.value = 0
    }
    public init(lastGlyph: UInt16, firstGlyph: UInt16, value: UInt16) {
        self.lastGlyph = lastGlyph
        self.firstGlyph = firstGlyph
        self.value = value
    }
}

public struct SFNTLookupSegmentHeader: Sendable { 
    public var binSearch: SFNTLookupBinarySearchHeader
    public var segments: SFNTLookupSegment
    public init() {
        self.binSearch = SFNTLookupBinarySearchHeader()
        self.segments = SFNTLookupSegment()
    }
    public init(binSearch: SFNTLookupBinarySearchHeader, segments: SFNTLookupSegment) {
        self.binSearch = binSearch
        self.segments = segments
    }
}

public struct SFNTLookupSingle: Sendable { 
    public var glyph: UInt16
    public var value: UInt16
    public init() {
        self.glyph = 0
        self.value = 0
    }
    public init(glyph: UInt16, value: UInt16) {
        self.glyph = glyph
        self.value = value
    }
}

public struct SFNTLookupSingleHeader: Sendable { 
    public var binSearch: SFNTLookupBinarySearchHeader
    public var entries: SFNTLookupSingle
    public init() {
        self.binSearch = SFNTLookupBinarySearchHeader()
        self.entries = SFNTLookupSingle()
    }
    public init(binSearch: SFNTLookupBinarySearchHeader, entries: SFNTLookupSingle) {
        self.binSearch = binSearch
        self.entries = entries
    }
}

public struct SFNTLookupTable: Sendable { 
    public var format: SFNTLookupTableFormat
    public var fsHeader: SFNTLookupFormatSpecificHeader
    public init() {
        self.format = 0
        self.fsHeader = SFNTLookupFormatSpecificHeader()
    }
    public init(format: SFNTLookupTableFormat, fsHeader: SFNTLookupFormatSpecificHeader) {
        self.format = format
        self.fsHeader = fsHeader
    }
}

public struct SFNTLookupTrimmedArrayHeader: Sendable { 
    public var count: UInt16
    public var firstGlyph: UInt16
    public var valueArray: SFNTLookupValue
    public init() {
        self.count = 0
        self.firstGlyph = 0
        self.valueArray = 0
    }
    public init(firstGlyph: UInt16, count: UInt16, valueArray: SFNTLookupValue) {
        self.firstGlyph = firstGlyph
        self.count = count
        self.valueArray = valueArray
    }
}

public struct SFNTLookupVectorHeader: Sendable { 
    public var count: UInt16
    public var firstGlyph: UInt16
    public var valueSize: UInt16
    public var values: UInt8
    public init() {
        self.count = 0
        self.firstGlyph = 0
        self.valueSize = 0
        self.values = 0
    }
    public init(valueSize: UInt16, firstGlyph: UInt16, count: UInt16, values: UInt8) {
        self.valueSize = valueSize
        self.firstGlyph = firstGlyph
        self.count = count
        self.values = values
    }
}

public struct STClassTable: Sendable { 
    public var classes: STClass
    public var firstGlyph: UInt16
    public var nGlyphs: UInt16
    public init() {
        self.classes = 0
        self.firstGlyph = 0
        self.nGlyphs = 0
    }
    public init(firstGlyph: UInt16, nGlyphs: UInt16, classes: STClass) {
        self.firstGlyph = firstGlyph
        self.nGlyphs = nGlyphs
        self.classes = classes
    }
}

public struct STEntryOne: Sendable { 
    public var flags: UInt16
    public var newState: UInt16
    public var offset1: UInt16
    public init() {
        self.flags = 0
        self.newState = 0
        self.offset1 = 0
    }
    public init(newState: UInt16, flags: UInt16, offset1: UInt16) {
        self.newState = newState
        self.flags = flags
        self.offset1 = offset1
    }
}

public struct STEntryTwo: Sendable { 
    public var flags: UInt16
    public var newState: UInt16
    public var offset1: UInt16
    public var offset2: UInt16
    public init() {
        self.flags = 0
        self.newState = 0
        self.offset1 = 0
        self.offset2 = 0
    }
    public init(newState: UInt16, flags: UInt16, offset1: UInt16, offset2: UInt16) {
        self.newState = newState
        self.flags = flags
        self.offset1 = offset1
        self.offset2 = offset2
    }
}

public struct STEntryZero: Sendable { 
    public var flags: UInt16
    public var newState: UInt16
    public init() {
        self.flags = 0
        self.newState = 0
    }
    public init(newState: UInt16, flags: UInt16) {
        self.newState = newState
        self.flags = flags
    }
}

public struct STHeader: Sendable { 
    public var classTableOffset: UInt16
    public var entryTableOffset: UInt16
    public var filler: UInt8
    public var nClasses: STClass
    public var stateArrayOffset: UInt16
    public init() {
        self.classTableOffset = 0
        self.entryTableOffset = 0
        self.filler = 0
        self.nClasses = 0
        self.stateArrayOffset = 0
    }
    public init(filler: UInt8, nClasses: STClass, classTableOffset: UInt16, stateArrayOffset: UInt16, entryTableOffset: UInt16) {
        self.filler = filler
        self.nClasses = nClasses
        self.classTableOffset = classTableOffset
        self.stateArrayOffset = stateArrayOffset
        self.entryTableOffset = entryTableOffset
    }
}

public struct STXEntryOne: Sendable { 
    public var flags: UInt16
    public var index1: UInt16
    public var newState: STXStateIndex
    public init() {
        self.flags = 0
        self.index1 = 0
        self.newState = 0
    }
    public init(newState: STXStateIndex, flags: UInt16, index1: UInt16) {
        self.newState = newState
        self.flags = flags
        self.index1 = index1
    }
}

public struct STXEntryTwo: Sendable { 
    public var flags: UInt16
    public var index1: UInt16
    public var index2: UInt16
    public var newState: STXStateIndex
    public init() {
        self.flags = 0
        self.index1 = 0
        self.index2 = 0
        self.newState = 0
    }
    public init(newState: STXStateIndex, flags: UInt16, index1: UInt16, index2: UInt16) {
        self.newState = newState
        self.flags = flags
        self.index1 = index1
        self.index2 = index2
    }
}

public struct STXEntryZero: Sendable { 
    public var flags: UInt16
    public var newState: STXStateIndex
    public init() {
        self.flags = 0
        self.newState = 0
    }
    public init(newState: STXStateIndex, flags: UInt16) {
        self.newState = newState
        self.flags = flags
    }
}

public struct STXHeader: Sendable { 
    public var classTableOffset: UInt32
    public var entryTableOffset: UInt32
    public var nClasses: UInt32
    public var stateArrayOffset: UInt32
    public init() {
        self.classTableOffset = 0
        self.entryTableOffset = 0
        self.nClasses = 0
        self.stateArrayOffset = 0
    }
    public init(nClasses: UInt32, classTableOffset: UInt32, stateArrayOffset: UInt32, entryTableOffset: UInt32) {
        self.nClasses = nClasses
        self.classTableOffset = classTableOffset
        self.stateArrayOffset = stateArrayOffset
        self.entryTableOffset = entryTableOffset
    }
}

public struct TrakTable: Sendable { 
    public var format: UInt16
    public var horizOffset: UInt16
    public var version: Fixed
    public var vertOffset: UInt16
    public init() {
        self.format = 0
        self.horizOffset = 0
        self.version = 0
        self.vertOffset = 0
    }
    public init(version: Fixed, format: UInt16, horizOffset: UInt16, vertOffset: UInt16) {
        self.version = version
        self.format = format
        self.horizOffset = horizOffset
        self.vertOffset = vertOffset
    }
}

public struct TrakTableData: Sendable { 
    public var nSizes: UInt16
    public var nTracks: UInt16
    public var sizeTableOffset: UInt32
    public var trakTable: TrakTableEntry
    public init() {
        self.nSizes = 0
        self.nTracks = 0
        self.sizeTableOffset = 0
        self.trakTable = TrakTableEntry()
    }
    public init(nTracks: UInt16, nSizes: UInt16, sizeTableOffset: UInt32, trakTable: TrakTableEntry) {
        self.nTracks = nTracks
        self.nSizes = nSizes
        self.sizeTableOffset = sizeTableOffset
        self.trakTable = trakTable
    }
}

public struct TrakTableEntry: Sendable { 
    public var nameTableIndex: UInt16
    public var sizesOffset: UInt16
    public var track: Fixed
    public init() {
        self.nameTableIndex = 0
        self.sizesOffset = 0
        self.track = 0
    }
    public init(track: Fixed, nameTableIndex: UInt16, sizesOffset: UInt16) {
        self.track = track
        self.nameTableIndex = nameTableIndex
        self.sizesOffset = sizesOffset
    }
}

public struct sfntCMapEncoding: Sendable { 
    public var offset: UInt32
    public var platformID: UInt16
    public var scriptID: UInt16
    public init() {
        self.offset = 0
        self.platformID = 0
        self.scriptID = 0
    }
    public init(platformID: UInt16, scriptID: UInt16, offset: UInt32) {
        self.platformID = platformID
        self.scriptID = scriptID
        self.offset = offset
    }
}

public struct sfntCMapExtendedSubHeader: Sendable { 
    public var format: UInt16
    public var language: UInt32
    public var length: UInt32
    public var reserved: UInt16
    public init() {
        self.format = 0
        self.language = 0
        self.length = 0
        self.reserved = 0
    }
    public init(format: UInt16, reserved: UInt16, length: UInt32, language: UInt32) {
        self.format = format
        self.reserved = reserved
        self.length = length
        self.language = language
    }
}

public struct sfntCMapHeader: Sendable { 
    public var encoding: sfntCMapEncoding
    public var numTables: UInt16
    public var version: UInt16
    public init() {
        self.encoding = sfntCMapEncoding()
        self.numTables = 0
        self.version = 0
    }
    public init(version: UInt16, numTables: UInt16, encoding: sfntCMapEncoding) {
        self.version = version
        self.numTables = numTables
        self.encoding = encoding
    }
}

public struct sfntCMapSubHeader: Sendable { 
    public var format: UInt16
    public var languageID: UInt16
    public var length: UInt16
    public init() {
        self.format = 0
        self.languageID = 0
        self.length = 0
    }
    public init(format: UInt16, length: UInt16, languageID: UInt16) {
        self.format = format
        self.length = length
        self.languageID = languageID
    }
}

public struct sfntDescriptorHeader: Sendable { 
    public var descriptor: sfntFontDescriptor
    public var descriptorCount: Int32
    public var version: Fixed
    public init() {
        self.descriptor = sfntFontDescriptor()
        self.descriptorCount = 0
        self.version = 0
    }
    public init(version: Fixed, descriptorCount: Int32, descriptor: sfntFontDescriptor) {
        self.version = version
        self.descriptorCount = descriptorCount
        self.descriptor = descriptor
    }
}

public struct sfntDirectory: Sendable { 
    public var entrySelector: UInt16
    public var format: FourCharCode
    public var numOffsets: UInt16
    public var rangeShift: UInt16
    public var searchRange: UInt16
    public var table: sfntDirectoryEntry
    public init() {
        self.entrySelector = 0
        self.format = 0
        self.numOffsets = 0
        self.rangeShift = 0
        self.searchRange = 0
        self.table = sfntDirectoryEntry()
    }
    public init(format: FourCharCode, numOffsets: UInt16, searchRange: UInt16, entrySelector: UInt16, rangeShift: UInt16, table: sfntDirectoryEntry) {
        self.format = format
        self.numOffsets = numOffsets
        self.searchRange = searchRange
        self.entrySelector = entrySelector
        self.rangeShift = rangeShift
        self.table = table
    }
}

public struct sfntDirectoryEntry: Sendable { 
    public var checkSum: UInt32
    public var length: UInt32
    public var offset: UInt32
    public var tableTag: FourCharCode
    public init() {
        self.checkSum = 0
        self.length = 0
        self.offset = 0
        self.tableTag = 0
    }
    public init(tableTag: FourCharCode, checkSum: UInt32, offset: UInt32, length: UInt32) {
        self.tableTag = tableTag
        self.checkSum = checkSum
        self.offset = offset
        self.length = length
    }
}

public struct sfntFeatureHeader: Sendable { 
    public var featureNameCount: UInt16
    public var featureSetCount: UInt16
    public var names: sfntFeatureName
    public var reserved: Int32
    public var runs: sfntFontRunFeature
    public var settings: sfntFontFeatureSetting
    public var version: Int32
    public init() {
        self.featureNameCount = 0
        self.featureSetCount = 0
        self.names = sfntFeatureName()
        self.reserved = 0
        self.runs = sfntFontRunFeature()
        self.settings = sfntFontFeatureSetting()
        self.version = 0
    }
    public init(version: Int32, featureNameCount: UInt16, featureSetCount: UInt16, reserved: Int32, names: sfntFeatureName, settings: sfntFontFeatureSetting, runs: sfntFontRunFeature) {
        self.version = version
        self.featureNameCount = featureNameCount
        self.featureSetCount = featureSetCount
        self.reserved = reserved
        self.names = names
        self.settings = settings
        self.runs = runs
    }
}

public struct sfntFeatureName: Sendable { 
    public var featureFlags: UInt16
    public var featureType: UInt16
    public var nameID: Int16
    public var offsetToSettings: Int32
    public var settingCount: UInt16
    public init() {
        self.featureFlags = 0
        self.featureType = 0
        self.nameID = 0
        self.offsetToSettings = 0
        self.settingCount = 0
    }
    public init(featureType: UInt16, settingCount: UInt16, offsetToSettings: Int32, featureFlags: UInt16, nameID: Int16) {
        self.featureType = featureType
        self.settingCount = settingCount
        self.offsetToSettings = offsetToSettings
        self.featureFlags = featureFlags
        self.nameID = nameID
    }
}

public struct sfntFontDescriptor: Sendable { 
    public var name: FourCharCode
    public var value: Fixed
    public init() {
        self.name = 0
        self.value = 0
    }
    public init(name: FourCharCode, value: Fixed) {
        self.name = name
        self.value = value
    }
}

public struct sfntFontFeatureSetting: Sendable { 
    public var nameID: Int16
    public var setting: UInt16
    public init() {
        self.nameID = 0
        self.setting = 0
    }
    public init(setting: UInt16, nameID: Int16) {
        self.setting = setting
        self.nameID = nameID
    }
}

public struct sfntFontRunFeature: Sendable { 
    public var featureType: UInt16
    public var setting: UInt16
    public init() {
        self.featureType = 0
        self.setting = 0
    }
    public init(featureType: UInt16, setting: UInt16) {
        self.featureType = featureType
        self.setting = setting
    }
}

public struct sfntInstance: Sendable { 
    public var coord: Fixed
    public var flags: Int16
    public var nameID: Int16
    public init() {
        self.coord = 0
        self.flags = 0
        self.nameID = 0
    }
    public init(nameID: Int16, flags: Int16, coord: Fixed) {
        self.nameID = nameID
        self.flags = flags
        self.coord = coord
    }
}

public struct sfntNameHeader: Sendable { 
    public var count: UInt16
    public var format: UInt16
    public var rec: sfntNameRecord
    public var stringOffset: UInt16
    public init() {
        self.count = 0
        self.format = 0
        self.rec = sfntNameRecord()
        self.stringOffset = 0
    }
    public init(format: UInt16, count: UInt16, stringOffset: UInt16, rec: sfntNameRecord) {
        self.format = format
        self.count = count
        self.stringOffset = stringOffset
        self.rec = rec
    }
}

public struct sfntNameRecord: Sendable { 
    public var languageID: UInt16
    public var length: UInt16
    public var nameID: UInt16
    public var offset: UInt16
    public var platformID: UInt16
    public var scriptID: UInt16
    public init() {
        self.languageID = 0
        self.length = 0
        self.nameID = 0
        self.offset = 0
        self.platformID = 0
        self.scriptID = 0
    }
    public init(platformID: UInt16, scriptID: UInt16, languageID: UInt16, nameID: UInt16, length: UInt16, offset: UInt16) {
        self.platformID = platformID
        self.scriptID = scriptID
        self.languageID = languageID
        self.nameID = nameID
        self.length = length
        self.offset = offset
    }
}

public struct sfntVariationAxis: Sendable { 
    public var axisTag: FourCharCode
    public var defaultValue: Fixed
    public var flags: Int16
    public var maxValue: Fixed
    public var minValue: Fixed
    public var nameID: Int16
    public init() {
        self.axisTag = 0
        self.defaultValue = 0
        self.flags = 0
        self.maxValue = 0
        self.minValue = 0
        self.nameID = 0
    }
    public init(axisTag: FourCharCode, minValue: Fixed, defaultValue: Fixed, maxValue: Fixed, flags: Int16, nameID: Int16) {
        self.axisTag = axisTag
        self.minValue = minValue
        self.defaultValue = defaultValue
        self.maxValue = maxValue
        self.flags = flags
        self.nameID = nameID
    }
}

public struct sfntVariationHeader: Sendable { 
    public var axis: sfntVariationAxis
    public var axisCount: UInt16
    public var axisSize: UInt16
    public var countSizePairs: UInt16
    public var instance: sfntInstance
    public var instanceCount: UInt16
    public var instanceSize: UInt16
    public var offsetToData: UInt16
    public var version: Fixed
    public init() {
        self.axis = sfntVariationAxis()
        self.axisCount = 0
        self.axisSize = 0
        self.countSizePairs = 0
        self.instance = sfntInstance()
        self.instanceCount = 0
        self.instanceSize = 0
        self.offsetToData = 0
        self.version = 0
    }
    public init(version: Fixed, offsetToData: UInt16, countSizePairs: UInt16, axisCount: UInt16, axisSize: UInt16, instanceCount: UInt16, instanceSize: UInt16, axis: sfntVariationAxis, instance: sfntInstance) {
        self.version = version
        self.offsetToData = offsetToData
        self.countSizePairs = countSizePairs
        self.axisCount = axisCount
        self.axisSize = axisSize
        self.instanceCount = instanceCount
        self.instanceSize = instanceSize
        self.axis = axis
        self.instance = instance
    }
}

// MARK: - Pointer typealiases (after struct types)

public typealias BslnTablePtr = UnsafeMutablePointer<BslnTable>
public typealias KernOffsetTablePtr = UnsafeMutablePointer<KernOffsetTable>
public typealias KernOrderedListEntryPtr = UnsafeMutablePointer<KernOrderedListEntry>
public typealias KernSubtableHeaderPtr = UnsafeMutablePointer<KernSubtableHeader>
public typealias KernTableHeaderHandle = UnsafeMutablePointer<KernTableHeaderPtr?>
public typealias KernTableHeaderPtr = UnsafeMutablePointer<KernTableHeader>
public typealias KerxOrderedListEntryPtr = UnsafeMutablePointer<KerxOrderedListEntry>
public typealias KerxSubtableHeaderPtr = UnsafeMutablePointer<KerxSubtableHeader>
public typealias KerxTableHeaderHandle = UnsafeMutablePointer<KerxTableHeaderPtr?>
public typealias KerxTableHeaderPtr = UnsafeMutablePointer<KerxTableHeader>
public typealias LcarCaretTablePtr = UnsafeMutablePointer<LcarCaretTable>
public typealias SFNTLookupTableHandle = UnsafeMutablePointer<SFNTLookupTablePtr?>
public typealias SFNTLookupTablePtr = UnsafeMutablePointer<SFNTLookupTable>

import Foundation
import CoreText

func testSFNTMasterAnchorAndBaselineTables() {
    var _ALMXGlyphEntryEmpty = ALMXGlyphEntry()
    _ = ALMXGlyphEntry.self
    _ = _ALMXGlyphEntryEmpty.GlyphIndexOffset
    _ALMXGlyphEntryEmpty.GlyphIndexOffset = 7
    precondition(_ALMXGlyphEntryEmpty.GlyphIndexOffset == 7)
    _ = _ALMXGlyphEntryEmpty.HorizontalAdvance
    _ALMXGlyphEntryEmpty.HorizontalAdvance = 7
    precondition(_ALMXGlyphEntryEmpty.HorizontalAdvance == 7)
    _ = _ALMXGlyphEntryEmpty.VerticalAdvance
    _ALMXGlyphEntryEmpty.VerticalAdvance = 7
    precondition(_ALMXGlyphEntryEmpty.VerticalAdvance == 7)
    _ = _ALMXGlyphEntryEmpty.XOffsetToHOrigin
    _ALMXGlyphEntryEmpty.XOffsetToHOrigin = 7
    precondition(_ALMXGlyphEntryEmpty.XOffsetToHOrigin == 7)
    _ = _ALMXGlyphEntryEmpty.YOffsetToVOrigin
    _ALMXGlyphEntryEmpty.YOffsetToVOrigin = 7
    precondition(_ALMXGlyphEntryEmpty.YOffsetToVOrigin == 7)
    var _ALMXHeaderEmpty = ALMXHeader()
    _ = ALMXHeader.self
    _ = _ALMXHeaderEmpty.FirstGlyph
    _ALMXHeaderEmpty.FirstGlyph = 7
    precondition(_ALMXHeaderEmpty.FirstGlyph == 7)
    _ = _ALMXHeaderEmpty.Flags
    _ALMXHeaderEmpty.Flags = 7
    precondition(_ALMXHeaderEmpty.Flags == 7)
    _ = _ALMXHeaderEmpty.LastGlyph
    _ALMXHeaderEmpty.LastGlyph = 7
    precondition(_ALMXHeaderEmpty.LastGlyph == 7)
    _ = _ALMXHeaderEmpty.NMasters
    _ALMXHeaderEmpty.NMasters = 7
    precondition(_ALMXHeaderEmpty.NMasters == 7)
    _ = _ALMXHeaderEmpty.Version
    _ALMXHeaderEmpty.Version = 7
    precondition(_ALMXHeaderEmpty.Version == 7)
    _ = _ALMXHeaderEmpty.lookup
    let _AnchorPointEmpty = AnchorPoint()
    _ = _AnchorPointEmpty
    _ = AnchorPoint.self
    var _AnchorPointTableEmpty = AnchorPointTable()
    _ = AnchorPointTable.self
    _ = _AnchorPointTableEmpty.nPoints
    _AnchorPointTableEmpty.nPoints = 7
    precondition(_AnchorPointTableEmpty.nPoints == 7)
    var _AnkrTableEmpty = AnkrTable()
    _ = AnkrTable.self
    _ = _AnkrTableEmpty.anchorPointTableOffset
    _AnkrTableEmpty.anchorPointTableOffset = 7
    precondition(_AnkrTableEmpty.anchorPointTableOffset == 7)
    _ = _AnkrTableEmpty.flags
    _AnkrTableEmpty.flags = 7
    precondition(_AnkrTableEmpty.flags == 7)
    _ = _AnkrTableEmpty.lookupTableOffset
    _AnkrTableEmpty.lookupTableOffset = 7
    precondition(_AnkrTableEmpty.lookupTableOffset == 7)
    let _BslnFormat0PartEmpty = BslnFormat0Part()
    _ = BslnFormat0Part.self
    _ = _BslnFormat0PartEmpty.deltas
    let _BslnFormat1PartEmpty = BslnFormat1Part()
    _ = BslnFormat1Part.self
    _ = _BslnFormat1PartEmpty.deltas
    _ = _BslnFormat1PartEmpty.mappingData
    var _BslnFormat2PartEmpty = BslnFormat2Part()
    _ = BslnFormat2Part.self
    _ = _BslnFormat2PartEmpty.ctlPoints
    _ = _BslnFormat2PartEmpty.stdGlyph
    _BslnFormat2PartEmpty.stdGlyph = 7
    precondition(_BslnFormat2PartEmpty.stdGlyph == 7)
    var _BslnFormat3PartEmpty = BslnFormat3Part()
    _ = BslnFormat3Part.self
    _ = _BslnFormat3PartEmpty.ctlPoints
    _ = _BslnFormat3PartEmpty.mappingData
    _ = _BslnFormat3PartEmpty.stdGlyph
    _BslnFormat3PartEmpty.stdGlyph = 7
    precondition(_BslnFormat3PartEmpty.stdGlyph == 7)
    var _BslnTableEmpty = BslnTable()
    _ = BslnTable.self
    _ = _BslnTableEmpty.defaultBaseline
    _BslnTableEmpty.defaultBaseline = 7
    precondition(_BslnTableEmpty.defaultBaseline == 7)
    _ = _BslnTableEmpty.format
    _BslnTableEmpty.format = 7
    precondition(_BslnTableEmpty.format == 7)
    _ = _BslnTableEmpty.parts
    let _FontVariationEmpty = FontVariation()
    _ = _FontVariationEmpty
    _ = FontVariation.self
    var _ROTAGlyphEntryEmpty = ROTAGlyphEntry()
    _ = ROTAGlyphEntry.self
    _ = _ROTAGlyphEntryEmpty.GlyphIndexOffset
    _ROTAGlyphEntryEmpty.GlyphIndexOffset = 7
    precondition(_ROTAGlyphEntryEmpty.GlyphIndexOffset == 7)
    _ = _ROTAGlyphEntryEmpty.HBaselineOffset
    _ROTAGlyphEntryEmpty.HBaselineOffset = 7
    precondition(_ROTAGlyphEntryEmpty.HBaselineOffset == 7)
    _ = _ROTAGlyphEntryEmpty.VBaselineOffset
    _ROTAGlyphEntryEmpty.VBaselineOffset = 7
    precondition(_ROTAGlyphEntryEmpty.VBaselineOffset == 7)
    var _ROTAHeaderEmpty = ROTAHeader()
    _ = ROTAHeader.self
    _ = _ROTAHeaderEmpty.FirstGlyph
    _ROTAHeaderEmpty.FirstGlyph = 7
    precondition(_ROTAHeaderEmpty.FirstGlyph == 7)
    _ = _ROTAHeaderEmpty.Flags
    _ROTAHeaderEmpty.Flags = 7
    precondition(_ROTAHeaderEmpty.Flags == 7)
    _ = _ROTAHeaderEmpty.LastGlyph
    _ROTAHeaderEmpty.LastGlyph = 7
    precondition(_ROTAHeaderEmpty.LastGlyph == 7)
    _ = _ROTAHeaderEmpty.NMasters
    _ROTAHeaderEmpty.NMasters = 7
    precondition(_ROTAHeaderEmpty.NMasters == 7)
    _ = _ROTAHeaderEmpty.Version
    _ROTAHeaderEmpty.Version = 7
    precondition(_ROTAHeaderEmpty.Version == 7)
    _ = _ROTAHeaderEmpty.lookup
    let _BslnFormatUnionEmpty = BslnFormatUnion()
    _ = BslnFormatUnion.self
    _ = _BslnFormatUnionEmpty.fmt0Part
    _ = _BslnFormatUnionEmpty.fmt1Part
    _ = _BslnFormatUnionEmpty.fmt2Part
    _ = _BslnFormatUnionEmpty.fmt3Part
    _ = ALMXHeader(Version: 0, Flags: 0, NMasters: 0, FirstGlyph: 0, LastGlyph: 0, lookup: SFNTLookupTable())
    _ = ALMXHeader()
    _ = ROTAHeader(Version: 0, Flags: 0, NMasters: 0, FirstGlyph: 0, LastGlyph: 0, lookup: SFNTLookupTable())
    _ = ROTAHeader()
    _ = AnchorPoint(x: 0, y: 0)
    _ = AnchorPoint()
    _ = FontVariation(name: 0, value: 0)
    _ = FontVariation()
    _ = ALMXGlyphEntry(GlyphIndexOffset: 0, HorizontalAdvance: 0, XOffsetToHOrigin: 0, VerticalAdvance: 0, YOffsetToVOrigin: 0)
    _ = ALMXGlyphEntry()
    _ = ROTAGlyphEntry(GlyphIndexOffset: 0, HBaselineOffset: 0, VBaselineOffset: 0)
    _ = ROTAGlyphEntry()
    _ = BslnFormat0Part(deltas: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    _ = BslnFormat0Part()
    _ = BslnFormat1Part(deltas: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), mappingData: SFNTLookupTable())
    _ = BslnFormat1Part()
    _ = BslnFormat2Part(stdGlyph: 0, ctlPoints: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    _ = BslnFormat2Part()
    _ = BslnFormat3Part(stdGlyph: 0, ctlPoints: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), mappingData: SFNTLookupTable())
    _ = BslnFormat3Part()
    _ = BslnFormatUnion(fmt0Part: BslnFormat0Part())
    _ = BslnFormatUnion(fmt1Part: BslnFormat1Part())
    _ = BslnFormatUnion(fmt2Part: BslnFormat2Part())
    _ = BslnFormatUnion(fmt3Part: BslnFormat3Part())
    _ = BslnFormatUnion()
    _ = AnchorPointTable(nPoints: 0, points: AnchorPoint())
    _ = AnchorPointTable()
    _ = AnkrTable(version: 0, flags: 0, lookupTableOffset: 0, anchorPointTableOffset: 0)
    _ = AnkrTable()
    _ = BslnTable(version: 0, format: 0, defaultBaseline: 0, parts: BslnFormatUnion())
    _ = BslnTable()
}

func testSFNTJustificationTables() {
    var _JustDirectionTableEmpty = JustDirectionTable()
    _ = JustDirectionTable.self
    _ = _JustDirectionTableEmpty.justClass
    _JustDirectionTableEmpty.justClass = 7
    precondition(_JustDirectionTableEmpty.justClass == 7)
    _ = _JustDirectionTableEmpty.lookup
    _ = _JustDirectionTableEmpty.postcomp
    _JustDirectionTableEmpty.postcomp = 7
    precondition(_JustDirectionTableEmpty.postcomp == 7)
    _ = _JustDirectionTableEmpty.widthDeltaClusters
    _JustDirectionTableEmpty.widthDeltaClusters = 7
    precondition(_JustDirectionTableEmpty.widthDeltaClusters == 7)
    var _JustPCActionEmpty = JustPCAction()
    _ = JustPCAction.self
    _ = _JustPCActionEmpty.actionCount
    _JustPCActionEmpty.actionCount = 7
    precondition(_JustPCActionEmpty.actionCount == 7)
    _ = _JustPCActionEmpty.actions
    var _JustPCActionSubrecordEmpty = JustPCActionSubrecord()
    _ = JustPCActionSubrecord.self
    _ = _JustPCActionSubrecordEmpty.theClass
    _JustPCActionSubrecordEmpty.theClass = 7
    precondition(_JustPCActionSubrecordEmpty.theClass == 7)
    _ = _JustPCActionSubrecordEmpty.theType
    _JustPCActionSubrecordEmpty.theType = 7
    precondition(_JustPCActionSubrecordEmpty.theType == 7)
    var _JustPCConditionalAddActionEmpty = JustPCConditionalAddAction()
    _ = JustPCConditionalAddAction.self
    _ = _JustPCConditionalAddActionEmpty.addGlyph
    _JustPCConditionalAddActionEmpty.addGlyph = 7
    precondition(_JustPCConditionalAddActionEmpty.addGlyph == 7)
    _ = _JustPCConditionalAddActionEmpty.substGlyph
    _JustPCConditionalAddActionEmpty.substGlyph = 7
    precondition(_JustPCConditionalAddActionEmpty.substGlyph == 7)
    _ = _JustPCConditionalAddActionEmpty.substThreshold
    _JustPCConditionalAddActionEmpty.substThreshold = 7
    precondition(_JustPCConditionalAddActionEmpty.substThreshold == 7)
    var _JustPCDecompositionActionEmpty = JustPCDecompositionAction()
    _ = JustPCDecompositionAction.self
    _ = _JustPCDecompositionActionEmpty.glyphs
    _JustPCDecompositionActionEmpty.glyphs = 7
    precondition(_JustPCDecompositionActionEmpty.glyphs == 7)
    _ = _JustPCDecompositionActionEmpty.lowerLimit
    _JustPCDecompositionActionEmpty.lowerLimit = 7
    precondition(_JustPCDecompositionActionEmpty.lowerLimit == 7)
    _ = _JustPCDecompositionActionEmpty.order
    _JustPCDecompositionActionEmpty.order = 7
    precondition(_JustPCDecompositionActionEmpty.order == 7)
    _ = _JustPCDecompositionActionEmpty.upperLimit
    _JustPCDecompositionActionEmpty.upperLimit = 7
    precondition(_JustPCDecompositionActionEmpty.upperLimit == 7)
    var _JustPCDuctilityActionEmpty = JustPCDuctilityAction()
    _ = JustPCDuctilityAction.self
    _ = _JustPCDuctilityActionEmpty.ductilityAxis
    _JustPCDuctilityActionEmpty.ductilityAxis = 7
    precondition(_JustPCDuctilityActionEmpty.ductilityAxis == 7)
    _ = _JustPCDuctilityActionEmpty.maximumLimit
    _JustPCDuctilityActionEmpty.maximumLimit = 7
    precondition(_JustPCDuctilityActionEmpty.maximumLimit == 7)
    _ = _JustPCDuctilityActionEmpty.minimumLimit
    _JustPCDuctilityActionEmpty.minimumLimit = 7
    precondition(_JustPCDuctilityActionEmpty.minimumLimit == 7)
    _ = _JustPCDuctilityActionEmpty.noStretchValue
    _JustPCDuctilityActionEmpty.noStretchValue = 7
    precondition(_JustPCDuctilityActionEmpty.noStretchValue == 7)
    var _JustPCGlyphRepeatAddActionEmpty = JustPCGlyphRepeatAddAction()
    _ = JustPCGlyphRepeatAddAction.self
    _ = _JustPCGlyphRepeatAddActionEmpty.flags
    _JustPCGlyphRepeatAddActionEmpty.flags = 7
    precondition(_JustPCGlyphRepeatAddActionEmpty.flags == 7)
    _ = _JustPCGlyphRepeatAddActionEmpty.glyph
    _JustPCGlyphRepeatAddActionEmpty.glyph = 7
    precondition(_JustPCGlyphRepeatAddActionEmpty.glyph == 7)
    let _JustPostcompTableEmpty = JustPostcompTable()
    _ = JustPostcompTable.self
    _ = _JustPostcompTableEmpty.lookupTable
    var _JustTableEmpty = JustTable()
    _ = JustTable.self
    _ = _JustTableEmpty.format
    _JustTableEmpty.format = 7
    precondition(_JustTableEmpty.format == 7)
    _ = _JustTableEmpty.horizHeaderOffset
    _JustTableEmpty.horizHeaderOffset = 7
    precondition(_JustTableEmpty.horizHeaderOffset == 7)
    _ = _JustTableEmpty.vertHeaderOffset
    _JustTableEmpty.vertHeaderOffset = 7
    precondition(_JustTableEmpty.vertHeaderOffset == 7)
    var _JustWidthDeltaEntryEmpty = JustWidthDeltaEntry()
    _ = JustWidthDeltaEntry.self
    _ = _JustWidthDeltaEntryEmpty.afterGrowLimit
    _JustWidthDeltaEntryEmpty.afterGrowLimit = 7
    precondition(_JustWidthDeltaEntryEmpty.afterGrowLimit == 7)
    _ = _JustWidthDeltaEntryEmpty.afterShrinkLimit
    _JustWidthDeltaEntryEmpty.afterShrinkLimit = 7
    precondition(_JustWidthDeltaEntryEmpty.afterShrinkLimit == 7)
    _ = _JustWidthDeltaEntryEmpty.beforeGrowLimit
    _JustWidthDeltaEntryEmpty.beforeGrowLimit = 7
    precondition(_JustWidthDeltaEntryEmpty.beforeGrowLimit == 7)
    _ = _JustWidthDeltaEntryEmpty.beforeShrinkLimit
    _JustWidthDeltaEntryEmpty.beforeShrinkLimit = 7
    precondition(_JustWidthDeltaEntryEmpty.beforeShrinkLimit == 7)
    _ = _JustWidthDeltaEntryEmpty.growFlags
    _JustWidthDeltaEntryEmpty.growFlags = 7
    precondition(_JustWidthDeltaEntryEmpty.growFlags == 7)
    _ = _JustWidthDeltaEntryEmpty.justClass
    _JustWidthDeltaEntryEmpty.justClass = 7
    precondition(_JustWidthDeltaEntryEmpty.justClass == 7)
    _ = _JustWidthDeltaEntryEmpty.shrinkFlags
    _JustWidthDeltaEntryEmpty.shrinkFlags = 7
    precondition(_JustWidthDeltaEntryEmpty.shrinkFlags == 7)
    let _JustWidthDeltaGroupEmpty = JustWidthDeltaGroup()
    _ = JustWidthDeltaGroup.self
    _ = _JustWidthDeltaGroupEmpty.entries
    _ = JustPCAction(actionCount: 0, actions: JustPCActionSubrecord())
    _ = JustPCAction()
    _ = JustPostcompTable(lookupTable: SFNTLookupTable())
    _ = JustPostcompTable()
    _ = JustDirectionTable(justClass: 0, widthDeltaClusters: 0, postcomp: 0, lookup: SFNTLookupTable())
    _ = JustDirectionTable()
    _ = JustWidthDeltaEntry(justClass: 0, beforeGrowLimit: 0, beforeShrinkLimit: 0, afterGrowLimit: 0, afterShrinkLimit: 0, growFlags: 0, shrinkFlags: 0)
    _ = JustWidthDeltaEntry()
    _ = JustWidthDeltaGroup(count: 0, entries: JustWidthDeltaEntry())
    _ = JustWidthDeltaGroup()
    _ = JustPCActionSubrecord(theClass: 0, theType: 0, length: 0, data: 0)
    _ = JustPCActionSubrecord()
    _ = JustPCDuctilityAction(ductilityAxis: 0, minimumLimit: 0, noStretchValue: 0, maximumLimit: 0)
    _ = JustPCDuctilityAction()
    _ = JustPCDecompositionAction(lowerLimit: 0, upperLimit: 0, order: 0, count: 0, glyphs: 0)
    _ = JustPCDecompositionAction()
    _ = JustPCConditionalAddAction(substThreshold: 0, addGlyph: 0, substGlyph: 0)
    _ = JustPCConditionalAddAction()
    _ = JustPCGlyphRepeatAddAction(flags: 0, glyph: 0)
    _ = JustPCGlyphRepeatAddAction()
    _ = JustTable(version: 0, format: 0, horizHeaderOffset: 0, vertHeaderOffset: 0)
    _ = JustTable()
}

func testSFNTKernTables() {
    var _KernIndexArrayHeaderEmpty = KernIndexArrayHeader()
    _ = KernIndexArrayHeader.self
    _ = _KernIndexArrayHeaderEmpty.flags
    _KernIndexArrayHeaderEmpty.flags = 7
    precondition(_KernIndexArrayHeaderEmpty.flags == 7)
    _ = _KernIndexArrayHeaderEmpty.glyphCount
    _KernIndexArrayHeaderEmpty.glyphCount = 7
    precondition(_KernIndexArrayHeaderEmpty.glyphCount == 7)
    _ = _KernIndexArrayHeaderEmpty.kernIndex
    _KernIndexArrayHeaderEmpty.kernIndex = 7
    precondition(_KernIndexArrayHeaderEmpty.kernIndex == 7)
    _ = _KernIndexArrayHeaderEmpty.kernValue
    _KernIndexArrayHeaderEmpty.kernValue = 7
    precondition(_KernIndexArrayHeaderEmpty.kernValue == 7)
    _ = _KernIndexArrayHeaderEmpty.kernValueCount
    _KernIndexArrayHeaderEmpty.kernValueCount = 7
    precondition(_KernIndexArrayHeaderEmpty.kernValueCount == 7)
    _ = _KernIndexArrayHeaderEmpty.leftClass
    _KernIndexArrayHeaderEmpty.leftClass = 7
    precondition(_KernIndexArrayHeaderEmpty.leftClass == 7)
    _ = _KernIndexArrayHeaderEmpty.leftClassCount
    _KernIndexArrayHeaderEmpty.leftClassCount = 7
    precondition(_KernIndexArrayHeaderEmpty.leftClassCount == 7)
    _ = _KernIndexArrayHeaderEmpty.rightClass
    _KernIndexArrayHeaderEmpty.rightClass = 7
    precondition(_KernIndexArrayHeaderEmpty.rightClass == 7)
    _ = _KernIndexArrayHeaderEmpty.rightClassCount
    _KernIndexArrayHeaderEmpty.rightClassCount = 7
    precondition(_KernIndexArrayHeaderEmpty.rightClassCount == 7)
    let _KernKerningPairEmpty = KernKerningPair()
    _ = _KernKerningPairEmpty
    _ = KernKerningPair.self
    var _KernOffsetTableEmpty = KernOffsetTable()
    _ = KernOffsetTable.self
    _ = _KernOffsetTableEmpty.firstGlyph
    _KernOffsetTableEmpty.firstGlyph = 7
    precondition(_KernOffsetTableEmpty.firstGlyph == 7)
    _ = _KernOffsetTableEmpty.nGlyphs
    _KernOffsetTableEmpty.nGlyphs = 7
    precondition(_KernOffsetTableEmpty.nGlyphs == 7)
    _ = _KernOffsetTableEmpty.offsetTable
    _KernOffsetTableEmpty.offsetTable = 7
    precondition(_KernOffsetTableEmpty.offsetTable == 7)
    let _KernOrderedListEntryEmpty = KernOrderedListEntry()
    _ = KernOrderedListEntry.self
    _ = _KernOrderedListEntryEmpty.pair
    var _KernOrderedListHeaderEmpty = KernOrderedListHeader()
    _ = KernOrderedListHeader.self
    _ = _KernOrderedListHeaderEmpty.entrySelector
    _KernOrderedListHeaderEmpty.entrySelector = 7
    precondition(_KernOrderedListHeaderEmpty.entrySelector == 7)
    _ = _KernOrderedListHeaderEmpty.nPairs
    _KernOrderedListHeaderEmpty.nPairs = 7
    precondition(_KernOrderedListHeaderEmpty.nPairs == 7)
    _ = _KernOrderedListHeaderEmpty.rangeShift
    _KernOrderedListHeaderEmpty.rangeShift = 7
    precondition(_KernOrderedListHeaderEmpty.rangeShift == 7)
    _ = _KernOrderedListHeaderEmpty.searchRange
    _KernOrderedListHeaderEmpty.searchRange = 7
    precondition(_KernOrderedListHeaderEmpty.searchRange == 7)
    _ = _KernOrderedListHeaderEmpty.table
    _KernOrderedListHeaderEmpty.table = 7
    precondition(_KernOrderedListHeaderEmpty.table == 7)
    var _KernSimpleArrayHeaderEmpty = KernSimpleArrayHeader()
    _ = KernSimpleArrayHeader.self
    _ = _KernSimpleArrayHeaderEmpty.firstTable
    _KernSimpleArrayHeaderEmpty.firstTable = 7
    precondition(_KernSimpleArrayHeaderEmpty.firstTable == 7)
    _ = _KernSimpleArrayHeaderEmpty.leftOffsetTable
    _KernSimpleArrayHeaderEmpty.leftOffsetTable = 7
    precondition(_KernSimpleArrayHeaderEmpty.leftOffsetTable == 7)
    _ = _KernSimpleArrayHeaderEmpty.rightOffsetTable
    _KernSimpleArrayHeaderEmpty.rightOffsetTable = 7
    precondition(_KernSimpleArrayHeaderEmpty.rightOffsetTable == 7)
    _ = _KernSimpleArrayHeaderEmpty.rowWidth
    _KernSimpleArrayHeaderEmpty.rowWidth = 7
    precondition(_KernSimpleArrayHeaderEmpty.rowWidth == 7)
    _ = _KernSimpleArrayHeaderEmpty.theArray
    _KernSimpleArrayHeaderEmpty.theArray = 7
    precondition(_KernSimpleArrayHeaderEmpty.theArray == 7)
    var _KernStateEntryEmpty = KernStateEntry()
    _ = KernStateEntry.self
    _ = _KernStateEntryEmpty.flags
    _KernStateEntryEmpty.flags = 7
    precondition(_KernStateEntryEmpty.flags == 7)
    _ = _KernStateEntryEmpty.newState
    _KernStateEntryEmpty.newState = 7
    precondition(_KernStateEntryEmpty.newState == 7)
    var _KernStateHeaderEmpty = KernStateHeader()
    _ = KernStateHeader.self
    _ = _KernStateHeaderEmpty.firstTable
    _KernStateHeaderEmpty.firstTable = 7
    precondition(_KernStateHeaderEmpty.firstTable == 7)
    _ = _KernStateHeaderEmpty.header
    _ = _KernStateHeaderEmpty.valueTable
    _KernStateHeaderEmpty.valueTable = 7
    precondition(_KernStateHeaderEmpty.valueTable == 7)
    var _KernSubtableHeaderEmpty = KernSubtableHeader()
    _ = KernSubtableHeader.self
    _ = _KernSubtableHeaderEmpty.fsHeader
    _ = _KernSubtableHeaderEmpty.stInfo
    _KernSubtableHeaderEmpty.stInfo = 7
    precondition(_KernSubtableHeaderEmpty.stInfo == 7)
    _ = _KernSubtableHeaderEmpty.tupleIndex
    _KernSubtableHeaderEmpty.tupleIndex = 7
    precondition(_KernSubtableHeaderEmpty.tupleIndex == 7)
    var _KernTableHeaderEmpty = KernTableHeader()
    _ = KernTableHeader.self
    _ = _KernTableHeaderEmpty.firstSubtable
    _KernTableHeaderEmpty.firstSubtable = 7
    precondition(_KernTableHeaderEmpty.firstSubtable == 7)
    _ = _KernTableHeaderEmpty.nTables
    _KernTableHeaderEmpty.nTables = 7
    precondition(_KernTableHeaderEmpty.nTables == 7)
    var _KernVersion0HeaderEmpty = KernVersion0Header()
    _ = KernVersion0Header.self
    _ = _KernVersion0HeaderEmpty.firstSubtable
    _KernVersion0HeaderEmpty.firstSubtable = 7
    precondition(_KernVersion0HeaderEmpty.firstSubtable == 7)
    _ = _KernVersion0HeaderEmpty.nTables
    _KernVersion0HeaderEmpty.nTables = 7
    precondition(_KernVersion0HeaderEmpty.nTables == 7)
    var _KernVersion0SubtableHeaderEmpty = KernVersion0SubtableHeader()
    _ = KernVersion0SubtableHeader.self
    _ = _KernVersion0SubtableHeaderEmpty.fsHeader
    _ = _KernVersion0SubtableHeaderEmpty.stInfo
    _KernVersion0SubtableHeaderEmpty.stInfo = 7
    precondition(_KernVersion0SubtableHeaderEmpty.stInfo == 7)
    let _KernFormatSpecificHeaderEmpty = KernFormatSpecificHeader()
    _ = KernFormatSpecificHeader.self
    _ = _KernFormatSpecificHeaderEmpty.indexArray
    _ = _KernFormatSpecificHeaderEmpty.orderedList
    _ = _KernFormatSpecificHeaderEmpty.simpleArray
    _ = _KernFormatSpecificHeaderEmpty.stateTable
    _ = KernStateEntry(newState: 0, flags: 0)
    _ = KernStateEntry()
    _ = KernKerningPair()
    _ = KernKerningPair()
    _ = KernOffsetTable(firstGlyph: 0, nGlyphs: 0, offsetTable: 0)
    _ = KernOffsetTable()
    _ = KernStateHeader(header: STHeader(), valueTable: 0, firstTable: 0)
    _ = KernStateHeader()
    _ = KernTableHeader(version: 0, nTables: 0, firstSubtable: 0)
    _ = KernTableHeader()
    _ = KernSubtableHeader(length: 0, stInfo: 0, tupleIndex: 0, fsHeader: KernFormatSpecificHeader())
    _ = KernSubtableHeader()
    _ = KernVersion0Header(version: 0, nTables: 0, firstSubtable: 0)
    _ = KernVersion0Header()
    _ = KernIndexArrayHeader(glyphCount: 0, kernValueCount: 0, leftClassCount: 0, rightClassCount: 0, flags: 0, kernValue: 0, leftClass: 0, rightClass: 0, kernIndex: 0)
    _ = KernIndexArrayHeader()
    _ = KernOrderedListEntry(pair: KernKerningPair(), value: KernKerningValue())
    _ = KernOrderedListEntry()
    _ = KernOrderedListHeader(nPairs: 0, searchRange: 0, entrySelector: 0, rangeShift: 0, table: 0)
    _ = KernOrderedListHeader()
    _ = KernSimpleArrayHeader(rowWidth: 0, leftOffsetTable: 0, rightOffsetTable: 0, theArray: 0, firstTable: 0)
    _ = KernSimpleArrayHeader()
    _ = KernFormatSpecificHeader(indexArray: KernIndexArrayHeader())
    _ = KernFormatSpecificHeader(stateTable: KernStateHeader())
    _ = KernFormatSpecificHeader(orderedList: KernOrderedListHeader())
    _ = KernFormatSpecificHeader(simpleArray: KernSimpleArrayHeader())
    _ = KernFormatSpecificHeader()
    _ = KernVersion0SubtableHeader(version: 0, length: 0, stInfo: 0, fsHeader: KernFormatSpecificHeader())
    _ = KernVersion0SubtableHeader()
}

func testSFNTKerxTables() {
    var _KerxAnchorPointActionEmpty = KerxAnchorPointAction()
    _ = KerxAnchorPointAction.self
    _ = _KerxAnchorPointActionEmpty.currAnchorPoint
    _KerxAnchorPointActionEmpty.currAnchorPoint = 7
    precondition(_KerxAnchorPointActionEmpty.currAnchorPoint == 7)
    _ = _KerxAnchorPointActionEmpty.markAnchorPoint
    _KerxAnchorPointActionEmpty.markAnchorPoint = 7
    precondition(_KerxAnchorPointActionEmpty.markAnchorPoint == 7)
    var _KerxControlPointActionEmpty = KerxControlPointAction()
    _ = KerxControlPointAction.self
    _ = _KerxControlPointActionEmpty.currControlPoint
    _KerxControlPointActionEmpty.currControlPoint = 7
    precondition(_KerxControlPointActionEmpty.currControlPoint == 7)
    _ = _KerxControlPointActionEmpty.markControlPoint
    _KerxControlPointActionEmpty.markControlPoint = 7
    precondition(_KerxControlPointActionEmpty.markControlPoint == 7)
    var _KerxControlPointEntryEmpty = KerxControlPointEntry()
    _ = KerxControlPointEntry.self
    _ = _KerxControlPointEntryEmpty.actionIndex
    _KerxControlPointEntryEmpty.actionIndex = 7
    precondition(_KerxControlPointEntryEmpty.actionIndex == 7)
    _ = _KerxControlPointEntryEmpty.flags
    _KerxControlPointEntryEmpty.flags = 7
    precondition(_KerxControlPointEntryEmpty.flags == 7)
    _ = _KerxControlPointEntryEmpty.newState
    _KerxControlPointEntryEmpty.newState = 7
    precondition(_KerxControlPointEntryEmpty.newState == 7)
    var _KerxControlPointHeaderEmpty = KerxControlPointHeader()
    _ = KerxControlPointHeader.self
    _ = _KerxControlPointHeaderEmpty.firstTable
    _KerxControlPointHeaderEmpty.firstTable = 7
    precondition(_KerxControlPointHeaderEmpty.firstTable == 7)
    _ = _KerxControlPointHeaderEmpty.flags
    _KerxControlPointHeaderEmpty.flags = 7
    precondition(_KerxControlPointHeaderEmpty.flags == 7)
    _ = _KerxControlPointHeaderEmpty.header
    var _KerxCoordinateActionEmpty = KerxCoordinateAction()
    _ = KerxCoordinateAction.self
    _ = _KerxCoordinateActionEmpty.currX
    _KerxCoordinateActionEmpty.currX = 7
    precondition(_KerxCoordinateActionEmpty.currX == 7)
    _ = _KerxCoordinateActionEmpty.currY
    _KerxCoordinateActionEmpty.currY = 7
    precondition(_KerxCoordinateActionEmpty.currY == 7)
    _ = _KerxCoordinateActionEmpty.markX
    _KerxCoordinateActionEmpty.markX = 7
    precondition(_KerxCoordinateActionEmpty.markX == 7)
    _ = _KerxCoordinateActionEmpty.markY
    _KerxCoordinateActionEmpty.markY = 7
    precondition(_KerxCoordinateActionEmpty.markY == 7)
    var _KerxIndexArrayHeaderEmpty = KerxIndexArrayHeader()
    _ = KerxIndexArrayHeader.self
    _ = _KerxIndexArrayHeaderEmpty.columnCount
    _KerxIndexArrayHeaderEmpty.columnCount = 7
    precondition(_KerxIndexArrayHeaderEmpty.columnCount == 7)
    _ = _KerxIndexArrayHeaderEmpty.columnIndexTableOffset
    _KerxIndexArrayHeaderEmpty.columnIndexTableOffset = 7
    precondition(_KerxIndexArrayHeaderEmpty.columnIndexTableOffset == 7)
    _ = _KerxIndexArrayHeaderEmpty.flags
    _KerxIndexArrayHeaderEmpty.flags = 7
    precondition(_KerxIndexArrayHeaderEmpty.flags == 7)
    _ = _KerxIndexArrayHeaderEmpty.kerningArrayOffset
    _KerxIndexArrayHeaderEmpty.kerningArrayOffset = 7
    precondition(_KerxIndexArrayHeaderEmpty.kerningArrayOffset == 7)
    _ = _KerxIndexArrayHeaderEmpty.kerningVectorOffset
    _KerxIndexArrayHeaderEmpty.kerningVectorOffset = 7
    precondition(_KerxIndexArrayHeaderEmpty.kerningVectorOffset == 7)
    _ = _KerxIndexArrayHeaderEmpty.rowCount
    _KerxIndexArrayHeaderEmpty.rowCount = 7
    precondition(_KerxIndexArrayHeaderEmpty.rowCount == 7)
    _ = _KerxIndexArrayHeaderEmpty.rowIndexTableOffset
    _KerxIndexArrayHeaderEmpty.rowIndexTableOffset = 7
    precondition(_KerxIndexArrayHeaderEmpty.rowIndexTableOffset == 7)
    let _KerxKerningPairEmpty = KerxKerningPair()
    _ = _KerxKerningPairEmpty
    _ = KerxKerningPair.self
    let _KerxOrderedListEntryEmpty = KerxOrderedListEntry()
    _ = KerxOrderedListEntry.self
    _ = _KerxOrderedListEntryEmpty.pair
    var _KerxOrderedListHeaderEmpty = KerxOrderedListHeader()
    _ = KerxOrderedListHeader.self
    _ = _KerxOrderedListHeaderEmpty.entrySelector
    _KerxOrderedListHeaderEmpty.entrySelector = 7
    precondition(_KerxOrderedListHeaderEmpty.entrySelector == 7)
    _ = _KerxOrderedListHeaderEmpty.nPairs
    _KerxOrderedListHeaderEmpty.nPairs = 7
    precondition(_KerxOrderedListHeaderEmpty.nPairs == 7)
    _ = _KerxOrderedListHeaderEmpty.rangeShift
    _KerxOrderedListHeaderEmpty.rangeShift = 7
    precondition(_KerxOrderedListHeaderEmpty.rangeShift == 7)
    _ = _KerxOrderedListHeaderEmpty.searchRange
    _KerxOrderedListHeaderEmpty.searchRange = 7
    precondition(_KerxOrderedListHeaderEmpty.searchRange == 7)
    _ = _KerxOrderedListHeaderEmpty.table
    _KerxOrderedListHeaderEmpty.table = 7
    precondition(_KerxOrderedListHeaderEmpty.table == 7)
    var _KerxSimpleArrayHeaderEmpty = KerxSimpleArrayHeader()
    _ = KerxSimpleArrayHeader.self
    _ = _KerxSimpleArrayHeaderEmpty.firstTable
    _KerxSimpleArrayHeaderEmpty.firstTable = 7
    precondition(_KerxSimpleArrayHeaderEmpty.firstTable == 7)
    _ = _KerxSimpleArrayHeaderEmpty.leftOffsetTable
    _KerxSimpleArrayHeaderEmpty.leftOffsetTable = 7
    precondition(_KerxSimpleArrayHeaderEmpty.leftOffsetTable == 7)
    _ = _KerxSimpleArrayHeaderEmpty.rightOffsetTable
    _KerxSimpleArrayHeaderEmpty.rightOffsetTable = 7
    precondition(_KerxSimpleArrayHeaderEmpty.rightOffsetTable == 7)
    _ = _KerxSimpleArrayHeaderEmpty.rowWidth
    _KerxSimpleArrayHeaderEmpty.rowWidth = 7
    precondition(_KerxSimpleArrayHeaderEmpty.rowWidth == 7)
    _ = _KerxSimpleArrayHeaderEmpty.theArray
    _KerxSimpleArrayHeaderEmpty.theArray = 7
    precondition(_KerxSimpleArrayHeaderEmpty.theArray == 7)
    var _KerxStateEntryEmpty = KerxStateEntry()
    _ = KerxStateEntry.self
    _ = _KerxStateEntryEmpty.flags
    _KerxStateEntryEmpty.flags = 7
    precondition(_KerxStateEntryEmpty.flags == 7)
    _ = _KerxStateEntryEmpty.newState
    _KerxStateEntryEmpty.newState = 7
    precondition(_KerxStateEntryEmpty.newState == 7)
    _ = _KerxStateEntryEmpty.valueIndex
    _KerxStateEntryEmpty.valueIndex = 7
    precondition(_KerxStateEntryEmpty.valueIndex == 7)
    var _KerxStateHeaderEmpty = KerxStateHeader()
    _ = KerxStateHeader.self
    _ = _KerxStateHeaderEmpty.firstTable
    _KerxStateHeaderEmpty.firstTable = 7
    precondition(_KerxStateHeaderEmpty.firstTable == 7)
    _ = _KerxStateHeaderEmpty.header
    _ = _KerxStateHeaderEmpty.valueTable
    _KerxStateHeaderEmpty.valueTable = 7
    precondition(_KerxStateHeaderEmpty.valueTable == 7)
    var _KerxSubtableHeaderEmpty = KerxSubtableHeader()
    _ = KerxSubtableHeader.self
    _ = _KerxSubtableHeaderEmpty.fsHeader
    _ = _KerxSubtableHeaderEmpty.stInfo
    _KerxSubtableHeaderEmpty.stInfo = 7
    precondition(_KerxSubtableHeaderEmpty.stInfo == 7)
    _ = _KerxSubtableHeaderEmpty.tupleCount
    _KerxSubtableHeaderEmpty.tupleCount = 7
    precondition(_KerxSubtableHeaderEmpty.tupleCount == 7)
    var _KerxTableHeaderEmpty = KerxTableHeader()
    _ = KerxTableHeader.self
    _ = _KerxTableHeaderEmpty.firstSubtable
    _KerxTableHeaderEmpty.firstSubtable = 7
    precondition(_KerxTableHeaderEmpty.firstSubtable == 7)
    _ = _KerxTableHeaderEmpty.nTables
    _KerxTableHeaderEmpty.nTables = 7
    precondition(_KerxTableHeaderEmpty.nTables == 7)
    let _KerxFormatSpecificHeaderEmpty = KerxFormatSpecificHeader()
    _ = KerxFormatSpecificHeader.self
    _ = _KerxFormatSpecificHeaderEmpty.controlPoint
    _ = _KerxFormatSpecificHeaderEmpty.indexArray
    _ = _KerxFormatSpecificHeaderEmpty.orderedList
    _ = _KerxFormatSpecificHeaderEmpty.simpleArray
    _ = _KerxFormatSpecificHeaderEmpty.stateTable
    _ = KerxStateEntry(newState: 0, flags: 0, valueIndex: 0)
    _ = KerxStateEntry()
    _ = KerxKerningPair()
    _ = KerxKerningPair()
    _ = KerxStateHeader(header: STXHeader(), valueTable: 0, firstTable: 0)
    _ = KerxStateHeader()
    _ = KerxTableHeader(version: 0, nTables: 0, firstSubtable: 0)
    _ = KerxTableHeader()
    _ = KerxSubtableHeader(length: 0, stInfo: 0, tupleCount: 0, fsHeader: KerxFormatSpecificHeader())
    _ = KerxSubtableHeader()
    _ = KerxCoordinateAction(markX: 0, markY: 0, currX: 0, currY: 0)
    _ = KerxCoordinateAction()
    _ = KerxIndexArrayHeader(flags: 0, rowCount: 0, columnCount: 0, rowIndexTableOffset: 0, columnIndexTableOffset: 0, kerningArrayOffset: 0, kerningVectorOffset: 0)
    _ = KerxIndexArrayHeader()
    _ = KerxOrderedListEntry(pair: KerxKerningPair(), value: KernKerningValue())
    _ = KerxOrderedListEntry()
    _ = KerxAnchorPointAction(markAnchorPoint: 0, currAnchorPoint: 0)
    _ = KerxAnchorPointAction()
    _ = KerxControlPointEntry(newState: 0, flags: 0, actionIndex: 0)
    _ = KerxControlPointEntry()
    _ = KerxOrderedListHeader(nPairs: 0, searchRange: 0, entrySelector: 0, rangeShift: 0, table: 0)
    _ = KerxOrderedListHeader()
    _ = KerxSimpleArrayHeader(rowWidth: 0, leftOffsetTable: 0, rightOffsetTable: 0, theArray: 0, firstTable: 0)
    _ = KerxSimpleArrayHeader()
    _ = KerxControlPointAction(markControlPoint: 0, currControlPoint: 0)
    _ = KerxControlPointAction()
    _ = KerxControlPointHeader(header: STXHeader(), flags: 0, firstTable: 0)
    _ = KerxControlPointHeader()
    _ = KerxFormatSpecificHeader(indexArray: KerxIndexArrayHeader())
    _ = KerxFormatSpecificHeader(stateTable: KerxStateHeader())
    _ = KerxFormatSpecificHeader(orderedList: KerxOrderedListHeader())
    _ = KerxFormatSpecificHeader(simpleArray: KerxSimpleArrayHeader())
    _ = KerxFormatSpecificHeader(controlPoint: KerxControlPointHeader())
    _ = KerxFormatSpecificHeader()
}

func testSFNTMortTables() {
    var _MortChainEmpty = MortChain()
    _ = MortChain.self
    _ = _MortChainEmpty.defaultFlags
    _MortChainEmpty.defaultFlags = 7
    precondition(_MortChainEmpty.defaultFlags == 7)
    _ = _MortChainEmpty.featureEntries
    _ = _MortChainEmpty.nFeatures
    _MortChainEmpty.nFeatures = 7
    precondition(_MortChainEmpty.nFeatures == 7)
    _ = _MortChainEmpty.nSubtables
    _MortChainEmpty.nSubtables = 7
    precondition(_MortChainEmpty.nSubtables == 7)
    var _MortContextualSubtableEmpty = MortContextualSubtable()
    _ = MortContextualSubtable.self
    _ = _MortContextualSubtableEmpty.header
    _ = _MortContextualSubtableEmpty.substitutionTableOffset
    _MortContextualSubtableEmpty.substitutionTableOffset = 7
    precondition(_MortContextualSubtableEmpty.substitutionTableOffset == 7)
    var _MortFeatureEntryEmpty = MortFeatureEntry()
    _ = MortFeatureEntry.self
    _ = _MortFeatureEntryEmpty.disableFlags
    _MortFeatureEntryEmpty.disableFlags = 7
    precondition(_MortFeatureEntryEmpty.disableFlags == 7)
    _ = _MortFeatureEntryEmpty.enableFlags
    _MortFeatureEntryEmpty.enableFlags = 7
    precondition(_MortFeatureEntryEmpty.enableFlags == 7)
    _ = _MortFeatureEntryEmpty.featureSelector
    _MortFeatureEntryEmpty.featureSelector = 7
    precondition(_MortFeatureEntryEmpty.featureSelector == 7)
    _ = _MortFeatureEntryEmpty.featureType
    _MortFeatureEntryEmpty.featureType = 7
    precondition(_MortFeatureEntryEmpty.featureType == 7)
    let _MortInsertionSubtableEmpty = MortInsertionSubtable()
    _ = MortInsertionSubtable.self
    _ = _MortInsertionSubtableEmpty.header
    var _MortLigatureSubtableEmpty = MortLigatureSubtable()
    _ = MortLigatureSubtable.self
    _ = _MortLigatureSubtableEmpty.componentTableOffset
    _MortLigatureSubtableEmpty.componentTableOffset = 7
    precondition(_MortLigatureSubtableEmpty.componentTableOffset == 7)
    _ = _MortLigatureSubtableEmpty.header
    _ = _MortLigatureSubtableEmpty.ligatureActionTableOffset
    _MortLigatureSubtableEmpty.ligatureActionTableOffset = 7
    precondition(_MortLigatureSubtableEmpty.ligatureActionTableOffset == 7)
    _ = _MortLigatureSubtableEmpty.ligatureTableOffset
    _MortLigatureSubtableEmpty.ligatureTableOffset = 7
    precondition(_MortLigatureSubtableEmpty.ligatureTableOffset == 7)
    let _MortRearrangementSubtableEmpty = MortRearrangementSubtable()
    _ = MortRearrangementSubtable.self
    _ = _MortRearrangementSubtableEmpty.header
    var _MortSubtableEmpty = MortSubtable()
    _ = MortSubtable.self
    _ = _MortSubtableEmpty.coverage
    _MortSubtableEmpty.coverage = 7
    precondition(_MortSubtableEmpty.coverage == 7)
    _ = _MortSubtableEmpty.flags
    _MortSubtableEmpty.flags = 7
    precondition(_MortSubtableEmpty.flags == 7)
    _ = _MortSubtableEmpty.u
    let _MortSwashSubtableEmpty = MortSwashSubtable()
    _ = MortSwashSubtable.self
    _ = _MortSwashSubtableEmpty.lookup
    var _MortTableEmpty = MortTable()
    _ = MortTable.self
    _ = _MortTableEmpty.chains
    _ = _MortTableEmpty.nChains
    _MortTableEmpty.nChains = 7
    precondition(_MortTableEmpty.nChains == 7)
    let _MortSpecificSubtableEmpty = MortSpecificSubtable()
    _ = MortSpecificSubtable.self
    _ = _MortSpecificSubtableEmpty.contextual
    _ = _MortSpecificSubtableEmpty.insertion
    _ = _MortSpecificSubtableEmpty.ligature
    _ = _MortSpecificSubtableEmpty.rearrangement
    _ = _MortSpecificSubtableEmpty.swash
    _ = MortSubtable(length: 0, coverage: 0, flags: 0, u: MortSpecificSubtable())
    _ = MortSubtable()
    _ = MortFeatureEntry(featureType: 0, featureSelector: 0, enableFlags: 0, disableFlags: 0)
    _ = MortFeatureEntry()
    _ = MortSwashSubtable(lookup: SFNTLookupTable())
    _ = MortSwashSubtable()
    _ = MortLigatureSubtable(header: STHeader(), ligatureActionTableOffset: 0, componentTableOffset: 0, ligatureTableOffset: 0)
    _ = MortLigatureSubtable()
    _ = MortSpecificSubtable(contextual: MortContextualSubtable())
    _ = MortSpecificSubtable(rearrangement: MortRearrangementSubtable())
    _ = MortSpecificSubtable(swash: MortSwashSubtable())
    _ = MortSpecificSubtable(ligature: MortLigatureSubtable())
    _ = MortSpecificSubtable(insertion: MortInsertionSubtable())
    _ = MortSpecificSubtable()
    _ = MortInsertionSubtable(header: STHeader())
    _ = MortInsertionSubtable()
    _ = MortContextualSubtable(header: STHeader(), substitutionTableOffset: 0)
    _ = MortContextualSubtable()
    _ = MortRearrangementSubtable(header: STHeader())
    _ = MortRearrangementSubtable()
    _ = MortChain(defaultFlags: 0, length: 0, nFeatures: 0, nSubtables: 0, featureEntries: MortFeatureEntry())
    _ = MortChain()
    _ = MortTable(version: 0, nChains: 0, chains: MortChain())
    _ = MortTable()
}

func testSFNTMorxTables() {
    var _MorxChainEmpty = MorxChain()
    _ = MorxChain.self
    _ = _MorxChainEmpty.defaultFlags
    _MorxChainEmpty.defaultFlags = 7
    precondition(_MorxChainEmpty.defaultFlags == 7)
    _ = _MorxChainEmpty.featureEntries
    _ = _MorxChainEmpty.nFeatures
    _MorxChainEmpty.nFeatures = 7
    precondition(_MorxChainEmpty.nFeatures == 7)
    _ = _MorxChainEmpty.nSubtables
    _MorxChainEmpty.nSubtables = 7
    precondition(_MorxChainEmpty.nSubtables == 7)
    var _MorxContextualSubtableEmpty = MorxContextualSubtable()
    _ = MorxContextualSubtable.self
    _ = _MorxContextualSubtableEmpty.header
    _ = _MorxContextualSubtableEmpty.substitutionTableOffset
    _MorxContextualSubtableEmpty.substitutionTableOffset = 7
    precondition(_MorxContextualSubtableEmpty.substitutionTableOffset == 7)
    var _MorxInsertionSubtableEmpty = MorxInsertionSubtable()
    _ = MorxInsertionSubtable.self
    _ = _MorxInsertionSubtableEmpty.header
    _ = _MorxInsertionSubtableEmpty.insertionGlyphTableOffset
    _MorxInsertionSubtableEmpty.insertionGlyphTableOffset = 7
    precondition(_MorxInsertionSubtableEmpty.insertionGlyphTableOffset == 7)
    var _MorxLigatureSubtableEmpty = MorxLigatureSubtable()
    _ = MorxLigatureSubtable.self
    _ = _MorxLigatureSubtableEmpty.componentTableOffset
    _MorxLigatureSubtableEmpty.componentTableOffset = 7
    precondition(_MorxLigatureSubtableEmpty.componentTableOffset == 7)
    _ = _MorxLigatureSubtableEmpty.header
    _ = _MorxLigatureSubtableEmpty.ligatureActionTableOffset
    _MorxLigatureSubtableEmpty.ligatureActionTableOffset = 7
    precondition(_MorxLigatureSubtableEmpty.ligatureActionTableOffset == 7)
    _ = _MorxLigatureSubtableEmpty.ligatureTableOffset
    _MorxLigatureSubtableEmpty.ligatureTableOffset = 7
    precondition(_MorxLigatureSubtableEmpty.ligatureTableOffset == 7)
    let _MorxRearrangementSubtableEmpty = MorxRearrangementSubtable()
    _ = MorxRearrangementSubtable.self
    _ = _MorxRearrangementSubtableEmpty.header
    var _MorxSubtableEmpty = MorxSubtable()
    _ = MorxSubtable.self
    _ = _MorxSubtableEmpty.coverage
    _MorxSubtableEmpty.coverage = 7
    precondition(_MorxSubtableEmpty.coverage == 7)
    _ = _MorxSubtableEmpty.flags
    _MorxSubtableEmpty.flags = 7
    precondition(_MorxSubtableEmpty.flags == 7)
    _ = _MorxSubtableEmpty.u
    var _MorxTableEmpty = MorxTable()
    _ = MorxTable.self
    _ = _MorxTableEmpty.chains
    _ = _MorxTableEmpty.nChains
    _MorxTableEmpty.nChains = 7
    precondition(_MorxTableEmpty.nChains == 7)
    let _MorxSpecificSubtableEmpty = MorxSpecificSubtable()
    _ = MorxSpecificSubtable.self
    _ = _MorxSpecificSubtableEmpty.contextual
    _ = _MorxSpecificSubtableEmpty.insertion
    _ = _MorxSpecificSubtableEmpty.ligature
    _ = _MorxSpecificSubtableEmpty.rearrangement
    _ = _MorxSpecificSubtableEmpty.swash
    _ = MorxSubtable(length: 0, coverage: 0, flags: 0, u: MorxSpecificSubtable())
    _ = MorxSubtable()
    _ = MorxLigatureSubtable(header: STXHeader(), ligatureActionTableOffset: 0, componentTableOffset: 0, ligatureTableOffset: 0)
    _ = MorxLigatureSubtable()
    _ = MorxSpecificSubtable(contextual: MorxContextualSubtable())
    _ = MorxSpecificSubtable(rearrangement: MorxRearrangementSubtable())
    _ = MorxSpecificSubtable(swash: MortSwashSubtable())
    _ = MorxSpecificSubtable(ligature: MorxLigatureSubtable())
    _ = MorxSpecificSubtable(insertion: MorxInsertionSubtable())
    _ = MorxSpecificSubtable()
    _ = MorxInsertionSubtable(header: STXHeader(), insertionGlyphTableOffset: 0)
    _ = MorxInsertionSubtable()
    _ = MorxContextualSubtable(header: STXHeader(), substitutionTableOffset: 0)
    _ = MorxContextualSubtable()
    _ = MorxRearrangementSubtable(header: STXHeader())
    _ = MorxRearrangementSubtable()
    _ = MorxChain(defaultFlags: 0, length: 0, nFeatures: 0, nSubtables: 0, featureEntries: MortFeatureEntry())
    _ = MorxChain()
    _ = MorxTable(version: 0, nChains: 0, chains: MorxChain())
    _ = MorxTable()
}

func testSFNTLookupStateAndTrackTables() {
    var _SFNTLookupArrayHeaderEmpty = SFNTLookupArrayHeader()
    _ = SFNTLookupArrayHeader.self
    _ = _SFNTLookupArrayHeaderEmpty.lookupValues
    _SFNTLookupArrayHeaderEmpty.lookupValues = 7
    precondition(_SFNTLookupArrayHeaderEmpty.lookupValues == 7)
    var _SFNTLookupBinarySearchHeaderEmpty = SFNTLookupBinarySearchHeader()
    _ = SFNTLookupBinarySearchHeader.self
    _ = _SFNTLookupBinarySearchHeaderEmpty.entrySelector
    _SFNTLookupBinarySearchHeaderEmpty.entrySelector = 7
    precondition(_SFNTLookupBinarySearchHeaderEmpty.entrySelector == 7)
    _ = _SFNTLookupBinarySearchHeaderEmpty.nUnits
    _SFNTLookupBinarySearchHeaderEmpty.nUnits = 7
    precondition(_SFNTLookupBinarySearchHeaderEmpty.nUnits == 7)
    _ = _SFNTLookupBinarySearchHeaderEmpty.rangeShift
    _SFNTLookupBinarySearchHeaderEmpty.rangeShift = 7
    precondition(_SFNTLookupBinarySearchHeaderEmpty.rangeShift == 7)
    _ = _SFNTLookupBinarySearchHeaderEmpty.searchRange
    _SFNTLookupBinarySearchHeaderEmpty.searchRange = 7
    precondition(_SFNTLookupBinarySearchHeaderEmpty.searchRange == 7)
    _ = _SFNTLookupBinarySearchHeaderEmpty.unitSize
    _SFNTLookupBinarySearchHeaderEmpty.unitSize = 7
    precondition(_SFNTLookupBinarySearchHeaderEmpty.unitSize == 7)
    var _SFNTLookupSegmentEmpty = SFNTLookupSegment()
    _ = SFNTLookupSegment.self
    _ = _SFNTLookupSegmentEmpty.firstGlyph
    _SFNTLookupSegmentEmpty.firstGlyph = 7
    precondition(_SFNTLookupSegmentEmpty.firstGlyph == 7)
    _ = _SFNTLookupSegmentEmpty.lastGlyph
    _SFNTLookupSegmentEmpty.lastGlyph = 7
    precondition(_SFNTLookupSegmentEmpty.lastGlyph == 7)
    let _SFNTLookupSegmentHeaderEmpty = SFNTLookupSegmentHeader()
    _ = SFNTLookupSegmentHeader.self
    _ = _SFNTLookupSegmentHeaderEmpty.binSearch
    _ = _SFNTLookupSegmentHeaderEmpty.segments
    var _SFNTLookupSingleEmpty = SFNTLookupSingle()
    _ = SFNTLookupSingle.self
    _ = _SFNTLookupSingleEmpty.glyph
    _SFNTLookupSingleEmpty.glyph = 7
    precondition(_SFNTLookupSingleEmpty.glyph == 7)
    let _SFNTLookupSingleHeaderEmpty = SFNTLookupSingleHeader()
    _ = SFNTLookupSingleHeader.self
    _ = _SFNTLookupSingleHeaderEmpty.binSearch
    _ = _SFNTLookupSingleHeaderEmpty.entries
    var _SFNTLookupTableEmpty = SFNTLookupTable()
    _ = SFNTLookupTable.self
    _ = _SFNTLookupTableEmpty.format
    _SFNTLookupTableEmpty.format = 7
    precondition(_SFNTLookupTableEmpty.format == 7)
    _ = _SFNTLookupTableEmpty.fsHeader
    var _SFNTLookupTrimmedArrayHeaderEmpty = SFNTLookupTrimmedArrayHeader()
    _ = SFNTLookupTrimmedArrayHeader.self
    _ = _SFNTLookupTrimmedArrayHeaderEmpty.firstGlyph
    _SFNTLookupTrimmedArrayHeaderEmpty.firstGlyph = 7
    precondition(_SFNTLookupTrimmedArrayHeaderEmpty.firstGlyph == 7)
    _ = _SFNTLookupTrimmedArrayHeaderEmpty.valueArray
    _SFNTLookupTrimmedArrayHeaderEmpty.valueArray = 7
    precondition(_SFNTLookupTrimmedArrayHeaderEmpty.valueArray == 7)
    var _SFNTLookupVectorHeaderEmpty = SFNTLookupVectorHeader()
    _ = SFNTLookupVectorHeader.self
    _ = _SFNTLookupVectorHeaderEmpty.firstGlyph
    _SFNTLookupVectorHeaderEmpty.firstGlyph = 7
    precondition(_SFNTLookupVectorHeaderEmpty.firstGlyph == 7)
    _ = _SFNTLookupVectorHeaderEmpty.values
    _SFNTLookupVectorHeaderEmpty.values = 7
    precondition(_SFNTLookupVectorHeaderEmpty.values == 7)
    var _STClassTableEmpty = STClassTable()
    _ = STClassTable.self
    _ = _STClassTableEmpty.classes
    _STClassTableEmpty.classes = 7
    precondition(_STClassTableEmpty.classes == 7)
    _ = _STClassTableEmpty.firstGlyph
    _STClassTableEmpty.firstGlyph = 7
    precondition(_STClassTableEmpty.firstGlyph == 7)
    _ = _STClassTableEmpty.nGlyphs
    _STClassTableEmpty.nGlyphs = 7
    precondition(_STClassTableEmpty.nGlyphs == 7)
    var _STEntryOneEmpty = STEntryOne()
    _ = STEntryOne.self
    _ = _STEntryOneEmpty.flags
    _STEntryOneEmpty.flags = 7
    precondition(_STEntryOneEmpty.flags == 7)
    _ = _STEntryOneEmpty.newState
    _STEntryOneEmpty.newState = 7
    precondition(_STEntryOneEmpty.newState == 7)
    _ = _STEntryOneEmpty.offset1
    _STEntryOneEmpty.offset1 = 7
    precondition(_STEntryOneEmpty.offset1 == 7)
    var _STEntryTwoEmpty = STEntryTwo()
    _ = STEntryTwo.self
    _ = _STEntryTwoEmpty.flags
    _STEntryTwoEmpty.flags = 7
    precondition(_STEntryTwoEmpty.flags == 7)
    _ = _STEntryTwoEmpty.newState
    _STEntryTwoEmpty.newState = 7
    precondition(_STEntryTwoEmpty.newState == 7)
    _ = _STEntryTwoEmpty.offset1
    _STEntryTwoEmpty.offset1 = 7
    precondition(_STEntryTwoEmpty.offset1 == 7)
    _ = _STEntryTwoEmpty.offset2
    _STEntryTwoEmpty.offset2 = 7
    precondition(_STEntryTwoEmpty.offset2 == 7)
    var _STEntryZeroEmpty = STEntryZero()
    _ = STEntryZero.self
    _ = _STEntryZeroEmpty.flags
    _STEntryZeroEmpty.flags = 7
    precondition(_STEntryZeroEmpty.flags == 7)
    _ = _STEntryZeroEmpty.newState
    _STEntryZeroEmpty.newState = 7
    precondition(_STEntryZeroEmpty.newState == 7)
    var _STHeaderEmpty = STHeader()
    _ = STHeader.self
    _ = _STHeaderEmpty.classTableOffset
    _STHeaderEmpty.classTableOffset = 7
    precondition(_STHeaderEmpty.classTableOffset == 7)
    _ = _STHeaderEmpty.entryTableOffset
    _STHeaderEmpty.entryTableOffset = 7
    precondition(_STHeaderEmpty.entryTableOffset == 7)
    _ = _STHeaderEmpty.filler
    _STHeaderEmpty.filler = 7
    precondition(_STHeaderEmpty.filler == 7)
    _ = _STHeaderEmpty.nClasses
    _STHeaderEmpty.nClasses = 7
    precondition(_STHeaderEmpty.nClasses == 7)
    _ = _STHeaderEmpty.stateArrayOffset
    _STHeaderEmpty.stateArrayOffset = 7
    precondition(_STHeaderEmpty.stateArrayOffset == 7)
    var _STXEntryOneEmpty = STXEntryOne()
    _ = STXEntryOne.self
    _ = _STXEntryOneEmpty.flags
    _STXEntryOneEmpty.flags = 7
    precondition(_STXEntryOneEmpty.flags == 7)
    _ = _STXEntryOneEmpty.index1
    _STXEntryOneEmpty.index1 = 7
    precondition(_STXEntryOneEmpty.index1 == 7)
    _ = _STXEntryOneEmpty.newState
    _STXEntryOneEmpty.newState = 7
    precondition(_STXEntryOneEmpty.newState == 7)
    var _STXEntryTwoEmpty = STXEntryTwo()
    _ = STXEntryTwo.self
    _ = _STXEntryTwoEmpty.flags
    _STXEntryTwoEmpty.flags = 7
    precondition(_STXEntryTwoEmpty.flags == 7)
    _ = _STXEntryTwoEmpty.index1
    _STXEntryTwoEmpty.index1 = 7
    precondition(_STXEntryTwoEmpty.index1 == 7)
    _ = _STXEntryTwoEmpty.index2
    _STXEntryTwoEmpty.index2 = 7
    precondition(_STXEntryTwoEmpty.index2 == 7)
    _ = _STXEntryTwoEmpty.newState
    _STXEntryTwoEmpty.newState = 7
    precondition(_STXEntryTwoEmpty.newState == 7)
    var _STXEntryZeroEmpty = STXEntryZero()
    _ = STXEntryZero.self
    _ = _STXEntryZeroEmpty.flags
    _STXEntryZeroEmpty.flags = 7
    precondition(_STXEntryZeroEmpty.flags == 7)
    _ = _STXEntryZeroEmpty.newState
    _STXEntryZeroEmpty.newState = 7
    precondition(_STXEntryZeroEmpty.newState == 7)
    var _STXHeaderEmpty = STXHeader()
    _ = STXHeader.self
    _ = _STXHeaderEmpty.classTableOffset
    _STXHeaderEmpty.classTableOffset = 7
    precondition(_STXHeaderEmpty.classTableOffset == 7)
    _ = _STXHeaderEmpty.entryTableOffset
    _STXHeaderEmpty.entryTableOffset = 7
    precondition(_STXHeaderEmpty.entryTableOffset == 7)
    _ = _STXHeaderEmpty.nClasses
    _STXHeaderEmpty.nClasses = 7
    precondition(_STXHeaderEmpty.nClasses == 7)
    _ = _STXHeaderEmpty.stateArrayOffset
    _STXHeaderEmpty.stateArrayOffset = 7
    precondition(_STXHeaderEmpty.stateArrayOffset == 7)
    var _TrakTableEmpty = TrakTable()
    _ = TrakTable.self
    _ = _TrakTableEmpty.format
    _TrakTableEmpty.format = 7
    precondition(_TrakTableEmpty.format == 7)
    _ = _TrakTableEmpty.horizOffset
    _TrakTableEmpty.horizOffset = 7
    precondition(_TrakTableEmpty.horizOffset == 7)
    _ = _TrakTableEmpty.vertOffset
    _TrakTableEmpty.vertOffset = 7
    precondition(_TrakTableEmpty.vertOffset == 7)
    var _TrakTableDataEmpty = TrakTableData()
    _ = TrakTableData.self
    _ = _TrakTableDataEmpty.nSizes
    _TrakTableDataEmpty.nSizes = 7
    precondition(_TrakTableDataEmpty.nSizes == 7)
    _ = _TrakTableDataEmpty.nTracks
    _TrakTableDataEmpty.nTracks = 7
    precondition(_TrakTableDataEmpty.nTracks == 7)
    _ = _TrakTableDataEmpty.sizeTableOffset
    _TrakTableDataEmpty.sizeTableOffset = 7
    precondition(_TrakTableDataEmpty.sizeTableOffset == 7)
    _ = _TrakTableDataEmpty.trakTable
    var _TrakTableEntryEmpty = TrakTableEntry()
    _ = TrakTableEntry.self
    _ = _TrakTableEntryEmpty.nameTableIndex
    _TrakTableEntryEmpty.nameTableIndex = 7
    precondition(_TrakTableEntryEmpty.nameTableIndex == 7)
    _ = _TrakTableEntryEmpty.sizesOffset
    _TrakTableEntryEmpty.sizesOffset = 7
    precondition(_TrakTableEntryEmpty.sizesOffset == 7)
    _ = _TrakTableEntryEmpty.track
    _TrakTableEntryEmpty.track = 7
    precondition(_TrakTableEntryEmpty.track == 7)
    let _SFNTLookupFormatSpecificHeaderEmpty = SFNTLookupFormatSpecificHeader()
    _ = SFNTLookupFormatSpecificHeader.self
    _ = _SFNTLookupFormatSpecificHeaderEmpty.segment
    _ = _SFNTLookupFormatSpecificHeaderEmpty.theArray
    _ = _SFNTLookupFormatSpecificHeaderEmpty.trimmedArray
    _ = _SFNTLookupFormatSpecificHeaderEmpty.vector
    _ = STEntryOne(newState: 0, flags: 0, offset1: 0)
    _ = STEntryOne()
    _ = STEntryTwo(newState: 0, flags: 0, offset1: 0, offset2: 0)
    _ = STEntryTwo()
    _ = STEntryZero(newState: 0, flags: 0)
    _ = STEntryZero()
    _ = STXEntryOne(newState: 0, flags: 0, index1: 0)
    _ = STXEntryOne()
    _ = STXEntryTwo(newState: 0, flags: 0, index1: 0, index2: 0)
    _ = STXEntryTwo()
    _ = STClassTable(firstGlyph: 0, nGlyphs: 0, classes: 0)
    _ = STClassTable()
    _ = STXEntryZero(newState: 0, flags: 0)
    _ = STXEntryZero()
    _ = TrakTableData(nTracks: 0, nSizes: 0, sizeTableOffset: 0, trakTable: TrakTableEntry())
    _ = TrakTableData()
    _ = TrakTableEntry(track: 0, nameTableIndex: 0, sizesOffset: 0)
    _ = TrakTableEntry()
    _ = SFNTLookupTable(format: 0, fsHeader: SFNTLookupFormatSpecificHeader())
    _ = SFNTLookupTable()
    _ = SFNTLookupSingle(glyph: 0, value: 0)
    _ = SFNTLookupSingle()
    _ = SFNTLookupSegment(lastGlyph: 0, firstGlyph: 0, value: 0)
    _ = SFNTLookupSegment()
    _ = SFNTLookupArrayHeader(lookupValues: 0)
    _ = SFNTLookupArrayHeader()
    _ = SFNTLookupSingleHeader(binSearch: SFNTLookupBinarySearchHeader(), entries: SFNTLookupSingle())
    _ = SFNTLookupSingleHeader()
    _ = SFNTLookupVectorHeader(valueSize: 0, firstGlyph: 0, count: 0, values: 0)
    _ = SFNTLookupVectorHeader()
    _ = SFNTLookupSegmentHeader(binSearch: SFNTLookupBinarySearchHeader(), segments: SFNTLookupSegment())
    _ = SFNTLookupSegmentHeader()
    _ = SFNTLookupBinarySearchHeader(unitSize: 0, nUnits: 0, searchRange: 0, entrySelector: 0, rangeShift: 0)
    _ = SFNTLookupBinarySearchHeader()
    _ = SFNTLookupTrimmedArrayHeader(firstGlyph: 0, count: 0, valueArray: 0)
    _ = SFNTLookupTrimmedArrayHeader()
    _ = SFNTLookupFormatSpecificHeader(trimmedArray: SFNTLookupTrimmedArrayHeader())
    _ = SFNTLookupFormatSpecificHeader(single: SFNTLookupSingleHeader())
    _ = SFNTLookupFormatSpecificHeader(vector: SFNTLookupVectorHeader())
    _ = SFNTLookupFormatSpecificHeader(segment: SFNTLookupSegmentHeader())
    _ = SFNTLookupFormatSpecificHeader(theArray: SFNTLookupArrayHeader())
    _ = SFNTLookupFormatSpecificHeader()
    _ = STHeader(filler: 0, nClasses: 0, classTableOffset: 0, stateArrayOffset: 0, entryTableOffset: 0)
    _ = STHeader()
    _ = STXHeader(nClasses: 0, classTableOffset: 0, stateArrayOffset: 0, entryTableOffset: 0)
    _ = STXHeader()
    _ = TrakTable(version: 0, format: 0, horizOffset: 0, vertOffset: 0)
    _ = TrakTable()
}

func testSFNTCmapNamePropAndDirectoryTables() {
    var _LcarCaretClassEntryEmpty = LcarCaretClassEntry()
    _ = LcarCaretClassEntry.self
    _ = _LcarCaretClassEntryEmpty.partials
    _LcarCaretClassEntryEmpty.partials = 7
    precondition(_LcarCaretClassEntryEmpty.partials == 7)
    var _LcarCaretTableEmpty = LcarCaretTable()
    _ = LcarCaretTable.self
    _ = _LcarCaretTableEmpty.format
    _LcarCaretTableEmpty.format = 7
    precondition(_LcarCaretTableEmpty.format == 7)
    _ = _LcarCaretTableEmpty.lookup
    let _LtagStringRangeEmpty = LtagStringRange()
    _ = _LtagStringRangeEmpty
    _ = LtagStringRange.self
    var _LtagTableEmpty = LtagTable()
    _ = LtagTable.self
    _ = _LtagTableEmpty.flags
    _LtagTableEmpty.flags = 7
    precondition(_LtagTableEmpty.flags == 7)
    _ = _LtagTableEmpty.numTags
    _LtagTableEmpty.numTags = 7
    precondition(_LtagTableEmpty.numTags == 7)
    _ = _LtagTableEmpty.tagRange
    var _OpbdSideValuesEmpty = OpbdSideValues()
    _ = OpbdSideValues.self
    _ = _OpbdSideValuesEmpty.bottomSideShift
    _OpbdSideValuesEmpty.bottomSideShift = 7
    precondition(_OpbdSideValuesEmpty.bottomSideShift == 7)
    _ = _OpbdSideValuesEmpty.leftSideShift
    _OpbdSideValuesEmpty.leftSideShift = 7
    precondition(_OpbdSideValuesEmpty.leftSideShift == 7)
    _ = _OpbdSideValuesEmpty.rightSideShift
    _OpbdSideValuesEmpty.rightSideShift = 7
    precondition(_OpbdSideValuesEmpty.rightSideShift == 7)
    _ = _OpbdSideValuesEmpty.topSideShift
    _OpbdSideValuesEmpty.topSideShift = 7
    precondition(_OpbdSideValuesEmpty.topSideShift == 7)
    var _OpbdTableEmpty = OpbdTable()
    _ = OpbdTable.self
    _ = _OpbdTableEmpty.format
    _OpbdTableEmpty.format = 7
    precondition(_OpbdTableEmpty.format == 7)
    _ = _OpbdTableEmpty.lookupTable
    var _PropLookupSegmentEmpty = PropLookupSegment()
    _ = PropLookupSegment.self
    _ = _PropLookupSegmentEmpty.firstGlyph
    _PropLookupSegmentEmpty.firstGlyph = 7
    precondition(_PropLookupSegmentEmpty.firstGlyph == 7)
    _ = _PropLookupSegmentEmpty.lastGlyph
    _PropLookupSegmentEmpty.lastGlyph = 7
    precondition(_PropLookupSegmentEmpty.lastGlyph == 7)
    var _PropLookupSingleEmpty = PropLookupSingle()
    _ = PropLookupSingle.self
    _ = _PropLookupSingleEmpty.glyph
    _PropLookupSingleEmpty.glyph = 7
    precondition(_PropLookupSingleEmpty.glyph == 7)
    _ = _PropLookupSingleEmpty.props
    _PropLookupSingleEmpty.props = 7
    precondition(_PropLookupSingleEmpty.props == 7)
    var _PropTableEmpty = PropTable()
    _ = PropTable.self
    _ = _PropTableEmpty.defaultProps
    _PropTableEmpty.defaultProps = 7
    precondition(_PropTableEmpty.defaultProps == 7)
    _ = _PropTableEmpty.format
    _PropTableEmpty.format = 7
    precondition(_PropTableEmpty.format == 7)
    _ = _PropTableEmpty.lookup
    var _sfntCMapEncodingEmpty = sfntCMapEncoding()
    _ = sfntCMapEncoding.self
    _ = _sfntCMapEncodingEmpty.platformID
    _sfntCMapEncodingEmpty.platformID = 7
    precondition(_sfntCMapEncodingEmpty.platformID == 7)
    _ = _sfntCMapEncodingEmpty.scriptID
    _sfntCMapEncodingEmpty.scriptID = 7
    precondition(_sfntCMapEncodingEmpty.scriptID == 7)
    var _sfntCMapExtendedSubHeaderEmpty = sfntCMapExtendedSubHeader()
    _ = sfntCMapExtendedSubHeader.self
    _ = _sfntCMapExtendedSubHeaderEmpty.format
    _sfntCMapExtendedSubHeaderEmpty.format = 7
    precondition(_sfntCMapExtendedSubHeaderEmpty.format == 7)
    _ = _sfntCMapExtendedSubHeaderEmpty.reserved
    _sfntCMapExtendedSubHeaderEmpty.reserved = 7
    precondition(_sfntCMapExtendedSubHeaderEmpty.reserved == 7)
    var _sfntCMapHeaderEmpty = sfntCMapHeader()
    _ = sfntCMapHeader.self
    _ = _sfntCMapHeaderEmpty.encoding
    _ = _sfntCMapHeaderEmpty.numTables
    _sfntCMapHeaderEmpty.numTables = 7
    precondition(_sfntCMapHeaderEmpty.numTables == 7)
    var _sfntCMapSubHeaderEmpty = sfntCMapSubHeader()
    _ = sfntCMapSubHeader.self
    _ = _sfntCMapSubHeaderEmpty.format
    _sfntCMapSubHeaderEmpty.format = 7
    precondition(_sfntCMapSubHeaderEmpty.format == 7)
    _ = _sfntCMapSubHeaderEmpty.languageID
    _sfntCMapSubHeaderEmpty.languageID = 7
    precondition(_sfntCMapSubHeaderEmpty.languageID == 7)
    var _sfntDescriptorHeaderEmpty = sfntDescriptorHeader()
    _ = sfntDescriptorHeader.self
    _ = _sfntDescriptorHeaderEmpty.descriptorCount
    _sfntDescriptorHeaderEmpty.descriptorCount = 7
    precondition(_sfntDescriptorHeaderEmpty.descriptorCount == 7)
    var _sfntDirectoryEmpty = sfntDirectory()
    _ = sfntDirectory.self
    _ = _sfntDirectoryEmpty.entrySelector
    _sfntDirectoryEmpty.entrySelector = 7
    precondition(_sfntDirectoryEmpty.entrySelector == 7)
    _ = _sfntDirectoryEmpty.format
    _sfntDirectoryEmpty.format = 7
    precondition(_sfntDirectoryEmpty.format == 7)
    _ = _sfntDirectoryEmpty.numOffsets
    _sfntDirectoryEmpty.numOffsets = 7
    precondition(_sfntDirectoryEmpty.numOffsets == 7)
    _ = _sfntDirectoryEmpty.rangeShift
    _sfntDirectoryEmpty.rangeShift = 7
    precondition(_sfntDirectoryEmpty.rangeShift == 7)
    _ = _sfntDirectoryEmpty.searchRange
    _sfntDirectoryEmpty.searchRange = 7
    precondition(_sfntDirectoryEmpty.searchRange == 7)
    _ = _sfntDirectoryEmpty.table
    var _sfntDirectoryEntryEmpty = sfntDirectoryEntry()
    _ = sfntDirectoryEntry.self
    _ = _sfntDirectoryEntryEmpty.checkSum
    _sfntDirectoryEntryEmpty.checkSum = 7
    precondition(_sfntDirectoryEntryEmpty.checkSum == 7)
    _ = _sfntDirectoryEntryEmpty.tableTag
    _sfntDirectoryEntryEmpty.tableTag = 7
    precondition(_sfntDirectoryEntryEmpty.tableTag == 7)
    var _sfntFeatureHeaderEmpty = sfntFeatureHeader()
    _ = sfntFeatureHeader.self
    _ = _sfntFeatureHeaderEmpty.featureNameCount
    _sfntFeatureHeaderEmpty.featureNameCount = 7
    precondition(_sfntFeatureHeaderEmpty.featureNameCount == 7)
    _ = _sfntFeatureHeaderEmpty.featureSetCount
    _sfntFeatureHeaderEmpty.featureSetCount = 7
    precondition(_sfntFeatureHeaderEmpty.featureSetCount == 7)
    _ = _sfntFeatureHeaderEmpty.names
    _ = _sfntFeatureHeaderEmpty.reserved
    _sfntFeatureHeaderEmpty.reserved = 7
    precondition(_sfntFeatureHeaderEmpty.reserved == 7)
    _ = _sfntFeatureHeaderEmpty.settings
    var _sfntFeatureNameEmpty = sfntFeatureName()
    _ = sfntFeatureName.self
    _ = _sfntFeatureNameEmpty.featureFlags
    _sfntFeatureNameEmpty.featureFlags = 7
    precondition(_sfntFeatureNameEmpty.featureFlags == 7)
    _ = _sfntFeatureNameEmpty.featureType
    _sfntFeatureNameEmpty.featureType = 7
    precondition(_sfntFeatureNameEmpty.featureType == 7)
    _ = _sfntFeatureNameEmpty.nameID
    _sfntFeatureNameEmpty.nameID = 7
    precondition(_sfntFeatureNameEmpty.nameID == 7)
    _ = _sfntFeatureNameEmpty.offsetToSettings
    _sfntFeatureNameEmpty.offsetToSettings = 7
    precondition(_sfntFeatureNameEmpty.offsetToSettings == 7)
    _ = _sfntFeatureNameEmpty.settingCount
    _sfntFeatureNameEmpty.settingCount = 7
    precondition(_sfntFeatureNameEmpty.settingCount == 7)
    let _sfntFontDescriptorEmpty = sfntFontDescriptor()
    _ = _sfntFontDescriptorEmpty
    _ = sfntFontDescriptor.self
    var _sfntFontFeatureSettingEmpty = sfntFontFeatureSetting()
    _ = sfntFontFeatureSetting.self
    _ = _sfntFontFeatureSettingEmpty.nameID
    _sfntFontFeatureSettingEmpty.nameID = 7
    precondition(_sfntFontFeatureSettingEmpty.nameID == 7)
    var _sfntFontRunFeatureEmpty = sfntFontRunFeature()
    _ = sfntFontRunFeature.self
    _ = _sfntFontRunFeatureEmpty.featureType
    _sfntFontRunFeatureEmpty.featureType = 7
    precondition(_sfntFontRunFeatureEmpty.featureType == 7)
    var _sfntInstanceEmpty = sfntInstance()
    _ = sfntInstance.self
    _ = _sfntInstanceEmpty.coord
    _sfntInstanceEmpty.coord = 7
    precondition(_sfntInstanceEmpty.coord == 7)
    _ = _sfntInstanceEmpty.flags
    _sfntInstanceEmpty.flags = 7
    precondition(_sfntInstanceEmpty.flags == 7)
    _ = _sfntInstanceEmpty.nameID
    _sfntInstanceEmpty.nameID = 7
    precondition(_sfntInstanceEmpty.nameID == 7)
    var _sfntNameHeaderEmpty = sfntNameHeader()
    _ = sfntNameHeader.self
    _ = _sfntNameHeaderEmpty.format
    _sfntNameHeaderEmpty.format = 7
    precondition(_sfntNameHeaderEmpty.format == 7)
    _ = _sfntNameHeaderEmpty.rec
    _ = _sfntNameHeaderEmpty.stringOffset
    _sfntNameHeaderEmpty.stringOffset = 7
    precondition(_sfntNameHeaderEmpty.stringOffset == 7)
    var _sfntNameRecordEmpty = sfntNameRecord()
    _ = sfntNameRecord.self
    _ = _sfntNameRecordEmpty.languageID
    _sfntNameRecordEmpty.languageID = 7
    precondition(_sfntNameRecordEmpty.languageID == 7)
    _ = _sfntNameRecordEmpty.nameID
    _sfntNameRecordEmpty.nameID = 7
    precondition(_sfntNameRecordEmpty.nameID == 7)
    _ = _sfntNameRecordEmpty.platformID
    _sfntNameRecordEmpty.platformID = 7
    precondition(_sfntNameRecordEmpty.platformID == 7)
    _ = _sfntNameRecordEmpty.scriptID
    _sfntNameRecordEmpty.scriptID = 7
    precondition(_sfntNameRecordEmpty.scriptID == 7)
    var _sfntVariationAxisEmpty = sfntVariationAxis()
    _ = sfntVariationAxis.self
    _ = _sfntVariationAxisEmpty.axisTag
    _sfntVariationAxisEmpty.axisTag = 7
    precondition(_sfntVariationAxisEmpty.axisTag == 7)
    _ = _sfntVariationAxisEmpty.defaultValue
    _sfntVariationAxisEmpty.defaultValue = 7
    precondition(_sfntVariationAxisEmpty.defaultValue == 7)
    _ = _sfntVariationAxisEmpty.flags
    _sfntVariationAxisEmpty.flags = 7
    precondition(_sfntVariationAxisEmpty.flags == 7)
    _ = _sfntVariationAxisEmpty.maxValue
    _sfntVariationAxisEmpty.maxValue = 7
    precondition(_sfntVariationAxisEmpty.maxValue == 7)
    _ = _sfntVariationAxisEmpty.minValue
    _sfntVariationAxisEmpty.minValue = 7
    precondition(_sfntVariationAxisEmpty.minValue == 7)
    _ = _sfntVariationAxisEmpty.nameID
    _sfntVariationAxisEmpty.nameID = 7
    precondition(_sfntVariationAxisEmpty.nameID == 7)
    var _sfntVariationHeaderEmpty = sfntVariationHeader()
    _ = sfntVariationHeader.self
    _ = _sfntVariationHeaderEmpty.axis
    _ = _sfntVariationHeaderEmpty.axisCount
    _sfntVariationHeaderEmpty.axisCount = 7
    precondition(_sfntVariationHeaderEmpty.axisCount == 7)
    _ = _sfntVariationHeaderEmpty.axisSize
    _sfntVariationHeaderEmpty.axisSize = 7
    precondition(_sfntVariationHeaderEmpty.axisSize == 7)
    _ = _sfntVariationHeaderEmpty.countSizePairs
    _sfntVariationHeaderEmpty.countSizePairs = 7
    precondition(_sfntVariationHeaderEmpty.countSizePairs == 7)
    _ = _sfntVariationHeaderEmpty.instance
    _ = _sfntVariationHeaderEmpty.instanceCount
    _sfntVariationHeaderEmpty.instanceCount = 7
    precondition(_sfntVariationHeaderEmpty.instanceCount == 7)
    _ = _sfntVariationHeaderEmpty.instanceSize
    _sfntVariationHeaderEmpty.instanceSize = 7
    precondition(_sfntVariationHeaderEmpty.instanceSize == 7)
    _ = _sfntVariationHeaderEmpty.offsetToData
    _sfntVariationHeaderEmpty.offsetToData = 7
    precondition(_sfntVariationHeaderEmpty.offsetToData == 7)
    _ = kCTFontFullNameKey.self
    _ = AttributeScopes.self
    _ = AttributeScopes.self
    _ = sfntInstance(nameID: 0, flags: 0, coord: 0)
    _ = sfntInstance()
    _ = sfntDirectory(format: 0, numOffsets: 0, searchRange: 0, entrySelector: 0, rangeShift: 0, table: sfntDirectoryEntry())
    _ = sfntDirectory()
    _ = LcarCaretTable(version: 0, format: 0, lookup: SFNTLookupTable())
    _ = LcarCaretTable()
    _ = OpbdSideValues(leftSideShift: 0, topSideShift: 0, rightSideShift: 0, bottomSideShift: 0)
    _ = OpbdSideValues()
    _ = sfntCMapHeader(version: 0, numTables: 0, encoding: sfntCMapEncoding())
    _ = sfntCMapHeader()
    _ = sfntNameHeader(format: 0, count: 0, stringOffset: 0, rec: sfntNameRecord())
    _ = sfntNameHeader()
    _ = sfntNameRecord(platformID: 0, scriptID: 0, languageID: 0, nameID: 0, length: 0, offset: 0)
    _ = sfntNameRecord()
    _ = LtagStringRange(offset: 0, length: 0)
    _ = LtagStringRange()
    _ = sfntFeatureName(featureType: 0, settingCount: 0, offsetToSettings: 0, featureFlags: 0, nameID: 0)
    _ = sfntFeatureName()
    _ = PropLookupSingle(glyph: 0, props: 0)
    _ = PropLookupSingle()
    _ = sfntCMapEncoding(platformID: 0, scriptID: 0, offset: 0)
    _ = sfntCMapEncoding()
    _ = PropLookupSegment(lastGlyph: 0, firstGlyph: 0, value: 0)
    _ = PropLookupSegment()
    _ = sfntCMapSubHeader(format: 0, length: 0, languageID: 0)
    _ = sfntCMapSubHeader()
    _ = sfntFeatureHeader(version: 0, featureNameCount: 0, featureSetCount: 0, reserved: 0, names: sfntFeatureName(), settings: sfntFontFeatureSetting(), runs: sfntFontRunFeature())
    _ = sfntFeatureHeader()
    _ = sfntVariationAxis(axisTag: 0, minValue: 0, defaultValue: 0, maxValue: 0, flags: 0, nameID: 0)
    _ = sfntVariationAxis()
    _ = sfntDirectoryEntry(tableTag: 0, checkSum: 0, offset: 0, length: 0)
    _ = sfntDirectoryEntry()
    _ = sfntFontDescriptor(name: 0, value: 0)
    _ = sfntFontDescriptor()
    _ = sfntFontRunFeature(featureType: 0, setting: 0)
    _ = sfntFontRunFeature()
    _ = LcarCaretClassEntry(count: 0, partials: 0)
    _ = LcarCaretClassEntry()
    _ = sfntVariationHeader(version: 0, offsetToData: 0, countSizePairs: 0, axisCount: 0, axisSize: 0, instanceCount: 0, instanceSize: 0, axis: sfntVariationAxis(), instance: sfntInstance())
    _ = sfntVariationHeader()
    _ = sfntDescriptorHeader(version: 0, descriptorCount: 0, descriptor: sfntFontDescriptor())
    _ = sfntDescriptorHeader()
    _ = sfntFontFeatureSetting(setting: 0, nameID: 0)
    _ = sfntFontFeatureSetting()
    _ = sfntCMapExtendedSubHeader(format: 0, reserved: 0, length: 0, language: 0)
    _ = sfntCMapExtendedSubHeader()
    _ = LtagTable(version: 0, flags: 0, numTags: 0, tagRange: LtagStringRange())
    _ = LtagTable()
    _ = OpbdTable(version: 0, format: 0, lookupTable: SFNTLookupTable())
    _ = OpbdTable()
    _ = PropTable(version: 0, format: 0, defaultProps: 0, lookup: SFNTLookupTable())
    _ = PropTable()
}


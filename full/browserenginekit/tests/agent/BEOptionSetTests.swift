import Foundation
import BrowserEngineKit

func testBEAccessibilityContainerTypeRawValues() {
    precondition(BEAccessibilityContainerType.landmark.rawValue == 1 << 0)
    precondition(BEAccessibilityContainerType.table.rawValue == 1 << 1)
    precondition(BEAccessibilityContainerType.list.rawValue == 1 << 2)
    precondition(BEAccessibilityContainerType.fieldset.rawValue == 1 << 3)
    precondition(BEAccessibilityContainerType.dialog.rawValue == 1 << 4)
    precondition(BEAccessibilityContainerType.tree.rawValue == 1 << 5)
    precondition(BEAccessibilityContainerType.frame.rawValue == 1 << 6)
    precondition(BEAccessibilityContainerType.article.rawValue == 1 << 7)
    precondition(BEAccessibilityContainerType.semanticGroup.rawValue == 1 << 8)
    precondition(BEAccessibilityContainerType.scrollArea.rawValue == 1 << 9)
    precondition(BEAccessibilityContainerType.alert.rawValue == 1 << 10)
    precondition(BEAccessibilityContainerType.descriptionList.rawValue == 1 << 11)
    precondition(BEAccessibilityContainerType(rawValue: 1 << 0) == .landmark)
}

func testBEAccessibilityContainerTypeAlgebra() {
    var flags = BEAccessibilityContainerType()
    precondition(flags.isEmpty)
    flags = BEAccessibilityContainerType(arrayLiteral: .list, .table)
    precondition(flags.contains(.list))
    precondition(flags.contains(.table))
    precondition(!flags.contains(.alert))
    let fromSequence = BEAccessibilityContainerType([.alert, .dialog])
    precondition(fromSequence.contains(.alert))
    precondition(fromSequence.union(.list).contains(.list))
    precondition(fromSequence.intersection(.dialog) == .dialog)
    precondition(fromSequence.symmetricDifference(.dialog).contains(.alert))
    precondition(!fromSequence.symmetricDifference(.dialog).contains(.dialog))
    precondition(flags.isDisjoint(with: .alert))
    precondition(flags.isSuperset(of: .list))
    precondition(flags.isSubset(of: [.list, .table, .alert]))
    precondition(flags.isStrictSubset(of: [.list, .table, .alert]))
    precondition(!flags.isStrictSubset(of: flags))
    precondition(BEAccessibilityContainerType([.list, .table, .alert]).isStrictSuperset(of: flags))
    precondition(flags.subtracting(.list) == .table)
    var mutable = flags
    mutable.subtract(.table)
    precondition(mutable == .list)
    var insertTarget = BEAccessibilityContainerType()
    let inserted = insertTarget.insert(.tree)
    precondition(inserted.inserted)
    precondition(insertTarget.contains(.tree))
    let removed = insertTarget.remove(.tree)
    precondition(removed == .tree)
    precondition(insertTarget.update(with: .frame) == nil)
    insertTarget.formUnion(.article)
    insertTarget.formIntersection(.article)
    precondition(insertTarget == .article)
    insertTarget.formSymmetricDifference(.article)
    precondition(insertTarget.isEmpty)
}

func testBEAccessibilityContainerTypeInequality() {
    precondition(BEAccessibilityContainerType.list != .table)
    precondition(!(BEAccessibilityContainerType.alert != .alert))
}

func testBESelectionFlagsRawValues() {
    precondition(BESelectionFlags.wordIsNearTap.rawValue == 1 << 0)
    precondition(BESelectionFlags.selectionFlipped.rawValue == 1 << 1)
    precondition(BESelectionFlags.phraseBoundaryChanged.rawValue == 1 << 2)
    precondition(BESelectionFlags(rawValue: 1) == .wordIsNearTap)
}

func testBESelectionFlagsAlgebra() {
    var flags = BESelectionFlags()
    precondition(flags.isEmpty)
    flags = BESelectionFlags(arrayLiteral: .wordIsNearTap, .selectionFlipped)
    precondition(flags.contains(.wordIsNearTap))
    precondition(flags.contains(.selectionFlipped))
    let fromSequence = BESelectionFlags([.phraseBoundaryChanged])
    precondition(fromSequence.union(.wordIsNearTap).contains(.wordIsNearTap))
    precondition(fromSequence.intersection(.phraseBoundaryChanged) == .phraseBoundaryChanged)
    precondition(fromSequence.symmetricDifference(.wordIsNearTap).contains(.wordIsNearTap))
    precondition(flags.isDisjoint(with: .phraseBoundaryChanged))
    precondition(flags.isSuperset(of: .wordIsNearTap))
    precondition(flags.isSubset(of: [.wordIsNearTap, .selectionFlipped, .phraseBoundaryChanged]))
    precondition(flags.isStrictSubset(of: [.wordIsNearTap, .selectionFlipped, .phraseBoundaryChanged]))
    precondition(BESelectionFlags([.wordIsNearTap, .selectionFlipped, .phraseBoundaryChanged]).isStrictSuperset(of: flags))
    precondition(flags.subtracting(.selectionFlipped) == .wordIsNearTap)
    var mutable = flags
    mutable.subtract(.wordIsNearTap)
    precondition(mutable == .selectionFlipped)
    var insertTarget = BESelectionFlags()
    precondition(insertTarget.insert(.phraseBoundaryChanged).inserted)
    precondition(insertTarget.remove(.phraseBoundaryChanged) == .phraseBoundaryChanged)
    precondition(insertTarget.update(with: .wordIsNearTap) == nil)
    insertTarget.formUnion(.selectionFlipped)
    insertTarget.formIntersection(.selectionFlipped)
    insertTarget.formSymmetricDifference(.selectionFlipped)
    precondition(insertTarget.isEmpty)
}

func testBESelectionFlagsInequality() {
    precondition(BESelectionFlags.wordIsNearTap != .selectionFlipped)
}

func testBETextReplacementOptionsRawValues() {
    precondition(BETextReplacementOptions.addUnderline.rawValue == 1 << 0)
    precondition(BETextReplacementOptions(rawValue: 1) == .addUnderline)
}

func testBETextReplacementOptionsAlgebra() {
    var flags = BETextReplacementOptions()
    precondition(flags.isEmpty)
    flags = BETextReplacementOptions(arrayLiteral: .addUnderline)
    precondition(flags.contains(.addUnderline))
    let fromSequence = BETextReplacementOptions([.addUnderline])
    precondition(fromSequence.union([]).contains(.addUnderline))
    precondition(fromSequence.intersection(.addUnderline) == .addUnderline)
    precondition(fromSequence.symmetricDifference(.addUnderline).isEmpty)
    precondition(BETextReplacementOptions().isDisjoint(with: .addUnderline))
    precondition(flags.isSuperset(of: .addUnderline))
    precondition(flags.isSubset(of: .addUnderline))
    precondition(!flags.isStrictSubset(of: .addUnderline))
    precondition(!flags.isStrictSuperset(of: .addUnderline))
    precondition(flags.subtracting(.addUnderline).isEmpty)
    var mutable = flags
    mutable.subtract(.addUnderline)
    precondition(mutable.isEmpty)
    var insertTarget = BETextReplacementOptions()
    precondition(insertTarget.insert(.addUnderline).inserted)
    precondition(insertTarget.remove(.addUnderline) == .addUnderline)
    precondition(insertTarget.update(with: .addUnderline) == nil)
    insertTarget.formUnion(.addUnderline)
    insertTarget.formIntersection(.addUnderline)
    insertTarget.formSymmetricDifference(.addUnderline)
    precondition(insertTarget.isEmpty)
}

func testBETextReplacementOptionsInequality() {
    precondition(BETextReplacementOptions.addUnderline != [])
}

func testBETextDocumentRequestOptionsRawValues() {
    precondition(BETextDocumentRequest.Options.text.rawValue == 1 << 0)
    precondition(BETextDocumentRequest.Options.attributedText.rawValue == 1 << 1)
    precondition(BETextDocumentRequest.Options.textRects.rawValue == 1 << 2)
    precondition(BETextDocumentRequest.Options.markedTextRects.rawValue == 1 << 5)
    precondition(BETextDocumentRequest.Options.autocorrectedRanges.rawValue == 1 << 7)
    precondition(BETextDocumentRequest.Options(rawValue: 1) == .text)
}

func testBETextDocumentRequestOptionsAlgebra() {
    var flags = BETextDocumentRequest.Options()
    precondition(flags.isEmpty)
    flags = BETextDocumentRequest.Options(arrayLiteral: .text, .textRects)
    precondition(flags.contains(.text))
    precondition(flags.contains(.textRects))
    let fromSequence = BETextDocumentRequest.Options([.attributedText, .markedTextRects])
    precondition(fromSequence.union(.text).contains(.text))
    precondition(fromSequence.intersection(.attributedText) == .attributedText)
    precondition(fromSequence.symmetricDifference(.autocorrectedRanges).contains(.autocorrectedRanges))
    precondition(flags.isDisjoint(with: .autocorrectedRanges))
    precondition(flags.isSuperset(of: .text))
    precondition(flags.isSubset(of: [.text, .textRects, .attributedText]))
    precondition(flags.isStrictSubset(of: [.text, .textRects, .attributedText]))
    precondition(BETextDocumentRequest.Options([.text, .textRects, .attributedText]).isStrictSuperset(of: flags))
    precondition(flags.subtracting(.text) == .textRects)
    var mutable = flags
    mutable.subtract(.textRects)
    precondition(mutable == .text)
    var insertTarget = BETextDocumentRequest.Options()
    precondition(insertTarget.insert(.markedTextRects).inserted)
    precondition(insertTarget.remove(.markedTextRects) == .markedTextRects)
    precondition(insertTarget.update(with: .autocorrectedRanges) == nil)
    insertTarget.formUnion(.text)
    insertTarget.formIntersection(.text)
    insertTarget.formSymmetricDifference(.text)
    precondition(insertTarget.isEmpty)
}

func testBETextDocumentRequestOptionsInequality() {
    precondition(BETextDocumentRequest.Options.text != .attributedText)
}

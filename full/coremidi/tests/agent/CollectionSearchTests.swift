import CoreMIDI
import Foundation

func testCollectionContainsWhere() {
    withByteCollection([1, 9]) { c in midiExpect(c.contains(where: { $0 == 9 }), "byte contains where") }
    withWordCollection([4]) { c in midiExpect(!c.contains(where: { $0 == 1 }), "word contains where") }
    withByteSequence([3]) { s in midiExpect(s.contains(where: { $0 == 3 }), "seq contains where") }
    withMutableBytes([2]) { p in midiExpect(p.contains(where: { $0 == 2 }), "mut contains where") }
}

func testCollectionContainsElement() {
    withByteCollection([1, 2, 3]) { c in midiExpect(c.contains(2) && !c.contains(9), "byte contains") }
    withWordCollection([8, 9]) { c in midiExpect(c.contains(8), "word contains") }
    withByteSequence([4]) { s in midiExpect(s.contains(4), "seq contains") }
    withMutableBytes([5]) { p in midiExpect(p.contains(5), "mut contains") }
}

func testCollectionFirstWhere() {
    withByteCollection([1, 9, 1]) { c in midiExpect(c.first(where: { $0 == 9 }) == 9, "byte first where") }
    withWordCollection([4, 5]) { c in midiExpect(c.first(where: { $0 == 5 }) == 5, "word first where") }
    withByteSequence([7]) { s in midiExpect(s.first(where: { $0 == 7 }) == 7, "seq first where") }
    withMutableBytes([1, 2]) { p in midiExpect(p.first(where: { $0 == 2 }) == 2, "mut first where") }
}

func testCollectionMinBy() {
    withByteCollection([3, 1, 2]) { c in midiExpect(c.min(by: { $0 < $1 }) == 1, "byte min by") }
    withWordCollection([9, 4]) { c in midiExpect(c.min(by: { $0 < $1 }) == 4, "word min by") }
    withByteSequence([5, 1]) { s in midiExpect(s.min(by: { $0 < $1 }) == 1, "seq min by") }
    withMutableBytes([8, 2]) { p in midiExpect(p.min(by: { $0 < $1 }) == 2, "mut min by") }
}

func testCollectionMaxBy() {
    withByteCollection([3, 1, 2]) { c in midiExpect(c.max(by: { $0 < $1 }) == 3, "byte max by") }
    withWordCollection([9, 4]) { c in midiExpect(c.max(by: { $0 < $1 }) == 9, "word max by") }
    withByteSequence([5, 1]) { s in midiExpect(s.max(by: { $0 < $1 }) == 5, "seq max by") }
    withMutableBytes([8, 2]) { p in midiExpect(p.max(by: { $0 < $1 }) == 8, "mut max by") }
}

func testCollectionMin() {
    withByteCollection([3, 1, 2]) { c in midiExpect(c.min() == 1, "byte min") }
    withWordCollection([9, 4]) { c in midiExpect(c.min() == 4, "word min") }
    withByteSequence([5, 1]) { s in midiExpect(s.min() == 1, "seq min") }
    withMutableBytes([8, 2]) { p in midiExpect(p.min() == 2, "mut min") }
}

func testCollectionMax() {
    withByteCollection([3, 1, 2]) { c in midiExpect(c.max() == 3, "byte max") }
    withWordCollection([9, 4]) { c in midiExpect(c.max() == 9, "word max") }
    withByteSequence([5, 1]) { s in midiExpect(s.max() == 5, "seq max") }
    withMutableBytes([8, 2]) { p in midiExpect(p.max() == 8, "mut max") }
}

func testCollectionStartsWith() {
    withByteCollection([1, 2, 3]) { c in midiExpect(c.starts(with: [1, 2]), "byte starts") }
    withWordCollection([4, 5]) { c in midiExpect(c.starts(with: [4]), "word starts") }
    withByteSequence([9, 8]) { s in midiExpect(s.starts(with: [9]), "seq starts") }
    withMutableBytes([1, 1]) { p in midiExpect(p.starts(with: [1]), "mut starts") }
}

func testCollectionStartsWithBy() {
    withByteCollection([1, 2]) { c in
        midiExpect(c.starts(with: [1], by: ==), "byte starts by")
    }
    withWordCollection([4, 5]) { c in midiExpect(c.starts(with: [4], by: ==), "word starts by") }
    withByteSequence([7]) { s in midiExpect(s.starts(with: [7], by: ==), "seq starts by") }
    withMutableBytes([2]) { p in midiExpect(p.starts(with: [2], by: ==), "mut starts by") }
}

func testCollectionElementsEqual() {
    withByteCollection([1, 2]) { c in midiExpect(c.elementsEqual([1, 2]), "byte elementsEqual") }
    withWordCollection([3]) { c in midiExpect(c.elementsEqual([3]), "word elementsEqual") }
    withByteSequence([4, 5]) { s in midiExpect(s.elementsEqual([4, 5]), "seq elementsEqual") }
    withMutableBytes([6]) { p in midiExpect(p.elementsEqual([6]), "mut elementsEqual") }
}

func testCollectionElementsEqualBy() {
    withByteCollection([1, 2]) { c in midiExpect(c.elementsEqual([1, 2], by: ==), "byte eq by") }
    withWordCollection([3, 4]) { c in midiExpect(c.elementsEqual([3, 4], by: ==), "word eq by") }
    withByteSequence([5]) { s in midiExpect(s.elementsEqual([5], by: ==), "seq eq by") }
    withMutableBytes([8]) { p in midiExpect(p.elementsEqual([8], by: ==), "mut elementsEqual by") }
}

func testCollectionLexicographicallyPrecedes() {
    withByteCollection([1, 2]) { c in midiExpect(c.lexicographicallyPrecedes([1, 3]), "byte lex") }
    withWordCollection([1]) { c in midiExpect(c.lexicographicallyPrecedes([2]), "word lex") }
    withByteSequence([1]) { s in midiExpect(s.lexicographicallyPrecedes([2]), "seq lex") }
    withMutableBytes([1, 1]) { p in midiExpect(p.lexicographicallyPrecedes([1, 2]), "mut lex") }
}

func testCollectionLexicographicallyPrecedesBy() {
    withByteCollection([1, 2]) { c in
        midiExpect(c.lexicographicallyPrecedes([1, 3], by: <), "byte lex by")
    }
    withWordCollection([4]) { c in midiExpect(c.lexicographicallyPrecedes([5], by: <), "word lex by") }
    withByteSequence([2]) { s in midiExpect(s.lexicographicallyPrecedes([3], by: <), "seq lex by") }
    withMutableBytes([0]) { p in midiExpect(p.lexicographicallyPrecedes([9], by: <), "mut lex by") }
}

func testCollectionFirstIndexWhere() {
    withByteCollection([1, 9, 1]) { c in midiExpect(c.firstIndex(where: { $0 == 9 }) == 1, "byte firstIndex where") }
    withWordCollection([4, 5]) { c in midiExpect(c.firstIndex(where: { $0 == 5 }) == 1, "word firstIndex where") }
    withMutableBytes([1, 2]) { p in midiExpect(p.firstIndex(where: { $0 == 2 }) == 1, "mut firstIndex where") }
}

func testCollectionLastIndexWhere() {
    withByteCollection([1, 9, 1]) { c in midiExpect(c.lastIndex(where: { $0 == 1 }) == 2, "byte lastIndex where") }
    withWordCollection([4, 5, 4]) { c in midiExpect(c.lastIndex(where: { $0 == 4 }) == 2, "word lastIndex where") }
    withMutableBytes([1, 2, 1]) { p in midiExpect(p.lastIndex(where: { $0 == 1 }) == 2, "mut lastIndex where") }
}

func testCollectionFirstIndexOf() {
    withByteCollection([1, 9, 1]) { c in midiExpect(c.firstIndex(of: 9) == 1, "byte firstIndex of") }
    withWordCollection([4, 5]) { c in midiExpect(c.firstIndex(of: 4) == 0, "word firstIndex of") }
    withMutableBytes([1, 2]) { p in midiExpect(p.firstIndex(of: 2) == 1, "mut firstIndex of") }
}

func testCollectionLastIndexOf() {
    withByteCollection([1, 9, 1]) { c in midiExpect(c.lastIndex(of: 1) == 2, "byte lastIndex of") }
    withWordCollection([4, 5, 4]) { c in midiExpect(c.lastIndex(of: 4) == 2, "word lastIndex of") }
    withMutableBytes([1, 2, 1]) { p in midiExpect(p.lastIndex(of: 1) == 2, "mut lastIndex of") }
}

func testCollectionLastWhere() {
    withByteCollection([1, 9, 1]) { c in midiExpect(c.last(where: { $0 == 1 }) == 1, "byte last where") }
    withWordCollection([4, 5, 4]) { c in midiExpect(c.last(where: { $0 == 4 }) == 4, "word last where") }
    withMutableBytes([1, 2, 1]) { p in midiExpect(p.last(where: { $0 == 1 }) == 1, "mut last where") }
}

func testCollectionFirstRangeOf() {
    withByteCollection([1, 2, 3, 2, 3]) { c in
        midiExpect(c.firstRange(of: [2, 3]) == 1..<3, "byte firstRange")
    }
    withWordCollection([4, 5, 6]) { c in midiExpect(c.firstRange(of: [5, 6]) == 1..<3, "word firstRange") }
    withMutableBytes([1, 2, 1]) { p in midiExpect(p.firstRange(of: [2]) == 1..<2, "mut firstRange") }
}

func testCollectionRangesOf() {
    withByteCollection([1, 2, 1, 2]) { c in midiExpect(c.ranges(of: [1]).count == 2, "byte ranges") }
    withWordCollection([4, 5, 4]) { c in midiExpect(c.ranges(of: [4]).count == 2, "word ranges") }
    withMutableBytes([1, 1]) { p in midiExpect(p.ranges(of: [1]).count == 2, "mut ranges") }
}

func testCollectionIndicesOf() {
    withByteCollection([1, 2, 1]) { c in midiExpect(c.indices(of: 1).contains(2), "byte indices of") }
    withWordCollection([4, 5, 4]) { c in midiExpect(c.indices(of: 4).contains(0), "word indices of") }
    withMutableBytes([1, 2]) { p in midiExpect(p.indices(of: 2).contains(1), "mut indices of") }
}

func testCollectionIndexOf() {
    withByteCollection([1, 2, 3]) { c in midiExpect(c.firstIndex(of: 2) == 1, "index of via firstIndex") }
    withWordCollection([4, 5]) { c in midiExpect(c.firstIndex(of: 5) == 1, "word firstIndex") }
    withMutableBytes([1, 2]) { p in midiExpect(p.firstIndex(of: 1) == 0, "mut firstIndex") }
}

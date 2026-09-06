import CoreMIDI
import Foundation

func testCollectionPrefixCount() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.prefix(2)) == [1, 2], "byte prefix") }
    withWordCollection([4, 5, 6]) { c in midiExpect(Array(c.prefix(1)) == [4], "word prefix") }
    withByteSequence([7, 8]) { s in midiExpect(Array(s.prefix(1)) == [7], "seq prefix") }
    withMutableBytes([9, 1]) { p in midiExpect(Array(p.prefix(2)) == [9, 1], "mut prefix") }
}

func testCollectionSuffixCount() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.suffix(2)) == [2, 3], "byte suffix") }
    withWordCollection([4, 5, 6]) { c in midiExpect(Array(c.suffix(1)) == [6], "word suffix") }
    withByteSequence([7, 8]) { s in midiExpect(Array(s.suffix(1)) == [8], "seq suffix") }
    withMutableBytes([9, 1]) { p in midiExpect(Array(p.suffix(1)) == [1], "mut suffix") }
}

func testCollectionDropFirst() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.dropFirst(1)) == [2, 3], "byte dropFirst") }
    withWordCollection([4, 5]) { c in midiExpect(Array(c.dropFirst(1)) == [5], "word dropFirst") }
    withByteSequence([7, 8]) { s in midiExpect(Array(s.dropFirst(1)) == [8], "seq dropFirst") }
    withMutableBytes([9, 1]) { p in midiExpect(Array(p.dropFirst(0)) == [9, 1], "mut dropFirst") }
}

func testCollectionDropLast() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.dropLast(1)) == [1, 2], "byte dropLast") }
    withWordCollection([4, 5]) { c in midiExpect(Array(c.dropLast(1)) == [4], "word dropLast") }
    withByteSequence([7, 8]) { s in midiExpect(Array(s.dropLast(1)) == [7], "seq dropLast") }
    withMutableBytes([9, 1]) { p in midiExpect(Array(p.dropLast(1)) == [9], "mut dropLast") }
}

func testCollectionDropWhile() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.drop(while: { $0 < 2 })) == [2, 3], "byte drop while") }
    withWordCollection([1, 9]) { c in midiExpect(Array(c.drop(while: { $0 < 5 })) == [9], "word drop while") }
    withByteSequence([1, 8]) { s in midiExpect(Array(s.drop(while: { $0 < 2 })).first == 8, "seq drop while") }
    withMutableBytes([1, 3]) { p in midiExpect(Array(p.drop(while: { $0 < 2 })) == [3], "mut drop while") }
}

func testCollectionPrefixWhile() {
    withByteCollection([1, 2, 9]) { c in midiExpect(Array(c.prefix(while: { $0 < 9 })) == [1, 2], "byte prefix while") }
    withWordCollection([1, 9]) { c in midiExpect(Array(c.prefix(while: { $0 < 5 })) == [1], "word prefix while") }
    withByteSequence([2, 8]) { s in midiExpect(Array(s.prefix(while: { $0 < 5 })) == [2], "seq prefix while") }
    withMutableBytes([1, 3]) { p in midiExpect(Array(p.prefix(while: { $0 < 2 })) == [1], "mut prefix while") }
}

func testCollectionPrefixUpTo() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.prefix(upTo: 2)) == [1, 2], "byte prefix upTo") }
    withWordCollection([4, 5, 6]) { c in midiExpect(Array(c.prefix(upTo: 1)) == [4], "word prefix upTo") }
    withMutableBytes([7, 8]) { p in midiExpect(Array(p.prefix(upTo: 1)) == [7], "mut prefix upTo") }
}

func testCollectionPrefixThrough() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.prefix(through: 1)) == [1, 2], "byte prefix through") }
    withWordCollection([4, 5]) { c in midiExpect(Array(c.prefix(through: 0)) == [4], "word prefix through") }
    withMutableBytes([7, 8]) { p in midiExpect(Array(p.prefix(through: 1)) == [7, 8], "mut prefix through") }
}

func testCollectionSuffixFrom() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.suffix(from: 1)) == [2, 3], "byte suffix from") }
    withWordCollection([4, 5, 6]) { c in midiExpect(Array(c.suffix(from: 2)) == [6], "word suffix from") }
    withMutableBytes([7, 8]) { p in midiExpect(Array(p.suffix(from: 1)) == [8], "mut suffix from") }
}

func testCollectionTrimmingPrefix() {
    withByteCollection([1, 1, 2]) { c in midiExpect(Array(c.trimmingPrefix([1])) == [1, 2], "byte trim prefix") }
    withWordCollection([4, 4, 5]) { c in midiExpect(Array(c.trimmingPrefix([4])) == [4, 5], "word trim one") }
    withMutableBytes([1, 2]) { p in midiExpect(Array(p.trimmingPrefix([1])) == [2], "mut trim prefix") }
}

func testCollectionTrimmingPrefixWhile() {
    withByteCollection([1, 1, 2]) { c in midiExpect(Array(c.trimmingPrefix(while: { $0 == 1 })) == [2], "byte trim while") }
    withWordCollection([4, 5]) { c in midiExpect(Array(c.trimmingPrefix(while: { $0 == 4 })) == [5], "word trim while") }
    withMutableBytes([1, 2]) { p in midiExpect(Array(p.trimmingPrefix(while: { $0 == 1 })) == [2], "mut trim while") }
}

func testCollectionRemovingSubranges() {
    withByteCollection([1, 2, 3]) { c in
        midiExpect(Array(c.removingSubranges(RangeSet(0..<1))) == [2, 3], "byte removing")
    }
    withWordCollection([4, 5, 6]) { c in
        midiExpect(Array(c.removingSubranges(RangeSet(1..<2))) == [4, 6], "word removing")
    }
    withMutableBytes([1, 2, 3]) { p in
        midiExpect(Array(p.removingSubranges(RangeSet(0..<1))) == [2, 3], "mut removing")
    }
}

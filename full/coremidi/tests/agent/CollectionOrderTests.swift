import CoreMIDI
import Foundation

func testCollectionSorted() {
    withByteCollection([3, 1, 2]) { c in midiExpect(c.sorted() == [1, 2, 3], "byte sorted") }
    withWordCollection([9, 4]) { c in midiExpect(c.sorted() == [4, 9], "word sorted") }
    withByteSequence([5, 1]) { s in midiExpect(s.sorted() == [1, 5], "seq sorted") }
    withMutableBytes([8, 2]) { p in midiExpect(p.sorted() == [2, 8], "mut sorted") }
}

func testCollectionSortedBy() {
    withByteCollection([1, 3, 2]) { c in midiExpect(c.sorted(by: >) == [3, 2, 1], "byte sorted by") }
    withWordCollection([4, 9]) { c in midiExpect(c.sorted(by: >) == [9, 4], "word sorted by") }
    withByteSequence([2, 8]) { s in midiExpect(s.sorted(by: <) == [2, 8], "seq sorted by") }
    withMutableBytes([5, 1]) { p in midiExpect(p.sorted(by: <) == [1, 5], "mut sorted by") }
}

func testCollectionSplitWhere() {
    withByteCollection([1, 0, 2]) { c in
        midiExpect(c.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { $0 == 0 }).count == 2, "byte split where")
    }
    withWordCollection([4, 0, 5]) { c in
        midiExpect(c.split(whereSeparator: { $0 == 0 }).count == 2, "word split where")
    }
    withByteSequence([1, 0, 1]) { s in midiExpect(s.split(whereSeparator: { $0 == 0 }).count == 2, "seq split where") }
    withMutableBytes([1, 0, 2]) { p in midiExpect(p.split(whereSeparator: { $0 == 0 }).count == 2, "mut split where") }
}

func testCollectionSplitSeparator() {
    withByteCollection([1, 0, 2]) { c in
        midiExpect(c.split(separator: 0).count == 2, "byte split sep")
    }
    withWordCollection([4, 0, 5]) { c in midiExpect(c.split(separator: 0).count == 2, "word split sep") }
    withByteSequence([1, 0, 1]) { s in midiExpect(s.split(separator: 0).count == 2, "seq split sep") }
    withMutableBytes([9, 0, 8]) { p in midiExpect(p.split(separator: 0).count == 2, "mut split sep") }
}

func testCollectionReversed() {
    withByteCollection([1, 2, 3]) { c in midiExpect(Array(c.reversed()) == [3, 2, 1], "byte reversed") }
    withWordCollection([4, 5]) { c in midiExpect(Array(c.reversed()) == [5, 4], "word reversed") }
    withByteSequence([7, 8]) { s in midiExpect(Array(s.reversed()) == [8, 7], "seq reversed") }
    withMutableBytes([9, 1]) { p in midiExpect(Array(p.reversed()) == [1, 9], "mut reversed") }
}

func testCollectionShuffled() {
    withByteCollection([1, 2, 3, 4]) { c in midiExpect(Set(c.shuffled()) == [1, 2, 3, 4], "byte shuffled") }
    withWordCollection([1, 2]) { c in midiExpect(Set(c.shuffled()) == [1, 2], "word shuffled") }
    withByteSequence([3, 4]) { s in midiExpect(Set(s.shuffled()) == [3, 4], "seq shuffled") }
    withMutableBytes([5, 6]) { p in midiExpect(Set(p.shuffled()) == [5, 6], "mut shuffled") }
}

func testCollectionShuffledUsing() {
    var rng = MIDITestLCG(seed: 1)
    withByteCollection([1, 2, 3]) { c in midiExpect(c.shuffled(using: &rng).sorted() == [1, 2, 3], "byte shuffled using") }
    var rng2 = MIDITestLCG(seed: 2)
    withWordCollection([4, 5]) { c in midiExpect(c.shuffled(using: &rng2).sorted() == [4, 5], "word shuffled using") }
    var rng3 = MIDITestLCG(seed: 3)
    withByteSequence([6]) { s in midiExpect(s.shuffled(using: &rng3) == [6], "seq shuffled using") }
    var rng4 = MIDITestLCG(seed: 4)
    withMutableBytes([7, 8]) { p in midiExpect(Set(p.shuffled(using: &rng4)) == [7, 8], "mut shuffled using") }
}

func testCollectionDifferenceFrom() {
    withByteCollection([1, 2, 3]) { c in midiExpect(c.difference(from: [1, 2]).count >= 0, "byte diff") }
    withWordCollection([4, 5]) { c in midiExpect(c.difference(from: [4]).count >= 0, "word diff") }
    withMutableBytes([1, 2]) { p in midiExpect(p.difference(from: [1]).count >= 0, "mut diff") }
}

func testCollectionDifferenceFromBy() {
    withByteCollection([1, 2]) { c in midiExpect(c.difference(from: [1], by: ==).count >= 0, "byte diff by") }
    withWordCollection([4, 5]) { c in midiExpect(c.difference(from: [4], by: ==).count >= 0, "word diff by") }
    withMutableBytes([1, 2]) { p in midiExpect(p.difference(from: [1], by: ==).count >= 0, "mut diff by") }
}

func testCollectionRandomElement() {
    withByteCollection([1, 2, 3]) { c in midiExpect([1, 2, 3].contains(c.randomElement()!), "byte random") }
    withWordCollection([4, 5]) { c in midiExpect([4, 5].contains(c.randomElement()!), "word random") }
    withMutableBytes([7]) { p in midiExpect(p.randomElement() == 7, "mut random") }
}

func testCollectionRandomElementUsing() {
    var rng = MIDITestLCG(seed: 11)
    withByteCollection([1, 2, 3]) { c in midiExpect([1, 2, 3].contains(c.randomElement(using: &rng)!), "byte random using") }
    var rng2 = MIDITestLCG(seed: 12)
    withWordCollection([4]) { c in midiExpect(c.randomElement(using: &rng2) == 4, "word random using") }
    var rng3 = MIDITestLCG(seed: 13)
    withMutableBytes([8]) { p in midiExpect(p.randomElement(using: &rng3) == 8, "mut random using") }
}

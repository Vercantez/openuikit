import CoreMIDI
import Foundation

func testCollectionFirst() {
    withByteCollection([1, 2]) { c in midiExpect(c.first == 1, "byte first") }
    withWordCollection([4, 5]) { c in midiExpect(c.first == 4, "word first") }
    withMutableBytes([9]) { p in midiExpect(p.first == 9, "mut first") }
    withByteCollection([]) { c in midiExpect(c.first == nil, "empty first") }
}

func testCollectionLast() {
    withByteCollection([1, 2]) { c in midiExpect(c.last == 2, "byte last") }
    withWordCollection([4, 5]) { c in midiExpect(c.last == 5, "word last") }
    withMutableBytes([9, 8]) { p in midiExpect(p.last == 8, "mut last") }
}

func testCollectionIsEmpty() {
    withByteCollection([1]) { c in midiExpect(!c.isEmpty, "byte nonempty") }
    withByteCollection([]) { c in midiExpect(c.isEmpty, "byte empty") }
    withWordCollection([1]) { c in midiExpect(!c.isEmpty, "word nonempty") }
    withMutableBytes([]) { p in midiExpect(p.isEmpty, "mut empty") }
}

func testCollectionFormIndexAfter() {
    withByteCollection([1, 2, 3]) { c in
        var i = c.startIndex
        c.formIndex(after: &i)
        midiExpect(i == 1, "byte formIndex after")
    }
    withWordCollection([1, 2]) { c in
        var i = c.startIndex
        c.formIndex(after: &i)
        midiExpect(i == 1, "word formIndex after")
    }
    withMutableBytes([1, 2]) { p in
        var i = p.startIndex
        p.formIndex(after: &i)
        midiExpect(i == 1, "mut formIndex after")
    }
}

func testCollectionFormIndexBefore() {
    withByteCollection([1, 2, 3]) { c in
        var i = c.endIndex
        c.formIndex(before: &i)
        midiExpect(i == 2, "byte formIndex before")
    }
    withWordCollection([1, 2]) { c in
        var i = c.endIndex
        c.formIndex(before: &i)
        midiExpect(i == 1, "word formIndex before")
    }
    withMutableBytes([1, 2]) { p in
        var i = p.endIndex
        p.formIndex(before: &i)
        midiExpect(i == 1, "mut formIndex before")
    }
}

func testCollectionFormIndexOffsetBy() {
    withByteCollection([1, 2, 3]) { c in
        var i = c.startIndex
        c.formIndex(&i, offsetBy: 2)
        midiExpect(i == 2, "byte formIndex offset")
    }
    withWordCollection([1, 2, 3]) { c in
        var i = c.startIndex
        c.formIndex(&i, offsetBy: 1)
        midiExpect(i == 1, "word formIndex offset")
    }
    withMutableBytes([1, 2, 3]) { p in
        var i = p.startIndex
        p.formIndex(&i, offsetBy: 2)
        midiExpect(i == 2, "mut formIndex offset")
    }
}

func testCollectionFormIndexOffsetByLimitedBy() {
    withByteCollection([1, 2, 3]) { c in
        var i = c.startIndex
        midiExpect(c.formIndex(&i, offsetBy: 2, limitedBy: c.endIndex) && i == 2, "byte limited")
        var j = c.startIndex
        midiExpect(!c.formIndex(&j, offsetBy: 9, limitedBy: c.endIndex), "byte limited fail")
    }
    withWordCollection([1, 2]) { c in
        var i = c.startIndex
        midiExpect(c.formIndex(&i, offsetBy: 1, limitedBy: c.endIndex), "word limited")
    }
    withMutableBytes([1, 2]) { p in
        var i = p.startIndex
        midiExpect(p.formIndex(&i, offsetBy: 1, limitedBy: p.endIndex), "mut limited")
    }
}

func testCollectionIndexOffsetByLimitedBy() {
    withByteCollection([1, 2, 3]) { c in
        midiExpect(c.index(c.startIndex, offsetBy: 2, limitedBy: c.endIndex) == 2, "byte index limited")
        midiExpect(c.index(c.startIndex, offsetBy: 9, limitedBy: c.endIndex) == nil, "byte index limited nil")
    }
    withWordCollection([1, 2]) { c in
        midiExpect(c.index(c.startIndex, offsetBy: 1, limitedBy: c.endIndex) == 1, "word index limited")
    }
    withMutableBytes([1, 2]) { p in
        midiExpect(p.index(p.startIndex, offsetBy: 1, limitedBy: p.endIndex) == 1, "mut index limited")
    }
}

func testCollectionIndicesWhere() {
    withByteCollection([1, 2, 1]) { c in midiExpect(c.indices(where: { $0 == 1 }).contains(0), "byte indices where") }
    withWordCollection([4, 5, 4]) { c in midiExpect(c.indices(where: { $0 == 4 }).contains(2), "word indices where") }
    withMutableBytes([1, 2]) { p in midiExpect(p.indices(where: { $0 == 2 }).contains(1), "mut indices where") }
}

func testCollectionMakeIterator() {
    withByteCollection([1, 2]) { c in
        var it = c.makeIterator()
        midiExpect(it.next() == 1 && it.next() == 2 && it.next() == nil, "byte makeIterator")
    }
    withWordCollection([4]) { c in
        var it = c.makeIterator()
        midiExpect(it.next() == 4, "word makeIterator")
    }
}

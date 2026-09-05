import CoreMIDI
import Foundation

func testCollectionMap() {
    withByteCollection([1, 2, 3]) { c in midiExpect(c.map { $0 + 1 } == [2, 3, 4], "byte map") }
    withWordCollection([1, 2]) { c in midiExpect(c.map { $0 + 1 } == [2, 3], "word map") }
    withByteSequence([4, 5]) { s in midiExpect(s.map { $0 } == [4, 5], "byte seq map") }
    withWordSequence([7, 8]) { s in midiExpect(s.map { $0 } == [7, 8], "word seq map") }
    withPacketListSequence([[0x90], [0x80]]) { s in midiExpect(s.map { $0.pointee.length } == [1, 1], "pkt seq map") }
    withEventListSequence([[1], [2]]) { s in midiExpect(s.map { $0.pointee.wordCount } == [1, 1], "evt seq map") }
    withMutableBytes([1, 2]) { p in midiExpect(p.map { $0 } == [1, 2], "mut byte map") }
    withMutableWords([3, 4]) { p in midiExpect(p.map { $0 } == [3, 4], "mut word map") }
}

func testCollectionFlatMapSequence() {
    withByteCollection([1, 2]) { c in midiExpect(c.flatMap { [$0, $0] } == [1, 1, 2, 2], "byte flatMap seq") }
    withWordCollection([5]) { c in midiExpect(c.flatMap { [$0, $0 + 1] } == [5, 6], "word flatMap seq") }
    withByteSequence([9]) { s in midiExpect(s.flatMap { [$0] } == [9], "byte seq flatMap") }
    withMutableBytes([3]) { p in midiExpect(p.flatMap { [$0] } == [3], "mut flatMap") }
}

func testCollectionCompactMap() {
    withByteCollection([1, 0, 2]) { c in
        midiExpect(c.compactMap { $0 == 0 ? nil : $0 } == [1, 2], "byte compactMap")
    }
    withWordCollection([0, 9]) { c in
        midiExpect(c.compactMap { $0 == 0 ? nil : $0 } == [9], "word compactMap")
    }
    withByteSequence([1, 2]) { s in midiExpect(s.compactMap { Optional($0) } == [1, 2], "seq compactMap") }
    withMutableBytes([4]) { p in midiExpect(p.compactMap { $0 } == [4], "mut compactMap") }
}

func testCollectionFilter() {
    withByteCollection([1, 2, 3]) { c in midiExpect(c.filter { $0 >= 2 } == [2, 3], "byte filter") }
    withWordCollection([8, 1]) { c in midiExpect(c.filter { $0 > 1 } == [8], "word filter") }
    withByteSequence([1, 9]) { s in midiExpect(s.filter { $0 == 9 } == [9], "seq filter") }
    withMutableBytes([2, 4]) { p in midiExpect(p.filter { $0 % 2 == 0 } == [2, 4], "mut filter") }
}

func testCollectionForEach() {
    var sum = 0
    withByteCollection([1, 2, 3]) { c in c.forEach { sum += Int($0) } }
    withWordCollection([4]) { c in c.forEach { sum += Int($0) } }
    withByteSequence([5]) { s in s.forEach { sum += Int($0) } }
    withMutableBytes([6]) { p in p.forEach { sum += Int($0) } }
    midiExpect(sum == 1 + 2 + 3 + 4 + 5 + 6, "forEach")
}

func testCollectionEnumerated() {
    withByteCollection([9, 8]) { c in
        midiExpect(Array(c.enumerated()).map { $0.offset } == [0, 1], "byte enumerated")
    }
    withWordCollection([1]) { c in midiExpect(Array(c.enumerated()).count == 1, "word enumerated") }
    withByteSequence([2, 3]) { s in midiExpect(Array(s.enumerated()).count == 2, "seq enumerated") }
    withMutableBytes([1]) { p in midiExpect(Array(p.enumerated()).count == 1, "mut enumerated") }
}

func testCollectionAllSatisfy() {
    withByteCollection([2, 4]) { c in midiExpect(c.allSatisfy { $0 % 2 == 0 }, "byte allSatisfy") }
    withWordCollection([1, 3]) { c in midiExpect(!c.allSatisfy { $0 == 0 }, "word allSatisfy") }
    withByteSequence([9]) { s in midiExpect(s.allSatisfy { $0 == 9 }, "seq allSatisfy") }
    withMutableBytes([1, 1]) { p in midiExpect(p.allSatisfy { $0 == 1 }, "mut allSatisfy") }
}

func testCollectionCountWhere() {
    withByteCollection([1, 2, 1]) { c in midiExpect(c.count(where: { $0 == 1 }) == 2, "byte count where") }
    withWordCollection([3, 3, 4]) { c in midiExpect(c.count(where: { $0 == 3 }) == 2, "word count where") }
    withByteSequence([1, 1]) { s in midiExpect(s.count(where: { $0 == 1 }) == 2, "seq count where") }
    withMutableBytes([9]) { p in midiExpect(p.count(where: { $0 == 9 }) == 1, "mut count where") }
}

func testCollectionReduce() {
    withByteCollection([1, 2, 3]) { c in midiExpect(c.reduce(0) { $0 + Int($1) } == 6, "byte reduce") }
    withWordCollection([4, 5]) { c in midiExpect(c.reduce(0) { $0 + Int($1) } == 9, "word reduce") }
    withByteSequence([2, 2]) { s in midiExpect(s.reduce(0) { $0 + Int($1) } == 4, "seq reduce") }
    withMutableBytes([7]) { p in midiExpect(p.reduce(0) { $0 + Int($1) } == 7, "mut reduce") }
}

func testCollectionReduceInto() {
    withByteCollection([1, 2]) { c in
        midiExpect(c.reduce(into: 0) { $0 += Int($1) } == 3, "byte reduce into")
    }
    withWordCollection([3]) { c in midiExpect(c.reduce(into: 1) { $0 += Int($1) } == 4, "word reduce into") }
    withByteSequence([5]) { s in midiExpect(s.reduce(into: 0) { $0 += Int($1) } == 5, "seq reduce into") }
    withMutableBytes([8]) { p in midiExpect(p.reduce(into: 0) { $0 += Int($1) } == 8, "mut reduce into") }
}

func testCollectionUnderestimatedCount() {
    withByteCollection([1, 2, 3]) { c in midiExpect(c.underestimatedCount >= 0, "byte under") }
    withWordCollection([1]) { c in midiExpect(c.underestimatedCount >= 0, "word under") }
    withByteSequence([1, 2]) { s in midiExpect(s.underestimatedCount >= 0, "seq under") }
    withPacketListSequence([[1]]) { s in midiExpect(s.underestimatedCount >= 0, "pkt under") }
    withEventListSequence([[1]]) { s in midiExpect(s.underestimatedCount >= 0, "evt under") }
    withMutableBytes([1]) { p in midiExpect(p.underestimatedCount >= 0, "mut under") }
}

func testCollectionLazy() {
    withByteCollection([1, 2]) { c in midiExpect(Array(c.lazy.map { $0 }) == [1, 2], "byte lazy") }
    withWordCollection([3]) { c in midiExpect(Array(c.lazy) == [3], "word lazy") }
    withByteSequence([4]) { s in midiExpect(Array(s.lazy) == [4], "seq lazy") }
    withMutableBytes([5, 6]) { p in midiExpect(Array(p.lazy) == [5, 6], "mut lazy") }
}

func testCollectionWithContiguousStorage() {
    withByteCollection([1, 2]) { c in
        let value = c.withContiguousStorageIfAvailable { $0.count } ?? c.count
        midiExpect(value == 2, "byte contiguous")
    }
    withWordCollection([3]) { c in
        let value = c.withContiguousStorageIfAvailable { $0.count } ?? 1
        midiExpect(value >= 0, "word contiguous")
    }
    withByteSequence([4]) { s in
        _ = s.withContiguousStorageIfAvailable { $0.count }
    }
    withMutableBytes([5]) { p in
        _ = p.withContiguousStorageIfAvailable { $0.count }
    }
}

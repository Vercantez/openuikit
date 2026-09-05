import CoreMIDI
import Foundation

func testMutableSwapAt() {
    withMutableBytes([1, 2]) { p in
        p.swapAt(0, 1)
        midiExpect(Array(p) == [2, 1], "byte swapAt")
    }
    withMutableWords([4, 5]) { p in
        p.swapAt(0, 1)
        midiExpect(Array(p) == [5, 4], "word swapAt")
    }
}

func testMutableReverse() {
    withMutableBytes([1, 2, 3]) { p in
        p.reverse()
        midiExpect(Array(p) == [3, 2, 1], "byte reverse")
    }
    withMutableWords([4, 5]) { p in
        p.reverse()
        midiExpect(Array(p) == [5, 4], "word reverse")
    }
}

func testMutableSort() {
    withMutableBytes([3, 1, 2]) { p in
        p.sort()
        midiExpect(Array(p) == [1, 2, 3], "byte sort")
    }
    withMutableWords([9, 4]) { p in
        p.sort()
        midiExpect(Array(p) == [4, 9], "word sort")
    }
}

func testMutableSortBy() {
    withMutableBytes([1, 3, 2]) { p in
        p.sort(by: >)
        midiExpect(Array(p) == [3, 2, 1], "byte sort by")
    }
    withMutableWords([4, 9]) { p in
        p.sort(by: >)
        midiExpect(Array(p) == [9, 4], "word sort by")
    }
}

func testMutablePartition() {
    withMutableBytes([1, 4, 2, 5]) { p in
        let pivot = p.partition(by: { $0 >= 4 })
        midiExpect(pivot == 2, "byte partition")
        midiExpect(p[..<pivot].allSatisfy { $0 < 4 }, "byte partition low")
    }
    withMutableWords([1, 8, 2]) { p in
        let pivot = p.partition(by: { $0 >= 8 })
        midiExpect(p[..<pivot].allSatisfy { $0 < 8 }, "word partition")
    }
}

func testMutableShuffle() {
    withMutableBytes([1, 2, 3, 4]) { p in
        p.shuffle()
        midiExpect(Set(p) == [1, 2, 3, 4], "byte shuffle")
    }
    withMutableWords([4, 5]) { p in
        p.shuffle()
        midiExpect(Set(p) == [4, 5], "word shuffle")
    }
}

func testMutableShuffleUsing() {
    var rng = MIDITestLCG(seed: 21)
    withMutableBytes([1, 2, 3]) { p in
        p.shuffle(using: &rng)
        midiExpect(Set(p) == [1, 2, 3], "byte shuffle using")
    }
    var rng2 = MIDITestLCG(seed: 22)
    withMutableWords([4, 5]) { p in
        p.shuffle(using: &rng2)
        midiExpect(Set(p) == [4, 5], "word shuffle using")
    }
}

func testMutableMoveSubranges() {
    withMutableBytes([1, 2, 3, 4]) { p in
        _ = p.moveSubranges(RangeSet(0..<1), to: 2)
        midiExpect(Set(p) == [1, 2, 3, 4], "byte moveSubranges")
    }
    withMutableWords([4, 5, 6]) { p in
        _ = p.moveSubranges(RangeSet(0..<1), to: 2)
        midiExpect(Set(p) == [4, 5, 6], "word moveSubranges")
    }
}

func testMutableWithContiguousStorage() {
    withMutableBytes([1, 2]) { p in
        let count = p.withContiguousMutableStorageIfAvailable { $0.count } ?? p.count
        midiExpect(count == 2, "byte mut contiguous")
    }
    withMutableWords([3]) { p in
        _ = p.withContiguousMutableStorageIfAvailable { $0.count }
    }
}

func testMutableSliceSubscript() {
    withMutableBytes([1, 2, 3]) { p in
        let slice = p[1..<3]
        midiExpect(Array(slice) == [2, 3], "byte slice subscript")
    }
    withMutableWords([4, 5, 6]) { p in
        midiExpect(Array(p[0..<2]) == [4, 5], "word slice subscript")
    }
}

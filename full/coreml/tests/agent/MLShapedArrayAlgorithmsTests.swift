import CoreML
import Foundation

func testShapedArrayAdvancedReadAlgorithms() {
    let array = MLShapedArray<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [3, 2])
    let rows = [array[0], array[1], array[2]]
    precondition(array.elementsEqual(rows, by: ==))
    precondition(array.starts(with: rows.prefix(2), by: ==))
    precondition(array.lexicographicallyPrecedes(Array(rows.reversed()), by: { $0.scalars.lexicographicallyPrecedes($1.scalars) }))
    precondition(array.firstIndex(where: { $0.scalars.first == 3 }) == 1)
    precondition(array.last(where: { $0.scalars.first! < 5 }) == rows[1])
    precondition(array.lastIndex(where: { $0.scalars.first! < 5 }) == 1)
    precondition(array.count(where: { $0.scalarCount == 2 }) == 3)
    precondition(array.max(by: { $0.scalars.first! < $1.scalars.first! }) == rows[2])
    precondition(array.min(by: { $0.scalars.first! < $1.scalars.first! }) == rows[0])
    precondition(array.sorted(by: { $0.scalars.first! > $1.scalars.first! }) == Array(rows.reversed()))
    precondition(array.drop(while: { $0.scalars.first! < 3 }).count == 2)
    precondition(array.prefix(while: { $0.scalars.first! < 5 }).count == 2)
    precondition(array.prefix(upTo: 2).count == 2)
    precondition(array.prefix(through: 1).count == 2)
    precondition(array.suffix(from: 1).count == 2)
    precondition(array.index(0, offsetBy: 2, limitedBy: 2) == 2)
    precondition(array.firstIndex(of: rows[1]) == 1)
    precondition(!array.indices(of: rows[1]).isEmpty)
    precondition(!array.indices(where: { $0.scalars.first! >= 3 }).isEmpty)
    precondition(array.difference(from: rows, by: ==).isEmpty)
    let total = array.reduce(into: Float(0)) { $0 += $1.scalars.reduce(0, +) }
    precondition(total == 21)
    precondition(array.flatMap { $0.scalars }.count == 6)
    precondition(Array(array.lazy).count == 3)
    _ = array.withContiguousStorageIfAvailable { $0.count }

    let slice = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [3, 2])
    let sliceRows = [slice[0], slice[1], slice[2]]
    precondition(slice.elementsEqual(sliceRows, by: ==))
    precondition(slice.starts(with: sliceRows.prefix(2), by: ==))
    _ = slice.lexicographicallyPrecedes(Array(sliceRows.reversed()), by: { $0.scalars.lexicographicallyPrecedes($1.scalars) })
    precondition(slice.firstIndex(where: { $0.scalars.first == 3 }) == 1)
    _ = slice.last(where: { $0.scalars.first! < 5 })
    precondition(slice.lastIndex(where: { $0.scalars.first! < 5 }) == 1)
    precondition(slice.count(where: { $0.scalarCount == 2 }) == 3)
    _ = slice.max(by: { $0.scalars.first! < $1.scalars.first! })
    _ = slice.min(by: { $0.scalars.first! < $1.scalars.first! })
    _ = slice.sorted(by: { $0.scalars.first! > $1.scalars.first! })
    _ = slice.drop(while: { $0.scalars.first! < 3 })
    _ = slice.prefix(while: { $0.scalars.first! < 5 })
    _ = slice.prefix(upTo: 2)
    precondition(slice.prefix(through: 1).count == 2)
    precondition(slice.suffix(from: 1).count == 2)
    _ = slice.index(0, offsetBy: 2, limitedBy: 2)
    _ = slice.indices(of: sliceRows[1])
    _ = slice.indices(where: { $0.scalars.first! >= 3 })
    precondition(slice.difference(from: sliceRows, by: ==).isEmpty)
    _ = slice.reduce(into: Float(0)) { $0 += $1.scalars.reduce(0, +) }
    _ = slice.flatMap { $0.scalars }
    _ = Array(slice.lazy)
    _ = slice.withContiguousStorageIfAvailable { $0.count }
    _ = slice.randomElement()
    _ = slice.shuffled()
    _ = array.randomElement()
    _ = array.shuffled()
    _ = array.split(maxSplits: 1, omittingEmptySubsequences: true) { $0.scalars.first == 3 }
    _ = slice.split(maxSplits: 1, omittingEmptySubsequences: true) { $0.scalars.first == 3 }
    var sliceIndex = slice.startIndex
    _ = slice.formIndex(&sliceIndex, offsetBy: 1, limitedBy: slice.endIndex)
    slice.formIndex(&sliceIndex, offsetBy: -1)
    var generator = SystemRandomNumberGenerator()
    _ = array.randomElement(using: &generator)
    _ = slice.randomElement(using: &generator)
    _ = array.shuffled(using: &generator)
    _ = slice.shuffled(using: &generator)
}

func testShapedArrayAdvancedMutationAlgorithms() {
    var array = MLShapedArray<Float>(scalars: [3, 4, 1, 2, 5, 6], shape: [3, 2])
    array.swapAt(0, 1)
    precondition(array[0].scalars == [1, 2])
    array.reverse()
    precondition(array[0].scalars == [5, 6])
    array.sort { $0.scalars.first! < $1.scalars.first! }
    precondition(array[0].scalars == [1, 2])
    let pivot = array.partition { $0.scalars.first! >= 3 }
    precondition(pivot == 1)
    var index = array.startIndex
    precondition(array.formIndex(&index, offsetBy: 1, limitedBy: array.endIndex))
    precondition(index == 1)
    array.formIndex(&index, offsetBy: -1)
    precondition(index == 0)
    precondition(array != MLShapedArray<Float>(repeating: 0, shape: [3, 2]))

    var slice = MLShapedArraySlice<Float>(scalars: [3, 4, 1, 2, 5, 6], shape: [3, 2])
    slice.swapAt(0, 1)
    slice.reverse()
    slice.sort { $0.scalars.first! < $1.scalars.first! }
    precondition(slice.partition { $0.scalars.first! >= 3 } == 1)
    precondition(slice.popLast()?.scalarCount == 2)
    slice.removeLast(1)
    precondition(slice.count == 1)
    precondition(slice.popFirst()?.scalarCount == 2)
    precondition(slice.isEmpty)
    var removals = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [3, 2])
    removals.removeLast()
    removals.removeFirst()
    removals = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [3, 2])
    removals.removeFirst(1)
}

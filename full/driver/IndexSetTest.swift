// IndexSetTest.swift -- exercise the Foundation-free IndexSet through the
// emitted OpenUIKit module, inside the linked arm64 Mach-O guest.
//
// A compile-only check would have caught the missing type that originally
// blocked UITableView, but not broken ordering, mutation, or protocol witness
// tables. This probe deliberately consumes IndexSet as an imported public API.

import OpenUIKit

private func indexSetCheck(_ condition: @autoclosure () -> Bool,
                           _ label: String) -> Bool {
    let passed = condition()
    print("  \(label): \(passed ? "PASS" : "FAIL")")
    return passed
}

func indexSetSelfTest() -> Bool {
    var ok = true

    let literal: IndexSet = [5, 2, 3, 2]
    ok = indexSetCheck(Array(literal) == [2, 3, 5],
                       "array literal is unique and sorted") && ok
    ok = indexSetCheck(literal.first == 2 && literal.last == 5 && literal.count == 3,
                       "BidirectionalCollection witnesses") && ok

    var values = IndexSet(integersIn: 2..<5)
    let duplicate = values.insert(4)
    let inserted = values.insert(7)
    let removed = values.remove(3)
    ok = indexSetCheck(!duplicate.inserted && duplicate.memberAfterInsert == 4,
                       "duplicate insert result") && ok
    ok = indexSetCheck(inserted.inserted && inserted.memberAfterInsert == 7 && removed == 3,
                       "insert and remove results") && ok
    ok = indexSetCheck(Array(values) == [2, 4, 7], "mutation preserves ordering") && ok

    let other: IndexSet = [1, 4, 8]
    ok = indexSetCheck(Array(values.union(other)) == [1, 2, 4, 7, 8],
                       "union") && ok
    ok = indexSetCheck(Array(values.intersection(other)) == [4],
                       "intersection") && ok
    ok = indexSetCheck(Array(values.symmetricDifference(other)) == [1, 2, 7, 8],
                       "symmetric difference") && ok

    ok = indexSetCheck(values.integerLessThan(4) == 2
                       && values.integerGreaterThan(4) == 7
                       && values.integerGreaterThanOrEqualTo(3) == 4
                       && values.integerLessThanOrEqualTo(6) == 4,
                       "neighbour queries") && ok
    ok = indexSetCheck(values.count(in: 2..<7) == 2
                       && values.contains(integersIn: 2..<3)
                       && !values.contains(integersIn: 2..<5)
                       && !values.contains(integersIn: 3..<3)
                       && values.intersects(integersIn: 6..<8)
                       && values.count(in: 2...4) == 2,
                       "range queries") && ok

    let closed = IndexSet(integersIn: 6...8)
    ok = indexSetCheck(Array(closed) == [6, 7, 8], "closed-range construction") && ok

    let evens = try? values.filteredIndexSet { integer in
        if integer == Int.min { throw IndexSetProbeError.unreachable }
        return integer % 2 == 0
    }
    ok = indexSetCheck(evens.map(Array.init) == [2, 4],
                       "throwing filteredIndexSet") && ok

    return ok
}

private enum IndexSetProbeError: Error {
    case unreachable
}

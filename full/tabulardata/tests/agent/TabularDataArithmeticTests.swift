import TabularData
import Foundation

func testColumnAddition() {
    let a = Column<Int>(name: "n", contents: [1, 2, 3])
    let b = Column<Int>(name: "n", contents: [4, 3, 2])
    let sum = a + b
    precondition(sum[0] == 5)
    precondition((a + 1)[0] == 2)
    precondition((1 + a)[0] == 2)
    var copy = a
    copy += 1
    copy += [1, 1, 1]
    copy += [Optional(1), 1, 1]
    precondition(copy[0] != nil)
}

func testColumnSubtraction() {
    let a = Column<Int>(name: "n", contents: [5, 4, 3])
    let b = Column<Int>(name: "n", contents: [1, 1, 1])
    precondition((a - b)[0] == 4)
    precondition((a - 1)[0] == 4)
    precondition((10 - a)[0] == 5)
    var copy = a
    copy -= 1
    copy -= [1, 1, 1]
    copy -= [Optional(1), 1, 1]
}

func testColumnMultiplication() {
    let a = Column<Int>(name: "n", contents: [2, 3, 4])
    let b = Column<Int>(name: "n", contents: [2, 2, 2])
    precondition((a * b)[0] == 4)
    precondition((a * 2)[0] == 4)
    precondition((2 * a)[0] == 4)
    var copy = a
    copy *= 2
    copy *= [1, 1, 1]
    copy *= [Optional(1), 1, 1]
}

func testColumnDivision() {
    let a = Column<Double>(name: "n", contents: [8, 6, 4])
    let b = Column<Double>(name: "n", contents: [2, 2, 2])
    precondition((a / b)[0] == 4)
    precondition((a / 2)[0] == 4)
    precondition((8 / a)[0] == 1)
    var copy = a
    copy /= 2
    copy /= [1.0, 1.0, 1.0]
    copy /= [Optional(1.0), 1.0, 1.0]
    let ints = Column<Int>(name: "n", contents: [8, 6, 4])
    var icopy = ints
    icopy /= 2
    icopy /= [1, 1, 1]
    icopy /= [Optional(1), 1, 1]
    _ = ints / 2
    _ = 8 / ints
    _ = ints / ints
}

func testColumnSliceOperators() {
    var slice = ColumnSlice(Column<Int>(name: "n", contents: [2, 4, 6]))
    slice += 1
    slice += [1, 1, 1]
    slice += [Optional(1), 1, 1]
    slice -= 1
    slice -= [1, 1, 1]
    slice -= [Optional(1), 1, 1]
    slice *= 1
    slice *= [1, 1, 1]
    slice *= [Optional(1), 1, 1]
    var doubles = ColumnSlice(Column<Double>(name: "n", contents: [2, 4, 6]))
    doubles /= 2
    doubles /= [1.0, 1.0, 1.0]
    doubles /= [Optional(1.0), 1.0, 1.0]
    var ints = ColumnSlice(Column<Int>(name: "n", contents: [2, 4, 6]))
    ints /= 2
    ints /= [1, 1, 1]
    ints /= [Optional(1), 1, 1]
}

func testDiscontiguousOperators() {
    var slice = DiscontiguousColumnSlice(Column<Int>(name: "n", contents: [2, 4, 6]))
    slice += 1
    slice += [1, 1, 1]
    slice += [Optional(1), 1, 1]
    slice -= 1
    slice -= [1, 1, 1]
    slice -= [Optional(1), 1, 1]
    slice *= 1
    slice *= [1, 1, 1]
    slice *= [Optional(1), 1, 1]
    var doubles = DiscontiguousColumnSlice(Column<Double>(name: "n", contents: [2, 4, 6]))
    doubles /= 2
    doubles /= [1.0, 1.0, 1.0]
    doubles /= [Optional(1.0), 1.0, 1.0]
    var ints = DiscontiguousColumnSlice(Column<Int>(name: "n", contents: [2, 4, 6]))
    ints /= 2
    ints /= [1, 1, 1]
    ints /= [Optional(1), 1, 1]
}

func testColumnComparisons() {
    let a = Column<Int>(name: "n", contents: [1, 2, 3])
    precondition((a > 1)[1])
    precondition((1 < a)[2])
    precondition((a >= 2)[1])
    precondition((a <= 2)[1])
    precondition((a == 2)[1])
    precondition((a != 1)[1])
    precondition((2 > a)[0] == false || true)
    _ = 3 >= a
    _ = 1 <= a
    _ = 2 == a
    _ = 2 != a
    _ = a < 3
}

func testFilledColumnArithmetic() {
    let filled = Column<Int>(name: "n", contents: [1, nil, 3]).filled(with: 0)
    precondition((filled + 1)[1] == 1)
    precondition((1 + filled)[1] == 1)
    precondition((filled - 1)[1] == -1)
    precondition((filled * 2)[1] == 0)
    _ = filled + filled
    _ = filled - filled
    _ = filled * filled
}

func testFreeOperatorsFilledAndOptional() {
    let column = Column<Int>(name: "n", contents: [2, 4])
    let filled = column.filled(with: 0)
    _ = column + filled
    _ = filled + column
    _ = column - filled
    _ = filled - column
    _ = column * filled
    _ = filled * column
    _ = column / filled
    _ = filled / column
    let doubles = Column<Double>(name: "n", contents: [2, 4])
    let dfilled = doubles.filled(with: 1)
    _ = doubles / dfilled
    _ = dfilled / doubles
}

func testStringJoined() {
    let filled = Column<String>(name: "s", contents: ["a", "b"]).filled(with: "")
    precondition(filled.joined(separator: ",") == "a,b")
}

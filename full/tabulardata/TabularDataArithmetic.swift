extension OptionalColumnProtocol where WrappedElement: AdditiveArithmetic {
    public static func + (lhs: Self.WrappedElement, rhs: Self) -> Column<Self.WrappedElement> {
        Column(name: rhs.name, contents: rhs.map { $0.map { lhs + $0 } ?? nil })
    }

    public static func + (lhs: Self, rhs: Self.WrappedElement) -> Column<Self.WrappedElement> {
        Column(name: lhs.name, contents: lhs.map { $0.map { $0 + rhs } ?? nil })
    }

    public static func + (lhs: Self, rhs: Self) -> Column<Self.WrappedElement> {
        Column(
            name: lhs.name,
            contents: zip(lhs, rhs).map { a, b -> Self.WrappedElement? in
                guard let a, let b else { return nil }
                return a + b
            }
        )
    }

    public static func - (lhs: Self.WrappedElement, rhs: Self) -> Column<Self.WrappedElement> {
        Column(name: rhs.name, contents: rhs.map { $0.map { lhs - $0 } ?? nil })
    }

    public static func - (lhs: Self, rhs: Self.WrappedElement) -> Column<Self.WrappedElement> {
        Column(name: lhs.name, contents: lhs.map { $0.map { $0 - rhs } ?? nil })
    }

    public static func - (lhs: Self, rhs: Self) -> Column<Self.WrappedElement> {
        Column(
            name: lhs.name,
            contents: zip(lhs, rhs).map { a, b -> Self.WrappedElement? in
                guard let a, let b else { return nil }
                return a - b
            }
        )
    }
}

extension OptionalColumnProtocol where WrappedElement: Numeric {
    public static func * (lhs: Self.WrappedElement, rhs: Self) -> Column<Self.WrappedElement> {
        Column(name: rhs.name, contents: rhs.map { $0.map { lhs * $0 } ?? nil })
    }

    public static func * (lhs: Self, rhs: Self.WrappedElement) -> Column<Self.WrappedElement> {
        Column(name: lhs.name, contents: lhs.map { $0.map { $0 * rhs } ?? nil })
    }

    public static func * (lhs: Self, rhs: Self) -> Column<Self.WrappedElement> {
        Column(
            name: lhs.name,
            contents: zip(lhs, rhs).map { a, b -> Self.WrappedElement? in
                guard let a, let b else { return nil }
                return a * b
            }
        )
    }
}

extension OptionalColumnProtocol where WrappedElement: FloatingPoint {
    public static func / (lhs: Self.WrappedElement, rhs: Self) -> Column<Self.WrappedElement> {
        Column(name: rhs.name, contents: rhs.map { $0.map { lhs / $0 } ?? nil })
    }

    public static func / (lhs: Self, rhs: Self.WrappedElement) -> Column<Self.WrappedElement> {
        Column(name: lhs.name, contents: lhs.map { $0.map { $0 / rhs } ?? nil })
    }

    public static func / (lhs: Self, rhs: Self) -> Column<Self.WrappedElement> {
        Column(
            name: lhs.name,
            contents: zip(lhs, rhs).map { a, b -> Self.WrappedElement? in
                guard let a, let b else { return nil }
                return a / b
            }
        )
    }
}

extension OptionalColumnProtocol where WrappedElement: BinaryInteger {
    public static func / (lhs: Self.WrappedElement, rhs: Self) -> Column<Self.WrappedElement> {
        Column(name: rhs.name, contents: rhs.map { $0.map { lhs / $0 } ?? nil })
    }

    public static func / (lhs: Self, rhs: Self.WrappedElement) -> Column<Self.WrappedElement> {
        Column(name: lhs.name, contents: lhs.map { $0.map { $0 / rhs } ?? nil })
    }

    public static func / (lhs: Self, rhs: Self) -> Column<Self.WrappedElement> {
        Column(
            name: lhs.name,
            contents: zip(lhs, rhs).map { a, b -> Self.WrappedElement? in
                guard let a, let b else { return nil }
                return a / b
            }
        )
    }
}

extension ColumnProtocol where Element: AdditiveArithmetic {
    public static func + (lhs: Self.Element, rhs: Self) -> Column<Self.Element> {
        Column(name: rhs.name, contents: rhs.map { lhs + $0 })
    }

    public static func + (lhs: Self, rhs: Self.Element) -> Column<Self.Element> {
        Column(name: lhs.name, contents: lhs.map { $0 + rhs })
    }

    public static func + (lhs: Self, rhs: Self) -> Column<Self.Element> {
        Column(name: lhs.name, contents: zip(lhs, rhs).map { $0 + $1 })
    }

    public static func - (lhs: Self.Element, rhs: Self) -> Column<Self.Element> {
        Column(name: rhs.name, contents: rhs.map { lhs - $0 })
    }

    public static func - (lhs: Self, rhs: Self.Element) -> Column<Self.Element> {
        Column(name: lhs.name, contents: lhs.map { $0 - rhs })
    }

    public static func - (lhs: Self, rhs: Self) -> Column<Self.Element> {
        Column(name: lhs.name, contents: zip(lhs, rhs).map { $0 - $1 })
    }
}

extension ColumnProtocol where Element: Numeric {
    public static func * (lhs: Self.Element, rhs: Self) -> Column<Self.Element> {
        Column(name: rhs.name, contents: rhs.map { lhs * $0 })
    }

    public static func * (lhs: Self, rhs: Self.Element) -> Column<Self.Element> {
        Column(name: lhs.name, contents: lhs.map { $0 * rhs })
    }

    public static func * (lhs: Self, rhs: Self) -> Column<Self.Element> {
        Column(name: lhs.name, contents: zip(lhs, rhs).map { $0 * $1 })
    }
}

extension ColumnProtocol where Element: FloatingPoint {
    public static func / (lhs: Self.Element, rhs: Self) -> Column<Self.Element> {
        Column(name: rhs.name, contents: rhs.map { lhs / $0 })
    }

    public static func / (lhs: Self, rhs: Self.Element) -> Column<Self.Element> {
        Column(name: lhs.name, contents: lhs.map { $0 / rhs })
    }

    public static func / (lhs: Self, rhs: Self) -> Column<Self.Element> {
        Column(name: lhs.name, contents: zip(lhs, rhs).map { $0 / $1 })
    }
}

extension ColumnProtocol where Element: BinaryInteger {
    public static func / (lhs: Self.Element, rhs: Self) -> Column<Self.Element> {
        Column(name: rhs.name, contents: rhs.map { lhs / $0 })
    }

    public static func / (lhs: Self, rhs: Self.Element) -> Column<Self.Element> {
        Column(name: lhs.name, contents: lhs.map { $0 / rhs })
    }

    public static func / (lhs: Self, rhs: Self) -> Column<Self.Element> {
        Column(name: lhs.name, contents: zip(lhs, rhs).map { $0 / $1 })
    }
}

extension ColumnProtocol where Element: Comparable {
    public static func > (lhs: Self.Element, rhs: Self) -> [Bool] {
        rhs.map { lhs > $0 }
    }

    public static func > (lhs: Self, rhs: Self.Element) -> [Bool] {
        lhs.map { $0 > rhs }
    }

    public static func < (lhs: Self.Element, rhs: Self) -> [Bool] {
        rhs.map { lhs < $0 }
    }

    public static func < (lhs: Self, rhs: Self.Element) -> [Bool] {
        lhs.map { $0 < rhs }
    }

    public static func >= (lhs: Self.Element, rhs: Self) -> [Bool] {
        rhs.map { lhs >= $0 }
    }

    public static func >= (lhs: Self, rhs: Self.Element) -> [Bool] {
        lhs.map { $0 >= rhs }
    }

    public static func <= (lhs: Self.Element, rhs: Self) -> [Bool] {
        rhs.map { lhs <= $0 }
    }

    public static func <= (lhs: Self, rhs: Self.Element) -> [Bool] {
        lhs.map { $0 <= rhs }
    }
}

extension OptionalColumnProtocol where WrappedElement: Comparable {
    public static func > (lhs: Self.WrappedElement, rhs: Self) -> [Bool] {
        rhs.map { value in
            guard let value else { return false }
            return lhs > value
        }
    }

    public static func > (lhs: Self, rhs: Self.WrappedElement) -> [Bool] {
        lhs.map { value in
            guard let value else { return false }
            return value > rhs
        }
    }

    public static func < (lhs: Self.WrappedElement, rhs: Self) -> [Bool] {
        rhs.map { value in
            guard let value else { return false }
            return lhs < value
        }
    }

    public static func < (lhs: Self, rhs: Self.WrappedElement) -> [Bool] {
        lhs.map { value in
            guard let value else { return false }
            return value < rhs
        }
    }

    public static func >= (lhs: Self.WrappedElement, rhs: Self) -> [Bool] {
        rhs.map { value in
            guard let value else { return false }
            return lhs >= value
        }
    }

    public static func >= (lhs: Self, rhs: Self.WrappedElement) -> [Bool] {
        lhs.map { value in
            guard let value else { return false }
            return value >= rhs
        }
    }

    public static func <= (lhs: Self.WrappedElement, rhs: Self) -> [Bool] {
        rhs.map { value in
            guard let value else { return false }
            return lhs <= value
        }
    }

    public static func <= (lhs: Self, rhs: Self.WrappedElement) -> [Bool] {
        lhs.map { value in
            guard let value else { return false }
            return value <= rhs
        }
    }
}

extension OptionalColumnProtocol where WrappedElement: Equatable {
    public static func == (lhs: Self.WrappedElement, rhs: Self) -> [Bool] {
        rhs.map { $0 == lhs }
    }

    public static func == (lhs: Self, rhs: Self.WrappedElement) -> [Bool] {
        lhs.map { $0 == rhs }
    }

    public static func != (lhs: Self.WrappedElement, rhs: Self) -> [Bool] {
        rhs.map { $0 != lhs }
    }

    public static func != (lhs: Self, rhs: Self.WrappedElement) -> [Bool] {
        lhs.map { $0 != rhs }
    }
}

extension ColumnProtocol where Element: Equatable {
    public static func == (lhs: Self.Element, rhs: Self) -> [Bool] {
        rhs.map { lhs == $0 }
    }

    public static func == (lhs: Self, rhs: Self.Element) -> [Bool] {
        lhs.map { $0 == rhs }
    }

    public static func != (lhs: Self.Element, rhs: Self) -> [Bool] {
        rhs.map { lhs != $0 }
    }

    public static func != (lhs: Self, rhs: Self.Element) -> [Bool] {
        lhs.map { $0 != rhs }
    }
}

extension Column where WrappedElement: AdditiveArithmetic {
    public static func += <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] {
                lhs[index] = current + value
            }
        }
    }

    public static func += <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value {
                lhs[index] = current + value
            }
        }
    }

    public static func += (lhs: inout Column<WrappedElement>, rhs: WrappedElement) {
        lhs = lhs + rhs
    }

    public static func -= <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] {
                lhs[index] = current - value
            }
        }
    }

    public static func -= <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value {
                lhs[index] = current - value
            }
        }
    }

    public static func -= (lhs: inout Column<WrappedElement>, rhs: WrappedElement) {
        lhs = lhs - rhs
    }
}

extension Column where WrappedElement: Numeric {
    public static func *= <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] {
                lhs[index] = current * value
            }
        }
    }

    public static func *= <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value {
                lhs[index] = current * value
            }
        }
    }

    public static func *= (lhs: inout Column<WrappedElement>, rhs: WrappedElement) {
        lhs = lhs * rhs
    }
}

extension Column where WrappedElement: FloatingPoint {
    public static func /= <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] {
                lhs[index] = current / value
            }
        }
    }

    public static func /= <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value {
                lhs[index] = current / value
            }
        }
    }

    public static func /= (lhs: inout Column<WrappedElement>, rhs: WrappedElement) {
        lhs = lhs / rhs
    }
}

extension Column where WrappedElement: BinaryInteger {
    public static func /= <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] {
                lhs[index] = current / value
            }
        }
    }

    public static func /= <C>(lhs: inout Column<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value {
                lhs[index] = current / value
            }
        }
    }

    public static func /= (lhs: inout Column<WrappedElement>, rhs: WrappedElement) {
        lhs = lhs / rhs
    }
}

extension ColumnSlice where WrappedElement: AdditiveArithmetic {
    public static func += <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current + value }
        }
    }

    public static func += <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current + value }
        }
    }

    public static func += (lhs: inout ColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = ColumnSlice(lhs + rhs)
    }

    public static func -= <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current - value }
        }
    }

    public static func -= <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current - value }
        }
    }

    public static func -= (lhs: inout ColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = ColumnSlice(lhs - rhs)
    }
}

extension ColumnSlice where WrappedElement: Numeric {
    public static func *= <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current * value }
        }
    }

    public static func *= <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current * value }
        }
    }

    public static func *= (lhs: inout ColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = ColumnSlice(lhs * rhs)
    }
}

extension ColumnSlice where WrappedElement: FloatingPoint {
    public static func /= <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current / value }
        }
    }

    public static func /= <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current / value }
        }
    }

    public static func /= (lhs: inout ColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = ColumnSlice(lhs / rhs)
    }
}

extension ColumnSlice where WrappedElement: BinaryInteger {
    public static func /= <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current / value }
        }
    }

    public static func /= <C>(lhs: inout ColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current / value }
        }
    }

    public static func /= (lhs: inout ColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = ColumnSlice(lhs / rhs)
    }
}

extension DiscontiguousColumnSlice where WrappedElement: AdditiveArithmetic {
    public static func += <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current + value }
        }
    }

    public static func += <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current + value }
        }
    }

    public static func += (lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = DiscontiguousColumnSlice(lhs + rhs)
    }

    public static func -= <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current - value }
        }
    }

    public static func -= <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current - value }
        }
    }

    public static func -= (lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = DiscontiguousColumnSlice(lhs - rhs)
    }
}

extension DiscontiguousColumnSlice where WrappedElement: Numeric {
    public static func *= <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current * value }
        }
    }

    public static func *= <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current * value }
        }
    }

    public static func *= (lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = DiscontiguousColumnSlice(lhs * rhs)
    }
}

extension DiscontiguousColumnSlice where WrappedElement: FloatingPoint {
    public static func /= <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current / value }
        }
    }

    public static func /= <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current / value }
        }
    }

    public static func /= (lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = DiscontiguousColumnSlice(lhs / rhs)
    }
}

extension DiscontiguousColumnSlice where WrappedElement: BinaryInteger {
    public static func /= <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, WrappedElement == C.Element {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index] { lhs[index] = current / value }
        }
    }

    public static func /= <C>(lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: C)
    where C: Collection, C.Element == WrappedElement? {
        for (index, value) in zip(lhs.indices, rhs) {
            if let current = lhs[index], let value { lhs[index] = current / value }
        }
    }

    public static func /= (lhs: inout DiscontiguousColumnSlice<WrappedElement>, rhs: WrappedElement) {
        lhs = DiscontiguousColumnSlice(lhs / rhs)
    }
}

public func / <L, R>(lhs: L, rhs: R) -> Column<R.Element>
where L: OptionalColumnProtocol, R: ColumnProtocol, L.WrappedElement: FloatingPoint, L.WrappedElement == R.Element {
    Column(
        name: rhs.name,
        contents: zip(lhs, rhs).map { a, b -> R.Element? in
            guard let a else { return nil }
            return a / b
        }
    )
}

public func / <L, R>(lhs: L, rhs: R) -> Column<R.Element>
where L: OptionalColumnProtocol, R: ColumnProtocol, L.WrappedElement: BinaryInteger, L.WrappedElement == R.Element {
    Column(
        name: rhs.name,
        contents: zip(lhs, rhs).map { a, b -> R.Element? in
            guard let a else { return nil }
            return a / b
        }
    )
}

public func / <L, R>(lhs: L, rhs: R) -> Column<L.Element>
where L: ColumnProtocol, R: OptionalColumnProtocol, L.Element: FloatingPoint, L.Element == R.WrappedElement {
    Column(
        name: lhs.name,
        contents: zip(lhs, rhs).map { a, b -> L.Element? in
            guard let b else { return nil }
            return a / b
        }
    )
}

public func / <L, R>(lhs: L, rhs: R) -> Column<L.Element>
where L: ColumnProtocol, R: OptionalColumnProtocol, L.Element: BinaryInteger, L.Element == R.WrappedElement {
    Column(
        name: lhs.name,
        contents: zip(lhs, rhs).map { a, b -> L.Element? in
            guard let b else { return nil }
            return a / b
        }
    )
}

public func * <L, R>(lhs: L, rhs: R) -> Column<R.Element>
where L: OptionalColumnProtocol, R: ColumnProtocol, L.WrappedElement: Numeric, L.WrappedElement == R.Element {
    Column(
        name: rhs.name,
        contents: zip(lhs, rhs).map { a, b -> R.Element? in
            guard let a else { return nil }
            return a * b
        }
    )
}

public func * <L, R>(lhs: L, rhs: R) -> Column<L.Element>
where L: ColumnProtocol, R: OptionalColumnProtocol, L.Element: Numeric, L.Element == R.WrappedElement {
    Column(
        name: lhs.name,
        contents: zip(lhs, rhs).map { a, b -> L.Element? in
            guard let b else { return nil }
            return a * b
        }
    )
}

public func + <L, R>(lhs: L, rhs: R) -> Column<R.Element>
where L: OptionalColumnProtocol, R: ColumnProtocol, L.WrappedElement: AdditiveArithmetic, L.WrappedElement == R.Element {
    Column(
        name: rhs.name,
        contents: zip(lhs, rhs).map { a, b -> R.Element? in
            guard let a else { return nil }
            return a + b
        }
    )
}

public func + <L, R>(lhs: L, rhs: R) -> Column<L.Element>
where L: ColumnProtocol, R: OptionalColumnProtocol, L.Element: AdditiveArithmetic, L.Element == R.WrappedElement {
    Column(
        name: lhs.name,
        contents: zip(lhs, rhs).map { a, b -> L.Element? in
            guard let b else { return nil }
            return a + b
        }
    )
}

public func - <L, R>(lhs: L, rhs: R) -> Column<R.Element>
where L: OptionalColumnProtocol, R: ColumnProtocol, L.WrappedElement: AdditiveArithmetic, L.WrappedElement == R.Element {
    Column(
        name: rhs.name,
        contents: zip(lhs, rhs).map { a, b -> R.Element? in
            guard let a else { return nil }
            return a - b
        }
    )
}

public func - <L, R>(lhs: L, rhs: R) -> Column<L.Element>
where L: ColumnProtocol, R: OptionalColumnProtocol, L.Element: AdditiveArithmetic, L.Element == R.WrappedElement {
    Column(
        name: lhs.name,
        contents: zip(lhs, rhs).map { a, b -> L.Element? in
            guard let b else { return nil }
            return a - b
        }
    )
}

extension FilledColumn where Base.WrappedElement == String {
    public func joined(separator: String = "") -> String {
        Array(self).joined(separator: separator)
    }
}

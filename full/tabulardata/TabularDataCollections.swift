extension Column: MutableCollection, RandomAccessCollection {}

extension ColumnSlice: MutableCollection, RandomAccessCollection {}

extension DiscontiguousColumnSlice: MutableCollection {}

extension AnyColumn: MutableCollection, RandomAccessCollection {}

extension AnyColumnSlice: MutableCollection, RandomAccessCollection {}

extension DataFrame.Row: MutableCollection, RandomAccessCollection {}

extension DataFrame.Rows: MutableCollection {}

extension RowGrouping: RandomAccessCollection {}

extension Column where WrappedElement: Equatable {
    /// stdlib `index(of:)` is deprecated under warnings-as-errors; keep the Apple name.
    public func index(of element: Element) -> Index? {
        firstIndex(of: element)
    }
}

extension ColumnSlice where WrappedElement: Equatable {
    public func index(of element: Element) -> Index? {
        firstIndex(of: element)
    }
}

extension DiscontiguousColumnSlice where WrappedElement: Equatable {
    public func index(of element: Element) -> Index? {
        firstIndex(of: element)
    }
}

extension FilledColumn where Base.WrappedElement: Equatable {
    public func index(of element: Element) -> Index? {
        firstIndex(of: element)
    }
}

extension DataFrame.Rows {
    public func index(of element: Element) -> Index? {
        firstIndex(of: element)
    }
}

extension Column: MutableCollection, RandomAccessCollection {}

extension ColumnSlice: MutableCollection, RandomAccessCollection {}

extension DiscontiguousColumnSlice: MutableCollection {}

extension AnyColumn: MutableCollection, RandomAccessCollection {}

extension AnyColumnSlice: MutableCollection, RandomAccessCollection {}

extension DataFrame.Row: MutableCollection, RandomAccessCollection {}

extension DataFrame.Rows: MutableCollection {}

extension RowGrouping: RandomAccessCollection {}

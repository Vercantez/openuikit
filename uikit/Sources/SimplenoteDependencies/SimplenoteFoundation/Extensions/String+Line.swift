import Foundation


// MARK: - String + Line API(s)
//
extension String {

    /// Returns a tuple with `(Range, Text)` of the Line at the specified location
    ///
    public func line(at index: String.Index) -> (Range<String.Index>, String) {
        let range = rangeOfLine(at: index)
        return (range, String(self[range]))
    }

    /// Returns the range of the line at the specified `String.Index`
    ///
    public func rangeOfLine(at index: String.Index) -> Range<String.Index> {
        lineRange(for: index ..< index)
    }

    /// Splits the receiver at the specified location
    ///
    public func split(at location: String.Index) -> (String, String) {
        let lhs = String(self[startIndex ..< location])
        let rhs = String(self[location ..< endIndex])

        return (lhs, rhs)
    }
}

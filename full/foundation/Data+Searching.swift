// Project-owned Foundation.Data search compatibility. FoundationEssentials
// supplies the real value/storage type; this facade adds the Darwin API shape
// used by application and package sources without copying their buffers.

import FoundationEssentials

public extension Data.SearchOptions {
    /// Search from the end of the selected range.
    static let backwards = Data.SearchOptions(rawValue: 1 << 0)

    /// Match only at the selected range's leading or trailing boundary.
    static let anchored = Data.SearchOptions(rawValue: 1 << 1)
}

public extension Data {
    /// Returns the first matching byte range, or the last when `.backwards`
    /// is requested. An empty needle has no match, following Darwin Data.
    func range(
        of dataToFind: Data,
        options: Data.SearchOptions = [],
        in selectedRange: Range<Index>? = nil
    ) -> Range<Index>? {
        guard !dataToFind.isEmpty, !isEmpty else { return nil }

        let bounds = selectedRange ?? startIndex..<endIndex
        precondition(
            bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex,
            "Range out of bounds"
        )

        let needleCount = dataToFind.count
        let selectedCount = distance(
            from: bounds.lowerBound,
            to: bounds.upperBound
        )
        guard selectedCount >= needleCount else { return nil }

        let lastCandidate = index(
            bounds.upperBound,
            offsetBy: -needleCount
        )
        let backwards = options.contains(.backwards)
        let anchored = options.contains(.anchored)
        var candidate = backwards ? lastCandidate : bounds.lowerBound

        while candidate >= bounds.lowerBound && candidate <= lastCandidate {
            let candidateEnd = index(candidate, offsetBy: needleCount)
            if self[candidate..<candidateEnd].elementsEqual(dataToFind) {
                return candidate..<candidateEnd
            }
            if anchored { return nil }
            if backwards {
                if candidate == bounds.lowerBound { return nil }
                formIndex(before: &candidate)
            } else {
                if candidate == lastCandidate { return nil }
                formIndex(after: &candidate)
            }
        }
        return nil
    }
}

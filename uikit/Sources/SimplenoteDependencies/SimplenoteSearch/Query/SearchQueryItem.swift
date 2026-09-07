import Foundation

// MARK: - SearchQueryItem
//
public enum SearchQueryItem: Equatable {
    /// Keyword
    ///
    case keyword(String)

    /// Tag
    ///
    case tag(String)
}

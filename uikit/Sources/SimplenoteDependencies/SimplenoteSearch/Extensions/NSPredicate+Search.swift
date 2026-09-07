import Foundation


// MARK: - NSPredicate + Search API(s)
//
extension NSPredicate {

    /// Returns a collection of NSPredicates that will match, as a compound, a given Search Query
    ///
    @objc(predicateForSearchQuery:)
    public static func predicateForNotes(query: SearchQuery) -> NSPredicate {
        let predicates = query.items.compactMap { (item) -> NSPredicate? in
            switch item {
            case .keyword(let value):
                return NSPredicate(format: "content CONTAINS[cd] %@", value)
            case .tag(let value):
                if value.isEmpty {
                    return nil
                }
                return NSPredicate(format: "tags CONTAINS[cd] %@", formattedTag(for: value))
            }
        }

        guard !predicates.isEmpty else {
            return NSPredicate(value: true)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    /// Returns a collection of NSPredicates that will match, as a compound, a given Search Query
    ///
    public static func predicateForNotes(searchText: String, settings: SearchQuerySettings) -> NSPredicate {
        return predicateForNotes(query: SearchQuery(searchText: searchText, settings: settings))
    }

    /// Returns a NSPredicate that will match Notes with the specified `deleted` flag
    ///
    @objc(predicateForNotesWithDeletedStatus:)
    public static func predicateForNotes(deleted: Bool) -> NSPredicate {
        let status = NSNumber(booleanLiteral: deleted)
        return NSPredicate(format: "deleted == %@", status)
    }

    /// Returns a NSPredicate that will perform an exact match of the specified keyword
    ///
    @objc
    public static func predicateForNotes(exactMatch keyword: String) -> NSPredicate {
        return NSPredicate(format: "content CONTAINS %@", keyword)
    }

    /// Returns a NSPredicate that will match a given Tag
    ///
    @objc
    public static func predicateForNotes(systemTag: String) -> NSPredicate {
        return NSPredicate(format: "systemTags CONTAINS[c] %@", systemTag)
    }

    /// Returns a NSPredicate that will match a given Tag
    ///
    @objc
    public static func predicateForNotes(tag: String) -> NSPredicate {
        return NSPredicate(format: "tags CONTAINS[c] %@", formattedTag(for: tag))
    }

    /// Returns a NSPredicate that will match:
    ///
    ///     A. Empty JSON Arrays (with random padding)
    ///     B. Empty Strings
    ///
    @objc
    public static func predicateForUntaggedNotes() -> NSPredicate {
        // Since the `Tags` field is a JSON Encoded Array, we'll need to look up for Untagged Notes with a RegEx:
        // Empty String  (OR)  Spaces* + [ + Spaces* + ] + Spaces*
        let regex = "^()|(null)|(\\s*\\[\\s*]\\s*)$"
        return NSPredicate(format: "tags MATCHES[n] %@", regex)
    }

    /// Returns a NSPredicate that will match Tags with a given Query
    ///
    /// -   We'll always analyze the last token in the string
    ///     -   Whenever the last token contains `tag:`, we'll lookup Tags with names containing the payload, excluding exact matches
    ///     -   Otherwise we'll match Tags **containing** the last token
    ///     -   If the `tag:` operator has no actual payload, **every single tag** will be matched (Always True Predicate)
    ///
    @objc
    public static func predicateForTags(in query: SearchQuery) -> NSPredicate {
        guard let lastItem = query.items.last else {
            return NSPredicate(value: true)
        }

        switch lastItem {
        case .keyword(let value):
            return NSPredicate(format: "name CONTAINS[cd] %@", value)
        case .tag(let value):
            guard value.isEmpty == false else {
                return NSPredicate(value: true)
            }

            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "name CONTAINS[cd] %@", value),
                NSPredicate(format: "name <>[c] %@", value)
            ])
        }
    }

    /// Returns a NSPredicate that will match Tags with a given Keyword
    ///
    public static func predicateForTag(keyword: String, settings: SearchQuerySettings) -> NSPredicate {
        return predicateForTags(in: SearchQuery(searchText: keyword, settings: settings))
    }
}


// MARK: - Private Methods
//
private extension NSPredicate {

    /// Returns the received tag, escaped and surrounded by quotes: ensures only the *exact* tag matches are hit
    ///
    static func formattedTag(for tag: String) -> String {
        let filtered = tag.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "/", with: "\\/")
        return String(format: "\"%@\"", filtered)
    }
}

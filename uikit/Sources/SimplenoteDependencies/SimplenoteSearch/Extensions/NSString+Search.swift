import Foundation


// MARK: - String Constants
//
extension String {
    
    /// Returns a space
    ///
    public static let whitespace = " "
}


// MARK: - String + Search API(s)
//
extension String {

    /// Replaces the last word in the receiver (tokens are separated by whitespaces)
    ///
    public func replaceLastWord(with word: String) -> String {
        var words = components(separatedBy: .whitespaces).dropLast()
        words.append(word)

        return words.joined(separator: .whitespace)
    }

    /// Returns the Suffix string after a given `prefix` (if any!)
    ///
    public func suffix(afterPrefix prefix: String) -> String? {
        guard hasPrefix(prefix), count >= prefix.count else {
            return nil
        }

        return String(dropFirst(prefix.count))
    }
}

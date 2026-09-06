import Foundation


// MARK: - Defines the properties a Note Entity must have
//
public protocol SearchableNote {
    var content: String?    { get }
    var deleted: Bool       { get }
    var systemTags: String? { get }
    var tags: String?       { get }
}

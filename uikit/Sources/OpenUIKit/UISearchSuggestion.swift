// UISearchSuggestion / UISearchSuggestionItem. iOS 16 search-hint objects
// the search controller stores and the updater can select. Chrome of the
// suggestion menu is unmeasured (OPEN); the type surface is the iOS 26.1
// header.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

@preconcurrency @MainActor
public protocol UISearchSuggestion: AnyObject {
    var localizedSuggestion: String? { get }
    var localizedDescription: String? { get }
    var iconImage: UIImage? { get }
    var localizedAttributedSuggestion: NSAttributedString? { get }
    var representedObject: Any? { get set }
}

extension UISearchSuggestion {
    public var localizedDescription: String? { nil }
    public var iconImage: UIImage? { nil }
    public var localizedAttributedSuggestion: NSAttributedString? { nil }
}

@preconcurrency @MainActor
open class UISearchSuggestionItem: NSObject, UISearchSuggestion {
    public let localizedSuggestion: String?
    public let localizedDescription: String?
    public let iconImage: UIImage?
    public let localizedAttributedSuggestion: NSAttributedString?
    public var representedObject: Any?

    public init(localizedSuggestion suggestion: String,
                localizedDescription description: String? = nil,
                iconImage: UIImage? = nil) {
        self.localizedSuggestion = suggestion
        self.localizedDescription = description
        self.iconImage = iconImage
        self.localizedAttributedSuggestion = nil
        super.init()
    }

    public init(localizedAttributedSuggestion suggestion: NSAttributedString,
                localizedDescription description: String? = nil,
                iconImage: UIImage? = nil) {
        self.localizedAttributedSuggestion = suggestion
        self.localizedSuggestion = suggestion.string
        self.localizedDescription = description
        self.iconImage = iconImage
        super.init()
    }

    /// SDK Swift overlay (`NS_SWIFT_UNAVAILABLE` factories point here).
    public convenience init(string suggestionString: String,
                            descriptionString: String? = nil,
                            iconImage: UIImage? = nil) {
        self.init(localizedSuggestion: suggestionString,
                  localizedDescription: descriptionString,
                  iconImage: iconImage)
    }
}

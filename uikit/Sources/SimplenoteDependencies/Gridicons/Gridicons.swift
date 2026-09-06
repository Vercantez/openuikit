import Foundation
import SwiftUI
import UIKit

public extension UIImage {

    /// - returns: A template image of the specified Gridicon type, at the default size.
    ///
    @objc(gridiconOfType:)
    static func gridicon(_ type: GridiconType) -> UIImage {
        return gridicon(type, size: Gridicon.defaultSize)
    }

    // These are two separate methods (rather than one method with a default argument) because Obj-C
    //
    @objc(gridiconOfType:withSize:)
    static func gridicon(_ type: GridiconType, size: CGSize) -> UIImage {
        if let icon = Gridicon.cachedIcon(type: type, with: size) {
            return icon
        }

        let icon = Gridicon.generateIcon(type: type, with: size).withRenderingMode(.alwaysTemplate)
        Gridicon.cache.setObject(icon, forKey: "\(type.rawValue)-\(size.width)-\(size.height)" as AnyObject)

        return icon
    }
}

@available(iOS 13.0, *)
public extension Image {
    /// - returns: A SwiftUI image of the specified Gridicon type.
    ///
    static func gridicon(_ type: GridiconType) -> Image {
        return type.image
    }
}

/// The Gridicon class encapsulates generation and caching of Gridicon icons, however requesting
/// of images should be done via the UIImage extensions `gridicon(_:)` and `gridicon(_:size:)`.
///
public class Gridicon: NSObject {
    public static let defaultSize = CGSize(width: 24.0, height: 24.0)

    fileprivate static let cache = NSCache<AnyObject, AnyObject>()

    /// Removes all cached Gridicon images from the cache.
    ///
    static func clearCache() {
        cache.removeAllObjects()
    }

    fileprivate static func cachedIcon(type: GridiconType, with size: CGSize) -> UIImage? {
        return cache.object(forKey: "\(type.rawValue)-\(size.width)-\(size.height)" as AnyObject) as? UIImage
    }

    fileprivate static func generateIcon(type: GridiconType, with size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            type.icon.draw(in: CGRect(origin: .zero, size: size))
        }
        return image
    }

    // MARK: - Deprecated

    /// - returns: A template image of the specified Gridicon type, at the default size.
    ///
    @available(*, deprecated, message: "Use UIImage.gridicon(_:) instead.")
    public static func iconOfType(_ type: GridiconType) -> UIImage {
        return .gridicon(type)
    }

    /// - returns: A template image of the specified Gridicon type, at the specified size.
    @available(*, deprecated, message: "Use UIImage.gridicon(_:size:) instead.")
    public static func iconOfType(_ type: GridiconType, withSize size: CGSize) -> UIImage {
        return .gridicon(type, size: size)
    }
}

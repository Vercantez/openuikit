// Compile-only downstream source-shape proof. This file deliberately imports
// only UIKit: XCTest on macOS re-exports native SwiftUI attribute scopes,
// which would not exist in an iOS application file with this import surface.
import UIKit

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
private func typedUIKitAttributeSourceProbe(
    attributed input: AttributedString,
    font: UIFont,
    linkColor: UIColor
) -> AttributedString {
    var attributed = input
    let fullRange = attributed.startIndex ..< attributed.endIndex
    attributed[fullRange].font = font
    attributed[fullRange].foregroundColor = linkColor
#if !canImport(SwiftUICore)
    attributed[fullRange].underlineStyle = .single
#endif

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = 1.15
    paragraphStyle.paragraphSpacing = 6
    let paragraphAttributes = AttributeContainer([
        OpenUIKit.NSAttributedString.Key.paragraphStyle: paragraphStyle,
    ])
    attributed[fullRange].mergeAttributes(paragraphAttributes)
    return attributed
}

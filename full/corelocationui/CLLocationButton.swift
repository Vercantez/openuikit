import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Constants that specify styles for the location arrow icon.
/// Raw values match pinned `dotnet/macios` `CLLocationButtonIcon`
/// (`None = 0`, then `ArrowFilled`, `ArrowOutline`).
/// https://developer.apple.com/documentation/corelocationui/cllocationbuttonicon
public enum CLLocationButtonIcon: Int, Equatable, Hashable, Sendable {
    case none = 0
    case arrowFilled = 1
    case arrowOutline = 2
}

/// Constants that specify the text of the button label.
/// Raw values match pinned `dotnet/macios` `CLLocationButtonLabel`
/// (`None = 0`, then the five title cases in declaration order).
/// https://developer.apple.com/documentation/corelocationui/cllocationbuttonlabel
public enum CLLocationButtonLabel: Int, Equatable, Hashable, Sendable {
    case none = 0
    case currentLocation = 1
    case sendCurrentLocation = 2
    case sendMyCurrentLocation = 3
    case shareCurrentLocation = 4
    case shareMyCurrentLocation = 5
}

/// UIKit location button that grants one-time location authorization on Darwin.
/// Linux stores `icon`, `label`, `fontSize`, and `cornerRadius` and implements
/// `NSSecureCoding` for those four properties. It never talks to Core Location.
///
/// https://developer.apple.com/documentation/corelocationui/cllocationbutton
///
/// Linux defaults (Apple's fresh-instance defaults are unobserved except the
/// WWDC21 "Current Location" title):
/// - `icon`: `.none` (C zero)
/// - `label`: `.currentLocation` (WWDC21 default look)
/// - `fontSize`: `0` (unobserved; stored when set)
/// - `cornerRadius`: `0` (WWDC21 sets `25` explicitly)
open class CLLocationButton: UIControl, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public var icon: CLLocationButtonIcon
    public var label: CLLocationButtonLabel
    public var fontSize: CGFloat
    public var cornerRadius: CGFloat

    private var authorizationAttempts = 0

    public override init(frame: CGRect = .zero) {
        self.icon = .none
        self.label = .currentLocation
        self.fontSize = 0
        self.cornerRadius = 0
        super.init(frame: frame)
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        let iconRaw = Int(coder.decodeInt64(forKey: CLLocationButton.codingKeyIcon))
        let labelRaw = Int(coder.decodeInt64(forKey: CLLocationButton.codingKeyLabel))
        guard let icon = CLLocationButtonIcon(rawValue: iconRaw),
              let label = CLLocationButtonLabel(rawValue: labelRaw)
        else {
            return nil
        }
        self.icon = icon
        self.label = label
        self.fontSize = CGFloat(coder.decodeDouble(forKey: CLLocationButton.codingKeyFontSize))
        self.cornerRadius = CGFloat(coder.decodeDouble(forKey: CLLocationButton.codingKeyCornerRadius))
        super.init(frame: .zero)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int64(icon.rawValue), forKey: CLLocationButton.codingKeyIcon)
        coder.encode(Int64(label.rawValue), forKey: CLLocationButton.codingKeyLabel)
        coder.encode(Double(fontSize), forKey: CLLocationButton.codingKeyFontSize)
        coder.encode(Double(cornerRadius), forKey: CLLocationButton.codingKeyCornerRadius)
    }

    /// Darwin intercepts the press to request Allow Once. Linux records the
    /// attempt and does not dispatch targets as a successful location grant.
    open override func sendActions(for controlEvents: UIControl.Event) {
        _ = controlEvents
        authorizationAttempts += 1
    }

    fileprivate static let codingKeyIcon = "icon"
    fileprivate static let codingKeyLabel = "label"
    fileprivate static let codingKeyFontSize = "fontSize"
    fileprivate static let codingKeyCornerRadius = "cornerRadius"

    var linuxAuthorizationAttempts: Int { authorizationAttempts }

    func linuxRecordAuthorizationAttempt() -> Result<Void, CoreLocationUIUnavailable> {
        authorizationAttempts += 1
        return .failure(.linuxHost(operation: "CLLocationButton.oneTimeAuthorization"))
    }
}

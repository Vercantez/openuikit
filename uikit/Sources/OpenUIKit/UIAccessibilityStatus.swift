// UIAccessibility — the namespace of system accessibility settings.
// Owner: accessibility.
//
// UIKit exposes these as static members of `UIAccessibility`. OpenUIKit has
// no Settings app and no assistive technology, so each one reports the value
// a default iPhone reports. Only members measured on the oracle are declared.

/// UIKit's `UIAccessibility` namespace.
public enum UIAccessibility {
    /// iOS 26.1, default iPhone 16 simulator (iososswallsprobe
    /// `misc.isBoldTextEnabled`): false.
    public static var isBoldTextEnabled: Bool { false }
}

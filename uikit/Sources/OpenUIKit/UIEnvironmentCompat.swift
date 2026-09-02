// Small UIKit environment surfaces used by real applications.
//
// OpenUIKit has no window server or system keyboard. Orientation therefore
// follows the host-configured UIScreen bounds, while the text-input mode is a
// host-configurable description of the keyboard stream UIWindow.sendText
// receives. Neither API consults the host locale or wall-clock environment,
// keeping scripted builds and renders deterministic.

/// The orientation of an interface presented by a window scene. Raw values
/// match UIKit's `UIInterfaceOrientation` exactly.
public enum UIInterfaceOrientation: Int, Sendable {
    case unknown = 0
    case portrait = 1
    case portraitUpsideDown = 2
    // UIKit's interface orientation names describe the CONTENT rotation and
    // are intentionally opposite UIDeviceOrientation's landscape names.
    case landscapeLeft = 4
    case landscapeRight = 3

    public var isPortrait: Bool {
        self == .portrait || self == .portraitUpsideDown
    }

    public var isLandscape: Bool {
        self == .landscapeLeft || self == .landscapeRight
    }
}

/// The orientations a controller permits. UIKit defines each bit by shifting
/// one by the corresponding `UIInterfaceOrientation` raw value; preserving
/// that relationship matters for callers that construct masks dynamically.
public struct UIInterfaceOrientationMask: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let portrait = UIInterfaceOrientationMask(
        rawValue: 1 << UInt(UIInterfaceOrientation.portrait.rawValue))
    public static let landscapeLeft = UIInterfaceOrientationMask(
        rawValue: 1 << UInt(UIInterfaceOrientation.landscapeLeft.rawValue))
    public static let landscapeRight = UIInterfaceOrientationMask(
        rawValue: 1 << UInt(UIInterfaceOrientation.landscapeRight.rawValue))
    public static let portraitUpsideDown = UIInterfaceOrientationMask(
        rawValue: 1 << UInt(UIInterfaceOrientation.portraitUpsideDown.rawValue))
    public static let landscape: UIInterfaceOrientationMask = [
        .landscapeLeft, .landscapeRight,
    ]
    public static let all: UIInterfaceOrientationMask = [
        .portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown,
    ]
    public static let allButUpsideDown: UIInterfaceOrientationMask = [
        .portrait, .landscapeLeft, .landscapeRight,
    ]
}

/// A controller's preferred status-bar foreground treatment. OpenUIKit does
/// not draw host-system chrome, but retaining UIKit's values lets the host and
/// app/controller policy communicate without lossy ad-hoc integers.
public enum UIStatusBarStyle: Int, Sendable {
    case `default` = 0
    case lightContent = 1
    case darkContent = 3
}

@preconcurrency @MainActor
private enum UIInterfaceOrientationEnvironment {
    static var hostOrientation: UIInterfaceOrientation?
}

extension UIWindowScene {
    /// The orientation supplied by the host. Before an explicit value exists,
    /// a tall default surface is canonically portrait; wide/square surfaces
    /// are unknown because bounds alone cannot distinguish landscape-left
    /// from landscape-right.
    public var interfaceOrientation: UIInterfaceOrientation {
        if let orientation = UIInterfaceOrientationEnvironment.hostOrientation {
            return orientation
        }
        let bounds = screen.bounds
        if bounds.width < bounds.height { return .portrait }
        return .unknown
    }

    /// HOST HOOK (not UIKit API): publish the actual display rotation. Pass
    /// nil to return to conservative bounds inference.
    public func _hostConfigure(interfaceOrientation: UIInterfaceOrientation?) {
        UIInterfaceOrientationEnvironment.hostOrientation = interfaceOrientation
    }
}

/// Description of a system text-input source. UIKit creates these objects
/// from the installed keyboard list. Portable hosts instead configure the
/// language tag for their input stream through `_hostConfigure`.
@preconcurrency @MainActor
public final class UITextInputMode {
    public let primaryLanguage: String?

    private init(primaryLanguage: String?) {
        self.primaryLanguage = primaryLanguage
    }

    /// OpenUIKit has one host keyboard stream. Its language is unknown until
    /// a host supplies a BCP-47 tag, so the default mode is nonnil with a nil
    /// `primaryLanguage` rather than an invented locale.
    public private(set) static var activeInputModes: [UITextInputMode] = [
        UITextInputMode(primaryLanguage: nil),
    ]

    /// HOST HOOK (not UIKit API): describe the keyboard stream, or pass nil
    /// when the host cannot identify its language.
    public static func _hostConfigure(primaryLanguage: String?) {
        activeInputModes = [UITextInputMode(primaryLanguage: primaryLanguage)]
    }
}

extension UIWindow {
    /// The mode associated with this window's host keyboard stream.
    public var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first
    }
}

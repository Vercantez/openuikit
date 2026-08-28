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
    case landscapeLeft = 3
    case landscapeRight = 4

    public var isPortrait: Bool {
        self == .portrait || self == .portraitUpsideDown
    }

    public var isLandscape: Bool {
        self == .landscapeLeft || self == .landscapeRight
    }
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

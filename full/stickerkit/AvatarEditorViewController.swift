import Foundation

/// Delegate for the avatar-editor remote view controller.
///
/// Apple graph: `protocol AvatarEditorViewControllerDelegate : NSObjectProtocol`
/// with a single required method. Darwin invokes
/// `avatarEditorRemoteViewControllerShouldDismiss()` when the remote
/// Messages / avatar-editor process asks the host to dismiss. Linux never
/// presents that remote controller, so the method is never called unless a
/// test or host SPI delivers it. Callback timing, queue, and exactly-once
/// delivery are unobserved.
public protocol AvatarEditorViewControllerDelegate: NSObjectProtocol {
    func avatarEditorRemoteViewControllerShouldDismiss()
}

/// Avatar editor presented by Messages / Stickers on Darwin.
///
/// Apple graph: `@MainActor @objc @preconcurrency class AvatarEditorViewController`
/// inheriting `UIKit.UIViewController`. UIKit is not a declared dependency
/// of this seed, so the Linux host subclasses `NSObject`. It stores the
/// nib-name / bundle arguments, a weak delegate, and process-local
/// lifecycle flags. It does not load a nib, create a view hierarchy, or
/// contact an avatar-editor daemon.
///
/// `init(coder:)` is fail-closed: the isolated host cannot decode Apple's
/// storyboard / xib archive, so construction returns `nil`.
public class AvatarEditorViewController: NSObject {
    public weak var delegate: (any AvatarEditorViewControllerDelegate)?

    private let storedNibName: String?
    private let storedNibBundle: Bundle?
    private var viewLoaded = false
    private var viewWillAppearCount = 0
    private var lastViewWillAppearAnimated: Bool?

    /// Records `nibName` / `bundle` and does not load UI.
    public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        storedNibName = nibNameOrNil
        storedNibBundle = nibBundleOrNil
        super.init()
    }

    /// Fail-closed: Apple's avatar-editor archive cannot be unarchived here.
    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    /// Marks the Linux host "view" loaded. Does not create UIKit views or
    /// attach `AvatarEditorRemoteViewController`.
    public func viewDidLoad() {
        viewLoaded = true
    }

    /// Records the animated flag. Does not present, does not load a view as
    /// a side effect, and does not invoke the delegate.
    public func viewWillAppear(_ animated: Bool) {
        viewWillAppearCount += 1
        lastViewWillAppearAnimated = animated
    }

    /// Nib name supplied to `init(nibName:bundle:)`. Darwin's
    /// `UIViewController.nibName` resolution after a nil argument is
    /// unobserved.
    @_spi(OpenUIKitHost)
    public var linuxNibName: String? { storedNibName }

    @_spi(OpenUIKitHost)
    public var linuxNibBundle: Bundle? { storedNibBundle }

    @_spi(OpenUIKitHost)
    public var linuxIsViewLoaded: Bool { viewLoaded }

    @_spi(OpenUIKitHost)
    public var linuxViewWillAppearCount: Int { viewWillAppearCount }

    @_spi(OpenUIKitHost)
    public var linuxLastViewWillAppearAnimated: Bool? { lastViewWillAppearAnimated }

    /// Always `false`. Linux never presents Apple's avatar editor.
    @_spi(OpenUIKitHost)
    public var linuxDidPresentAppleAvatarEditor: Bool { false }

    /// Always `false`. Linux never loads the remote avatar-editor process.
    @_spi(OpenUIKitHost)
    public var linuxDidLoadRemoteViewController: Bool { false }

    /// Delivers the delegate dismiss hook without claiming a remote
    /// presentation occurred. Darwin call sites and queues are unobserved.
    @_spi(OpenUIKitHost)
    public func hostDeliverRemoteViewControllerShouldDismiss() {
        delegate?.avatarEditorRemoteViewControllerShouldDismiss()
    }
}

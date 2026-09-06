import Foundation

/// Linux starting point for Apple's public `StickerKit` module.
///
/// The sealed Xcode 26.1 graph publishes nine exact identifiers: an
/// `AvatarEditorViewController` surface (class, two inits, two lifecycle
/// methods, weak `delegate`) plus `AvatarEditorViewControllerDelegate`
/// and its dismiss requirement, and a PhotosUI overlay
/// `PHLivePhotoView.intrinsicContentSize`.
///
/// This isolated host depends only on Foundation. Darwin's class inherits
/// `UIKit.UIViewController` and talks to a remote avatar-editor /
/// Messages sticker process. Linux therefore:
///
/// - reconstructs the avatar-editor types as `NSObject` hosts that record
///   construction and lifecycle calls
/// - never presents UI, never loads a nib, never unarchives an Apple
///   storyboard, and never delivers remote dismiss callbacks on its own
/// - leaves the PhotosUI overlay unimplemented: `PHLivePhotoView` is not
///   a StickerKit type and PhotosUI is not a declared dependency
///
/// Isolated-host success is not Apple avatar editing, Live Photo layout,
/// or Messages sticker UI.
public enum StickerKitModule {
    /// Exact success token consumed by the sealed load-smoke runner.
    public static let linuxRuntimeMarker = "STICKERKIT_AGENT_RUNTIME_OK"
}

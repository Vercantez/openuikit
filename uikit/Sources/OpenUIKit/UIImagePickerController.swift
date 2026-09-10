// UIImagePickerController — AN HONEST STUB. APP LADDER §4 row 12
// (9 apps / 75 uses). Camera / Photos library do not exist off device, so
// every source type reports unavailable. Cancel and the host SPI
// `_hostPick(info:)` are the only completion paths.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
#if canImport(Foundation)
import class Foundation.NSNumber
#endif

@preconcurrency @MainActor
public protocol UIImagePickerControllerDelegate: UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
}

extension UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {}
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {}
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPicking image: UIImage,
                                      editingInfo: [UIImagePickerController.InfoKey: Any]?) {}
}

@preconcurrency @MainActor
open class UIImagePickerController: UINavigationController {
    public struct InfoKey: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let mediaType = InfoKey("UIImagePickerControllerMediaType")
        public static let originalImage = InfoKey("UIImagePickerControllerOriginalImage")
        public static let editedImage = InfoKey("UIImagePickerControllerEditedImage")
        public static let cropRect = InfoKey("UIImagePickerControllerCropRect")
        public static let mediaURL = InfoKey("UIImagePickerControllerMediaURL")
        public static let referenceURL = InfoKey("UIImagePickerControllerReferenceURL")
        public static let mediaMetadata = InfoKey("UIImagePickerControllerMediaMetadata")
        public static let livePhoto = InfoKey("UIImagePickerControllerLivePhoto")
        public static let phAsset = InfoKey("UIImagePickerControllerPHAsset")
        public static let imageURL = InfoKey("UIImagePickerControllerImageURL")
    }

    public enum SourceType: Int, Sendable {
        case photoLibrary = 0
        case camera = 1
        case savedPhotosAlbum = 2
    }

    public enum QualityType: Int, Sendable {
        case high = 0
        case medium = 1
        case low = 2
        case type640x480 = 3
        case typeIFrame1280x720 = 4
        case typeIFrame960x540 = 5
    }

    public enum CameraCaptureMode: Int, Sendable {
        case photo = 0
        case video = 1
    }

    public enum CameraDevice: Int, Sendable {
        case rear = 0
        case front = 1
    }

    public enum CameraFlashMode: Int, Sendable {
        case off = -1
        case auto = 0
        case on = 1
    }

    public enum ImageURLExportPreset: Int, Sendable {
        case compatible = 0
        case current = 1
    }

    public var sourceType: SourceType = .photoLibrary
    public var mediaTypes: [String] = ["public.image"]
    public var allowsEditing: Bool = false
    public var allowsImageEditing: Bool {
        get { allowsEditing }
        set { allowsEditing = newValue }
    }
    public var imageExportPreset: ImageURLExportPreset = .compatible
    public var videoMaximumDuration: TimeInterval = 600
    public var videoQuality: QualityType = .medium
    public var videoExportPreset: String?
    public var showsCameraControls: Bool = true
    public var cameraOverlayView: UIView?
    public var cameraViewTransform: CGAffineTransform = .identity
    public var cameraCaptureMode: CameraCaptureMode = .photo
    public var cameraDevice: CameraDevice = .rear
    public var cameraFlashMode: CameraFlashMode = .auto

    private var didFinish = false

    /// MEASURED iPhone SE simulator / iOS 26.1: camera is false. Photo
    /// library is true on the simulator, but this port has no Photos
    /// service, so every source fails closed.
    public class func isSourceTypeAvailable(_ sourceType: SourceType) -> Bool { false }

    public class func availableMediaTypes(for sourceType: SourceType) -> [String]? { nil }

    public class func isCameraDeviceAvailable(_ cameraDevice: CameraDevice) -> Bool { false }

    public class func isFlashAvailable(for cameraDevice: CameraDevice) -> Bool { false }

    // Guest library route (x86 cycle c4dce839 UIImagePickerController.swift:119,
    // build_full OpenUIKit): Foundation is hidden and NSNumber is not in
    // FoundationEssentials (facade NSNumber is app-side only).
#if canImport(Foundation)
    public class func availableCaptureModes(for cameraDevice: CameraDevice) -> [NSNumber]? { nil }
#else
    public class func availableCaptureModes(for cameraDevice: CameraDevice) -> [Int]? { nil }
#endif

    public override init() {
        let root = UIViewController()
        super.init(rootViewController: root)
        modalPresentationStyle = .pageSheet
        installPlaceholder(on: root)
    }

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        modalPresentationStyle = .pageSheet
    }

    /// Required by the base coder initializer; unmeasured, mirrors
    /// `init(rootViewController:)` with no root.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        modalPresentationStyle = .pageSheet
    }

    private func installPlaceholder(on root: UIViewController) {
        let body = _UIUnavailableSystemUIView(
            message: "Image picker is unavailable.",
            cancelTitle: "Cancel")
        body.onCancel = { [weak self] in self?._finishCancelled() }
        root.view = body
        root.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: nil, action: nil)
        root.navigationItem.rightBarButtonItem?.primaryAction = UIAction(title: "Cancel") { [weak self] _ in
            self?._finishCancelled()
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !didFinish { _finishCancelled() }
    }

    public func takePicture() {}
    public func startVideoCapture() -> Bool { false }
    public func stopVideoCapture() {}

    @_spi(OpenUIKitHost)
    public func _hostCancel() { _finishCancelled() }

    @_spi(OpenUIKitHost)
    public func _hostPick(info: [InfoKey: Any]) {
        guard !didFinish else { return }
        didFinish = true
        (delegate as? UIImagePickerControllerDelegate)?
            .imagePickerController(self, didFinishPickingMediaWithInfo: info)
        if presentingViewController != nil { dismiss(animated: true) }
    }

    private func _finishCancelled() {
        guard !didFinish else { return }
        didFinish = true
        (delegate as? UIImagePickerControllerDelegate)?
            .imagePickerControllerDidCancel(self)
        if presentingViewController != nil { dismiss(animated: true) }
    }
}

public func UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(_ videoPath: String) -> Bool {
    _ = videoPath
    return false
}

public func UISaveVideoAtPathToSavedPhotosAlbum(
    _ videoPath: String,
    _ completionTarget: Any?,
    _ completionSelector: Selector?,
    _ contextInfo: UnsafeMutableRawPointer?
) {
    _ = videoPath
    _ = completionTarget
    _ = completionSelector
    _ = contextInfo
}

import Foundation

/// Fail-closed picker. MEASURED /tmp/mp_oracle.json iOS 26.1:
/// `allowsPickingMultipleItems` false, `showsCloudItems` true,
/// `showsItemsWithProtectedAssets` true, `prompt` nil, superclass
/// UIViewController. Never presents a library UI on Linux.
@MainActor
open class MPMediaPickerController: UIViewController {
    public private(set) var mediaTypes: MPMediaType
    public var allowsPickingMultipleItems: Bool = false
    public weak var delegate: (any MPMediaPickerControllerDelegate)?
    public var prompt: String?
    public var showsCloudItems: Bool = true
    public var showsItemsWithProtectedAssets: Bool = true

    public init(mediaTypes: MPMediaType) {
        self.mediaTypes = mediaTypes
        super.init()
    }
}

public protocol MPMediaPickerControllerDelegate: NSObjectProtocol {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection)
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController)
}

extension MPMediaPickerControllerDelegate {
    public func mediaPicker(
        _ mediaPicker: MPMediaPickerController,
        didPickMediaItems mediaItemCollection: MPMediaItemCollection
    ) {
        _ = mediaPicker
        _ = mediaItemCollection
    }

    public func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        _ = mediaPicker
    }
}

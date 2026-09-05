import Foundation
import PhotosUI

/// Schema-v2 sealed acceptance compiles `tests/agent/*Tests.swift`.
/// This file records the runtime contract those tests exercise: picker
/// filter composition, PHPickerViewController._present() main-thread
/// delivery, NSItemProvider loadObject/loadFileRepresentation, typed
/// transferable load, fail-closed system UI, and OptionSet/enum identities
/// corroborated by pinned macios bindings and Apple's PhotosUI docs.
enum PhotosUIRuntime {
    static let portableSelectionLimitDefault = 1
}

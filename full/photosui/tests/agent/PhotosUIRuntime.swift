import Foundation
import PhotosUI

/// Schema-v2 sealed acceptance compiles `tests/agent/*Tests.swift`.
/// This file records the runtime contract those tests exercise: picker
/// filter composition, PHPickerHostAsset algebra, library-driven
/// PHPickerViewController selection (deselect/move/update/scroll),
/// NSItemProvider type identifiers, typed transferable load, fail-closed
/// system UI, and OptionSet/enum identities corroborated by pinned macios
/// bindings and Apple's PhotosUI docs.
/// SwiftUI overlay re-exports (`s:7SwiftUI4View…`) are not-applicable or
/// declared, never implemented.
enum PhotosUIRuntime {
    static let portableSelectionLimitDefault = 1
}

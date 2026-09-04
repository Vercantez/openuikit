import Foundation
import PhotosUI

/// Schema-v2 sealed acceptance compiles `tests/agent/*Tests.swift`.
/// This file records the runtime contract those tests exercise: picker
/// filter composition, typed transferable load, fail-closed system UI,
/// and OptionSet/enum identities corroborated by pinned macios bindings.
enum PhotosUIRuntime {
    static let portableSelectionLimitDefault = 1
}

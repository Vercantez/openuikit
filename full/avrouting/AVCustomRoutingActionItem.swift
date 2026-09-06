import Foundation

/// A custom action shown in the system routing picker.
///
/// `overrideTitle` and `type` are stored locally. Linux never presents a
/// routing-picker UI, so mutating these fields does not show a sheet.
/// Darwin's default `type` after `init()` is unobserved; Linux starts
/// with an empty identifier.
///
/// Apple graph: `open class AVCustomRoutingActionItem: NSObject`, iOS 16+.
/// `@NSCopying var type: UTType`. Not Sendable in the graph.
open class AVCustomRoutingActionItem: NSObject {
    /// Replacement title for the action item. `nil` means no override.
    public var overrideTitle: String?

    /// Type of the custom action. Isolated-host `UTType` is an identifier
    /// string overlay; the real UniformTypeIdentifiers type is used when
    /// that module is importable.
    public var type: UTType

    public override init() {
        self.overrideTitle = nil
        self.type = UTType(identifier: "")
        super.init()
    }
}

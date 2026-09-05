import Foundation

open class PKResponderState: NSObject {
    public var activeToolPicker: PKToolPicker?
    public var toolPickerVisibility: PKToolPickerVisibility?

    public override init() {
        super.init()
    }
}

#if canImport(UIKit)
extension UIResponder {
    private static var pkStateKey: UInt8 = 0

    public var pencilKitResponderState: PKResponderState {
        if let existing = objc_getAssociatedObject(self, &Self.pkStateKey) as? PKResponderState {
            return existing
        }
        let created = PKResponderState()
        objc_setAssociatedObject(self, &Self.pkStateKey, created, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return created
    }
}
#endif

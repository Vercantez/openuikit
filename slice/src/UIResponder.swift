// UIResponder.
// VENDOR-EDIT (swift-macho-linux slice): minimal base class. ~/uikit's real
// UIResponder carries the responder chain, first-responder machinery, key
// commands and touch entry points (all pulling UIWindow / UIEvent / UITouch /
// UIKeyCommand). None are on the static render path, so this slice keeps only
// the empty base UIView inherits from.
open class UIResponder {
    public init() {}
    open var next: UIResponder? { nil }
}

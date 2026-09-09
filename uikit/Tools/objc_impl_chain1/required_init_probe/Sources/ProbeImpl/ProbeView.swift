import Foundation
import ProbeHeader

@objc @implementation extension ProbeView {
    public var frame: CGRect = .zero
    public init(frame: CGRect) { super.init(); self.frame = frame }
    // NSCoding makes this `required`; the compiler insists on the modifier
    // ("initializer 'init(coder:)' should be 'required' to match initializer
    // declared by the header" without it).
    public required init?(coder: NSCoder) { super.init() }
    public convenience override init() { self.init(frame: .zero) }
    @objc(encodeWithCoder:) public func encode(with coder: NSCoder) {}
}

/// A DIRECT Swift subclass compiles (UILabel's shape).
open class ProbeLabel: ProbeView {
    public override init(frame: CGRect) { super.init(frame: frame) }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

/// A Swift subclass TWO levels down does not (UIButton : UIControl : UIView),
/// whatever it declares:
///   error: 'required' initializer 'init(coder:)' must be provided by subclass of 'ProbeView'
///   note: 'required' initializer is declared in superclass here  (ProbeView.h, initWithCoder:)
/// and, as a consequence, it no longer inherits the convenience `init()`.
#if PROBE_SAME_MODULE
public final class ProbeButton: ProbeLabel {
    public override init(frame: CGRect) { super.init(frame: frame) }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
@MainActor func _use() { _ = ProbeButton() }
#endif

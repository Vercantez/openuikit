// MiniAnimation.swift -- NOT part of ~/uikit.
// Provenance: replaces ~/uikit's UIViewAnimation.swift (453 lines: UIView.animate
// blocks, presentation sampling, completion queue, UIWindow.tick clock) for the
// static render slice. Keeps only the value types UIView's property observers
// name and a no-op recordAnimation -- with no active UIView.animate context, the
// real recordAnimation is a no-op too, so the render is unchanged.

struct UIViewAnimation {
    enum Property {
        case position, bounds, alpha, backgroundColor, transform, cornerRadius
    }
    enum Value {
        case scalar(CGFloat)
        case point(CGPoint)
        case rect(CGRect)
        case color(UIColor?)
        case transform(CGAffineTransform)
    }
}

extension UIView {
    func recordAnimation(_ property: UIViewAnimation.Property,
                         from: UIViewAnimation.Value,
                         to: UIViewAnimation.Value) {
        // No UIView.animate context in the render slice: nothing to record.
    }
}

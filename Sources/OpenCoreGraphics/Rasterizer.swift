// Software rasterizer implementation for Canvas.
// OWNED BY: rasterizer module. Implement every _-prefixed hook.
// See Canvas.swift for the contract and required semantics.

extension Canvas {
    func _save() {
        fatalError("rasterizer: unimplemented")
    }
    func _restore() {
        fatalError("rasterizer: unimplemented")
    }
    func _concatenate(_ t: CGAffineTransform) {
        fatalError("rasterizer: unimplemented")
    }
    func _clip(_ path: Path) {
        fatalError("rasterizer: unimplemented")
    }
    func _beginLayer(_ alpha: CGFloat) {
        fatalError("rasterizer: unimplemented")
    }
    func _endLayer() {
        fatalError("rasterizer: unimplemented")
    }
    func _fill(_ path: Path, _ color: CGColor, _ evenOdd: Bool) {
        fatalError("rasterizer: unimplemented")
    }
    func _stroke(_ path: Path, _ color: CGColor, _ lineWidth: CGFloat) {
        fatalError("rasterizer: unimplemented")
    }
    func _drawImage(_ image: Bitmap, _ rect: CGRect, _ interpolate: Bool) {
        fatalError("rasterizer: unimplemented")
    }
    func _drawMask(_ mask: [UInt8], _ w: Int, _ h: Int, _ x: Int, _ y: Int, _ color: CGColor) {
        fatalError("rasterizer: unimplemented")
    }
}

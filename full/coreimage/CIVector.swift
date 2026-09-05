import Foundation

public class CIVector: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private let values: [CGFloat]

    public var count: Int { values.count }
    public var x: CGFloat { value(at: 0) }
    public var y: CGFloat { value(at: 1) }
    public var z: CGFloat { value(at: 2) }
    public var w: CGFloat { value(at: 3) }

    public var cgPointValue: CGPoint { CGPoint(x: x, y: y) }
    public var cgRectValue: CGRect {
        CGRect(x: value(at: 0), y: value(at: 1), width: value(at: 2), height: value(at: 3))
    }
    public var cgAffineTransformValue: CGAffineTransform {
        CGAffineTransform(
            a: value(at: 0),
            b: value(at: 1),
            c: value(at: 2),
            d: value(at: 3),
            tx: value(at: 4),
            ty: value(at: 5)
        )
    }

    public var stringRepresentation: String {
        "[" + values.map { String(format: "%.6g", Double($0)) }.joined(separator: " ") + "]"
    }

    public init(values: UnsafePointer<CGFloat>, count: Int) {
        self.values = (0..<max(0, count)).map { values[$0] }
        super.init()
    }

    public convenience init(x: CGFloat) {
        self.init(scalars: [x])
    }

    public convenience init(x: CGFloat, y: CGFloat) {
        self.init(scalars: [x, y])
    }

    public convenience init(x: CGFloat, Y y: CGFloat) {
        self.init(x: x, y: y)
    }

    public convenience init(x: CGFloat, y: CGFloat, z: CGFloat) {
        self.init(scalars: [x, y, z])
    }

    public convenience init(x: CGFloat, Y y: CGFloat, Z z: CGFloat) {
        self.init(x: x, y: y, z: z)
    }

    public convenience init(x: CGFloat, y: CGFloat, z: CGFloat, w: CGFloat) {
        self.init(scalars: [x, y, z, w])
    }

    public convenience init(x: CGFloat, Y y: CGFloat, Z z: CGFloat, W w: CGFloat) {
        self.init(x: x, y: y, z: z, w: w)
    }

    public convenience init(cgPoint p: CGPoint) {
        self.init(x: p.x, y: p.y)
    }

    public convenience init(CGPoint p: CGPoint) {
        self.init(cgPoint: p)
    }

    public convenience init(cgRect r: CGRect) {
        self.init(x: r.origin.x, y: r.origin.y, z: r.size.width, w: r.size.height)
    }

    public convenience init(CGRect r: CGRect) {
        self.init(cgRect: r)
    }

    public convenience init(cgAffineTransform t: CGAffineTransform) {
        self.init(scalars: [t.a, t.b, t.c, t.d, t.tx, t.ty])
    }

    public convenience init(CGAffineTransform t: CGAffineTransform) {
        self.init(cgAffineTransform: t)
    }

    public convenience init(string representation: String) {
        let trimmed = representation.trimmingCharacters(in: CharacterSet(charactersIn: "[]() "))
        let parts = trimmed.split(whereSeparator: { $0 == " " || $0 == "," })
            .compactMap { CGFloat(Double($0) ?? 0) }
        self.init(scalars: parts)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CIVector else { return false }
        guard count == other.count else { return false }
        for index in 0..<count {
            if value(at: index) != other.value(at: index) { return false }
        }
        return true
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(count)
        for index in 0..<count {
            hasher.combine(value(at: index))
        }
        return hasher.finalize()
    }

    public func value(at index: Int) -> CGFloat {
        guard index >= 0, index < values.count else { return 0 }
        return values[index]
    }

    private init(scalars: [CGFloat]) {
        self.values = scalars
        super.init()
    }
}

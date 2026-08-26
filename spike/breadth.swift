// Breadth probe: is it only trivial Swift that survives, or the language?
// Compile-only -- this exists to find stdlib-interface holes, not to run.
import ObjectiveC

public protocol Drawable: AnyObject { func draw(into: inout [String]) }

public struct Rect: Equatable, CustomStringConvertible {
    public var x, y, w, h: Double
    public init(x: Double, y: Double, w: Double, h: Double) { (self.x, self.y, self.w, self.h) = (x, y, w, h) }
    public var description: String { "Rect(\(x), \(y), \(w), \(h))" }
}

open class View: NSObject, Drawable {
    public var frame = Rect(x: 0, y: 0, w: 0, h: 0)
    public var subviews: [View] = []
    private var handlers: [String: (View) -> Void] = [:]
    @objc open dynamic func layout() {}
    public func on(_ name: String, _ h: @escaping (View) -> Void) { handlers[name] = h }
    public func fire(_ name: String) { handlers[name]?(self) }
    open func draw(into out: inout [String]) {
        out.append("\(type(of: self)) \(frame)")
        for s in subviews.sorted(by: { $0.frame.x < $1.frame.x }) { s.draw(into: &out) }
    }
}

public enum Edge: Int, CaseIterable { case top, left, bottom, right }

public func describe<T: Drawable>(_ items: [T]) -> String {
    var out: [String] = []
    for i in items { i.draw(into: &out) }
    return out.joined(separator: "; ") + " edges=\(Edge.allCases.map(\.rawValue))"
}

@available(macOS 11, *)
public func asyncish() async throws -> Int {
    try await withCheckedThrowingContinuation { c in c.resume(returning: 7) }
}

@_cdecl("breadth_probe")
public func breadthProbe() -> Int32 {
    let root = View(); root.frame = Rect(x: 0, y: 0, w: 100, h: 50)
    for i in (0..<3).reversed() {
        let v = View(); v.frame = Rect(x: Double(i) * 10, y: 0, w: 5, h: 5)
        root.subviews.append(v)
    }
    var hits = 0
    root.on("tap") { _ in hits += 1 }
    root.fire("tap"); root.fire("tap")
    print(describe([root]))
    print("hits=\(hits) responds(layout)=\(root.responds(to: #selector(View.layout)))")
    return Int32(root.subviews.count + hits)
}

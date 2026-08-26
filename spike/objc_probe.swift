// Rung 4: does a Darwin-targeted build on Linux have real Objective-C interop?
// No Foundation anywhere -- only the ObjectiveC overlay over objc4's headers.
import ObjectiveC

@objc public class SpikeCounter: NSObject {
    @objc public var value: Int32 = 0
    @objc public func bump() { value += 1 }
}

@_cdecl("objc_probe")
public func objcProbe() -> Int32 {
    let c = SpikeCounter()
    c.bump(); c.bump(); c.bump()
    let sel = #selector(SpikeCounter.bump)
    let responds = c.responds(to: sel)
    let cls = String(cString: class_getName(type(of: c)))
    let name = String(cString: sel_getName(sel))
    print("objc: class=\(cls) sel=\(name) responds=\(responds) value=\(c.value)")
    return c.value
}

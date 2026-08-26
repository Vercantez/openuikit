// png_probe.swift -- isolates the isa-decode paths that machorun's image
// placement used to break. Every case is graded against native macOS.
protocol Backend: AnyObject { func v() -> Int32 }
final class ImplA: Backend { func v() -> Int32 { 3 } }

@_cdecl("p_existential") public func p_existential() -> Int32 {
    let b: Backend = ImplA()          // class-bound protocol existential
    let r = b.v()                     // witness dispatch
    return r                          // b released here
}
@_cdecl("p_plainclass") public func p_plainclass() -> Int32 {
    final class C { var x: Int32 = 5 }
    let c = C(); return c.x           // native class release -> swift_release
}
@_cdecl("p_arrayslice") public func p_arrayslice() -> Int32 {
    var arr: [UInt8] = []
    for i in 0..<32 { arr.append(UInt8(i)) }
    let s = arr[4..<20]
    var sum: Int32 = 0
    for b in s { sum &+= Int32(b) }
    return sum &+ Int32(s.count)      // 184 + 16 = 200
}
@_cdecl("p_string") public func p_string() -> Int32 {
    let s = "boxes" + "_basic"
    return Int32(s.count)             // 11
}

// --- bare AnyObject: the cheapest swift_unknownObject{Retain,Release} path ---
@_cdecl("p_anyobject") public func p_anyobject() -> Int32 {
    final class D { var y: Int32 = 7 }
    let o: AnyObject = D()            // unknown-object reference
    let d = o as! D
    return d.y                        // 7
}
// --- NON-class-bound existential (what CanvasBackend actually is) ---
protocol AnyBackend { func w() -> Int32 }
final class ImplB: AnyBackend { func w() -> Int32 { 13 } }
@_cdecl("p_anyexistential") public func p_anyexistential() -> Int32 {
    let b: AnyBackend = ImplB()       // not AnyObject-constrained -> boxed existential
    return b.w()                      // 13
}
// --- runtime-instantiated generic metadata over a USER type ---
final class Elem { var n: Int32; init(_ n: Int32) { self.n = n } }
@_cdecl("p_userarrayslice") public func p_userarrayslice() -> Int32 {
    var arr: [Elem] = []              // __ContiguousArrayStorage<Elem>: NOT prespecialized
    for i in 0..<10 { arr.append(Elem(Int32(i))) }
    let s = arr[2..<8]                // ArraySlice over user-class storage
    var sum: Int32 = 0
    for e in s { sum &+= e.n }
    return sum &+ Int32(s.count)      // 2+..+7 = 27, +6 = 33
}
final class Box<T> { var t: T; init(_ t: T) { self.t = t } }
@_cdecl("p_genericclass") public func p_genericclass() -> Int32 {
    let b = Box<Elem>(Elem(21))       // runtime-instantiated generic CLASS metadata
    let c = Box<Int32>(4)
    return b.t.n &+ c.t               // 25
}
// --- unowned: side-table path ---
final class Owner { var v: Int32 = 6 }
final class Holder { unowned let o: Owner; init(_ o: Owner) { self.o = o } }
@_cdecl("p_unowned") public func p_unowned() -> Int32 {
    let o = Owner(); let h = Holder(o)
    return h.o.v &* 3                 // 18
}

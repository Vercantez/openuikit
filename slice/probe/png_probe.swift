protocol Backend: AnyObject { func v() -> Int32 }
final class ImplA: Backend { func v() -> Int32 { 3 } }
@_cdecl("p_existential") public func p_existential() -> Int32 {
    let b: Backend = ImplA()          // class-bound protocol existential
    let r = b.v()                     // witness dispatch
    return r                          // b released here -> swift_unknownObjectRelease
}
@_cdecl("p_plainclass") public func p_plainclass() -> Int32 {
    final class C { var x: Int32 = 5 }
    let c = C(); return c.x           // native class release -> swift_release
}

import Foundation

enum _AccelerateNumeric {
    static func zip3<A, B, O>(
        _ a: A,
        _ b: B,
        _ out: inout O,
        _ combine: (A.Element, B.Element) -> O.Element
    ) where A: AccelerateBuffer, B: AccelerateBuffer, O: AccelerateMutableBuffer {
        a.withUnsafeBufferPointer { av in
            b.withUnsafeBufferPointer { bv in
                out.withUnsafeMutableBufferPointer { ov in
                    let n = min(av.count, min(bv.count, ov.count))
                    for i in 0..<n {
                        ov[i] = combine(av[i], bv[i])
                    }
                }
            }
        }
    }

    static func map<A, O>(
        _ a: A,
        _ out: inout O,
        _ transform: (A.Element) -> O.Element
    ) where A: AccelerateBuffer, O: AccelerateMutableBuffer {
        a.withUnsafeBufferPointer { av in
            out.withUnsafeMutableBufferPointer { ov in
                let n = min(av.count, ov.count)
                for i in 0..<n {
                    ov[i] = transform(av[i])
                }
            }
        }
    }

    static func countOf<A>(_ a: A) -> Int where A: AccelerateBuffer {
        a.withUnsafeBufferPointer { $0.count }
    }
}

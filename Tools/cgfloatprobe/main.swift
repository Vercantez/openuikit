#if canImport(CoreGraphics)
import CoreGraphics
let probeMode = "native"
#else
let probeMode = "foundation-hidden-macho"
#endif

protocol DistinctCGFloatWitness {}
extension Double: DistinctCGFloatWitness {}
extension CGFloat: DistinctCGFloatWitness {}

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        print("CGFLOAT_CONTRACT_FAIL mode=\(probeMode) check=\(message)")
        fatalError(message)
    }
}

require(MemoryLayout<CGFloat>.size == 8, "size")
require(MemoryLayout<CGFloat>.stride == 8, "stride")
require(MemoryLayout<CGFloat>.alignment == 8, "alignment")

let value = CGFloat(1.5)
require(Double(value) == 1.5, "double-conversion")
require(Float(value) == 1.5, "float-conversion")
require(value + 2 == 3.5, "addition")
require(value * 4 == 6, "multiplication")
require(value.distance(to: 4.5) == 3, "stride-distance")
require(value.advanced(by: 2) == 3.5, "stride-advance")
require(CGFloat(exactly: Int64(9)) == 9, "exact-integer")
require(CGFloat(exactly: Int64.max) == nil, "inexact-integer")
require(CGFloat(bitPattern: value.bitPattern) == value, "bit-pattern")
require(CGFloat.infinity.isInfinite, "infinity")
require(CGFloat.nan.isNaN, "nan")

var values = Set<CGFloat>()
values.insert(value)
values.insert(CGFloat(1.5))
require(values.count == 1, "hash-identity")

print("CGFLOAT_CONTRACT_OK mode=\(probeMode) size=\(MemoryLayout<CGFloat>.size) value=\(value)")

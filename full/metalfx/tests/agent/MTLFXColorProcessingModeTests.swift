import Foundation
import MetalFX

func testColorProcessingModeRawValues() {
    let table: [(MTLFXSpatialScalerColorProcessingMode, Int)] = [
        (.perceptual, 0),
        (.linear, 1),
        (.hdr, 2),
    ]
    for (mode, raw) in table {
        precondition(mode.rawValue == raw)
        precondition(MTLFXSpatialScalerColorProcessingMode(rawValue: raw) == mode)
    }
    precondition(MTLFXSpatialScalerColorProcessingMode(rawValue: 3) == nil)
    precondition(MTLFXSpatialScalerColorProcessingMode(rawValue: -1) == nil)
}

func testColorProcessingModeInequality() {
    precondition(MTLFXSpatialScalerColorProcessingMode.perceptual != .linear)
    precondition(MTLFXSpatialScalerColorProcessingMode.linear != .hdr)
    precondition(!(MTLFXSpatialScalerColorProcessingMode.hdr != .hdr))
}

func testColorProcessingModeHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    MTLFXSpatialScalerColorProcessingMode.linear.hash(into: &hasherA)
    MTLFXSpatialScalerColorProcessingMode.linear.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        MTLFXSpatialScalerColorProcessingMode.perceptual.hashValue
            != MTLFXSpatialScalerColorProcessingMode.hdr.hashValue
    )
    var set: Set<MTLFXSpatialScalerColorProcessingMode> = []
    set.insert(.perceptual)
    set.insert(.linear)
    set.insert(.hdr)
    set.insert(.linear)
    precondition(set.count == 3)
}

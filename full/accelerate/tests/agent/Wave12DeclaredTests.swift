import Accelerate
import Foundation

// Wave 12 declared-remainder conversion: exercise the two Apple protocol
// witnesses whose Linux requirements were missing. The api-digester confirms
// all four overlay optimizers conform to BNNSOptimizer and the ten pixel
// formats below conform to InitializableFromCGImage; the conformances added
// this wave only cover the witnessed members (optimizer getters with
// oracle-pinned wave-10 values, pixel-format bitCountPerComponent). CGImage
// initializers stay deferred: CoreGraphics is not a declared dependency.
// No test uses DispatchQueue.main, RunLoop, semaphores, or await.

func testWave12OptimizerFunctionWitness() {
    let optimizers: [any BNNSOptimizer] = [
        BNNS.AdamOptimizer(),
        BNNS.AdamWOptimizer(),
        BNNS.RMSPropOptimizer(),
        BNNS.SGDMomentumOptimizer(),
    ]
    precondition(optimizers.map { $0.bnnsOptimizerFunction.rawValue } == [8, 10, 9, 7])
    var amsgradOpt = BNNS.AdamOptimizer()
    amsgradOpt.usesAMSGrad = true
    let amsgrad: any BNNSOptimizer = amsgradOpt
    precondition(amsgrad.bnnsOptimizerFunction.rawValue == 11)
}

func testWave12OptimizerAccumulatorWitness() {
    let optimizers: [any BNNSOptimizer] = [
        BNNS.AdamOptimizer(),
        BNNS.AdamWOptimizer(),
        BNNS.RMSPropOptimizer(),
        BNNS.SGDMomentumOptimizer(),
    ]
    precondition(optimizers.map { $0.accumulatorCountMultiplier } == [2, 2, 1, 0])
    var amsgradOpt = BNNS.AdamOptimizer()
    amsgradOpt.usesAMSGrad = true
    let amsgrad: any BNNSOptimizer = amsgradOpt
    precondition(amsgrad.accumulatorCountMultiplier == 3)
}

func testWave12CGImageFormatWitness() {
    let formats: [(any InitializableFromCGImage.Type, Int)] = [
        (vImage.Planar8.self, 8),
        (vImage.Interleaved8x3.self, 8),
        (vImage.Interleaved8x4.self, 8),
        (vImage.Planar16F.self, 16),
        (vImage.Interleaved16Fx4.self, 16),
        (vImage.PlanarF.self, 32),
        (vImage.InterleavedFx3.self, 32),
        (vImage.InterleavedFx4.self, 32),
        (vImage.Interleaved16Ux2.self, 16),
        (vImage.Interleaved16Ux4.self, 16),
    ]
    for (format, expected) in formats {
        precondition(format.bitCountPerComponent == expected)
    }
}

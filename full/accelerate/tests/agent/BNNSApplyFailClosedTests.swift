import Accelerate
import Foundation

private func _accDummy() -> UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(bitPattern: 1)!
}

func testBNNSFilterApplyFailClosed() {
    var descA = BNNSNDArrayDescriptor()
    var descB = BNNSNDArrayDescriptor()
    var descC = BNNSNDArrayDescriptor()
    let p = _accDummy()
    precondition(BNNSFilterApply(nil, p, p) == BNNSLinuxFailClosedStatus)
    precondition(BNNSFilterApplyBatch(nil, 1, p, 0, p, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSFilterApplyTwoInput(nil, p, p, p) == BNNSLinuxFailClosedStatus)
    precondition(BNNSFilterApplyTwoInputBatch(nil, 1, p, 0, p, 0, p, 0) == BNNSLinuxFailClosedStatus)
    BNNSFilterDestroy(nil)
    _ = BNNSGetPointer(nil, BNNSPointerSpecifier(rawValue: 0))
    var act = BNNSLayerParametersActivation()
    precondition(BNNSDirectApplyActivationBatch(&act, nil, 1, 0, 0) == BNNSLinuxFailClosedStatus)
    var lstm = BNNSLayerParametersLSTM()
    precondition(BNNSComputeLSTMTrainingCacheCapacity(&lstm) == 0)
    var crop = BNNSLayerParametersCropResize()
    precondition(BNNSCropResize(&crop, &descA, &descB, &descC, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSCropResizeBackward(&crop, &descA, &descB, &descC, nil) == BNNSLinuxFailClosedStatus)
}

func testBNNSApplyBatchFailClosed() {
    var descA = BNNSNDArrayDescriptor()
    var descB = BNNSNDArrayDescriptor()
    var descC = BNNSNDArrayDescriptor()
    var descD = BNNSNDArrayDescriptor()
    let p = _accDummy()
    var inDelta = descA
    var inDeltaB = descA
    precondition(BNNSFilterApplyBackwardBatch(nil, 1, p, 0, &inDelta, 0, p, 0, &descA, 0, &descB, &descC) == BNNSLinuxFailClosedStatus)
    precondition(BNNSFilterApplyBackwardTwoInputBatch(nil, 1, p, 0, &inDelta, 0, p, 0, &inDeltaB, 0, p, 0, &descA, 0, &descB, &descC) == BNNSLinuxFailClosedStatus)
    var inPtr = UnsafeRawPointer(p)
    let stride = 0
    withUnsafeMutablePointer(to: &inPtr) { ip in
        withUnsafePointer(to: stride) { sp in
            precondition(BNNSArithmeticFilterApplyBatch(nil, 1, 1, ip, sp, p, 0) == BNNSLinuxFailClosedStatus)
        }
    }
    precondition(BNNSFusedFilterApplyBatch(nil, 1, p, 0, p, 0, false) == BNNSLinuxFailClosedStatus)
    precondition(BNNSLossFilterApplyBatch(nil, 1, p, 0, p, 0, nil, 0, p, &descD, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSNormalizationFilterApplyBatch(nil, 1, p, 0, p, 0, false) == BNNSLinuxFailClosedStatus)
    precondition(BNNSPoolingFilterApplyBatch(nil, 1, p, 0, p, 0, nil, 0) == BNNSLinuxFailClosedStatus)
}

func testBNNSTensorFailClosed() {
    var descA = BNNSNDArrayDescriptor()
    var descB = BNNSNDArrayDescriptor()
    var descC = BNNSNDArrayDescriptor()
    precondition(BNNSBandPart(0, 0, &descA, &descB, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSClipByNorm(&descB, &descA, 1, 0) == BNNSLinuxFailClosedStatus)
    withUnsafeMutablePointer(to: &descB) { destBase in
        var destPtr = destBase
        withUnsafePointer(to: descA) { srcBase in
            var srcPtr = srcBase
            withUnsafeMutablePointer(to: &destPtr) { destList in
                withUnsafeMutablePointer(to: &srcPtr) { srcList in
                    _ = BNNSClipByGlobalNorm(destList, srcList, 1, 1, 1)
                }
            }
        }
    }
    precondition(BNNSComputeNorm(&descB, &descA, BNNSNormType(rawValue: 0), 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSGather(0, &descA, &descB, &descC, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSGatherND(&descA, &descB, &descC, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSScatter(0, BNNSReduceFunction(rawValue: 0), &descA, &descB, &descC, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSScatterND(BNNSReduceFunction(rawValue: 0), &descA, &descB, &descC, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSShuffle(BNNSShuffleType(rawValue: 0), &descA, &descB, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSTileBackward(&descB, &descA, nil) == BNNSLinuxFailClosedStatus)
}

func testBNNSRandomAndSparsifyFailClosed() {
    var descA = BNNSNDArrayDescriptor()
    var descB = BNNSNDArrayDescriptor()
    var descC = BNNSNDArrayDescriptor()
    var descD = BNNSNDArrayDescriptor()
    var descE = BNNSNDArrayDescriptor()
    BNNSDestroyNearestNeighbors(nil)
    BNNSDestroyRandomGenerator(nil)
    precondition(BNNSNearestNeighborsLoad(nil, 0, _accDummy()) == BNNSLinuxFailClosedStatus)
    precondition(BNNSNearestNeighborsGetInfo(nil, 0, nil, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSRandomGeneratorStateSize(nil) == 0)
    var sparse = BNNSSparsityParameters()
    precondition(BNNSNDArrayFullyConnectedSparsifySparseCOO(&descA, &descB, &descC, &descD, &sparse, 1, nil, 0, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSNDArrayFullyConnectedSparsifySparseCSR(&descA, &descB, &descC, &descD, &descE, &sparse, 1, nil, 0, nil) == BNNSLinuxFailClosedStatus)
    withUnsafeMutablePointer(to: &descA) { d in
        var param = d
        var grad: UnsafePointer<BNNSNDArrayDescriptor> = UnsafePointer(d)
        withUnsafeMutablePointer(to: &param) { pp in
            withUnsafeMutablePointer(to: &grad) { gp in
                precondition(
                    BNNSOptimizerStep(BNNSOptimizerFunction(rawValue: 0), _accDummy(), 1, pp, gp, nil, nil)
                        == BNNSLinuxFailClosedStatus
                )
            }
        }
    }
    var red = BNNSLayerParametersReduction()
    precondition(BNNSDirectApplyReduction(&red, nil) == BNNSLinuxFailClosedStatus)
    var quant = BNNSLayerParametersQuantization()
    precondition(BNNSDirectApplyQuantizer(&quant, nil, 1, 0, 0) == BNNSLinuxFailClosedStatus)
    BNNSDirectApplyBroadcastMatMul(false, false, 1, &descA, &descB, &descC, nil)
}

func testBNNSMoreApplyFailClosed() {
    var descA = BNNSNDArrayDescriptor()
    var descB = BNNSNDArrayDescriptor()
    var descC = BNNSNDArrayDescriptor()
    let p = _accDummy()
    precondition(BNNSApplyMultiheadAttention(nil, 1, p, 0, p, 0, nil, 0, p, 0, p, 0, nil, nil, nil, nil, nil) == BNNSLinuxFailClosedStatus)
    var mha = BNNSMHAProjectionParameters()
    _ = BNNSApplyMultiheadAttentionBackward(nil, 1, nil, 0, nil, nil, 0, nil, 0, nil, nil, 0, nil, nil, nil, nil, nil, 0, &mha, 0, nil, nil, nil)
    withUnsafeMutablePointer(to: &descA) { d in
        var dp = d
        let stride = 0
        withUnsafeMutablePointer(to: &dp) { dpp in
            withUnsafePointer(to: stride) { sp in
                _ = BNNSArithmeticFilterApplyBackwardBatch(nil, 1, 1, nil, nil, dpp, sp, nil, 0, d, 0)
            }
        }
    }
    var lstm = BNNSLayerParametersLSTM()
    var lstmDelta = BNNSLayerParametersLSTM()
    precondition(BNNSDirectApplyLSTMBatchBackward(&lstm, &lstmDelta, nil, nil, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSDirectApplyLSTMBatchTrainingCaching(&lstm, nil, nil, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSDirectApplyInTopK(1, 0, 1, &descA, 0, &descB, 0, &descC, 0, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSDirectApplyTopK(1, 0, 1, &descA, 0, &descB, 0, nil, 0, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSFusedFilterApplyBackwardBatch(nil, 1, nil, 0, &descA, 0, nil, 0, &descB, 0, nil) == BNNSLinuxFailClosedStatus)
    var inPtr = UnsafeRawPointer(p)
    let stride = 0
    withUnsafeMutablePointer(to: &inPtr) { ip in
        withUnsafePointer(to: stride) { sp in
            precondition(BNNSFusedFilterApplyMultiInputBatch(nil, 1, 1, ip, sp, p, 0, false) == BNNSLinuxFailClosedStatus)
        }
    }
    withUnsafeMutablePointer(to: &descA) { d in
        var dp = d
        let stride2 = 0
        withUnsafeMutablePointer(to: &dp) { dpp in
            withUnsafePointer(to: stride2) { sp in
                precondition(
                    BNNSFusedFilterApplyBackwardMultiInputBatch(nil, 1, 1, nil, nil, dpp, sp, nil, 0, d, 0, nil)
                        == BNNSLinuxFailClosedStatus
                )
            }
        }
    }
    precondition(BNNSLossFilterApplyBackwardBatch(nil, 1, p, 0, &descA, 0, p, 0, nil, 0, &descB, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSNormalizationFilterApplyBackwardBatch(nil, 1, &descA, 0, nil, 0, &descB, 0, nil, nil) == BNNSLinuxFailClosedStatus)
    precondition(BNNSPermuteFilterApplyBackwardBatch(nil, 1, &descA, 0, &descB, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSPoolingFilterApplyBackwardBatch(nil, 1, nil, 0, nil, 0, nil, 0, &descA, 0, nil, nil, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSPoolingFilterApplyBackwardBatchEx(nil, 1, nil, 0, nil, 0, nil, 0, &descA, 0, nil, BNNSDataType(rawValue: 0), nil, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSPoolingFilterApplyBatchEx(nil, 1, p, 0, p, 0, BNNSDataType(rawValue: 0), nil, 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSComputeNormBackward(p, &descA, p, &descB, BNNSNormType(rawValue: 0), 0) == BNNSLinuxFailClosedStatus)
    precondition(BNNSDataLayoutGetRank(BNNSDataLayout(rawValue: 0)) == 0)
    _ = BNNSRandomFillCategoricalFloat(nil, &descA, &descB, false)
    _ = BNNSRandomFillNormalFloat(nil, &descA, 0, 0)
    _ = BNNSRandomFillUniformFloat(nil, &descA, 0, 0)
    _ = BNNSRandomFillUniformInt(nil, &descA, 0, 0)
    var state = [UInt8](repeating: 0, count: 8)
    state.withUnsafeMutableBytes { raw in
        _ = BNNSRandomGeneratorGetState(nil, 0, raw.baseAddress!)
        _ = BNNSRandomGeneratorSetState(nil, 0, raw.baseAddress!)
    }
    var tensor = BNNSTensor()
    _ = BNNSTensorGetAllocationSize(&tensor)
}

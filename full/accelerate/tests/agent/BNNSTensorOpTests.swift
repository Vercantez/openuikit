import Accelerate
import Foundation

private func _desc(_ data: UnsafeMutablePointer<Float>, _ count: Int) -> BNNSNDArrayDescriptor {
    var d = BNNSNDArrayDescriptor()
    d.data = UnsafeMutableRawPointer(data)
    d.data_type = BNNSDataTypeFloat32
    d.size.0 = count
    return d
}

func testBNNSCopyFloat() {
    var srcVals: [Float] = [1, 2, 3, 4]
    var dstVals: [Float] = [0, 0, 0, 0]
    var src = _desc(&srcVals, 4)
    var dst = _desc(&dstVals, 4)
    precondition(BNNSCopy(&dst, &src, nil) == 0)
    precondition(dstVals == srcVals)
    precondition(BNNSNDArrayGetDataSize(&src) == 16)
}

func testBNNSClipByValueFloat() {
    var srcVals: [Float] = [-2, 0.5, 9]
    var dstVals: [Float] = [0, 0, 0]
    var src = _desc(&srcVals, 3)
    var dst = _desc(&dstVals, 3)
    precondition(BNNSClipByValue(&dst, &src, 0, 1) == 0)
    precondition(dstVals == [0, 0.5, 1])
}

func testBNNSCompareTensorFloat() {
    var aVals: [Float] = [1, 2, 3]
    var bVals: [Float] = [1, 0, 3]
    var oVals: [Float] = [9, 9, 9]
    var a = _desc(&aVals, 3)
    var b = _desc(&bVals, 3)
    var o = _desc(&oVals, 3)
    precondition(BNNSCompareTensor(&a, &b, BNNSRelationalOperatorEqual, &o) == 0)
    precondition(oVals == [1, 0, 1])
    _ = BNNSCompareTensor(&a, &b, BNNSRelationalOperatorNotEqual, &o)
    _ = BNNSCompareTensor(&a, &b, BNNSRelationalOperatorGreater, &o)
    _ = BNNSCompareTensor(&a, &b, BNNSRelationalOperatorLess, &o)
    _ = BNNSCompareTensor(&a, &b, BNNSRelationalOperatorGreaterEqual, &o)
    _ = BNNSCompareTensor(&a, &b, BNNSRelationalOperatorLessEqual, &o)
}

func testBNNSMatMulFloatIdentity() {
    var aVals: [Float] = [1, 2, 3, 4]
    var bVals: [Float] = [1, 0, 0, 1]
    var cVals: [Float] = [0, 0, 0, 0]
    aVals.withUnsafeMutableBufferPointer { ap in
        bVals.withUnsafeMutableBufferPointer { bp in
            cVals.withUnsafeMutableBufferPointer { cp in
                var A = BNNSNDArrayDescriptor()
                A.data = UnsafeMutableRawPointer(ap.baseAddress!)
                A.size.0 = 2
                A.size.1 = 2
                var B = BNNSNDArrayDescriptor()
                B.data = UnsafeMutableRawPointer(bp.baseAddress!)
                B.size.0 = 2
                B.size.1 = 2
                var C = BNNSNDArrayDescriptor()
                C.data = UnsafeMutableRawPointer(cp.baseAddress!)
                C.size.0 = 2
                C.size.1 = 2
                precondition(BNNSMatMul(false, false, 1, &A, &B, &C, nil, nil) == 0)
                precondition(Array(cp) == [1, 2, 3, 4])
                _ = BNNSMatMulWorkspaceSize(false, false, 1, &A, &B, &C, nil)
            }
        }
    }
}

func testBNNSTransposeFloat() {
    var srcVals: [Float] = [1, 2, 3, 4, 5, 6]
    var dstVals: [Float] = [0, 0, 0, 0, 0, 0]
    srcVals.withUnsafeMutableBufferPointer { sp in
        dstVals.withUnsafeMutableBufferPointer { dp in
            var src = BNNSNDArrayDescriptor()
            src.data = UnsafeMutableRawPointer(sp.baseAddress!)
            src.size.0 = 2
            src.size.1 = 3
            var dst = BNNSNDArrayDescriptor()
            dst.data = UnsafeMutableRawPointer(dp.baseAddress!)
            dst.size.0 = 3
            dst.size.1 = 2
            precondition(BNNSTranspose(&dst, &src, 0, 1, nil) == 0)
            precondition(Array(dp) == [1, 4, 2, 5, 3, 6])
        }
    }
}

func testBNNSTileFloat() {
    var srcVals: [Float] = [1, 2]
    var dstVals: [Float] = [0, 0, 0, 0]
    srcVals.withUnsafeMutableBufferPointer { sp in
        dstVals.withUnsafeMutableBufferPointer { dp in
            var src = BNNSNDArrayDescriptor()
            src.data = UnsafeMutableRawPointer(sp.baseAddress!)
            src.size.0 = 1
            src.size.1 = 2
            var dst = BNNSNDArrayDescriptor()
            dst.data = UnsafeMutableRawPointer(dp.baseAddress!)
            dst.size.0 = 2
            dst.size.1 = 2
            precondition(BNNSTile(&src, &dst, nil) == 0)
            precondition(Array(dp) == [1, 2, 1, 2])
        }
    }
}

import Accelerate
import Foundation

func testVImageBoxConvolveARGB8888MatchesAppleTranscript() {
    var source: [UInt8] = [
        10, 0, 1, 2,   20, 3, 4, 5,   30, 6, 7, 8,
        40, 9, 10, 11, 50, 12, 13, 14, 60, 15, 16, 17,
        70, 18, 19, 20, 80, 21, 22, 23, 90, 24, 25, 26
    ]
    var output = [UInt8](repeating: 0, count: source.count)
    let status = source.withUnsafeMutableBytes { sourceBytes in
        output.withUnsafeMutableBytes { outputBytes in
            var input = vImage_Buffer(
                data: sourceBytes.baseAddress,
                height: 3,
                width: 3,
                rowBytes: 12
            )
            var destination = vImage_Buffer(
                data: outputBytes.baseAddress,
                height: 3,
                width: 3,
                rowBytes: 12
            )
            return vImageBoxConvolve_ARGB8888(
                &input,
                &destination,
                nil,
                0,
                0,
                3,
                3,
                nil,
                vImage_Flags(kvImageEdgeExtend)
            )
        }
    }
    let expected: [UInt8] = [
        23, 4, 5, 6,   30, 6, 7, 8,   37, 8, 9, 10,
        43, 10, 11, 12, 50, 12, 13, 14, 57, 14, 15, 16,
        63, 16, 17, 18, 70, 18, 19, 20, 77, 20, 21, 22
    ]
    precondition(status == kvImageNoError)
    precondition(output == expected)
}

func testVImageBoxConvolveErrorCodes() {
    var source: [UInt8] = [
        10, 0, 1, 2, 20, 3, 4, 5,
        30, 6, 7, 8, 40, 9, 10, 11
    ]
    var output = [UInt8](repeating: 0, count: source.count)
    source.withUnsafeMutableBytes { sourceBytes in
        output.withUnsafeMutableBytes { outputBytes in
            var input = vImage_Buffer(
                data: sourceBytes.baseAddress,
                height: 2,
                width: 2,
                rowBytes: 8
            )
            var destination = vImage_Buffer(
                data: outputBytes.baseAddress,
                height: 2,
                width: 2,
                rowBytes: 8
            )
            let evenKernel = vImageBoxConvolve_ARGB8888(
                &input, &destination, nil, 0, 0, 2, 2, nil, vImage_Flags(kvImageEdgeExtend)
            )
            precondition(evenKernel == kvImageInvalidKernelSize)
            let noEdge = vImageBoxConvolve_ARGB8888(
                &input, &destination, nil, 0, 0, 3, 3, nil, vImage_Flags(kvImageNoFlags)
            )
            precondition(noEdge == kvImageInvalidEdgeStyle)
            var tinyDest = vImage_Buffer(
                data: outputBytes.baseAddress,
                height: 2,
                width: 2,
                rowBytes: 8
            )
            let roi = vImageBoxConvolve_ARGB8888(
                &input, &tinyDest, nil, 1, 0, 3, 3, nil, vImage_Flags(kvImageEdgeExtend)
            )
            precondition(roi == kvImageBufferSizeMismatch)
        }
    }
    precondition(kvImageNullPointerArgument == -21772)
    precondition(kvImageLeaveAlphaUnchanged == 1)
}

func testVDSPAddDotSum() {
    let a: [Float] = [1, 2, 3, 4]
    let b: [Float] = [10, 20, 30, 40]
    var summed = [Float](repeating: 0, count: 4)
    vDSP.add(a, b, result: &summed)
    precondition(summed == [11, 22, 33, 44])
    precondition(vDSP.add(a, b) == [11, 22, 33, 44])
    precondition(vDSP.dot(a, b) == 300)
    precondition(vDSP.sum(a) == 10)
}

func testVForceExpSqrt() {
    let input: [Float] = [0, 1, 4]
    var expOut = [Float](repeating: 0, count: 3)
    vForce.exp(input, result: &expOut)
    precondition(abs(expOut[0] - 1) < 0.0001)
    precondition(abs(expOut[1] - Foundation.exp(Float(1))) < 0.0001)
    var sqrtOut = [Float](repeating: 0, count: 3)
    vForce.sqrt(input, result: &sqrtOut)
    precondition(sqrtOut[0] == 0)
    precondition(sqrtOut[2] == 2)
}

func testBLASSaxpySdot() {
    var n: Int32 = 3
    var a: Float = 2
    var x: [Float] = [1, 2, 3]
    var y: [Float] = [10, 20, 30]
    var incx: Int32 = 1
    var incy: Int32 = 1
    let axpy = saxpy_(&n, &a, &x, &incx, &y, &incy)
    precondition(axpy == 0)
    precondition(y == [12, 24, 36])
    var x2: [Float] = [1, 2, 3]
    var y2: [Float] = [4, 5, 6]
    var incx2: Int32 = 1
    var incy2: Int32 = 1
    let product = sdot_(&n, &x2, &incx2, &y2, &incy2)
    precondition(product == 32)
}

func testBLASThreading() {
    precondition(BLAS_THREADING_MULTI_THREADED.rawValue == 0)
    precondition(BLAS_THREADING_SINGLE_THREADED.rawValue == 1)
    precondition(BLAS_THREADING_MAX_OPTIONS.rawValue == 2)
    let previous = BLASGetThreading()
    let ok = BLASSetThreading(BLAS_THREADING_SINGLE_THREADED)
    precondition(ok == 0)
    precondition(BLASGetThreading() == BLAS_THREADING_SINGLE_THREADED)
    let rejected = BLASSetThreading(BLAS_THREADING_MAX_OPTIONS)
    precondition(rejected == -1)
    _ = BLASSetThreading(previous)
}

func testCBLASOrderValues() {
    precondition(CblasRowMajor.rawValue == 101)
    precondition(CblasColMajor.rawValue == 102)
    precondition(CblasNoTrans.rawValue == 111)
}

func testBNNSFilterCreateFailClosed() {
    var params = BNNSLayerParametersActivation()
    let filter = BNNSFilterCreateLayerActivation(&params, nil)
    precondition(filter == nil)
}

import Accelerate
import Foundation

func testVDSPUnaryTransforms() {
    let a: [Float] = [1, -2, 3, -4]
    var out = [Float](repeating: 0, count: 4)
    vDSP.negative(a, result: &out)
    precondition(vDSP.negative(a) == [-1, 2, -3, 4])
    vDSP.square(a, result: &out)
    precondition(vDSP.square(a) == [1, 4, 9, 16])
    vDSP.signedSquare(a, result: &out)
    _ = vDSP.signedSquare(a)
    vDSP.negativeAbsolute(a, result: &out)
    _ = vDSP.negativeAbsolute(a)
    vDSP.trunc(a, result: &out)
    _ = vDSP.trunc(a)
    vDSP.invertedClip(a, to: -1...2, result: &out)
    _ = vDSP.invertedClip(a, to: -1...2)
    _ = vDSP.limit(a, limit: 2, withOutputLimitedTo: 9)
    vDSP.limit(a, limit: 2, withOutputLimitedTo: 9, result: &out)
    vDSP.threshold(a, to: 0, with: .clampToThreshold, result: &out)
    _ = vDSP.threshold(a, to: 0, with: .clampToThreshold)
    vDSP.threshold(a, to: 0, with: .zeroFill, result: &out)
    vDSP.threshold(a, to: 0, with: .signedConstant(5), result: &out)
    var a2 = a
    var b2: [Float] = [10, 20, 30, 40]
    vDSP.swapElements(&a2, &b2)
    vDSP.hypot(a, b2, result: &out)
    _ = vDSP.hypot(a, b2)
    _ = vDSP.distanceSquared(a, b2)
    _ = vDSP.countZeroCrossings(a)
    _ = vDSP.indexOfMaximumMagnitude(a)
    var ramp = [Float](repeating: 0, count: 4)
    vDSP.formRamp(withInitialValue: 1, increment: 2, result: &ramp)
    var start: Float = 0
    _ = vDSP.ramp(withInitialValue: &start, multiplyingBy: a, increment: 1)
    vDSP.gather(a, indices: [Float]([0, 2, 1, 3]), result: &out)
    vDSP.evaluatePolynomial(usingCoefficients: [1, 0, 0], withVariables: a, result: &out)
    _ = vDSP.evaluatePolynomial(usingCoefficients: [1, 0], withVariables: a)
    _ = vDSP.powerToDecibels(a.map { abs($0) }, zeroReference: 1)
    _ = vDSP.amplitudeToDecibels(a, zeroReference: 1)
    var norm = [Float](repeating: 0, count: 4)
    _ = vDSP.normalize(a, result: &norm)
    vDSP.integrate(a, using: .runningSum, result: &out)
    vDSP.integrate(a, using: .trapezoidal, result: &out)
    vDSP.integrate(a, using: .simpson, result: &out)
    var filt = [Float](repeating: 0, count: 4)
    vDSP.slidingWindowSum(a, usingWindowLength: 2, result: &filt)
    _ = vDSP.slidingWindowSum(a, usingWindowLength: 2)
    vDSP.downsample(a, decimationFactor: 2, filter: [Float]([1]), result: &out)
    _ = vDSP.downsample(a, decimationFactor: 2, filter: [Float]([1]))
    _ = vDSP.linearInterpolate(a, b2, using: 0.5)
    vDSP.linearInterpolate(a, b2, using: 0.5, result: &out)
    vDSP.correlate(a, withKernel: [Float]([1, 0]), result: &out)
    _ = vDSP.correlate(a, withKernel: [Float]([1]))
    vDSP.convolve(a, rowCount: 2, columnCount: 2, withKernel: [Float]([1, 0, 0, 0]), kernelRowCount: 2, kernelColumnCount: 2, result: &out)
    _ = vDSP.convolve(a, rowCount: 2, columnCount: 2, withKernel: [Float]([1, 0, 0, 0]), kernelRowCount: 2, kernelColumnCount: 2)
    vDSP.convolve(a, rowCount: 2, columnCount: 2, with3x3Kernel: [Float](repeating: 1, count: 9), result: &out)
    _ = vDSP.convolve(a, rowCount: 2, columnCount: 2, with3x3Kernel: [Float](repeating: 1, count: 9))
    vDSP.convolve(a, rowCount: 2, columnCount: 2, with5x5Kernel: [Float](repeating: 1, count: 25), result: &out)
    _ = vDSP.convolve(a, rowCount: 2, columnCount: 2, with5x5Kernel: [Float](repeating: 1, count: 25))
    vDSP.add(multiplication: (a: a, b: Float(2)), a, result: &out)
    _ = vDSP.add(multiplication: (a: a, b: Float(2)), a)
    vDSP.add(multiplication: (a: a, b: Float(2)), Float(1), result: &out)
    _ = vDSP.add(multiplication: (a: a, b: Float(2)), Float(1))
    vDSP.add(multiplication: (a: a, b: Float(1)), multiplication: (c: b2, d: Float(1)), result: &out)
    _ = vDSP.add(multiplication: (a: a, b: Float(1)), multiplication: (c: b2, d: Float(1)))
}

func testVDSPUnaryTransformsDouble() {
    let a: [Double] = [1, -2, 3, -4]
    var out = [Double](repeating: 0, count: 4)
    vDSP.negative(a, result: &out)
    _ = vDSP.negative(a)
    vDSP.square(a, result: &out)
    _ = vDSP.square(a)
    vDSP.signedSquare(a, result: &out)
    _ = vDSP.signedSquare(a)
    vDSP.negativeAbsolute(a, result: &out)
    _ = vDSP.negativeAbsolute(a)
    vDSP.trunc(a, result: &out)
    _ = vDSP.trunc(a)
    vDSP.invertedClip(a, to: -1...2, result: &out)
    _ = vDSP.invertedClip(a, to: -1...2)
    vDSP.limit(a, limit: 2, withOutputLimitedTo: 9, result: &out)
    _ = vDSP.limit(a, limit: 2, withOutputLimitedTo: 9)
    vDSP.threshold(a, to: 0, with: .clampToThreshold, result: &out)
    _ = vDSP.threshold(a, to: 0, with: .zeroFill)
    var a2 = a
    var b2: [Double] = [10, 20, 30, 40]
    vDSP.swapElements(&a2, &b2)
    vDSP.hypot(a, b2, result: &out)
    _ = vDSP.hypot(a, b2)
    _ = vDSP.distanceSquared(a, b2)
    _ = vDSP.countZeroCrossings(a)
    _ = vDSP.indexOfMaximumMagnitude(a)
    var ramp = [Double](repeating: 0, count: 4)
    vDSP.formRamp(withInitialValue: 1, increment: 2, result: &ramp)
    var start: Double = 0
    _ = vDSP.ramp(withInitialValue: &start, multiplyingBy: a, increment: 1)
    vDSP.gather(a, indices: [Double]([0, 2, 1, 3]), result: &out)
    vDSP.evaluatePolynomial(usingCoefficients: [Double]([1, 0, 0]), withVariables: a, result: &out)
    _ = vDSP.evaluatePolynomial(usingCoefficients: [Double]([1, 0]), withVariables: a)
    _ = vDSP.powerToDecibels(a.map { abs($0) }, zeroReference: 1)
    _ = vDSP.amplitudeToDecibels(a, zeroReference: 1)
    var norm = [Double](repeating: 0, count: 4)
    _ = vDSP.normalize(a, result: &norm)
    vDSP.integrate(a, using: .runningSum, result: &out)
    var filt = [Double](repeating: 0, count: 4)
    vDSP.slidingWindowSum(a, usingWindowLength: 2, result: &filt)
    _ = vDSP.slidingWindowSum(a, usingWindowLength: 2)
    vDSP.downsample(a, decimationFactor: 2, filter: [Double]([1]), result: &out)
    _ = vDSP.downsample(a, decimationFactor: 2, filter: [Double]([1]))
    _ = vDSP.linearInterpolate(a, b2, using: 0.5)
    vDSP.linearInterpolate(a, b2, using: 0.5, result: &out)
    vDSP.correlate(a, withKernel: [Double]([1, 0]), result: &out)
    _ = vDSP.correlate(a, withKernel: [Double]([1]))
    vDSP.convolve(a, rowCount: 2, columnCount: 2, withKernel: [Double]([1, 0, 0, 0]), kernelRowCount: 2, kernelColumnCount: 2, result: &out)
    _ = vDSP.convolve(a, rowCount: 2, columnCount: 2, withKernel: [Double]([1, 0, 0, 0]), kernelRowCount: 2, kernelColumnCount: 2)
    vDSP.convolve(a, rowCount: 2, columnCount: 2, with3x3Kernel: [Double](repeating: 1, count: 9), result: &out)
    _ = vDSP.convolve(a, rowCount: 2, columnCount: 2, with3x3Kernel: [Double](repeating: 1, count: 9))
    vDSP.convolve(a, rowCount: 2, columnCount: 2, with5x5Kernel: [Double](repeating: 1, count: 25), result: &out)
    _ = vDSP.convolve(a, rowCount: 2, columnCount: 2, with5x5Kernel: [Double](repeating: 1, count: 25))
    vDSP.add(multiplication: (a: a, b: Double(2)), a, result: &out)
    _ = vDSP.add(multiplication: (a: a, b: Double(2)), a)
    vDSP.addSubtract(a, b2, addResult: &out, subtractResult: &norm)
    vDSP.multiply(addition: (a: a, b: b2), Double(2), result: &out)
    _ = vDSP.multiply(addition: (a: a, b: b2), Double(2))
    vDSP.multiply(subtraction: (a: b2, b: a), Double(1), result: &out)
    _ = vDSP.multiply(subtraction: (a: b2, b: a), Double(1))
    vDSP.fill(&out, with: 3)
    vDSP.clear(&out)
}

func testVDSPConvertElementsAll() {
    var f = [Float](repeating: 0, count: 2)
    var d = [Double](repeating: 0, count: 2)
    var i8 = [Int8](repeating: 0, count: 2)
    var i16 = [Int16](repeating: 0, count: 2)
    var i32 = [Int32](repeating: 0, count: 2)
    var u8 = [UInt8](repeating: 0, count: 2)
    var u16 = [UInt16](repeating: 0, count: 2)
    var u32 = [UInt32](repeating: 0, count: 2)
    let srcF: [Float] = [1.2, 2.8]
    let srcD: [Double] = [1.2, 2.8]
    vDSP.convertElements(of: srcF, to: &f)
    vDSP.convertElements(of: srcD, to: &d)
    vDSP.convertElements(of: srcD, to: &f)
    vDSP.convertElements(of: srcF, to: &d)
    vDSP.convertElements(of: [Int8]([1, 2]), to: &f)
    vDSP.convertElements(of: srcF, to: &i8, rounding: .towardZero)
    vDSP.convertElements(of: [Int8]([1, 2]), to: &d)
    vDSP.convertElements(of: srcD, to: &i8, rounding: .towardNearestInteger)
    vDSP.convertElements(of: [Int16]([1, 2]), to: &f)
    vDSP.convertElements(of: srcF, to: &i16, rounding: .towardZero)
    vDSP.convertElements(of: [Int16]([1, 2]), to: &d)
    vDSP.convertElements(of: srcD, to: &i16, rounding: .towardNearestInteger)
    vDSP.convertElements(of: [Int32]([1, 2]), to: &f)
    vDSP.convertElements(of: srcF, to: &i32, rounding: .towardZero)
    vDSP.convertElements(of: [Int32]([1, 2]), to: &d)
    vDSP.convertElements(of: srcD, to: &i32, rounding: .towardNearestInteger)
    vDSP.convertElements(of: [UInt8]([1, 2]), to: &f)
    vDSP.convertElements(of: srcF, to: &u8, rounding: .towardZero)
    vDSP.convertElements(of: [UInt8]([1, 2]), to: &d)
    vDSP.convertElements(of: srcD, to: &u8, rounding: .towardNearestInteger)
    vDSP.convertElements(of: [UInt16]([1, 2]), to: &f)
    vDSP.convertElements(of: srcF, to: &u16, rounding: .towardZero)
    vDSP.convertElements(of: [UInt16]([1, 2]), to: &d)
    vDSP.convertElements(of: srcD, to: &u16, rounding: .towardNearestInteger)
    vDSP.convertElements(of: [UInt32]([1, 2]), to: &f)
    vDSP.convertElements(of: srcF, to: &u32, rounding: .towardZero)
    vDSP.convertElements(of: [UInt32]([1, 2]), to: &d)
    vDSP.convertElements(of: srcD, to: &u32, rounding: .towardNearestInteger)
    _ = vDSP.floatToDouble(srcF)
    _ = vDSP.doubleToFloat(srcD)
}

func testVDSPSplitComplexOps() {
    var real: [Float] = [1, 0, 0, 1]
    var imag: [Float] = [0, 1, 0, 0]
    var mag = [Float](repeating: 0, count: 4)
    var phase = [Float](repeating: 0, count: 4)
    real.withUnsafeMutableBufferPointer { rp in
        imag.withUnsafeMutableBufferPointer { ip in
            var sc = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
            vDSP.squareMagnitudes(sc, result: &mag)
            vDSP.phase(sc, result: &phase)
            var rr = [Float](repeating: 0, count: 4)
            var ii = [Float](repeating: 0, count: 4)
            rr.withUnsafeMutableBufferPointer { rrp in
                ii.withUnsafeMutableBufferPointer { iip in
                    var dest = DSPSplitComplex(realp: rrp.baseAddress!, imagp: iip.baseAddress!)
                    vDSP.multiply(sc, by: sc, count: 4, useConjugate: false, result: &dest)
                }
            }
            vDSP.conjugate(&sc, count: 4)
        }
    }
    var dreal: [Double] = [1, 0, 0, 1]
    var dimag: [Double] = [0, 1, 0, 0]
    var dmag = [Double](repeating: 0, count: 4)
    var dphase = [Double](repeating: 0, count: 4)
    dreal.withUnsafeMutableBufferPointer { rp in
        dimag.withUnsafeMutableBufferPointer { ip in
            var sc = DSPDoubleSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
            vDSP.squareMagnitudes(sc, result: &dmag)
            vDSP.phase(sc, result: &dphase)
            var rr = [Double](repeating: 0, count: 4)
            var ii = [Double](repeating: 0, count: 4)
            rr.withUnsafeMutableBufferPointer { rrp in
                ii.withUnsafeMutableBufferPointer { iip in
                    var dest = DSPDoubleSplitComplex(realp: rrp.baseAddress!, imagp: iip.baseAddress!)
                    vDSP.multiply(sc, by: sc, count: 4, useConjugate: true, result: &dest)
                }
            }
            vDSP.conjugate(&sc, count: 4)
        }
    }
    var start: Float = 0
    var left = [Float](repeating: 0, count: 2)
    var right = [Float](repeating: 0, count: 2)
    vDSP.formStereoRamp(
        withInitialValue: &start,
        multiplyingBy: [Float]([1, 1]),
        [Float]([1, 1]),
        increment: 1,
        results: &left,
        &right
    )
    var dstart: Double = 0
    var dleft = [Double](repeating: 0, count: 2)
    var dright = [Double](repeating: 0, count: 2)
    vDSP.formStereoRamp(
        withInitialValue: &dstart,
        multiplyingBy: [Double]([1, 1]),
        [Double]([1, 1]),
        increment: 1,
        results: &dleft,
        &dright
    )
}

func testCBLASDaxpySgemm() {
    var y: [Double] = [0, 0, 0]
    cblas_daxpy(3, 2, [Double]([1, 2, 3]), 1, &y, 1)
    precondition(y == [2, 4, 6])
    var c = [Float](repeating: 0, count: 4)
    cblas_sgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 2, 2, 2, 1, [Float]([1, 0, 0, 1]), 2, [Float]([1, 2, 3, 4]), 2, 0, &c, 2)
    var dc = [Double](repeating: 0, count: 4)
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 2, 2, 2, 1, [Double]([1, 0, 0, 1]), 2, [Double]([1, 2, 3, 4]), 2, 0, &dc, 2)
}

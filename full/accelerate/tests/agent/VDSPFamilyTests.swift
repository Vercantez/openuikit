import Accelerate
import Foundation

func testVDSPArithmeticFloat() {
    let a: [Float] = [1, 2, 3, 4]
    let b: [Float] = [10, 20, 30, 40]
    var out = [Float](repeating: 0, count: 4)
    vDSP.add(a, b, result: &out)
    precondition(out == [11, 22, 33, 44])
    precondition(vDSP.add(a, b) == [11, 22, 33, 44])
    vDSP.add(Float(2), a, result: &out)
    precondition(vDSP.add(Float(2), a) == [3, 4, 5, 6])
    vDSP.subtract(a, b, result: &out)
    _ = vDSP.subtract(a, b)
    vDSP.multiply(a, b, result: &out)
    precondition(vDSP.multiply(a, b) == [10, 40, 90, 160])
    vDSP.multiply(Float(2), a, result: &out)
    _ = vDSP.multiply(Float(2), a)
    vDSP.divide(b, a, result: &out)
    _ = vDSP.divide(b, a)
    var addOut = [Float](repeating: 0, count: 4)
    var subOut = [Float](repeating: 0, count: 4)
    vDSP.addSubtract(a, b, addResult: &addOut, subtractResult: &subOut)
    vDSP.multiply(addition: (a: a, b: b), Float(2), result: &out)
    _ = vDSP.multiply(addition: (a: a, b: b), Float(2))
    vDSP.multiply(subtraction: (a: b, b: a), Float(1), result: &out)
    _ = vDSP.multiply(subtraction: (a: b, b: a), Float(1))
    vDSP.absolute(a, result: &out)
    _ = vDSP.absolute([-1, 2, -3] as [Float])
    vDSP.fill(&out, with: Float(7))
    vDSP.clear(&out)
    var rev = a
    vDSP.reverse(&rev)
    precondition(rev == [4, 3, 2, 1])
    vDSP.clip(a, to: 2...3, result: &out)
    _ = vDSP.clip(a, to: 2...3)
    precondition(vDSP.dot(a, b) == 300)
}

func testVDSPArithmeticDouble() {
    let a: [Double] = [1, 2, 3, 4]
    let b: [Double] = [10, 20, 30, 40]
    var out = [Double](repeating: 0, count: 4)
    vDSP.add(a, b, result: &out)
    precondition(vDSP.add(a, b) == [11, 22, 33, 44])
    vDSP.add(Double(2), a, result: &out)
    _ = vDSP.add(Double(2), a)
    vDSP.subtract(a, b, result: &out)
    _ = vDSP.subtract(a, b)
    vDSP.multiply(a, b, result: &out)
    _ = vDSP.multiply(a, b)
    vDSP.multiply(Double(2), a, result: &out)
    _ = vDSP.multiply(Double(2), a)
    vDSP.divide(b, a, result: &out)
    _ = vDSP.divide(b, a)
    vDSP.absolute(a, result: &out)
    _ = vDSP.absolute(a)
    vDSP.fill(&out, with: 7)
    vDSP.clear(&out)
    var rev = a
    vDSP.reverse(&rev)
    vDSP.clip(a, to: 2...3, result: &out)
    _ = vDSP.clip(a, to: 2...3)
    precondition(vDSP.dot(a, b) == 300)
}

func testVDSPStats() {
    let a: [Float] = [1, 2, 3, 4]
    precondition(vDSP.sum(a) == 10)
    precondition(vDSP.mean(a) == 2.5)
    precondition(vDSP.meanSquare(a) == 7.5)
    precondition(vDSP.meanMagnitude(a) == 2.5)
    precondition(vDSP.sumOfSquares(a) == 30)
    precondition(vDSP.sumOfMagnitudes(a) == 10)
    let pair = vDSP.sumAndSumOfSquares(a)
    precondition(pair.elementsSum == 10)
    precondition(vDSP.rootMeanSquare(a) > 0)
    _ = vDSP.maximum(a)
    _ = vDSP.minimum(a)
    _ = vDSP.indexOfMaximum(a)
    _ = vDSP.indexOfMinimum(a)
    _ = vDSP.maximumMagnitude(a)
    _ = vDSP.standardDeviation(a)
    let d: [Double] = [1, 2, 3, 4]
    precondition(vDSP.sum(d) == 10)
    precondition(vDSP.mean(d) == 2.5)
    _ = vDSP.meanSquare(d)
    _ = vDSP.meanMagnitude(d)
    _ = vDSP.sumOfSquares(d)
    _ = vDSP.sumOfMagnitudes(d)
    _ = vDSP.sumAndSumOfSquares(d)
    _ = vDSP.rootMeanSquare(d)
    _ = vDSP.maximum(d)
    _ = vDSP.minimum(d)
    _ = vDSP.indexOfMaximum(d)
    _ = vDSP.indexOfMinimum(d)
    _ = vDSP.maximumMagnitude(d)
    _ = vDSP.standardDeviation(d)
}

func testVDSPWindowConvolve() {
    var window = [Float](repeating: 0, count: 8)
    vDSP.formWindow(usingSequence: .hamming, result: &window, isHalfWindow: false)
    _ = vDSP.window(ofType: Float.self, usingSequence: .hanningNormalized, count: 8, isHalfWindow: false)
    vDSP.formWindow(usingSequence: .blackman, result: &window, isHalfWindow: false)
    vDSP.formWindow(usingSequence: .hanningDenormalized, result: &window, isHalfWindow: false)
    var dwindow = [Double](repeating: 0, count: 8)
    vDSP.formWindow(usingSequence: .hamming, result: &dwindow, isHalfWindow: false)
    let kernel: [Float] = [1, 0, 0]
    let vector: [Float] = [1, 2, 3, 4]
    var conv = [Float](repeating: 0, count: 4)
    vDSP.convolve(vector, withKernel: kernel, result: &conv)
    _ = vDSP.convolve(vector, withKernel: kernel)
    var sorted: [Float] = [3, 1, 2]
    vDSP.sort(&sorted, order: .ascending)
    precondition(sorted[0] <= sorted[2])
    var dsorted: [Double] = [3, 1, 2]
    vDSP.sort(&dsorted, order: .descending)
}

func testVDSPConvertCopy() {
    let ints: [Int8] = [1, 2, 3]
    let f: [Float] = vDSP.integerToFloatingPoint(ints, floatingPointType: Float.self)
    precondition(f == [1, 2, 3])
    _ = vDSP.integerToFloatingPoint([Int16]([1, 2]), floatingPointType: Float.self)
    _ = vDSP.integerToFloatingPoint([Int32]([1, 2]), floatingPointType: Double.self)
    _ = vDSP.integerToFloatingPoint([UInt8]([1, 2]), floatingPointType: Float.self)
    _ = vDSP.integerToFloatingPoint([UInt16]([1, 2]), floatingPointType: Float.self)
    _ = vDSP.integerToFloatingPoint([UInt32]([1, 2]), floatingPointType: Double.self)
    let back: [Int32] = vDSP.floatingPointToInteger([1.2, 2.8] as [Float], integerType: Int32.self, rounding: .towardZero)
    precondition(back[0] == 1)
    _ = vDSP.floatingPointToInteger([1.2, 2.8] as [Double], integerType: Int32.self, rounding: .towardNearestInteger)
    var dest = [Float](repeating: 0, count: 3)
    vDSP.convertElements(of: [UInt8]([1, 2, 3]), to: &dest)
    _ = vDSP.copy([Float]([1, 2, 3]))
    _ = vDSP.copy([Double]([1, 2, 3]))
    _ = vDSP.float16ToFloat([Float16]([1, 2, 3]))
    _ = vDSP.floatToFloat16([Float]([1, 2, 3]))
    _ = vDSP.taperedMerge([Float]([0, 0, 0]), [Float]([1, 1, 1]))
    var merge = [Float](repeating: 0, count: 3)
    vDSP.taperedMerge([Float]([0, 0, 0]), [Float]([1, 1, 1]), result: &merge)
    var dmerge = [Double](repeating: 0, count: 3)
    vDSP.taperedMerge([Double]([0, 0, 0]), [Double]([1, 1, 1]), result: &dmerge)
    _ = vDSP.taperedMerge([Double]([0, 0, 0]), [Double]([1, 1, 1]))
    _ = vDSP.compress([Float]([1, 2, 3]), gatingVector: [Float]([0, 1, 1]), threshold: 0.5)
    var cdest = [Float](repeating: 0, count: 3)
    vDSP.compress([Float]([1, 2, 3]), gatingVector: [Float]([0, 1, 1]), threshold: Float(0.5), result: &cdest)
    _ = vDSP.compress([Double]([1, 2, 3]), gatingVector: [Double]([0, 1, 1]), threshold: 0.5)
    var dcdest = [Double](repeating: 0, count: 3)
    vDSP.compress([Double]([1, 2, 3]), gatingVector: [Double]([0, 1, 1]), threshold: 0.5, result: &dcdest)
    _ = vDSP.polarToRectangular([Float]([1, 1, 0, Float.pi / 2]))
    _ = vDSP.rectangularToPolar([Float]([1, 0, 0, 1]))
    _ = vDSP.polarToRectangular([Double]([1, 1, 0, Double.pi / 2]))
    _ = vDSP.rectangularToPolar([Double]([1, 0, 0, 1]))
    _ = vDSP.twoPoleTwoZeroFilter([Float]([1, 0, 0, 0]), coefficients: (1, 0, 0, 0, 0))
    var filt = [Float](repeating: 0, count: 4)
    vDSP.twoPoleTwoZeroFilter([Float]([1, 0, 0, 0]), coefficients: (1, 0, 0, 0, 0), result: &filt)
    _ = vDSP.twoPoleTwoZeroFilter([Double]([1, 0, 0, 0]), coefficients: (1, 0, 0, 0, 0))
    var dfilt = [Double](repeating: 0, count: 4)
    vDSP.twoPoleTwoZeroFilter([Double]([1, 0, 0, 0]), coefficients: (1, 0, 0, 0, 0), result: &dfilt)
    var start: Float = 0
    _ = vDSP.stereoRamp(withInitialValue: &start, multiplyingBy: [Float]([1, 1]), [Float]([2, 2]), increment: 1)
    var dstart: Double = 0
    _ = vDSP.stereoRamp(withInitialValue: &dstart, multiplyingBy: [Double]([1, 1]), [Double]([2, 2]), increment: 1)
}

func testVDSPFFT() {
    precondition(vDSP.Radix.radix2.fftRadix == FFTRadix(FFT_RADIX2))
    precondition(vDSP.FourierTransformDirection.forward.fftDirection == FFTDirection(FFT_FORWARD))
    precondition(vDSP.FourierTransformDirection.inverse.fftDirection == FFTDirection(FFT_INVERSE))
    precondition(vDSP.DCTTransformType.II.dctType == .II)
    precondition(vDSP.DCTTransformType.III.dctType == .III)
    precondition(vDSP.DCTTransformType.IV.dctType == .IV)
    let setup = vDSP.FFT<DSPSplitComplex>(log2n: 3, radix: .radix2, ofType: DSPSplitComplex.self)
    precondition(setup != nil)
    var real: [Float] = [1, 0, 0, 0, 0, 0, 0, 0]
    var imag = [Float](repeating: 0, count: 8)
    var outR = [Float](repeating: 0, count: 8)
    var outI = [Float](repeating: 0, count: 8)
    real.withUnsafeMutableBufferPointer { rp in
        imag.withUnsafeMutableBufferPointer { ip in
            outR.withUnsafeMutableBufferPointer { orp in
                outI.withUnsafeMutableBufferPointer { oip in
                    var src = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                    var dest = DSPSplitComplex(realp: orp.baseAddress!, imagp: oip.baseAddress!)
                    setup!.forward(input: src, output: &dest)
                    setup!.inverse(input: dest, output: &src)
                    setup!.transform(input: src, output: &dest, direction: .forward)
                }
            }
        }
    }
    var dftReal = [Float](repeating: 0, count: 8)
    var dftImag = [Float](repeating: 0, count: 8)
    let impulse: [Float] = [1, 0, 0, 0, 0, 0, 0, 0]
    let zeros = [Float](repeating: 0, count: 8)
    for k in 0..<8 {
        var sumR: Float = 0
        var sumI: Float = 0
        for t in 0..<8 {
            let angle = -2 * Float.pi * Float(k * t) / 8
            sumR += impulse[t] * Foundation.cos(angle) - zeros[t] * Foundation.sin(angle)
            sumI += impulse[t] * Foundation.sin(angle) + zeros[t] * Foundation.cos(angle)
        }
        dftReal[k] = sumR
        dftImag[k] = sumI
    }
    precondition(abs(dftReal[0] - 1) < 0.0001)
    if let fftSetup = vDSP_SplitComplexFloat.makeFFTSetup(log2n: 3, radix: .radix2) {
        vDSP_SplitComplexFloat.destroySetup(fftSetup)
    }
    if let dft = try? vDSP.DFTSinglePrecisionInterleavedFunctions.makeDiscreteFourierTransform(
        count: 8, direction: .forward, transformType: .complexComplex
    ) {
        vDSP.DFTSinglePrecisionInterleavedFunctions.destroySetup(dft)
    }
    if let interleaved = vDSP_DFT_Interleaved_CreateSetup(nil, 8, .FORWARD, .interleaved_ComplextoComplex) {
        var iri = [DSPComplex](repeating: DSPComplex(real: 0, imag: 0), count: 8)
        iri[0] = DSPComplex(real: 1, imag: 0)
        var ori = [DSPComplex](repeating: DSPComplex(), count: 8)
        vDSP_DFT_Interleaved_Execute(interleaved, iri, &ori)
        vDSP_DFT_Interleaved_DestroySetup(interleaved)
        precondition(abs(ori[0].real - 1) < 0.001)
    }
    _ = vDSP.VectorizableFloat.makeBiquadSetup(channelCount: 1, coefficients: [1, 0, 0, 0, 0], sectionCount: 1)
    _ = vDSP.FFT2D<DSPSplitComplex>(width: 4, height: 4, ofType: DSPSplitComplex.self)
    if let dftObj = try? vDSP.DiscreteFourierTransform<Float>(
        previousDFT: nil, count: 8, direction: .forward, transformType: .complexComplex, ofType: Float.self
    ) {
        let impulseF: [Float] = [1, 0, 0, 0, 0, 0, 0, 0]
        let zerosF = [Float](repeating: 0, count: 8)
        let split = dftObj.transform(real: impulseF, imaginary: zerosF)
        precondition(abs(split.real[0] - 1) < 0.001)
        var outReal = [Float](repeating: 0, count: 8)
        var outImag = [Float](repeating: 0, count: 8)
        dftObj.transform(inputReal: impulseF, inputImaginary: zerosF, outputReal: &outReal, outputImaginary: &outImag)
    }
    if let dftD = try? vDSP.DiscreteFourierTransform<Double>(
        previous: nil, count: 8, direction: .forward, transformType: .complexComplex, ofType: Double.self
    ) {
        let impulseD: [Double] = [1, 0, 0, 0, 0, 0, 0, 0]
        let zerosD = [Double](repeating: 0, count: 8)
        _ = dftD.transform(real: impulseD, imaginary: zerosD)
    }
    if let dftC = try? vDSP.DiscreteFourierTransform<DSPComplex>(
        previousDFT: nil, count: 8, direction: .forward, transformType: .complexComplex, ofType: DSPComplex.self
    ) {
        var interleavedIn = [DSPComplex](repeating: DSPComplex(), count: 8)
        interleavedIn[0] = DSPComplex(real: 1, imag: 0)
        var interleavedOut = [DSPComplex](repeating: DSPComplex(), count: 8)
        dftC.transform(input: interleavedIn, output: &interleavedOut)
        _ = dftC.transform(input: interleavedIn)
    }
    if let dftDC = try? vDSP.DiscreteFourierTransform<DSPDoubleComplex>(
        previousDFT: nil, count: 8, direction: .forward, transformType: .complexComplex, ofType: DSPDoubleComplex.self
    ) {
        var interleavedIn = [DSPDoubleComplex](repeating: DSPDoubleComplex(), count: 8)
        interleavedIn[0] = DSPDoubleComplex(real: 1, imag: 0)
        _ = dftDC.transform(input: interleavedIn)
    }
    if let fourier = vDSP.DFT<Float>(
        previous: nil, count: 8, direction: .forward, transformType: .complexComplex, ofType: Float.self
    ) {
        let impulseF: [Float] = [1, 0, 0, 0, 0, 0, 0, 0]
        let zerosF = [Float](repeating: 0, count: 8)
        var outReal = [Float](repeating: 0, count: 8)
        var outImag = [Float](repeating: 0, count: 8)
        fourier.transform(inputReal: impulseF, inputImaginary: zerosF, outputReal: &outReal, outputImaginary: &outImag)
        _ = fourier.transform(inputReal: impulseF, inputImaginary: zerosF)
    }
    if let dct = vDSP.DCT(previous: nil, count: 8, transformType: .II) {
        let impulseF: [Float] = [1, 0, 0, 0, 0, 0, 0, 0]
        var dctOut = [Float](repeating: 0, count: 8)
        dct.transform(impulseF, result: &dctOut)
        _ = dct.transform(impulseF)
    }
}

func testVDSPEnums() {
    _ = vDSP.RoundingMode.towardZero
    _ = vDSP.RoundingMode.towardNearestInteger
    _ = vDSP.ThresholdRule<Float>.clampToThreshold
    _ = vDSP.ThresholdRule<Float>.signedConstant(1)
    _ = vDSP.ThresholdRule<Float>.zeroFill
    _ = vDSP.WindowSequence.hanningNormalized
    _ = vDSP.WindowSequence.hanningDenormalized
    _ = vDSP.WindowSequence.hamming
    _ = vDSP.WindowSequence.blackman
    _ = vDSP.IntegrationRule.runningSum
    _ = vDSP.IntegrationRule.trapezoidal
    _ = vDSP.IntegrationRule.simpson
    _ = vDSP.DCTTransformType.II
    _ = vDSP.DCTTransformType.III
    _ = vDSP.DCTTransformType.IV
    _ = vDSP.DFTTransformType.complexReal
    _ = vDSP.DFTTransformType.complexComplex
    _ = vDSP.FourierTransformDirection.forward
    _ = vDSP.FourierTransformDirection.inverse
    _ = vDSP.Radix.radix2
    _ = vDSP.Radix.radix3
    _ = vDSP.Radix.radix5
    _ = vDSP.DFTError.invalidInterleavedCount(count: 3)
    _ = vDSP.DFTError.invalidSplitComplexCount(count: 3, transformType: .complexComplex)
    _ = vDSP.SortOrder.ascending
    _ = vDSP.SortOrder.descending
    precondition(vDSP.SortOrder.ascending.rawValue == 1)
    precondition(vDSP.DCTTransformType.allCases.count == 3)
}

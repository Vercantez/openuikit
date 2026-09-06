import Foundation

extension vDSP.VectorizableFloat {
    public static func makeDFTSetup<T>(
        previous: vDSP.DFT<T>? = nil,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType
    ) -> OpaquePointer? where T: vDSP_FloatingPointDiscreteFourierTransformable {
        _ = previous
        _ = direction
        _ = transformType
        guard count > 0, count & (count - 1) == 0, let box = _FFTSetupBox(log2n: count.trailingZeroBitCount) else { return nil }
        return _fftRetain(box)
    }

    public static func destroySetup(_ setup: OpaquePointer) {
        _fftRelease(setup)
    }

    public static func destroySetup(channelCount: UInt, biquadSetup: OpaquePointer) {
        _ = channelCount
        _biquadRelease(biquadSetup)
    }

    public static func makeBiquadSetup(channelCount: UInt, coefficients: [Double], sectionCount: UInt) -> OpaquePointer? {
        _ = channelCount
        guard let box = _BiquadSetupBox(coefficients: coefficients, sectionCount: Int(sectionCount)) else { return nil }
        return _biquadRetain(box)
    }

    public static func applyMulti(
        setup: vDSP_biquadm_SetupD,
        pInputs: UnsafeMutablePointer<UnsafePointer<vDSP.VectorizableFloat.Scalar>>,
        pOutputs: UnsafeMutablePointer<UnsafeMutablePointer<vDSP.VectorizableFloat.Scalar>>,
        count: vDSP_Length
    ) {
        guard let box = _biquadBox(setup) else { return }
        var delays = [Float](repeating: 0, count: max(2, box.sections * 2))
        delays.withUnsafeMutableBufferPointer { dp in
            _biquadApply(
                source: pInputs[0],
                destination: pOutputs[0],
                delays: dp.baseAddress!,
                box: box,
                count: Int(count)
            )
        }
    }

    public static func applySingle<U, V>(
        source: U,
        destination: inout V,
        delays: UnsafeMutablePointer<vDSP.VectorizableFloat.Scalar>,
        setup: vDSP_biquad_Setup,
        sectionCount: vDSP_Length,
        count: vDSP_Length
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        _ = sectionCount
        guard let box = _biquadBox(setup) else {
            _AccelerateNumeric.map(source, &destination) { $0 }
            return
        }
        source.withUnsafeBufferPointer { src in
            destination.withUnsafeMutableBufferPointer { dest in
                let n = min(Int(count), src.count, dest.count)
                guard let sp = src.baseAddress, let dp = dest.baseAddress else { return }
                _biquadApply(source: sp, destination: dp, delays: delays, box: box, count: n)
            }
        }
    }

    public static func transform<U, V>(
        dftSetup: OpaquePointer,
        inputReal: U,
        inputImaginary: U,
        outputReal: inout V,
        outputImaginary: inout V
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var real = [Float](repeating: 0, count: inputReal.count)
        var imag = [Float](repeating: 0, count: inputImaginary.count)
        inputReal.withUnsafeBufferPointer { src in
            for i in 0..<src.count { real[i] = src[i] }
        }
        inputImaginary.withUnsafeBufferPointer { src in
            for i in 0..<src.count { imag[i] = src[i] }
        }
        guard let box = Unmanaged<_FFTSetupBox>.fromOpaque(UnsafeRawPointer(dftSetup)).takeUnretainedValue() as _FFTSetupBox? else { return }
        let n = min(box.n, real.count)
        real.withUnsafeMutableBufferPointer { rp in
            imag.withUnsafeMutableBufferPointer { ip in
                _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: false)
            }
        }
        outputReal.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, n) { dest[i] = real[i] }
        }
        outputImaginary.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, n) { dest[i] = imag[i] }
        }
    }
}

extension vDSP.VectorizableDouble {
    public static func makeDFTSetup<T>(
        previous: vDSP.DFT<T>? = nil,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType
    ) -> OpaquePointer? where T: vDSP_FloatingPointDiscreteFourierTransformable {
        _ = previous
        _ = direction
        _ = transformType
        guard count > 0, count & (count - 1) == 0, let box = _FFTSetupBox(log2n: count.trailingZeroBitCount) else { return nil }
        return _fftRetain(box)
    }

    public static func destroySetup(_ setup: OpaquePointer) {
        _fftRelease(setup)
    }

    public static func destroySetup(channelCount: UInt, biquadSetup: OpaquePointer) {
        _ = channelCount
        _biquadRelease(biquadSetup)
    }

    public static func makeBiquadSetup(channelCount: vDSP_Length, coefficients: [Double], sectionCount: vDSP_Length) -> OpaquePointer? {
        _ = channelCount
        guard let box = _BiquadSetupBox(coefficients: coefficients, sectionCount: Int(sectionCount)) else { return nil }
        return _biquadRetain(box)
    }

    public static func applyMulti(
        setup: vDSP_biquadm_SetupD,
        pInputs: UnsafeMutablePointer<UnsafePointer<vDSP.VectorizableDouble.Scalar>>,
        pOutputs: UnsafeMutablePointer<UnsafeMutablePointer<vDSP.VectorizableDouble.Scalar>>,
        count: vDSP_Length
    ) {
        guard let box = _biquadBox(setup) else { return }
        var delays = [Double](repeating: 0, count: max(2, box.sections * 2))
        delays.withUnsafeMutableBufferPointer { dp in
            _biquadApply(
                source: pInputs[0],
                destination: pOutputs[0],
                delays: dp.baseAddress!,
                box: box,
                count: Int(count)
            )
        }
    }

    public static func applySingle<U, V>(
        source: U,
        destination: inout V,
        delays: UnsafeMutablePointer<vDSP.VectorizableDouble.Scalar>,
        setup: vDSP_biquad_Setup,
        sectionCount: vDSP_Length,
        count: vDSP_Length
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        _ = sectionCount
        guard let box = _biquadBox(setup) else {
            _AccelerateNumeric.map(source, &destination) { $0 }
            return
        }
        source.withUnsafeBufferPointer { src in
            destination.withUnsafeMutableBufferPointer { dest in
                let n = min(Int(count), src.count, dest.count)
                guard let sp = src.baseAddress, let dp = dest.baseAddress else { return }
                _biquadApply(source: sp, destination: dp, delays: delays, box: box, count: n)
            }
        }
    }

    public static func transform<U, V>(
        dftSetup: OpaquePointer,
        inputReal: U,
        inputImaginary: U,
        outputReal: inout V,
        outputImaginary: inout V
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        var real = [Double](repeating: 0, count: inputReal.count)
        var imag = [Double](repeating: 0, count: inputImaginary.count)
        inputReal.withUnsafeBufferPointer { src in
            for i in 0..<src.count { real[i] = src[i] }
        }
        inputImaginary.withUnsafeBufferPointer { src in
            for i in 0..<src.count { imag[i] = src[i] }
        }
        let box = Unmanaged<_FFTSetupBox>.fromOpaque(UnsafeRawPointer(dftSetup)).takeUnretainedValue()
        let n = min(box.n, real.count)
        real.withUnsafeMutableBufferPointer { rp in
            imag.withUnsafeMutableBufferPointer { ip in
                _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: false)
            }
        }
        outputReal.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, n) { dest[i] = real[i] }
        }
        outputImaginary.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, n) { dest[i] = imag[i] }
        }
    }
}

extension vDSP.DFTSinglePrecisionInterleavedFunctions {
    public static func destroySetup(_ setup: OpaquePointer) {
        _fftRelease(setup)
    }

    public static func makeDiscreteFourierTransform(
        previous: OpaquePointer? = nil,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType
    ) throws -> OpaquePointer {
        _ = previous
        _ = direction
        _ = transformType
        guard count > 0, count & (count - 1) == 0, let box = _FFTSetupBox(log2n: count.trailingZeroBitCount) else {
            throw vDSP.DFTError.invalidInterleavedCount(count: count)
        }
        return _fftRetain(box)
    }
}

extension vDSP.DFTDoublePrecisionInterleavedFunctions {
    public static func destroySetup(_ setup: OpaquePointer) {
        _fftRelease(setup)
    }

    public static func makeDiscreteFourierTransform(
        previous: OpaquePointer? = nil,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType
    ) throws -> OpaquePointer {
        _ = previous
        _ = direction
        _ = transformType
        guard count > 0, count & (count - 1) == 0, let box = _FFTSetupBox(log2n: count.trailingZeroBitCount) else {
            throw vDSP.DFTError.invalidInterleavedCount(count: count)
        }
        return _fftRetain(box)
    }
}

extension vDSP.DFTSinglePrecisionSplitComplexFunctions {
    public static func destroySetup(_ setup: OpaquePointer) {
        _fftRelease(setup)
    }

    public static func makeDiscreteFourierTransform(
        previous: OpaquePointer? = nil,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType
    ) throws -> OpaquePointer {
        _ = previous
        _ = direction
        _ = transformType
        guard count > 0, count & (count - 1) == 0, let box = _FFTSetupBox(log2n: count.trailingZeroBitCount) else {
            throw vDSP.DFTError.invalidSplitComplexCount(count: count, transformType: transformType)
        }
        return _fftRetain(box)
    }
}

extension vDSP.DFTDoublePrecisionSplitComplexFunctions {
    public static func destroySetup(_ setup: OpaquePointer) {
        _fftRelease(setup)
    }

    public static func makeDiscreteFourierTransform(
        previous: OpaquePointer? = nil,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType
    ) throws -> OpaquePointer {
        _ = previous
        _ = direction
        _ = transformType
        guard count > 0, count & (count - 1) == 0, let box = _FFTSetupBox(log2n: count.trailingZeroBitCount) else {
            throw vDSP.DFTError.invalidSplitComplexCount(count: count, transformType: transformType)
        }
        return _fftRetain(box)
    }
}

extension vDSP_DFTFunctions {
    public static func makeDFTSetup<T>(
        previous: vDSP.DFT<T>?,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType
    ) -> OpaquePointer? where T: vDSP_FloatingPointDiscreteFourierTransformable {
        _ = previous
        _ = direction
        _ = transformType
        guard count > 0, count & (count - 1) == 0, let box = _FFTSetupBox(log2n: count.trailingZeroBitCount) else {
            return nil
        }
        return _fftRetain(box)
    }

    public static func transform<U, V>(
        dftSetup: OpaquePointer,
        inputReal: U,
        inputImaginary: U,
        outputReal: inout V,
        outputImaginary: inout V
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == V.Element {
        _ = dftSetup
        _AccelerateNumeric.map(inputReal, &outputReal) { $0 }
        _AccelerateNumeric.map(inputImaginary, &outputImaginary) { $0 }
    }
}

import Foundation

final class _BiquadSetupBox {
    let sections: Int
    let coeffs: [Double]
    init?(coefficients: [Double], sectionCount: Int) {
        guard sectionCount > 0, coefficients.count >= sectionCount * 5 else { return nil }
        self.sections = sectionCount
        self.coeffs = Array(coefficients.prefix(sectionCount * 5))
    }
}

func _biquadRetain(_ box: _BiquadSetupBox) -> OpaquePointer {
    OpaquePointer(Unmanaged.passRetained(box).toOpaque())
}

func _biquadBox(_ setup: OpaquePointer?) -> _BiquadSetupBox? {
    guard let setup else { return nil }
    return Unmanaged<_BiquadSetupBox>.fromOpaque(UnsafeRawPointer(setup)).takeUnretainedValue()
}

func _biquadRelease(_ setup: OpaquePointer?) {
    guard let setup else { return }
    Unmanaged<_BiquadSetupBox>.fromOpaque(UnsafeRawPointer(setup)).release()
}

func _biquadApply<T: BinaryFloatingPoint>(
    source: UnsafePointer<T>,
    destination: UnsafeMutablePointer<T>,
    delays: UnsafeMutablePointer<T>,
    box: _BiquadSetupBox,
    count: Int
) {
    let sections = box.sections
    for i in 0..<count {
        var sample = Double(source[i])
        for s in 0..<sections {
            let b0 = box.coeffs[s * 5]
            let b1 = box.coeffs[s * 5 + 1]
            let b2 = box.coeffs[s * 5 + 2]
            let a1 = box.coeffs[s * 5 + 3]
            let a2 = box.coeffs[s * 5 + 4]
            let w1 = Double(delays[s * 2])
            let w2 = Double(delays[s * 2 + 1])
            let w0 = sample - a1 * w1 - a2 * w2
            sample = b0 * w0 + b1 * w1 + b2 * w2
            delays[s * 2] = T(w0)
            delays[s * 2 + 1] = T(w1)
        }
        destination[i] = T(sample)
    }
}

final class _FFTSetupBox {
    let log2n: Int
    let n: Int
    init?(log2n: Int) {
        guard log2n >= 0, log2n <= 20 else { return nil }
        self.log2n = log2n
        self.n = 1 << log2n
    }
}

func _fftRetain(_ box: _FFTSetupBox) -> OpaquePointer {
    OpaquePointer(Unmanaged.passRetained(box).toOpaque())
}

func _fftBox(_ setup: OpaquePointer?) -> _FFTSetupBox? {
    guard let setup else { return nil }
    return Unmanaged<_FFTSetupBox>.fromOpaque(UnsafeRawPointer(setup)).takeUnretainedValue()
}

func _fftRelease(_ setup: OpaquePointer?) {
    guard let setup else { return }
    Unmanaged<_FFTSetupBox>.fromOpaque(UnsafeRawPointer(setup)).release()
}

private func _bitReverse(_ value: Int, bits: Int) -> Int {
    var x = value
    var y = 0
    for _ in 0..<bits {
        y = (y << 1) | (x & 1)
        x >>= 1
    }
    return y
}

func _radix2FFT(real: UnsafeMutablePointer<Float>, imag: UnsafeMutablePointer<Float>, n: Int, inverse: Bool) {
    let bits = n.trailingZeroBitCount
    for i in 0..<n {
        let j = _bitReverse(i, bits: bits)
        if j > i {
            let tr = real[i]; real[i] = real[j]; real[j] = tr
            let ti = imag[i]; imag[i] = imag[j]; imag[j] = ti
        }
    }
    var len = 2
    while len <= n {
        let half = len / 2
        let angle = (inverse ? 2.0 : -2.0) * Double.pi / Double(len)
        let wLenRe = Float(Foundation.cos(angle))
        let wLenIm = Float(Foundation.sin(angle))
        var i = 0
        while i < n {
            var wRe: Float = 1
            var wIm: Float = 0
            for j in 0..<half {
                let uRe = real[i + j]
                let uIm = imag[i + j]
                let vRe = real[i + j + half] * wRe - imag[i + j + half] * wIm
                let vIm = real[i + j + half] * wIm + imag[i + j + half] * wRe
                real[i + j] = uRe + vRe
                imag[i + j] = uIm + vIm
                real[i + j + half] = uRe - vRe
                imag[i + j + half] = uIm - vIm
                let nextRe = wRe * wLenRe - wIm * wLenIm
                wIm = wRe * wLenIm + wIm * wLenRe
                wRe = nextRe
            }
            i += len
        }
        len *= 2
    }
}

func _radix2FFT(real: UnsafeMutablePointer<Double>, imag: UnsafeMutablePointer<Double>, n: Int, inverse: Bool) {
    let bits = n.trailingZeroBitCount
    for i in 0..<n {
        let j = _bitReverse(i, bits: bits)
        if j > i {
            let tr = real[i]; real[i] = real[j]; real[j] = tr
            let ti = imag[i]; imag[i] = imag[j]; imag[j] = ti
        }
    }
    var len = 2
    while len <= n {
        let half = len / 2
        let angle = (inverse ? 2.0 : -2.0) * Double.pi / Double(len)
        let wLenRe = Foundation.cos(angle)
        let wLenIm = Foundation.sin(angle)
        var i = 0
        while i < n {
            var wRe = 1.0
            var wIm = 0.0
            for j in 0..<half {
                let uRe = real[i + j]
                let uIm = imag[i + j]
                let vRe = real[i + j + half] * wRe - imag[i + j + half] * wIm
                let vIm = real[i + j + half] * wIm + imag[i + j + half] * wRe
                real[i + j] = uRe + vRe
                imag[i + j] = uIm + vIm
                real[i + j + half] = uRe - vRe
                imag[i + j + half] = uIm - vIm
                let nextRe = wRe * wLenRe - wIm * wLenIm
                wIm = wRe * wLenIm + wIm * wLenRe
                wRe = nextRe
            }
            i += len
        }
        len *= 2
    }
}

extension vDSP_SplitComplexFloat {
    public static func makeFFTSetup(log2n: vDSP_Length, radix: vDSP.Radix) -> OpaquePointer? {
        guard radix == .radix2, let box = _FFTSetupBox(log2n: Int(log2n)) else { return nil }
        return _fftRetain(box)
    }

    public static func destroySetup(_ setup: OpaquePointer?) {
        _fftRelease(setup)
    }

    public static func transform(
        fftSetup: OpaquePointer?,
        log2n: vDSP_Length,
        source: DSPSplitComplex,
        destination: inout DSPSplitComplex,
        direction: vDSP.FourierTransformDirection
    ) {
        let n = 1 << Int(log2n)
        for i in 0..<n {
            destination.realp[i] = source.realp[i]
            destination.imagp[i] = source.imagp[i]
        }
        _radix2FFT(real: destination.realp, imag: destination.imagp, n: n, inverse: direction == .inverse)
        _ = fftSetup
    }

    public static func transform2D(
        fftSetup: OpaquePointer?,
        width: vDSP_Length,
        height: vDSP_Length,
        source: DSPSplitComplex,
        destination: inout DSPSplitComplex,
        direction: vDSP.FourierTransformDirection
    ) {
        let w = Int(width)
        let h = Int(height)
        for r in 0..<h {
            for c in 0..<w {
                destination.realp[r * w + c] = source.realp[r * w + c]
                destination.imagp[r * w + c] = source.imagp[r * w + c]
            }
        }
        // row FFTs then column FFTs
        for r in 0..<h {
            _radix2FFT(real: destination.realp + r * w, imag: destination.imagp + r * w, n: w, inverse: direction == .inverse)
        }
        var colReal = [Float](repeating: 0, count: h)
        var colImag = [Float](repeating: 0, count: h)
        for c in 0..<w {
            for r in 0..<h {
                colReal[r] = destination.realp[r * w + c]
                colImag[r] = destination.imagp[r * w + c]
            }
            colReal.withUnsafeMutableBufferPointer { rp in
                colImag.withUnsafeMutableBufferPointer { ip in
                    _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: h, inverse: direction == .inverse)
                }
            }
            for r in 0..<h {
                destination.realp[r * w + c] = colReal[r]
                destination.imagp[r * w + c] = colImag[r]
            }
        }
        _ = fftSetup
    }
}

extension vDSP_SplitComplexDouble {
    public static func makeFFTSetup(log2n: vDSP_Length, radix: vDSP.Radix) -> OpaquePointer? {
        guard radix == .radix2, let box = _FFTSetupBox(log2n: Int(log2n)) else { return nil }
        return _fftRetain(box)
    }

    public static func destroySetup(_ setup: OpaquePointer?) {
        _fftRelease(setup)
    }

    public static func transform(
        fftSetup: OpaquePointer?,
        log2n: vDSP_Length,
        source: DSPDoubleSplitComplex,
        destination: inout DSPDoubleSplitComplex,
        direction: vDSP.FourierTransformDirection
    ) {
        let n = 1 << Int(log2n)
        for i in 0..<n {
            destination.realp[i] = source.realp[i]
            destination.imagp[i] = source.imagp[i]
        }
        _radix2FFT(real: destination.realp, imag: destination.imagp, n: n, inverse: direction == .inverse)
        _ = fftSetup
    }

    public static func transform2D(
        fftSetup: OpaquePointer?,
        width: vDSP_Length,
        height: vDSP_Length,
        source: DSPDoubleSplitComplex,
        destination: inout DSPDoubleSplitComplex,
        direction: vDSP.FourierTransformDirection
    ) {
        let w = Int(width)
        let h = Int(height)
        for r in 0..<h {
            for c in 0..<w {
                destination.realp[r * w + c] = source.realp[r * w + c]
                destination.imagp[r * w + c] = source.imagp[r * w + c]
            }
        }
        for r in 0..<h {
            _radix2FFT(real: destination.realp + r * w, imag: destination.imagp + r * w, n: w, inverse: direction == .inverse)
        }
        var colReal = [Double](repeating: 0, count: h)
        var colImag = [Double](repeating: 0, count: h)
        for c in 0..<w {
            for r in 0..<h {
                colReal[r] = destination.realp[r * w + c]
                colImag[r] = destination.imagp[r * w + c]
            }
            colReal.withUnsafeMutableBufferPointer { rp in
                colImag.withUnsafeMutableBufferPointer { ip in
                    _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: h, inverse: direction == .inverse)
                }
            }
            for r in 0..<h {
                destination.realp[r * w + c] = colReal[r]
                destination.imagp[r * w + c] = colImag[r]
            }
        }
        _ = fftSetup
    }
}

extension vDSP_FourierTransformFunctions {
    public static func makeFFTSetup(log2n: vDSP_Length, radix: vDSP.Radix) -> OpaquePointer? {
        guard radix == .radix2, let box = _FFTSetupBox(log2n: Int(log2n)) else { return nil }
        return _fftRetain(box)
    }

    public static func destroySetup(_ setup: OpaquePointer?) {
        _fftRelease(setup)
    }
}

extension vDSP.FFT {
    public convenience init?(log2n: vDSP_Length, radix: vDSP.Radix, ofType: T.Type) {
        guard radix == .radix2, let box = _FFTSetupBox(log2n: Int(log2n)) else { return nil }
        self.init()
        self.log2n = log2n
        self.setup = _fftRetain(box)
        _ = ofType
    }

    public func forward(input: DSPSplitComplex, output: inout DSPSplitComplex) {
        vDSP_SplitComplexFloat.transform(
            fftSetup: setup,
            log2n: log2n,
            source: input,
            destination: &output,
            direction: .forward
        )
    }

    public func inverse(input: DSPSplitComplex, output: inout DSPSplitComplex) {
        vDSP_SplitComplexFloat.transform(
            fftSetup: setup,
            log2n: log2n,
            source: input,
            destination: &output,
            direction: .inverse
        )
    }

    public func transform<U>(
        input: U,
        output: inout U,
        direction: vDSP.FourierTransformDirection
    ) where U: vDSP_FourierTransformable {
        _ = input
        _ = output
        _ = direction
    }
}

extension vDSP.FFT where T == DSPSplitComplex {
    public func transform(
        input: DSPSplitComplex,
        output: inout DSPSplitComplex,
        direction: vDSP.FourierTransformDirection
    ) {
        vDSP_SplitComplexFloat.transform(
            fftSetup: setup,
            log2n: log2n,
            source: input,
            destination: &output,
            direction: direction
        )
    }
}

extension vDSP.FFT2D {
        public convenience init?(width: Int, height: Int, ofType: T.Type) {
        let logW = width.trailingZeroBitCount
        let logH = height.trailingZeroBitCount
        guard width == (1 << logW), height == (1 << logH), width > 0, height > 0 else { return nil }
        self.init(log2n: vDSP_Length(max(logW, logH)), radix: .radix2, ofType: ofType)
        self.width = width
        self.height = height
    }
}

extension vDSP_DFTFunctions {
    public static func destroySetup(_ setup: OpaquePointer) {
        _fftRelease(setup)
    }
}

/// Direct DFT used as an FFT cross-check in tests.
func _accelerateDirectDFT(
    real: [Float],
    imag: [Float],
    inverse: Bool
) -> (real: [Float], imag: [Float]) {
    let n = real.count
    var outR = [Float](repeating: 0, count: n)
    var outI = [Float](repeating: 0, count: n)
    let sign: Float = inverse ? 1 : -1
    for k in 0..<n {
        var sumR: Float = 0
        var sumI: Float = 0
        for t in 0..<n {
            let angle = sign * 2 * Float.pi * Float(k * t) / Float(n)
            let c = Foundation.cos(angle)
            let s = Foundation.sin(angle)
            sumR += real[t] * c - imag[t] * s
            sumI += real[t] * s + imag[t] * c
        }
        outR[k] = sumR
        outI[k] = sumI
    }
    return (outR, outI)
}

extension vDSP.DiscreteFourierTransform {
    public convenience init(
        previousDFT: vDSP.DiscreteFourierTransform<T>?,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType,
        ofType: T.Type
    ) throws {
        guard count > 0 else { throw AccelerateLinuxError.failClosed }
        self.init()
        self.count = count
        self.inverse = direction == .inverse
        _ = previousDFT
        _ = transformType
        _ = ofType
    }

    public convenience init(
        previous: vDSP.DiscreteFourierTransform<Float>?,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType,
        ofType: T.Type
    ) throws {
        try self.init(
            previousDFT: nil,
            count: count,
            direction: direction,
            transformType: transformType,
            ofType: ofType
        )
        _ = previous
    }
}

extension vDSP.DiscreteFourierTransform where T == Float {
    public func transform<U>(real: U, imaginary: U) -> (real: [Float], imaginary: [Float])
    where U: AccelerateBuffer, U.Element == Float {
        var r: [Float] = []
        var i: [Float] = []
        real.withUnsafeBufferPointer { r = Array($0) }
        imaginary.withUnsafeBufferPointer { i = Array($0) }
        let n = min(count, min(r.count, i.count))
        guard n > 0 else { return ([], []) }
        if n.nonzeroBitCount == 1 {
            var rr = Array(r.prefix(n))
            var ii = Array(i.prefix(n))
            rr.withUnsafeMutableBufferPointer { rp in
                ii.withUnsafeMutableBufferPointer { ip in
                    _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: inverse)
                }
            }
            return (rr, ii)
        }
        let dft = _accelerateDirectDFT(real: Array(r.prefix(n)), imag: Array(i.prefix(n)), inverse: inverse)
        return (real: dft.real, imaginary: dft.imag)
    }

    public func transform<U, V>(
        inputReal: U,
        inputImaginary: U,
        outputReal: inout V,
        outputImaginary: inout V
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        let result = transform(real: inputReal, imaginary: inputImaginary)
        outputReal.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, result.real.count) { dest[i] = result.real[i] }
        }
        outputImaginary.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, result.imaginary.count) { dest[i] = result.imaginary[i] }
        }
    }
}

extension vDSP.DiscreteFourierTransform where T == Double {
    public func transform<U>(real: U, imaginary: U) -> (real: [Double], imaginary: [Double])
    where U: AccelerateBuffer, U.Element == Double {
        var r: [Double] = []
        var i: [Double] = []
        real.withUnsafeBufferPointer { r = Array($0) }
        imaginary.withUnsafeBufferPointer { i = Array($0) }
        let n = min(count, min(r.count, i.count))
        guard n > 0 else { return ([], []) }
        var rr = Array(r.prefix(n))
        var ii = Array(i.prefix(n))
        if n.nonzeroBitCount == 1 {
            rr.withUnsafeMutableBufferPointer { rp in
                ii.withUnsafeMutableBufferPointer { ip in
                    _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: inverse)
                }
            }
            return (rr, ii)
        }
        let nD = Double(n)
        var outR = [Double](repeating: 0, count: n)
        var outI = [Double](repeating: 0, count: n)
        let sign: Double = inverse ? 1 : -1
        for k in 0..<n {
            var sumR = 0.0
            var sumI = 0.0
            for t in 0..<n {
                let angle = sign * 2 * Double.pi * Double(k * t) / nD
                let c = Foundation.cos(angle)
                let s = Foundation.sin(angle)
                sumR += rr[t] * c - ii[t] * s
                sumI += rr[t] * s + ii[t] * c
            }
            outR[k] = sumR
            outI[k] = sumI
        }
        return (outR, outI)
    }

    public func transform<U, V>(
        inputReal: U,
        inputImaginary: U,
        outputReal: inout V,
        outputImaginary: inout V
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Double, V.Element == Double {
        let result = transform(real: inputReal, imaginary: inputImaginary)
        outputReal.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, result.real.count) { dest[i] = result.real[i] }
        }
        outputImaginary.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, result.imaginary.count) { dest[i] = result.imaginary[i] }
        }
    }
}

extension vDSP.DiscreteFourierTransform where T == DSPComplex {
    public func transform<U, V>(input: U, output: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == DSPComplex, V.Element == DSPComplex {
        var values: [DSPComplex] = []
        input.withUnsafeBufferPointer { values = Array($0) }
        let n = min(count, values.count)
        var real = values.prefix(n).map(\.real)
        var imag = values.prefix(n).map(\.imag)
        if n > 0, n.nonzeroBitCount == 1 {
            real.withUnsafeMutableBufferPointer { rp in
                imag.withUnsafeMutableBufferPointer { ip in
                    _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: inverse)
                }
            }
        }
        output.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, n) {
                dest[i] = DSPComplex(real: real[i], imag: imag[i])
            }
        }
    }

    public func transform<U>(input: U) -> [DSPComplex]
    where U: AccelerateBuffer, U.Element == DSPComplex {
        var out = [DSPComplex](repeating: DSPComplex(), count: count)
        transform(input: input, output: &out)
        return out
    }
}

extension vDSP.DiscreteFourierTransform where T == DSPDoubleComplex {
    public func transform<U, V>(input: U, output: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == DSPDoubleComplex, V.Element == DSPDoubleComplex {
        var values: [DSPDoubleComplex] = []
        input.withUnsafeBufferPointer { values = Array($0) }
        let n = min(count, values.count)
        var real = values.prefix(n).map(\.real)
        var imag = values.prefix(n).map(\.imag)
        if n > 0, n.nonzeroBitCount == 1 {
            real.withUnsafeMutableBufferPointer { rp in
                imag.withUnsafeMutableBufferPointer { ip in
                    _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: inverse)
                }
            }
        }
        output.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, n) {
                dest[i] = DSPDoubleComplex(real: real[i], imag: imag[i])
            }
        }
    }

    public func transform<U>(input: U) -> [DSPDoubleComplex]
    where U: AccelerateBuffer, U.Element == DSPDoubleComplex {
        var out = [DSPDoubleComplex](repeating: DSPDoubleComplex(), count: count)
        transform(input: input, output: &out)
        return out
    }
}

extension vDSP.DFT {
    public convenience init?(
        previous: vDSP.DFT<T>?,
        count: Int,
        direction: vDSP.FourierTransformDirection,
        transformType: vDSP.DFTTransformType,
        ofType: T.Type
    ) {
        guard count > 0 else { return nil }
        self.init()
        self.count = count
        self.inverse = direction == .inverse
        _ = previous
        _ = transformType
        _ = ofType
    }

    public func transform<U>(inputReal: U, inputImaginary: U) -> (real: [T], imaginary: [T])
    where T == U.Element, U: AccelerateBuffer {
        var r: [T] = []
        var i: [T] = []
        inputReal.withUnsafeBufferPointer { r = Array($0) }
        inputImaginary.withUnsafeBufferPointer { i = Array($0) }
        return (Array(r.prefix(count)), Array(i.prefix(count)))
    }
}

extension vDSP.DFT where T == Float {
    public func transform<U, V>(
        inputReal: U,
        inputImaginary: U,
        outputReal: inout V,
        outputImaginary: inout V
    ) where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        var r: [Float] = []
        var i: [Float] = []
        inputReal.withUnsafeBufferPointer { r = Array($0) }
        inputImaginary.withUnsafeBufferPointer { i = Array($0) }
        let n = min(count, min(r.count, i.count))
        var rr = Array(r.prefix(n))
        var ii = Array(i.prefix(n))
        if n > 0, n.nonzeroBitCount == 1 {
            rr.withUnsafeMutableBufferPointer { rp in
                ii.withUnsafeMutableBufferPointer { ip in
                    _radix2FFT(real: rp.baseAddress!, imag: ip.baseAddress!, n: n, inverse: inverse)
                }
            }
        }
        outputReal.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, n) { dest[i] = rr[i] }
        }
        outputImaginary.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, n) { dest[i] = ii[i] }
        }
    }
}

extension vDSP.DCT {
    public convenience init?(previous: vDSP.DCT? = nil, count: Int, transformType: vDSP.DCTTransformType) {
        guard count > 0 else { return nil }
        self.init()
        self.count = count
        self.transformType = transformType
        _ = previous
    }

    public func transform<U, V>(_ vector: U, result: inout V)
    where U: AccelerateBuffer, V: AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        let values = transform(vector)
        result.withUnsafeMutableBufferPointer { dest in
            for i in 0..<min(dest.count, values.count) { dest[i] = values[i] }
        }
    }

    public func transform<U>(_ vector: U) -> [Float]
    where U: AccelerateBuffer, U.Element == Float {
        var x: [Float] = []
        vector.withUnsafeBufferPointer { x = Array($0) }
        let n = min(count, x.count)
        guard n > 0 else { return [] }
        var out = [Float](repeating: 0, count: n)
        let nF = Float(n)
        for k in 0..<n {
            var sum: Float = 0
            for t in 0..<n {
                let angle: Float
                switch transformType {
                case .II:
                    angle = Float.pi / nF * (Float(t) + 0.5) * Float(k)
                case .III:
                    angle = Float.pi / nF * Float(t) * (Float(k) + 0.5)
                case .IV:
                    angle = Float.pi / nF * (Float(t) + 0.5) * (Float(k) + 0.5)
                }
                sum += x[t] * Foundation.cos(angle)
            }
            out[k] = sum
        }
        return out
    }
}


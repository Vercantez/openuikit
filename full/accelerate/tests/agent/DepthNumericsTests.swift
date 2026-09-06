import Accelerate
import Foundation

func testQuadratureIntegratePolynomial() {
    let q = Quadrature(integrator: .nonAdaptive, absoluteTolerance: 1e-8, relativeTolerance: 1e-8)
    let square = q.integrate(over: 0...1, integrand: { $0 * $0 })
    guard case .success(let pair) = square else { preconditionFailure("x^2 integral failed") }
    precondition(abs(pair.integralResult - 1.0 / 3.0) < 1e-6)
    let sine = Quadrature(integrator: .qng, absoluteTolerance: 1e-8, relativeTolerance: 1e-8)
        .integrate(over: 0...Double.pi, integrand: Foundation.sin)
    guard case .success(let sinPair) = sine else { preconditionFailure("sin integral failed") }
    precondition(abs(sinPair.integralResult - 2) < 1e-5)
    let buffered = q.integrate(over: 0...1) { xs, ys in
        for i in 0..<xs.count { ys[i] = 1 }
    }
    guard case .success(let one) = buffered else { preconditionFailure("ones integral failed") }
    precondition(abs(one.integralResult - 1) < 1e-6)
}

func testQuadratureOverlaySurface() {
    precondition(Quadrature.QAGPointsPerInterval.fifteen.points == 15)
    precondition(Quadrature.QAGPointsPerInterval.twentyOne.points == 21)
    precondition(Quadrature.QAGPointsPerInterval.thirtyOne.points == 31)
    precondition(Quadrature.QAGPointsPerInterval.fortyOne.points == 41)
    precondition(Quadrature.QAGPointsPerInterval.fiftyOne.points == 51)
    precondition(Quadrature.QAGPointsPerInterval.sixtyOne.points == 61)
    _ = Quadrature.Integrator.qag(pointsPerInterval: .fifteen, maxIntervals: 8)
    _ = Quadrature.Integrator.qags(maxIntervals: 8)
    _ = Quadrature.Integrator.adaptive(pointsPerInterval: .twentyOne, maxIntervals: 4)
    _ = Quadrature.Integrator.adaptiveWithSingularities(maxIntervals: 4)
    var q = Quadrature(integrator: .qng, absoluteTolerance: 1e-6, relativeTolerance: 1e-4)
    precondition(q.absoluteTolerance == 1e-6)
    q.absoluteTolerance = 1e-7
    q.relativeTolerance = 1e-5
    precondition(q.relativeTolerance == 1e-5)
    let e1 = Quadrature.Error.invalidArgument
    let e2 = Quadrature.Error(quadratureStatus: QUADRATURE_INVALID_ARG_ERROR)
    precondition(e1 == e2)
    precondition(e1 != .generic)
    precondition(e1.errorDescription.contains("invalid"))
    var hasher = Hasher()
    e1.hash(into: &hasher)
    _ = e1.hashValue
    _ = e1.localizedDescription
}

func testSparseMultiplyKnownMatrix() {
    var rows: [Int32] = [0, 0, 1]
    var cols: [Int32] = [0, 1, 1]
    var vals: [Float] = [1, 2, 3]
    var matrix = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rows, &cols, &vals)
    var xdata: [Float] = [1, 1]
    var ydata: [Float] = [0, 0]
    let x = DenseVector_Float(count: 2, data: &xdata)
    var y = DenseVector_Float(count: 2, data: &ydata)
    SparseMultiply(matrix, x, y)
    precondition(abs(ydata[0] - 3) < 0.0001)
    precondition(abs(ydata[1] - 3) < 0.0001)
    ydata = [10, 10]
    SparseMultiplyAdd(matrix, x, y)
    precondition(abs(ydata[0] - 13) < 0.0001)
    var scaled: [Float] = [0, 0]
    var ys = DenseVector_Float(count: 2, data: &scaled)
    SparseMultiply(Float(2), matrix, x, ys)
    precondition(abs(scaled[0] - 6) < 0.0001)
    var addScaled: [Float] = [1, 1]
    var yas = DenseVector_Float(count: 2, data: &addScaled)
    SparseMultiplyAdd(Float(2), matrix, x, yas)
    precondition(abs(addScaled[0] - 7) < 0.0001)
    var storage = [UInt8](repeating: 0, count: 64)
    var workspace = [UInt8](repeating: 0, count: 64)
    var rows2 = rows
    var cols2 = cols
    var vals2 = vals
    var matrix2 = storage.withUnsafeMutableBytes { sb in
        workspace.withUnsafeMutableBytes { wb in
            SparseConvertFromCoordinate(
                2, 2, 3, 1, SparseAttributes_t(), &rows2, &cols2, &vals2,
                sb.baseAddress!, wb.baseAddress!
            )
        }
    }
    SparseCleanup(matrix)
    SparseCleanup(matrix2)
}

func testSparseMultiplyDoubleAndMatrix() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Double] = [4, 5]
    var workspace = [UInt8](repeating: 0, count: 64)
    var storage = [UInt8](repeating: 0, count: 64)
    var matrix = storage.withUnsafeMutableBytes { sb in
        workspace.withUnsafeMutableBytes { wb in
            SparseConvertFromCoordinate(
                2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals,
                sb.baseAddress!, wb.baseAddress!
            )
        }
    }
    var xdata: [Double] = [1, 2]
    var ydata: [Double] = [0, 0]
    let x = DenseVector_Double(count: 2, data: &xdata)
    var y = DenseVector_Double(count: 2, data: &ydata)
    SparseMultiply(matrix, x, y)
    precondition(abs(ydata[0] - 4) < 1e-12)
    precondition(abs(ydata[1] - 10) < 1e-12)
    ydata = [1, 1]
    SparseMultiplyAdd(matrix, x, y)
    precondition(abs(ydata[0] - 5) < 1e-12)
    var y2data: [Double] = [0, 0]
    var y2 = DenseVector_Double(count: 2, data: &y2data)
    SparseMultiply(2.0, matrix, x, y2)
    precondition(abs(y2data[0] - 8) < 1e-12)
    var y3data: [Double] = [1, 0]
    var y3 = DenseVector_Double(count: 2, data: &y3data)
    SparseMultiplyAdd(2.0, matrix, x, y3)
    precondition(abs(y3data[0] - 9) < 1e-12)
    var xmat: [Float] = [1, 0, 0, 1]
    var ymat = [Float](repeating: 0, count: 4)
    var rowsF: [Int32] = [0, 1]
    var colsF: [Int32] = [0, 1]
    var valsF: [Float] = [2, 3]
    var mf = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsF, &colsF, &valsF)
    var X = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &xmat
    )
    var Y = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &ymat
    )
    SparseMultiply(mf, X, Y)
    precondition(abs(ymat[0] - 2) < 0.0001)
    precondition(abs(ymat[3] - 3) < 0.0001)
    var ymat2 = [Float](repeating: 1, count: 4)
    var Y2 = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &ymat2
    )
    SparseMultiplyAdd(mf, X, Y2)
    precondition(abs(ymat2[0] - 3) < 0.0001)
    var ymat3 = [Float](repeating: 0, count: 4)
    var Y3 = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &ymat3
    )
    SparseMultiply(Float(3), mf, X, Y3)
    precondition(abs(ymat3[0] - 6) < 0.0001)
    var ymat4 = [Float](repeating: 1, count: 4)
    var Y4 = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &ymat4
    )
    SparseMultiplyAdd(Float(3), mf, X, Y4)
    precondition(abs(ymat4[0] - 7) < 0.0001)
    var dmat: [Double] = [1, 0, 0, 1]
    var dymat = [Double](repeating: 0, count: 4)
    var DX = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dmat
    )
    var DY = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dymat
    )
    SparseMultiply(matrix, DX, DY)
    precondition(abs(dymat[0] - 4) < 1e-12)
    var dymat2 = [Double](repeating: 1, count: 4)
    var DY2 = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dymat2
    )
    SparseMultiplyAdd(matrix, DX, DY2)
    precondition(abs(dymat2[0] - 5) < 1e-12)
    var dymat3 = [Double](repeating: 0, count: 4)
    var DY3 = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dymat3
    )
    SparseMultiply(2.0, matrix, DX, DY3)
    precondition(abs(dymat3[0] - 8) < 1e-12)
    var dymat4 = [Double](repeating: 1, count: 4)
    var DY4 = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dymat4
    )
    SparseMultiplyAdd(2.0, matrix, DX, DY4)
    precondition(abs(dymat4[0] - 9) < 1e-12)
    SparseCleanup(matrix)
    SparseCleanup(mf)
}

func testCBLASDotGemvKnown() {
    let x: [Float] = [1, 2, 3]
    let y: [Float] = [4, 5, 6]
    precondition(abs(cblas_sdot(3, x, 1, y, 1) - 32) < 0.0001)
    let a: [Float] = [1, 0, 0, 1]
    var out: [Float] = [0, 0]
    var xv: [Float] = [7, 8]
    cblas_sgemv(CblasColMajor, CblasNoTrans, 2, 2, 1, a, 2, xv, 1, 0, &out, 1)
    precondition(abs(out[0] - 7) < 0.0001)
    precondition(abs(out[1] - 8) < 0.0001)
    var rowOut: [Float] = [0, 0]
    var rm: [Float] = [1, 2, 3, 4]
    var rv: [Float] = [1, 1]
    cblas_sgemv(CblasRowMajor, CblasNoTrans, 2, 2, 1, rm, 2, rv, 1, 0, &rowOut, 1)
    precondition(abs(rowOut[0] - 3) < 0.0001)
    precondition(abs(rowOut[1] - 7) < 0.0001)
    var n: Int32 = 2
    var sx: [Float] = [1, 2]
    var sy: [Float] = [3, 4]
    var inc: Int32 = 1
    precondition(abs(dsdot_(&n, &sx, &inc, &sy, &inc) - 11) < 0.0001)
    var sb: Float = 5
    precondition(abs(sdsdot_(&n, &sb, &sx, &inc, &sy, &inc) - 16) < 0.0001)
}

func testBLASRotSymvTrsvSyrk() {
    var n: Int32 = 2
    var x: [Float] = [1, 0]
    var y: [Float] = [0, 1]
    var inc: Int32 = 1
    var c: Float = 0
    var s: Float = 1
    _ = srot_(&n, &x, &inc, &y, &inc, &c, &s)
    precondition(abs(x[0] - 0) < 0.0001)
    precondition(abs(y[0] - -1) < 0.0001)
    var dx: [Double] = [1, 0]
    var dy: [Double] = [0, 1]
    var dc: Double = 1
    var ds: Double = 0
    _ = drot_(&n, &dx, &inc, &dy, &inc, &dc, &ds)
    precondition(abs(dx[0] - 1) < 1e-12)
    var uplo = CChar(76)
    var trans = CChar(78)
    var diag = CChar(78)
    var lda: Int32 = 2
    var a: [Float] = [2, 1, 0, 2]
    var rhs: [Float] = [2, 3]
    _ = strsv_(&uplo, &trans, &diag, &n, &a, &lda, &rhs, &inc)
    precondition(abs(rhs[0] - 1) < 0.0001)
    precondition(abs(rhs[1] - 1) < 0.0001)
    var da: [Double] = [2, 1, 0, 2]
    var drhs: [Double] = [2, 3]
    _ = dtrsv_(&uplo, &trans, &diag, &n, &da, &lda, &drhs, &inc)
    precondition(abs(drhs[0] - 1) < 1e-12)
    var alpha: Float = 1
    var beta: Float = 0
    var symA: [Float] = [2, 1, 1, 2]
    var sx: [Float] = [1, 1]
    var sy = [Float](repeating: 0, count: 2)
    _ = ssymv_(&uplo, &n, &alpha, &symA, &lda, &sx, &inc, &beta, &sy, &inc)
    precondition(abs(sy[0] - 3) < 0.0001)
    precondition(abs(sy[1] - 3) < 0.0001)
    var k: Int32 = 2
    var a2: [Float] = [1, 0, 0, 1]
    var cOut = [Float](repeating: 0, count: 4)
    var ldc: Int32 = 2
    _ = ssyrk_(&uplo, &trans, &n, &k, &alpha, &a2, &lda, &beta, &cOut, &ldc)
    precondition(abs(cOut[0] - 1) < 0.0001)
    var dalpha: Double = 1
    var dbeta: Double = 0
    var dsymA: [Double] = [2, 1, 1, 2]
    var dsx: [Double] = [1, 1]
    var dsy = [Double](repeating: 0, count: 2)
    _ = dsymv_(&uplo, &n, &dalpha, &dsymA, &lda, &dsx, &inc, &dbeta, &dsy, &inc)
    precondition(abs(dsy[0] - 3) < 1e-12)
    var da2: [Double] = [1, 0, 0, 1]
    var dcOut = [Double](repeating: 0, count: 4)
    _ = dsyrk_(&uplo, &trans, &n, &k, &dalpha, &da2, &lda, &dbeta, &dcOut, &ldc)
    precondition(abs(dcOut[0] - 1) < 1e-12)
}

func testBLASRotgSyrTrmv() {
    var a: Float = 3
    var b: Float = 4
    var c: Float = 0
    var s: Float = 0
    _ = srotg_(&a, &b, &c, &s)
    precondition(abs(abs(a) - 5) < 0.0001)
    precondition(abs(c - 3.0 / 5.0) < 0.0001)
    precondition(abs(s - 4.0 / 5.0) < 0.0001)
    var da: Double = 3
    var db: Double = 4
    var dc: Double = 0
    var ds: Double = 0
    _ = drotg_(&da, &db, &dc, &ds)
    precondition(abs(abs(da) - 5) < 1e-12)
    var n: Int32 = 2
    var uplo = CChar(76)
    var inc: Int32 = 1
    var lda: Int32 = 2
    var alpha: Float = 1
    var x: [Float] = [1, 1]
    var A = [Float](repeating: 0, count: 4)
    _ = ssyr_(&uplo, &n, &alpha, &x, &inc, &A, &lda)
    precondition(abs(A[0] - 1) < 0.0001)
    precondition(abs(A[1] - 1) < 0.0001)
    precondition(abs(A[3] - 1) < 0.0001)
    var dalpha: Double = 1
    var dx: [Double] = [1, 1]
    var dA = [Double](repeating: 0, count: 4)
    _ = dsyr_(&uplo, &n, &dalpha, &dx, &inc, &dA, &lda)
    precondition(abs(dA[0] - 1) < 1e-12)
    var trans = CChar(78)
    var diag = CChar(78)
    var L: [Float] = [2, 1, 0, 2]
    var xv: [Float] = [1, 1]
    _ = strmv_(&uplo, &trans, &diag, &n, &L, &lda, &xv, &inc)
    precondition(abs(xv[0] - 2) < 0.0001)
    precondition(abs(xv[1] - 3) < 0.0001)
    var dL: [Double] = [2, 1, 0, 2]
    var dxv: [Double] = [1, 1]
    _ = dtrmv_(&uplo, &trans, &diag, &n, &dL, &lda, &dxv, &inc)
    precondition(abs(dxv[0] - 2) < 1e-12)
    precondition(abs(dxv[1] - 3) < 1e-12)
}

func testLAPACKCholeskyAndInverse() {
    var n: Int32 = 2
    var lda: Int32 = 2
    var info: Int32 = 0
    var uplo = CChar(76)
    var a: [Float] = [4, 2, 2, 3]
    _ = spotrf_(&uplo, &n, &a, &lda, &info)
    precondition(info == 0)
    precondition(abs(a[0] - 2) < 0.0001)
    precondition(abs(a[1] - 1) < 0.0001)
    var da: [Double] = [4, 2, 2, 3]
    _ = dpotrf_(&uplo, &n, &da, &lda, &info)
    precondition(info == 0)
    var inv: [Float] = [2, 0, 0, 2]
    var ipiv: [Int32] = [0, 0]
    var m: Int32 = 2
    _ = sgetrf_(&m, &n, &inv, &lda, &ipiv, &info)
    var work: [Float] = [0, 0]
    var lwork: Int32 = 2
    _ = sgetri_(&n, &inv, &lda, &ipiv, &work, &lwork, &info)
    precondition(info == 0)
    precondition(abs(inv[0] - 0.5) < 0.0001)
    precondition(abs(inv[3] - 0.5) < 0.0001)
    var dinv: [Double] = [2, 0, 0, 2]
    var dipiv: [Int32] = [0, 0]
    var dwork: [Double] = [0, 0]
    _ = dgetrf_(&m, &n, &dinv, &lda, &dipiv, &info)
    _ = dgetri_(&n, &dinv, &lda, &dipiv, &dwork, &lwork, &info)
    precondition(abs(dinv[0] - 0.5) < 1e-12)
}

func testVDSPBiquadPassThrough() {
    guard let setup = vDSP.VectorizableFloat.makeBiquadSetup(
        channelCount: 1, coefficients: [1, 0, 0, 0, 0], sectionCount: 1
    ) else {
        preconditionFailure("biquad setup")
    }
    var delays: [Float] = [0, 0]
    var dest = [Float](repeating: 0, count: 4)
    let src: [Float] = [1, 2, 3, 4]
    vDSP.VectorizableFloat.applySingle(
        source: src, destination: &dest, delays: &delays,
        setup: setup, sectionCount: 1, count: 4
    )
    precondition(dest == src)
    var srcCopy = src
    var destMulti = [Float](repeating: 0, count: 4)
    srcCopy.withUnsafeBufferPointer { sp in
        destMulti.withUnsafeMutableBufferPointer { dp in
            var inP = sp.baseAddress!
            var outP = dp.baseAddress!
            withUnsafeMutablePointer(to: &inP) { ip in
                withUnsafeMutablePointer(to: &outP) { op in
                    vDSP.VectorizableFloat.applyMulti(
                        setup: setup, pInputs: ip, pOutputs: op, count: 4
                    )
                }
            }
        }
    }
    precondition(destMulti == src)
    var ddelays: [Double] = [0, 0]
    var ddest = [Double](repeating: 0, count: 4)
    let dsrc: [Double] = [1, 2, 3, 4]
    if let dsetup = vDSP.VectorizableDouble.makeBiquadSetup(
        channelCount: 1, coefficients: [1, 0, 0, 0, 0], sectionCount: 1
    ) {
        vDSP.VectorizableDouble.applySingle(
            source: dsrc, destination: &ddest, delays: &ddelays,
            setup: dsetup, sectionCount: 1, count: 4
        )
        precondition(ddest == dsrc)
        var dsrcCopy = dsrc
        var ddestMulti = [Double](repeating: 0, count: 4)
        dsrcCopy.withUnsafeBufferPointer { sp in
            ddestMulti.withUnsafeMutableBufferPointer { dp in
                var inP = sp.baseAddress!
                var outP = dp.baseAddress!
                withUnsafeMutablePointer(to: &inP) { ip in
                    withUnsafeMutablePointer(to: &outP) { op in
                        vDSP.VectorizableDouble.applyMulti(
                            setup: dsetup, pInputs: ip, pOutputs: op, count: 4
                        )
                    }
                }
            }
        }
        precondition(ddestMulti == dsrc)
        vDSP.VectorizableDouble.destroySetup(channelCount: 1, biquadSetup: dsetup)
    }
    vDSP.VectorizableFloat.destroySetup(channelCount: 1, biquadSetup: setup)
}

func testVDSPDFTInterleavedDouble() {
    if let setup = vDSP_DFT_Interleaved_CreateSetupD(nil, 8, .FORWARD, .interleaved_ComplextoComplex) {
        var iri = [DSPDoubleComplex](repeating: DSPDoubleComplex(real: 0, imag: 0), count: 8)
        iri[0] = DSPDoubleComplex(real: 1, imag: 0)
        var ori = [DSPDoubleComplex](repeating: DSPDoubleComplex(), count: 8)
        vDSP_DFT_Interleaved_ExecuteD(setup, iri, &ori)
        precondition(abs(ori[0].real - 1) < 1e-9)
        var dftR = [Double](repeating: 0, count: 8)
        for k in 0..<8 {
            var sum = 0.0
            for t in 0..<8 {
                let angle = -2 * Double.pi * Double(k * t) / 8
                sum += (t == 0 ? 1.0 : 0.0) * Foundation.cos(angle)
            }
            dftR[k] = sum
        }
        precondition(abs(ori[3].real - dftR[3]) < 1e-9)
        vDSP_DFT_Interleaved_DestroySetupD(setup)
    } else {
        preconditionFailure("double interleaved DFT setup")
    }
}

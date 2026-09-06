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

func testQAGPointsPerIntervalValues() {
    let table: [(Quadrature.QAGPointsPerInterval, Int)] = [
        (.fifteen, 15),
        (.twentyOne, 21),
        (.thirtyOne, 31),
        (.fortyOne, 41),
        (.fiftyOne, 51),
        (.sixtyOne, 61)
    ]
    for (value, expected) in table {
        precondition(value.points == expected)
    }
}

func testQuadratureIntegratorAdaptive() {
    let adaptive = Quadrature.Integrator.adaptive(pointsPerInterval: .twentyOne, maxIntervals: 4)
    let singular = Quadrature.Integrator.adaptiveWithSingularities(maxIntervals: 4)
    let qag = Quadrature.Integrator.qag(pointsPerInterval: .fifteen, maxIntervals: 8)
    let q = Quadrature(integrator: adaptive, absoluteTolerance: 1e-8, relativeTolerance: 1e-8)
    let linear = q.integrate(over: 0...1, integrand: { $0 })
    guard case .success(let pair) = linear else { preconditionFailure("adaptive integral failed") }
    precondition(abs(pair.integralResult - 0.5) < 1e-6)
    let q2 = Quadrature(integrator: singular, absoluteTolerance: 1e-8, relativeTolerance: 1e-8)
    let ones = q2.integrate(over: 0...1, integrand: { _ in 1 })
    guard case .success(let one) = ones else { preconditionFailure("qags integral failed") }
    precondition(abs(one.integralResult - 1) < 1e-6)
    let q3 = Quadrature(integrator: qag, absoluteTolerance: 1e-8, relativeTolerance: 1e-8)
    let half = q3.integrate(over: 0...1, integrand: { $0 })
    guard case .success(let halfPair) = half else { preconditionFailure("qag integral failed") }
    precondition(abs(halfPair.integralResult - 0.5) < 1e-6)
}

func testQuadratureTolerances() {
    var q = Quadrature(integrator: .qng, absoluteTolerance: 1e-6, relativeTolerance: 1e-4)
    precondition(q.absoluteTolerance == 1e-6)
    q.absoluteTolerance = 1e-7
    q.relativeTolerance = 1e-5
    precondition(q.relativeTolerance == 1e-5)
}

func testQuadratureErrorHashable() {
    let table: [(Quadrature.Error, quadrature_status, String)] = [
        (.invalidArgument, QUADRATURE_INVALID_ARG_ERROR, "invalid"),
        (.integrateMaxEval, QUADRATURE_INTEGRATE_MAX_EVAL_ERROR, "maximum"),
        (.badIntegrandBehaviour, QUADRATURE_INTEGRATE_BAD_BEHAVIOUR_ERROR, "integrand"),
        (.internal, QUADRATURE_INTERNAL_ERROR, "internal")
    ]
    for (expected, status, needle) in table {
        let parsed = Quadrature.Error(quadratureStatus: status)
        precondition(parsed == expected)
        precondition(parsed != .generic)
        precondition(expected.errorDescription.contains(needle))
        _ = expected.localizedDescription
        var hasher = Hasher()
        expected.hash(into: &hasher)
        _ = expected.hashValue
    }
}

func testSparseMultiplyFloatVector() {
    var rows: [Int32] = [0, 0, 1]
    var cols: [Int32] = [0, 1, 1]
    var vals: [Float] = [1, 2, 3]
    let matrix = SparseConvertFromCoordinate(2, 2, 3, 1, SparseAttributes_t(), &rows, &cols, &vals)
    var xdata: [Float] = [1, 1]
    var ydata: [Float] = [0, 0]
    let x = DenseVector_Float(count: 2, data: &xdata)
    let y = DenseVector_Float(count: 2, data: &ydata)
    SparseMultiply(matrix, x, y)
    precondition(abs(ydata[0] - 3) < 0.0001)
    precondition(abs(ydata[1] - 3) < 0.0001)
    ydata[0] = 10
    ydata[1] = 10
    SparseMultiplyAdd(matrix, x, y)
    precondition(abs(ydata[0] - 13) < 0.0001)
    var scaled: [Float] = [0, 0]
    let ys = DenseVector_Float(count: 2, data: &scaled)
    SparseMultiply(Float(2), matrix, x, ys)
    precondition(abs(scaled[0] - 6) < 0.0001)
    var addScaled: [Float] = [1, 1]
    let yas = DenseVector_Float(count: 2, data: &addScaled)
    SparseMultiplyAdd(Float(2), matrix, x, yas)
    precondition(abs(addScaled[0] - 7) < 0.0001)
    var storage = [UInt8](repeating: 0, count: 64)
    var workspace = [UInt8](repeating: 0, count: 64)
    var rows2 = rows
    var cols2 = cols
    var vals2 = vals
    let matrix2 = storage.withUnsafeMutableBytes { sb in
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

func testSparseMultiplyDoubleVector() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Double] = [4, 5]
    var workspace = [UInt8](repeating: 0, count: 64)
    var storage = [UInt8](repeating: 0, count: 64)
    let matrix = storage.withUnsafeMutableBytes { sb in
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
    let y = DenseVector_Double(count: 2, data: &ydata)
    SparseMultiply(matrix, x, y)
    precondition(abs(ydata[0] - 4) < 1e-12)
    precondition(abs(ydata[1] - 10) < 1e-12)
    ydata[0] = 1
    ydata[1] = 1
    SparseMultiplyAdd(matrix, x, y)
    precondition(abs(ydata[0] - 5) < 1e-12)
    var y2data: [Double] = [0, 0]
    let y2 = DenseVector_Double(count: 2, data: &y2data)
    SparseMultiply(2.0, matrix, x, y2)
    precondition(abs(y2data[0] - 8) < 1e-12)
    var y3data: [Double] = [1, 0]
    let y3 = DenseVector_Double(count: 2, data: &y3data)
    SparseMultiplyAdd(2.0, matrix, x, y3)
    precondition(abs(y3data[0] - 9) < 1e-12)
    var rows2 = rows
    var cols2 = cols
    var vals2 = vals
    let matrix2 = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows2, &cols2, &vals2)
    SparseCleanup(matrix)
    SparseCleanup(matrix2)
}

func testSparseMultiplyFloatMatrix() {
    var rowsF: [Int32] = [0, 1]
    var colsF: [Int32] = [0, 1]
    var valsF: [Float] = [2, 3]
    let mf = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rowsF, &colsF, &valsF)
    var xmat: [Float] = [1, 0, 0, 1]
    var ymat = [Float](repeating: 0, count: 4)
    let X = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &xmat
    )
    let Y = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &ymat
    )
    SparseMultiply(mf, X, Y)
    precondition(abs(ymat[0] - 2) < 0.0001)
    precondition(abs(ymat[3] - 3) < 0.0001)
    var ymat2 = [Float](repeating: 1, count: 4)
    let Y2 = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &ymat2
    )
    SparseMultiplyAdd(mf, X, Y2)
    precondition(abs(ymat2[0] - 3) < 0.0001)
    var ymat3 = [Float](repeating: 0, count: 4)
    let Y3 = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &ymat3
    )
    SparseMultiply(Float(3), mf, X, Y3)
    precondition(abs(ymat3[0] - 6) < 0.0001)
    var ymat4 = [Float](repeating: 1, count: 4)
    let Y4 = DenseMatrix_Float(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &ymat4
    )
    SparseMultiplyAdd(Float(3), mf, X, Y4)
    precondition(abs(ymat4[0] - 7) < 0.0001)
    SparseCleanup(mf)
}

func testSparseMultiplyDoubleMatrix() {
    var rows: [Int32] = [0, 1]
    var cols: [Int32] = [0, 1]
    var vals: [Double] = [4, 5]
    let matrix = SparseConvertFromCoordinate(2, 2, 2, 1, SparseAttributes_t(), &rows, &cols, &vals)
    var dmat: [Double] = [1, 0, 0, 1]
    var dymat = [Double](repeating: 0, count: 4)
    let DX = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dmat
    )
    let DY = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dymat
    )
    SparseMultiply(matrix, DX, DY)
    precondition(abs(dymat[0] - 4) < 1e-12)
    var dymat2 = [Double](repeating: 1, count: 4)
    let DY2 = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dymat2
    )
    SparseMultiplyAdd(matrix, DX, DY2)
    precondition(abs(dymat2[0] - 5) < 1e-12)
    var dymat3 = [Double](repeating: 0, count: 4)
    let DY3 = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dymat3
    )
    SparseMultiply(2.0, matrix, DX, DY3)
    precondition(abs(dymat3[0] - 8) < 1e-12)
    var dymat4 = [Double](repeating: 1, count: 4)
    let DY4 = DenseMatrix_Double(
        rowCount: 2, columnCount: 2, columnStride: 2,
        attributes: SparseAttributes_t(), data: &dymat4
    )
    SparseMultiplyAdd(2.0, matrix, DX, DY4)
    precondition(abs(dymat4[0] - 9) < 1e-12)
    SparseCleanup(matrix)
}

func testBLASDsdot() {
    var n: Int32 = 2
    var sx: [Float] = [1, 2]
    var sy: [Float] = [3, 4]
    var incx: Int32 = 1
    var incy: Int32 = 1
    precondition(abs(dsdot_(&n, &sx, &incx, &sy, &incy) - 11) < 0.0001)
}

func testBLASSdsdot() {
    var n: Int32 = 2
    var sx: [Float] = [1, 2]
    var sy: [Float] = [3, 4]
    var incx: Int32 = 1
    var incy: Int32 = 1
    var sb: Float = 5
    precondition(abs(sdsdot_(&n, &sb, &sx, &incx, &sy, &incy) - 16) < 0.0001)
}

func testBLASRot() {
    var n: Int32 = 2
    var x: [Float] = [1, 0]
    var y: [Float] = [0, 1]
    var incx: Int32 = 1
    var incy: Int32 = 1
    var c: Float = 0
    var s: Float = 1
    _ = srot_(&n, &x, &incx, &y, &incy, &c, &s)
    precondition(abs(x[0] - 0) < 0.0001)
    precondition(abs(y[0] - -1) < 0.0001)
    var dx: [Double] = [1, 0]
    var dy: [Double] = [0, 1]
    var dc: Double = 1
    var ds: Double = 0
    _ = drot_(&n, &dx, &incx, &dy, &incy, &dc, &ds)
    precondition(abs(dx[0] - 1) < 1e-12)
}

func testBLASTrsv() {
    var n: Int32 = 2
    var uplo = CChar(76)
    var trans = CChar(78)
    var diag = CChar(78)
    var lda: Int32 = 2
    var incx: Int32 = 1
    var a: [Float] = [2, 1, 0, 2]
    var rhs: [Float] = [2, 3]
    _ = strsv_(&uplo, &trans, &diag, &n, &a, &lda, &rhs, &incx)
    precondition(abs(rhs[0] - 1) < 0.0001)
    precondition(abs(rhs[1] - 1) < 0.0001)
    var da: [Double] = [2, 1, 0, 2]
    var drhs: [Double] = [2, 3]
    _ = dtrsv_(&uplo, &trans, &diag, &n, &da, &lda, &drhs, &incx)
    precondition(abs(drhs[0] - 1) < 1e-12)
}

func testBLASSymv() {
    var n: Int32 = 2
    var uplo = CChar(76)
    var lda: Int32 = 2
    var incx: Int32 = 1
    var incy: Int32 = 1
    var alpha: Float = 1
    var beta: Float = 0
    var symA: [Float] = [2, 1, 1, 2]
    var sx: [Float] = [1, 1]
    var sy = [Float](repeating: 0, count: 2)
    _ = ssymv_(&uplo, &n, &alpha, &symA, &lda, &sx, &incx, &beta, &sy, &incy)
    precondition(abs(sy[0] - 3) < 0.0001)
    precondition(abs(sy[1] - 3) < 0.0001)
    var dalpha: Double = 1
    var dbeta: Double = 0
    var dsymA: [Double] = [2, 1, 1, 2]
    var dsx: [Double] = [1, 1]
    var dsy = [Double](repeating: 0, count: 2)
    _ = dsymv_(&uplo, &n, &dalpha, &dsymA, &lda, &dsx, &incx, &dbeta, &dsy, &incy)
    precondition(abs(dsy[0] - 3) < 1e-12)
}

func testBLASSyrk() {
    var n: Int32 = 2
    var k: Int32 = 2
    var uplo = CChar(76)
    var trans = CChar(78)
    var lda: Int32 = 2
    var ldc: Int32 = 2
    var alpha: Float = 1
    var beta: Float = 0
    var a2: [Float] = [1, 0, 0, 1]
    var cOut = [Float](repeating: 0, count: 4)
    _ = ssyrk_(&uplo, &trans, &n, &k, &alpha, &a2, &lda, &beta, &cOut, &ldc)
    precondition(abs(cOut[0] - 1) < 0.0001)
    var dalpha: Double = 1
    var dbeta: Double = 0
    var da2: [Double] = [1, 0, 0, 1]
    var dcOut = [Double](repeating: 0, count: 4)
    _ = dsyrk_(&uplo, &trans, &n, &k, &dalpha, &da2, &lda, &dbeta, &dcOut, &ldc)
    precondition(abs(dcOut[0] - 1) < 1e-12)
}

func testBLASRotg() {
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
}

func testBLASSyr() {
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
}

func testBLASTrmv() {
    var n: Int32 = 2
    var uplo = CChar(76)
    var trans = CChar(78)
    var diag = CChar(78)
    var inc: Int32 = 1
    var lda: Int32 = 2
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

func testVDSPBiquadFloatApply() {
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
    let srcCopy = src
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
    vDSP.VectorizableFloat.destroySetup(channelCount: 1, biquadSetup: setup)
}

func testVDSPBiquadDoubleApply() {
    guard let dsetup = vDSP.VectorizableDouble.makeBiquadSetup(
        channelCount: 1, coefficients: [1, 0, 0, 0, 0], sectionCount: 1
    ) else {
        preconditionFailure("double biquad setup")
    }
    var ddelays: [Double] = [0, 0]
    var ddest = [Double](repeating: 0, count: 4)
    let dsrc: [Double] = [1, 2, 3, 4]
    vDSP.VectorizableDouble.applySingle(
        source: dsrc, destination: &ddest, delays: &ddelays,
        setup: dsetup, sectionCount: 1, count: 4
    )
    precondition(ddest == dsrc)
    let dsrcCopy = dsrc
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

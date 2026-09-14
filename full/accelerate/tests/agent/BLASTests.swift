import Accelerate
import Foundation

func testBLASLevel1() {
    var n: Int32 = 3
    var a: Float = 2
    var x: [Float] = [1, 2, 3]
    var y: [Float] = [10, 20, 30]
    var incx: Int32 = 1
    var incy: Int32 = 1
    _ = saxpy_(&n, &a, &x, &incx, &y, &incy)
    precondition(y == [12, 24, 36])
    var x2: [Float] = [1, 2, 3]
    var y2: [Float] = [4, 5, 6]
    var incx2: Int32 = 1
    var incy2: Int32 = 1
    precondition(sdot_(&n, &x2, &incx2, &y2, &incy2) == 32)
    var incs: Int32 = 1
    _ = sscal_(&n, &a, &x2, &incs)
    var inca: Int32 = 1
    _ = sasum_(&n, &x, &inca)
    var incn: Int32 = 1
    _ = snrm2_(&n, &x, &incn)
    var inci: Int32 = 1
    _ = isamax_(&n, &x, &inci)
    var copy = [Float](repeating: 0, count: 3)
    var incCopySrc: Int32 = 1
    var incCopyDst: Int32 = 1
    _ = scopy_(&n, &x, &incCopySrc, &copy, &incCopyDst)
    var s1: [Float] = [1, 2, 3]
    var s2: [Float] = [4, 5, 6]
    var incSwapA: Int32 = 1
    var incSwapB: Int32 = 1
    _ = sswap_(&n, &s1, &incSwapA, &s2, &incSwapB)
    var da: Double = 2
    var dx: [Double] = [1, 2, 3]
    var dy: [Double] = [10, 20, 30]
    var dincx: Int32 = 1
    var dincy: Int32 = 1
    _ = daxpy_(&n, &da, &dx, &dincx, &dy, &dincy)
    var ddotx: Int32 = 1
    var ddoty: Int32 = 1
    _ = ddot_(&n, &dx, &ddotx, &dy, &ddoty)
    var dincs: Int32 = 1
    _ = dscal_(&n, &da, &dx, &dincs)
    var dinca: Int32 = 1
    _ = dasum_(&n, &dx, &dinca)
    var dincn: Int32 = 1
    _ = dnrm2_(&n, &dx, &dincn)
    var dinci: Int32 = 1
    _ = idamax_(&n, &dx, &dinci)
    var dcopy = [Double](repeating: 0, count: 3)
    var dincCopySrc: Int32 = 1
    var dincCopyDst: Int32 = 1
    _ = dcopy_(&n, &dx, &dincCopySrc, &dcopy, &dincCopyDst)
    var dincSwapA: Int32 = 1
    var dincSwapB: Int32 = 1
    _ = dswap_(&n, &dx, &dincSwapA, &dy, &dincSwapB)
}

func testBLASLevel23() {
    var transA = CChar(78)
    var transB = CChar(78)
    var m: Int32 = 2
    var n: Int32 = 2
    var k: Int32 = 2
    var alpha: Float = 1
    var beta: Float = 0
    var a: [Float] = [1, 0, 0, 1]
    var b: [Float] = [1, 2, 3, 4]
    var c = [Float](repeating: 0, count: 4)
    var lda: Int32 = 2
    var ldb: Int32 = 2
    var ldc: Int32 = 2
    _ = sgemm_(&transA, &transB, &m, &n, &k, &alpha, &a, &lda, &b, &ldb, &beta, &c, &ldc)
    var x: [Float] = [1, 1]
    var y = [Float](repeating: 0, count: 2)
    var incx: Int32 = 1
    var incy: Int32 = 1
    var transN = CChar(78)
    _ = sgemv_(&transN, &m, &n, &alpha, &a, &lda, &x, &incx, &beta, &y, &incy)
    var gerA = [Float](repeating: 0, count: 4)
    var gx: [Float] = [1, 2]
    var gy: [Float] = [3, 4]
    var gerIncX: Int32 = 1
    var gerIncY: Int32 = 1
    var gerLda: Int32 = 2
    _ = sger_(&m, &n, &alpha, &gx, &gerIncX, &gy, &gerIncY, &gerA, &gerLda)
    precondition(abs(gerA[0] - 3) < 0.0001)
    var dalpha: Double = 1
    var dbeta: Double = 0
    var da: [Double] = [1, 0, 0, 1]
    var db: [Double] = [1, 2, 3, 4]
    var dc = [Double](repeating: 0, count: 4)
    var dtransA = CChar(78)
    var dtransB = CChar(78)
    var dlda: Int32 = 2
    var dldb: Int32 = 2
    var dldc: Int32 = 2
    _ = dgemm_(&dtransA, &dtransB, &m, &n, &k, &dalpha, &da, &dlda, &db, &dldb, &dbeta, &dc, &dldc)
    var dx: [Double] = [1, 1]
    var dy = [Double](repeating: 0, count: 2)
    var dincx: Int32 = 1
    var dincy: Int32 = 1
    var dtransN = CChar(78)
    _ = dgemv_(&dtransN, &m, &n, &dalpha, &da, &dlda, &dx, &dincx, &dbeta, &dy, &dincy)
    var dgerA = [Double](repeating: 0, count: 4)
    var dgerX: [Double] = [1, 1]
    var dgerY: [Double] = [1, 1]
    var dgerIncX: Int32 = 1
    var dgerIncY: Int32 = 1
    var dgerLda: Int32 = 2
    _ = dger_(&m, &n, &dalpha, &dgerX, &dgerIncX, &dgerY, &dgerIncY, &dgerA, &dgerLda)
    var cy: [Float] = [0, 0, 0]
    cblas_saxpy(3, 2, [Float]([1, 2, 3]), 1, &cy, 1)
    precondition(cy == [2, 4, 6])
}

func testLAPACKSolvers() {
    var n: Int32 = 2
    var nrhs: Int32 = 1
    var lda: Int32 = 2
    var ldb: Int32 = 2
    var a: [Float] = [2, 1, 1, 3]
    var b: [Float] = [5, 8]
    var ipiv: [Int32] = [0, 0]
    var info: Int32 = 0
    _ = sgesv_(&n, &nrhs, &a, &lda, &ipiv, &b, &ldb, &info)
    precondition(info == 0)
    precondition(abs(b[0] - 1.4) < 0.001)
    precondition(abs(b[1] - 2.2) < 0.001)
    var da: [Double] = [2, 1, 1, 3]
    var db: [Double] = [5, 8]
    var dipiv: [Int32] = [0, 0]
    var dlda: Int32 = 2
    var dldb: Int32 = 2
    _ = dgesv_(&n, &nrhs, &da, &dlda, &dipiv, &db, &dldb, &info)
    var fa: [Float] = [2, 1, 1, 3]
    var mGetrf: Int32 = 2
    var nGetrf: Int32 = 2
    _ = sgetrf_(&mGetrf, &nGetrf, &fa, &lda, &ipiv, &info)
    var dmGetrf: Int32 = 2
    var dnGetrf: Int32 = 2
    _ = dgetrf_(&dmGetrf, &dnGetrf, &da, &dlda, &dipiv, &info)
    var uplo = CChar(85)
    var pa: [Float] = [2, 0, 0, 2]
    var pb: [Float] = [2, 4]
    var plda: Int32 = 2
    var pldb: Int32 = 2
    _ = sposv_(&uplo, &n, &nrhs, &pa, &plda, &pb, &pldb, &info)
    var trans = CChar(78)
    var m: Int32 = 2
    var gelsA: [Float] = [1, 0, 0, 1]
    var gelsB: [Float] = [3, 4]
    var work: [Float] = [0]
    var lwork: Int32 = 1
    var gelsLda: Int32 = 2
    var gelsLdb: Int32 = 2
    _ = sgels_(&trans, &m, &n, &nrhs, &gelsA, &gelsLda, &gelsB, &gelsLdb, &work, &lwork, &info)
}

func testCBLASRemainingConstants() {
    precondition(CblasTrans.rawValue == 112)
    precondition(CblasConjTrans.rawValue == 113)
    precondition(CblasUpper.rawValue == 121)
    precondition(CblasLower.rawValue == 122)
    precondition(CblasNonUnit.rawValue == 131)
    precondition(CblasUnit.rawValue == 132)
    precondition(CblasLeft.rawValue == 141)
    precondition(CblasRight.rawValue == 142)
}

func testCBLASSgemmRowAndColumnMajor() {
    var a: [Float] = [1, 2, 3, 4, 5, 6]
    var b: [Float] = [7, 8, 9, 10, 11, 12]
    var c = [Float](repeating: 0, count: 4)
    cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 2, 2, 3, 1, &a, 3, &b, 2, 0, &c, 2)
    precondition(c == [58, 64, 139, 154])
    var c2 = [Float](repeating: 0, count: 4)
    var aCol: [Float] = [1, 4, 2, 5, 3, 6]
    var bCol: [Float] = [7, 9, 11, 8, 10, 12]
    cblas_sgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, 2, 2, 3, 1, &aCol, 2, &bCol, 3, 0, &c2, 2)
    precondition(c2 == [58, 139, 64, 154])
    var y: [Float] = [0, 0, 0]
    cblas_saxpy(3, 2, [Float]([1, 2, 3]), 1, &y, 1)
    precondition(y == [2, 4, 6])
    precondition(cblas_sdot(3, [Float]([1, 2, 3]), 1, [Float]([4, 5, 6]), 1) == 32)
}

func testBLASComplexLevel1Float() {
    var n: Int32 = 2
    var incx: Int32 = 1
    var incy: Int32 = 1
    var alpha: [Float] = [2, 0]
    var x: [Float] = [1, 1, 2, 0]
    var y: [Float] = [0, 0, 0, 0]
    _ = caxpy_(&n, &alpha, &x, &incx, &y, &incy)
    precondition(abs(y[0] - 2) < 0.0001 && abs(y[1] - 2) < 0.0001)
    precondition(abs(y[2] - 4) < 0.0001 && abs(y[3]) < 0.0001)
    var copy = [Float](repeating: 0, count: 4)
    var incCopySrc: Int32 = 1
    var incCopyDst: Int32 = 1
    _ = ccopy_(&n, &x, &incCopySrc, &copy, &incCopyDst)
    precondition(copy[0] == 1 && copy[2] == 2)
    var dotc = [Float](repeating: 0, count: 2)
    var ydot: [Float] = [3, 0, 4, -1]
    var incDotX: Int32 = 1
    var incDotY: Int32 = 1
    cdotc_(&dotc, &n, &x, &incDotX, &ydot, &incDotY)
    precondition(abs(dotc[0] - 11) < 0.0001 && abs(dotc[1] + 5) < 0.0001)
    var dotu = [Float](repeating: 0, count: 2)
    var incDotUX: Int32 = 1
    var incDotUY: Int32 = 1
    cdotu_(&dotu, &n, &x, &incDotUX, &ydot, &incDotUY)
    precondition(abs(dotu[0] - 11) < 0.0001 && abs(dotu[1] - 1) < 0.0001)
    var scaled = x
    var iAlpha: [Float] = [0, 1]
    var incs: Int32 = 1
    _ = cscal_(&n, &iAlpha, &scaled, &incs)
    precondition(abs(scaled[0] + 1) < 0.0001 && abs(scaled[1] - 1) < 0.0001)
    var realScale: Float = 2
    var rss = x
    var incRSS: Int32 = 1
    _ = csscal_(&n, &realScale, &rss, &incRSS)
    precondition(abs(rss[0] - 2) < 0.0001 && abs(rss[2] - 4) < 0.0001)
    var s1 = x
    var s2 = ydot
    var incSwapA: Int32 = 1
    var incSwapB: Int32 = 1
    _ = cswap_(&n, &s1, &incSwapA, &s2, &incSwapB)
    precondition(s1[0] == 3 && s2[0] == 1)
    var incA: Int32 = 1
    precondition(abs(scasum_(&n, &x, &incA) - 4.0) < 0.0001)
    var incN: Int32 = 1
    precondition(abs(scnrm2_(&n, &x, &incN) - (6.0).squareRoot()) < 0.0001)
    var wide: [Float] = [1, 0, 3, 4]
    var incI: Int32 = 1
    precondition(icamax_(&n, &wide, &incI) == 1)
}

func testBLASComplexLevel1Double() {
    var n: Int32 = 2
    var incx: Int32 = 1
    var incy: Int32 = 1
    var alpha: [Double] = [2, 0]
    var x: [Double] = [1, 1, 2, 0]
    var y: [Double] = [0, 0, 0, 0]
    _ = zaxpy_(&n, &alpha, &x, &incx, &y, &incy)
    precondition(abs(y[0] - 2) < 1e-12 && abs(y[1] - 2) < 1e-12)
    var copy = [Double](repeating: 0, count: 4)
    var incCopySrc: Int32 = 1
    var incCopyDst: Int32 = 1
    _ = zcopy_(&n, &x, &incCopySrc, &copy, &incCopyDst)
    precondition(copy[2] == 2)
    var dotc = [Double](repeating: 0, count: 2)
    var ydot: [Double] = [3, 0, 4, -1]
    var incDotX: Int32 = 1
    var incDotY: Int32 = 1
    zdotc_(&dotc, &n, &x, &incDotX, &ydot, &incDotY)
    precondition(abs(dotc[0] - 11) < 1e-12 && abs(dotc[1] + 5) < 1e-12)
    var dotu = [Double](repeating: 0, count: 2)
    var incDotUX: Int32 = 1
    var incDotUY: Int32 = 1
    zdotu_(&dotu, &n, &x, &incDotUX, &ydot, &incDotUY)
    precondition(abs(dotu[0] - 11) < 1e-12 && abs(dotu[1] - 1) < 1e-12)
    var scaled = x
    var iAlpha: [Double] = [0, 1]
    var incs: Int32 = 1
    _ = zscal_(&n, &iAlpha, &scaled, &incs)
    precondition(abs(scaled[0] + 1) < 1e-12)
    var realScale: Double = 2
    var rss = x
    var incRSS: Int32 = 1
    _ = zdscal_(&n, &realScale, &rss, &incRSS)
    precondition(abs(rss[2] - 4) < 1e-12)
    var s1 = x
    var s2 = ydot
    var incSwapA: Int32 = 1
    var incSwapB: Int32 = 1
    _ = zswap_(&n, &s1, &incSwapA, &s2, &incSwapB)
    precondition(s1[0] == 3 && s2[0] == 1)
    var incA: Int32 = 1
    precondition(abs(dzasum_(&n, &x, &incA) - 4.0) < 1e-12)
    var incN: Int32 = 1
    precondition(abs(dznrm2_(&n, &x, &incN) - (6.0).squareRoot()) < 1e-12)
    var wide: [Double] = [1, 0, 3, 4]
    var incI: Int32 = 1
    precondition(izamax_(&n, &wide, &incI) == 1)
}

func testBLASComplexGemm() {
    var transA = CChar(78)
    var transB = CChar(78)
    var m: Int32 = 2
    var n: Int32 = 2
    var k: Int32 = 2
    var alpha: [Float] = [1, 0]
    var beta: [Float] = [0, 0]
    var a: [Float] = [1, 1, 3, 0, 2, 0, 4, -1]
    var b: [Float] = [1, 0, 0, 0, 0, 1, 1, 0]
    var c = [Float](repeating: 0, count: 8)
    var lda: Int32 = 2
    var ldb: Int32 = 2
    var ldc: Int32 = 2
    _ = cgemm_(&transA, &transB, &m, &n, &k, &alpha, &a, &lda, &b, &ldb, &beta, &c, &ldc)
    precondition(abs(c[0] - 1) < 0.0001 && abs(c[1] - 1) < 0.0001)
    precondition(abs(c[2] - 3) < 0.0001 && abs(c[3]) < 0.0001)
    precondition(abs(c[4] - 1) < 0.0001 && abs(c[5] - 1) < 0.0001)
    precondition(abs(c[6] - 4) < 0.0001 && abs(c[7] - 2) < 0.0001)
    var dtransA = CChar(78)
    var dtransB = CChar(78)
    var da: [Double] = [1, 1, 3, 0, 2, 0, 4, -1]
    var db: [Double] = [1, 0, 0, 0, 0, 1, 1, 0]
    var dc = [Double](repeating: 0, count: 8)
    var dalpha: [Double] = [1, 0]
    var dbeta: [Double] = [0, 0]
    var dlda: Int32 = 2
    var dldb: Int32 = 2
    var dldc: Int32 = 2
    _ = zgemm_(&dtransA, &dtransB, &m, &n, &k, &dalpha, &da, &dlda, &db, &dldb, &dbeta, &dc, &dldc)
    precondition(abs(dc[0] - 1) < 1e-12 && abs(dc[6] - 4) < 1e-12)
}

func testBLASComplexGemvHemv() {
    var trans = CChar(78)
    var m: Int32 = 2
    var n: Int32 = 2
    var alpha: [Float] = [1, 0]
    var beta: [Float] = [0, 0]
    var a: [Float] = [1, 0, 0, 0, 0, 0, 1, 0]
    var x: [Float] = [2, 1, 3, 0]
    var y = [Float](repeating: 0, count: 4)
    var lda: Int32 = 2
    var incx: Int32 = 1
    var incy: Int32 = 1
    _ = cgemv_(&trans, &m, &n, &alpha, &a, &lda, &x, &incx, &beta, &y, &incy)
    precondition(abs(y[0] - 2) < 0.0001 && abs(y[1] - 1) < 0.0001)
    precondition(abs(y[2] - 3) < 0.0001)
    var dtrans = CChar(78)
    var da: [Double] = [1, 0, 0, 0, 0, 0, 1, 0]
    var dx: [Double] = [2, 1, 3, 0]
    var dy = [Double](repeating: 0, count: 4)
    var dalpha: [Double] = [1, 0]
    var dbeta: [Double] = [0, 0]
    var dlda: Int32 = 2
    var dincx: Int32 = 1
    var dincy: Int32 = 1
    _ = zgemv_(&dtrans, &m, &n, &dalpha, &da, &dlda, &dx, &dincx, &dbeta, &dy, &dincy)
    precondition(abs(dy[0] - 2) < 1e-12)
    var gerA = [Float](repeating: 0, count: 8)
    var gx: [Float] = [1, 0, 0, 0]
    var gy: [Float] = [2, 0, 3, 0]
    var gerIncX: Int32 = 1
    var gerIncY: Int32 = 1
    var gerLda: Int32 = 2
    _ = cgeru_(&m, &n, &alpha, &gx, &gerIncX, &gy, &gerIncY, &gerA, &gerLda)
    precondition(abs(gerA[0] - 2) < 0.0001 && abs(gerA[4] - 3) < 0.0001)
    var gercA = [Float](repeating: 0, count: 8)
    var gyC: [Float] = [0, 1, 1, 0]
    var gercIncX: Int32 = 1
    var gercIncY: Int32 = 1
    var gercLda: Int32 = 2
    _ = cgerc_(&m, &n, &alpha, &gx, &gercIncX, &gyC, &gercIncY, &gercA, &gercLda)
    precondition(abs(gercA[1] + 1) < 0.0001)
    var dgerA = [Double](repeating: 0, count: 8)
    var dgx: [Double] = [1, 0, 0, 0]
    var dgy: [Double] = [2, 0, 3, 0]
    var dgerIncX: Int32 = 1
    var dgerIncY: Int32 = 1
    var dgerLda: Int32 = 2
    _ = zgeru_(&m, &n, &dalpha, &dgx, &dgerIncX, &dgy, &dgerIncY, &dgerA, &dgerLda)
    precondition(abs(dgerA[0] - 2) < 1e-12)
    var dgercA = [Double](repeating: 0, count: 8)
    var dgyC: [Double] = [0, 1, 1, 0]
    var dgercIncX: Int32 = 1
    var dgercIncY: Int32 = 1
    var dgercLda: Int32 = 2
    _ = zgerc_(&m, &n, &dalpha, &dgx, &dgercIncX, &dgyC, &dgercIncY, &dgercA, &dgercLda)
    precondition(abs(dgercA[1] + 1) < 1e-12)
    var uplo = CChar(85)
    var ha: [Float] = [1, 0, 0, 0, 2, -3, 4, 0]
    var hx: [Float] = [1, 0, 0, 1]
    var hy = [Float](repeating: 0, count: 4)
    var hlda: Int32 = 2
    var hincx: Int32 = 1
    var hincy: Int32 = 1
    _ = chemv_(&uplo, &n, &alpha, &ha, &hlda, &hx, &hincx, &beta, &hy, &hincy)
    precondition(abs(hy[0] - 4) < 0.0001 && abs(hy[1] - 2) < 0.0001)
    precondition(abs(hy[2] - 2) < 0.0001 && abs(hy[3] - 7) < 0.0001)
    var dha: [Double] = [1, 0, 0, 0, 2, -3, 4, 0]
    var dhx: [Double] = [1, 0, 0, 1]
    var dhy = [Double](repeating: 0, count: 4)
    var dhlda: Int32 = 2
    var dhincx: Int32 = 1
    var dhincy: Int32 = 1
    _ = zhemv_(&uplo, &n, &dalpha, &dha, &dhlda, &dhx, &dhincx, &dbeta, &dhy, &dhincy)
    precondition(abs(dhy[0] - 4) < 1e-12 && abs(dhy[3] - 7) < 1e-12)
}

func testBLASComplexTrmvTrsv() {
    var uplo = CChar(85)
    var transN = CChar(78)
    var transC = CChar(67)
    var diagN = CChar(78)
    var diagU = CChar(85)
    var n: Int32 = 2
    var lda: Int32 = 2
    var incx: Int32 = 1
    var a: [Float] = [1, 1, 0, 0, 2, 0, 3, -1]
    var x: [Float] = [1, 0, 0, 1]
    _ = ctrmv_(&uplo, &transN, &diagN, &n, &a, &lda, &x, &incx)
    precondition(abs(x[0] - 1) < 0.0001 && abs(x[1] - 3) < 0.0001)
    precondition(abs(x[2] - 1) < 0.0001 && abs(x[3] - 3) < 0.0001)
    var xc: [Float] = [1, 0, 0, 1]
    _ = ctrmv_(&uplo, &transC, &diagN, &n, &a, &lda, &xc, &incx)
    precondition(abs(xc[0] - 1) < 0.0001 && abs(xc[1] + 1) < 0.0001)
    precondition(abs(xc[2] - 1) < 0.0001 && abs(xc[3] - 3) < 0.0001)
    var xs: [Float] = [1, 3, 1, 3]
    _ = ctrsv_(&uplo, &transN, &diagN, &n, &a, &lda, &xs, &incx)
    precondition(abs(xs[0] - 1) < 0.0001 && abs(xs[1]) < 0.0001)
    precondition(abs(xs[2]) < 0.0001 && abs(xs[3] - 1) < 0.0001)
    var uploL = CChar(76)
    var aLow: [Float] = [1, 1, 2, 0, 0, 0, 3, -1]
    var xl: [Float] = [1, 0, 0, 1]
    _ = ctrmv_(&uploL, &transN, &diagN, &n, &aLow, &lda, &xl, &incx)
    precondition(abs(xl[0] - 1) < 0.0001 && abs(xl[1] - 1) < 0.0001)
    precondition(abs(xl[2] - 3) < 0.0001 && abs(xl[3] - 3) < 0.0001)
    var aUnit: [Float] = [99, 99, 0, 0, 2, 0, 99, 99]
    var xu: [Float] = [1, 0, 0, 1]
    _ = ctrmv_(&uplo, &transN, &diagU, &n, &aUnit, &lda, &xu, &incx)
    precondition(abs(xu[0] - 1) < 0.0001 && abs(xu[1] - 2) < 0.0001)
    precondition(abs(xu[2]) < 0.0001 && abs(xu[3] - 1) < 0.0001)
    var n3: Int32 = 3
    var lda3: Int32 = 3
    var a3: [Float] = [
        2, 0, 0, 0, 0, 0,
        1, 0, 2, 0, 0, 0,
        0, 0, 1, 0, 2, 0
    ]
    var x3: [Float] = [1, 0, 1, 0, 1, 0]
    _ = ctrmv_(&uplo, &transN, &diagN, &n3, &a3, &lda3, &x3, &incx)
    precondition(abs(x3[0] - 3) < 0.0001 && abs(x3[2] - 3) < 0.0001 && abs(x3[4] - 2) < 0.0001)
    var b3 = x3
    _ = ctrsv_(&uplo, &transN, &diagN, &n3, &a3, &lda3, &b3, &incx)
    precondition(abs(b3[0] - 1) < 0.0001 && abs(b3[2] - 1) < 0.0001 && abs(b3[4] - 1) < 0.0001)
    var da: [Double] = [1, 1, 0, 0, 2, 0, 3, -1]
    var dx: [Double] = [1, 0, 0, 1]
    _ = ztrmv_(&uplo, &transN, &diagN, &n, &da, &lda, &dx, &incx)
    precondition(abs(dx[0] - 1) < 1e-12 && abs(dx[1] - 3) < 1e-12)
    var dxs: [Double] = [1, 3, 1, 3]
    _ = ztrsv_(&uplo, &transN, &diagN, &n, &da, &lda, &dxs, &incx)
    precondition(abs(dxs[0] - 1) < 1e-12 && abs(dxs[3] - 1) < 1e-12)
}

func testBLASComplexTrmmTrsm() {
    var sideL = CChar(76)
    var sideR = CChar(82)
    var uplo = CChar(85)
    var transN = CChar(78)
    var transC = CChar(67)
    var diagN = CChar(78)
    var m: Int32 = 2
    var n: Int32 = 2
    var lda: Int32 = 2
    var ldb: Int32 = 2
    var alpha: [Float] = [1, 0]
    var a: [Float] = [1, 1, 0, 0, 2, 0, 3, -1]
    var b: [Float] = [1, 0, 0, 0, 0, 0, 1, 0]
    _ = ctrmm_(&sideL, &uplo, &transN, &diagN, &m, &n, &alpha, &a, &lda, &b, &ldb)
    precondition(abs(b[0] - 1) < 0.0001 && abs(b[1] - 1) < 0.0001)
    precondition(abs(b[4] - 2) < 0.0001 && abs(b[6] - 3) < 0.0001 && abs(b[7] + 1) < 0.0001)
    var bC: [Float] = [1, 0, 0, 0, 0, 0, 1, 0]
    _ = ctrmm_(&sideL, &uplo, &transC, &diagN, &m, &n, &alpha, &a, &lda, &bC, &ldb)
    precondition(abs(bC[0] - 1) < 0.0001 && abs(bC[1] + 1) < 0.0001)
    precondition(abs(bC[2] - 2) < 0.0001 && abs(bC[6] - 3) < 0.0001 && abs(bC[7] - 1) < 0.0001)
    var bR: [Float] = [1, 0, 0, 0, 0, 0, 1, 0]
    _ = ctrmm_(&sideR, &uplo, &transN, &diagN, &m, &n, &alpha, &a, &lda, &bR, &ldb)
    precondition(abs(bR[0] - 1) < 0.0001 && abs(bR[6] - 3) < 0.0001)
    var bS = b
    _ = ctrsm_(&sideL, &uplo, &transN, &diagN, &m, &n, &alpha, &a, &lda, &bS, &ldb)
    precondition(abs(bS[0] - 1) < 0.0001 && abs(bS[1]) < 0.0001)
    precondition(abs(bS[2]) < 0.0001 && abs(bS[3]) < 0.0001)
    precondition(abs(bS[4]) < 0.0001 && abs(bS[6] - 1) < 0.0001)
    var da: [Double] = [1, 1, 0, 0, 2, 0, 3, -1]
    var db: [Double] = [1, 0, 0, 0, 0, 0, 1, 0]
    var dalpha: [Double] = [1, 0]
    _ = ztrmm_(&sideL, &uplo, &transN, &diagN, &m, &n, &dalpha, &da, &lda, &db, &ldb)
    precondition(abs(db[0] - 1) < 1e-12 && abs(db[6] - 3) < 1e-12)
    _ = ztrsm_(&sideL, &uplo, &transN, &diagN, &m, &n, &dalpha, &da, &lda, &db, &ldb)
    precondition(abs(db[0] - 1) < 1e-12 && abs(db[6] - 1) < 1e-12)
}

func testBLASComplexHemmHerkCher() {
    var sideL = CChar(76)
    var sideR = CChar(82)
    var uplo = CChar(85)
    var transN = CChar(78)
    var transC = CChar(67)
    var m: Int32 = 2
    var n: Int32 = 2
    var k1: Int32 = 1
    var lda: Int32 = 2
    var ldb: Int32 = 2
    var ldc: Int32 = 2
    var lda1: Int32 = 1
    var incx: Int32 = 1
    var alpha: [Float] = [1, 0]
    var beta: [Float] = [0, 0]
    var alphaR: Float = 1
    var betaR: Float = 0
    var aH: [Float] = [1, 0, 0, 0, 2, -3, 4, 0]
    var b: [Float] = [1, 0, 0, 0, 1, 0, 0, 1]
    var c = [Float](repeating: 0, count: 8)
    _ = chemm_(&sideL, &uplo, &m, &n, &alpha, &aH, &lda, &b, &ldb, &beta, &c, &ldc)
    precondition(abs(c[0] - 1) < 0.0001 && abs(c[1]) < 0.0001)
    precondition(abs(c[2] - 2) < 0.0001 && abs(c[3] - 3) < 0.0001)
    precondition(abs(c[4] - 4) < 0.0001 && abs(c[5] - 2) < 0.0001)
    precondition(abs(c[6] - 2) < 0.0001 && abs(c[7] - 7) < 0.0001)
    var cR = [Float](repeating: 0, count: 8)
    _ = chemm_(&sideR, &uplo, &m, &n, &alpha, &aH, &lda, &b, &ldb, &beta, &cR, &ldc)
    precondition(abs(cR[0] - 3) < 0.0001 && abs(cR[1] - 3) < 0.0001)
    precondition(abs(cR[2] + 3) < 0.0001 && abs(cR[3] - 2) < 0.0001)
    var aI: [Float] = [1, 0, 0, 0, 0, 0, 1, 0]
    var xh: [Float] = [1, 0, 0, 1]
    _ = cher_(&uplo, &n, &alphaR, &xh, &incx, &aI, &lda)
    precondition(abs(aI[0] - 2) < 0.0001 && abs(aI[1]) < 0.0001)
    precondition(abs(aI[4]) < 0.0001 && abs(aI[5] + 1) < 0.0001)
    precondition(abs(aI[6] - 2) < 0.0001)
    var aCol: [Float] = [1, 0, 0, 1]
    var ck = [Float](repeating: 0, count: 8)
    _ = cherk_(&uplo, &transN, &n, &k1, &alphaR, &aCol, &lda, &betaR, &ck, &ldc)
    precondition(abs(ck[0] - 1) < 0.0001 && abs(ck[5] + 1) < 0.0001 && abs(ck[6] - 1) < 0.0001)
    var aRow: [Float] = [1, 0, 0, 1]
    var ckC = [Float](repeating: 0, count: 8)
    _ = cherk_(&uplo, &transC, &n, &k1, &alphaR, &aRow, &lda1, &betaR, &ckC, &ldc)
    precondition(abs(ckC[0] - 1) < 0.0001 && abs(ckC[5] - 1) < 0.0001 && abs(ckC[6] - 1) < 0.0001)
    var daH: [Double] = [1, 0, 0, 0, 2, -3, 4, 0]
    var db: [Double] = [1, 0, 0, 0, 1, 0, 0, 1]
    var dc = [Double](repeating: 0, count: 8)
    var dalpha: [Double] = [1, 0]
    var dbeta: [Double] = [0, 0]
    _ = zhemm_(&sideL, &uplo, &m, &n, &dalpha, &daH, &lda, &db, &ldb, &dbeta, &dc, &ldc)
    precondition(abs(dc[0] - 1) < 1e-12 && abs(dc[7] - 7) < 1e-12)
    var daI: [Double] = [1, 0, 0, 0, 0, 0, 1, 0]
    var dxh: [Double] = [1, 0, 0, 1]
    var dAlphaR: Double = 1
    _ = zher_(&uplo, &n, &dAlphaR, &dxh, &incx, &daI, &lda)
    precondition(abs(daI[0] - 2) < 1e-12 && abs(daI[5] + 1) < 1e-12)
    var daCol: [Double] = [1, 0, 0, 1]
    var dck = [Double](repeating: 0, count: 8)
    var dBetaR: Double = 0
    _ = zherk_(&uplo, &transN, &n, &k1, &dAlphaR, &daCol, &lda, &dBetaR, &dck, &ldc)
    precondition(abs(dck[0] - 1) < 1e-12 && abs(dck[5] + 1) < 1e-12)
}

func testBLASComplexCher2SymmSyrk() {
    var sideL = CChar(76)
    var uplo = CChar(85)
    var transN = CChar(78)
    var n: Int32 = 2
    var m: Int32 = 2
    var k1: Int32 = 1
    var lda: Int32 = 2
    var ldb: Int32 = 2
    var ldc: Int32 = 2
    var incx: Int32 = 1
    var incy: Int32 = 1
    var alpha: [Float] = [1, 0]
    var beta: [Float] = [0, 0]
    var betaR: Float = 0
    var aH = [Float](repeating: 0, count: 8)
    var x2: [Float] = [1, 0, 0, 1]
    var y2: [Float] = [0, 1, 1, 0]
    _ = cher2_(&uplo, &n, &alpha, &x2, &incx, &y2, &incy, &aH, &lda)
    precondition(abs(aH[0]) < 0.0001 && abs(aH[4] - 2) < 0.0001 && abs(aH[6]) < 0.0001)
    var aA: [Float] = [1, 0, 0, 1]
    var bB: [Float] = [0, 1, 1, 0]
    var c2k = [Float](repeating: 0, count: 8)
    _ = cher2k_(&uplo, &transN, &n, &k1, &alpha, &aA, &lda, &bB, &ldb, &betaR, &c2k, &ldc)
    precondition(abs(c2k[0]) < 0.0001 && abs(c2k[4] - 2) < 0.0001)
    var aS: [Float] = [1, 0, 0, 0, 2, 1, 3, 0]
    var b: [Float] = [1, 0, 0, 0, 1, 0, 0, 1]
    var cS = [Float](repeating: 0, count: 8)
    _ = csymm_(&sideL, &uplo, &m, &n, &alpha, &aS, &lda, &b, &ldb, &beta, &cS, &ldc)
    precondition(abs(cS[0] - 1) < 0.0001 && abs(cS[2] - 2) < 0.0001 && abs(cS[3] - 1) < 0.0001)
    precondition(abs(cS[4]) < 0.0001 && abs(cS[5] - 2) < 0.0001)
    precondition(abs(cS[6] - 2) < 0.0001 && abs(cS[7] - 4) < 0.0001)
    var aCol: [Float] = [1, 0, 0, 1]
    var cK = [Float](repeating: 0, count: 8)
    _ = csyrk_(&uplo, &transN, &n, &k1, &alpha, &aCol, &lda, &beta, &cK, &ldc)
    precondition(abs(cK[0] - 1) < 0.0001 && abs(cK[5] - 1) < 0.0001 && abs(cK[6] + 1) < 0.0001)
    var c2s = [Float](repeating: 0, count: 8)
    _ = csyr2k_(&uplo, &transN, &n, &k1, &alpha, &aA, &lda, &bB, &ldb, &beta, &c2s, &ldc)
    precondition(abs(c2s[1] - 2) < 0.0001 && abs(c2s[7] - 2) < 0.0001)
    var dalpha: [Double] = [1, 0]
    var dbeta: [Double] = [0, 0]
    var dBetaR: Double = 0
    var daH = [Double](repeating: 0, count: 8)
    var dx2: [Double] = [1, 0, 0, 1]
    var dy2: [Double] = [0, 1, 1, 0]
    _ = zher2_(&uplo, &n, &dalpha, &dx2, &incx, &dy2, &incy, &daH, &lda)
    precondition(abs(daH[4] - 2) < 1e-12)
    var daA: [Double] = [1, 0, 0, 1]
    var dbB: [Double] = [0, 1, 1, 0]
    var dc2k = [Double](repeating: 0, count: 8)
    _ = zher2k_(&uplo, &transN, &n, &k1, &dalpha, &daA, &lda, &dbB, &ldb, &dBetaR, &dc2k, &ldc)
    precondition(abs(dc2k[4] - 2) < 1e-12)
    var daS: [Double] = [1, 0, 0, 0, 2, 1, 3, 0]
    var db: [Double] = [1, 0, 0, 0, 1, 0, 0, 1]
    var dcS = [Double](repeating: 0, count: 8)
    _ = zsymm_(&sideL, &uplo, &m, &n, &dalpha, &daS, &lda, &db, &ldb, &dbeta, &dcS, &ldc)
    precondition(abs(dcS[6] - 2) < 1e-12 && abs(dcS[7] - 4) < 1e-12)
    var daCol: [Double] = [1, 0, 0, 1]
    var dcK = [Double](repeating: 0, count: 8)
    _ = zsyrk_(&uplo, &transN, &n, &k1, &dalpha, &daCol, &lda, &dbeta, &dcK, &ldc)
    precondition(abs(dcK[6] + 1) < 1e-12)
    var dc2s = [Double](repeating: 0, count: 8)
    _ = zsyr2k_(&uplo, &transN, &n, &k1, &dalpha, &daA, &lda, &dbB, &ldb, &dbeta, &dc2s, &ldc)
    precondition(abs(dc2s[1] - 2) < 1e-12 && abs(dc2s[7] - 2) < 1e-12)
}

func testBLASComplexRotgRot() {
    var n: Int32 = 2
    var incx: Int32 = 1
    var incy: Int32 = 1
    var ca: [Float] = [3, 4]
    var cb: [Float] = [0, 5]
    var c: Float = 0
    var cs: [Float] = [0, 0]
    _ = crotg_(&ca, &cb, &c, &cs)
    precondition(abs(ca[0] - 4.2426405) < 0.0001 && abs(ca[1] - 5.656854) < 0.0001)
    precondition(abs(c - 0.70710677) < 0.0001)
    precondition(abs(cs[0] - 0.565685) < 0.0001 && abs(cs[1] + 0.424264) < 0.0001)
    var ca0: [Float] = [0, 0]
    var cb0: [Float] = [3, 4]
    var c0: Float = 99
    var s0: [Float] = [9, 9]
    _ = crotg_(&ca0, &cb0, &c0, &s0)
    precondition(abs(c0) < 0.0001 && abs(s0[0] - 1) < 0.0001 && abs(s0[1]) < 0.0001)
    precondition(abs(ca0[0] - 3) < 0.0001 && abs(ca0[1] - 4) < 0.0001)
    var cx: [Float] = [1, 2, 3, 4]
    var cy: [Float] = [5, 6, 7, 8]
    var cval: Float = 0.6
    var sval: Float = 0.8
    _ = csrot_(&n, &cx, &incx, &cy, &incy, &cval, &sval)
    precondition(abs(cx[0] - 4.6) < 0.0001 && abs(cx[1] - 6) < 0.0001)
    precondition(abs(cx[2] - 7.4) < 0.0001 && abs(cx[3] - 8.8) < 0.0001)
    precondition(abs(cy[0] - 2.2) < 0.0001 && abs(cy[1] - 2) < 0.0001)
    precondition(abs(cy[2] - 1.8) < 0.0001 && abs(cy[3] - 1.6) < 0.0001)
    var zca: [Double] = [3, 4]
    var zcb: [Double] = [0, 5]
    var zc: Double = 0
    var zcs: [Double] = [0, 0]
    _ = zrotg_(&zca, &zcb, &zc, &zcs)
    precondition(abs(zca[0] - 4.242640687119285) < 1e-9)
    precondition(abs(zc - 0.7071067811865475) < 1e-12)
    var dzx: [Double] = [1, 2, 3, 4]
    var dzy: [Double] = [5, 6, 7, 8]
    var dcval: Double = 0.6
    var dsval: Double = 0.8
    _ = zdrot_(&n, &dzx, &incx, &dzy, &incy, &dcval, &dsval)
    precondition(abs(dzx[0] - 4.6) < 1e-12 && abs(dzy[0] - 2.2) < 1e-12)
}

func testBLASComplexPackedHpmv() {
    var uplo = CChar(85)
    var uploL = CChar(76)
    var n: Int32 = 2
    var alpha: [Float] = [1, 0]
    var beta: [Float] = [0, 0]
    var incx: Int32 = 1
    var incy: Int32 = 1
    var ap: [Float] = [1, 0, 2, -3, 4, 0]
    var x: [Float] = [1, 0, 0, 1]
    var y = [Float](repeating: 0, count: 4)
    _ = chpmv_(&uplo, &n, &alpha, &ap, &x, &incx, &beta, &y, &incy)
    precondition(abs(y[0] - 4) < 0.0001 && abs(y[1] - 2) < 0.0001)
    precondition(abs(y[2] - 2) < 0.0001 && abs(y[3] - 7) < 0.0001)
    var apL: [Float] = [1, 0, 2, 3, 4, 0]
    var yL = [Float](repeating: 0, count: 4)
    _ = chpmv_(&uploL, &n, &alpha, &apL, &x, &incx, &beta, &yL, &incy)
    precondition(abs(yL[0] - 4) < 0.0001 && abs(yL[3] - 7) < 0.0001)
    var n3: Int32 = 3
    var ap3: [Float] = [2, 0, 1, -1, 3, 0, 0, 0, 1, 0, 4, 0]
    var x3: [Float] = [1, 0, 1, 0, 1, 0]
    var y3 = [Float](repeating: 0, count: 6)
    _ = chpmv_(&uplo, &n3, &alpha, &ap3, &x3, &incx, &beta, &y3, &incy)
    precondition(abs(y3[0] - 3) < 0.0001 && abs(y3[1] + 1) < 0.0001)
    precondition(abs(y3[2] - 5) < 0.0001 && abs(y3[3] - 1) < 0.0001)
    precondition(abs(y3[4] - 5) < 0.0001)
    var dalpha: [Double] = [1, 0]
    var dbeta: [Double] = [0, 0]
    var dap: [Double] = [1, 0, 2, -3, 4, 0]
    var dx: [Double] = [1, 0, 0, 1]
    var dy = [Double](repeating: 0, count: 4)
    _ = zhpmv_(&uplo, &n, &dalpha, &dap, &dx, &incx, &dbeta, &dy, &incy)
    precondition(abs(dy[0] - 4) < 1e-12 && abs(dy[3] - 7) < 1e-12)
}

func testBLASComplexPackedHpr() {
    var uplo = CChar(85)
    var uploL = CChar(76)
    var n: Int32 = 2
    var alphaR: Float = 1
    var incx: Int32 = 1
    var incy: Int32 = 1
    var ap: [Float] = [1, 0, 0, 0, 1, 0]
    var x: [Float] = [1, 0, 0, 1]
    _ = chpr_(&uplo, &n, &alphaR, &x, &incx, &ap)
    precondition(abs(ap[0] - 2) < 0.0001 && abs(ap[1]) < 0.0001)
    precondition(abs(ap[2]) < 0.0001 && abs(ap[3] + 1) < 0.0001)
    precondition(abs(ap[4] - 2) < 0.0001)
    var apL: [Float] = [1, 0, 0, 0, 1, 0]
    _ = chpr_(&uploL, &n, &alphaR, &x, &incx, &apL)
    precondition(abs(apL[0] - 2) < 0.0001 && abs(apL[3] - 1) < 0.0001 && abs(apL[4] - 2) < 0.0001)
    var alpha: [Float] = [1, 0]
    var y: [Float] = [0, 1, 1, 0]
    var ap2 = [Float](repeating: 0, count: 6)
    _ = chpr2_(&uplo, &n, &alpha, &x, &incx, &y, &incy, &ap2)
    precondition(abs(ap2[0]) < 0.0001 && abs(ap2[2] - 2) < 0.0001 && abs(ap2[4]) < 0.0001)
    var dAlphaR: Double = 1
    var dap: [Double] = [1, 0, 0, 0, 1, 0]
    var dx: [Double] = [1, 0, 0, 1]
    _ = zhpr_(&uplo, &n, &dAlphaR, &dx, &incx, &dap)
    precondition(abs(dap[0] - 2) < 1e-12 && abs(dap[3] + 1) < 1e-12)
    var dalpha: [Double] = [1, 0]
    var dy: [Double] = [0, 1, 1, 0]
    var dap2 = [Double](repeating: 0, count: 6)
    _ = zhpr2_(&uplo, &n, &dalpha, &dx, &incx, &dy, &incy, &dap2)
    precondition(abs(dap2[2] - 2) < 1e-12)
}

func testBLASComplexPackedTpmvTpsv() {
    var uplo = CChar(85)
    var uploL = CChar(76)
    var transN = CChar(78)
    var transC = CChar(67)
    var transT = CChar(84)
    var diagN = CChar(78)
    var diagU = CChar(85)
    var n: Int32 = 2
    var incx: Int32 = 1
    var ap: [Float] = [1, 1, 2, 0, 3, -1]
    var x: [Float] = [1, 0, 0, 1]
    _ = ctpmv_(&uplo, &transN, &diagN, &n, &ap, &x, &incx)
    precondition(abs(x[0] - 1) < 0.0001 && abs(x[1] - 3) < 0.0001)
    precondition(abs(x[2] - 1) < 0.0001 && abs(x[3] - 3) < 0.0001)
    var xc: [Float] = [1, 0, 0, 1]
    _ = ctpmv_(&uplo, &transC, &diagN, &n, &ap, &xc, &incx)
    precondition(abs(xc[0] - 1) < 0.0001 && abs(xc[1] + 1) < 0.0001)
    precondition(abs(xc[2] - 1) < 0.0001 && abs(xc[3] - 3) < 0.0001)
    var xt: [Float] = [1, 0, 0, 1]
    _ = ctpmv_(&uplo, &transT, &diagN, &n, &ap, &xt, &incx)
    precondition(abs(xt[0] - 1) < 0.0001 && abs(xt[1] - 1) < 0.0001)
    precondition(abs(xt[2] - 3) < 0.0001 && abs(xt[3] - 3) < 0.0001)
    var xl: [Float] = [1, 0, 0, 1]
    _ = ctpmv_(&uploL, &transN, &diagN, &n, &ap, &xl, &incx)
    precondition(abs(xl[0] - 1) < 0.0001 && abs(xl[1] - 1) < 0.0001)
    precondition(abs(xl[2] - 3) < 0.0001 && abs(xl[3] - 3) < 0.0001)
    var apU: [Float] = [99, 99, 2, 0, 99, 99]
    var xu: [Float] = [1, 0, 0, 1]
    _ = ctpmv_(&uplo, &transN, &diagU, &n, &apU, &xu, &incx)
    precondition(abs(xu[0] - 1) < 0.0001 && abs(xu[1] - 2) < 0.0001)
    precondition(abs(xu[2]) < 0.0001 && abs(xu[3] - 1) < 0.0001)
    var xs: [Float] = [1, 3, 1, 3]
    _ = ctpsv_(&uplo, &transN, &diagN, &n, &ap, &xs, &incx)
    precondition(abs(xs[0] - 1) < 0.0001 && abs(xs[1]) < 0.0001)
    precondition(abs(xs[2]) < 0.0001 && abs(xs[3] - 1) < 0.0001)
    var n3: Int32 = 3
    var ap3: [Float] = [2, 0, 1, 0, 2, 0, 0, 0, 1, 0, 2, 0]
    var x3: [Float] = [1, 0, 1, 0, 1, 0]
    _ = ctpmv_(&uplo, &transN, &diagN, &n3, &ap3, &x3, &incx)
    precondition(abs(x3[0] - 3) < 0.0001 && abs(x3[2] - 3) < 0.0001 && abs(x3[4] - 2) < 0.0001)
    var b3 = x3
    _ = ctpsv_(&uplo, &transN, &diagN, &n3, &ap3, &b3, &incx)
    precondition(abs(b3[0] - 1) < 0.0001 && abs(b3[2] - 1) < 0.0001 && abs(b3[4] - 1) < 0.0001)
    var dap: [Double] = [1, 1, 2, 0, 3, -1]
    var dx: [Double] = [1, 0, 0, 1]
    _ = ztpmv_(&uplo, &transN, &diagN, &n, &dap, &dx, &incx)
    precondition(abs(dx[0] - 1) < 1e-12 && abs(dx[1] - 3) < 1e-12)
    var dxs: [Double] = [1, 3, 1, 3]
    _ = ztpsv_(&uplo, &transN, &diagN, &n, &dap, &dxs, &incx)
    precondition(abs(dxs[0] - 1) < 1e-12 && abs(dxs[3] - 1) < 1e-12)
}

func testBLASComplexBandedGbmvHbmv() {
    var trans = CChar(78)
    var transT = CChar(84)
    var transC = CChar(67)
    var m: Int32 = 2
    var n: Int32 = 2
    var kl: Int32 = 1
    var ku: Int32 = 1
    var alpha: [Float] = [1, 0]
    var beta: [Float] = [0, 0]
    var lda: Int32 = 3
    var incx: Int32 = 1
    var incy: Int32 = 1
    var a: [Float] = [9, 9, 1, 0, 3, 0, 2, 0, 4, 0, 9, 9]
    var x: [Float] = [1, 0, 1, 0]
    var y = [Float](repeating: 0, count: 4)
    _ = cgbmv_(&trans, &m, &n, &kl, &ku, &alpha, &a, &lda, &x, &incx, &beta, &y, &incy)
    precondition(abs(y[0] - 3) < 0.0001 && abs(y[2] - 7) < 0.0001)
    var yT = [Float](repeating: 0, count: 4)
    _ = cgbmv_(&transT, &m, &n, &kl, &ku, &alpha, &a, &lda, &x, &incx, &beta, &yT, &incy)
    precondition(abs(yT[0] - 4) < 0.0001 && abs(yT[2] - 6) < 0.0001)
    var aC: [Float] = [9, 9, 1, 1, 3, 0, 2, 0, 4, -1, 9, 9]
    var yC = [Float](repeating: 0, count: 4)
    _ = cgbmv_(&transC, &m, &n, &kl, &ku, &alpha, &aC, &lda, &x, &incx, &beta, &yC, &incy)
    precondition(abs(yC[0] - 4) < 0.0001 && abs(yC[1] + 1) < 0.0001)
    precondition(abs(yC[2] - 6) < 0.0001 && abs(yC[3] - 1) < 0.0001)
    var m3: Int32 = 3
    var n3: Int32 = 3
    var a3: [Float] = [9, 9, 2, 0, 1, 0, 1, 0, 2, 0, 1, 0, 1, 0, 2, 0, 9, 9]
    var x3: [Float] = [1, 0, 1, 0, 1, 0]
    var y3 = [Float](repeating: 0, count: 6)
    _ = cgbmv_(&trans, &m3, &n3, &kl, &ku, &alpha, &a3, &lda, &x3, &incx, &beta, &y3, &incy)
    precondition(abs(y3[0] - 3) < 0.0001 && abs(y3[2] - 4) < 0.0001 && abs(y3[4] - 3) < 0.0001)
    var uplo = CChar(85)
    var uploL = CChar(76)
    var k: Int32 = 1
    var hlda: Int32 = 2
    var ha: [Float] = [9, 9, 1, 0, 2, -3, 4, 0]
    var hx: [Float] = [1, 0, 0, 1]
    var hy = [Float](repeating: 0, count: 4)
    _ = chbmv_(&uplo, &n, &k, &alpha, &ha, &hlda, &hx, &incx, &beta, &hy, &incy)
    precondition(abs(hy[0] - 4) < 0.0001 && abs(hy[1] - 2) < 0.0001)
    precondition(abs(hy[2] - 2) < 0.0001 && abs(hy[3] - 7) < 0.0001)
    var haL: [Float] = [1, 0, 2, 3, 4, 0, 9, 9]
    var hyL = [Float](repeating: 0, count: 4)
    _ = chbmv_(&uploL, &n, &k, &alpha, &haL, &hlda, &hx, &incx, &beta, &hyL, &incy)
    precondition(abs(hyL[0] - 4) < 0.0001 && abs(hyL[3] - 7) < 0.0001)
    var ha3: [Float] = [9, 9, 2, 0, 1, -1, 3, 0, 1, 0, 4, 0]
    var hy3 = [Float](repeating: 0, count: 6)
    _ = chbmv_(&uplo, &n3, &k, &alpha, &ha3, &hlda, &x3, &incx, &beta, &hy3, &incy)
    precondition(abs(hy3[0] - 3) < 0.0001 && abs(hy3[1] + 1) < 0.0001)
    precondition(abs(hy3[2] - 5) < 0.0001 && abs(hy3[3] - 1) < 0.0001)
    precondition(abs(hy3[4] - 5) < 0.0001)
    var dalpha: [Double] = [1, 0]
    var dbeta: [Double] = [0, 0]
    var da: [Double] = [9, 9, 1, 0, 3, 0, 2, 0, 4, 0, 9, 9]
    var dx: [Double] = [1, 0, 1, 0]
    var dy = [Double](repeating: 0, count: 4)
    _ = zgbmv_(&trans, &m, &n, &kl, &ku, &dalpha, &da, &lda, &dx, &incx, &dbeta, &dy, &incy)
    precondition(abs(dy[0] - 3) < 1e-12 && abs(dy[2] - 7) < 1e-12)
    var dha: [Double] = [9, 9, 1, 0, 2, -3, 4, 0]
    var dhx: [Double] = [1, 0, 0, 1]
    var dhy = [Double](repeating: 0, count: 4)
    _ = zhbmv_(&uplo, &n, &k, &dalpha, &dha, &hlda, &dhx, &incx, &dbeta, &dhy, &incy)
    precondition(abs(dhy[0] - 4) < 1e-12 && abs(dhy[3] - 7) < 1e-12)
}

func testBLASComplexBandedTbmvTbsv() {
    var uplo = CChar(85)
    var uploL = CChar(76)
    var transN = CChar(78)
    var transC = CChar(67)
    var diagN = CChar(78)
    var n: Int32 = 2
    var k: Int32 = 1
    var lda: Int32 = 2
    var incx: Int32 = 1
    var a: [Float] = [9, 9, 1, 1, 2, 0, 3, -1]
    var x: [Float] = [1, 0, 0, 1]
    _ = ctbmv_(&uplo, &transN, &diagN, &n, &k, &a, &lda, &x, &incx)
    precondition(abs(x[0] - 1) < 0.0001 && abs(x[1] - 3) < 0.0001)
    precondition(abs(x[2] - 1) < 0.0001 && abs(x[3] - 3) < 0.0001)
    var xc: [Float] = [1, 0, 0, 1]
    _ = ctbmv_(&uplo, &transC, &diagN, &n, &k, &a, &lda, &xc, &incx)
    precondition(abs(xc[0] - 1) < 0.0001 && abs(xc[1] + 1) < 0.0001)
    precondition(abs(xc[2] - 1) < 0.0001 && abs(xc[3] - 3) < 0.0001)
    var aL: [Float] = [1, 1, 2, 0, 3, -1, 9, 9]
    var xl: [Float] = [1, 0, 0, 1]
    _ = ctbmv_(&uploL, &transN, &diagN, &n, &k, &aL, &lda, &xl, &incx)
    precondition(abs(xl[0] - 1) < 0.0001 && abs(xl[1] - 1) < 0.0001)
    precondition(abs(xl[2] - 3) < 0.0001 && abs(xl[3] - 3) < 0.0001)
    var xs: [Float] = [1, 3, 1, 3]
    _ = ctbsv_(&uplo, &transN, &diagN, &n, &k, &a, &lda, &xs, &incx)
    precondition(abs(xs[0] - 1) < 0.0001 && abs(xs[1]) < 0.0001)
    precondition(abs(xs[2]) < 0.0001 && abs(xs[3] - 1) < 0.0001)
    var n3: Int32 = 3
    var a3: [Float] = [9, 9, 2, 0, 1, 0, 2, 0, 1, 0, 2, 0]
    var x3: [Float] = [1, 0, 1, 0, 1, 0]
    _ = ctbmv_(&uplo, &transN, &diagN, &n3, &k, &a3, &lda, &x3, &incx)
    precondition(abs(x3[0] - 3) < 0.0001 && abs(x3[2] - 3) < 0.0001 && abs(x3[4] - 2) < 0.0001)
    var b3 = x3
    _ = ctbsv_(&uplo, &transN, &diagN, &n3, &k, &a3, &lda, &b3, &incx)
    precondition(abs(b3[0] - 1) < 0.0001 && abs(b3[2] - 1) < 0.0001 && abs(b3[4] - 1) < 0.0001)
    var da: [Double] = [9, 9, 1, 1, 2, 0, 3, -1]
    var dx: [Double] = [1, 0, 0, 1]
    _ = ztbmv_(&uplo, &transN, &diagN, &n, &k, &da, &lda, &dx, &incx)
    precondition(abs(dx[0] - 1) < 1e-12 && abs(dx[1] - 3) < 1e-12)
    var dxs: [Double] = [1, 3, 1, 3]
    _ = ztbsv_(&uplo, &transN, &diagN, &n, &k, &da, &lda, &dxs, &incx)
    precondition(abs(dxs[0] - 1) < 1e-12 && abs(dxs[3] - 1) < 1e-12)
}

func testBLASPackedSpmvSpr() {
    var uplo = CChar(85)
    var uploL = CChar(76)
    var n: Int32 = 2
    var alpha: Float = 1
    var beta: Float = 0
    var incx: Int32 = 1
    var incy: Int32 = 1
    var ap: [Float] = [1, 2, 3]
    var x: [Float] = [1, 1]
    var y = [Float](repeating: 0, count: 2)
    _ = sspmv_(&uplo, &n, &alpha, &ap, &x, &incx, &beta, &y, &incy)
    precondition(abs(y[0] - 3) < 0.0001 && abs(y[1] - 5) < 0.0001)
    var yL = [Float](repeating: 0, count: 2)
    _ = sspmv_(&uploL, &n, &alpha, &ap, &x, &incx, &beta, &yL, &incy)
    precondition(abs(yL[0] - 3) < 0.0001 && abs(yL[1] - 5) < 0.0001)
    var n3: Int32 = 3
    var ap3: [Float] = [2, 1, 2, 0, 1, 2]
    var x3: [Float] = [1, 1, 1]
    var y3 = [Float](repeating: 0, count: 3)
    _ = sspmv_(&uplo, &n3, &alpha, &ap3, &x3, &incx, &beta, &y3, &incy)
    precondition(abs(y3[0] - 3) < 0.0001 && abs(y3[1] - 4) < 0.0001 && abs(y3[2] - 3) < 0.0001)
    var apR: [Float] = [1, 0, 1]
    var xr: [Float] = [1, 2]
    _ = sspr_(&uplo, &n, &alpha, &xr, &incx, &apR)
    precondition(abs(apR[0] - 2) < 0.0001 && abs(apR[1] - 2) < 0.0001 && abs(apR[2] - 5) < 0.0001)
    var apRL: [Float] = [1, 0, 1]
    _ = sspr_(&uploL, &n, &alpha, &xr, &incx, &apRL)
    precondition(abs(apRL[0] - 2) < 0.0001 && abs(apRL[2] - 5) < 0.0001)
    var ap2 = [Float](repeating: 0, count: 3)
    var x2: [Float] = [1, 0]
    var y2: [Float] = [0, 1]
    _ = sspr2_(&uplo, &n, &alpha, &x2, &incx, &y2, &incy, &ap2)
    precondition(abs(ap2[0]) < 0.0001 && abs(ap2[1] - 1) < 0.0001 && abs(ap2[2]) < 0.0001)
    var dalpha: Double = 1
    var dbeta: Double = 0
    var dap: [Double] = [1, 2, 3]
    var dx: [Double] = [1, 1]
    var dy = [Double](repeating: 0, count: 2)
    _ = dspmv_(&uplo, &n, &dalpha, &dap, &dx, &incx, &dbeta, &dy, &incy)
    precondition(abs(dy[0] - 3) < 1e-12 && abs(dy[1] - 5) < 1e-12)
    var dapR: [Double] = [1, 0, 1]
    var dxr: [Double] = [1, 2]
    _ = dspr_(&uplo, &n, &dalpha, &dxr, &incx, &dapR)
    precondition(abs(dapR[0] - 2) < 1e-12 && abs(dapR[2] - 5) < 1e-12)
    var dap2 = [Double](repeating: 0, count: 3)
    var dx2: [Double] = [1, 0]
    var dy2: [Double] = [0, 1]
    _ = dspr2_(&uplo, &n, &dalpha, &dx2, &incx, &dy2, &incy, &dap2)
    precondition(abs(dap2[1] - 1) < 1e-12)
}

func testBLASBandedGbmvSbmv() {
    var trans = CChar(78)
    var transT = CChar(84)
    var m: Int32 = 2
    var n: Int32 = 2
    var kl: Int32 = 1
    var ku: Int32 = 1
    var alpha: Float = 1
    var beta: Float = 0
    var lda: Int32 = 3
    var incx: Int32 = 1
    var incy: Int32 = 1
    var a: [Float] = [9, 1, 3, 2, 4, 9]
    var x: [Float] = [1, 1]
    var y = [Float](repeating: 0, count: 2)
    _ = sgbmv_(&trans, &m, &n, &kl, &ku, &alpha, &a, &lda, &x, &incx, &beta, &y, &incy)
    precondition(abs(y[0] - 3) < 0.0001 && abs(y[1] - 7) < 0.0001)
    var yT = [Float](repeating: 0, count: 2)
    _ = sgbmv_(&transT, &m, &n, &kl, &ku, &alpha, &a, &lda, &x, &incx, &beta, &yT, &incy)
    precondition(abs(yT[0] - 4) < 0.0001 && abs(yT[1] - 6) < 0.0001)
    var m3: Int32 = 3
    var n3: Int32 = 3
    var a3: [Float] = [9, 2, 1, 1, 2, 1, 1, 2, 9]
    var x3: [Float] = [1, 1, 1]
    var y3 = [Float](repeating: 0, count: 3)
    _ = sgbmv_(&trans, &m3, &n3, &kl, &ku, &alpha, &a3, &lda, &x3, &incx, &beta, &y3, &incy)
    precondition(abs(y3[0] - 3) < 0.0001 && abs(y3[1] - 4) < 0.0001 && abs(y3[2] - 3) < 0.0001)
    var uplo = CChar(85)
    var uploL = CChar(76)
    var k: Int32 = 1
    var hlda: Int32 = 2
    var ha: [Float] = [9, 1, 2, 3]
    var hy = [Float](repeating: 0, count: 2)
    _ = ssbmv_(&uplo, &n, &k, &alpha, &ha, &hlda, &x, &incx, &beta, &hy, &incy)
    precondition(abs(hy[0] - 3) < 0.0001 && abs(hy[1] - 5) < 0.0001)
    var haL: [Float] = [1, 2, 3, 9]
    var hyL = [Float](repeating: 0, count: 2)
    _ = ssbmv_(&uploL, &n, &k, &alpha, &haL, &hlda, &x, &incx, &beta, &hyL, &incy)
    precondition(abs(hyL[0] - 3) < 0.0001 && abs(hyL[1] - 5) < 0.0001)
    var ha3: [Float] = [9, 2, 1, 2, 1, 2]
    var hy3 = [Float](repeating: 0, count: 3)
    _ = ssbmv_(&uplo, &n3, &k, &alpha, &ha3, &hlda, &x3, &incx, &beta, &hy3, &incy)
    precondition(abs(hy3[0] - 3) < 0.0001 && abs(hy3[1] - 4) < 0.0001 && abs(hy3[2] - 3) < 0.0001)
    var dalpha: Double = 1
    var dbeta: Double = 0
    var da: [Double] = [9, 1, 3, 2, 4, 9]
    var dx: [Double] = [1, 1]
    var dy = [Double](repeating: 0, count: 2)
    _ = dgbmv_(&trans, &m, &n, &kl, &ku, &dalpha, &da, &lda, &dx, &incx, &dbeta, &dy, &incy)
    precondition(abs(dy[0] - 3) < 1e-12 && abs(dy[1] - 7) < 1e-12)
    var dha: [Double] = [9, 1, 2, 3]
    var dhy = [Double](repeating: 0, count: 2)
    _ = dsbmv_(&uplo, &n, &k, &dalpha, &dha, &hlda, &dx, &incx, &dbeta, &dhy, &incy)
    precondition(abs(dhy[0] - 3) < 1e-12 && abs(dhy[1] - 5) < 1e-12)
}

func testBLASPackedTpmvTpsv() {
    var uplo = CChar(85)
    var uploL = CChar(76)
    var transN = CChar(78)
    var transT = CChar(84)
    var diagN = CChar(78)
    var diagU = CChar(85)
    var n: Int32 = 2
    var incx: Int32 = 1
    var ap: [Float] = [1, 2, 3]
    var x: [Float] = [1, 1]
    _ = stpmv_(&uplo, &transN, &diagN, &n, &ap, &x, &incx)
    precondition(abs(x[0] - 3) < 0.0001 && abs(x[1] - 3) < 0.0001)
    var xt: [Float] = [1, 1]
    _ = stpmv_(&uplo, &transT, &diagN, &n, &ap, &xt, &incx)
    precondition(abs(xt[0] - 1) < 0.0001 && abs(xt[1] - 5) < 0.0001)
    var apU: [Float] = [99, 2, 99]
    var xu: [Float] = [1, 1]
    _ = stpmv_(&uplo, &transN, &diagU, &n, &apU, &xu, &incx)
    precondition(abs(xu[0] - 3) < 0.0001 && abs(xu[1] - 1) < 0.0001)
    var xl: [Float] = [1, 1]
    _ = stpmv_(&uploL, &transN, &diagN, &n, &ap, &xl, &incx)
    precondition(abs(xl[0] - 1) < 0.0001 && abs(xl[1] - 5) < 0.0001)
    var xs: [Float] = [3, 3]
    _ = stpsv_(&uplo, &transN, &diagN, &n, &ap, &xs, &incx)
    precondition(abs(xs[0] - 1) < 0.0001 && abs(xs[1] - 1) < 0.0001)
    var n3: Int32 = 3
    var ap3: [Float] = [2, 1, 2, 0, 1, 2]
    var x3: [Float] = [1, 1, 1]
    _ = stpmv_(&uplo, &transN, &diagN, &n3, &ap3, &x3, &incx)
    precondition(abs(x3[0] - 3) < 0.0001 && abs(x3[1] - 3) < 0.0001 && abs(x3[2] - 2) < 0.0001)
    var b3 = x3
    _ = stpsv_(&uplo, &transN, &diagN, &n3, &ap3, &b3, &incx)
    precondition(abs(b3[0] - 1) < 0.0001 && abs(b3[1] - 1) < 0.0001 && abs(b3[2] - 1) < 0.0001)
    var dap: [Double] = [1, 2, 3]
    var dx: [Double] = [1, 1]
    _ = dtpmv_(&uplo, &transN, &diagN, &n, &dap, &dx, &incx)
    precondition(abs(dx[0] - 3) < 1e-12 && abs(dx[1] - 3) < 1e-12)
    var dxs: [Double] = [3, 3]
    _ = dtpsv_(&uplo, &transN, &diagN, &n, &dap, &dxs, &incx)
    precondition(abs(dxs[0] - 1) < 1e-12 && abs(dxs[1] - 1) < 1e-12)
}

func testBLASBandedTbmvTbsv() {
    var uplo = CChar(85)
    var uploL = CChar(76)
    var transN = CChar(78)
    var transT = CChar(84)
    var diagN = CChar(78)
    var n: Int32 = 2
    var k: Int32 = 1
    var lda: Int32 = 2
    var incx: Int32 = 1
    var a: [Float] = [9, 1, 2, 3]
    var x: [Float] = [1, 1]
    _ = stbmv_(&uplo, &transN, &diagN, &n, &k, &a, &lda, &x, &incx)
    precondition(abs(x[0] - 3) < 0.0001 && abs(x[1] - 3) < 0.0001)
    var xt: [Float] = [1, 1]
    _ = stbmv_(&uplo, &transT, &diagN, &n, &k, &a, &lda, &xt, &incx)
    precondition(abs(xt[0] - 1) < 0.0001 && abs(xt[1] - 5) < 0.0001)
    var aL: [Float] = [1, 2, 3, 9]
    var xl: [Float] = [1, 1]
    _ = stbmv_(&uploL, &transN, &diagN, &n, &k, &aL, &lda, &xl, &incx)
    precondition(abs(xl[0] - 1) < 0.0001 && abs(xl[1] - 5) < 0.0001)
    var xs: [Float] = [3, 3]
    _ = stbsv_(&uplo, &transN, &diagN, &n, &k, &a, &lda, &xs, &incx)
    precondition(abs(xs[0] - 1) < 0.0001 && abs(xs[1] - 1) < 0.0001)
    var n3: Int32 = 3
    var a3: [Float] = [9, 2, 1, 2, 1, 2]
    var x3: [Float] = [1, 1, 1]
    _ = stbmv_(&uplo, &transN, &diagN, &n3, &k, &a3, &lda, &x3, &incx)
    precondition(abs(x3[0] - 3) < 0.0001 && abs(x3[1] - 3) < 0.0001 && abs(x3[2] - 2) < 0.0001)
    var b3 = x3
    _ = stbsv_(&uplo, &transN, &diagN, &n3, &k, &a3, &lda, &b3, &incx)
    precondition(abs(b3[0] - 1) < 0.0001 && abs(b3[1] - 1) < 0.0001 && abs(b3[2] - 1) < 0.0001)
    var da: [Double] = [9, 1, 2, 3]
    var dx: [Double] = [1, 1]
    _ = dtbmv_(&uplo, &transN, &diagN, &n, &k, &da, &lda, &dx, &incx)
    precondition(abs(dx[0] - 3) < 1e-12 && abs(dx[1] - 3) < 1e-12)
    var dxs: [Double] = [3, 3]
    _ = dtbsv_(&uplo, &transN, &diagN, &n, &k, &da, &lda, &dxs, &incx)
    precondition(abs(dxs[0] - 1) < 1e-12 && abs(dxs[1] - 1) < 1e-12)
}

func testBLASSymmSyr2Syr2k() {
    var sideL = CChar(76)
    var sideR = CChar(82)
    var uplo = CChar(85)
    var transN = CChar(78)
    var transT = CChar(84)
    var m: Int32 = 2
    var n: Int32 = 2
    var k1: Int32 = 1
    var alpha: Float = 1
    var beta: Float = 0
    var lda: Int32 = 2
    var ldb: Int32 = 2
    var ldc: Int32 = 2
    var incx: Int32 = 1
    var incy: Int32 = 1
    var a: [Float] = [1, 0, 2, 3]
    var b: [Float] = [1, 0, 0, 1]
    var c = [Float](repeating: 0, count: 4)
    _ = ssymm_(&sideL, &uplo, &m, &n, &alpha, &a, &lda, &b, &ldb, &beta, &c, &ldc)
    precondition(abs(c[0] - 1) < 0.0001 && abs(c[1] - 2) < 0.0001)
    precondition(abs(c[2] - 2) < 0.0001 && abs(c[3] - 3) < 0.0001)
    var cR = [Float](repeating: 0, count: 4)
    _ = ssymm_(&sideR, &uplo, &m, &n, &alpha, &a, &lda, &b, &ldb, &beta, &cR, &ldc)
    precondition(abs(cR[0] - 1) < 0.0001 && abs(cR[3] - 3) < 0.0001)
    var a2 = [Float](repeating: 0, count: 4)
    var x: [Float] = [1, 0]
    var y: [Float] = [0, 1]
    _ = ssyr2_(&uplo, &n, &alpha, &x, &incx, &y, &incy, &a2, &lda)
    precondition(abs(a2[0]) < 0.0001 && abs(a2[2] - 1) < 0.0001 && abs(a2[3]) < 0.0001)
    var aCol: [Float] = [1, 0]
    var bCol: [Float] = [0, 1]
    var c2k = [Float](repeating: 0, count: 4)
    _ = ssyr2k_(&uplo, &transN, &n, &k1, &alpha, &aCol, &lda, &bCol, &ldb, &beta, &c2k, &ldc)
    precondition(abs(c2k[0]) < 0.0001 && abs(c2k[2] - 1) < 0.0001 && abs(c2k[3]) < 0.0001)
    var aT: [Float] = [1, 0]
    var bT: [Float] = [0, 1]
    var lda1: Int32 = 1
    var ldb1: Int32 = 1
    var cT = [Float](repeating: 0, count: 4)
    _ = ssyr2k_(&uplo, &transT, &n, &k1, &alpha, &aT, &lda1, &bT, &ldb1, &beta, &cT, &ldc)
    precondition(abs(cT[2] - 1) < 0.0001)
    var dalpha: Double = 1
    var dbeta: Double = 0
    var da: [Double] = [1, 0, 2, 3]
    var db: [Double] = [1, 0, 0, 1]
    var dc = [Double](repeating: 0, count: 4)
    _ = dsymm_(&sideL, &uplo, &m, &n, &dalpha, &da, &lda, &db, &ldb, &dbeta, &dc, &ldc)
    precondition(abs(dc[0] - 1) < 1e-12 && abs(dc[3] - 3) < 1e-12)
    var da2 = [Double](repeating: 0, count: 4)
    var dx: [Double] = [1, 0]
    var dy: [Double] = [0, 1]
    _ = dsyr2_(&uplo, &n, &dalpha, &dx, &incx, &dy, &incy, &da2, &lda)
    precondition(abs(da2[2] - 1) < 1e-12)
    var daCol: [Double] = [1, 0]
    var dbCol: [Double] = [0, 1]
    var dc2k = [Double](repeating: 0, count: 4)
    _ = dsyr2k_(&uplo, &transN, &n, &k1, &dalpha, &daCol, &lda, &dbCol, &ldb, &dbeta, &dc2k, &ldc)
    precondition(abs(dc2k[2] - 1) < 1e-12)
}

func testBLASTrmmTrsm() {
    var sideL = CChar(76)
    var sideR = CChar(82)
    var uplo = CChar(85)
    var transN = CChar(78)
    var transT = CChar(84)
    var diagN = CChar(78)
    var m: Int32 = 2
    var n: Int32 = 2
    var alpha: Float = 1
    var lda: Int32 = 2
    var ldb: Int32 = 2
    var a: [Float] = [1, 0, 2, 3]
    var b: [Float] = [1, 0, 0, 1]
    _ = strmm_(&sideL, &uplo, &transN, &diagN, &m, &n, &alpha, &a, &lda, &b, &ldb)
    precondition(abs(b[0] - 1) < 0.0001 && abs(b[1]) < 0.0001)
    precondition(abs(b[2] - 2) < 0.0001 && abs(b[3] - 3) < 0.0001)
    var bT: [Float] = [1, 0, 0, 1]
    _ = strmm_(&sideL, &uplo, &transT, &diagN, &m, &n, &alpha, &a, &lda, &bT, &ldb)
    precondition(abs(bT[0] - 1) < 0.0001 && abs(bT[1] - 2) < 0.0001)
    precondition(abs(bT[2]) < 0.0001 && abs(bT[3] - 3) < 0.0001)
    var bR: [Float] = [1, 0, 0, 1]
    _ = strmm_(&sideR, &uplo, &transN, &diagN, &m, &n, &alpha, &a, &lda, &bR, &ldb)
    precondition(abs(bR[0] - 1) < 0.0001 && abs(bR[3] - 3) < 0.0001)
    var bs: [Float] = [1, 0, 2, 3]
    _ = strsm_(&sideL, &uplo, &transN, &diagN, &m, &n, &alpha, &a, &lda, &bs, &ldb)
    precondition(abs(bs[0] - 1) < 0.0001 && abs(bs[1]) < 0.0001)
    precondition(abs(bs[2]) < 0.0001 && abs(bs[3] - 1) < 0.0001)
    var da: [Double] = [1, 0, 2, 3]
    var db: [Double] = [1, 0, 0, 1]
    var dalpha: Double = 1
    _ = dtrmm_(&sideL, &uplo, &transN, &diagN, &m, &n, &dalpha, &da, &lda, &db, &ldb)
    precondition(abs(db[0] - 1) < 1e-12 && abs(db[3] - 3) < 1e-12)
    var dbs: [Double] = [1, 0, 2, 3]
    _ = dtrsm_(&sideL, &uplo, &transN, &diagN, &m, &n, &dalpha, &da, &lda, &dbs, &ldb)
    precondition(abs(dbs[0] - 1) < 1e-12 && abs(dbs[3] - 1) < 1e-12)
}

func testBLASRotmRotmg() {
    var n: Int32 = 2
    var incx: Int32 = 1
    var incy: Int32 = 1
    var x: [Float] = [1, 3]
    var y: [Float] = [2, 4]
    var param: [Float] = [-1, 0.6, -0.8, 0.8, 0.6]
    _ = srotm_(&n, &x, &incx, &y, &incy, &param)
    precondition(abs(x[0] - 2.2) < 0.0001 && abs(x[1] - 5) < 0.0001)
    precondition(abs(y[0] - 0.4) < 0.0001 && abs(y[1]) < 0.0001)
    var x0: [Float] = [1, 3]
    var y0: [Float] = [2, 4]
    var p0: [Float] = [0, 99, -0.5, 0.5, 99]
    _ = srotm_(&n, &x0, &incx, &y0, &incy, &p0)
    precondition(abs(x0[0] - 2) < 0.0001 && abs(x0[1] - 5) < 0.0001)
    precondition(abs(y0[0] - 1.5) < 0.0001 && abs(y0[1] - 2.5) < 0.0001)
    var x1: [Float] = [1, 3]
    var y1: [Float] = [2, 4]
    var p1: [Float] = [1, 0.5, 99, 99, 0.5]
    _ = srotm_(&n, &x1, &incx, &y1, &incy, &p1)
    precondition(abs(x1[0] - 2.5) < 0.0001 && abs(x1[1] - 5.5) < 0.0001)
    precondition(abs(y1[0]) < 0.0001 && abs(y1[1] + 1) < 0.0001)
    var xi: [Float] = [1, 3]
    var yi: [Float] = [2, 4]
    var pi: [Float] = [-2, 99, 99, 99, 99]
    _ = srotm_(&n, &xi, &incx, &yi, &incy, &pi)
    precondition(xi == [1, 3] && yi == [2, 4])
    var d1: Float = 1
    var d2: Float = 1
    var sx1: Float = 3
    var sy1: Float = 4
    var pg = [Float](repeating: 0, count: 5)
    _ = srotmg_(&d1, &d2, &sx1, &sy1, &pg)
    precondition(abs(d1 - 0.64) < 0.0001 && abs(d2 - 0.64) < 0.0001)
    precondition(abs(sx1 - 6.25) < 0.0001)
    precondition(abs(pg[0] - 1) < 0.0001 && abs(pg[1] - 0.75) < 0.0001 && abs(pg[4] - 0.75) < 0.0001)
    var xr: [Float] = [3, 0]
    var yr: [Float] = [4, 1]
    _ = srotm_(&n, &xr, &incx, &yr, &incy, &pg)
    precondition(abs(xr[0] - 6.25) < 0.0001 && abs(xr[1] - 1) < 0.0001)
    precondition(abs(yr[0]) < 0.0001 && abs(yr[1] - 0.75) < 0.0001)
    var zd1: Float = 1
    var zd2: Float = 1
    var zx1: Float = 1
    var zy1: Float = 0
    var pz = [Float](repeating: 0, count: 5)
    _ = srotmg_(&zd1, &zd2, &zx1, &zy1, &pz)
    precondition(abs(pz[0] + 2) < 0.0001)
    var dd1: Double = 1
    var dd2: Double = 1
    var dx1: Double = 3
    var dy1: Double = 4
    var dpg = [Double](repeating: 0, count: 5)
    _ = drotmg_(&dd1, &dd2, &dx1, &dy1, &dpg)
    precondition(abs(dd1 - 0.64) < 1e-12 && abs(dpg[0] - 1) < 1e-12 && abs(dpg[1] - 0.75) < 1e-12)
    var dx: [Double] = [1, 3]
    var dy: [Double] = [2, 4]
    var dparam: [Double] = [-1, 0.6, -0.8, 0.8, 0.6]
    _ = drotm_(&n, &dx, &incx, &dy, &incy, &dparam)
    precondition(abs(dx[0] - 2.2) < 1e-12 && abs(dy[0] - 0.4) < 1e-12)
}

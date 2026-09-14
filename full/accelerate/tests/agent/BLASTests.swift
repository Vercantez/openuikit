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

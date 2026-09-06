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

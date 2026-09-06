import Accelerate
import Foundation

func testLAFloatMatrixRoundTrip() {
    var values: [Float] = [1, 2, 3, 4]
    let matrix = la_matrix_from_float_buffer(&values, 2, 2, 2, 0, 0)
    precondition(la_status(matrix) == 0)
    precondition(la_matrix_rows(matrix) == 2)
    precondition(la_matrix_cols(matrix) == 2)
    var out = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&out, 2, matrix) == 0)
    precondition(out == [1, 2, 3, 4])
    let retained = la_retain(matrix)
    precondition(la_matrix_rows(retained) == 2)
    la_release(retained)
    la_add_attributes(matrix, 1)
    la_remove_attributes(matrix, 1)
    var nocopy = values
    let copied = la_matrix_from_float_buffer_nocopy(&nocopy, 2, 2, 2, 0, nil, 0)
    precondition(la_matrix_rows(copied) == 2)
}

func testLADoubleMatrixRoundTrip() {
    var values: [Double] = [1, 0, 0, 1]
    let matrix = la_matrix_from_double_buffer(&values, 2, 2, 2, 0, 0)
    precondition(la_status(matrix) == 0)
    var out = [Double](repeating: 0, count: 4)
    precondition(la_matrix_to_double_buffer(&out, 2, matrix) == 0)
    precondition(out == [1, 0, 0, 1])
    var nocopy = values
    let copied = la_matrix_from_double_buffer_nocopy(&nocopy, 2, 2, 2, 0, nil, 0)
    precondition(la_matrix_cols(copied) == 2)
}

func testLAIdentitySplatScale() {
    let ident = la_identity_matrix(2, 0, 0)
    var out = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&out, 2, ident) == 0)
    precondition(out == [1, 0, 0, 1])
    let splat = la_splat_from_float(3, 0)
    let filled = la_matrix_from_splat(splat, 2, 2)
    var fillOut = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&fillOut, 2, filled) == 0)
    precondition(fillOut == [3, 3, 3, 3])
    let scaled = la_scale_with_float(ident, 2)
    var scaledOut = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&scaledOut, 2, scaled) == 0)
    precondition(scaledOut == [2, 0, 0, 2])
    let dsplat = la_splat_from_double(4, 0)
    let dvec = la_vector_from_splat(dsplat, 3)
    precondition(la_vector_length(dvec) == 3)
    let dident = la_identity_matrix(2, 1, 0)
    let dscaled = la_scale_with_double(dident, 0.5)
    var dout = [Double](repeating: 0, count: 4)
    precondition(la_matrix_to_double_buffer(&dout, 2, dscaled) == 0)
    precondition(abs(dout[0] - 0.5) < 1e-12)
}

func testLASumProductTranspose() {
    var aVals: [Float] = [1, 2, 3, 4]
    var bVals: [Float] = [5, 6, 7, 8]
    let a = la_matrix_from_float_buffer(&aVals, 2, 2, 2, 0, 0)
    let b = la_matrix_from_float_buffer(&bVals, 2, 2, 2, 0, 0)
    let summed = la_sum(a, b)
    var sOut = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&sOut, 2, summed) == 0)
    precondition(sOut == [6, 8, 10, 12])
    let diff = la_difference(b, a)
    var dOut = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&dOut, 2, diff) == 0)
    precondition(dOut == [4, 4, 4, 4])
    let hadamard = la_elementwise_product(a, b)
    var hOut = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&hOut, 2, hadamard) == 0)
    precondition(hOut == [5, 12, 21, 32])
    let identVals: [Float] = [1, 0, 0, 1]
    var identBuf = identVals
    let ident = la_matrix_from_float_buffer(&identBuf, 2, 2, 2, 0, 0)
    let product = la_matrix_product(a, ident)
    var pOut = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&pOut, 2, product) == 0)
    precondition(pOut == [1, 2, 3, 4])
    let transposed = la_transpose(a)
    var tOut = [Float](repeating: 0, count: 4)
    precondition(la_matrix_to_float_buffer(&tOut, 2, transposed) == 0)
    precondition(tOut == [1, 3, 2, 4])
}

func testLAVectorInnerOuterNorm() {
    var xVals: [Float] = [1, 2, 3]
    var yVals: [Float] = [4, 5, 6]
    let x = la_matrix_from_float_buffer(&xVals, 3, 1, 1, 0, 0)
    let y = la_matrix_from_float_buffer(&yVals, 3, 1, 1, 0, 0)
    precondition(la_vector_length(x) == 3)
    let inner = la_inner_product(x, y)
    var innerOut: [Float] = [0]
    precondition(la_vector_to_float_buffer(&innerOut, 1, inner) == 0)
    precondition(innerOut[0] == 32)
    let outer = la_outer_product(x, y)
    precondition(la_matrix_rows(outer) == 3)
    precondition(la_matrix_cols(outer) == 3)
    var outerFirst: [Float] = [0, 0, 0]
    _ = la_vector_to_float_buffer(&outerFirst, 1, la_vector_from_matrix_row(outer, 0))
    precondition(outerFirst == [4, 5, 6])
    precondition(abs(la_norm_as_float(x, 1) - 6) < 0.0001)
    precondition(abs(la_norm_as_double(x, 2) - Double((1 + 4 + 9) as Float).squareRoot()) < 1e-5)
    let unit = la_normalized_vector(x, 1)
    precondition(abs(la_norm_as_float(unit, 1) - 1) < 0.0001)
    var dx: [Double] = [3, 4]
    let dv = la_matrix_from_double_buffer(&dx, 2, 1, 1, 0, 0)
    var dvOut: [Double] = [0, 0]
    precondition(la_vector_to_double_buffer(&dvOut, 1, dv) == 0)
    precondition(dvOut == [3, 4])
}

func testLASlicingDiagonalSolve() {
    var m: [Float] = [1, 2, 3, 4]
    let matrix = la_matrix_from_float_buffer(&m, 2, 2, 2, 0, 0)
    let row = la_vector_from_matrix_row(matrix, 1)
    var rowOut: [Float] = [0, 0]
    _ = la_vector_to_float_buffer(&rowOut, 1, row)
    precondition(rowOut == [3, 4])
    let col = la_vector_from_matrix_col(matrix, 0)
    var colOut: [Float] = [0, 0]
    _ = la_vector_to_float_buffer(&colOut, 1, col)
    precondition(colOut == [1, 3])
    let diag = la_vector_from_matrix_diagonal(matrix, 0)
    var diagOut: [Float] = [0, 0]
    _ = la_vector_to_float_buffer(&diagOut, 1, diag)
    precondition(diagOut == [1, 4])
    let rebuilt = la_diagonal_matrix_from_vector(diag, 0)
    var rebuiltOut = [Float](repeating: 0, count: 4)
    _ = la_matrix_to_float_buffer(&rebuiltOut, 2, rebuilt)
    precondition(rebuiltOut == [1, 0, 0, 4])
    let slice = la_matrix_slice(matrix, 0, 1, 1, 1, 2, 1)
    precondition(la_matrix_rows(slice) == 2)
    precondition(la_matrix_cols(slice) == 1)
    let vslice = la_vector_slice(row, 0, 1, 2)
    precondition(la_vector_length(vslice) == 2)
    let el = la_splat_from_matrix_element(matrix, 0, 1)
    let vel = la_splat_from_vector_element(row, 0)
    let fromEl = la_matrix_from_splat(el, 1, 1)
    var elOut: [Float] = [0]
    _ = la_matrix_to_float_buffer(&elOut, 1, fromEl)
    precondition(elOut[0] == 2)
    _ = vel
    var a: [Float] = [2, 0, 0, 2]
    var rhs: [Float] = [2, 4]
    let A = la_matrix_from_float_buffer(&a, 2, 2, 2, 0, 0)
    let b = la_matrix_from_float_buffer(&rhs, 2, 1, 1, 0, 0)
    let x = la_solve(A, b)
    var xOut: [Float] = [0, 0]
    _ = la_vector_to_float_buffer(&xOut, 1, x)
    precondition(abs(xOut[0] - 1) < 0.0001)
    precondition(abs(xOut[1] - 2) < 0.0001)
}

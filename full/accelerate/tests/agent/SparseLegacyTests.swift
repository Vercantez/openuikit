import Accelerate
import Foundation

func testSparseLegacyFloatCreateMultiply() {
    guard let A = sparse_matrix_create_float(2, 2) else { preconditionFailure("create float") }
    precondition(sparse_insert_entry_float(A, 1, 0, 0).rawValue == 0)
    var extraVals: [Float] = [2]
    var extraRows: [sparse_index] = [0]
    var extraCols: [sparse_index] = [1]
    precondition(sparse_insert_entries_float(A, 1, &extraVals, &extraRows, &extraCols).rawValue == 0)
    var colVals: [Float] = [3]
    var colRows: [sparse_index] = [1]
    precondition(sparse_insert_col_float(A, 1, 1, &colVals, &colRows).rawValue == 0)
    var rowVals: [Float] = [0]
    var rowCols: [sparse_index] = [0]
    _ = sparse_insert_row_float(A, 1, 1, &rowVals, &rowCols)
    precondition(sparse_commit(UnsafeMutableRawPointer(A)).rawValue == 0)
    precondition(sparse_get_matrix_number_of_rows(UnsafeMutableRawPointer(A)) == 2)
    precondition(sparse_get_matrix_number_of_columns(UnsafeMutableRawPointer(A)) == 2)
    precondition(sparse_get_matrix_nonzero_count(UnsafeMutableRawPointer(A)) == 4)
    precondition(sparse_get_matrix_nonzero_count_for_row(UnsafeMutableRawPointer(A), 0) == 2)
    precondition(sparse_get_matrix_nonzero_count_for_column(UnsafeMutableRawPointer(A), 1) == 2)
    var x: [Float] = [1, 1]
    var y: [Float] = [0, 0]
    precondition(sparse_matrix_vector_product_dense_float(CblasNoTrans, 1, A, &x, 1, &y, 1).rawValue == 0)
    precondition(abs(y[0] - 3) < 0.0001)
    precondition(abs(y[1] - 3) < 0.0001)
    precondition(abs(sparse_matrix_trace_float(A, 0) - 4) < 0.0001)
    precondition(sparse_elementwise_norm_float(A, SPARSE_NORM_ONE) > 0)
    precondition(sparse_operator_norm_float(A, SPARSE_NORM_TWO) > 0)
    var perm: [sparse_index] = [1, 0]
    _ = sparse_permute_rows_float(A, &perm)
    _ = sparse_permute_cols_float(A, &perm)
    _ = sparse_set_matrix_property(UnsafeMutableRawPointer(A), sparse_matrix_property(rawValue: 1))
    _ = sparse_get_matrix_property(UnsafeMutableRawPointer(A), sparse_matrix_property(rawValue: 1))
    precondition(sparse_matrix_destroy(UnsafeMutableRawPointer(A)).rawValue == 0)
}

func testSparseLegacyDoubleCreateMultiply() {
    guard let A = sparse_matrix_create_double(2, 2) else { preconditionFailure("create double") }
    var vals: [Double] = [1, 2]
    var rows: [sparse_index] = [0, 1]
    var cols: [sparse_index] = [0, 1]
    precondition(sparse_insert_entry_double(A, 0, 0, 1).rawValue == 0)
    precondition(sparse_insert_entries_double(A, 2, &vals, &rows, &cols).rawValue == 0)
    var extra: [Double] = [4]
    var extraRows: [sparse_index] = [0]
    precondition(sparse_insert_col_double(A, 1, 1, &extra, &extraRows).rawValue == 0)
    var rowVals: [Double] = [3]
    var rowCols: [sparse_index] = [0]
    precondition(sparse_insert_row_double(A, 1, 1, &rowVals, &rowCols).rawValue == 0)
    precondition(sparse_commit(UnsafeMutableRawPointer(A)).rawValue == 0)
    var x: [Double] = [1, 0]
    var y: [Double] = [0, 0]
    precondition(sparse_matrix_vector_product_dense_double(CblasNoTrans, 1, A, &x, 1, &y, 1).rawValue == 0)
    precondition(abs(y[0] - 1) < 1e-12)
    var B: [Double] = [1, 0, 0, 1]
    var C = [Double](repeating: 0, count: 4)
    precondition(
        sparse_matrix_product_dense_double(CblasRowMajor, CblasNoTrans, 2, 1, A, &B, 2, &C, 2).rawValue == 0
    )
    precondition(sparse_elementwise_norm_double(A, SPARSE_NORM_INF) > 0)
    precondition(sparse_operator_norm_double(A, SPARSE_NORM_ONE) > 0)
    precondition(abs(sparse_matrix_trace_double(A, 0) - 3) < 1e-12)
    var perm: [sparse_index] = [0, 1]
    _ = sparse_permute_rows_double(A, &perm)
    _ = sparse_permute_cols_double(A, &perm)
    precondition(sparse_matrix_destroy(UnsafeMutableRawPointer(A)).rawValue == 0)
}

func testSparseLegacyVectorPackInner() {
    var dense: [Float] = [0, 2, 0, 4]
    precondition(sparse_get_vector_nonzero_count_float(4, &dense, 1) == 2)
    var packed = [Float](repeating: 0, count: 2)
    var idx = [sparse_index](repeating: 0, count: 2)
    precondition(sparse_pack_vector_float(4, 2, &dense, 1, &packed, &idx) == 2)
    precondition(packed == [2, 4])
    var unpacked = [Float](repeating: 9, count: 4)
    sparse_unpack_vector_float(4, 2, true, &packed, &idx, &unpacked, 1)
    precondition(unpacked == [0, 2, 0, 4])
    var y: [Float] = [1, 1, 1, 1]
    sparse_vector_add_with_scale_dense_float(2, 1, &packed, &idx, &y, 1)
    precondition(y[1] == 3)
    var denseY: [Float] = [10, 20, 30, 40]
    // Packed [2, 4] at indices [1, 3]: 2 * 20 + 4 * 40 = 200.
    precondition(abs(sparse_inner_product_dense_float(2, &packed, &idx, &denseY, 1) - 200) < 0.0001)
    var sx: [Float] = [1, 2]
    var ix: [sparse_index] = [0, 2]
    var sy: [Float] = [3, 4]
    var iy: [sparse_index] = [0, 2]
    precondition(abs(sparse_inner_product_sparse_float(2, 2, &sx, &ix, &sy, &iy) - 11) < 0.0001)
    precondition(sparse_vector_norm_float(2, &packed, &idx, SPARSE_NORM_ONE) == 6)
    var ddense: [Double] = [0, 5, 0]
    precondition(sparse_get_vector_nonzero_count_double(3, &ddense, 1) == 1)
    var dpacked: [Double] = [0]
    var didx: [sparse_index] = [0]
    _ = sparse_pack_vector_double(3, 1, &ddense, 1, &dpacked, &didx)
    var dunp = [Double](repeating: 0, count: 3)
    sparse_unpack_vector_double(3, 1, true, &dpacked, &didx, &dunp, 1)
    precondition(dunp[1] == 5)
    var dy: [Double] = [1, 1, 1]
    sparse_vector_add_with_scale_dense_double(1, 2, &dpacked, &didx, &dy, 1)
    precondition(dy[1] == 11)
    var dy2: [Double] = [1, 2, 3]
    _ = sparse_inner_product_dense_double(1, &dpacked, &didx, &dy2, 1)
    var dsx: [Double] = [2]
    var dix: [sparse_index] = [0]
    var dsy: [Double] = [4]
    var diy: [sparse_index] = [0]
    _ = sparse_inner_product_sparse_double(1, 1, &dsx, &dix, &dsy, &diy)
    _ = sparse_vector_norm_double(1, &dpacked, &didx, SPARSE_NORM_TWO)
}

func testSparseLegacyExtractBlockSolve() {
    guard let A = sparse_matrix_block_create_float(1, 1, 2, 2) else { preconditionFailure("block create") }
    var block: [Float] = [2, 0, 1, 2]
    precondition(sparse_insert_block_float(A, &block, 2, 1, 0, 0).rawValue == 0)
    precondition(sparse_commit(UnsafeMutableRawPointer(A)).rawValue == 0)
    precondition(sparse_get_block_dimension_for_row(UnsafeMutableRawPointer(A), 0) == 2)
    precondition(sparse_get_block_dimension_for_col(UnsafeMutableRawPointer(A), 0) == 2)
    var extracted = [Float](repeating: 0, count: 4)
    precondition(sparse_extract_block_float(A, 0, 0, 2, 1, &extracted).rawValue == 0)
    precondition(extracted[0] == 2)
    var rowVal: [Float] = [0, 0]
    var rowIdx: [sparse_index] = [0, 0]
    var rowEnd: sparse_index = 0
    _ = sparse_extract_sparse_row_float(A, 0, 0, &rowEnd, 2, &rowVal, &rowIdx)
    var colVal: [Float] = [0, 0]
    var colIdx: [sparse_index] = [0, 0]
    var colEnd: sparse_index = 0
    _ = sparse_extract_sparse_column_float(A, 0, 0, &colEnd, 2, &colVal, &colIdx)
    var rhs: [Float] = [2, 4]
    precondition(sparse_matrix_triangular_solve_dense_float(CblasColMajor, CblasNoTrans, 1, 1, A, &rhs, 2).rawValue == 0)
    precondition(abs(rhs[0] - 1) < 0.0001)
    var x: [Float] = [2, 4]
    _ = sparse_vector_triangular_solve_dense_float(CblasNoTrans, 1, A, &x, 1)
    var k: [sparse_dimension] = [1, 1]
    var l: [sparse_dimension] = [1, 1]
    if let v = sparse_matrix_variable_block_create_float(2, 2, &k, &l) {
        _ = sparse_matrix_destroy(UnsafeMutableRawPointer(v))
    }
    _ = sparse_matrix_destroy(UnsafeMutableRawPointer(A))

    guard let D = sparse_matrix_block_create_double(1, 1, 2, 2) else { preconditionFailure("d block") }
    var dblock: [Double] = [2, 0, 0, 2]
    _ = sparse_insert_block_double(D, &dblock, 2, 1, 0, 0)
    _ = sparse_commit(UnsafeMutableRawPointer(D))
    var dex = [Double](repeating: 0, count: 4)
    _ = sparse_extract_block_double(D, 0, 0, 2, 1, &dex)
    var drow = [Double](repeating: 0, count: 2)
    var drowIdx = [sparse_index](repeating: 0, count: 2)
    var dend: sparse_index = 0
    _ = sparse_extract_sparse_row_double(D, 0, 0, &dend, 2, &drow, &drowIdx)
    var dcol = [Double](repeating: 0, count: 2)
    var dcolIdx = [sparse_index](repeating: 0, count: 2)
    _ = sparse_extract_sparse_column_double(D, 0, 0, &dend, 2, &dcol, &dcolIdx)
    var drhs: [Double] = [2, 4]
    _ = sparse_matrix_triangular_solve_dense_double(CblasColMajor, CblasNoTrans, 1, 1, D, &drhs, 2)
    var dx: [Double] = [2, 4]
    _ = sparse_vector_triangular_solve_dense_double(CblasNoTrans, 1, D, &dx, 1)
    if let dv = sparse_matrix_variable_block_create_double(2, 2, &k, &l) {
        _ = sparse_matrix_destroy(UnsafeMutableRawPointer(dv))
    }
    _ = sparse_matrix_destroy(UnsafeMutableRawPointer(D))
}

func testSparseLegacyOuterProductSparseProduct() {
    var x: [Float] = [1, 2]
    var y: [Float] = [3]
    var indy: [sparse_index] = [0]
    var produced: sparse_matrix_float?
    precondition(sparse_outer_product_dense_float(2, 1, 1, 1, &x, 1, &y, &indy, &produced).rawValue == 0)
    guard let C = produced else { preconditionFailure("outer float") }
    var xv: [Float] = [1]
    var yv: [Float] = [0, 0]
    _ = sparse_matrix_vector_product_dense_float(CblasNoTrans, 1, C, &xv, 1, &yv, 1)
    precondition(abs(yv[0] - 3) < 0.0001)
    precondition(abs(yv[1] - 6) < 0.0001)
    var ident: [Float] = [1, 0, 0, 1]
    var out = [Float](repeating: 0, count: 4)
    guard let A = sparse_matrix_create_float(2, 2) else { preconditionFailure("A") }
    _ = sparse_insert_entry_float(A, 1, 0, 0)
    _ = sparse_insert_entry_float(A, 1, 1, 1)
    _ = sparse_commit(UnsafeMutableRawPointer(A))
    _ = sparse_matrix_product_dense_float(CblasRowMajor, CblasNoTrans, 2, 1, A, &ident, 2, &out, 2)
    _ = sparse_matrix_product_sparse_float(CblasRowMajor, CblasNoTrans, 1, A, A, &out, 2)
    _ = sparse_matrix_destroy(UnsafeMutableRawPointer(A))
    _ = sparse_matrix_destroy(UnsafeMutableRawPointer(C))

    var dx: [Double] = [1, 1]
    var dy: [Double] = [2]
    var didy: [sparse_index] = [1]
    var dproduced: sparse_matrix_double?
    _ = sparse_outer_product_dense_double(2, 2, 1, 1, &dx, 1, &dy, &didy, &dproduced)
    if let DC = dproduced {
        guard let DA = sparse_matrix_create_double(2, 2) else { preconditionFailure("DA") }
        _ = sparse_insert_entry_double(DA, 1, 0, 0)
        _ = sparse_insert_entry_double(DA, 1, 1, 1)
        _ = sparse_commit(UnsafeMutableRawPointer(DA))
        var dout = [Double](repeating: 0, count: 4)
        _ = sparse_matrix_product_sparse_double(CblasRowMajor, CblasNoTrans, 1, DA, DA, &dout, 2)
        _ = sparse_matrix_destroy(UnsafeMutableRawPointer(DA))
        _ = sparse_matrix_destroy(UnsafeMutableRawPointer(DC))
    }
}

func testSparseLegacyComplexFailClosed() {
    precondition(sparse_matrix_create_float_complex(2, 2) == nil)
    precondition(sparse_matrix_create_double_complex(2, 2) == nil)
    precondition(sparse_matrix_block_create_float_complex(1, 1, 1, 1) == nil)
    precondition(sparse_matrix_block_create_double_complex(1, 1, 1, 1) == nil)
    var k: [sparse_dimension] = [1]
    var l: [sparse_dimension] = [1]
    precondition(sparse_matrix_variable_block_create_float_complex(1, 1, &k, &l) == nil)
    precondition(sparse_matrix_variable_block_create_double_complex(1, 1, &k, &l) == nil)
    precondition(sparse_insert_entries_float_complex(nil, 0, nil, nil, nil).rawValue != 0)
    precondition(sparse_insert_entries_double_complex(nil, 0, nil, nil, nil).rawValue != 0)
    precondition(sparse_insert_col_float_complex(nil, 0, 0, nil, nil).rawValue != 0)
    precondition(sparse_insert_col_double_complex(nil, 0, 0, nil, nil).rawValue != 0)
    precondition(sparse_insert_row_float_complex(nil, 0, 0, nil, nil).rawValue != 0)
    precondition(sparse_insert_row_double_complex(nil, 0, 0, nil, nil).rawValue != 0)
    precondition(sparse_insert_block_float_complex(nil, nil, 0, 0, 0, 0).rawValue != 0)
    precondition(sparse_insert_block_double_complex(nil, nil, 0, 0, 0, 0).rawValue != 0)
    precondition(sparse_elementwise_norm_float_complex(nil, SPARSE_NORM_ONE) == 0)
    precondition(sparse_elementwise_norm_double_complex(nil, SPARSE_NORM_ONE) == 0)
    precondition(sparse_operator_norm_float_complex(nil, SPARSE_NORM_ONE) == 0)
    precondition(sparse_operator_norm_double_complex(nil, SPARSE_NORM_ONE) == 0)
    precondition(sparse_get_vector_nonzero_count_float_complex(0, nil, 1) == 0)
    precondition(sparse_get_vector_nonzero_count_double_complex(0, nil, 1) == 0)
    precondition(sparse_pack_vector_float_complex(0, 0, nil, 1, nil, nil) == 0)
    precondition(sparse_pack_vector_double_complex(0, 0, nil, 1, nil, nil) == 0)
    sparse_unpack_vector_float_complex(0, 0, true, nil, nil, nil, 1)
    sparse_unpack_vector_double_complex(0, 0, true, nil, nil, nil, 1)
    precondition(sparse_vector_norm_float_complex(0, nil, nil, SPARSE_NORM_ONE) == 0)
    precondition(sparse_vector_norm_double_complex(0, nil, nil, SPARSE_NORM_ONE) == 0)
    precondition(sparse_extract_sparse_row_float_complex(nil, 0, 0, nil, 0, nil, nil).rawValue != 0)
    precondition(sparse_extract_sparse_row_double_complex(nil, 0, 0, nil, 0, nil, nil).rawValue != 0)
    precondition(sparse_extract_sparse_column_float_complex(nil, 0, 0, nil, 0, nil, nil).rawValue != 0)
    precondition(sparse_extract_sparse_column_double_complex(nil, 0, 0, nil, 0, nil, nil).rawValue != 0)
    precondition(sparse_extract_block_float_complex(nil, 0, 0, 0, 0, nil).rawValue != 0)
    precondition(sparse_extract_block_double_complex(nil, 0, 0, 0, 0, nil).rawValue != 0)
    precondition(sparse_permute_rows_float_complex(nil, nil).rawValue != 0)
    precondition(sparse_permute_rows_double_complex(nil, nil).rawValue != 0)
    precondition(sparse_permute_cols_float_complex(nil, nil).rawValue != 0)
    precondition(sparse_permute_cols_double_complex(nil, nil).rawValue != 0)
}

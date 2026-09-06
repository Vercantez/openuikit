import Foundation

func _sparseCSCMultiplyVector<T: BinaryFloatingPoint>(
    structure: SparseMatrixStructure,
    data: UnsafePointer<T>,
    x: UnsafePointer<T>,
    y: UnsafeMutablePointer<T>,
    alpha: T,
    add: Bool
) {
    let rows = Int(structure.rowCount)
    let cols = Int(structure.columnCount)
    if !add {
        for i in 0..<rows { y[i] = 0 }
    }
    let transpose = structure.attributes.transpose
    for j in 0..<cols {
        let start = structure.columnStarts[j]
        let end = structure.columnStarts[j + 1]
        if start < 0 || end < start { continue }
        for p in start..<end {
            let row = Int(structure.rowIndices[p])
            if row < 0 { continue }
            let value = data[p]
            if transpose {
                if j < rows { y[j] += alpha * value * x[row] }
            } else {
                if row < rows { y[row] += alpha * value * x[j] }
            }
        }
    }
}

func _sparseCSCMultiplyMatrix(
    structure: SparseMatrixStructure,
    data: UnsafePointer<Float>,
    x: DenseMatrix_Float,
    y: DenseMatrix_Float,
    alpha: Float,
    add: Bool
) {
    let rhs = Int(x.columnCount)
    let xStride = Int(x.columnStride)
    let yStride = Int(y.columnStride)
    for k in 0..<rhs {
        _sparseCSCMultiplyVector(
            structure: structure,
            data: data,
            x: x.data.advanced(by: k * xStride),
            y: y.data.advanced(by: k * yStride),
            alpha: alpha,
            add: add
        )
    }
}

func _sparseCSCMultiplyMatrixD(
    structure: SparseMatrixStructure,
    data: UnsafePointer<Double>,
    x: DenseMatrix_Double,
    y: DenseMatrix_Double,
    alpha: Double,
    add: Bool
) {
    let rhs = Int(x.columnCount)
    let xStride = Int(x.columnStride)
    let yStride = Int(y.columnStride)
    for k in 0..<rhs {
        _sparseCSCMultiplyVector(
            structure: structure,
            data: data,
            x: x.data.advanced(by: k * xStride),
            y: y.data.advanced(by: k * yStride),
            alpha: alpha,
            add: add
        )
    }
}

func _sparseConvertFromCoordinate<T: BinaryFloatingPoint>(
    rowCount: Int32,
    columnCount: Int32,
    blockCount: Int,
    blockSize: UInt8,
    attributes: SparseAttributes_t,
    row: UnsafePointer<Int32>,
    column: UnsafePointer<Int32>,
    data: UnsafePointer<T>
) -> (structure: SparseMatrixStructure, values: UnsafeMutablePointer<T>) {
    let rows = Int(rowCount)
    let cols = Int(columnCount)
    let nnz = max(blockCount, 0)
    _ = blockSize
    var counts = [Int](repeating: 0, count: max(cols, 1))
    for i in 0..<nnz {
        let c = Int(column[i])
        if c >= 0 && c < cols { counts[c] += 1 }
    }
    let colStarts = UnsafeMutablePointer<Int>.allocate(capacity: cols + 1)
    colStarts[0] = 0
    for c in 0..<cols { colStarts[c + 1] = colStarts[c] + counts[c] }
    let rowIndices = UnsafeMutablePointer<Int32>.allocate(capacity: max(nnz, 1))
    let values = UnsafeMutablePointer<T>.allocate(capacity: max(nnz, 1))
    var next = [Int](repeating: 0, count: cols + 1)
    for c in 0...cols { next[c] = colStarts[c] }
    for i in 0..<nnz {
        let c = Int(column[i])
        let r = row[i]
        if c < 0 || c >= cols { continue }
        let dest = next[c]
        rowIndices[dest] = r
        values[dest] = data[i]
        next[c] = dest + 1
    }
    var structure = SparseMatrixStructure()
    structure.columnStarts.deallocate()
    structure.rowIndices.deallocate()
    structure.attributes = attributes
    structure.blockSize = blockSize == 0 ? 1 : blockSize
    structure.columnCount = columnCount
    structure.rowCount = rowCount
    structure.columnStarts = colStarts
    structure.rowIndices = rowIndices
    _ = rows
    return (structure, values)
}

func _sparseCleanupFloat(_ matrix: SparseMatrix_Float) {
    matrix.structure.columnStarts.deallocate()
    matrix.structure.rowIndices.deallocate()
    matrix.data.deallocate()
}

func _sparseCleanupDouble(_ matrix: SparseMatrix_Double) {
    matrix.structure.columnStarts.deallocate()
    matrix.structure.rowIndices.deallocate()
    matrix.data.deallocate()
}

import Foundation
import MetalPerformanceShaders

private func batchMatrix(rows: Int, columns: Int, rowBytes: Int, matrixBytes: Int,
                         offset: Int = 16, matrices: Int = 3) -> MPSMatrix {
    let device = MPSHostDevice.shared
    let buffer = device.makeBuffer(length: offset + matrices * matrixBytes + 16)
    let p = buffer.contents.bindMemory(to: Float.self, capacity: buffer.length / 4)
    for index in 0..<(buffer.length / 4) { p[index] = -999 }
    return MPSMatrix(buffer: buffer, offset: offset, descriptor: MPSMatrixDescriptor(
        rows: rows, columns: columns, matrices: matrices, rowBytes: rowBytes,
        matrixBytes: matrixBytes, dataType: .float32))
}

private func batchPut(_ matrix: MPSMatrix, batch: Int, values: [Float], transpose: Bool = false) {
    let p = matrix.data.contents.advanced(by: matrix.offset + batch * matrix.matrixBytes)
        .bindMemory(to: Float.self, capacity: matrix.matrixBytes / 4)
    for row in 0..<matrix.rows {
        for col in 0..<matrix.columns {
            p[row * matrix.rowBytes / 4 + col] = values[transpose ? col * matrix.rows + row : row * matrix.columns + col]
        }
    }
}

private func batchSnapshot(_ matrix: MPSMatrix) -> [Float] {
    Array(UnsafeBufferPointer(start: matrix.data.contents.bindMemory(to: Float.self,
        capacity: matrix.data.length / 4), count: matrix.data.length / 4))
}

private func batchExpect(_ matrix: MPSMatrix, batches: [[Float]?]) {
    var expected = [Float](repeating: -999, count: matrix.data.length / 4)
    for (batch, values) in batches.enumerated() {
        guard let values else { continue }
        for row in 0..<matrix.rows {
            for col in 0..<matrix.columns {
                expected[(matrix.offset + batch * matrix.matrixBytes + row * matrix.rowBytes) / 4 + col] = values[row * matrix.columns + col]
            }
        }
    }
    precondition(batchSnapshot(matrix) == expected, "Batch payload, prefix, row padding, matrix padding or suffix changed")
}

func testMPSMatrixBinaryKernelBatchedSoftMaxGradient() {
    let device = MPSHostDevice.shared
    let g = batchMatrix(rows: 1, columns: 2, rowBytes: 16, matrixBytes: 24)
    let y = batchMatrix(rows: 1, columns: 2, rowBytes: 20, matrixBytes: 32)
    let dx = batchMatrix(rows: 1, columns: 2, rowBytes: 24, matrixBytes: 40)
    batchPut(g, batch: 1, values: [2, 6]); batchPut(g, batch: 2, values: [8, -4])
    batchPut(y, batch: 1, values: [0.25, 0.75]); batchPut(y, batch: 2, values: [0.5, 0.5])
    let kernel = MPSMatrixSoftMaxGradient(device: device)
    let binary: MPSMatrixBinaryKernel = kernel
    binary.batchStart = 1; binary.batchSize = 2
    precondition(binary.batchStart == 1 && binary.batchSize == 2)
    kernel.sourceRows = 1; kernel.sourceColumns = 2
    let zero = MTLOrigin(x: 0, y: 0, z: 0)
    binary.primarySourceMatrixOrigin = zero
    binary.secondarySourceMatrixOrigin = zero
    binary.resultMatrixOrigin = zero
    precondition(binary.primarySourceMatrixOrigin == zero && binary.secondarySourceMatrixOrigin == zero
        && binary.resultMatrixOrigin == zero)
    let copied = kernel.copy(with: nil, device: nil)
    precondition(copied.batchStart == 1 && copied.batchSize == 2)
    copied.encode(to: device.makeCommandBuffer(), gradientMatrix: g, forwardOutputMatrix: y, resultMatrix: dx)
    batchExpect(dx, batches: [nil, [-0.75, 0.75], [3, -3]])
    batchExpect(g, batches: [nil, [2, 6], [8, -4]])
    batchExpect(y, batches: [nil, [0.25, 0.75], [0.5, 0.5]])
    // Unknown nonzero coordinate semantics are retained and refused, not ignored.
    let origins = [MTLOrigin(x: 1, y: 0, z: 0), MTLOrigin(x: 0, y: 2, z: 0), MTLOrigin(x: 0, y: 0, z: 3)]
    for index in origins.indices {
        binary.primarySourceMatrixOrigin = index == 0 ? origins[index] : zero
        binary.secondarySourceMatrixOrigin = index == 1 ? origins[index] : zero
        binary.resultMatrixOrigin = index == 2 ? origins[index] : zero
        let copy = kernel.copy(with: nil, device: nil)
        precondition(copy.primarySourceMatrixOrigin == binary.primarySourceMatrixOrigin)
        precondition(copy.secondarySourceMatrixOrigin == binary.secondarySourceMatrixOrigin)
        precondition(copy.resultMatrixOrigin == binary.resultMatrixOrigin)
        MPSHostBoundary.reset()
        copy.encode(to: device.makeCommandBuffer(), gradientMatrix: g, forwardOutputMatrix: y, resultMatrix: dx)
        precondition(MPSHostBoundary.lastRefusedAPI == "MPSMatrixSoftMaxGradient.encode")
        batchExpect(dx, batches: [nil, [-0.75, 0.75], [3, -3]])
    }
}

func testMPSMatrixBatchedGEMMAllTransposes() {
    for transposeLeft in [false, true] {
        for transposeRight in [false, true] {
            let a = batchMatrix(rows: transposeLeft ? 3 : 2, columns: transposeLeft ? 2 : 3,
                                rowBytes: 20, matrixBytes: 80)
            let b = batchMatrix(rows: transposeRight ? 2 : 3, columns: transposeRight ? 3 : 2,
                                rowBytes: 24, matrixBytes: 96)
            let c = batchMatrix(rows: 2, columns: 2, rowBytes: 28, matrixBytes: 112)
            // Logical A=[1,2,0;3,4,0], B=[5,6;7,8;0,0].
            // Second batch A=[2,0,1;-1,3,2], B=[1,2;4,5;-2,1].
            batchPut(a, batch: 1, values: [1,2,0,3,4,0], transpose: transposeLeft)
            batchPut(b, batch: 1, values: [5,6,7,8,0,0], transpose: transposeRight)
            batchPut(a, batch: 2, values: [2,0,1,-1,3,2], transpose: transposeLeft)
            batchPut(b, batch: 2, values: [1,2,4,5,-2,1], transpose: transposeRight)
            batchPut(c, batch: 1, values: [1,2,3,4]); batchPut(c, batch: 2, values: [3,2,1,0])
            let beforeA = batchSnapshot(a), beforeB = batchSnapshot(b)
            let kernel = MPSMatrixMultiplication(device: MPSHostDevice.shared,
                transposeLeft: transposeLeft, transposeRight: transposeRight,
                resultRows: 2, resultColumns: 2, interiorColumns: 3, alpha: 2, beta: -1)
            kernel.batchStart = 1; kernel.batchSize = 2
            kernel.encode(commandBuffer: MPSHostDevice.shared.makeCommandBuffer(), leftMatrix: a, rightMatrix: b, resultMatrix: c)
            // 2*A*B-C: [37,42;83,96], [-3,8;13,30].
            batchExpect(c, batches: [nil, [37,42,83,96], [-3,8,13,30]])
            precondition(batchSnapshot(a) == beforeA && batchSnapshot(b) == beforeB)
        }
    }
}

func testMPSMatrixBatchedPreflightIsAtomic() {
    let device = MPSHostDevice.shared
    let a = batchMatrix(rows: 1, columns: 2, rowBytes: 16, matrixBytes: 24)
    let b = batchMatrix(rows: 1, columns: 2, rowBytes: 20, matrixBytes: 32)
    let c = batchMatrix(rows: 1, columns: 2, rowBytes: 24, matrixBytes: 40)
    let kernel = MPSMatrixSoftMaxGradient(device: device)
    let before = batchSnapshot(c)
    for (start, size) in [(-1,1), (0,-1), (2,2), (Int.max,1), (1,Int.max)] {
        kernel.batchStart = start; kernel.batchSize = size
        MPSHostBoundary.reset()
        kernel.encode(to: device.makeCommandBuffer(), gradientMatrix: a, forwardOutputMatrix: b, resultMatrix: c)
        precondition(MPSHostBoundary.lastRefusedAPI == "MPSMatrixSoftMaxGradient.encode")
        precondition(batchSnapshot(c) == before)
    }
    kernel.batchStart = 0; kernel.batchSize = 3
    // Descriptor promises 3 matrices, backing buffer supplies only the first two.
    let short = MPSMatrix(buffer: device.makeBuffer(length: 64), descriptor:
        MPSMatrixDescriptor(rows: 1, columns: 2, matrices: 3, rowBytes: 20, matrixBytes: 32, dataType: .float32))
    MPSHostBoundary.reset()
    kernel.encode(to: device.makeCommandBuffer(), gradientMatrix: a, forwardOutputMatrix: short, resultMatrix: c)
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSMatrixSoftMaxGradient.encode")
    precondition(batchSnapshot(c) == before)
    kernel.batchStart = 3; kernel.batchSize = 0
    MPSHostBoundary.reset()
    kernel.encode(to: device.makeCommandBuffer(), gradientMatrix: a, forwardOutputMatrix: b, resultMatrix: c)
    precondition(MPSHostBoundary.lastRefusedAPI == nil && batchSnapshot(c) == before)
}

func testMPSMatrixGEMMZeroBetaAndInvalidBatch() {
    let device = MPSHostDevice.shared
    let a = batchMatrix(rows: 1, columns: 1, rowBytes: 4, matrixBytes: 8)
    let b = batchMatrix(rows: 1, columns: 1, rowBytes: 4, matrixBytes: 12)
    let c = batchMatrix(rows: 1, columns: 1, rowBytes: 4, matrixBytes: 16)
    batchPut(a, batch: 0, values: [2]); batchPut(b, batch: 0, values: [3])
    batchPut(c, batch: 0, values: [.nan])
    let kernel = MPSMatrixMultiplication(device: device, resultRows: 1, resultColumns: 1, interiorColumns: 1)
    kernel.encode(commandBuffer: device.makeCommandBuffer(), leftMatrix: a, rightMatrix: b, resultMatrix: c)
    batchExpect(c, batches: [[6], nil, nil])
    kernel.batchSize = 4
    MPSHostBoundary.reset()
    kernel.encode(commandBuffer: device.makeCommandBuffer(), leftMatrix: a, rightMatrix: b, resultMatrix: c)
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSMatrixMultiplication.encode")
    batchExpect(c, batches: [[6], nil, nil])
    kernel.batchSize = 1; kernel.leftMatrixOrigin.x = Int.max
    MPSHostBoundary.reset()
    kernel.encode(commandBuffer: device.makeCommandBuffer(), leftMatrix: a, rightMatrix: b, resultMatrix: c)
    precondition(MPSHostBoundary.lastRefusedAPI == "MPSMatrixMultiplication.encode")
    batchExpect(c, batches: [[6], nil, nil])
}

import Foundation

open class MPSMatrixCopyDescriptor: NSObject {
    public private(set) var count: Int
    private var sources: [MPSMatrix?]
    private var destinations: [MPSMatrix?]
    private var offsets: [MPSMatrixCopyOffsets]

    public init(device: any MTLDevice, count: Int) {
        _ = device
        self.count = max(count, 0)
        self.sources = Array(repeating: nil, count: self.count)
        self.destinations = Array(repeating: nil, count: self.count)
        self.offsets = Array(repeating: MPSMatrixCopyOffsets(), count: self.count)
        super.init()
    }

    public convenience init(
        sourceMatrix: MPSMatrix,
        destinationMatrix: MPSMatrix,
        offsets: MPSMatrixCopyOffsets
    ) {
        self.init(device: sourceMatrix.device, count: 1)
        setCopyOperationAt(0, sourceMatrix: sourceMatrix, destinationMatrix: destinationMatrix, offsets: offsets)
    }

    public init(
        sourceMatrices: [MPSMatrix],
        destinationMatrices: [MPSMatrix],
        offsetVector offsets: MPSVector?,
        offset byteOffset: Int
    ) {
        _ = (offsets, byteOffset)
        self.count = min(sourceMatrices.count, destinationMatrices.count)
        self.sources = sourceMatrices
        self.destinations = destinationMatrices
        self.offsets = Array(repeating: MPSMatrixCopyOffsets(), count: self.count)
        super.init()
    }

    public func setCopyOperationAt(
        _ index: Int,
        sourceMatrix: MPSMatrix,
        destinationMatrix: MPSMatrix,
        offsets: MPSMatrixCopyOffsets
    ) {
        guard sources.indices.contains(index) else { return }
        sources[index] = sourceMatrix
        destinations[index] = destinationMatrix
        self.offsets[index] = offsets
    }

    func operation(at index: Int) -> (MPSMatrix, MPSMatrix, MPSMatrixCopyOffsets)? {
        guard sources.indices.contains(index),
              let source = sources[index],
              let destination = destinations[index]
        else { return nil }
        return (source, destination, offsets[index])
    }
}

open class MPSMatrixCopy: MPSKernel {
    public private(set) var copyRows: Int
    public private(set) var copyColumns: Int
    public private(set) var sourcesAreTransposed: Bool
    public private(set) var destinationsAreTransposed: Bool

    public required init(device: any MTLDevice) {
        self.copyRows = 1
        self.copyColumns = 1
        self.sourcesAreTransposed = false
        self.destinationsAreTransposed = false
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        copyRows: Int,
        copyColumns: Int,
        sourcesAreTransposed: Bool,
        destinationsAreTransposed: Bool
    ) {
        self.copyRows = max(copyRows, 0)
        self.copyColumns = max(copyColumns, 0)
        self.sourcesAreTransposed = sourcesAreTransposed
        self.destinationsAreTransposed = destinationsAreTransposed
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(commandBuffer: any MTLCommandBuffer, copyDescriptor: MPSMatrixCopyDescriptor) {
        _ = commandBuffer
        mpsCopyMatrices(copyDescriptor: copyDescriptor, rows: copyRows, columns: copyColumns)
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        copyDescriptor: MPSMatrixCopyDescriptor,
        rowPermuteIndices: MPSVector?,
        rowPermuteOffset: Int,
        columnPermuteIndices: MPSVector?,
        columnPermuteOffset: Int
    ) {
        _ = (rowPermuteIndices, rowPermuteOffset, columnPermuteIndices, columnPermuteOffset)
        encode(commandBuffer: commandBuffer, copyDescriptor: copyDescriptor)
    }
}

// Host binary kernels retain SDK configuration. Nonzero origins remain
// fail-closed until an oracle establishes their coordinate conventions.
open class MPSMatrixBinaryKernel: MPSKernel {
    public var primarySourceMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var secondarySourceMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var resultMatrixOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var batchStart: Int = 0
    public var batchSize: Int = 1

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = super.copy(with: zone, device: device)
        copyBinaryConfiguration(to: copied)
        return copied
    }

    func copyBinaryConfiguration(to copied: MPSMatrixBinaryKernel) {
        copied.primarySourceMatrixOrigin = primarySourceMatrixOrigin
        copied.secondarySourceMatrixOrigin = secondarySourceMatrixOrigin
        copied.resultMatrixOrigin = resultMatrixOrigin
        copied.batchStart = batchStart
        copied.batchSize = batchSize
    }

    var hasHostOrigins: Bool {
        let zero = MTLOrigin(x: 0, y: 0, z: 0)
        return primarySourceMatrixOrigin == zero && secondarySourceMatrixOrigin == zero
            && resultMatrixOrigin == zero
    }
}

// Validate the complete batch before any write. Division-based checks avoid
// overflow even for adversarial descriptor sizes, offsets and batch ranges.
func mpsHostMatrixRegionFits(
    _ matrix: MPSMatrix, rows: Int, columns: Int, origin: MTLOrigin,
    batchStart: Int, batchSize: Int
) -> Bool {
    guard matrix.dataType == .float32, rows >= 0, columns >= 0,
          origin.x >= 0, origin.y >= 0, origin.z == 0,
          matrix.rows >= origin.y, rows <= matrix.rows - origin.y,
          matrix.columns >= origin.x, columns <= matrix.columns - origin.x,
          matrix.rowBytes > 0, matrix.rowBytes % 4 == 0,
          matrix.columns <= matrix.rowBytes / 4,
          matrix.matrixBytes > 0, matrix.matrixBytes % 4 == 0,
          matrix.rows <= matrix.matrixBytes / matrix.rowBytes,
          matrix.offset >= 0, matrix.offset % 4 == 0, matrix.offset <= matrix.data.length,
          batchStart >= 0, batchSize >= 0, batchStart <= matrix.matrices,
          batchSize <= matrix.matrices - batchStart
    else { return false }
    let availableMatrices = (matrix.data.length - matrix.offset) / matrix.matrixBytes
    return batchStart <= availableMatrices && batchSize <= availableMatrices - batchStart
}

open class MPSMatrixMultiplication: MPSKernel {
    public private(set) var transposeLeft: Bool
    public private(set) var transposeRight: Bool
    public private(set) var resultRows: Int
    public private(set) var resultColumns: Int
    public private(set) var interiorColumns: Int
    public private(set) var alpha: Double
    public private(set) var beta: Double
    public var resultMatrixOrigin: MTLOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var leftMatrixOrigin: MTLOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var rightMatrixOrigin: MTLOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var batchStart: Int = 0
    public var batchSize: Int = 1

    public required init(device: any MTLDevice) {
        self.transposeLeft = false
        self.transposeRight = false
        self.resultRows = 1
        self.resultColumns = 1
        self.interiorColumns = 1
        self.alpha = 1
        self.beta = 0
        super.init(device: device)
    }

    public init(device: any MTLDevice, resultRows: Int, resultColumns: Int, interiorColumns: Int) {
        self.transposeLeft = false
        self.transposeRight = false
        self.resultRows = max(resultRows, 0)
        self.resultColumns = max(resultColumns, 0)
        self.interiorColumns = max(interiorColumns, 0)
        self.alpha = 1
        self.beta = 0
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        transposeLeft: Bool,
        transposeRight: Bool,
        resultRows: Int,
        resultColumns: Int,
        interiorColumns: Int,
        alpha: Double,
        beta: Double
    ) {
        self.transposeLeft = transposeLeft
        self.transposeRight = transposeRight
        self.resultRows = max(resultRows, 0)
        self.resultColumns = max(resultColumns, 0)
        self.interiorColumns = max(interiorColumns, 0)
        self.alpha = alpha
        self.beta = beta
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        leftMatrix: MPSMatrix,
        rightMatrix: MPSMatrix,
        resultMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard leftMatrix.dataType == .float32,
              rightMatrix.dataType == .float32,
              resultMatrix.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixMultiplication.encode")
            return
        }
        guard mpsHostMatrixRegionFits(leftMatrix,
                rows: transposeLeft ? interiorColumns : resultRows,
                columns: transposeLeft ? resultRows : interiorColumns,
                origin: leftMatrixOrigin, batchStart: batchStart, batchSize: batchSize),
              mpsHostMatrixRegionFits(rightMatrix,
                rows: transposeRight ? resultColumns : interiorColumns,
                columns: transposeRight ? interiorColumns : resultColumns,
                origin: rightMatrixOrigin, batchStart: batchStart, batchSize: batchSize),
              mpsHostMatrixRegionFits(resultMatrix, rows: resultRows, columns: resultColumns,
                origin: resultMatrixOrigin, batchStart: batchStart, batchSize: batchSize),
              resultMatrix.data !== leftMatrix.data, resultMatrix.data !== rightMatrix.data
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixMultiplication.encode")
            return
        }
        // BatchedCPUTests: batches 1/2 at independent 80/96/112-byte strides;
        // 2*A*B-C yields [37,42;83,96] and [-3,8;13,30].
        for batch in batchStart..<(batchStart + batchSize) {
            mpsGEMM(
                left: leftMatrix,
                right: rightMatrix,
                result: resultMatrix,
                transposeLeft: transposeLeft,
                transposeRight: transposeRight,
                m: resultRows,
                n: resultColumns,
                k: interiorColumns,
                alpha: Float(alpha),
                beta: Float(beta),
                leftOrigin: leftMatrixOrigin,
                rightOrigin: rightMatrixOrigin,
                resultOrigin: resultMatrixOrigin,
                batchIndex: batch
            )
        }
    }
}

open class MPSMatrixVectorMultiplication: MPSKernel {
    public private(set) var transpose: Bool
    public private(set) var rows: Int
    public private(set) var columns: Int
    public private(set) var alpha: Double
    public private(set) var beta: Double

    public required init(device: any MTLDevice) {
        self.transpose = false
        self.rows = 1
        self.columns = 1
        self.alpha = 1
        self.beta = 0
        super.init(device: device)
    }

    public init(device: any MTLDevice, rows: Int, columns: Int) {
        self.transpose = false
        self.rows = max(rows, 0)
        self.columns = max(columns, 0)
        self.alpha = 1
        self.beta = 0
        super.init(device: device)
    }

    public init(
        device: any MTLDevice,
        transpose: Bool,
        rows: Int,
        columns: Int,
        alpha: Double,
        beta: Double
    ) {
        self.transpose = transpose
        self.rows = max(rows, 0)
        self.columns = max(columns, 0)
        self.alpha = alpha
        self.beta = beta
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputMatrix: MPSMatrix,
        inputVector: MPSVector,
        resultVector: MPSVector
    ) {
        _ = commandBuffer
        guard inputMatrix.dataType == .float32,
              inputVector.dataType == .float32,
              resultVector.dataType == .float32
        else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixVectorMultiplication.encode")
            return
        }
        mpsGEMV(
            matrix: inputMatrix,
            vector: inputVector,
            result: resultVector,
            transpose: transpose,
            rows: rows,
            columns: columns,
            alpha: Float(alpha),
            beta: Float(beta)
        )
    }
}

open class MPSImageCopyToMatrix: MPSKernel {
    public private(set) var dataLayout: MPSDataLayout
    public var destinationMatrixOrigin: MTLOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var destinationMatrixBatchIndex: Int = 0

    public required init(device: any MTLDevice) {
        self.dataLayout = .HeightxWidthxFeatureChannels
        super.init(device: device)
    }

    public init(device: any MTLDevice, dataLayout: MPSDataLayout) {
        self.dataLayout = dataLayout
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceImage: MPSImage,
        destinationMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        mpsCopyImageToMatrix(
            image: sourceImage,
            matrix: destinationMatrix,
            origin: destinationMatrixOrigin,
            layout: dataLayout
        )
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceImages: [MPSImage],
        destinationMatrix: MPSMatrix
    ) {
        guard let first = sourceImages.first else { return }
        encode(commandBuffer: commandBuffer, sourceImage: first, destinationMatrix: destinationMatrix)
    }
}

open class MPSMatrixCopyToImage: MPSKernel {
    public private(set) var dataLayout: MPSDataLayout
    public var sourceMatrixOrigin: MTLOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    public var sourceMatrixBatchIndex: Int = 0

    public required init(device: any MTLDevice) {
        self.dataLayout = .HeightxWidthxFeatureChannels
        super.init(device: device)
    }

    public init(device: any MTLDevice, dataLayout: MPSDataLayout) {
        self.dataLayout = dataLayout
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrix: MPSMatrix,
        destinationImage: MPSImage
    ) {
        _ = commandBuffer
        mpsCopyMatrixToImage(
            matrix: sourceMatrix,
            image: destinationImage,
            origin: sourceMatrixOrigin,
            layout: dataLayout
        )
    }

    open func encodeBatch(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrix: MPSMatrix,
        destinationImages: [MPSImage]
    ) {
        guard let first = destinationImages.first else { return }
        encode(commandBuffer: commandBuffer, sourceMatrix: sourceMatrix, destinationImage: first)
    }
}

func mpsFloatBuffer(_ buffer: any MTLBuffer, offset: Int = 0) -> UnsafeMutablePointer<Float> {
    buffer.contents.advanced(by: max(offset, 0)).bindMemory(to: Float.self, capacity: max((buffer.length - offset) / 4, 1))
}

func mpsGEMM(
    left: MPSMatrix,
    right: MPSMatrix,
    result: MPSMatrix,
    transposeLeft: Bool,
    transposeRight: Bool,
    m: Int,
    n: Int,
    k: Int,
    alpha: Float,
    beta: Float,
    leftOrigin: MTLOrigin,
    rightOrigin: MTLOrigin,
    resultOrigin: MTLOrigin,
    batchIndex: Int = 0
) {
    let a = mpsFloatBuffer(left.data, offset: left.offset + batchIndex * left.matrixBytes)
    let b = mpsFloatBuffer(right.data, offset: right.offset + batchIndex * right.matrixBytes)
    let c = mpsFloatBuffer(result.data, offset: result.offset + batchIndex * result.matrixBytes)
    let lda = max(left.rowBytes / 4, 1)
    let ldb = max(right.rowBytes / 4, 1)
    let ldc = max(result.rowBytes / 4, 1)
    for row in 0..<m {
        for col in 0..<n {
            var acc: Float = 0
            for inner in 0..<k {
                let aRow = transposeLeft ? inner + leftOrigin.y : row + leftOrigin.y
                let aCol = transposeLeft ? row + leftOrigin.x : inner + leftOrigin.x
                let bRow = transposeRight ? col + rightOrigin.y : inner + rightOrigin.y
                let bCol = transposeRight ? inner + rightOrigin.x : col + rightOrigin.x
                acc += a[aRow * lda + aCol] * b[bRow * ldb + bCol]
            }
            let cIndex = (row + resultOrigin.y) * ldc + (col + resultOrigin.x)
            // beta=0 must not read uninitialized/NaN destination values.
            c[cIndex] = beta == 0 ? alpha * acc : alpha * acc + beta * c[cIndex]
        }
    }
}

func mpsGEMV(
    matrix: MPSMatrix,
    vector: MPSVector,
    result: MPSVector,
    transpose: Bool,
    rows: Int,
    columns: Int,
    alpha: Float,
    beta: Float
) {
    let a = mpsFloatBuffer(matrix.data, offset: matrix.offset)
    let x = mpsFloatBuffer(vector.data, offset: vector.offset)
    let y = mpsFloatBuffer(result.data, offset: result.offset)
    let lda = max(matrix.rowBytes / 4, 1)
    let outCount = transpose ? columns : rows
    let innerCount = transpose ? rows : columns
    for i in 0..<outCount {
        var acc: Float = 0
        for j in 0..<innerCount {
            let aVal = transpose ? a[j * lda + i] : a[i * lda + j]
            acc += aVal * x[j]
        }
        y[i] = alpha * acc + beta * y[i]
    }
}

open class MPSMatrixFindTopK: MPSKernel {
    public private(set) var numberOfTopKValues: Int
    public var indexOffset: Int = 0
    public var sourceRows: Int = 0
    public var sourceColumns: Int = 0

    public required init(device: any MTLDevice) {
        self.numberOfTopKValues = 1
        super.init(device: device)
    }

    public init(device: any MTLDevice, numberOfTopKValues: Int) {
        self.numberOfTopKValues = max(numberOfTopKValues, 1)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixFindTopK(device: device ?? self.device, numberOfTopKValues: numberOfTopKValues)
        copied.options = options
        copied.label = label
        copied.indexOffset = indexOffset
        copied.sourceRows = sourceRows
        copied.sourceColumns = sourceColumns
        return copied as! Self
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        inputMatrix: MPSMatrix,
        resultIndexMatrix: MPSMatrix,
        resultValueMatrix: MPSMatrix
    ) {
        _ = commandBuffer
        guard inputMatrix.dataType == .float32, resultValueMatrix.dataType == .float32 else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixFindTopK.encode")
            return
        }
        let rows = sourceRows > 0 ? sourceRows : inputMatrix.rows
        let columns = sourceColumns > 0 ? sourceColumns : inputMatrix.columns
        let k = min(numberOfTopKValues, columns)
        let a = mpsFloatBuffer(inputMatrix.data, offset: inputMatrix.offset)
        let lda = max(inputMatrix.rowBytes / 4, 1)
        let values = mpsFloatBuffer(resultValueMatrix.data, offset: resultValueMatrix.offset)
        let ldc = max(resultValueMatrix.rowBytes / 4, 1)
        let indices = resultIndexMatrix.data.contents.advanced(by: resultIndexMatrix.offset).bindMemory(
            to: UInt32.self,
            capacity: max(resultIndexMatrix.data.length / 4, 1)
        )
        let ldi = max(resultIndexMatrix.rowBytes / 4, 1)
        for row in 0..<rows {
            var pairs: [(Float, Int)] = []
            pairs.reserveCapacity(columns)
            for col in 0..<columns {
                pairs.append((a[row * lda + col], col))
            }
            pairs.sort { lhs, rhs in
                if lhs.0 == rhs.0 { return lhs.1 < rhs.1 }
                return lhs.0 > rhs.0
            }
            for i in 0..<k {
                values[row * ldc + i] = pairs[i].0
                indices[row * ldi + i] = UInt32(pairs[i].1 + indexOffset)
            }
        }
    }
}

open class MPSMatrixSoftMax: MPSKernel {
    public var sourceRows: Int = 0
    public var sourceColumns: Int = 0

    public required init(device: any MTLDevice) {
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = MPSMatrixSoftMax(device: device ?? self.device)
        copied.options = options
        copied.label = label
        copied.sourceRows = sourceRows
        copied.sourceColumns = sourceColumns
        return copied as! Self
    }

    open func encode(commandBuffer: any MTLCommandBuffer, inputMatrix: MPSMatrix, resultMatrix: MPSMatrix) {
        _ = commandBuffer
        guard inputMatrix.dataType == .float32, resultMatrix.dataType == .float32 else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixSoftMax.encode")
            return
        }
        let rows = sourceRows > 0 ? sourceRows : inputMatrix.rows
        let columns = sourceColumns > 0 ? sourceColumns : inputMatrix.columns
        let a = mpsFloatBuffer(inputMatrix.data, offset: inputMatrix.offset)
        let c = mpsFloatBuffer(resultMatrix.data, offset: resultMatrix.offset)
        let lda = max(inputMatrix.rowBytes / 4, 1)
        let ldc = max(resultMatrix.rowBytes / 4, 1)
        for row in 0..<rows {
            var maxValue = a[row * lda]
            for col in 1..<columns {
                maxValue = max(maxValue, a[row * lda + col])
            }
            var sum: Float = 0
            for col in 0..<columns {
                let e = exp(a[row * lda + col] - maxValue)
                c[row * ldc + col] = e
                sum += e
            }
            if sum == 0 { continue }
            for col in 0..<columns {
                c[row * ldc + col] /= sum
            }
        }
    }
}

open class MPSMatrixSum: MPSKernel {
    public private(set) var count: Int
    public private(set) var rows: Int
    public private(set) var columns: Int
    public private(set) var transpose: Bool
    public var resultMatrixOrigin: MTLOrigin = MTLOrigin(x: 0, y: 0, z: 0)
    private var neuron: MPSCNNNeuronType = .none
    private var neuronA: Float = 0
    private var neuronB: Float = 0
    private var neuronC: Float = 0

    public required init(device: any MTLDevice) {
        self.count = 1
        self.rows = 1
        self.columns = 1
        self.transpose = false
        super.init(device: device)
    }

    public init(device: any MTLDevice, count: Int, rows: Int, columns: Int, transpose: Bool) {
        self.count = max(count, 0)
        self.rows = max(rows, 0)
        self.columns = max(columns, 0)
        self.transpose = transpose
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) {
        return nil
    }

    open func neuronType() -> MPSCNNNeuronType { neuron }
    public var neuronParameterA: Float { neuronA }
    public var neuronParameterB: Float { neuronB }
    public var neuronParameterC: Float { neuronC }

    open func setNeuronType(_ neuronType: MPSCNNNeuronType, parameterA: Float, parameterB: Float, parameterC: Float) {
        neuron = neuronType
        neuronA = parameterA
        neuronB = parameterB
        neuronC = parameterC
    }

    open func encode(
        commandBuffer: any MTLCommandBuffer,
        sourceMatrices: [MPSMatrix],
        resultMatrix: MPSMatrix,
        scaleVector: MPSVector?,
        offsetVector: MPSVector?,
        biasVector: MPSVector?,
        startIndex: Int
    ) {
        _ = commandBuffer
        guard resultMatrix.dataType == .float32 else {
            MPSHostBoundary.refuseGPUEncode("MPSMatrixSum.encode")
            return
        }
        let c = mpsFloatBuffer(resultMatrix.data, offset: resultMatrix.offset)
        let ldc = max(resultMatrix.rowBytes / 4, 1)
        let origin = resultMatrixOrigin
        for row in 0..<rows {
            for col in 0..<columns {
                c[(row + origin.y) * ldc + (col + origin.x)] = 0
            }
        }
        let limit = min(count, sourceMatrices.count)
        for index in 0..<limit {
            let matrix = sourceMatrices[index]
            guard matrix.dataType == .float32 else { continue }
            let a = mpsFloatBuffer(matrix.data, offset: matrix.offset)
            let lda = max(matrix.rowBytes / 4, 1)
            var scale: Float = 1
            if let scaleVector {
                scale = mpsFloatBuffer(scaleVector.data, offset: scaleVector.offset)[startIndex + index]
            }
            var rowOff = 0
            var colOff = 0
            if let offsetVector {
                let offs = offsetVector.data.contents.advanced(by: offsetVector.offset).bindMemory(
                    to: Int32.self,
                    capacity: max(offsetVector.data.length / 4, 1)
                )
                rowOff = Int(offs[(startIndex + index) * 2])
                colOff = Int(offs[(startIndex + index) * 2 + 1])
            }
            for row in 0..<rows {
                for col in 0..<columns {
                    let src = transpose ? a[(col + colOff) * lda + (row + rowOff)] : a[(row + rowOff) * lda + (col + colOff)]
                    c[(row + origin.y) * ldc + (col + origin.x)] += scale * src
                }
            }
        }
        if let biasVector, biasVector.dataType == .float32 {
            let bias = mpsFloatBuffer(biasVector.data, offset: biasVector.offset)
            for row in 0..<rows {
                for col in 0..<columns {
                    c[(row + origin.y) * ldc + (col + origin.x)] += bias[col]
                }
            }
        }
        if neuron == .reLU {
            for row in 0..<rows {
                for col in 0..<columns {
                    let idx = (row + origin.y) * ldc + (col + origin.x)
                    if c[idx] < 0 { c[idx] *= neuronA }
                }
            }
        }
    }
}

func mpsCopyMatrices(copyDescriptor: MPSMatrixCopyDescriptor, rows: Int, columns: Int) {
    for index in 0..<copyDescriptor.count {
        guard let (source, destination, offsets) = copyDescriptor.operation(at: index) else { continue }
        let src = source.data.contents
        let dst = destination.data.contents
        let srcStride = source.rowBytes
        let dstStride = destination.rowBytes
        let element = max(MPSSizeofMPSDataType(source.dataType), 1)
        for row in 0..<rows {
            let srcRow = Int(offsets.sourceRowOffset) + row
            let dstRow = Int(offsets.destinationRowOffset) + row
            let srcOff = srcRow * srcStride + Int(offsets.sourceColumnOffset) * element
            let dstOff = dstRow * dstStride + Int(offsets.destinationColumnOffset) * element
            dst.advanced(by: dstOff).copyMemory(from: src.advanced(by: srcOff), byteCount: columns * element)
        }
    }
}

func mpsCopyImageToMatrix(
    image: MPSImage,
    matrix: MPSMatrix,
    origin: MTLOrigin,
    layout: MPSDataLayout
) {
    _ = layout
    let width = image.width
    let height = image.height
    let channels = image.featureChannels
    let bytes = width * height * channels * image.pixelSize
    var storage = [UInt8](repeating: 0, count: max(bytes, 0))
    storage.withUnsafeMutableBytes { raw in
        image.readBytes(raw.baseAddress!, dataLayout: .HeightxWidthxFeatureChannels, imageIndex: 0)
        let dst = matrix.data.contents.advanced(by: origin.y * matrix.rowBytes + origin.x * max(MPSSizeofMPSDataType(matrix.dataType), 1))
        dst.copyMemory(from: raw.baseAddress!, byteCount: min(bytes, matrix.data.length))
    }
}

func mpsCopyMatrixToImage(
    matrix: MPSMatrix,
    image: MPSImage,
    origin: MTLOrigin,
    layout: MPSDataLayout
) {
    _ = (origin, layout)
    let width = image.width
    let height = image.height
    let channels = image.featureChannels
    let bytes = width * height * channels * image.pixelSize
    image.writeBytes(
        matrix.data.contents,
        dataLayout: .HeightxWidthxFeatureChannels,
        imageIndex: 0
    )
    _ = bytes
}

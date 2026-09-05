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
            resultOrigin: resultMatrixOrigin
        )
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

func mpsFloatBuffer(_ buffer: any MTLBuffer) -> UnsafeMutablePointer<Float> {
    buffer.contents.bindMemory(to: Float.self, capacity: max(buffer.length / 4, 1))
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
    resultOrigin: MTLOrigin
) {
    let a = mpsFloatBuffer(left.data)
    let b = mpsFloatBuffer(right.data)
    let c = mpsFloatBuffer(result.data)
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
            c[cIndex] = alpha * acc + beta * c[cIndex]
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
    let a = mpsFloatBuffer(matrix.data)
    let x = mpsFloatBuffer(vector.data)
    let y = mpsFloatBuffer(result.data)
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

import Foundation

open class MPSMatrixDescriptor: NSObject {
    public var rows: Int
    public var columns: Int
    public var rowBytes: Int
    public var dataType: MPSDataType
    public private(set) var matrices: Int
    public private(set) var matrixBytes: Int

    public convenience init(rows: Int, columns: Int, rowBytes: Int, dataType: MPSDataType) {
        self.init(
            rows: rows,
            columns: columns,
            matrices: 1,
            rowBytes: rowBytes,
            matrixBytes: rowBytes * rows,
            dataType: dataType
        )
    }

    public convenience init(dimensions rows: Int, columns: Int, rowBytes: Int, dataType: MPSDataType) {
        self.init(rows: rows, columns: columns, rowBytes: rowBytes, dataType: dataType)
    }

    public convenience init(
        rows: Int,
        columns: Int,
        matrices: Int,
        rowBytes: Int,
        matrixBytes: Int,
        dataType: MPSDataType
    ) {
        self.init()
        self.rows = rows
        self.columns = columns
        self.matrices = max(matrices, 1)
        self.rowBytes = rowBytes
        self.matrixBytes = matrixBytes
        self.dataType = dataType
    }

    public override init() {
        self.rows = 1
        self.columns = 1
        self.rowBytes = 4
        self.dataType = .float32
        self.matrices = 1
        self.matrixBytes = 4
        super.init()
    }

    public class func rowBytes(forColumns columns: Int, dataType: MPSDataType) -> Int {
        let stride = max(MPSSizeofMPSDataType(dataType), 1)
        return columns * stride
    }

    public class func rowBytes(fromColumns columns: Int, dataType: MPSDataType) -> Int {
        rowBytes(forColumns: columns, dataType: dataType)
    }
}

open class MPSVectorDescriptor: NSObject {
    public var length: Int
    public var dataType: MPSDataType
    public private(set) var vectors: Int
    public private(set) var vectorBytes: Int

    public convenience init(length: Int, dataType: MPSDataType) {
        self.init(length: length, vectors: 1, vectorBytes: MPSVectorDescriptor.vectorBytes(forLength: length, dataType: dataType), dataType: dataType)
    }

    public convenience init(length: Int, vectors: Int, vectorBytes: Int, dataType: MPSDataType) {
        self.init()
        self.length = length
        self.vectors = max(vectors, 1)
        self.vectorBytes = vectorBytes
        self.dataType = dataType
    }

    public override init() {
        self.length = 1
        self.dataType = .float32
        self.vectors = 1
        self.vectorBytes = 4
        super.init()
    }

    public class func vectorBytes(forLength length: Int, dataType: MPSDataType) -> Int {
        max(length, 0) * max(MPSSizeofMPSDataType(dataType), 1)
    }
}

open class MPSMatrix: NSObject {
    public private(set) var device: any MTLDevice
    public private(set) var rows: Int
    public private(set) var columns: Int
    public private(set) var rowBytes: Int
    public private(set) var dataType: MPSDataType
    public private(set) var matrices: Int
    public private(set) var matrixBytes: Int
    public private(set) var offset: Int
    public private(set) var data: any MTLBuffer

    public init(device: any MTLDevice, descriptor: MPSMatrixDescriptor) {
        self.device = device
        self.rows = descriptor.rows
        self.columns = descriptor.columns
        self.rowBytes = descriptor.rowBytes
        self.dataType = descriptor.dataType
        self.matrices = descriptor.matrices
        self.matrixBytes = descriptor.matrixBytes
        self.offset = 0
        let length = max(descriptor.matrixBytes * descriptor.matrices, descriptor.rowBytes * descriptor.rows)
        if let host = device as? MPSHostDevice {
            self.data = host.makeBuffer(length: length)
        } else {
            self.data = MPSHostBuffer(device: device, length: length)
        }
        super.init()
    }

    public convenience init(buffer: any MTLBuffer, descriptor: MPSMatrixDescriptor) {
        self.init(buffer: buffer, offset: 0, descriptor: descriptor)
    }

    public init(buffer: any MTLBuffer, offset: Int, descriptor: MPSMatrixDescriptor) {
        self.device = buffer.device
        self.data = buffer
        self.offset = offset
        self.rows = descriptor.rows
        self.columns = descriptor.columns
        self.rowBytes = descriptor.rowBytes
        self.dataType = descriptor.dataType
        self.matrices = descriptor.matrices
        self.matrixBytes = descriptor.matrixBytes
        super.init()
    }

    open func resourceSize() -> Int {
        max(matrixBytes * matrices, data.length)
    }

    open func synchronize(on commandBuffer: any MTLCommandBuffer) {
        _ = commandBuffer
    }
}

open class MPSVector: NSObject {
    public private(set) var device: any MTLDevice
    public private(set) var length: Int
    public private(set) var vectors: Int
    public private(set) var vectorBytes: Int
    public private(set) var dataType: MPSDataType
    public private(set) var offset: Int
    public private(set) var data: any MTLBuffer

    public init(device: any MTLDevice, descriptor: MPSVectorDescriptor) {
        self.device = device
        self.length = descriptor.length
        self.vectors = descriptor.vectors
        self.vectorBytes = descriptor.vectorBytes
        self.dataType = descriptor.dataType
        self.offset = 0
        let size = max(descriptor.vectorBytes * descriptor.vectors, descriptor.length * MPSSizeofMPSDataType(descriptor.dataType))
        if let host = device as? MPSHostDevice {
            self.data = host.makeBuffer(length: size)
        } else {
            self.data = MPSHostBuffer(device: device, length: size)
        }
        super.init()
    }

    public convenience init(buffer: any MTLBuffer, descriptor: MPSVectorDescriptor) {
        self.init(buffer: buffer, offset: 0, descriptor: descriptor)
    }

    public init(buffer: any MTLBuffer, offset: Int, descriptor: MPSVectorDescriptor) {
        self.device = buffer.device
        self.data = buffer
        self.offset = offset
        self.length = descriptor.length
        self.vectors = descriptor.vectors
        self.vectorBytes = descriptor.vectorBytes
        self.dataType = descriptor.dataType
        super.init()
    }

    open func resourceSize() -> Int {
        max(vectorBytes * vectors, data.length)
    }

    open func synchronize(on commandBuffer: any MTLCommandBuffer) {
        _ = commandBuffer
    }
}

open class MPSTemporaryMatrix: MPSMatrix {
    public var readCount: Int = 1

    public class func prefetchStorage(
        with commandBuffer: any MTLCommandBuffer,
        matrixDescriptorList descriptorList: [MPSMatrixDescriptor]
    ) {
        _ = (commandBuffer, descriptorList)
    }

    public convenience init(
        commandBuffer: any MTLCommandBuffer,
        matrixDescriptor: MPSMatrixDescriptor
    ) {
        self.init(device: commandBuffer.device, descriptor: matrixDescriptor)
        readCount = 1
    }
}

open class MPSTemporaryVector: MPSVector {
    public var readCount: Int = 1

    public class func prefetchStorage(
        with commandBuffer: any MTLCommandBuffer,
        descriptorList: [MPSVectorDescriptor]
    ) {
        _ = (commandBuffer, descriptorList)
    }

    public convenience init(
        commandBuffer: any MTLCommandBuffer,
        descriptor: MPSVectorDescriptor
    ) {
        self.init(device: commandBuffer.device, descriptor: descriptor)
        readCount = 1
    }
}

import Foundation

open class MPSGraphObject: NSObject {}

open class MPSGraphType: MPSGraphObject {}

open class MPSGraphShapedType: MPSGraphType {
    public var shape: [NSNumber]?
    public var dataType: MPSDataType

    public init(shape: [NSNumber]?, dataType: MPSDataType) {
        self.shape = shape
        self.dataType = dataType
        super.init()
    }

    public func isEqual(to object: MPSGraphShapedType?) -> Bool {
        guard let object else { return false }
        return dataType == object.dataType && Self.shapesEqual(shape, object.shape)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MPSGraphShapedType else { return false }
        return isEqual(to: other)
    }

    private static func shapesEqual(_ a: [NSNumber]?, _ b: [NSNumber]?) -> Bool {
        switch (a, b) {
        case (nil, nil):
            return true
        case let (x?, y?):
            return x.map(\.intValue) == y.map(\.intValue)
        default:
            return false
        }
    }
}

open class MPSGraphDevice: MPSGraphObject {
    public var type: MPSGraphDeviceType { .metal }

    /// Host device used when Metal is not imported. `type` remains `.metal`
    /// because that is the only documented enumerator; this is not a GPU.
    public static func hostDevice() -> MPSGraphDevice {
        MPSGraphDevice()
    }
}

open class MPSGraphOperation: MPSGraphObject {
    public private(set) var graph: MPSGraph
    public private(set) var inputTensors: [MPSGraphTensor]
    public private(set) var outputTensors: [MPSGraphTensor]
    public private(set) var controlDependencies: [MPSGraphOperation]
    public private(set) var name: String
    let kind: String
    let attributes: [String: Any]

    init(
        graph: MPSGraph,
        kind: String,
        inputs: [MPSGraphTensor],
        name: String?,
        attributes: [String: Any] = [:]
    ) {
        self.graph = graph
        self.kind = kind
        self.inputTensors = inputs
        self.outputTensors = []
        self.controlDependencies = graph.pendingControlDependencies
        self.name = name ?? kind
        self.attributes = attributes
        super.init()
    }

    func attachOutputs(_ tensors: [MPSGraphTensor]) {
        outputTensors = tensors
    }
}

open class MPSGraphVariableOp: MPSGraphOperation {
    public var dataType: MPSDataType {
        (attributes["dataType"] as? MPSDataType) ?? .float32
    }

    public var shape: [NSNumber] {
        (attributes["shape"] as? [NSNumber]) ?? []
    }
}

open class MPSGraphTensor: MPSGraphObject {
    public private(set) var shape: [NSNumber]?
    public private(set) var dataType: MPSDataType
    public private(set) var operation: MPSGraphOperation

    init(shape: [NSNumber]?, dataType: MPSDataType, operation: MPSGraphOperation) {
        self.shape = shape
        self.dataType = dataType
        self.operation = operation
        super.init()
    }
}

open class MPSGraphTensorData: MPSGraphObject {
    public private(set) var device: MPSGraphDevice
    public private(set) var shape: [NSNumber]
    public private(set) var dataType: MPSDataType
    public private(set) var storage: Data

    public init(device: MPSGraphDevice, data: Data, shape: [NSNumber], dataType: MPSDataType) {
        self.device = device
        self.storage = data
        self.shape = shape
        self.dataType = dataType
        super.init()
    }

    public var elementCount: Int {
        MPSGraphShapeMath.elementCount(shape)
    }

    func floatValues() -> [Double] {
        MPSGraphShapeMath.doubles(from: storage, dataType: dataType, count: elementCount)
    }
}

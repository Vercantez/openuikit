import Foundation

open class MPSGraph: MPSGraphObject {
    public var options: MPSGraphOptions = .default
    public private(set) var placeholderTensors: [MPSGraphTensor] = []
    var operations: [MPSGraphOperation] = []
    var pendingControlDependencies: [MPSGraphOperation] = []

    public required override init() {
        super.init()
    }

    open class func new() -> Self {
        Self.init()
    }

    func recordOperation(
        kind: String,
        inputs: [MPSGraphTensor],
        name: String?,
        attributes: [String: Any] = [:]
    ) -> MPSGraphOperation {
        let op: MPSGraphOperation
        if kind == "variable" {
            op = MPSGraphVariableOp(
                graph: self,
                kind: kind,
                inputs: inputs,
                name: name,
                attributes: attributes
            )
        } else {
            op = MPSGraphOperation(
                graph: self,
                kind: kind,
                inputs: inputs,
                name: name,
                attributes: attributes
            )
        }
        operations.append(op)
        return op
    }

    func recordTensor(
        kind: String,
        inputs: [MPSGraphTensor],
        shape: [NSNumber]?,
        dataType: MPSDataType,
        name: String?,
        attributes: [String: Any] = [:]
    ) -> MPSGraphTensor {
        let op = recordOperation(kind: kind, inputs: inputs, name: name, attributes: attributes)
        let tensor = MPSGraphTensor(shape: shape, dataType: dataType, operation: op)
        op.attachOutputs([tensor])
        return tensor
    }

    func recordTensors(
        kind: String,
        inputs: [MPSGraphTensor],
        count: Int,
        name: String?,
        attributes: [String: Any] = [:]
    ) -> [MPSGraphTensor] {
        let op = recordOperation(kind: kind, inputs: inputs, name: name, attributes: attributes)
        let shape = inputs.first?.shape
        let dataType = inputs.first?.dataType ?? .float32
        let tensors = (0..<max(count, 1)).map { index in
            MPSGraphTensor(
                shape: shape,
                dataType: dataType,
                operation: op
            )
        }
        _ = tensors.map { $0 }
        op.attachOutputs(tensors)
        return tensors
    }

    func recordGradients(
        kind: String,
        of primary: MPSGraphTensor?,
        with tensors: [MPSGraphTensor],
        name: String?
    ) -> [MPSGraphTensor: MPSGraphTensor] {
        var result: [MPSGraphTensor: MPSGraphTensor] = [:]
        for tensor in tensors {
            let gradient = recordTensor(
                kind: kind,
                inputs: [primary, tensor].compactMap { $0 },
                shape: tensor.shape,
                dataType: tensor.dataType,
                name: name
            )
            result[tensor] = gradient
        }
        return result
    }

    public func placeholder(shape: [NSNumber]?, dataType: MPSDataType, name: String?) -> MPSGraphTensor {
        let tensor = recordTensor(
            kind: "placeholder",
            inputs: [],
            shape: shape,
            dataType: dataType,
            name: name
        )
        placeholderTensors.append(tensor)
        return tensor
    }

    public func placeholder(shape: [NSNumber]?, name: String?) -> MPSGraphTensor {
        placeholder(shape: shape, dataType: .float32, name: name)
    }

    public func constant(_ data: Data, shape: [NSNumber], dataType: MPSDataType) -> MPSGraphTensor {
        recordTensor(
            kind: "constant",
            inputs: [],
            shape: shape,
            dataType: dataType,
            name: nil,
            attributes: ["data": data]
        )
    }

    public func constant(_ scalar: Double, dataType: MPSDataType) -> MPSGraphTensor {
        let payload = MPSGraphShapeMath.data(from: [scalar], dataType: dataType)
        return recordTensor(
            kind: "constant",
            inputs: [],
            shape: [],
            dataType: dataType,
            name: nil,
            attributes: ["data": payload, "scalar": scalar]
        )
    }

    public func constant(_ scalar: Double, shape: [NSNumber], dataType: MPSDataType) -> MPSGraphTensor {
        let count = MPSGraphShapeMath.elementCount(shape)
        let values = Array(repeating: scalar, count: max(count, 1))
        let payload = MPSGraphShapeMath.data(from: values, dataType: dataType)
        return recordTensor(
            kind: "constant",
            inputs: [],
            shape: shape,
            dataType: dataType,
            name: nil,
            attributes: ["data": payload, "scalar": scalar]
        )
    }

    public func complexConstant(realPart: Double, imaginaryPart: Double) -> MPSGraphTensor {
        complexConstant(realPart: realPart, imaginaryPart: imaginaryPart, dataType: .complexFloat32)
    }

    public func complexConstant(realPart: Double, imaginaryPart: Double, dataType: MPSDataType) -> MPSGraphTensor {
        complexConstant(realPart: realPart, imaginaryPart: imaginaryPart, shape: [], dataType: dataType)
    }

    public func complexConstant(
        realPart: Double,
        imaginaryPart: Double,
        shape: [NSNumber],
        dataType: MPSDataType
    ) -> MPSGraphTensor {
        recordTensor(
            kind: "complexConstant",
            inputs: [],
            shape: shape,
            dataType: dataType,
            name: nil,
            attributes: ["real": realPart, "imag": imaginaryPart]
        )
    }

    public func variable(with data: Data, shape: [NSNumber], dataType: MPSDataType, name: String?) -> MPSGraphTensor {
        recordTensor(
            kind: "variable",
            inputs: [],
            shape: shape,
            dataType: dataType,
            name: name,
            attributes: ["data": data, "shape": shape, "dataType": dataType]
        )
    }

    public func variableFromTensor(_ tensor: MPSGraphTensor, name: String?) -> MPSGraphTensor {
        recordTensor(
            kind: "variableFromTensor",
            inputs: [tensor],
            shape: tensor.shape,
            dataType: tensor.dataType,
            name: name,
            attributes: ["shape": tensor.shape ?? [], "dataType": tensor.dataType]
        )
    }

    public func assign(_ variable: MPSGraphTensor, tensor: MPSGraphTensor, name: String?) -> MPSGraphOperation {
        recordOperation(kind: "assign", inputs: [variable, tensor], name: name)
    }

    public func gradients(
        of primaryTensor: MPSGraphTensor,
        with tensors: [MPSGraphTensor],
        name: String?
    ) -> [MPSGraphTensor: MPSGraphTensor] {
        recordGradients(kind: "gradients", of: primaryTensor, with: tensors, name: name)
    }

    public func controlDependency(
        with operations: [MPSGraphOperation],
        dependentBlock: @escaping MPSGraphControlFlowDependencyBlock,
        name: String?
    ) -> [MPSGraphTensor] {
        let previous = pendingControlDependencies
        pendingControlDependencies = operations
        let produced = dependentBlock()
        pendingControlDependencies = previous
        _ = name
        return produced
    }

    public func `if`(
        _ predicateTensor: MPSGraphTensor,
        then thenBlock: @escaping MPSGraphIfThenElseBlock,
        else elseBlock: MPSGraphIfThenElseBlock?,
        name: String?
    ) -> [MPSGraphTensor] {
        let thenTensors = thenBlock()
        let elseTensors = elseBlock?() ?? []
        let count = max(thenTensors.count, elseTensors.count, 1)
        return recordTensors(
            kind: "if",
            inputs: [predicateTensor] + thenTensors + elseTensors,
            count: count,
            name: name
        )
    }

    public func `for`(
        lowerBound: MPSGraphTensor,
        upperBound: MPSGraphTensor,
        step: MPSGraphTensor,
        initialBodyArguments: [MPSGraphTensor],
        body: @escaping MPSGraphForLoopBodyBlock,
        name: String?
    ) -> [MPSGraphTensor] {
        let produced = body(lowerBound, initialBodyArguments)
        return recordTensors(
            kind: "for",
            inputs: [lowerBound, upperBound, step] + initialBodyArguments + produced,
            count: max(produced.count, initialBodyArguments.count, 1),
            name: name
        )
    }

    public func `for`(
        numberOfIterations: MPSGraphTensor,
        initialBodyArguments: [MPSGraphTensor],
        body: @escaping MPSGraphForLoopBodyBlock,
        name: String?
    ) -> [MPSGraphTensor] {
        let produced = body(numberOfIterations, initialBodyArguments)
        return recordTensors(
            kind: "for",
            inputs: [numberOfIterations] + initialBodyArguments + produced,
            count: max(produced.count, initialBodyArguments.count, 1),
            name: name
        )
    }

    public func `while`(
        initialInputs: [MPSGraphTensor],
        before: @escaping MPSGraphWhileBeforeBlock,
        after: @escaping MPSGraphWhileAfterBlock,
        name: String?
    ) -> [MPSGraphTensor] {
        let condArray = NSMutableArray()
        let condition = before(initialInputs, condArray)
        let afterTensors = after(initialInputs)
        return recordTensors(
            kind: "while",
            inputs: [condition] + initialInputs + afterTensors,
            count: max(afterTensors.count, initialInputs.count, 1),
            name: name
        )
    }

    public func compile(
        with device: MPSGraphDevice?,
        feeds: [MPSGraphTensor: MPSGraphShapedType],
        targetTensors: [MPSGraphTensor],
        targetOperations: [MPSGraphOperation]?,
        compilationDescriptor: MPSGraphCompilationDescriptor?
    ) -> MPSGraphExecutable {
        _ = device
        _ = targetOperations
        if let descriptor = compilationDescriptor, descriptor.waitForCompilationCompletion {
            descriptor.compilationCompletionHandler(
                MPSGraphExecutable(graph: self, feeds: feeds, targets: targetTensors),
                nil
            )
        }
        return MPSGraphExecutable(graph: self, feeds: feeds, targets: targetTensors)
    }

    public func run(
        feeds: [MPSGraphTensor: MPSGraphTensorData],
        targetTensors: [MPSGraphTensor],
        targetOperations: [MPSGraphOperation]?
    ) -> [MPSGraphTensor: MPSGraphTensorData] {
        _ = targetOperations
        return MPSGraphCPU.execute(graph: self, feeds: feeds, targets: targetTensors)
    }

    public func runAsync(
        feeds: [MPSGraphTensor: MPSGraphTensorData],
        targetTensors: [MPSGraphTensor],
        targetOperations: [MPSGraphOperation]?,
        executionDescriptor: MPSGraphExecutionDescriptor?
    ) -> [MPSGraphTensor: MPSGraphTensorData] {
        let results = run(feeds: feeds, targetTensors: targetTensors, targetOperations: targetOperations)
        executionDescriptor?.scheduledHandler(results, nil)
        executionDescriptor?.completionHandler(results, nil)
        return results
    }
}

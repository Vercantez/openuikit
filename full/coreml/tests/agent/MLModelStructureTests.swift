import CoreML
import Foundation

func testModelStructureConstruction() {
    let layer = MLModelStructure.NeuralNetwork.Layer(
        name: "relu",
        type: "activation",
        inputNames: ["in"],
        outputNames: ["out"]
    )
    precondition(layer.name == "relu")
    precondition(layer.type == "activation")
    precondition(layer.inputNames == ["in"])
    precondition(layer.outputNames == ["out"])
    let network = MLModelStructure.NeuralNetwork(layers: [layer])
    precondition(network.layers.count == 1)
    let valueType = MLModelStructure.Program.ValueType()
    let named = MLModelStructure.Program.NamedValueType(name: "x", type: valueType)
    precondition(named.name == "x")
    _ = named.type
    let bindingName = MLModelStructure.Program.Binding.name("x")
    let bindingValue = MLModelStructure.Program.Binding.value(MLModelStructure.Program.Value())
    _ = (bindingName, bindingValue)
    let argument = MLModelStructure.Program.Argument(bindings: [bindingName])
    precondition(argument.bindings.count == 1)
    let block = MLModelStructure.Program.Block(inputs: [named], outputs: ["y"], operations: [])
    precondition(block.outputNames == ["y"])
    precondition(block.inputs.count == 1)
    precondition(block.operations.isEmpty)
    let function = MLModelStructure.Program.Function(inputs: [named], block: block)
    precondition(function.inputs.count == 1)
    _ = function.block
    let program = MLModelStructure.Program(functions: ["main": function])
    precondition(program.functions["main"] != nil)
    let pipeline = MLModelStructure.Pipeline(subModelNames: ["a"], subModels: [.unsupported])
    precondition(pipeline.subModelNames == ["a"])
    precondition(pipeline.subModels.count == 1)
    let neuralCase = MLModelStructure.neuralNetwork(network)
    let programCase = MLModelStructure.program(program)
    let pipelineCase = MLModelStructure.pipeline(pipeline)
    let unsupported = MLModelStructure.unsupported
    _ = (neuralCase, programCase, pipelineCase, unsupported)
    let operation = MLModelStructure.Program.Operation(
        operatorName: "identity",
        inputs: ["x": argument],
        outputs: [named],
        blocks: [block]
    )
    precondition(operation.operatorName == "identity")
    precondition(operation.inputs.count == 1)
    precondition(operation.outputs.count == 1)
    precondition(operation.blocks.count == 1)
}

func testComputePlanDeviceUsageAndCost() {
    let layer = MLModelStructure.NeuralNetwork.Layer(
        name: "relu",
        type: "activation",
        inputNames: ["in"],
        outputNames: ["out"]
    )
    let usage = MLComputePlan.DeviceUsage(
        preferred: .cpu(MLCPUComputeDevice()),
        supported: MLComputeDevice.allComputeDevices
    )
    precondition(usage.supported.count == 1)
    _ = usage.preferred
    let cost = MLComputePlan.Cost(weight: 1.25)
    precondition(cost.weight == 1.25)
    let plan = MLComputePlan(modelStructure: .unsupported)
    precondition(plan.deviceUsage(for: layer) == nil)
    let named = MLModelStructure.Program.NamedValueType(name: "x", type: MLModelStructure.Program.ValueType())
    let argument = MLModelStructure.Program.Argument(bindings: [.name("x")])
    let block = MLModelStructure.Program.Block(inputs: [named], outputs: ["y"], operations: [])
    let operation = MLModelStructure.Program.Operation(
        operatorName: "identity",
        inputs: ["x": argument],
        outputs: [named],
        blocks: [block]
    )
    precondition(plan.deviceUsage(for: operation) == nil)
    precondition(plan.estimatedCost(of: operation) == nil)
    if case .unsupported = plan.modelStructure { } else {
        fatalError("expected unsupported structure")
    }
}

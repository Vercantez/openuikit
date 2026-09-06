import Foundation
import MetalPerformanceShadersGraph

func testGraphObjectBase() {
    let object = MPSGraphObject()
    precondition((object as NSObject) === object)
}

func testGraphInitAndNew() {
    let graph = MPSGraph()
    precondition(graph.options == .default)
    graph.options = .verbose
    precondition(graph.options == .verbose)
    let created = MPSGraph.new()
    precondition(created.options == .synchronizeResults)
}

func testShapedTypeEquality() {
    let a = MPSGraphShapedType(shape: mpsgShape(2, 3), dataType: .float32)
    let b = MPSGraphShapedType(shape: mpsgShape(2, 3), dataType: .float32)
    let c = MPSGraphShapedType(shape: mpsgShape(2, 3), dataType: .float16)
    precondition(a.isEqual(to: b))
    precondition(a.isEqual(b))
    precondition(!a.isEqual(to: c))
    precondition(!a.isEqual(to: nil))
    a.shape = mpsgShape(4)
    a.dataType = .int32
    precondition(a.dataType == .int32)
    let typed: MPSGraphType = a
    precondition((typed as? MPSGraphShapedType) === a)
}

func testDeviceType() {
    let device = MPSGraphDevice.hostDevice()
    precondition(device.type == .metal)
}

func testTensorDataHostBuffer() {
    let data = mpsgFloatData([1, 2, 3, 4], shape: [2, 2])
    precondition(data.shape.map(\.intValue) == [2, 2])
    precondition(data.dataType == .float32)
    precondition(data.device.type == .metal)
    precondition(data.elementCount == 4)
    mpsgClose(mpsgFloats(data), [1, 2, 3, 4])
}

func testTensorProperties() {
    let graph = MPSGraph()
    let tensor = graph.placeholder(shape: mpsgShape(2, 2), dataType: .float16, name: "t")
    precondition(tensor.dataType == .float16)
    precondition(tensor.shape?.map(\.intValue) == [2, 2])
    precondition(tensor.operation.name == "t" || tensor.operation.outputTensors.contains { $0 === tensor })
}

func testOperationProperties() {
    let graph = MPSGraph()
    let x = graph.placeholder(shape: mpsgShape(2), dataType: .float32, name: "x")
    let y = graph.identity(with: x, name: "id")
    let op = y.operation
    precondition(op.graph === graph)
    precondition(op.inputTensors.contains { $0 === x })
    precondition(op.outputTensors.contains { $0 === y })
    precondition(op.name == "id")
    precondition(op.controlDependencies.isEmpty)
}

func testPlaceholderAndConstants() {
    let graph = MPSGraph()
    let typed = graph.placeholder(shape: mpsgShape(2), dataType: .float32, name: "p")
    let inferred = graph.placeholder(shape: mpsgShape(2), name: "q")
    precondition(graph.placeholderTensors.contains { $0 === typed })
    precondition(inferred.dataType == .float32)
    let scalar = graph.constant(3.0, dataType: .float32)
    let filled = graph.constant(2.0, shape: mpsgShape(2), dataType: .float32)
    let payload: [Float] = [4, 5]
    let raw = graph.constant(payload.withUnsafeBytes { Data($0) }, shape: mpsgShape(2), dataType: .float32)
    let complex = graph.complexConstant(realPart: 1, imaginaryPart: 2)
    _ = graph.complexConstant(realPart: 1, imaginaryPart: 2, dataType: .complexFloat32)
    _ = graph.complexConstant(realPart: 1, imaginaryPart: 2, shape: mpsgShape(1), dataType: .complexFloat32)
    let scalarRun = mpsgRun(graph, feeds: [:], scalar)
    mpsgClose(scalarRun, [3])
    let filledRun = mpsgRun(graph, feeds: [:], filled)
    mpsgClose(filledRun, [2, 2])
    let rawRun = mpsgRun(graph, feeds: [:], raw)
    mpsgClose(rawRun, [4, 5])
    _ = complex
}

func testVariableOp() {
    let graph = MPSGraph()
    let payload: [Float] = [1, 2]
    let variable = graph.variable(
        with: payload.withUnsafeBytes { Data($0) },
        shape: mpsgShape(2),
        dataType: .float32,
        name: "w"
    )
    let op = variable.operation as? MPSGraphVariableOp
    precondition(op?.dataType == .float32)
    precondition(op?.shape.map(\.intValue) == [2])
    let fromTensor = graph.variableFromTensor(variable, name: "w2")
    let assigned = graph.assign(variable, tensor: fromTensor, name: "assign")
    let read = graph.read(variable, name: "read")
    let values = mpsgRun(graph, feeds: [:], read)
    mpsgClose(values, [1, 2])
    precondition(assigned.inputTensors.count == 2)
}

func testRunAndRunAsync() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 2, name: "x")
    let doubled = graph.addition(x, x, name: nil)
    let feed = mpsgFloatData([1, 2], shape: [2])
    let sync = graph.run(feeds: [x: feed], targetTensors: [doubled], targetOperations: [])
    mpsgClose(mpsgFloats(sync[doubled]!), [2, 4])
    var scheduled = false
    var completed = false
    let descriptor = MPSGraphExecutionDescriptor()
    descriptor.scheduledHandler = { results, error in
        scheduled = true
        precondition(error == nil)
        mpsgClose(mpsgFloats(results[doubled]!), [2, 4])
    }
    descriptor.completionHandler = { _, _ in completed = true }
    let asyncResult = graph.runAsync(
        feeds: [x: feed],
        targetTensors: [doubled],
        targetOperations: nil,
        executionDescriptor: descriptor
    )
    mpsgClose(mpsgFloats(asyncResult[doubled]!), [2, 4])
    precondition(scheduled && completed)
}

func testGradientsAndControlFlow() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 1, name: "x")
    let y = graph.square(with: x, name: nil)
    let grads = graph.gradients(of: y, with: [x], name: "dy")
    precondition(grads[x] != nil)
    let dep = graph.controlDependency(with: [y.operation], dependentBlock: {
        [graph.identity(with: y, name: "dep")]
    }, name: "cd")
    precondition(dep.count == 1)
    let pred = graph.constant(1.0, dataType: .float32)
    let branched = graph.if(pred, then: {
        [graph.constant(4.0, dataType: .float32)]
    }, else: {
        [graph.constant(5.0, dataType: .float32)]
    }, name: "branch")
    precondition(branched.count == 1)
    let lower = graph.constant(0, dataType: .int32)
    let upper = graph.constant(3, dataType: .int32)
    let step = graph.constant(1, dataType: .int32)
    let looped = graph.for(
        lowerBound: lower,
        upperBound: upper,
        step: step,
        initialBodyArguments: [x],
        body: { _, args in args },
        name: "for"
    )
    precondition(looped.count == 1)
    let counted = graph.for(numberOfIterations: upper, initialBodyArguments: [x], body: { _, args in args }, name: "forN")
    precondition(counted.count == 1)
    let loopedWhile = graph.while(
        initialInputs: [x],
        before: { inputs, cond in
            cond.add(false)
            return inputs[0]
        },
        after: { $0 },
        name: "while"
    )
    precondition(loopedWhile.count == 1)
}

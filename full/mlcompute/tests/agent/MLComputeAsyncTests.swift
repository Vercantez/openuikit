import Foundation
import MLCompute

func testAsyncInferenceExecuteFailClosed() async {
    let graph = MLCGraph()
    let input = MLCTensor(shape: [1, 1, 2, 2])
    _ = graph.node(with: MLCActivationLayer.relu, source: input)
    let inference = MLCInferenceGraph(graphObjects: [graph])
    let data = ["x": MLCTensorData(linuxCopying: Data(count: 16))]
    do {
        let _: (result: MLCTensor?, executionTime: TimeInterval) = try await inference.execute(
            inputsData: data,
            lossLabelsData: nil,
            lossLabelWeightsData: nil,
            outputsData: nil,
            batchSize: 1,
            options: []
        )
        preconditionFailure("async inference execute should throw fail-closed")
    } catch let error as MLComputeError {
        precondition(error.nsError.code == MLComputeErrorCode.executeFailed.rawValue)
    } catch {
        precondition((error as NSError).domain == MLComputeErrorDomain)
    }
}

func testAsyncTrainingExecuteForwardFailClosed() async {
    let graph = MLCGraph()
    let input = MLCTensor(shape: [1, 4])
    _ = graph.node(with: MLCActivationLayer.relu, source: input)
    let descriptor = MLCOptimizerDescriptor(
        learningRate: 0.01,
        gradientRescale: 1,
        regularizationType: .none,
        regularizationScale: 0
    )
    let training = MLCTrainingGraph(
        graphObjects: [graph],
        lossLayer: nil,
        optimizer: MLCAdamOptimizer(descriptor: descriptor)
    )
    do {
        let _: (result: MLCTensor?, executionTime: TimeInterval) = try await training.executeForward(
            batchSize: 1,
            options: [],
            outputsData: nil
        )
        preconditionFailure("async executeForward should throw fail-closed")
    } catch let error as MLComputeError {
        precondition(error.nsError.code == MLComputeErrorCode.executeFailed.rawValue)
    } catch {
        precondition((error as NSError).domain == MLComputeErrorDomain)
    }
}

func testAsyncTrainingExecuteGradientFailClosed() async {
    let graph = MLCGraph()
    let input = MLCTensor(shape: [1, 4])
    _ = graph.node(with: MLCActivationLayer.relu, source: input)
    let descriptor = MLCOptimizerDescriptor(
        learningRate: 0.01,
        gradientRescale: 1,
        regularizationType: .none,
        regularizationScale: 0
    )
    let training = MLCTrainingGraph(
        graphObjects: [graph],
        lossLayer: nil,
        optimizer: MLCAdamOptimizer(descriptor: descriptor)
    )
    do {
        let _: TimeInterval = try await training.executeGradient(
            batchSize: 1,
            options: [],
            outputsData: nil
        )
        preconditionFailure("async executeGradient should throw fail-closed")
    } catch let error as MLComputeError {
        precondition(error.nsError.code == MLComputeErrorCode.executeFailed.rawValue)
    } catch {
        precondition((error as NSError).domain == MLComputeErrorDomain)
    }
}

func testAsyncTrainingExecuteOptimizerUpdateFailClosed() async {
    let graph = MLCGraph()
    let input = MLCTensor(shape: [1, 4])
    _ = graph.node(with: MLCActivationLayer.relu, source: input)
    let descriptor = MLCOptimizerDescriptor(
        learningRate: 0.01,
        gradientRescale: 1,
        regularizationType: .none,
        regularizationScale: 0
    )
    let training = MLCTrainingGraph(
        graphObjects: [graph],
        lossLayer: nil,
        optimizer: MLCAdamOptimizer(descriptor: descriptor)
    )
    do {
        let _: TimeInterval = try await training.executeOptimizerUpdate(options: [])
        preconditionFailure("async executeOptimizerUpdate should throw fail-closed")
    } catch let error as MLComputeError {
        precondition(error.nsError.code == MLComputeErrorCode.executeFailed.rawValue)
    } catch {
        precondition((error as NSError).domain == MLComputeErrorDomain)
    }
}

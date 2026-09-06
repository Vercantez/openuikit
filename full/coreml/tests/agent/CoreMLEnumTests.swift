import CoreML
import Foundation

func coremlRequireError(_ error: Error, _ code: MLModelError.Code) {
    guard let modelError = error as? MLModelError else {
        fatalError("expected MLModelError, got \(error)")
    }
    precondition(modelError.code == code, "unexpected MLModelError.Code \(modelError.code)")
    precondition(modelError.errorCode == code.rawValue)
    precondition(MLModelError.errorDomain == MLModelErrorDomain)
    precondition(MLModelErrorDomain == "com.apple.CoreML")
}

func coremlRequireThrows(_ code: MLModelError.Code, _ body: () throws -> Void) {
    do {
        try body()
        fatalError("expected throw \(code)")
    } catch {
        coremlRequireError(error, code)
    }
}

func coremlWaitFor(_ semaphore: DispatchSemaphore) {
    precondition(semaphore.wait(timeout: .now() + 5) == .success, "completion was not delivered")
}

func coremlWaitAsync(_ body: @escaping @Sendable () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await body()
        semaphore.signal()
    }
    coremlWaitFor(semaphore)
}

func testEnumAndConstantRawValues() {
    precondition(MLComputeUnits.cpuOnly.rawValue == 0)
    precondition(MLComputeUnits.cpuAndGPU.rawValue == 1)
    precondition(MLComputeUnits.all.rawValue == 2)
    precondition(MLComputeUnits.cpuAndNeuralEngine.rawValue == 3)
    precondition(MLComputeUnits(rawValue: 2) == .all)
    precondition(MLComputeUnits.cpuOnly != .all)
    precondition(MLComputeUnits.all.hashValue == MLComputeUnits.all.hashValue)
    var computeHasher = Hasher()
    MLComputeUnits.all.hash(into: &computeHasher)

    precondition(MLFeatureType.invalid.rawValue == 0)
    precondition(MLFeatureType.int64.rawValue == 1)
    precondition(MLFeatureType.double.rawValue == 2)
    precondition(MLFeatureType.string.rawValue == 3)
    precondition(MLFeatureType.image.rawValue == 4)
    precondition(MLFeatureType.multiArray.rawValue == 5)
    precondition(MLFeatureType.dictionary.rawValue == 6)
    precondition(MLFeatureType.sequence.rawValue == 7)
    precondition(MLFeatureType.state.rawValue == 8)
    precondition(MLFeatureType(rawValue: 5) == .multiArray)
    precondition(MLFeatureType.int64 != .double)
    var featureHasher = Hasher()
    MLFeatureType.string.hash(into: &featureHasher)
    _ = MLFeatureType.string.hashValue

    precondition(MLImageSizeConstraintType.unspecified.rawValue == 0)
    precondition(MLImageSizeConstraintType.enumerated.rawValue == 2)
    precondition(MLImageSizeConstraintType.range.rawValue == 3)
    precondition(MLImageSizeConstraintType(rawValue: 2) == .enumerated)
    precondition(MLImageSizeConstraintType.range != .unspecified)
    var imageHasher = Hasher()
    MLImageSizeConstraintType.range.hash(into: &imageHasher)
    _ = MLImageSizeConstraintType.range.hashValue

    precondition(MLMultiArrayDataType.double.rawValue == 0x10040)
    precondition(MLMultiArrayDataType.float64 == .double)
    precondition(MLMultiArrayDataType.float32.rawValue == 0x10020)
    precondition(MLMultiArrayDataType.float == .float32)
    precondition(MLMultiArrayDataType.float16.rawValue == 0x10010)
    precondition(MLMultiArrayDataType.int32.rawValue == 0x20020)
    precondition(MLMultiArrayDataType.int8.rawValue == 0x20008)
    precondition(MLMultiArrayDataType(rawValue: 0x10020) == .float32)
    precondition(MLMultiArrayDataType.int8 != .int32)
    var dtypeHasher = Hasher()
    MLMultiArrayDataType.float16.hash(into: &dtypeHasher)
    _ = MLMultiArrayDataType.int32.hashValue

    precondition(MLMultiArrayShapeConstraintType.unspecified.rawValue == 1)
    precondition(MLMultiArrayShapeConstraintType.enumerated.rawValue == 2)
    precondition(MLMultiArrayShapeConstraintType.range.rawValue == 3)
    precondition(MLMultiArrayShapeConstraintType(rawValue: 1) == .unspecified)
    precondition(MLMultiArrayShapeConstraintType.range != .enumerated)
    var shapeHasher = Hasher()
    MLMultiArrayShapeConstraintType.enumerated.hash(into: &shapeHasher)
    _ = MLMultiArrayShapeConstraintType.enumerated.hashValue

    precondition(MLTaskState.suspended.rawValue == 1)
    precondition(MLTaskState.running.rawValue == 2)
    precondition(MLTaskState.cancelling.rawValue == 3)
    precondition(MLTaskState.completed.rawValue == 4)
    precondition(MLTaskState.failed.rawValue == 5)
    precondition(MLTaskState(rawValue: 5) == .failed)
    precondition(MLTaskState.running != .failed)
    var taskHasher = Hasher()
    MLTaskState.completed.hash(into: &taskHasher)
    _ = MLTaskState.failed.hashValue

    precondition(MLModelError.Code.generic.rawValue == 0)
    precondition(MLModelError.Code.featureType.rawValue == 1)
    precondition(MLModelError.Code.io.rawValue == 3)
    precondition(MLModelError.Code.customLayer.rawValue == 4)
    precondition(MLModelError.Code.customModel.rawValue == 5)
    precondition(MLModelError.Code.update.rawValue == 6)
    precondition(MLModelError.Code.parameters.rawValue == 7)
    precondition(MLModelError.Code.modelDecryptionKeyFetch.rawValue == 8)
    precondition(MLModelError.Code.modelDecryption.rawValue == 9)
    precondition(MLModelError.Code.modelCollection.rawValue == 10)
    precondition(MLModelError.Code.predictionCancelled.rawValue == 11)
    precondition(MLModelError.Code(rawValue: 3) == .io)
    var codeHasher = Hasher()
    MLModelError.Code.io.hash(into: &codeHasher)
    _ = MLModelError.Code.io.hashValue

    precondition(MLOptimizationHints.ReshapeFrequency.frequent.rawValue == 0)
    precondition(MLOptimizationHints.ReshapeFrequency.infrequent.rawValue == 1)
    precondition(MLOptimizationHints.ReshapeFrequency(rawValue: 1) == .infrequent)
    precondition(MLOptimizationHints.ReshapeFrequency.frequent != .infrequent)
    var reshapeHasher = Hasher()
    MLOptimizationHints.ReshapeFrequency.frequent.hash(into: &reshapeHasher)
    _ = MLOptimizationHints.ReshapeFrequency.frequent.hashValue
    let reshapeRaw: MLOptimizationHints.ReshapeFrequency.RawValue = 0
    _ = reshapeRaw

    precondition(MLOptimizationHints.SpecializationStrategy.default.rawValue == 0)
    precondition(MLOptimizationHints.SpecializationStrategy.fastPrediction.rawValue == 1)
    precondition(MLOptimizationHints.SpecializationStrategy(rawValue: 0) == .default)
    precondition(MLOptimizationHints.SpecializationStrategy.default != .fastPrediction)
    var strategyHasher = Hasher()
    MLOptimizationHints.SpecializationStrategy.fastPrediction.hash(into: &strategyHasher)
    _ = MLOptimizationHints.SpecializationStrategy.fastPrediction.hashValue
    let strategyRaw: MLOptimizationHints.SpecializationStrategy.RawValue = 1
    _ = strategyRaw

    precondition(MLUpdateProgressEvent.trainingBegin.rawValue == 1)
    precondition(MLUpdateProgressEvent.miniBatchEnd.rawValue == 2)
    precondition(MLUpdateProgressEvent.epochEnd.rawValue == 4)
    let combined = MLUpdateProgressEvent([.epochEnd, .miniBatchEnd])
    precondition(combined.contains(.epochEnd))
    precondition(combined.union(.trainingBegin).contains(.trainingBegin))
    precondition(MLUpdateProgressEvent().isEmpty)
    var inserted = MLUpdateProgressEvent()
    _ = inserted.insert(.trainingBegin)
    precondition(inserted.contains(.trainingBegin))
    precondition(MLUpdateProgressEvent(rawValue: 1) == .trainingBegin)

    let cpu = MLComputeDevice.cpu(MLCPUComputeDevice())
    let gpu = MLComputeDevice.gpu(MLGPUComputeDevice())
    let neural = MLComputeDevice.neuralEngine(MLNeuralEngineComputeDevice())
    precondition(cpu != gpu)
    precondition(gpu != neural)
    _ = cpu.description
    _ = cpu.hashValue
    var deviceHasher = Hasher()
    cpu.hash(into: &deviceHasher)

    let layout: MLShapedArrayBufferLayout = .lastMajorContiguous
    _ = MLShapedArrayBufferLayout.firstMajorContiguous
    _ = MLShapedArrayBufferLayout.strides([1])
    _ = layout

    let unsupported = MLModelStructure.unsupported
    if case .unsupported = unsupported { } else {
        fatalError("expected unsupported")
    }
}

func testModelErrorValueSemantics() {
    precondition(MLModelErrorDomain == "com.apple.CoreML")
    precondition(MLModelError.errorDomain == "com.apple.CoreML")
    precondition(MLModelError.generic.rawValue == 0)
    precondition(MLModelError.featureType.rawValue == 1)
    precondition(MLModelError.io.rawValue == 3)
    precondition(MLModelError.customLayer.rawValue == 4)
    precondition(MLModelError.customModel.rawValue == 5)
    precondition(MLModelError.update.rawValue == 6)
    precondition(MLModelError.parameters.rawValue == 7)
    precondition(MLModelError.modelDecryptionKeyFetch.rawValue == 8)
    precondition(MLModelError.modelDecryption.rawValue == 9)
    precondition(MLModelError.modelCollection.rawValue == 10)
    precondition(MLModelError.predictionCancelled.rawValue == 11)
    let error = MLModelError(.io, userInfo: ["reason": "missing"])
    precondition(error.code == .io)
    precondition(error.userInfo["reason"] as? String == "missing")
    precondition(error.errorUserInfo["reason"] as? String == "missing")
    precondition(error.errorCode == MLModelError.Code.io.rawValue)
    precondition(error == MLModelError(.io, userInfo: ["reason": "missing"]))
    precondition(error != MLModelError(.generic))
    precondition(MLModelError.Code.io ~= error)
    _ = error.hashValue
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = error.localizedDescription
}

func testUpdateProgressEventSetAlgebra() {
    let begin = MLUpdateProgressEvent.trainingBegin
    let epoch = MLUpdateProgressEvent.epochEnd
    let combined: MLUpdateProgressEvent = [.trainingBegin, .miniBatchEnd]
    precondition(combined.contains(.trainingBegin))
    precondition(begin.isSubset(of: combined))
    precondition(combined.isSuperset(of: begin))
    precondition(begin.isDisjoint(with: epoch))
    precondition(begin.isStrictSubset(of: combined))
    precondition(combined.isStrictSuperset(of: begin))
    precondition(combined.subtracting(begin).contains(.miniBatchEnd))
    precondition(begin != epoch)
    precondition(combined.intersection(begin) == begin)
    precondition(begin.union(epoch).contains(.epochEnd))
    precondition(combined.symmetricDifference(begin).contains(.miniBatchEnd))
    var mutable = combined
    mutable.subtract(begin)
    precondition(!mutable.contains(.trainingBegin))
    mutable.formUnion(.trainingBegin)
    mutable.formIntersection(combined)
    mutable.formSymmetricDifference(epoch)
    _ = mutable.remove(.miniBatchEnd)
    _ = mutable.update(with: .trainingBegin)
    precondition(MLUpdateProgressEvent().isEmpty)
}

import CoreML
import Foundation

private func requireError(_ error: Error, _ code: MLModelError.Code) {
    guard let modelError = error as? MLModelError else {
        fatalError("expected MLModelError, got \(error)")
    }
    precondition(modelError.code == code, "unexpected MLModelError.Code \(modelError.code)")
    precondition(modelError.errorCode == code.rawValue)
    precondition(MLModelError.errorDomain == MLModelErrorDomain)
}

private func requireThrows(_ code: MLModelError.Code, _ body: () throws -> Void) {
    do {
        try body()
        fatalError("expected throw \(code)")
    } catch {
        requireError(error, code)
    }
}

enum CoreMLRuntime {
    static func main() async {
        testErrors()
        testEnums()
        testMultiArray()
        testFeatureValues()
        testProviders()
        testConfiguration()
        testFailClosedModel()
        await testFailClosedAsync()
        testShapedArray()
        testComputeDevices()
        testKeys()
        testSequence()
        testSendable()
        testUpdateFailsClosed()
        print("COREML_AGENT_RUNTIME_OK")
    }

    static func testErrors() {
        precondition(MLModelErrorDomain == "com.apple.CoreML.ErrorDomain")
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
        precondition(error == MLModelError(.io, userInfo: ["reason": "missing"]))
        precondition(error != MLModelError(.generic))
        precondition(MLModelError.Code.io ~= error)
    }

    static func testEnums() {
        precondition(MLComputeUnits.cpuOnly.rawValue == 0)
        precondition(MLComputeUnits.cpuAndGPU.rawValue == 1)
        precondition(MLComputeUnits.all.rawValue == 2)
        precondition(MLComputeUnits.cpuAndNeuralEngine.rawValue == 3)
        precondition(MLFeatureType.invalid.rawValue == 0)
        precondition(MLFeatureType.int64.rawValue == 1)
        precondition(MLFeatureType.double.rawValue == 2)
        precondition(MLFeatureType.string.rawValue == 3)
        precondition(MLFeatureType.image.rawValue == 4)
        precondition(MLFeatureType.multiArray.rawValue == 5)
        precondition(MLFeatureType.dictionary.rawValue == 6)
        precondition(MLFeatureType.sequence.rawValue == 7)
        precondition(MLFeatureType.state.rawValue == 8)
        precondition(MLMultiArrayDataType.double.rawValue == 0x10040)
        precondition(MLMultiArrayDataType.float64 == .double)
        precondition(MLMultiArrayDataType.float32.rawValue == 0x10020)
        precondition(MLMultiArrayDataType.float == .float32)
        precondition(MLMultiArrayDataType.float16.rawValue == 0x10010)
        precondition(MLMultiArrayDataType.int32.rawValue == 0x20020)
        precondition(MLMultiArrayDataType.int8.rawValue == 0x20008)
        precondition(MLTaskState.suspended.rawValue == 1)
        precondition(MLTaskState.running.rawValue == 2)
        precondition(MLUpdateProgressEvent.trainingBegin.rawValue == 1)
        precondition(MLUpdateProgressEvent([.epochEnd, .miniBatchEnd]).contains(.epochEnd))
        precondition(MLImageSizeConstraintType.unspecified.rawValue == 0)
        precondition(MLMultiArrayShapeConstraintType.unspecified.rawValue == 1)
    }

    static func testMultiArray() {
        let array = try! MLMultiArray(shape: [2, 3], dataType: .float32)
        precondition(array.count == 6)
        precondition(array.shape.map(\.intValue) == [2, 3])
        precondition(array.strides.map(\.intValue) == [3, 1])
        precondition(array.dataType == .float32)
        array[0] = 1.5
        array[[NSNumber(value: 1), NSNumber(value: 2)]] = 9
        precondition(array[0].floatValue == 1.5)
        precondition(abs(array[[NSNumber(value: 1), NSNumber(value: 2)]].floatValue - 9) < 0.0001)
        let copy = try! MLMultiArray(shape: [2, 3], dataType: .float32)
        array.transfer(to: copy)
        precondition(copy[0].floatValue == 1.5)
        let fromDoubles = try! MLMultiArray([1.0, 2.0, 3.0])
        precondition(fromDoubles.count == 3)
        precondition(fromDoubles.dataType == .double)
        fromDoubles.withUnsafeBytes { buffer in
            precondition(buffer.count == 24)
        }
        let ints = try! MLMultiArray([Int32(4), Int32(5)])
        precondition(ints[1].int32Value == 5)
        let concat = MLMultiArray(
            byConcatenatingMultiArrays: [fromDoubles, fromDoubles],
            alongAxis: 0,
            dataType: .double
        )
        precondition(concat.count == 6)
        concat.withUnsafeBufferPointer(ofType: Double.self) { buffer in
            precondition(Array(buffer) == [1, 2, 3, 1, 2, 3])
        }
        let shaped = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
        let fromShaped = MLMultiArray(shaped)
        precondition(fromShaped.count == 4)
        precondition(fromShaped.dataType == .float32)
        let pointerBuffer = try! UnsafeBufferPointer<Float>(fromShaped)
        precondition(pointerBuffer.count == 4)
        precondition(fromShaped.withUnsafeMutableBytes { buffer, strides in
            strides == [2, 1] && buffer.count == 16
        })
        precondition(MLMultiArray(coder: NSCoder()) == nil)
    }

    static func testFeatureValues() {
        let intValue = MLFeatureValue(int64: 42)
        precondition(intValue.type == .int64)
        precondition(intValue.int64Value == 42)
        precondition(!intValue.isUndefined)
        let doubleValue = MLFeatureValue(double: 1.25)
        precondition(doubleValue.doubleValue == 1.25)
        let stringValue = MLFeatureValue(string: "age")
        precondition(stringValue.stringValue == "age")
        let array = try! MLMultiArray(shape: [1, 4], dataType: .float32)
        array[0] = 3
        let multi = MLFeatureValue(multiArray: array)
        precondition(multi.multiArrayValue?.count == 4)
        precondition(multi.isEqual(to: MLFeatureValue(multiArray: array)))
        let undefined = MLFeatureValue(undefined: .string)
        precondition(undefined.isUndefined)
        precondition(undefined.type == .string)
        let dict = try! MLFeatureValue(dictionary: ["cat": NSNumber(value: 0.9)])
        precondition(dict.dictionaryValue["cat"]?.doubleValue == 0.9)
        let sequence = MLFeatureValue(sequence: MLSequence(strings: ["a", "b"]))
        precondition(sequence.sequenceValue?.stringValues == ["a", "b"])
        let shaped = MLShapedArray<Float>(scalars: [0, 1], shape: [2])
        let fromShaped = MLFeatureValue(shapedArray: shaped)
        precondition(fromShaped.shapedArrayValue(of: Float.self)?.scalars == [0, 1])
        precondition(intValue.isEqual(to: MLFeatureValue(int64: 42)))
        precondition(!intValue.isEqual(to: doubleValue))
    }

    static func testProviders() {
        let input = try! MLDictionaryFeatureProvider(dictionary: [
            "age": MLFeatureValue(int64: 21),
            "score": 0.5,
            "label": "adult"
        ])
        precondition(input.featureNames == ["age", "score", "label"])
        precondition(input["age"]?.int64Value == 21)
        precondition(input.featureValue(for: "label")?.stringValue == "adult")
        let batch = MLArrayBatchProvider(array: [input, input])
        precondition(batch.count == 2)
        precondition(batch.features(at: 1).featureValue(for: "age")?.int64Value == 21)
        let alias = MLArrayBatchProvider(featureProviderArray: [input])
        precondition(alias.count == 1)
        let columns = try! MLArrayBatchProvider(dictionary: [
            "x": [1, 2],
            "y": ["a", "b"]
        ])
        precondition(columns.count == 2)
        precondition(columns.features(at: 1).featureValue(for: "x")?.int64Value == 2)
    }

    static func testConfiguration() {
        let configuration = MLModelConfiguration()
        precondition(configuration.computeUnits == .cpuOnly)
        configuration.computeUnits = .all
        configuration.allowLowPrecisionAccumulationOnGPU = true
        configuration.functionName = "main"
        configuration.modelDisplayName = "AgeNet"
        configuration.optimizationHints.reshapeFrequency = .infrequent
        configuration.optimizationHints.specializationStrategy = .fastPrediction
        let copy = configuration.copy() as! MLModelConfiguration
        precondition(copy.computeUnits == .all)
        precondition(copy.functionName == "main")
        let options = MLPredictionOptions()
        precondition(options.usesCPUOnly)
        options.usesCPUOnly = true
        options.outputBackings = ["out": 1]
        precondition(options.outputBackings["out"] as? Int == 1)
        let hints = MLOptimizationHints()
        precondition(hints.reshapeFrequency == .frequent)
        precondition(hints.specializationStrategy == .default)
    }

    static func testFailClosedModel() {
        let url = URL(fileURLWithPath: "/tmp/missing.mlmodelc")
        requireThrows(.io) {
            _ = try MLModel(contentsOf: url)
        }
        requireThrows(.io) {
            _ = try MLModel(contentsOfURL: url)
        }
        requireThrows(.io) {
            _ = try MLModel(contentsOf: url, configuration: MLModelConfiguration())
        }
        requireThrows(.io) {
            _ = try MLModel.compileModel(at: url)
        }
        requireThrows(.io) {
            _ = try MLModelAsset(url: url)
        }
        requireThrows(.io) {
            _ = try MLModelAsset(specification: Data([0, 1, 2]))
        }
        MLModel.load(contentsOf: url) { result in
            switch result {
            case .failure(let error):
                requireError(error, .io)
            case .success:
                fatalError("load must fail closed")
            }
        }
        MLModel.compileModel(at: url) { result in
            switch result {
            case .failure(let error):
                requireError(error, .io)
            case .success:
                fatalError("compile must fail closed")
            }
        }
    }

    static func testFailClosedAsync() async {
        let url = URL(fileURLWithPath: "/tmp/missing.mlmodelc")
        do {
            _ = try await MLModel.load(contentsOf: url)
            fatalError("async load must fail closed")
        } catch {
            requireError(error, .io)
        }
        do {
            _ = try await MLModel.compileModel(at: url)
            fatalError("async compile must fail closed")
        } catch {
            requireError(error, .io)
        }
        do {
            _ = try await MLModelStructure.load(contentsOf: url)
            fatalError("structure load must fail closed")
        } catch {
            requireError(error, .io)
        }
        do {
            _ = try await MLComputePlan.load(contentsOf: url, configuration: MLModelConfiguration())
            fatalError("compute plan load must fail closed")
        } catch {
            requireError(error, .io)
        }
        let tensor = MLTensor(repeating: 1.0, shape: [2, 2])
        precondition(tensor.shape == [2, 2])
        precondition(tensor.scalarCount == 4)
        precondition(tensor.rank == 2)
        let flat = tensor.flattened()
        precondition(flat.shape == [4])
    }

    static func testShapedArray() {
        var array = MLShapedArray<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [2, 3])
        precondition(array.scalarCount == 6)
        precondition(!array.isScalar)
        precondition(array[scalarAt: 1, 2] == 6)
        array[scalarAt: 0, 0] = 9
        precondition(array.scalars.first == 9)
        array.fill(with: 2)
        precondition(array.scalars.allSatisfy { $0 == 2 })
        let identity = MLShapedArray<Int32>(identityMatrixOfSize: 2)
        precondition(identity.scalars == [1, 0, 0, 1])
        let expanded = array.expandingShape(at: 0)
        precondition(expanded.shape == [1, 2, 3])
        let squeezed = expanded.squeezingShape()
        precondition(squeezed.shape == [2, 3])
        let transposed = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2]).transposed()
        precondition(transposed.scalars == [1, 3, 2, 4])
        let slice = array[0]
        precondition(slice.shape == [3])
        precondition(Float.multiArrayDataType == .float32)
        precondition(Double.multiArrayDataType == .double)
        precondition(Float16.multiArrayDataType == .float16)
        precondition(Int32.multiArrayDataType == .int32)
        precondition(Int8.multiArrayDataType == .int8)
        let encoded = try! JSONEncoder().encode(array)
        let decoded = try! JSONDecoder().decode(MLShapedArray<Float>.self, from: encoded)
        precondition(decoded == array)
        let policy = withMLTensorComputePolicy(.cpuOnly) { 7 }
        precondition(policy == 7)
        let range = (1..<4).relative(toShapedArrayAxis: 0..<10)
        precondition(range == 1..<4)
    }

    static func testComputeDevices() {
        let devices = MLModel.availableComputeDevices
        precondition(devices.count == 1)
        guard case .cpu = devices[0] else {
            fatalError("Linux CoreML must advertise only CPU")
        }
        precondition(MLComputeDevice.allComputeDevices.count == 1)
        let ane = MLNeuralEngineComputeDevice()
        precondition(ane.totalCoreCount == 0)
        let policy = MLComputePolicy(.cpuOnly)
        precondition(policy == .cpuOnly)
        precondition(policy.description.contains("cpuOnly"))
        _ = MLCPUComputeDevice()
        _ = MLGPUComputeDevice()
    }

    static func testKeys() {
        precondition(MLParameterKey.learningRate.name == "learningRate")
        let scoped = MLParameterKey.weights.scoped(to: "conv1")
        precondition(scoped.scope == "conv1")
        precondition(MLMetricKey.lossValue.name == "lossValue")
        precondition(MLModelMetadataKey.author.rawValue.contains("author"))
        precondition(MLFeatureValue.ImageOption.cropRect.rawValue.contains("CropRect"))
    }

    static func testSequence() {
        let empty = MLSequence(empty: .string)
        precondition(empty.stringValues.isEmpty)
        let strings = MLSequence(stringArray: ["one", "two"])
        precondition(strings.type == .string)
        precondition(strings.stringValues == ["one", "two"])
        let ints = MLSequence(int64Array: [NSNumber(value: 1), NSNumber(value: 2)])
        precondition(ints.int64Values.map(\.intValue) == [1, 2])
    }

    static func testSendable() {
        let sendable = MLSendableFeatureValue(21)
        precondition(sendable.integerValue == 21)
        precondition(sendable.type == .int64)
        let fromFeature = MLSendableFeatureValue(MLFeatureValue(string: "hi"))
        precondition(fromFeature?.stringValue == "hi")
        let roundTrip = MLFeatureValue(sendable)
        precondition(roundTrip.int64Value == 21)
        let undefined = MLSendableFeatureValue(undefined: .double)
        precondition(undefined.isUndefined)
    }

    static func testUpdateFailsClosed() {
        let provider = MLArrayBatchProvider(array: [])
        requireThrows(.update) {
            _ = try MLUpdateTask(
                forModelAt: URL(fileURLWithPath: "/tmp/model.mlmodelc"),
                trainingData: provider,
                completionHandler: { _ in }
            )
        }
        let handlers = MLUpdateProgressHandlers(
            forEvents: [.trainingBegin, .epochEnd],
            progressHandler: nil,
            completionHandler: { _ in }
        )
        requireThrows(.update) {
            _ = try MLUpdateTask(
                forModelAt: URL(fileURLWithPath: "/tmp/model.mlmodelc"),
                trainingData: provider,
                progressHandlers: handlers
            )
        }
        let task = MLTask()
        task.resume()
        precondition(task.state == .failed)
        task.cancel()
        precondition(task.state == .completed)
        let state = MLState()
        do {
            _ = try state.withMultiArray { _ in 1 }
            fatalError("empty MLState must fail closed")
        } catch {
            requireError(error, .generic)
        }
    }
}

await CoreMLRuntime.main()

import CoreML
import Dispatch
import Foundation

private func requireError(_ error: Error, _ code: MLModelError.Code) {
    guard let modelError = error as? MLModelError else {
        fatalError("expected MLModelError, got \(error)")
    }
    precondition(modelError.code == code, "unexpected MLModelError.Code \(modelError.code)")
    precondition(modelError.errorCode == code.rawValue)
    precondition(MLModelError.errorDomain == MLModelErrorDomain)
    precondition(MLModelErrorDomain == "com.apple.CoreML")
}

private func requireThrows(_ code: MLModelError.Code, _ body: () throws -> Void) {
    do {
        try body()
        fatalError("expected throw \(code)")
    } catch {
        requireError(error, code)
    }
}

private func waitFor(_ semaphore: DispatchSemaphore) {
    precondition(semaphore.wait(timeout: .now() + 5) == .success, "completion was not delivered")
}

enum CoreMLRuntime {
    static func main() async {
        testErrors()
        testEnums()
        testMultiArray()
        testMultiArrayConcatAndTransfer()
        testFeatureValues()
        testProviders()
        testConfiguration()
        testFailClosedModel()
        testCompletionDelivery()
        await testFailClosedAsync()
        testShapedArray()
        testComputeDevices()
        testKeys()
        testSequence()
        testSendable()
        testUpdateFailsClosed()
        testDescriptions()
        testShapedArrayCollection()
        testModelIOAndPrediction()
        testCustomLayerFailsClosed()
        testStructureSurface()
        print("COREML_AGENT_RUNTIME_OK")
    }

    static func testErrors() {
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

    static func testMultiArrayConcatAndTransfer() {
        let left = try! MLMultiArray(shape: [2, 2], dataType: .float32)
        left[[NSNumber(value: 0), NSNumber(value: 0)]] = 1
        left[[NSNumber(value: 0), NSNumber(value: 1)]] = 2
        left[[NSNumber(value: 1), NSNumber(value: 0)]] = 3
        left[[NSNumber(value: 1), NSNumber(value: 1)]] = 4
        let right = try! MLMultiArray(shape: [2, 1], dataType: .int32)
        right[[NSNumber(value: 0), NSNumber(value: 0)]] = 5
        right[[NSNumber(value: 1), NSNumber(value: 0)]] = 6

        let axisOne = MLMultiArray(
            byConcatenatingMultiArrays: [left, right],
            alongAxis: 1,
            dataType: .float32
        )
        precondition(axisOne.shape.map(\.intValue) == [2, 3])
        precondition(axisOne[[NSNumber(value: 0), NSNumber(value: 0)]].floatValue == 1)
        precondition(axisOne[[NSNumber(value: 0), NSNumber(value: 1)]].floatValue == 2)
        precondition(axisOne[[NSNumber(value: 0), NSNumber(value: 2)]].floatValue == 5)
        precondition(axisOne[[NSNumber(value: 1), NSNumber(value: 0)]].floatValue == 3)
        precondition(axisOne[[NSNumber(value: 1), NSNumber(value: 1)]].floatValue == 4)
        precondition(axisOne[[NSNumber(value: 1), NSNumber(value: 2)]].floatValue == 6)

        let wrapped = MLMultiArray(
            byConcatenatingMultiArrays: [left, right],
            alongAxis: -1,
            dataType: .double
        )
        precondition(wrapped.shape.map(\.intValue) == [2, 3])
        precondition(wrapped[[NSNumber(value: 0), NSNumber(value: 2)]].doubleValue == 5)
        precondition(wrapped[[NSNumber(value: 1), NSNumber(value: 2)]].doubleValue == 6)

        let mixed = MLMultiArray(
            byConcatenatingMultiArrays: [
                try! MLMultiArray([Float(1.5), Float(2.25)]),
                try! MLMultiArray([Int32(3), Int32(4)])
            ],
            alongAxis: 0,
            dataType: .double
        )
        precondition(mixed.dataType == .double)
        precondition(mixed[0].doubleValue == 1.5)
        precondition(mixed[1].doubleValue == 2.25)
        precondition(mixed[2].doubleValue == 3)
        precondition(mixed[3].doubleValue == 4)

        let padded = MLMultiArray(shape: [2, 2], dataType: .float32, strides: [8, 1])
        precondition(padded.strides.map(\.intValue) == [8, 1])
        padded[[NSNumber(value: 0), NSNumber(value: 0)]] = 10
        padded[[NSNumber(value: 0), NSNumber(value: 1)]] = 11
        padded[[NSNumber(value: 1), NSNumber(value: 0)]] = 12
        padded[[NSNumber(value: 1), NSNumber(value: 1)]] = 13
        let packed = try! MLMultiArray(shape: [2, 2], dataType: .int32)
        padded.transfer(to: packed)
        precondition(packed[0].int32Value == 10)
        precondition(packed[1].int32Value == 11)
        precondition(packed[2].int32Value == 12)
        precondition(packed[3].int32Value == 13)

        let zero = try! MLMultiArray(shape: [2, 0, 3], dataType: .int8)
        precondition(zero.count == 0)
        let zeroDest = try! MLMultiArray(shape: [2, 0, 3], dataType: .float16)
        zero.transfer(to: zeroDest)
        let zeroConcat = MLMultiArray(
            byConcatenatingMultiArrays: [zero, zero],
            alongAxis: 1,
            dataType: .int8
        )
        precondition(zeroConcat.shape.map(\.intValue) == [2, 0, 3])
        precondition(zeroConcat.count == 0)

        requireThrows(.io) {
            _ = try MLMultiArray(shape: [NSNumber(value: -1)], dataType: .float32)
        }
        let scratch = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
        scratch.initializeMemory(as: UInt8.self, repeating: 0, count: 16)
        requireThrows(.featureType) {
            _ = try MLMultiArray(
                dataPointer: scratch,
                shape: [NSNumber(value: 2), NSNumber(value: 2)],
                dataType: .float32,
                strides: [NSNumber(value: 1)],
                deallocator: { _ in }
            )
        }
        requireThrows(.io) {
            _ = try MLMultiArray(
                dataPointer: scratch,
                shape: [NSNumber(value: 2)],
                dataType: .int32,
                strides: [NSNumber(value: -1)],
                deallocator: { _ in }
            )
        }
        requireThrows(.io) {
            _ = try MLMultiArray(
                shape: [NSNumber(value: Int.max), NSNumber(value: 4)],
                dataType: .int8
            )
        }
        scratch.deallocate()

        var deallocatorCount = 0
        let owned = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 4)
        owned.initializeMemory(as: UInt8.self, repeating: 0, count: 16)
        do {
            let array = try MLMultiArray(
                dataPointer: owned,
                shape: [NSNumber(value: 4)],
                dataType: .int32,
                strides: [NSNumber(value: 1)],
                deallocator: { pointer in
                    deallocatorCount += 1
                    pointer.deallocate()
                }
            )
            precondition(deallocatorCount == 0)
            array[0] = 8
            precondition(array[0].int32Value == 8)
        } catch {
            fatalError("owned MLMultiArray must construct: \(error)")
        }
        precondition(deallocatorCount == 1)
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
        precondition(configuration.computeUnits == .all)
        precondition(configuration.computeUnits.rawValue == 2)
        precondition(configuration.allowLowPrecisionAccumulationOnGPU == false)
        configuration.computeUnits = .cpuOnly
        configuration.allowLowPrecisionAccumulationOnGPU = true
        configuration.functionName = "main"
        configuration.modelDisplayName = "AgeNet"
        configuration.parameters = [MLParameterKey.learningRate: 0.01]
        configuration.optimizationHints.reshapeFrequency = .infrequent
        configuration.optimizationHints.specializationStrategy = .fastPrediction
        precondition(configuration.preferredMetalDevice == nil)
        configuration.preferredMetalDevice = nil
        let copyingWitness: any Foundation.NSCopying = configuration
        _ = copyingWitness
        let copy = configuration.copy() as! MLModelConfiguration
        precondition(copy !== configuration)
        precondition(copy.computeUnits == .cpuOnly)
        precondition(copy.allowLowPrecisionAccumulationOnGPU == true)
        precondition(copy.functionName == "main")
        precondition(copy.modelDisplayName == "AgeNet")
        precondition((copy.parameters?[MLParameterKey.learningRate] as? Double) == 0.01)
        precondition(copy.optimizationHints.reshapeFrequency == .infrequent)
        precondition(copy.optimizationHints.specializationStrategy == .fastPrediction)
        let options = MLPredictionOptions()
        precondition(options.usesCPUOnly == false)
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
        let asset = try! MLModelAsset(url: url)
        let fromSpec = try! MLModelAsset(specification: Data([0, 1, 2]))
        _ = try! MLModelAsset(specification: Data([0]), blobMapping: [:])
        _ = (asset, fromSpec)
    }

    static func testCompletionDelivery() {
        let url = URL(fileURLWithPath: "/tmp/missing.mlmodelc")
        let asset = try! MLModelAsset(url: url)

        func assertReturnedBeforeCallback(_ start: (@escaping () -> Void) -> Void) {
            let lock = NSLock()
            var returned = false
            var calledInline = false
            let delivered = DispatchSemaphore(value: 0)
            start {
                lock.lock()
                if !returned {
                    calledInline = true
                }
                lock.unlock()
                delivered.signal()
            }
            lock.lock()
            returned = true
            let inline = calledInline
            lock.unlock()
            precondition(!inline, "completion must not run inline on the caller")
            waitFor(delivered)
        }

        assertReturnedBeforeCallback { finish in
            MLModel.load(contentsOf: url) { result in
                switch result {
                case .failure(let error):
                    requireError(error, .generic)
                case .success:
                    fatalError("load must fail closed")
                }
                finish()
            }
        }

        assertReturnedBeforeCallback { finish in
            MLModel.compileModel(at: url) { result in
                switch result {
                case .failure(let error):
                    requireError(error, .io)
                case .success:
                    fatalError("compile must fail closed")
                }
                finish()
            }
        }

        assertReturnedBeforeCallback { finish in
            MLModel.load(asset, configuration: MLModelConfiguration()) { model, error in
                precondition(model == nil)
                requireError(error!, .generic)
                finish()
            }
        }

        assertReturnedBeforeCallback { finish in
            asset.functionNames { names, error in
                precondition(names == nil)
                requireError(error!, .generic)
                finish()
            }
        }

        assertReturnedBeforeCallback { finish in
            asset.modelDescription { description, error in
                precondition(description == nil)
                requireError(error!, .generic)
                finish()
            }
        }

        assertReturnedBeforeCallback { finish in
            asset.modelDescription(of: "main") { description, error in
                precondition(description == nil)
                requireError(error!, .generic)
                finish()
            }
        }

        var loadCount = 0
        let loadOnce = DispatchSemaphore(value: 0)
        MLModel.load(contentsOf: url) { _ in
            loadCount += 1
            loadOnce.signal()
        }
        waitFor(loadOnce)
        Thread.sleep(forTimeInterval: 0.05)
        precondition(loadCount == 1, "load completion must run exactly once")

        var compileCount = 0
        let compileOnce = DispatchSemaphore(value: 0)
        MLModel.compileModel(at: url) { _ in
            compileCount += 1
            compileOnce.signal()
        }
        waitFor(compileOnce)
        Thread.sleep(forTimeInterval: 0.05)
        precondition(compileCount == 1, "compile completion must run exactly once")

        var assetCount = 0
        let assetOnce = DispatchSemaphore(value: 0)
        asset.functionNames { _, _ in
            assetCount += 1
            assetOnce.signal()
        }
        waitFor(assetOnce)
        Thread.sleep(forTimeInterval: 0.05)
        precondition(assetCount == 1, "asset completion must run exactly once")

        let group = DispatchGroup()
        let countLock = NSLock()
        var genericLoads = 0
        var ioCompiles = 0
        for _ in 0..<8 {
            group.enter()
            MLModel.load(contentsOf: url) { result in
                if case .failure(let error) = result, (error as? MLModelError)?.code == .generic {
                    countLock.lock()
                    genericLoads += 1
                    countLock.unlock()
                }
                group.leave()
            }
            group.enter()
            MLModel.compileModel(at: url) { result in
                if case .failure(let error) = result, (error as? MLModelError)?.code == .io {
                    countLock.lock()
                    ioCompiles += 1
                    countLock.unlock()
                }
                group.leave()
            }
        }
        precondition(group.wait(timeout: .now() + 5) == .success, "concurrent completions must finish")
        precondition(genericLoads == 8)
        precondition(ioCompiles == 8)
    }

    static func testFailClosedAsync() async {
        let url = URL(fileURLWithPath: "/tmp/missing.mlmodelc")
        do {
            _ = try await MLModel.load(contentsOf: url)
            fatalError("async load must fail closed")
        } catch {
            requireError(error, .generic)
        }
        do {
            _ = try await MLModel.compileModel(at: url)
            fatalError("async compile must fail closed")
        } catch {
            requireError(error, .io)
        }
        let asset = try! MLModelAsset(url: url)
        do {
            _ = try await asset.modelDescription(of: "main")
            fatalError("async asset description must fail closed")
        } catch {
            requireError(error, .generic)
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
        let configuration = MLModelConfiguration()
        precondition(configuration.computeUnits == .all)
        guard case .cpu = MLComputeDevice.allComputeDevices[0] else {
            fatalError("MLComputeUnits.all is every available Linux backend, which is CPU-only")
        }
    }

    static func testKeys() {
        precondition(MLParameterKey.learningRate.name == "learningRate")
        let scoped = MLParameterKey.weights.scoped(to: "conv1")
        precondition(scoped.scope == "conv1")
        precondition(MLParameterKey.beta1.name == "beta1")
        precondition(MLParameterKey.beta2.name == "beta2")
        precondition(MLParameterKey.biases.name == "biases")
        precondition(MLParameterKey.epochs.name == "epochs")
        precondition(MLParameterKey.eps.name == "eps")
        precondition(MLParameterKey.linkedModelFileName.name == "linkedModelFileName")
        precondition(MLParameterKey.linkedModelSearchPath.name == "linkedModelSearchPath")
        precondition(MLParameterKey.miniBatchSize.name == "miniBatchSize")
        precondition(MLParameterKey.momentum.name == "momentum")
        precondition(MLParameterKey.numberOfNeighbors.name == "numberOfNeighbors")
        precondition(MLParameterKey.seed.name == "seed")
        precondition(MLParameterKey.shuffle.name == "shuffle")
        precondition(MLMetricKey.lossValue.name == "lossValue")
        precondition(MLMetricKey.epochIndex.name == "epochIndex")
        precondition(MLMetricKey.miniBatchIndex.name == "miniBatchIndex")
        precondition(MLModelMetadataKey.author.rawValue.contains("author"))
        precondition(MLModelMetadataKey.description.rawValue.contains("description"))
        precondition(MLModelMetadataKey.versionString.rawValue.contains("versionstring"))
        precondition(MLModelMetadataKey.license.rawValue.contains("license"))
        precondition(MLModelMetadataKey.creatorDefinedKey.rawValue.contains("creatordefined"))
        precondition(MLFeatureValue.ImageOption.cropRect.rawValue.contains("CropRect"))
        precondition(MLFeatureValue.ImageOption.cropAndScale.rawValue.contains("CropAndScale"))
        _ = MLFeatureValue.ImageOption("custom")
    }

    static func testSequence() {
        let empty = MLSequence(empty: .string)
        precondition(empty.stringValues.isEmpty)
        let strings = MLSequence(stringArray: ["one", "two"])
        precondition(strings.type == .string)
        precondition(strings.stringValues == ["one", "two"])
        let ints = MLSequence(int64Array: [NSNumber(value: 1), NSNumber(value: 2)])
        precondition(ints.int64Values.map(\.intValue) == [1, 2])
        let alt = MLSequence(int64s: [NSNumber(value: 1), NSNumber(value: 2)])
        precondition(alt.type == .int64)
        let altStrings = MLSequence(strings: ["z"])
        precondition(altStrings.stringValues == ["z"])
        precondition(MLSequence(coder: NSCoder()) == nil)
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
        requireThrows(.customLayer) {
            _ = try MLFailClosedCustomLayer(parameters: [:])
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

    static func testDescriptions() {
        let multiConstraint = MLMultiArrayConstraint(
            shape: [NSNumber(value: 2), NSNumber(value: 3)],
            dataType: .float32,
            shapeConstraint: MLMultiArrayShapeConstraint(
                type: .enumerated,
                enumeratedShapes: [[NSNumber(value: 2), NSNumber(value: 3)]]
            )
        )
        precondition(multiConstraint.dataType == .float32)
        precondition(multiConstraint.shape.map(\.intValue) == [2, 3])
        precondition(multiConstraint.shapeConstraint.type == .enumerated)
        precondition(multiConstraint.shapeConstraint.enumeratedShapes.count == 1)
        precondition(multiConstraint.shapeConstraint.sizeRangeForDimension.isEmpty)

        let imageSize = MLImageSize(pixelsWide: 224, pixelsHigh: 224)
        precondition(imageSize.pixelsWide == 224)
        precondition(imageSize.pixelsHigh == 224)
        let sizeConstraint = MLImageSizeConstraint(
            type: .range,
            enumeratedImageSizes: [imageSize],
            pixelsWideRange: NSRange(location: 32, length: 480),
            pixelsHighRange: NSRange(location: 32, length: 480)
        )
        precondition(sizeConstraint.type == .range)
        precondition(sizeConstraint.enumeratedImageSizes.count == 1)
        precondition(sizeConstraint.pixelsWideRange.location == 32)
        precondition(sizeConstraint.pixelsHighRange.location == 32)
        let imageConstraint = MLImageConstraint(
            pixelsWide: 224,
            pixelsHigh: 224,
            pixelFormatType: 0x42475241,
            sizeConstraint: sizeConstraint
        )
        precondition(imageConstraint.pixelsWide == 224)
        precondition(imageConstraint.pixelsHigh == 224)
        precondition(imageConstraint.pixelFormatType == 0x42475241)
        precondition(imageConstraint.sizeConstraint.type == .range)

        let dictionaryConstraint = MLDictionaryConstraint(keyType: .string)
        precondition(dictionaryConstraint.keyType == .string)
        let sequenceConstraint = MLSequenceConstraint(
            valueDescription: MLFeatureDescription(name: "token", type: .string),
            countRange: NSRange(location: 1, length: 8)
        )
        precondition(sequenceConstraint.valueDescription.type == .string)
        precondition(sequenceConstraint.countRange.location == 1)
        let stateConstraint = MLStateConstraint(dataType: .float16, bufferShape: [4])
        precondition(stateConstraint.dataType == .float16)
        precondition(stateConstraint.bufferShape == [4])
        let numeric = MLNumericConstraint(
            minNumber: 0,
            maxNumber: 1,
            enumeratedNumbers: [0.5]
        )
        precondition(numeric.minNumber.doubleValue == 0)
        precondition(numeric.maxNumber.doubleValue == 1)
        precondition(numeric.enumeratedNumbers?.contains(0.5) == true)
        let parameter = MLParameterDescription(
            key: .learningRate,
            defaultValue: 0.01,
            numericConstraint: numeric
        )
        precondition(parameter.key.name == "learningRate")
        precondition((parameter.defaultValue as? Double) == 0.01)
        precondition(parameter.numericConstraint?.maxNumber.doubleValue == 1)

        let feature = MLFeatureDescription(
            name: "x",
            type: .multiArray,
            isOptional: false,
            multiArrayConstraint: multiConstraint
        )
        precondition(feature.name == "x")
        precondition(feature.type == .multiArray)
        precondition(!feature.isOptional)
        precondition(feature.multiArrayConstraint?.dataType == .float32)
        precondition(feature.dictionaryConstraint == nil)
        precondition(feature.imageConstraint == nil)
        precondition(feature.sequenceConstraint == nil)
        precondition(feature.stateConstraint == nil)
        let allowed = try! MLMultiArray(shape: [2, 3], dataType: .float32)
        precondition(feature.isAllowedValue(MLFeatureValue(multiArray: allowed)))
        precondition(!feature.isAllowedValue(MLFeatureValue(int64: 1)))
        let optional = MLFeatureDescription(name: "y", type: .string, isOptional: true)
        precondition(optional.isAllowedValue(MLFeatureValue(undefined: .string)))

        let description = MLModelDescription(
            inputDescriptionsByName: ["x": feature],
            outputDescriptionsByName: ["y": optional],
            stateDescriptionsByName: ["h": MLFeatureDescription(name: "h", type: .state, stateConstraint: stateConstraint)],
            trainingInputDescriptionsByName: [:],
            predictedFeatureName: "y",
            predictedProbabilitiesName: "probs",
            metadata: [
                .author: "OpenUIKit",
                .description: "probe",
                .versionString: "1.0",
                .license: "BSD"
            ],
            classLabels: ["cat", "dog"],
            isUpdatable: false,
            parameterDescriptionsByKey: [.learningRate: parameter]
        )
        precondition(description.inputDescriptionsByName["x"]?.name == "x")
        precondition(description.outputDescriptionsByName["y"]?.type == .string)
        precondition(description.stateDescriptionsByName["h"]?.stateConstraint?.bufferShape == [4])
        precondition(description.trainingInputDescriptionsByName.isEmpty)
        precondition(description.predictedFeatureName == "y")
        precondition(description.predictedProbabilitiesName == "probs")
        precondition(description.metadata[.author] as? String == "OpenUIKit")
        precondition((description.classLabels as? [String]) == ["cat", "dog"])
        precondition(!description.isUpdatable)
        precondition(description.parameterDescriptionsByKey[.learningRate]?.key.name == "learningRate")
        precondition(MLModelDescription(coder: NSCoder()) == nil)
        precondition(MLFeatureDescription(coder: NSCoder()) == nil)
        precondition(MLDictionaryConstraint(coder: NSCoder()) == nil)
        precondition(MLImageSize(coder: NSCoder()) == nil)
        precondition(MLImageSizeConstraint(coder: NSCoder()) == nil)
        precondition(MLImageConstraint(coder: NSCoder()) == nil)
        precondition(MLMultiArrayConstraint(coder: NSCoder()) == nil)
        precondition(MLMultiArrayShapeConstraint(coder: NSCoder()) == nil)
        precondition(MLSequenceConstraint(coder: NSCoder()) == nil)
        precondition(MLStateConstraint(coder: NSCoder()) == nil)
        precondition(MLNumericConstraint(coder: NSCoder()) == nil)
        precondition(MLParameterDescription(coder: NSCoder()) == nil)
        precondition(MLKey(coder: NSCoder()) == nil)
        requireThrows(.featureType) {
            _ = try MLFeatureValue(
                imageAtURL: URL(fileURLWithPath: "/tmp/missing.png"),
                constraint: imageConstraint
            )
        }
        requireThrows(.featureType) {
            _ = try MLFeatureValue(
                imageAtURL: URL(fileURLWithPath: "/tmp/missing.png"),
                pixelsWide: 2,
                pixelsHigh: 2,
                pixelFormatType: 0
            )
        }
    }

    static func testShapedArrayCollection() {
        let array = MLShapedArray<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [2, 3])
        precondition(array.count == 2)
        precondition(!array.isEmpty)
        precondition(array.startIndex == 0)
        precondition(array.endIndex == 2)
        precondition(array.indices == 0..<2)
        precondition(array.strides == [3, 1])
        precondition(array.first?.scalars == [1, 2, 3])
        precondition(array.last?.scalars == [4, 5, 6])
        var iterator = array.makeIterator()
        precondition(iterator.next()?.scalars.first == 1)
        let mapped = array.map { $0.scalars.first ?? 0 }
        precondition(mapped == [1, 4])
        precondition(array.dropFirst().count == 1)
        precondition(array.prefix(1).count == 1)
        precondition(Array(array.reversed()).first?.scalars == [4, 5, 6])
        var index = array.startIndex
        array.formIndex(after: &index)
        precondition(index == 1)
        array.formIndex(before: &index)
        precondition(index == 0)
        let concat = MLShapedArray<Float>(concatenating: [array, array], alongAxis: 0)
        precondition(concat.shape == [4, 3])
        let sliceConcat = MLShapedArraySlice<Float>(concatenating: [array[0], array[1]], alongAxis: 0)
        precondition(sliceConcat.scalars == array.scalars)
        var slice = array[0]
        precondition(slice.count == 3)
        slice.fill(with: 9)
        precondition(slice.scalars.allSatisfy { $0 == 9 })
        slice.fill(with: [7, 8, 9])
        precondition(slice.scalars == [7, 8, 9])
        let floats = array.scalars
        let fromData = MLShapedArray<Float>(
            data: floats.withUnsafeBytes { Data($0) },
            shape: [2, 3]
        )
        precondition(fromData.scalarCount == 6)
        let scalar = MLShapedArray<Float>(scalar: 3)
        precondition(scalar.isScalar)
        precondition(scalar.scalar == 3)
        let converted = MLShapedArray<Float>(converting: array)
        precondition(converted == array)
        let fromMulti = MLShapedArray<Float>(try! MLMultiArray(shape: [2], dataType: .float32))
        precondition(fromMulti.shape == [2])
        let random = MLShapedArray<Int32>(randomScalarsIn: 0..<4, shape: [2])
        precondition(random.scalarCount == 2)
        let bytes = UnsafeMutablePointer<Float>.allocate(capacity: 2)
        bytes.initialize(repeating: 1.5, count: 2)
        let copied = MLShapedArray<Float>(
            bytesNoCopy: UnsafeRawPointer(bytes),
            shape: [2],
            strides: [1],
            deallocator: .none
        )
        precondition(copied.scalars == [1.5, 1.5])
        bytes.deinitialize(count: 2)
        bytes.deallocate()
        var uninit = MLShapedArray<Float>(
            unsafeUninitializedShape: [2],
            initializingWith: { buffer, strides in
                precondition(strides == [1])
                buffer[0] = 1
                buffer[1] = 2
            }
        )
        precondition(uninit.scalars == [1, 2])
        uninit.withUnsafeMutableShapedBufferPointer { buffer, _, _ in
            buffer[0] = 8
        }
        precondition(uninit.scalars.first == 8)
        let layout = uninit.changingLayout(to: .lastMajorContiguous)
        precondition(layout.scalars.first == 8)
        let permuted = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2]).transposed(permutation: [1, 0])
        precondition(permuted.scalars == [1, 3, 2, 4])
        let tensor = MLTensor(concatenating: [MLTensor(repeating: 1, shape: [2]), MLTensor(repeating: 2, shape: [2])])
        precondition(tensor.shape == [4])
        let range = array[0..<1]
        precondition(range.count == 1)
        _ = array.description
        _ = slice.description
        precondition(MLShapedArraySlice<Float>(converting: array).shape == array.shape)
        var replaceable = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
        replaceable.replaceSubrange(1..<2, with: [MLShapedArraySlice<Float>(scalars: [9, 8], shape: [2])])
        precondition(replaceable.shape[0] == 2)
        let emptySlice = MLShapedArraySlice<Float>()
        precondition(emptySlice.count == 0)
    }

    static func testModelIOAndPrediction() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let identityURL = directory.appendingPathComponent("identity.mlmodel")
        try! CoreMLSpecification.identityModel(
            inputName: "x",
            outputName: "y",
            shape: [2],
            dataType: .float32,
            author: "depth-pass"
        ).write(to: identityURL)

        let compiled = try! MLModel.compileModel(at: identityURL)
        precondition(compiled.pathExtension == "mlmodelc")
        let metadataURL = compiled.appendingPathComponent("metadata.json")
        precondition(FileManager.default.fileExists(atPath: metadataURL.path))

        let model = try! MLModel(contentsOf: compiled, configuration: MLModelConfiguration())
        precondition(model.modelDescription.inputDescriptionsByName["x"]?.type == .multiArray)
        precondition(model.modelDescription.outputDescriptionsByName["y"]?.type == .multiArray)
        precondition(model.modelDescription.metadata[.author] as? String == "depth-pass")
        precondition(model.configuration.computeUnits == .all)
        let inputArray = try! MLMultiArray(shape: [2], dataType: .float32)
        inputArray[0] = 1.25
        inputArray[1] = 4.5
        let input = try! MLDictionaryFeatureProvider(dictionary: ["x": MLFeatureValue(multiArray: inputArray)])
        let output = try! model.prediction(from: input)
        precondition(output.featureValue(for: "y")?.multiArrayValue?[0].floatValue == 1.25)
        precondition(output.featureValue(for: "y")?.multiArrayValue?[1].floatValue == 4.5)
        let fromOptions = try! model.prediction(from: input, options: MLPredictionOptions())
        precondition(fromOptions.featureNames.contains("y"))
        let batch = try! model.predictions(from: MLArrayBatchProvider(array: [input]), options: MLPredictionOptions())
        precondition(batch.count == 1)
        let fromBatch = try! model.predictions(fromBatch: MLArrayBatchProvider(array: [input]))
        precondition(fromBatch.count == 1)
        requireThrows(.parameters) {
            _ = try model.parameterValue(for: .learningRate)
        }
        let configured = MLModelConfiguration()
        configured.parameters = [.learningRate: 0.2]
        let withParams = try! MLModel(contentsOf: compiled, configuration: configured)
        precondition((try! withParams.parameterValue(for: .learningRate) as? Double) == 0.2)

        let vectorURL = directory.appendingPathComponent("vectorizer.mlmodel")
        try! CoreMLSpecification.dictVectorizerModel(
            vocabulary: ["a", "c", "b", "z"]
        ).write(to: vectorURL)
        let vectorModel = try! MLModel(contentsOf: vectorURL)
        let dictIn = try! MLDictionaryFeatureProvider(dictionary: [
            "input": try! MLFeatureValue(dictionary: ["a": 4, "c": 8])
        ])
        let vectorOut = try! vectorModel.prediction(from: dictIn)
        let vector = vectorOut.featureValue(for: "output")?.multiArrayValue
        precondition(vector?[0].doubleValue == 4)
        precondition(vector?[1].doubleValue == 8)
        precondition(vector?[2].doubleValue == 0)
        precondition(vector?[3].doubleValue == 0)

        let pipelineURL = directory.appendingPathComponent("pipeline.mlmodel")
        try! CoreMLSpecification.pipelineModel(
            models: [
                CoreMLSpecification.identityModel(inputName: "x", outputName: "x", shape: [2]),
                CoreMLSpecification.identityModel(inputName: "x", outputName: "y", shape: [2])
            ]
        ).write(to: pipelineURL)
        let pipeline = try! MLModel(contentsOf: pipelineURL)
        let pipelineOut = try! pipeline.prediction(from: input)
        precondition(pipelineOut.featureValue(for: "y")?.multiArrayValue?[0].floatValue == 1.25)

        let neuralURL = directory.appendingPathComponent("neural.mlmodel")
        try! CoreMLSpecification.neuralNetworkStub().write(to: neuralURL)
        let neural = try! MLModel(contentsOf: neuralURL)
        precondition(neural.modelDescription.predictedFeatureName == "classLabel")
        precondition((neural.modelDescription.classLabels as? [String]) == ["cat", "dog"])
        do {
            _ = try neural.prediction(from: input)
            fatalError("neural network must fail closed")
        } catch {
            requireError(error, .generic)
            let message = (error as? MLModelError)?.userInfo[NSLocalizedDescriptionKey] as? String ?? ""
            precondition(message.contains("neural network layers not implemented"))
        }

        let loaded = try! MLModel(contentsOfURL: identityURL)
        precondition(loaded.modelDescription.inputDescriptionsByName["x"] != nil)

        let group = DispatchGroup()
        var compiledAsync: URL?
        group.enter()
        MLModel.compileModel(at: identityURL) { result in
            compiledAsync = try? result.get()
            group.leave()
        }
        precondition(group.wait(timeout: .now() + 5) == .success)
        precondition(compiledAsync != nil)
    }

    static func testCustomLayerFailsClosed() {
        requireThrows(.customLayer) {
            _ = try MLFailClosedCustomLayer(parameterDictionary: ["k": 1])
        }
        do {
            _ = try MLFailClosedCustomLayer(parameters: [:])
            fatalError("expected custom layer throw")
        } catch {
            requireError(error, .customLayer)
        }
    }

    static func testStructureSurface() {
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
        let bindingName = MLModelStructure.Program.Binding.name("x")
        let bindingValue = MLModelStructure.Program.Binding.value(MLModelStructure.Program.Value())
        _ = (bindingName, bindingValue)
        let argument = MLModelStructure.Program.Argument(bindings: [bindingName])
        precondition(argument.bindings.count == 1)
        let block = MLModelStructure.Program.Block(inputs: [named], outputs: ["y"], operations: [])
        precondition(block.outputNames == ["y"])
        let function = MLModelStructure.Program.Function(inputs: [named], block: block)
        precondition(function.inputs.count == 1)
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
        let usage = MLComputePlan.DeviceUsage(
            preferred: .cpu(MLCPUComputeDevice()),
            supported: MLComputeDevice.allComputeDevices
        )
        precondition(usage.supported.count == 1)
        let cost = MLComputePlan.Cost(weight: 1.25)
        precondition(cost.weight == 1.25)
        let plan = MLComputePlan(modelStructure: .unsupported)
        precondition(plan.deviceUsage(for: layer) == nil)
        let operation = MLModelStructure.Program.Operation(
            operatorName: "identity",
            inputs: ["x": argument],
            outputs: [named],
            blocks: [block]
        )
        precondition(operation.operatorName == "identity")
        precondition(plan.deviceUsage(for: operation) == nil)
        precondition(plan.estimatedCost(of: operation) == nil)
        if case .unsupported = plan.modelStructure { } else {
            fatalError("expected unsupported structure")
        }
        let dictionary = try! MLDictionaryFeatureProvider(dictionary: ["age": 21])
        precondition(dictionary.dictionary["age"]?.int64Value == 21)
        let batch = MLArrayBatchProvider(array: [dictionary])
        precondition(batch.array.count == 1)
        let provider: any MLFeatureProvider = dictionary
        precondition(provider.featureNames.contains("age"))
        let batchProvider: any MLBatchProvider = batch
        precondition(batchProvider.count == 1)
        let featureType: MLFeatureType = .int64
        _ = featureType
        let copyConfig = MLModelConfiguration()
        copyConfig.encode(with: NSCoder())
        _ = MLModelConfiguration.supportsSecureCoding
        _ = MLFeatureValue.supportsSecureCoding
        _ = MLMultiArray.supportsSecureCoding
        _ = MLSequence.supportsSecureCoding
        _ = MLModelDescription.supportsSecureCoding
        _ = MLFeatureDescription.supportsSecureCoding
        _ = MLKey.supportsSecureCoding
        let hints = MLOptimizationHints()
        _ = hints.reshapeFrequency
        _ = hints.specializationStrategy
        let reshape = MLOptimizationHints.ReshapeFrequency.frequent
        let strategy = MLOptimizationHints.SpecializationStrategy.default
        _ = (reshape, strategy)
    }
}

await CoreMLRuntime.main()

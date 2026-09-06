import CoreML
import Dispatch
import Foundation

func testMissingPathThrowsIO() {
    let url = URL(fileURLWithPath: "/tmp/missing.mlmodelc")
    coremlRequireThrows(.io) {
        _ = try MLModel(contentsOf: url)
    }
    coremlRequireThrows(.io) {
        _ = try MLModel(contentsOfURL: url)
    }
    coremlRequireThrows(.io) {
        _ = try MLModel(contentsOf: url, configuration: MLModelConfiguration())
    }
    coremlRequireThrows(.io) {
        _ = try MLModel(contentsOfURL: url, configuration: MLModelConfiguration())
    }
    coremlRequireThrows(.io) {
        _ = try MLModel.compileModel(at: url)
    }
    let asset = try! MLModelAsset(url: url)
    let fromURL = try! MLModelAsset(URL: url)
    let fromSpec = try! MLModelAsset(specification: Data([0, 1, 2]))
    _ = try! MLModelAsset(specification: Data([0]), blobMapping: [:])
    _ = (asset, fromURL, fromSpec)
}

func testCompileIdentityAndPrediction() {
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
    let withState = try! model.prediction(from: input, using: MLState())
    precondition(withState.featureNames.contains("y"))
    let withStateOptions = try! model.prediction(from: input, using: MLState(), options: MLPredictionOptions())
    precondition(withStateOptions.featureNames.contains("y"))
    let batch = try! model.predictions(from: MLArrayBatchProvider(array: [input]), options: MLPredictionOptions())
    precondition(batch.count == 1)
    let fromBatch = try! model.predictions(fromBatch: MLArrayBatchProvider(array: [input]))
    precondition(fromBatch.count == 1)
    _ = model.makeState()
    let loaded = try! MLModel(contentsOfURL: identityURL)
    precondition(loaded.modelDescription.inputDescriptionsByName["x"] != nil)
}

func testDictVectorizerPrediction() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
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
}

func testPipelinePrediction() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let pipelineURL = directory.appendingPathComponent("pipeline.mlmodel")
    try! CoreMLSpecification.pipelineModel(
        models: [
            CoreMLSpecification.identityModel(inputName: "x", outputName: "x", shape: [2]),
            CoreMLSpecification.identityModel(inputName: "x", outputName: "y", shape: [2])
        ]
    ).write(to: pipelineURL)
    let pipeline = try! MLModel(contentsOf: pipelineURL)
    let inputArray = try! MLMultiArray(shape: [2], dataType: .float32)
    inputArray[0] = 1.25
    let input = try! MLDictionaryFeatureProvider(dictionary: ["x": MLFeatureValue(multiArray: inputArray)])
    let pipelineOut = try! pipeline.prediction(from: input)
    precondition(pipelineOut.featureValue(for: "y")?.multiArrayValue?[0].floatValue == 1.25)
}

func testNeuralNetworkFailsClosed() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let neuralURL = directory.appendingPathComponent("neural.mlmodel")
    try! CoreMLSpecification.neuralNetworkStub().write(to: neuralURL)
    let neural = try! MLModel(contentsOf: neuralURL)
    precondition(neural.modelDescription.predictedFeatureName == "classLabel")
    precondition((neural.modelDescription.classLabels as? [String]) == ["cat", "dog"])
    let inputArray = try! MLMultiArray(shape: [2], dataType: .float32)
    let input = try! MLDictionaryFeatureProvider(dictionary: ["x": MLFeatureValue(multiArray: inputArray)])
    do {
        _ = try neural.prediction(from: input)
        fatalError("neural network must fail closed")
    } catch {
        coremlRequireError(error, .generic)
        let message = (error as? MLModelError)?.userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        precondition(message.contains("neural network layers not implemented"))
    }
}

func testParameterValueFromConfiguration() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let identityURL = directory.appendingPathComponent("identity.mlmodel")
    try! CoreMLSpecification.identityModel(inputName: "x", outputName: "y", shape: [2]).write(to: identityURL)
    let compiled = try! MLModel.compileModel(at: identityURL)
    let model = try! MLModel(contentsOf: compiled)
    coremlRequireThrows(.parameters) {
        _ = try model.parameterValue(for: .learningRate)
    }
    let configured = MLModelConfiguration()
    configured.parameters = [.learningRate: 0.2]
    let withParams = try! MLModel(contentsOf: compiled, configuration: configured)
    precondition((try! withParams.parameterValue(for: .learningRate) as? Double) == 0.2)
}

func testGLMLinearPrediction() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let glmURL = directory.appendingPathComponent("linear.mlmodel")
    try! CoreMLSpecification.glmRegressorModel(
        weights: [3, 4],
        offset: 5,
        author: "wave8"
    ).write(to: glmURL)
    let compiled = try! MLModel.compileModel(at: glmURL)
    precondition(FileManager.default.fileExists(atPath: compiled.appendingPathComponent("metadata.plist").path))
    let model = try! MLModel(contentsOf: compiled)
    precondition(model.modelDescription.metadata[.author] as? String == "wave8")
    precondition(model.modelDescription.metadata[.license] as? String == "BSD")
    precondition(model.modelDescription.metadata[.versionString] as? String == "1.0")
    let inputArray = try! MLMultiArray(shape: [2], dataType: .double)
    inputArray[0] = 1
    inputArray[1] = 2
    let input = try! MLDictionaryFeatureProvider(dictionary: ["x": MLFeatureValue(multiArray: inputArray)])
    let output = try! model.prediction(from: input)
    // y = 3*1 + 4*2 + 5 = 16
    precondition(output.featureValue(for: "y")?.multiArrayValue?[0].doubleValue == 16)
    try! model.write(to: directory.appendingPathComponent("written.mlmodelc"))
    precondition(FileManager.default.fileExists(atPath: directory.appendingPathComponent("written.mlmodelc/metadata.plist").path))
}

func testCompiledPlistMetadataLoad() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let identityURL = directory.appendingPathComponent("identity.mlmodel")
    try! CoreMLSpecification.identityModel(
        inputName: "in",
        outputName: "out",
        shape: [2],
        author: "plist-author"
    ).write(to: identityURL)
    let compiled = try! MLModel.compileModel(at: identityURL)
    try? FileManager.default.removeItem(at: compiled.appendingPathComponent("metadata.json"))
    let reloaded = try! MLModel(contentsOf: compiled)
    precondition(reloaded.modelDescription.inputDescriptionsByName["in"]?.type == .multiArray)
    precondition(reloaded.modelDescription.metadata[.author] as? String == "plist-author")
}

func testCompletionDeliveryIsOffCaller() {
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
        coremlWaitFor(delivered)
    }

    assertReturnedBeforeCallback { finish in
        MLModel.load(contentsOf: url) { result in
            switch result {
            case .failure(let error):
                coremlRequireError(error, .generic)
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
                coremlRequireError(error, .io)
            case .success:
                fatalError("compile must fail closed")
            }
            finish()
        }
    }

    assertReturnedBeforeCallback { finish in
        MLModel.load(asset, configuration: MLModelConfiguration()) { model, error in
            precondition(model == nil)
            coremlRequireError(error!, .generic)
            finish()
        }
    }

    assertReturnedBeforeCallback { finish in
        asset.functionNames { names, error in
            precondition(names == nil)
            coremlRequireError(error!, .generic)
            finish()
        }
    }

    assertReturnedBeforeCallback { finish in
        asset.modelDescription { description, error in
            precondition(description == nil)
            coremlRequireError(error!, .generic)
            finish()
        }
    }

    assertReturnedBeforeCallback { finish in
        asset.modelDescription(of: "main") { description, error in
            precondition(description == nil)
            coremlRequireError(error!, .generic)
            finish()
        }
    }

    var loadCount = 0
    let loadOnce = DispatchSemaphore(value: 0)
    MLModel.load(contentsOf: url) { _ in
        loadCount += 1
        loadOnce.signal()
    }
    coremlWaitFor(loadOnce)
    Thread.sleep(forTimeInterval: 0.05)
    precondition(loadCount == 1, "load completion must run exactly once")

    var compileCount = 0
    let compileOnce = DispatchSemaphore(value: 0)
    MLModel.compileModel(at: url) { _ in
        compileCount += 1
        compileOnce.signal()
    }
    coremlWaitFor(compileOnce)
    Thread.sleep(forTimeInterval: 0.05)
    precondition(compileCount == 1, "compile completion must run exactly once")

    var assetCount = 0
    let assetOnce = DispatchSemaphore(value: 0)
    asset.functionNames { _, _ in
        assetCount += 1
        assetOnce.signal()
    }
    coremlWaitFor(assetOnce)
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

func testAsyncLoadCompileAndStructureFailClosed() {
    coremlWaitAsync {
        let url = URL(fileURLWithPath: "/tmp/missing.mlmodelc")
        do {
            _ = try await MLModel.load(contentsOf: url)
            fatalError("async load must fail closed")
        } catch {
            coremlRequireError(error, .generic)
        }
        do {
            _ = try await MLModel.compileModel(at: url)
            fatalError("async compile must fail closed")
        } catch {
            coremlRequireError(error, .io)
        }
        let asset = try! MLModelAsset(url: url)
        do {
            _ = try await asset.modelDescription(of: "main")
            fatalError("async asset description must fail closed")
        } catch {
            coremlRequireError(error, .generic)
        }
        do {
            _ = try await MLModelStructure.load(contentsOf: url)
            fatalError("structure load must fail closed")
        } catch {
            coremlRequireError(error, .io)
        }
        do {
            _ = try await MLModelStructure.load(asset: asset)
            fatalError("structure asset load must fail closed")
        } catch {
            coremlRequireError(error, .io)
        }
        do {
            _ = try await MLComputePlan.load(contentsOf: url, configuration: MLModelConfiguration())
            fatalError("compute plan load must fail closed")
        } catch {
            coremlRequireError(error, .io)
        }
        do {
            _ = try await MLComputePlan.load(asset: asset, configuration: MLModelConfiguration())
            fatalError("compute plan asset load must fail closed")
        } catch {
            coremlRequireError(error, .io)
        }
        let asyncPolicy = await withMLTensorComputePolicy(.cpuOnly) {
            await Task.yield()
            return 4
        }
        precondition(asyncPolicy == 4)
    }
}

import CoreML
import Dispatch
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


func testMultiArrayInitAndSubscript() {
    let array = try! MLMultiArray(shape: [2, 3], dataType: .float32)
    precondition(array.count == 6)
    precondition(array.shape.map(\.intValue) == [2, 3])
    precondition(array.strides.map(\.intValue) == [3, 1])
    precondition(array.dataType == .float32)
    array[0] = 1.5
    array[[NSNumber(value: 1), NSNumber(value: 2)]] = 9
    precondition(array[0].floatValue == 1.5)
    precondition(abs(array[[NSNumber(value: 1), NSNumber(value: 2)]].floatValue - 9) < 0.0001)
    let fromDoubles = try! MLMultiArray([1.0, 2.0, 3.0])
    precondition(fromDoubles.count == 3)
    precondition(fromDoubles.dataType == .double)
    let fromFloats = try! MLMultiArray([Float(1), Float(2)])
    precondition(fromFloats.dataType == .float32)
    let ints = try! MLMultiArray([Int32(4), Int32(5)])
    precondition(ints[1].int32Value == 5)
    let shaped = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    let fromShaped = MLMultiArray(shaped)
    precondition(fromShaped.count == 4)
    precondition(fromShaped.dataType == .float32)
}

func testMultiArrayConcatAndTransfer() {
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
    precondition(axisOne[[NSNumber(value: 0), NSNumber(value: 2)]].floatValue == 5)

    let wrapped = MLMultiArray(
        byConcatenatingMultiArrays: [left, right],
        alongAxis: -1,
        dataType: .double
    )
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
}

func testMultiArrayPointerViewsAndDeallocator() {
    let fromDoubles = try! MLMultiArray([1.0, 2.0, 3.0])
    fromDoubles.withUnsafeBytes { buffer in
        precondition(buffer.count == 24)
    }
    let concat = MLMultiArray(
        byConcatenatingMultiArrays: [fromDoubles, fromDoubles],
        alongAxis: 0,
        dataType: .double
    )
    concat.withUnsafeBufferPointer(ofType: Double.self) { buffer in
        precondition(Array(buffer) == [1, 2, 3, 1, 2, 3])
    }
    concat.withUnsafeMutableBufferPointer(ofType: Double.self) { buffer, _ in
        buffer[0] = 9
    }
    precondition(concat[0].doubleValue == 9)

    let shaped = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    let fromShaped = MLMultiArray(shaped)
    let pointerBuffer = try! UnsafeBufferPointer<Float>(fromShaped)
    precondition(pointerBuffer.count == 4)
    _ = try! UnsafeMutableBufferPointer<Float>(fromShaped)
    precondition(fromShaped.withUnsafeMutableBytes { buffer, strides in
        strides == [2, 1] && buffer.count == 16
    })
    _ = fromShaped.dataPointer

    coremlRequireThrows(.io) {
        _ = try MLMultiArray(shape: [NSNumber(value: -1)], dataType: .float32)
    }
    let scratch = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 8)
    scratch.initializeMemory(as: UInt8.self, repeating: 0, count: 16)
    coremlRequireThrows(.featureType) {
        _ = try MLMultiArray(
            dataPointer: scratch,
            shape: [NSNumber(value: 2), NSNumber(value: 2)],
            dataType: .float32,
            strides: [NSNumber(value: 1)],
            deallocator: { _ in }
        )
    }
    coremlRequireThrows(.io) {
        _ = try MLMultiArray(
            dataPointer: scratch,
            shape: [NSNumber(value: 2)],
            dataType: .int32,
            strides: [NSNumber(value: -1)],
            deallocator: { _ in }
        )
    }
    coremlRequireThrows(.io) {
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

func testMultiArrayCoderReturnsNil() {
    precondition(MLMultiArray(coder: NSCoder()) == nil)
    _ = MLMultiArray.supportsSecureCoding
}


func testShapedArrayScalarsAndTransforms() {
    var array = MLShapedArray<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [2, 3])
    precondition(array.scalarCount == 6)
    precondition(!array.isScalar)
    precondition(array.shape == [2, 3])
    precondition(array.strides == [3, 1])
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
    let permuted = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2]).transposed(permutation: [1, 0])
    precondition(permuted.scalars == [1, 3, 2, 4])
    let reshaped = array.reshaped(to: [3, 2])
    precondition(reshaped.shape == [3, 2])
    let scalar = MLShapedArray<Float>(scalar: 3)
    precondition(scalar.isScalar)
    precondition(scalar.scalar == 3)
    let repeating = MLShapedArray<Float>(repeating: 7, shape: [2])
    precondition(repeating.scalars == [7, 7])
    precondition(Float.multiArrayDataType == .float32)
    precondition(Double.multiArrayDataType == .double)
    precondition(Float16.multiArrayDataType == .float16)
    precondition(Int32.multiArrayDataType == .int32)
    precondition(Int8.multiArrayDataType == .int8)
}

func testShapedArrayCollectionTraversal() {
    let array = MLShapedArray<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [2, 3])
    precondition(array.count == 2)
    precondition(!array.isEmpty)
    precondition(array.startIndex == 0)
    precondition(array.endIndex == 2)
    precondition(array.indices == 0..<2)
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
    precondition(array.index(after: 0) == 1)
    precondition(array.index(before: 1) == 0)
    let range = array[0..<1]
    precondition(range.count == 1)
    _ = array.description
}

func testShapedArrayConcatConvertAndSlice() {
    let array = MLShapedArray<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [2, 3])
    let concat = MLShapedArray<Float>(concatenating: [array, array], alongAxis: 0)
    precondition(concat.shape == [4, 3])
    let sliceConcat = MLShapedArraySlice<Float>(concatenating: [array[0], array[1]], alongAxis: 0)
    precondition(sliceConcat.scalars == array.scalars)
    var slice = array[0]
    precondition(slice.count == 3)
    precondition(slice.shape == [3])
    slice.fill(with: 9)
    precondition(slice.scalars.allSatisfy { $0 == 9 })
    slice.fill(with: [7, 8, 9])
    precondition(slice.scalars == [7, 8, 9])
    _ = slice.description
    precondition(!slice.isEmpty)
    precondition(slice.startIndex == 0)
    precondition(slice.endIndex == 3)
    precondition(slice.first?.scalar == 7)
    precondition(slice.last?.scalar == 9)
    let mappedSlice = slice.map { $0.scalar ?? 0 }
    precondition(mappedSlice == [7, 8, 9])
    precondition(slice.dropFirst().count == 2)
    precondition(slice.prefix(1).count == 1)
    precondition(Array(slice.reversed()).first?.scalar == 9)
    var sliceIndex = slice.startIndex
    slice.formIndex(after: &sliceIndex)
    slice.formIndex(before: &sliceIndex)
    var sliceIterator = slice.makeIterator()
    precondition(sliceIterator.next()?.scalar == 7)

    let floats = array.scalars
    let fromData = MLShapedArray<Float>(
        data: floats.withUnsafeBytes { Data($0) },
        shape: [2, 3]
    )
    precondition(fromData.scalarCount == 6)
    let fromDataStrides = MLShapedArray<Float>(
        data: floats.withUnsafeBytes { Data($0) },
        shape: [2, 3],
        strides: [3, 1]
    )
    precondition(fromDataStrides.strides == [3, 1])
    let converted = MLShapedArray<Float>(converting: array)
    precondition(converted == array)
    let fromMulti = MLShapedArray<Float>(try! MLMultiArray(shape: [2], dataType: .float32))
    precondition(fromMulti.shape == [2])
    let convertingMulti = MLShapedArray<Float>(converting: try! MLMultiArray(shape: [2], dataType: .float32))
    precondition(convertingMulti.shape == [2])
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
    let noStrideCopy = MLShapedArray<Float>(
        bytesNoCopy: UnsafeRawPointer(bytes),
        shape: [2],
        deallocator: .none
    )
    precondition(noStrideCopy.scalarCount == 2)
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
    uninit.withUnsafeShapedBufferPointer { buffer, _, _ in
        precondition(buffer.count == 2)
    }
    uninit.withUnsafeMutableShapedBufferPointer { buffer, _, _ in
        buffer[0] = 8
    }
    uninit.withUnsafeMutableShapedBufferPointer(using: .lastMajorContiguous) { buffer, _, _ in
        buffer[1] = 9
    }
    precondition(uninit.scalars.first == 8)
    let layout = uninit.changingLayout(to: .lastMajorContiguous)
    precondition(layout.scalars.first == 8)
    precondition(MLShapedArraySlice<Float>(converting: array).shape == array.shape)
    var replaceable = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    replaceable.replaceSubrange(1..<2, with: [MLShapedArraySlice<Float>(scalars: [9, 8], shape: [2])])
    precondition(replaceable.shape[0] == 2)
    let emptySlice = MLShapedArraySlice<Float>()
    precondition(emptySlice.count == 0)
    let sliceScalar = MLShapedArraySlice<Float>(scalar: 4)
    precondition(sliceScalar.scalar == 4)
    let sliceRepeating = MLShapedArraySlice<Float>(repeating: 1, shape: [2])
    precondition(sliceRepeating.scalars == [1, 1])
    let sliceIdentity = MLShapedArraySlice<Int32>(identityMatrixOfSize: 2)
    precondition(sliceIdentity.scalarCount == 4)
    let sliceRandom = MLShapedArraySlice<Int32>(randomScalarsIn: 0..<3, shape: [2])
    precondition(sliceRandom.scalarCount == 2)
    let sliceFromMulti = MLShapedArraySlice<Float>(try! MLMultiArray(shape: [2], dataType: .float32))
    precondition(sliceFromMulti.shape == [2])
    var sliceTransforms = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    precondition(sliceTransforms.transposed().scalarCount == 4)
    precondition(sliceTransforms.transposed(permutation: [1, 0]).scalarCount == 4)
    precondition(sliceTransforms.expandingShape(at: 0).shape.first == 1)
    precondition(sliceTransforms.squeezingShape().scalarCount == 4)
    precondition(sliceTransforms.reshaped(to: [4]).shape == [4])
    _ = sliceTransforms.changingLayout(to: .firstMajorContiguous)
    sliceTransforms.withUnsafeShapedBufferPointer { buffer, _, _ in
        precondition(buffer.count == 4)
    }
    sliceTransforms.withUnsafeMutableShapedBufferPointer { buffer, _, _ in
        buffer[0] = 0
    }
    sliceTransforms.withUnsafeMutableShapedBufferPointer(using: .lastMajorContiguous) { buffer, _, _ in
        buffer[1] = 0
    }
    let literal: MLShapedArray<Float> = [1, 2]
    precondition(literal.scalarCount == 2)
    let sliceLiteral: MLShapedArraySlice<Float> = [3, 4]
    precondition(sliceLiteral.scalarCount == 2)
    let sliceData = MLShapedArraySlice<Float>(data: Data(count: 8), shape: [2])
    precondition(sliceData.shape == [2])
    let sliceDataStrides = MLShapedArraySlice<Float>(data: Data(count: 8), shape: [2], strides: [1])
    precondition(sliceDataStrides.strides == [1])
    let sliceUninit = MLShapedArraySlice<Float>(
        unsafeUninitializedShape: [2],
        initializingWith: { buffer, _ in
            buffer[0] = 1
            buffer[1] = 2
        }
    )
    precondition(sliceUninit.scalars == [1, 2])
    let sliceBytes = UnsafeMutablePointer<Float>.allocate(capacity: 2)
    sliceBytes.initialize(repeating: 1, count: 2)
    let sliceCopied = MLShapedArraySlice<Float>(
        bytesNoCopy: UnsafeRawPointer(sliceBytes),
        shape: [2],
        strides: [1],
        deallocator: .none
    )
    precondition(sliceCopied.scalarCount == 2)
    let sliceCopiedNoStride = MLShapedArraySlice<Float>(
        bytesNoCopy: UnsafeRawPointer(sliceBytes),
        shape: [2],
        deallocator: .none
    )
    precondition(sliceCopiedNoStride.scalarCount == 2)
    sliceBytes.deinitialize(count: 2)
    sliceBytes.deallocate()
}

func testShapedArrayJSONCodingAndRanges() {
    let array = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    let encoded = try! JSONEncoder().encode(array)
    let decoded = try! JSONDecoder().decode(MLShapedArray<Float>.self, from: encoded)
    precondition(decoded == array)
    let policy = withMLTensorComputePolicy(.cpuOnly) { 7 }
    precondition(policy == 7)
    let range = (1..<4).relative(toShapedArrayAxis: 0..<10)
    precondition(range == 1..<4)
    precondition((1...3).relative(toShapedArrayAxis: 0..<10) == 1..<4)
    precondition((2...).relative(toShapedArrayAxis: 0..<5) == 2..<5)
    precondition((..<3).relative(toShapedArrayAxis: 0..<5) == 0..<3)
    precondition((...2).relative(toShapedArrayAxis: 0..<5) == 0..<3)
}


func testFeatureValueScalarsAndEquality() {
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
    precondition(intValue.isEqual(to: MLFeatureValue(int64: 42)))
    precondition(!intValue.isEqual(to: doubleValue))
    let fromSendable = MLFeatureValue(MLSendableFeatureValue(21))
    precondition(fromSendable.int64Value == 21)
}

func testFeatureValueSequenceDictionaryAndShapedArray() {
    let dict = try! MLFeatureValue(dictionary: ["cat": NSNumber(value: 0.9)])
    precondition(dict.dictionaryValue["cat"]?.doubleValue == 0.9)
    let sequence = MLFeatureValue(sequence: MLSequence(strings: ["a", "b"]))
    precondition(sequence.sequenceValue?.stringValues == ["a", "b"])
    let shaped = MLShapedArray<Float>(scalars: [0, 1], shape: [2])
    let fromShaped = MLFeatureValue(shapedArray: shaped)
    precondition(fromShaped.shapedArrayValue(of: Float.self)?.scalars == [0, 1])
}

func testFeatureValueImageAtURLFailsClosed() {
    let imageSize = MLImageSize(pixelsWide: 2, pixelsHigh: 2)
    let sizeConstraint = MLImageSizeConstraint(
        type: .range,
        enumeratedImageSizes: [imageSize],
        pixelsWideRange: NSRange(location: 1, length: 8),
        pixelsHighRange: NSRange(location: 1, length: 8)
    )
    let imageConstraint = MLImageConstraint(
        pixelsWide: 2,
        pixelsHigh: 2,
        pixelFormatType: 0,
        sizeConstraint: sizeConstraint
    )
    coremlRequireThrows(.featureType) {
        _ = try MLFeatureValue(
            imageAtURL: URL(fileURLWithPath: "/tmp/missing.png"),
            constraint: imageConstraint
        )
    }
    coremlRequireThrows(.featureType) {
        _ = try MLFeatureValue(
            imageAtURL: URL(fileURLWithPath: "/tmp/missing.png"),
            pixelsWide: 2,
            pixelsHigh: 2,
            pixelFormatType: 0
        )
    }
    precondition(MLFeatureValue(coder: NSCoder()) == nil)
    _ = MLFeatureValue.supportsSecureCoding
    precondition(MLFeatureValue.ImageOption.cropRect.rawValue.contains("CropRect"))
    precondition(MLFeatureValue.ImageOption.cropAndScale.rawValue.contains("CropAndScale"))
    let custom = MLFeatureValue.ImageOption("custom")
    precondition(custom.rawValue == "custom")
    precondition(MLFeatureValue.ImageOption(rawValue: "x") != custom)
    _ = custom.hashValue
    var hasher = Hasher()
    custom.hash(into: &hasher)
}

func testSequenceConstruction() {
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
    _ = MLSequence.supportsSecureCoding
}

func testSendableFeatureValueRoundTrip() {
    let sendable = MLSendableFeatureValue(21)
    precondition(sendable.integerValue == 21)
    precondition(sendable.type == .int64)
    precondition(sendable.isScalar)
    let fromFeature = MLSendableFeatureValue(MLFeatureValue(string: "hi"))
    precondition(fromFeature?.stringValue == "hi")
    let fromDouble = MLSendableFeatureValue(1.5)
    precondition(fromDouble.doubleValue == 1.5)
    precondition(fromDouble.floatValue == 1.5)
    let fromFloat = MLSendableFeatureValue(Float(2.25))
    precondition(fromFloat.floatValue == 2.25)
    let fromFloat16 = MLSendableFeatureValue(Float16(1))
    precondition(fromFloat16.float16Value == 1)
    let fromStringArray = MLSendableFeatureValue(["a", "b"])
    precondition(fromStringArray.stringArrayValue == ["a", "b"])
    let undefined = MLSendableFeatureValue(undefined: .double)
    precondition(undefined.isUndefined)
    precondition(!undefined.isShapedArray)
    _ = undefined.debugDescription
    precondition(sendable != undefined)
    let roundTrip = MLFeatureValue(sendable)
    precondition(roundTrip.int64Value == 21)
}


func testDictionaryFeatureProvider() {
    let input = try! MLDictionaryFeatureProvider(dictionary: [
        "age": MLFeatureValue(int64: 21),
        "score": 0.5,
        "label": "adult"
    ])
    precondition(input.featureNames == ["age", "score", "label"])
    precondition(input["age"]?.int64Value == 21)
    precondition(input.featureValue(for: "label")?.stringValue == "adult")
    precondition(input.dictionary["age"]?.int64Value == 21)
    let provider: any MLFeatureProvider = input
    precondition(provider.featureNames.contains("age"))
    precondition(provider.featureValue(for: "age")?.int64Value == 21)
    precondition(MLDictionaryFeatureProvider(coder: NSCoder()) == nil)
}

func testArrayBatchProvider() {
    let input = try! MLDictionaryFeatureProvider(dictionary: [
        "age": MLFeatureValue(int64: 21)
    ])
    let batch = MLArrayBatchProvider(array: [input, input])
    precondition(batch.count == 2)
    precondition(batch.features(at: 1).featureValue(for: "age")?.int64Value == 21)
    precondition(batch.array.count == 2)
    let alias = MLArrayBatchProvider(featureProviderArray: [input])
    precondition(alias.count == 1)
    let columns = try! MLArrayBatchProvider(dictionary: [
        "x": [1, 2],
        "y": ["a", "b"]
    ])
    precondition(columns.count == 2)
    precondition(columns.features(at: 1).featureValue(for: "x")?.int64Value == 2)
    let batchProvider: any MLBatchProvider = batch
    precondition(batchProvider.count == 2)
    _ = batchProvider.features(at: 0)
}


func testConstraintsAndFeatureDescription() {
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
}

func testModelDescriptionMetadata() {
    let feature = MLFeatureDescription(name: "x", type: .multiArray)
    let optional = MLFeatureDescription(name: "y", type: .string, isOptional: true)
    let stateConstraint = MLStateConstraint(dataType: .float16, bufferShape: [4])
    let numeric = MLNumericConstraint(minNumber: 0, maxNumber: 1, enumeratedNumbers: [0.5])
    let parameter = MLParameterDescription(
        key: .learningRate,
        defaultValue: 0.01,
        numericConstraint: numeric
    )
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
}

func testDescriptionCodersReturnNil() {
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
    _ = MLModelDescription.supportsSecureCoding
    _ = MLFeatureDescription.supportsSecureCoding
}


func testModelConfigurationDefaultsAndCopy() {
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
    copy.encode(with: NSCoder())
    precondition(MLModelConfiguration(coder: NSCoder()) == nil)
    _ = MLModelConfiguration.supportsSecureCoding
    _ = configuration.optimizationHints
}

func testPredictionOptionsAndOptimizationHints() {
    let options = MLPredictionOptions()
    precondition(options.usesCPUOnly == false)
    options.usesCPUOnly = true
    options.outputBackings = ["out": 1]
    precondition(options.outputBackings["out"] as? Int == 1)
    let hints = MLOptimizationHints()
    precondition(hints.reshapeFrequency == .frequent)
    precondition(hints.specializationStrategy == .default)
    let other = MLOptimizationHints()
    precondition(hints == other)
    var mutated = MLOptimizationHints()
    mutated.reshapeFrequency = .infrequent
    precondition(hints != mutated)
    precondition(MLOptimizationHints.ReshapeFrequency.frequent != .infrequent)
    precondition(MLOptimizationHints.SpecializationStrategy.default != .fastPrediction)
}

func testParameterMetricAndMetadataKeys() {
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
    precondition(MLModelMetadataKey(rawValue: "x") != .author)
    _ = MLModelMetadataKey.author.hashValue
    var hasher = Hasher()
    MLModelMetadataKey.author.hash(into: &hasher)
    precondition(MLKey(coder: NSCoder()) == nil)
    _ = MLKey.supportsSecureCoding
}

func testComputeDevicesAreCPUOnly() {
    let devices = MLModel.availableComputeDevices
    precondition(devices.count == 1)
    guard case .cpu = devices[0] else {
        fatalError("Linux CoreML must advertise only CPU")
    }
    precondition(MLComputeDevice.allComputeDevices.count == 1)
    precondition(MLComputeDevice.allComputeDevices[0] == devices[0])
    let ane = MLNeuralEngineComputeDevice()
    precondition(ane.totalCoreCount == 0)
    let policy = MLComputePolicy(.cpuOnly)
    precondition(policy == .cpuOnly)
    precondition(policy.description.contains("cpuOnly"))
    _ = policy.hashValue
    var hasher = Hasher()
    policy.hash(into: &hasher)
    _ = policy.customMirror
    precondition(MLComputePolicy.cpuAndGPU != .cpuOnly)
    _ = MLCPUComputeDevice()
    _ = MLGPUComputeDevice()
    let protocolWitness: any MLComputeDeviceProtocol = MLCPUComputeDevice()
    _ = protocolWitness
}


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


func testUpdateTaskFailsClosed() {
    let provider = MLArrayBatchProvider(array: [])
    let url = URL(fileURLWithPath: "/tmp/model.mlmodelc")
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAt: url,
            trainingData: provider,
            completionHandler: { _ in }
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAtURL: url,
            trainingData: provider,
            completionHandler: { _ in }
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAt: url,
            trainingData: provider,
            configuration: MLModelConfiguration(),
            completionHandler: { _ in }
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAtURL: url,
            trainingData: provider,
            configuration: MLModelConfiguration(),
            completionHandler: { _ in }
        )
    }
    let handlers = MLUpdateProgressHandlers(
        forEvents: [.trainingBegin, .epochEnd],
        progressHandler: nil,
        completionHandler: { _ in }
    )
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAt: url,
            trainingData: provider,
            progressHandlers: handlers
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAtURL: url,
            trainingData: provider,
            progressHandlers: handlers
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAt: url,
            trainingData: provider,
            configuration: nil,
            progressHandlers: handlers
        )
    }
    coremlRequireThrows(.update) {
        _ = try MLUpdateTask(
            forModelAtURL: url,
            trainingData: provider,
            configuration: nil,
            progressHandlers: handlers
        )
    }
}

func testCustomLayerFailsClosed() {
    coremlRequireThrows(.customLayer) {
        _ = try MLFailClosedCustomLayer(parameterDictionary: ["k": 1])
    }
    coremlRequireThrows(.customLayer) {
        _ = try MLFailClosedCustomLayer(parameters: [:])
    }
}

func testTaskResumeAndCancel() {
    let task = MLTask()
    precondition(task.state == .failed)
    _ = task.taskIdentifier
    _ = task.error
    task.resume()
    precondition(task.state == .failed)
    task.cancel()
    precondition(task.state == .completed)
}

func testEmptyStateFailsClosed() {
    let state = MLState()
    do {
        _ = try state.withMultiArray { _ in 1 }
        fatalError("empty MLState must fail closed")
    } catch {
        coremlRequireError(error, .generic)
    }
}


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


func testTensorShapeRankAndFlatten() {
    let tensor = MLTensor(repeating: 1.0, shape: [2, 2])
    precondition(tensor.shape == [2, 2])
    precondition(tensor.scalarCount == 4)
    precondition(tensor.rank == 2)
    precondition(!tensor.isScalar)
    _ = tensor.scalarType
    _ = tensor.description
    _ = tensor.customMirror
    let flat = tensor.flattened()
    precondition(flat.shape == [4])
    let reshaped = tensor.reshaped(to: [4, 1])
    precondition(reshaped.shape == [4, 1])
}

func testTensorConcatenatingAndInitializers() {
    let tensor = MLTensor(concatenating: [MLTensor(repeating: 1, shape: [2]), MLTensor(repeating: 2, shape: [2])])
    precondition(tensor.shape == [4])
    let zeros = MLTensor(zeros: [3], scalarType: Float.self)
    precondition(zeros.shape == [3])
    let fromFloats = MLTensor([Float(1), Float(2)])
    precondition(fromFloats.shape == [2])
    let fromInts = MLTensor([Int32(3), Int32(4)])
    precondition(fromInts.shape == [2])
    let shaped = MLTensor(shape: [2], scalars: [Float(1), Float(2)])
    precondition(shaped.scalarCount == 2)
    let fromData = MLTensor(shape: [1], data: Data(count: 4), scalarType: Float.self)
    precondition(fromData.rank == 1)
    coremlWaitAsync {
        let converted = await tensor.shapedArray(of: Float.self)
        precondition(converted.scalarCount == 4)
    }
}

func testTensorArithmeticAndMatmul() {
    let a = MLTensor(shape: [2, 2], scalars: [Float(1), 2, 3, 4])
    let b = MLTensor(shape: [2, 2], scalars: [Float(5), 6, 7, 8])
    a.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 2, 3, 4])
    }
    let sum = a + b
    sum.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [6, 8, 10, 12])
    }
    let scaled = a * Float(2)
    scaled.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [2, 4, 6, 8])
    }
    let shifted = Float(1) + a
    shifted.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [2, 3, 4, 5])
    }
    let sub = b - a
    sub.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [4, 4, 4, 4])
    }
    let negated = -a
    negated.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [-1, -2, -3, -4])
    }
    let divided = b / a
    divided.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 5)
    }
    let remainder = MLTensor([Float(5), 6]) % MLTensor([Float(2), 4])
    remainder.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    var acc = a
    acc += b
    acc.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [6, 8, 10, 12])
    }
    acc -= b
    acc *= b
    acc /= b
    acc %= b
    let product = a.matmul(b)
    // [1 2; 3 4] x [5 6; 7 8] = [19 22; 43 50]
    product.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [19, 22, 43, 50])
    }
    let pointMax = pointwiseMax(a, b)
    pointMax.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [5, 6, 7, 8])
    }
    let pointMin = pointwiseMin(a, Float(2))
    pointMin.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 2, 2, 2])
    }
    let scalarMax = pointwiseMax(Float(3), a)
    scalarMax.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [3, 3, 3, 4])
    }
    _ = pointwiseMin(a, b)
    _ = pointwiseMin(Float(1), a)
}

func testTensorReductionsAndElementwise() {
    let a = MLTensor(shape: [2, 2], scalars: [Float(1), 2, 3, 4])
    a.sum().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 10)
    }
    a.product().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 24)
    }
    a.mean().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 2.5)
    }
    a.max().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 4)
    }
    a.min().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    a.sum(alongAxes: 1).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [3, 7])
    }
    a.mean(alongAxes: [0]).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [2, 3])
    }
    a.max(alongAxes: 0).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [3, 4])
    }
    a.min(alongAxes: 1).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 3])
    }
    a.argmax().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 3)
    }
    a.argmin().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 0)
    }
    let softmax = MLTensor([Float(1), 1]).softmax()
    softmax.withUnsafeBufferPointer { buffer in
        precondition(abs(buffer[0] - 0.5) < 0.0001)
    }
    a.abs().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    a.squared().withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 4, 9, 16])
    }
    a.reciprocal().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    MLTensor([Float(4)]).squareRoot().withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 2)
    }
    MLTensor([Float(4)]).rsqrt().withUnsafeBufferPointer { buffer in
        precondition(abs(buffer[0] - 0.5) < 0.0001)
    }
    MLTensor([Float(-2), 0, 3]).sign().withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [-1, 0, 1])
    }
    MLTensor([Float(1)]).exp().withUnsafeBufferPointer { buffer in
        precondition(abs(buffer[0] - Foundation.exp(Float(1))) < 0.0001)
    }
    _ = a.exp2()
    _ = a.log()
    _ = a.sin()
    _ = a.cos()
    _ = a.tan()
    _ = a.asin()
    _ = a.acos()
    _ = a.atan()
    _ = a.sinh()
    _ = a.cosh()
    _ = a.tanh()
    _ = a.asinh()
    _ = a.acosh()
    _ = a.atanh()
    _ = a.ceil()
    _ = a.floor()
    _ = a.round()
    _ = a.pow(2 as Float)
    _ = a.pow(MLTensor(repeating: 2, shape: [2, 2]))
    _ = a.clamped(to: 0...3)
    _ = a.clamped(to: 2...)
    _ = a.clamped(to: ...2)
    _ = a.cast(to: Int32.self)
    _ = a.cast(like: MLTensor([Int32(1)]))
    _ = a.cumulativeSum(alongAxis: 1)
    _ = a.cumulativeProduct(alongAxis: 0)
    _ = a.all()
    _ = a.any()
    _ = a.all(alongAxes: 0)
    _ = a.any(alongAxes: 1)
    _ = a.product(alongAxes: 0)
    _ = a.product(alongAxes: [0])
    _ = a.all(alongAxes: [0])
    _ = a.any(alongAxes: [1])
    _ = a.sum(alongAxes: [1])
    _ = a.max(alongAxes: [0])
    _ = a.min(alongAxes: [1])
    _ = a.argmax(alongAxis: 1)
    _ = a.argmin(alongAxis: 0)
    _ = a.argsort()
    let top = a.flattened().topK(2)
    top.values.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 4)
    }
}

func testTensorShapeOpsAndEnums() {
    let a = MLTensor(shape: [2, 2], scalars: [Float(1), 2, 3, 4])
    let transposed = a.transposed()
    transposed.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 3, 2, 4])
    }
    _ = a.transposed(permutation: 1, 0)
    _ = a.transposed(permutation: [1, 0])
    let expanded = a.expandingShape(at: 0)
    precondition(expanded.shape == [1, 2, 2])
    _ = a.expandingShape(at: [0])
    precondition(expanded.squeezingShape().shape == [2, 2])
    _ = expanded.squeezingShape(at: 0)
    _ = expanded.squeezingShape(at: [0])
    let stacked = MLTensor(stacking: [a, a], alongAxis: 0)
    precondition(stacked.shape == [2, 2, 2])
    let concat = a.concatenated(with: a, alongAxis: 0)
    precondition(concat.shape == [4, 2])
    precondition(a.unstacked().count == 2)
    precondition(a.split(count: 2, alongAxis: 0).count == 2)
    precondition(a.split(sizes: [1, 1], alongAxis: 0).count == 2)
    let tiled = a.tiled(multiples: [2, 1])
    precondition(tiled.shape == [4, 2])
    _ = a.reversed(alongAxes: 0)
    _ = a.reversed(alongAxes: [1])
    let padded = a.padded(forSizes: [(1, 1), (0, 0)], with: 0)
    precondition(padded.shape == [4, 2])
    _ = a.padded(forSizes: [(0, 0), (1, 1)], mode: .constant(0))
    _ = a.padded(forSizes: [(1, 0), (0, 0)], mode: .reflection)
    _ = a.padded(forSizes: [(1, 0), (0, 0)], mode: .symmetric)
    let nearest = a.resized(to: (newHeight: 4, newWidth: 2), method: .nearestNeighbor)
    precondition(nearest.shape == [4, 2])
    _ = a.resized(to: (newHeight: 2, newWidth: 2), method: .bilinear(alignCorners: false))
    let gathered = a.gathering(atIndices: MLTensor([Int32(1)]), alongAxis: 0)
    precondition(gathered.shape[0] == 1)
    _ = a.gathering(atIndices: MLTensor([Int32(0)]))
    let mask = MLTensor(shape: [2, 2], scalars: [Float(1), 0, 1, 0])
    _ = a.replacing(with: bZero(), where: mask)
    _ = a.replacing(with: Float(9), where: mask)
    _ = a.replacing(with: MLTensor([Float(9), 9]), atIndices: MLTensor([Int32(0)]), alongAxis: 0)
    _ = a.replacing(atIndices: MLTensor([Int32(1)]), with: Float(0), alongAxis: 0)
    _ = a.bandPart(lowerBandCount: 0, upperBandCount: 0)
    let ones = MLTensor(ones: [2], scalarType: Float.self)
    ones.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 1])
    }
    _ = MLTensor(ones: [2], scalarType: Int32.self)
    _ = MLTensor(repeating: Int32(3), shape: [2], scalarType: Int32.self)
    _ = MLTensor(Float(2), scalarType: Float.self)
    _ = MLTensor([Float(1), 2], scalarType: Float.self)
    _ = MLTensor(shape: [2], scalars: [Int32(1), 2], scalarType: Int32.self)
    _ = MLTensor(MLShapedArray<Float>(scalars: [1, 2], shape: [2]))
    _ = MLTensor([a.flattened(), a.flattened()], alongAxis: 0)
    let linspace = MLTensor(linearSpaceFrom: Float(0), through: 2, count: 3)
    linspace.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [0, 1, 2])
    }
    _ = MLTensor(linearSpaceFrom: Float(0), through: 1, count: 2, scalarType: Float.self)
    let ranged = MLTensor(rangeFrom: Float(0), to: 3, by: 1)
    ranged.withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [0, 1, 2])
    }
    _ = MLTensor(rangeFrom: Float(0), to: 2, by: 1, scalarType: Float.self)
    _ = MLTensor(randomNormal: [2], seed: 1, scalarType: Float.self)
    _ = MLTensor(randomUniform: [2], in: Float(0)..<1, seed: 1, scalarType: Float.self)
    _ = MLTensor(randomUniform: [2], in: Int32(0)...3, seed: 1, scalarType: Int32.self)
    let scalar: MLTensor = 1.5
    precondition(scalar.isScalar)
    let intLiteral: MLTensor = 3
    _ = intLiteral
    let boolLiteral: MLTensor = true
    _ = boolLiteral
    let arrayLiteral: MLTensor = [MLTensor([Float(1)]), MLTensor([Float(2)])]
    precondition(arrayLiteral.rank >= 1)
    let bytes = UnsafeMutablePointer<Float>.allocate(capacity: 2)
    bytes.initialize(repeating: 3, count: 2)
    let copied = MLTensor(
        bytesNoCopy: UnsafeRawBufferPointer(start: UnsafeRawPointer(bytes), count: 8),
        shape: [2],
        scalarType: Float.self,
        deallocator: .none
    )
    copied.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 3)
    }
    bytes.deinitialize(count: 2)
    bytes.deallocate()
    let uninit = MLTensor(
        unsafeUninitializedShape: [2],
        scalarType: Float.self,
        initializingWith: { buffer in
            buffer.bindMemory(to: Float.self).initialize(repeating: 4)
        }
    )
    uninit.withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 4)
    }
    precondition(MLTensor.PaddingMode.reflection == .reflection)
    precondition(MLTensor.PaddingMode.symmetric != .constant(0))
    _ = MLTensor.PaddingMode.constant(1).hashValue
    var hasher = Hasher()
    MLTensor.PaddingMode.reflection.hash(into: &hasher)
    _ = MLTensor.PaddingMode.reflection.description
    _ = MLTensor.PaddingMode.symmetric.description
    _ = MLTensor.PaddingMode.constant(1).description
    precondition(MLTensor.ResizeMethod.nearestNeighbor == .nearestNeighbor)
    precondition(MLTensor.ResizeMethod.bilinear(alignCorners: true) != .nearestNeighbor)
    _ = MLTensor.ResizeMethod.nearestNeighbor.hashValue
    MLTensor.ResizeMethod.nearestNeighbor.hash(into: &hasher)
    _ = MLTensor.ResizeMethod.nearestNeighbor.description
    _ = MLTensor.ResizeMethod.bilinear(alignCorners: false).description
    _ = CoreMLTensorRange.range(0..<1)
    _ = CoreMLTensorRange.closedRange(0...0)
    _ = CoreMLTensorRange.partialRangeFrom(0...)
    _ = CoreMLTensorRange.partialRangeUpTo(..<1)
    _ = CoreMLTensorRange.partialRangeUpTo(...0)
    _ = CoreMLTensorRange.index(0)
    _ = CoreMLTensorRange.fillAll
    _ = CoreMLTensorRange.newAxis
    _ = CoreMLTensorRange.squeezeAxis
    let sliced = a[CoreMLTensorRange.index(0)]
    precondition(sliced.rank == 1)
    _ = a[...]
    _ = a.cpuShapedArray(of: Float.self)
}

private func bZero() -> MLTensor {
    MLTensor(zeros: [2, 2], scalarType: Float.self)
}

func testTensorComparisonsAndBitwise() {
    let a = MLTensor([Float(1), 2, 3])
    let b = MLTensor([Float(1), 0, 4])
    (a .== b).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 0, 0])
    }
    (a .!= Float(2)).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [1, 0, 1])
    }
    (a .< b).withUnsafeBufferPointer { buffer in
        precondition(buffer[2] == 1)
    }
    (a .> Float(1)).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [0, 1, 1])
    }
    (a .<= b).withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    (a .>= Float(3)).withUnsafeBufferPointer { buffer in
        precondition(Array(buffer) == [0, 0, 1])
    }
    _ = a .== Float(1)
    _ = a .!= b
    _ = a .< Float(2)
    _ = a .> b
    _ = a .<= Float(2)
    _ = a .>= b
    let bits = MLTensor([Int32(1), 3])
    (bits .& bits).withUnsafeBufferPointer { buffer in
        precondition(buffer[0] == 1)
    }
    _ = bits .| bits
    _ = bits .^ bits
    _ = (.!)(a)
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


func testUpdateContextFailClosedModel() {
    let context = MLUpdateContext.linuxFailClosedContext(
        event: .epochEnd,
        metrics: [.lossValue: 0.25],
        parameters: [.epochs: 2]
    )
    precondition(context.event == .epochEnd)
    precondition((context.metrics[.lossValue] as? Double) == 0.25)
    precondition((context.parameters[.epochs] as? Int) == 2)
    _ = context.task.taskIdentifier
    precondition(context.task.state == .failed)
    let writable: any MLModel & MLWritable = context.model
    coremlRequireThrows(.io) {
        try writable.write(to: URL(fileURLWithPath: "/tmp/updated.mlmodelc"))
    }
}

func testModelCollectionFailsClosed() {
    let beginOnce = DispatchSemaphore(value: 0)
    let progress = MLModelCollection.beginAccessing(identifier: "bundle") { collection, error in
        precondition(collection == nil)
        coremlRequireError(error!, .modelCollection)
        beginOnce.signal()
    }
    _ = progress
    precondition(beginOnce.wait(timeout: .now() + 5) == .success)
    let resultOnce = DispatchSemaphore(value: 0)
    let resultProgress = MLModelCollection.beginAccessing(identifier: "bundle") { (result: Result<MLModelCollection, any Error>) in
        if case .failure(let error) = result {
            coremlRequireError(error, .modelCollection)
        } else {
            fatalError("collection begin must fail closed")
        }
        resultOnce.signal()
    }
    _ = resultProgress
    precondition(resultOnce.wait(timeout: .now() + 5) == .success)
    let delivered = DispatchSemaphore(value: 0)
    MLModelCollection.endAccessing(identifier: "bundle") { error in
        coremlRequireError(error!, .modelCollection)
        delivered.signal()
    }
    precondition(delivered.wait(timeout: .now() + 5) == .success)
    let endOnce = DispatchSemaphore(value: 0)
    MLModelCollection.endAccessing(identifier: "bundle") { (result: Result<Void, any Error>) in
        if case .failure(let error) = result {
            coremlRequireError(error, .modelCollection)
        } else {
            fatalError("collection end Result must fail closed")
        }
        endOnce.signal()
    }
    precondition(endOnce.wait(timeout: .now() + 5) == .success)
    let entry = MLModelCollectionEntry(
        modelIdentifier: "m",
        modelURL: URL(fileURLWithPath: "/tmp/x.mlmodelc")
    )
    precondition(entry.modelIdentifier == "m")
    precondition(entry.isEqual(entry))
}


func testMultiArrayCopyDataAndTranspose() {
    let source = try! MLMultiArray(shape: [2, 2], dataType: .float32)
    source[0] = 1
    source[1] = 2
    source[2] = 3
    source[3] = 4
    let copied = source.copy() as! MLMultiArray
    precondition(copied !== source)
    precondition(copied[3].floatValue == 4)
    copied[0] = 9
    precondition(source[0].floatValue == 1)
    let data = source.data
    precondition(data.count >= 16)
    let fromData = try! MLMultiArray(data: data, shape: [2, 2], dataType: .float32)
    precondition(fromData[1].floatValue == 2)
    let transposed = try! source.transposed()
    precondition(transposed.shape.map(\.intValue) == [2, 2])
    precondition(transposed[[NSNumber(value: 0), NSNumber(value: 1)]].floatValue == 3)
    let int8 = try! MLMultiArray(shape: [2], dataType: .int8)
    int8[0] = 7
    precondition(int8[0].int8Value == 7)
    let float16 = try! MLMultiArray(shape: [2], dataType: .float16)
    float16[0] = 1.5
    precondition(abs(float16[0].floatValue - 1.5) < 0.01)
    let doubles = try! MLMultiArray(shape: [1], dataType: .double)
    doubles[0] = 2.5
    precondition(doubles.dataType == .double)
    let witness: any Foundation.NSCopying = source
    _ = witness
}


func testShapedArrayEquatableCollectionOps() {
    let array = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    let first = array[0]
    let second = array[1]
    precondition(array.contains(first))
    precondition(array.firstIndex(of: first) == 0)
    precondition(array.elementsEqual([first, second]))
    precondition(array.starts(with: [first]))
    precondition(array.contains([first]))
    let slice = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    precondition(slice.contains(slice[0]))
    precondition(slice.firstIndex(of: slice[0]) == 0)
    precondition(slice.elementsEqual([slice[0], slice[1]]))
    precondition(slice.starts(with: [slice[0]]))
    precondition(slice.contains([slice[0]]))
    precondition(array.difference(from: array).isEmpty)
    precondition(slice.difference(from: slice).isEmpty)
}

func testShapedArrayProtocolWitnesses() {
    func inspect<T: MLShapedArrayProtocol>(_ value: T, expected: [T.Scalar], shape: [Int])
    where T.Scalar: Equatable {
        precondition(value.shape == shape)
        precondition(value.strides == [1] || value.strides.count == shape.count)
        precondition(value.scalarCount == expected.count)
        precondition(value.scalars == expected)
        precondition(value.isScalar == shape.isEmpty)
        if shape.isEmpty {
            precondition(value.scalar == expected.first)
        } else {
            precondition(value.scalar == nil)
        }
    }
    inspect(MLShapedArray<Float>(scalars: [1, 2], shape: [2]), expected: [1, 2], shape: [2])
    inspect(MLShapedArraySlice<Float>(scalars: [1, 2], shape: [2]), expected: [1, 2], shape: [2])
    inspect(MLShapedArray<Float>(scalar: 3), expected: [3], shape: [])
}

func testShapedArraySequenceHelpers() {
    let array = MLShapedArray<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    precondition(array.allSatisfy { $0.scalarCount == 2 })
    precondition(array.contains(where: { $0.scalars.first == 1 }))
    precondition(array.first(where: { $0.scalars.first == 3 })?.scalars == [3, 4])
    precondition(array.filter { $0.scalars.first == 1 }.count == 1)
    precondition(array.reduce(0) { $0 + ($1.scalars.first ?? 0) } == 4)
    var walked = 0
    array.forEach { sum in walked += Int(sum.scalars.first ?? 0) }
    precondition(walked == 4)
    precondition(array.compactMap { $0.scalars.first }.count == 2)
    precondition(Array(array.enumerated()).count == 2)
    precondition(array.underestimatedCount >= 2)
    precondition(array.dropLast(1).count == 1)
    precondition(array.suffix(1).count == 1)
    precondition(array.lastIndex(of: array[1]) == 1)
    let slice = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4], shape: [2, 2])
    precondition(slice.allSatisfy { $0.scalarCount == 2 })
    precondition(slice.contains(where: { $0.scalars.first == 1 }))
    precondition(slice.filter { $0.scalars.first == 1 }.count == 1)
    precondition(slice.reduce(0) { $0 + ($1.scalars.first ?? 0) } == 4)
}

func testShapedArrayAdvancedReadAlgorithms() {
    let array = MLShapedArray<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [3, 2])
    let rows = [array[0], array[1], array[2]]
    precondition(array.elementsEqual(rows, by: ==))
    precondition(array.starts(with: rows.prefix(2), by: ==))
    precondition(array.lexicographicallyPrecedes(Array(rows.reversed()), by: { $0.scalars.lexicographicallyPrecedes($1.scalars) }))
    precondition(array.firstIndex(where: { $0.scalars.first == 3 }) == 1)
    precondition(array.last(where: { $0.scalars.first! < 5 }) == rows[1])
    precondition(array.lastIndex(where: { $0.scalars.first! < 5 }) == 1)
    precondition(array.count(where: { $0.scalarCount == 2 }) == 3)
    precondition(array.max(by: { $0.scalars.first! < $1.scalars.first! }) == rows[2])
    precondition(array.min(by: { $0.scalars.first! < $1.scalars.first! }) == rows[0])
    precondition(array.sorted(by: { $0.scalars.first! > $1.scalars.first! }) == Array(rows.reversed()))
    precondition(array.drop(while: { $0.scalars.first! < 3 }).count == 2)
    precondition(array.prefix(while: { $0.scalars.first! < 5 }).count == 2)
    precondition(array.prefix(upTo: 2).count == 2)
    precondition(array.prefix(through: 1).count == 2)
    precondition(array.suffix(from: 1).count == 2)
    precondition(array.index(0, offsetBy: 2, limitedBy: 2) == 2)
    precondition(array.firstIndex(of: rows[1]) == 1)
    precondition(!array.indices(of: rows[1]).isEmpty)
    precondition(!array.indices(where: { $0.scalars.first! >= 3 }).isEmpty)
    precondition(array.difference(from: rows, by: ==).isEmpty)
    let total = array.reduce(into: Float(0)) { $0 += $1.scalars.reduce(0, +) }
    precondition(total == 21)
    precondition(array.flatMap { $0.scalars }.count == 6)
    precondition(Array(array.lazy).count == 3)
    _ = array.withContiguousStorageIfAvailable { $0.count }

    let slice = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [3, 2])
    let sliceRows = [slice[0], slice[1], slice[2]]
    precondition(slice.elementsEqual(sliceRows, by: ==))
    precondition(slice.starts(with: sliceRows.prefix(2), by: ==))
    _ = slice.lexicographicallyPrecedes(Array(sliceRows.reversed()), by: { $0.scalars.lexicographicallyPrecedes($1.scalars) })
    precondition(slice.firstIndex(where: { $0.scalars.first == 3 }) == 1)
    _ = slice.last(where: { $0.scalars.first! < 5 })
    precondition(slice.lastIndex(where: { $0.scalars.first! < 5 }) == 1)
    precondition(slice.count(where: { $0.scalarCount == 2 }) == 3)
    _ = slice.max(by: { $0.scalars.first! < $1.scalars.first! })
    _ = slice.min(by: { $0.scalars.first! < $1.scalars.first! })
    _ = slice.sorted(by: { $0.scalars.first! > $1.scalars.first! })
    _ = slice.drop(while: { $0.scalars.first! < 3 })
    _ = slice.prefix(while: { $0.scalars.first! < 5 })
    _ = slice.prefix(upTo: 2)
    precondition(slice.prefix(through: 1).count == 2)
    precondition(slice.suffix(from: 1).count == 2)
    _ = slice.index(0, offsetBy: 2, limitedBy: 2)
    _ = slice.indices(of: sliceRows[1])
    _ = slice.indices(where: { $0.scalars.first! >= 3 })
    precondition(slice.difference(from: sliceRows, by: ==).isEmpty)
    _ = slice.reduce(into: Float(0)) { $0 += $1.scalars.reduce(0, +) }
    _ = slice.flatMap { $0.scalars }
    _ = Array(slice.lazy)
    _ = slice.withContiguousStorageIfAvailable { $0.count }
    _ = slice.randomElement()
    _ = slice.shuffled()
    _ = array.randomElement()
    _ = array.shuffled()
    _ = array.split(maxSplits: 1, omittingEmptySubsequences: true) { $0.scalars.first == 3 }
    _ = slice.split(maxSplits: 1, omittingEmptySubsequences: true) { $0.scalars.first == 3 }
    var sliceIndex = slice.startIndex
    _ = slice.formIndex(&sliceIndex, offsetBy: 1, limitedBy: slice.endIndex)
    slice.formIndex(&sliceIndex, offsetBy: -1)
    var generator = SystemRandomNumberGenerator()
    _ = array.randomElement(using: &generator)
    _ = slice.randomElement(using: &generator)
    _ = array.shuffled(using: &generator)
    _ = slice.shuffled(using: &generator)
}

func testShapedArrayAdvancedMutationAlgorithms() {
    var array = MLShapedArray<Float>(scalars: [3, 4, 1, 2, 5, 6], shape: [3, 2])
    array.swapAt(0, 1)
    precondition(array[0].scalars == [1, 2])
    array.reverse()
    precondition(array[0].scalars == [5, 6])
    array.sort { $0.scalars.first! < $1.scalars.first! }
    precondition(array[0].scalars == [1, 2])
    let pivot = array.partition { $0.scalars.first! >= 3 }
    precondition(pivot == 1)
    var index = array.startIndex
    precondition(array.formIndex(&index, offsetBy: 1, limitedBy: array.endIndex))
    precondition(index == 1)
    array.formIndex(&index, offsetBy: -1)
    precondition(index == 0)
    precondition(array != MLShapedArray<Float>(repeating: 0, shape: [3, 2]))

    var slice = MLShapedArraySlice<Float>(scalars: [3, 4, 1, 2, 5, 6], shape: [3, 2])
    slice.swapAt(0, 1)
    slice.reverse()
    slice.sort { $0.scalars.first! < $1.scalars.first! }
    precondition(slice.partition { $0.scalars.first! >= 3 } == 1)
    precondition(slice.popLast()?.scalarCount == 2)
    slice.removeLast(1)
    precondition(slice.count == 1)
    precondition(slice.popFirst()?.scalarCount == 2)
    precondition(slice.isEmpty)
    var removals = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [3, 2])
    removals.removeLast()
    removals.removeFirst()
    removals = MLShapedArraySlice<Float>(scalars: [1, 2, 3, 4, 5, 6], shape: [3, 2])
    removals.removeFirst(1)
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

enum CoreMLRuntime {
    static func main() {
        testEnumAndConstantRawValues()
        testModelErrorValueSemantics()
        testMultiArrayInitAndSubscript()
        testMultiArrayConcatAndTransfer()
        testMultiArrayPointerViewsAndDeallocator()
        testMultiArrayCoderReturnsNil()
        testShapedArrayScalarsAndTransforms()
        testShapedArrayCollectionTraversal()
        testShapedArrayConcatConvertAndSlice()
        testShapedArrayJSONCodingAndRanges()
        testFeatureValueScalarsAndEquality()
        testFeatureValueSequenceDictionaryAndShapedArray()
        testFeatureValueImageAtURLFailsClosed()
        testSequenceConstruction()
        testSendableFeatureValueRoundTrip()
        testDictionaryFeatureProvider()
        testArrayBatchProvider()
        testConstraintsAndFeatureDescription()
        testModelDescriptionMetadata()
        testDescriptionCodersReturnNil()
        testModelConfigurationDefaultsAndCopy()
        testPredictionOptionsAndOptimizationHints()
        testParameterMetricAndMetadataKeys()
        testComputeDevicesAreCPUOnly()
        testMissingPathThrowsIO()
        testCompileIdentityAndPrediction()
        testDictVectorizerPrediction()
        testPipelinePrediction()
        testNeuralNetworkFailsClosed()
        testParameterValueFromConfiguration()
        testCompletionDeliveryIsOffCaller()
        testAsyncLoadCompileAndStructureFailClosed()
        testUpdateTaskFailsClosed()
        testCustomLayerFailsClosed()
        testTaskResumeAndCancel()
        testEmptyStateFailsClosed()
        testModelStructureConstruction()
        testComputePlanDeviceUsageAndCost()
        testTensorShapeRankAndFlatten()
        testTensorConcatenatingAndInitializers()
        testTensorArithmeticAndMatmul()
        testTensorReductionsAndElementwise()
        testTensorShapeOpsAndEnums()
        testTensorComparisonsAndBitwise()
        testGLMLinearPrediction()
        testCompiledPlistMetadataLoad()
        testUpdateContextFailClosedModel()
        testModelCollectionFailsClosed()
        testMultiArrayCopyDataAndTranspose()
        testShapedArrayEquatableCollectionOps()
        testShapedArrayProtocolWitnesses()
        testShapedArraySequenceHelpers()
        testShapedArrayAdvancedReadAlgorithms()
        testShapedArrayAdvancedMutationAlgorithms()
        testUpdateProgressEventSetAlgebra()
        print("COREML_AGENT_RUNTIME_OK")
    }
}

CoreMLRuntime.main()

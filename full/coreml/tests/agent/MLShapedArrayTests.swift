import CoreML
import Foundation

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

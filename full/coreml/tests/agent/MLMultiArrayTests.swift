import CoreML
import Foundation

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

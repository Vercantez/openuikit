import CoreML
import Foundation

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

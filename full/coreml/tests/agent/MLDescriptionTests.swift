import CoreML
import Foundation

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

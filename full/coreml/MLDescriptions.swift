import Foundation

public typealias OSType = UInt32

open class MLDictionaryConstraint: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var keyType: MLFeatureType

    init(keyType: MLFeatureType) {
        self.keyType = keyType
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLImageSize: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var pixelsWide: Int
    public private(set) var pixelsHigh: Int

    init(pixelsWide: Int, pixelsHigh: Int) {
        self.pixelsWide = pixelsWide
        self.pixelsHigh = pixelsHigh
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLImageSizeConstraint: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var type: MLImageSizeConstraintType
    public private(set) var enumeratedImageSizes: [MLImageSize]
    public private(set) var pixelsWideRange: NSRange
    public private(set) var pixelsHighRange: NSRange

    init(
        type: MLImageSizeConstraintType,
        enumeratedImageSizes: [MLImageSize] = [],
        pixelsWideRange: NSRange = NSRange(location: 0, length: 0),
        pixelsHighRange: NSRange = NSRange(location: 0, length: 0)
    ) {
        self.type = type
        self.enumeratedImageSizes = enumeratedImageSizes
        self.pixelsWideRange = pixelsWideRange
        self.pixelsHighRange = pixelsHighRange
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLImageConstraint: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var pixelsWide: Int
    public private(set) var pixelsHigh: Int
    public private(set) var pixelFormatType: OSType
    public private(set) var sizeConstraint: MLImageSizeConstraint

    init(
        pixelsWide: Int,
        pixelsHigh: Int,
        pixelFormatType: OSType,
        sizeConstraint: MLImageSizeConstraint
    ) {
        self.pixelsWide = pixelsWide
        self.pixelsHigh = pixelsHigh
        self.pixelFormatType = pixelFormatType
        self.sizeConstraint = sizeConstraint
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLMultiArrayShapeConstraint: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var type: MLMultiArrayShapeConstraintType
    public private(set) var enumeratedShapes: [[NSNumber]]
    public private(set) var sizeRangeForDimension: [NSValue]

    init(
        type: MLMultiArrayShapeConstraintType,
        enumeratedShapes: [[NSNumber]] = [],
        sizeRangeForDimension: [NSValue] = []
    ) {
        self.type = type
        self.enumeratedShapes = enumeratedShapes
        self.sizeRangeForDimension = sizeRangeForDimension
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLMultiArrayConstraint: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var shape: [NSNumber]
    public private(set) var dataType: MLMultiArrayDataType
    public private(set) var shapeConstraint: MLMultiArrayShapeConstraint

    init(shape: [NSNumber], dataType: MLMultiArrayDataType, shapeConstraint: MLMultiArrayShapeConstraint) {
        self.shape = shape
        self.dataType = dataType
        self.shapeConstraint = shapeConstraint
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLSequenceConstraint: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var valueDescription: MLFeatureDescription
    public private(set) var countRange: NSRange

    init(valueDescription: MLFeatureDescription, countRange: NSRange) {
        self.valueDescription = valueDescription
        self.countRange = countRange
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLStateConstraint: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var dataType: MLMultiArrayDataType
    public private(set) var bufferShape: [Int]

    init(dataType: MLMultiArrayDataType, bufferShape: [Int]) {
        self.dataType = dataType
        self.bufferShape = bufferShape
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLNumericConstraint: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var minNumber: NSNumber
    public private(set) var maxNumber: NSNumber
    public private(set) var enumeratedNumbers: Set<NSNumber>?

    init(minNumber: NSNumber, maxNumber: NSNumber, enumeratedNumbers: Set<NSNumber>? = nil) {
        self.minNumber = minNumber
        self.maxNumber = maxNumber
        self.enumeratedNumbers = enumeratedNumbers
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLParameterDescription: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var key: MLParameterKey
    public private(set) var defaultValue: Any
    public private(set) var numericConstraint: MLNumericConstraint?

    init(key: MLParameterKey, defaultValue: Any, numericConstraint: MLNumericConstraint? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.numericConstraint = numericConstraint
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

open class MLFeatureDescription: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public private(set) var name: String
    public private(set) var type: MLFeatureType
    public private(set) var isOptional: Bool
    public private(set) var dictionaryConstraint: MLDictionaryConstraint?
    public private(set) var imageConstraint: MLImageConstraint?
    public private(set) var multiArrayConstraint: MLMultiArrayConstraint?
    public private(set) var sequenceConstraint: MLSequenceConstraint?
    public private(set) var stateConstraint: MLStateConstraint?

    init(
        name: String,
        type: MLFeatureType,
        isOptional: Bool = false,
        dictionaryConstraint: MLDictionaryConstraint? = nil,
        imageConstraint: MLImageConstraint? = nil,
        multiArrayConstraint: MLMultiArrayConstraint? = nil,
        sequenceConstraint: MLSequenceConstraint? = nil,
        stateConstraint: MLStateConstraint? = nil
    ) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.dictionaryConstraint = dictionaryConstraint
        self.imageConstraint = imageConstraint
        self.multiArrayConstraint = multiArrayConstraint
        self.sequenceConstraint = sequenceConstraint
        self.stateConstraint = stateConstraint
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}

    open func isAllowedValue(_ value: MLFeatureValue) -> Bool {
        if value.isUndefined {
            return isOptional
        }
        guard value.type == type else { return false }
        if let constraint = multiArrayConstraint, let array = value.multiArrayValue {
            if constraint.dataType != array.dataType { return false }
            if !constraint.shape.isEmpty && constraint.shape.map(\.intValue) != array.shape.map(\.intValue) {
                return constraint.shapeConstraint.type != .unspecified
            }
        }
        return true
    }
}

open class MLModelDescription: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public private(set) var inputDescriptionsByName: [String: MLFeatureDescription]
    public private(set) var outputDescriptionsByName: [String: MLFeatureDescription]
    public private(set) var stateDescriptionsByName: [String: MLFeatureDescription]
    public private(set) var trainingInputDescriptionsByName: [String: MLFeatureDescription]
    public private(set) var predictedFeatureName: String?
    public private(set) var predictedProbabilitiesName: String?
    public private(set) var metadata: [MLModelMetadataKey: Any]
    public private(set) var classLabels: [Any]?
    public private(set) var isUpdatable: Bool
    public private(set) var parameterDescriptionsByKey: [MLParameterKey: MLParameterDescription]

    init(
        inputDescriptionsByName: [String: MLFeatureDescription] = [:],
        outputDescriptionsByName: [String: MLFeatureDescription] = [:],
        stateDescriptionsByName: [String: MLFeatureDescription] = [:],
        trainingInputDescriptionsByName: [String: MLFeatureDescription] = [:],
        predictedFeatureName: String? = nil,
        predictedProbabilitiesName: String? = nil,
        metadata: [MLModelMetadataKey: Any] = [:],
        classLabels: [Any]? = nil,
        isUpdatable: Bool = false,
        parameterDescriptionsByKey: [MLParameterKey: MLParameterDescription] = [:]
    ) {
        self.inputDescriptionsByName = inputDescriptionsByName
        self.outputDescriptionsByName = outputDescriptionsByName
        self.stateDescriptionsByName = stateDescriptionsByName
        self.trainingInputDescriptionsByName = trainingInputDescriptionsByName
        self.predictedFeatureName = predictedFeatureName
        self.predictedProbabilitiesName = predictedProbabilitiesName
        self.metadata = metadata
        self.classLabels = classLabels
        self.isUpdatable = isUpdatable
        self.parameterDescriptionsByKey = parameterDescriptionsByKey
        super.init()
    }

    public required init?(coder: NSCoder) { nil }
    open func encode(with coder: NSCoder) {}
}

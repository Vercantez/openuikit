import Foundation

// MARK: - Protobuf (Core ML Model.proto, coremltools public spec)

enum CoreMLWire {
    static func varint(_ value: UInt64) -> [UInt8] {
        var current = value
        var bytes: [UInt8] = []
        while current >= 0x80 {
            bytes.append(UInt8(current & 0x7F) | 0x80)
            current >>= 7
        }
        bytes.append(UInt8(current))
        return bytes
    }

    static func zigzag(_ value: Int64) -> UInt64 {
        UInt64(bitPattern: (value << 1) ^ (value >> 63))
    }

    static func key(_ field: UInt64, wire: UInt64) -> [UInt8] {
        varint((field << 3) | wire)
    }

    static func length(_ bytes: [UInt8]) -> [UInt8] {
        varint(UInt64(bytes.count)) + bytes
    }

    static func message(_ field: UInt64, _ bytes: [UInt8]) -> [UInt8] {
        key(field, wire: 2) + length(bytes)
    }

    static func string(_ field: UInt64, _ value: String) -> [UInt8] {
        message(field, Array(value.utf8))
    }

    static func int32(_ field: UInt64, _ value: Int32) -> [UInt8] {
        key(field, wire: 0) + varint(UInt64(UInt32(bitPattern: value)))
    }

    static func int64(_ field: UInt64, _ value: Int64) -> [UInt8] {
        key(field, wire: 0) + varint(UInt64(bitPattern: value))
    }

    static func uint64(_ field: UInt64, _ value: UInt64) -> [UInt8] {
        key(field, wire: 0) + varint(value)
    }

    static func float64(_ field: UInt64, _ value: Double) -> [UInt8] {
        var bits = value.bitPattern.littleEndian
        let bytes = withUnsafeBytes(of: &bits) { Array($0) }
        return key(field, wire: 1) + bytes
    }

    static func packedDoubles(_ field: UInt64, _ values: [Double]) -> [UInt8] {
        var payload: [UInt8] = []
        for value in values {
            var bits = value.bitPattern.littleEndian
            payload += withUnsafeBytes(of: &bits) { Array($0) }
        }
        return message(field, payload)
    }

    static func bool(_ field: UInt64, _ value: Bool) -> [UInt8] {
        value ? uint64(field, 1) : []
    }
}

struct CoreMLProtoReader {
    let bytes: [UInt8]
    var offset = 0

    init(_ data: Data) {
        self.bytes = Array(data)
    }

    init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    var isAtEnd: Bool { offset >= bytes.count }

    mutating func next() throws -> (field: UInt64, wire: UInt64, payload: [UInt8])? {
        guard !isAtEnd else { return nil }
        let key = try readVarint()
        let field = key >> 3
        let wire = key & 0x7
        switch wire {
        case 0:
            let value = try readVarint()
            return (field, wire, CoreMLWire.varint(value))
        case 1:
            let payload = try readBytes(8)
            return (field, wire, payload)
        case 2:
            let length = try readVarint()
            let payload = try readBytes(Int(length))
            return (field, wire, payload)
        case 5:
            let payload = try readBytes(4)
            return (field, wire, payload)
        default:
            throw coreMLError(.io, "Unsupported protobuf wire type \(wire).")
        }
    }

    mutating func readVarint() throws -> UInt64 {
        var result: UInt64 = 0
        var shift = 0
        while true {
            guard offset < bytes.count else {
                throw coreMLError(.io, "Truncated protobuf varint.")
            }
            let byte = bytes[offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte & 0x80 == 0 {
                return result
            }
            shift += 7
            if shift > 63 {
                throw coreMLError(.io, "Protobuf varint overflow.")
            }
        }
    }

    mutating func readBytes(_ count: Int) throws -> [UInt8] {
        guard count >= 0, offset + count <= bytes.count else {
            throw coreMLError(.io, "Truncated protobuf payload.")
        }
        let slice = Array(bytes[offset..<(offset + count)])
        offset += count
        return slice
    }

    static func string(_ payload: [UInt8]) -> String {
        String(decoding: payload, as: UTF8.self)
    }

    static func varint(_ payload: [UInt8]) -> UInt64 {
        var reader = CoreMLProtoReader(payload)
        return (try? reader.readVarint()) ?? 0
    }

    static func int32(_ payload: [UInt8]) -> Int32 {
        Int32(truncatingIfNeeded: varint(payload))
    }

    static func int64(_ payload: [UInt8]) -> Int64 {
        Int64(bitPattern: varint(payload))
    }

    static func float64(_ payload: [UInt8]) -> Double {
        guard payload.count >= 8 else { return 0 }
        let bits = payload.prefix(8).enumerated().reduce(UInt64(0)) { partial, item in
            partial | (UInt64(item.element) << (UInt64(item.offset) * 8))
        }
        return Double(bitPattern: bits)
    }

    static func packedFloat64(_ payload: [UInt8]) -> [Double] {
        stride(from: 0, to: payload.count, by: 8).map { offset in
            float64(Array(payload[offset..<min(offset + 8, payload.count)]))
        }
    }
}

// MARK: - Compiled program

enum CoreMLProgram {
    case identity
    case dictVectorizer(stringToIndex: [String], int64ToIndex: [Int64])
    case glmRegressor(weights: [[Double]], offset: [Double], transform: Int32)
    case pipeline([CoreMLCompiledModel])
    case customLayer
    case customModel
    case neuralNetwork
    case unsupported(field: UInt64)
}

struct CoreMLCompiledModel {
    var specificationVersion: Int32
    var isUpdatable: Bool
    var description: MLModelDescription
    var program: CoreMLProgram
    var specificationData: Data
}

enum CoreMLModelCodec {
    static func compile(contentsOf url: URL) throws -> URL {
        let spec = try load(contentsOf: url)
        let compiledURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathExtension("mlmodelc")
        try writeCompiledBundle(spec, to: compiledURL)
        return compiledURL
    }

    static func load(contentsOf url: URL) throws -> CoreMLCompiledModel {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        guard exists else {
            throw coreMLNoModelIO("missing model at \(url.path)")
        }
        if isDirectory.boolValue {
            return try loadCompiledDirectory(url)
        }
        let data = try Data(contentsOf: url)
        return try decodeModel(data)
    }

    static func writeCompiledBundle(_ spec: CoreMLCompiledModel, to url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let specificationURL = url.appendingPathComponent("model.specification")
        try spec.specificationData.write(to: specificationURL)
        let metadata = metadataJSON(from: spec)
        let metadataURL = url.appendingPathComponent("metadata.json")
        let json = try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: metadataURL)
        let plistURL = url.appendingPathComponent("metadata.plist")
        let plist = try PropertyListSerialization.data(fromPropertyList: metadata, format: .xml, options: 0)
        try plist.write(to: plistURL)
    }

    static func loadCompiledDirectory(_ url: URL) throws -> CoreMLCompiledModel {
        let specificationURL = url.appendingPathComponent("model.specification")
        if FileManager.default.fileExists(atPath: specificationURL.path) {
            let data = try Data(contentsOf: specificationURL)
            var spec = try decodeModel(data)
            if let object = try? loadMetadataObject(from: url) {
                spec.description = mergeMetadata(spec.description, json: object)
            }
            return spec
        }
        if let object = try? loadMetadataObject(from: url) {
            var spec = CoreMLCompiledModel(
                specificationVersion: 1,
                isUpdatable: object["isUpdatable"] as? Bool ?? false,
                description: description(fromMetadataJSON: object),
                program: .unsupported(field: 0),
                specificationData: Data()
            )
            spec.description = mergeMetadata(spec.description, json: object)
            return spec
        }
        throw coreMLNoModelIO("compiled model is missing model.specification and metadata.json")
    }

    private static func optionalFile(_ url: URL) -> URL? {
        FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func loadMetadataObject(from directory: URL) throws -> [String: Any] {
        if let plistURL = optionalFile(directory.appendingPathComponent("metadata.plist")),
           let data = try? Data(contentsOf: plistURL),
           let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            return object
        }
        if let jsonURL = optionalFile(directory.appendingPathComponent("metadata.json")),
           let json = try? Data(contentsOf: jsonURL),
           let object = try? JSONSerialization.jsonObject(with: json) as? [String: Any] {
            return object
        }
        throw coreMLNoModelIO("compiled model is missing metadata.plist and metadata.json")
    }

    static func decodeModel(_ data: Data) throws -> CoreMLCompiledModel {
        var reader = CoreMLProtoReader(data)
        var version: Int32 = 1
        var isUpdatable = false
        var description = MLModelDescription()
        var program = CoreMLProgram.unsupported(field: 0)
        var sawType = false
        while let field = try reader.next() {
            switch field.field {
            case 1:
                version = CoreMLProtoReader.int32(field.payload)
            case 2:
                description = try decodeDescription(field.payload)
            case 10:
                isUpdatable = CoreMLProtoReader.varint(field.payload) != 0
            case 200, 201:
                // PipelineClassifier / PipelineRegressor wrap Pipeline at field 1.
                program = try decodeWrappedPipeline(field.payload)
                sawType = true
            case 202:
                program = try decodePipeline(field.payload)
                sawType = true
            case 500, 303, 403:
                program = .neuralNetwork
                sawType = true
            case 502:
                program = .neuralNetwork
                sawType = true
            case 300:
                program = try decodeGLMRegressor(field.payload)
                sawType = true
            case 555:
                program = .customModel
                sawType = true
            case 603:
                program = try decodeDictVectorizer(field.payload)
                sawType = true
            case 900:
                program = .identity
                sawType = true
            default:
                if field.field >= 200 {
                    if !sawType {
                        program = .unsupported(field: field.field)
                        sawType = true
                    }
                }
            }
        }
        description.isUpdatable = isUpdatable
        return CoreMLCompiledModel(
            specificationVersion: version,
            isUpdatable: isUpdatable,
            description: description,
            program: program,
            specificationData: data
        )
    }

    static func decodeDescription(_ payload: [UInt8]) throws -> MLModelDescription {
        var reader = CoreMLProtoReader(payload)
        var inputs: [MLFeatureDescription] = []
        var outputs: [MLFeatureDescription] = []
        var states: [MLFeatureDescription] = []
        var training: [MLFeatureDescription] = []
        var predictedFeatureName: String?
        var predictedProbabilitiesName: String?
        var metadata: [MLModelMetadataKey: Any] = [:]
        var classLabels: [Any]?
        while let field = try reader.next() {
            switch field.field {
            case 1:
                inputs.append(try decodeFeatureDescription(field.payload))
            case 10:
                outputs.append(try decodeFeatureDescription(field.payload))
            case 11:
                predictedFeatureName = CoreMLProtoReader.string(field.payload)
            case 12:
                predictedProbabilitiesName = CoreMLProtoReader.string(field.payload)
            case 13:
                states.append(try decodeFeatureDescription(field.payload))
            case 50:
                training.append(try decodeFeatureDescription(field.payload))
            case 100:
                metadata = try decodeMetadata(field.payload)
            default:
                break
            }
        }
        if let labels = metadata[MLModelMetadataKey.creatorDefinedKey] as? [String: String],
           let encoded = labels["classLabels"] {
            classLabels = encoded.split(separator: "\u{1e}").map(String.init)
        }
        return MLModelDescription(
            inputDescriptionsByName: Dictionary(uniqueKeysWithValues: inputs.map { ($0.name, $0) }),
            outputDescriptionsByName: Dictionary(uniqueKeysWithValues: outputs.map { ($0.name, $0) }),
            stateDescriptionsByName: Dictionary(uniqueKeysWithValues: states.map { ($0.name, $0) }),
            trainingInputDescriptionsByName: Dictionary(uniqueKeysWithValues: training.map { ($0.name, $0) }),
            predictedFeatureName: predictedFeatureName,
            predictedProbabilitiesName: predictedProbabilitiesName,
            metadata: metadata,
            classLabels: classLabels,
            isUpdatable: false
        )
    }

    static func decodeFeatureDescription(_ payload: [UInt8]) throws -> MLFeatureDescription {
        var reader = CoreMLProtoReader(payload)
        var name = ""
        var type = MLFeatureType.invalid
        var isOptional = false
        var dictionaryConstraint: MLDictionaryConstraint?
        var imageConstraint: MLImageConstraint?
        var multiArrayConstraint: MLMultiArrayConstraint?
        var sequenceConstraint: MLSequenceConstraint?
        var stateConstraint: MLStateConstraint?
        while let field = try reader.next() {
            switch field.field {
            case 1:
                name = CoreMLProtoReader.string(field.payload)
            case 3:
                (type, isOptional, dictionaryConstraint, imageConstraint, multiArrayConstraint, sequenceConstraint, stateConstraint) =
                    try decodeFeatureType(field.payload)
            default:
                break
            }
        }
        return MLFeatureDescription(
            name: name,
            type: type,
            isOptional: isOptional,
            dictionaryConstraint: dictionaryConstraint,
            imageConstraint: imageConstraint,
            multiArrayConstraint: multiArrayConstraint,
            sequenceConstraint: sequenceConstraint,
            stateConstraint: stateConstraint
        )
    }

    static func decodeFeatureType(_ payload: [UInt8]) throws -> (
        MLFeatureType,
        Bool,
        MLDictionaryConstraint?,
        MLImageConstraint?,
        MLMultiArrayConstraint?,
        MLSequenceConstraint?,
        MLStateConstraint?
    ) {
        var reader = CoreMLProtoReader(payload)
        var type = MLFeatureType.invalid
        var isOptional = false
        var dictionaryConstraint: MLDictionaryConstraint?
        var imageConstraint: MLImageConstraint?
        var multiArrayConstraint: MLMultiArrayConstraint?
        var sequenceConstraint: MLSequenceConstraint?
        var stateConstraint: MLStateConstraint?
        while let field = try reader.next() {
            switch field.field {
            case 1:
                type = .int64
            case 2:
                type = .double
            case 3:
                type = .string
            case 4:
                type = .image
                imageConstraint = try decodeImageConstraint(field.payload)
            case 5:
                type = .multiArray
                multiArrayConstraint = try decodeMultiArrayConstraint(field.payload)
            case 6:
                type = .dictionary
                dictionaryConstraint = try decodeDictionaryConstraint(field.payload)
            case 7:
                type = .sequence
                sequenceConstraint = try decodeSequenceConstraint(field.payload)
            case 8:
                type = .state
                stateConstraint = try decodeStateConstraint(field.payload)
            case 1000:
                isOptional = CoreMLProtoReader.varint(field.payload) != 0
            default:
                break
            }
        }
        return (type, isOptional, dictionaryConstraint, imageConstraint, multiArrayConstraint, sequenceConstraint, stateConstraint)
    }

    static func decodeMultiArrayConstraint(_ payload: [UInt8]) throws -> MLMultiArrayConstraint {
        var reader = CoreMLProtoReader(payload)
        var shape: [NSNumber] = []
        var dataType = MLMultiArrayDataType.float32
        var enumerated: [[NSNumber]] = []
        while let field = try reader.next() {
            switch field.field {
            case 1:
                shape.append(NSNumber(value: CoreMLProtoReader.int64(field.payload)))
            case 2:
                dataType = MLMultiArrayDataType(rawValue: Int(CoreMLProtoReader.int32(field.payload))) ?? .float32
            case 21:
                enumerated.append(contentsOf: try decodeEnumeratedShapes(field.payload))
            default:
                break
            }
        }
        let constraintType: MLMultiArrayShapeConstraintType = enumerated.isEmpty ? .unspecified : .enumerated
        return MLMultiArrayConstraint(
            shape: shape,
            dataType: dataType,
            shapeConstraint: MLMultiArrayShapeConstraint(
                type: constraintType,
                enumeratedShapes: enumerated
            )
        )
    }

    static func decodeEnumeratedShapes(_ payload: [UInt8]) throws -> [[NSNumber]] {
        var reader = CoreMLProtoReader(payload)
        var shapes: [[NSNumber]] = []
        while let field = try reader.next() {
            if field.field == 1 {
                var inner = CoreMLProtoReader(field.payload)
                var dims: [NSNumber] = []
                while let dim = try inner.next() {
                    if dim.field == 1 {
                        dims.append(NSNumber(value: CoreMLProtoReader.int64(dim.payload)))
                    }
                }
                shapes.append(dims)
            }
        }
        return shapes
    }

    static func decodeDictionaryConstraint(_ payload: [UInt8]) throws -> MLDictionaryConstraint {
        var reader = CoreMLProtoReader(payload)
        var keyType = MLFeatureType.string
        while let field = try reader.next() {
            switch field.field {
            case 1:
                keyType = .int64
            case 2:
                keyType = .string
            default:
                break
            }
        }
        return MLDictionaryConstraint(keyType: keyType)
    }

    static func decodeImageConstraint(_ payload: [UInt8]) throws -> MLImageConstraint {
        var reader = CoreMLProtoReader(payload)
        var width = 0
        var height = 0
        var colorSpace: UInt32 = 0
        while let field = try reader.next() {
            switch field.field {
            case 1:
                width = Int(CoreMLProtoReader.int64(field.payload))
            case 2:
                height = Int(CoreMLProtoReader.int64(field.payload))
            case 3:
                colorSpace = UInt32(CoreMLProtoReader.varint(field.payload))
            default:
                break
            }
        }
        return MLImageConstraint(
            pixelsWide: width,
            pixelsHigh: height,
            pixelFormatType: colorSpace,
            sizeConstraint: MLImageSizeConstraint(
                type: .unspecified,
                enumeratedImageSizes: [MLImageSize(pixelsWide: width, pixelsHigh: height)],
                pixelsWideRange: NSRange(location: width, length: 0),
                pixelsHighRange: NSRange(location: height, length: 0)
            )
        )
    }

    static func decodeSequenceConstraint(_ payload: [UInt8]) throws -> MLSequenceConstraint {
        var reader = CoreMLProtoReader(payload)
        var valueType = MLFeatureType.string
        var countRange = NSRange(location: 0, length: Int.max / 4)
        while let field = try reader.next() {
            switch field.field {
            case 1:
                valueType = .int64
            case 3:
                valueType = .string
            case 101:
                countRange = try decodeSizeRange(field.payload)
            default:
                break
            }
        }
        return MLSequenceConstraint(
            valueDescription: MLFeatureDescription(name: "", type: valueType),
            countRange: countRange
        )
    }

    static func decodeStateConstraint(_ payload: [UInt8]) throws -> MLStateConstraint {
        var reader = CoreMLProtoReader(payload)
        var dataType = MLMultiArrayDataType.float32
        var shape: [Int] = []
        while let field = try reader.next() {
            if field.field == 1 {
                let constraint = try decodeMultiArrayConstraint(field.payload)
                dataType = constraint.dataType
                shape = constraint.shape.map(\.intValue)
            }
        }
        return MLStateConstraint(dataType: dataType, bufferShape: shape)
    }

    static func decodeSizeRange(_ payload: [UInt8]) throws -> NSRange {
        var reader = CoreMLProtoReader(payload)
        var lower = 0
        var upper = 0
        while let field = try reader.next() {
            switch field.field {
            case 1:
                lower = Int(CoreMLProtoReader.varint(field.payload))
            case 2:
                upper = Int(CoreMLProtoReader.int64(field.payload))
            default:
                break
            }
        }
        let length = upper < 0 ? Int.max / 4 : max(0, upper - lower)
        return NSRange(location: lower, length: length)
    }

    static func decodeMetadata(_ payload: [UInt8]) throws -> [MLModelMetadataKey: Any] {
        var reader = CoreMLProtoReader(payload)
        var metadata: [MLModelMetadataKey: Any] = [:]
        var userDefined: [String: String] = [:]
        while let field = try reader.next() {
            switch field.field {
            case 1:
                metadata[.description] = CoreMLProtoReader.string(field.payload)
            case 2:
                metadata[.versionString] = CoreMLProtoReader.string(field.payload)
            case 3:
                metadata[.author] = CoreMLProtoReader.string(field.payload)
            case 4:
                metadata[.license] = CoreMLProtoReader.string(field.payload)
            case 100:
                if let entry = try decodeStringMapEntry(field.payload) {
                    userDefined[entry.0] = entry.1
                }
            default:
                break
            }
        }
        if !userDefined.isEmpty {
            metadata[.creatorDefinedKey] = userDefined
        }
        return metadata
    }

    static func decodeStringMapEntry(_ payload: [UInt8]) throws -> (String, String)? {
        var reader = CoreMLProtoReader(payload)
        var key = ""
        var value = ""
        while let field = try reader.next() {
            switch field.field {
            case 1:
                key = CoreMLProtoReader.string(field.payload)
            case 2:
                value = CoreMLProtoReader.string(field.payload)
            default:
                break
            }
        }
        return key.isEmpty ? nil : (key, value)
    }

    static func decodeDictVectorizer(_ payload: [UInt8]) throws -> CoreMLProgram {
        var reader = CoreMLProtoReader(payload)
        var strings: [String] = []
        var ints: [Int64] = []
        while let field = try reader.next() {
            switch field.field {
            case 1:
                strings = try decodeStringVector(field.payload)
            case 2:
                ints = try decodeInt64Vector(field.payload)
            default:
                break
            }
        }
        return .dictVectorizer(stringToIndex: strings, int64ToIndex: ints)
    }

    static func decodeGLMRegressor(_ payload: [UInt8]) throws -> CoreMLProgram {
        var reader = CoreMLProtoReader(payload)
        var weights: [[Double]] = []
        var offset: [Double] = []
        var transform: Int32 = 0
        while let field = try reader.next() {
            switch field.field {
            case 1:
                weights.append(try decodeDoubleArray(field.payload, wire: field.wire))
            case 2:
                if field.wire == 2 {
                    offset.append(contentsOf: CoreMLProtoReader.packedFloat64(field.payload))
                } else {
                    offset.append(CoreMLProtoReader.float64(field.payload))
                }
            case 3:
                transform = CoreMLProtoReader.int32(field.payload)
            default:
                break
            }
        }
        return .glmRegressor(weights: weights, offset: offset, transform: transform)
    }

    static func decodeDoubleArray(_ payload: [UInt8], wire: UInt64) throws -> [Double] {
        if wire == 1 {
            return [CoreMLProtoReader.float64(payload)]
        }
        var reader = CoreMLProtoReader(payload)
        var values: [Double] = []
        while let field = try reader.next() {
            if field.field == 1 {
                if field.wire == 2 {
                    values.append(contentsOf: CoreMLProtoReader.packedFloat64(field.payload))
                } else {
                    values.append(CoreMLProtoReader.float64(field.payload))
                }
            }
        }
        return values
    }

    static func decodeStringVector(_ payload: [UInt8]) throws -> [String] {
        var reader = CoreMLProtoReader(payload)
        var values: [String] = []
        while let field = try reader.next() {
            if field.field == 1 {
                values.append(CoreMLProtoReader.string(field.payload))
            }
        }
        return values
    }

    static func decodeInt64Vector(_ payload: [UInt8]) throws -> [Int64] {
        var reader = CoreMLProtoReader(payload)
        var values: [Int64] = []
        while let field = try reader.next() {
            if field.field == 1 {
                values.append(CoreMLProtoReader.int64(field.payload))
            }
        }
        return values
    }

    static func decodePipeline(_ payload: [UInt8]) throws -> CoreMLProgram {
        var reader = CoreMLProtoReader(payload)
        var models: [CoreMLCompiledModel] = []
        while let field = try reader.next() {
            if field.field == 1 {
                models.append(try decodeModel(Data(field.payload)))
            }
        }
        return .pipeline(models)
    }

    static func decodeWrappedPipeline(_ payload: [UInt8]) throws -> CoreMLProgram {
        var reader = CoreMLProtoReader(payload)
        while let field = try reader.next() {
            if field.field == 1 {
                return try decodePipeline(field.payload)
            }
        }
        return .pipeline([])
    }

    static func metadataJSON(from spec: CoreMLCompiledModel) -> [String: Any] {
        func schema(_ descriptions: [String: MLFeatureDescription]) -> [[String: Any]] {
            descriptions.values.sorted { $0.name < $1.name }.map { feature in
                var row: [String: Any] = [
                    "name": feature.name,
                    "type": string(for: feature.type),
                    "isOptional": feature.isOptional
                ]
                if let constraint = feature.multiArrayConstraint {
                    row["formattedType"] = string(for: constraint.dataType)
                    row["shape"] = constraint.shape.map(\.intValue)
                }
                return row
            }
        }
        var json: [String: Any] = [
            "inputSchema": schema(spec.description.inputDescriptionsByName),
            "outputSchema": schema(spec.description.outputDescriptionsByName),
            "isUpdatable": spec.isUpdatable,
            "linuxProgram": string(for: spec.program)
        ]
        if let author = spec.description.metadata[.author] as? String {
            json["MLModelAuthorKey"] = author
        }
        if let description = spec.description.metadata[.description] as? String {
            json["MLModelDescriptionKey"] = description
        }
        if let version = spec.description.metadata[.versionString] as? String {
            json["MLModelVersionStringKey"] = version
        }
        if let license = spec.description.metadata[.license] as? String {
            json["MLModelLicenseKey"] = license
        }
        if let labels = spec.description.classLabels {
            json["classLabels"] = labels.map { String(describing: $0) }
        }
        return json
    }

    static func description(fromMetadataJSON json: [String: Any]) -> MLModelDescription {
        func features(_ key: String) -> [String: MLFeatureDescription] {
            let rows = json[key] as? [[String: Any]] ?? []
            var result: [String: MLFeatureDescription] = [:]
            for row in rows {
                let name = row["name"] as? String ?? ""
                let type = featureType(from: row["type"] as? String)
                var multi: MLMultiArrayConstraint?
                if type == .multiArray {
                    let shape = (row["shape"] as? [Int] ?? []).map { NSNumber(value: $0) }
                    let dataType = dataType(from: row["formattedType"] as? String)
                    multi = MLMultiArrayConstraint(
                        shape: shape,
                        dataType: dataType,
                        shapeConstraint: MLMultiArrayShapeConstraint(type: .unspecified)
                    )
                }
                result[name] = MLFeatureDescription(
                    name: name,
                    type: type,
                    isOptional: row["isOptional"] as? Bool ?? false,
                    multiArrayConstraint: multi
                )
            }
            return result
        }
        var metadata: [MLModelMetadataKey: Any] = [:]
        if let author = json["MLModelAuthorKey"] as? String { metadata[.author] = author }
        if let description = json["MLModelDescriptionKey"] as? String { metadata[.description] = description }
        if let version = json["MLModelVersionStringKey"] as? String { metadata[.versionString] = version }
        if let license = json["MLModelLicenseKey"] as? String { metadata[.license] = license }
        let labels = json["classLabels"] as? [String]
        return MLModelDescription(
            inputDescriptionsByName: features("inputSchema"),
            outputDescriptionsByName: features("outputSchema"),
            metadata: metadata,
            classLabels: labels,
            isUpdatable: json["isUpdatable"] as? Bool ?? false
        )
    }

    static func mergeMetadata(_ existing: MLModelDescription, json: [String: Any]) -> MLModelDescription {
        var merged = existing
        if merged.inputDescriptionsByName.isEmpty {
            merged = description(fromMetadataJSON: json)
        }
        if let labels = json["classLabels"] as? [String], merged.classLabels == nil {
            merged.classLabels = labels
        }
        return merged
    }

    static func string(for type: MLFeatureType) -> String {
        switch type {
        case .int64: return "Int64"
        case .double: return "Double"
        case .string: return "String"
        case .image: return "Image"
        case .multiArray: return "MultiArray"
        case .dictionary: return "Dictionary"
        case .sequence: return "Sequence"
        case .state: return "State"
        case .invalid: return "Invalid"
        }
    }

    static func string(for type: MLMultiArrayDataType) -> String {
        switch type {
        case .double: return "Double"
        case .float32: return "Float32"
        case .float16: return "Float16"
        case .int32: return "Int32"
        case .int8: return "Int8"
        }
    }

    static func string(for program: CoreMLProgram) -> String {
        switch program {
        case .identity: return "identity"
        case .dictVectorizer: return "dictVectorizer"
        case .glmRegressor: return "glmRegressor"
        case .pipeline: return "pipeline"
        case .customLayer: return "customLayer"
        case .customModel: return "customModel"
        case .neuralNetwork: return "neuralNetwork"
        case .unsupported: return "unsupported"
        }
    }

    static func featureType(from name: String?) -> MLFeatureType {
        switch name {
        case "Int64": return .int64
        case "Double": return .double
        case "String": return .string
        case "Image": return .image
        case "MultiArray": return .multiArray
        case "Dictionary": return .dictionary
        case "Sequence": return .sequence
        case "State": return .state
        default: return .invalid
        }
    }

    static func dataType(from name: String?) -> MLMultiArrayDataType {
        switch name {
        case "Double": return .double
        case "Float16": return .float16
        case "Int32": return .int32
        case "Int8": return .int8
        default: return .float32
        }
    }
}

public enum CoreMLSpecification {
    static func feature(
        name: String,
        type: MLFeatureType,
        shape: [Int] = [],
        dataType: MLMultiArrayDataType = .float32,
        dictionaryKey: MLFeatureType = .string,
        optional: Bool = false
    ) -> [UInt8] {
        var typeBytes: [UInt8] = []
        switch type {
        case .int64:
            typeBytes += CoreMLWire.message(1, [])
        case .double:
            typeBytes += CoreMLWire.message(2, [])
        case .string:
            typeBytes += CoreMLWire.message(3, [])
        case .multiArray:
            var array: [UInt8] = []
            for dim in shape {
                array += CoreMLWire.int64(1, Int64(dim))
            }
            array += CoreMLWire.int32(2, Int32(dataType.rawValue))
            typeBytes += CoreMLWire.message(5, array)
        case .dictionary:
            let keyField: UInt64 = dictionaryKey == .int64 ? 1 : 2
            typeBytes += CoreMLWire.message(6, CoreMLWire.message(keyField, []))
        default:
            break
        }
        if optional {
            typeBytes += CoreMLWire.bool(1000, true)
        }
        var feature: [UInt8] = []
        feature += CoreMLWire.string(1, name)
        feature += CoreMLWire.message(3, typeBytes)
        return feature
    }

    static func metadata(
        author: String = "",
        description: String = "",
        version: String = "",
        license: String = "",
        classLabels: [String] = []
    ) -> [UInt8] {
        var bytes: [UInt8] = []
        if !description.isEmpty { bytes += CoreMLWire.string(1, description) }
        if !version.isEmpty { bytes += CoreMLWire.string(2, version) }
        if !author.isEmpty { bytes += CoreMLWire.string(3, author) }
        if !license.isEmpty { bytes += CoreMLWire.string(4, license) }
        if !classLabels.isEmpty {
            bytes += CoreMLWire.message(100, CoreMLWire.string(1, "classLabels") + CoreMLWire.string(2, classLabels.joined(separator: "\u{1e}")))
        }
        return bytes
    }

    static func description(
        inputs: [[UInt8]],
        outputs: [[UInt8]],
        predictedFeatureName: String? = nil,
        predictedProbabilitiesName: String? = nil,
        metadata: [UInt8] = []
    ) -> [UInt8] {
        var bytes: [UInt8] = []
        for input in inputs {
            bytes += CoreMLWire.message(1, input)
        }
        for output in outputs {
            bytes += CoreMLWire.message(10, output)
        }
        if let predictedFeatureName {
            bytes += CoreMLWire.string(11, predictedFeatureName)
        }
        if let predictedProbabilitiesName {
            bytes += CoreMLWire.string(12, predictedProbabilitiesName)
        }
        if !metadata.isEmpty {
            bytes += CoreMLWire.message(100, metadata)
        }
        return bytes
    }

    public static func identityModel(
        inputName: String = "x",
        outputName: String = "y",
        shape: [Int] = [2],
        dataType: MLMultiArrayDataType = .float32,
        author: String = "OpenUIKit"
    ) -> Data {
        let input = feature(name: inputName, type: .multiArray, shape: shape, dataType: dataType)
        let output = feature(name: outputName, type: .multiArray, shape: shape, dataType: dataType)
        var model: [UInt8] = []
        model += CoreMLWire.int32(1, 1)
        model += CoreMLWire.message(
            2,
            description(
                inputs: [input],
                outputs: [output],
                metadata: metadata(author: author, description: "identity", version: "1.0", license: "BSD")
            )
        )
        model += CoreMLWire.message(900, [])
        return Data(model)
    }

    public static func dictVectorizerModel(
        inputName: String = "input",
        outputName: String = "output",
        vocabulary: [String]
    ) -> Data {
        let input = feature(name: inputName, type: .dictionary, dictionaryKey: .string)
        let output = feature(name: outputName, type: .multiArray, shape: [vocabulary.count], dataType: .double)
        var vector: [UInt8] = []
        for word in vocabulary {
            vector += CoreMLWire.string(1, word)
        }
        var model: [UInt8] = []
        model += CoreMLWire.int32(1, 1)
        model += CoreMLWire.message(
            2,
            description(
                inputs: [input],
                outputs: [output],
                metadata: metadata(author: "OpenUIKit", description: "dict vectorizer")
            )
        )
        model += CoreMLWire.message(603, CoreMLWire.message(1, vector))
        return Data(model)
    }

    public static func glmRegressorModel(
        inputName: String = "x",
        outputName: String = "y",
        weights: [Double],
        offset: Double,
        author: String = "depth-pass"
    ) -> Data {
        let input = feature(name: inputName, type: .multiArray, shape: [weights.count], dataType: .double)
        let output = feature(name: outputName, type: .multiArray, shape: [1], dataType: .double)
        var weightRow: [UInt8] = []
        for value in weights {
            weightRow += CoreMLWire.float64(1, value)
        }
        var glm: [UInt8] = []
        glm += CoreMLWire.message(1, weightRow)
        glm += CoreMLWire.float64(2, offset)
        var model: [UInt8] = []
        model += CoreMLWire.int32(1, 1)
        model += CoreMLWire.message(
            2,
            description(
                inputs: [input],
                outputs: [output],
                metadata: metadata(
                    author: author,
                    description: "glm",
                    version: "1.0",
                    license: "BSD"
                )
            )
        )
        model += CoreMLWire.message(300, glm)
        return Data(model)
    }

    public static func pipelineModel(models: [Data], names: [String] = []) -> Data {
        var pipeline: [UInt8] = []
        for nested in models {
            pipeline += CoreMLWire.message(1, Array(nested))
        }
        for name in names {
            pipeline += CoreMLWire.string(2, name)
        }
        var outer: [UInt8] = []
        let first = try? CoreMLModelCodec.decodeModel(models[0])
        let last = try? CoreMLModelCodec.decodeModel(models[models.count - 1])
        var desc: [UInt8] = []
        if let first {
            for feature in first.description.inputDescriptionsByName.values.sorted(by: { $0.name < $1.name }) {
                desc += CoreMLWire.message(
                    1,
                    CoreMLSpecification.feature(
                        name: feature.name,
                        type: feature.type,
                        shape: feature.multiArrayConstraint?.shape.map(\.intValue) ?? [],
                        dataType: feature.multiArrayConstraint?.dataType ?? .float32,
                        dictionaryKey: feature.dictionaryConstraint?.keyType ?? .string
                    )
                )
            }
        }
        if let last {
            for feature in last.description.outputDescriptionsByName.values.sorted(by: { $0.name < $1.name }) {
                desc += CoreMLWire.message(
                    10,
                    CoreMLSpecification.feature(
                        name: feature.name,
                        type: feature.type,
                        shape: feature.multiArrayConstraint?.shape.map(\.intValue) ?? [],
                        dataType: feature.multiArrayConstraint?.dataType ?? .float32
                    )
                )
            }
        }
        desc += CoreMLWire.message(100, metadata(author: "OpenUIKit", description: "pipeline"))
        outer += CoreMLWire.int32(1, 1)
        outer += CoreMLWire.message(2, desc)
        outer += CoreMLWire.message(202, pipeline)
        return Data(outer)
    }

    public static func neuralNetworkStub(inputName: String = "image", outputName: String = "classLabel") -> Data {
        let input = feature(name: inputName, type: .multiArray, shape: [1, 3], dataType: .float32)
        let output = feature(name: outputName, type: .string)
        var model: [UInt8] = []
        model += CoreMLWire.int32(1, 1)
        model += CoreMLWire.message(
            2,
            description(
                inputs: [input],
                outputs: [output],
                predictedFeatureName: outputName,
                metadata: metadata(
                    author: "OpenUIKit",
                    description: "neural stub",
                    classLabels: ["cat", "dog"]
                )
            )
        )
        model += CoreMLWire.message(500, [])
        return Data(model)
    }
}

func coreMLPredict(
    _ spec: CoreMLCompiledModel,
    from input: any MLFeatureProvider,
    options: MLPredictionOptions
) throws -> any MLFeatureProvider {
    _ = options
    switch spec.program {
    case .identity:
        return try coreMLIdentityPredict(spec, from: input)
    case .dictVectorizer(let strings, let ints):
        return try coreMLDictVectorizerPredict(spec, from: input, stringToIndex: strings, int64ToIndex: ints)
    case .glmRegressor(let weights, let offset, let transform):
        return try coreMLGLMPredict(
            spec,
            from: input,
            weights: weights,
            offset: offset,
            transform: transform
        )
    case .pipeline(let models):
        var current: any MLFeatureProvider = input
        for model in models {
            current = try coreMLPredict(model, from: current, options: options)
        }
        return current
    case .neuralNetwork:
        throw coreMLError(.generic, "neural network layers not implemented")
    case .customLayer:
        throw coreMLError(.customLayer, "MLCustomLayer is fail-closed on Linux.")
    case .customModel:
        throw coreMLError(.customModel, "MLCustomModel is fail-closed on Linux.")
    case .unsupported(let field):
        throw coreMLError(
            .generic,
            "neural network layers not implemented (unsupported Core ML type field \(field))"
        )
    }
}

private func coreMLIdentityPredict(
    _ spec: CoreMLCompiledModel,
    from input: any MLFeatureProvider
) throws -> any MLFeatureProvider {
    var values: [String: MLFeatureValue] = [:]
    let outputs = spec.description.outputDescriptionsByName
    let inputs = spec.description.inputDescriptionsByName
    if outputs.count == 1, inputs.count == 1,
       let output = outputs.values.first,
       let inputName = inputs.keys.first,
       let value = input.featureValue(for: inputName) {
        values[output.name] = value
    } else {
        for (name, description) in outputs {
            if let value = input.featureValue(for: name) {
                values[name] = value
            } else if description.isOptional {
                values[name] = MLFeatureValue(undefined: description.type)
            } else {
                throw coreMLError(.featureType, "Identity model missing input feature \(name).")
            }
        }
    }
    return try MLDictionaryFeatureProvider(dictionary: values)
}

private func coreMLDictVectorizerPredict(
    _ spec: CoreMLCompiledModel,
    from input: any MLFeatureProvider,
    stringToIndex: [String],
    int64ToIndex: [Int64]
) throws -> any MLFeatureProvider {
    let inputName = spec.description.inputDescriptionsByName.keys.sorted().first
        ?? input.featureNames.sorted().first
    guard let inputName, let feature = input.featureValue(for: inputName) else {
        throw coreMLError(.featureType, "DictVectorizer missing dictionary input.")
    }
    let dictionary = feature.dictionaryValue
    let count = max(stringToIndex.count, int64ToIndex.count)
    let array = try MLMultiArray(shape: [NSNumber(value: count)], dataType: .double)
    if !stringToIndex.isEmpty {
        for (index, key) in stringToIndex.enumerated() {
            array[index] = dictionary[key] ?? 0
        }
    } else {
        for (index, key) in int64ToIndex.enumerated() {
            let number = dictionary[Int(key)] ?? dictionary[NSNumber(value: key)] ?? 0
            array[index] = number
        }
    }
    let outputName = spec.description.outputDescriptionsByName.keys.sorted().first ?? "output"
    return try MLDictionaryFeatureProvider(dictionary: [outputName: MLFeatureValue(multiArray: array)])
}

private func coreMLGLMPredict(
    _ spec: CoreMLCompiledModel,
    from input: any MLFeatureProvider,
    weights: [[Double]],
    offset: [Double],
    transform: Int32
) throws -> any MLFeatureProvider {
    guard transform == 0 else {
        throw coreMLError(
            .generic,
            "neural network layers not implemented (GLM post-evaluation transform \(transform))"
        )
    }
    let inputName = spec.description.inputDescriptionsByName.keys.sorted().first
        ?? input.featureNames.sorted().first
    guard let inputName, let feature = input.featureValue(for: inputName), let array = feature.multiArrayValue else {
        throw coreMLError(.featureType, "GLMRegressor missing multi-array input.")
    }
    let outputs = max(weights.count, 1)
    let result = try MLMultiArray(shape: [NSNumber(value: outputs)], dataType: .double)
    for (rowIndex, row) in weights.enumerated() {
        var dot = offset.indices.contains(rowIndex) ? offset[rowIndex] : (offset.first ?? 0)
        for (column, weight) in row.enumerated() where column < array.count {
            dot += weight * array[column].doubleValue
        }
        result[rowIndex] = NSNumber(value: dot)
    }
    if weights.isEmpty {
        result[0] = NSNumber(value: offset.first ?? 0)
    }
    let outputName = spec.description.outputDescriptionsByName.keys.sorted().first ?? "y"
    return try MLDictionaryFeatureProvider(dictionary: [outputName: MLFeatureValue(multiArray: result)])
}

import Foundation

/// A processed scan of a single interior room.
public struct CapturedRoom: Sendable {
    public var walls: [Surface]
    public var doors: [Surface]
    public var windows: [Surface]
    public var openings: [Surface]
    public var floors: [Surface]
    public var objects: [Object]
    public var identifier: UUID
    public var sections: [Section]
    public var story: Int
    public var version: Int

    public init(
        walls: [Surface] = [],
        doors: [Surface] = [],
        windows: [Surface] = [],
        openings: [Surface] = [],
        floors: [Surface] = [],
        objects: [Object] = [],
        identifier: UUID = UUID(),
        sections: [Section] = [],
        story: Int = 0,
        version: Int = 0
    ) {
        self.walls = walls
        self.doors = doors
        self.windows = windows
        self.openings = openings
        self.floors = floors
        self.objects = objects
        self.identifier = identifier
        self.sections = sections
        self.story = story
        self.version = version
    }
}

extension CapturedRoom: Codable {
    enum CodingKeys: String, CodingKey {
        case walls, doors, windows, openings, floors, objects
        case identifier, sections, story, version
    }
}

extension CapturedRoom {
    /// Levels of certainty in the classification of a particular detail in a scan.
    public enum Confidence: String, Codable, Sendable, Equatable, Hashable {
        case high
        case medium
        case low
    }

    /// Errors that can occur during a captured room export.
    public enum Error: Swift.Error, LocalizedError, Equatable, Hashable, Sendable {
        case urlInvalidScheme
        case urlInvalidFilePath
        case urlMissingFileExtension
        case urlInvalidFileExtension
        case deviceNotSupported

        public var errorDescription: String? {
            switch self {
            case .urlInvalidScheme:
                return "The URL prefix represents an unsupported scheme."
            case .urlInvalidFilePath:
                return "The URL references an invalid file path."
            case .urlMissingFileExtension:
                return "The URL lacks a necessary file extension."
            case .urlInvalidFileExtension:
                return "The URL contains an unsupported file extension."
            case .deviceNotSupported:
                return "The framework doesn't support the user's device."
            }
        }
    }

    public struct Section: Codable, Sendable {
        public var label: Label
        public var center: simd_float3
        public var story: Int

        public init(label: Label, center: simd_float3 = .zero, story: Int = 0) {
            self.label = label
            self.center = center
            self.story = story
        }

        enum CodingKeys: String, CodingKey {
            case label, center, story
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            label = try container.decode(Label.self, forKey: .label)
            let values = try container.decode([Float].self, forKey: .center)
            guard values.count == 3 else {
                throw DecodingError.dataCorruptedError(
                    forKey: .center, in: container, debugDescription: "center"
                )
            }
            center = simd_float3(values[0], values[1], values[2])
            story = try container.decode(Int.self, forKey: .story)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(label, forKey: .label)
            try container.encode([center.x, center.y, center.z], forKey: .center)
            try container.encode(story, forKey: .story)
        }

        public enum Label: String, Codable, Sendable, Equatable, Hashable {
            case livingRoom
            case bedroom
            case bathroom
            case kitchen
            case diningRoom
            case unidentified
        }
    }

    public struct Surface: Sendable {
        public var category: Category
        public var confidence: Confidence
        public var dimensions: simd_float3
        public var identifier: UUID
        public var completedEdges: Set<Edge>
        public var polygonCorners: [simd_float3]
        public var parentIdentifier: UUID?
        public var curve: Curve?
        public var story: Int
        public var transform: simd_float4x4

        public init(
            category: Category,
            confidence: Confidence = .low,
            dimensions: simd_float3 = .zero,
            identifier: UUID = UUID(),
            completedEdges: Set<Edge> = [],
            polygonCorners: [simd_float3] = [],
            parentIdentifier: UUID? = nil,
            curve: Curve? = nil,
            story: Int = 0,
            transform: simd_float4x4 = .identity
        ) {
            self.category = category
            self.confidence = confidence
            self.dimensions = dimensions
            self.identifier = identifier
            self.completedEdges = completedEdges
            self.polygonCorners = polygonCorners
            self.parentIdentifier = parentIdentifier
            self.curve = curve
            self.story = story
            self.transform = transform
        }

        public enum Category: Equatable, Hashable, Sendable {
            case wall
            case opening
            case window
            case door(isOpen: Bool)
            case floor
        }

        public enum Edge: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
            case top
            case right
            case bottom
            case left
        }

        public struct Curve: Codable, Sendable {
            public var startAngle: Measurement<UnitAngle>
            public var endAngle: Measurement<UnitAngle>
            public var center: simd_float2
            public var radius: Float

            public init(
                startAngle: Measurement<UnitAngle>,
                endAngle: Measurement<UnitAngle>,
                center: simd_float2,
                radius: Float
            ) {
                self.startAngle = startAngle
                self.endAngle = endAngle
                self.center = center
                self.radius = radius
            }

            enum CodingKeys: String, CodingKey {
                case startAngle, endAngle, center, radius
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                startAngle = try container.decode(Measurement<UnitAngle>.self, forKey: .startAngle)
                endAngle = try container.decode(Measurement<UnitAngle>.self, forKey: .endAngle)
                let values = try container.decode([Float].self, forKey: .center)
                guard values.count == 2 else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .center, in: container, debugDescription: "curve center"
                    )
                }
                center = simd_float2(values[0], values[1])
                radius = try container.decode(Float.self, forKey: .radius)
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(startAngle, forKey: .startAngle)
                try container.encode(endAngle, forKey: .endAngle)
                try container.encode([center.x, center.y], forKey: .center)
                try container.encode(radius, forKey: .radius)
            }
        }
    }

    public struct Object: Sendable {
        public var attributes: [any CapturedRoomAttribute]
        public var confidence: Confidence
        public var dimensions: simd_float3
        public var identifier: UUID
        public var parentIdentifier: UUID?
        public var story: Int
        public var category: Category
        public var transform: simd_float4x4

        public init(
            category: Category,
            attributes: [any CapturedRoomAttribute] = [],
            confidence: Confidence = .low,
            dimensions: simd_float3 = .zero,
            identifier: UUID = UUID(),
            parentIdentifier: UUID? = nil,
            story: Int = 0,
            transform: simd_float4x4 = .identity
        ) {
            self.attributes = attributes
            self.confidence = confidence
            self.dimensions = dimensions
            self.identifier = identifier
            self.parentIdentifier = parentIdentifier
            self.story = story
            self.category = category
            self.transform = transform
        }

        public func attribute<T: CapturedRoomAttribute>(of attributeType: T.Type) -> T? {
            for item in attributes {
                if let typed = item as? T {
                    return typed
                }
            }
            return nil
        }

        public enum Category: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
            case storage
            case refrigerator
            case stove
            case bed
            case sink
            case washerDryer
            case toilet
            case bathtub
            case oven
            case dishwasher
            case table
            case sofa
            case chair
            case fireplace
            case television
            case stairs

            public var supportedAttributeTypes: [any CapturedRoomAttribute.Type] {
                switch self {
                case .storage:
                    return [StorageType.self]
                case .table:
                    return [TableType.self, TableShapeType.self]
                case .sofa:
                    return [SofaType.self]
                case .chair:
                    return [
                        ChairType.self, ChairLegType.self, ChairArmType.self, ChairBackType.self,
                    ]
                default:
                    return []
                }
            }

            public func supportsCombination(_ attributes: [any CapturedRoomAttribute]) -> Bool {
                if attributes.isEmpty {
                    return false
                }
                let allowed = Set(supportedAttributeTypes.map(roomPlanAttributeTypeName))
                var seen = Set<String>()
                for attribute in attributes {
                    let typeName = roomPlanAttributeTypeName(attribute)
                    guard allowed.contains(typeName) else { return false }
                    if !seen.insert(typeName).inserted {
                        return false
                    }
                    guard type(of: attribute).parentCategory == .object(self) else { return false }
                }
                return true
            }

            public var supportedCombinations: [[any CapturedRoomAttribute]] {
                switch self {
                case .storage:
                    return StorageType.allCases.map { [$0] }
                case .sofa:
                    return SofaType.allCases.map { [$0] }
                case .table:
                    return roomPlanCartesianAttributeCombinations([
                        TableType.allCases.map { $0 as any CapturedRoomAttribute },
                        TableShapeType.allCases.map { $0 as any CapturedRoomAttribute },
                    ])
                case .chair:
                    return roomPlanCartesianAttributeCombinations([
                        ChairType.allCases.map { $0 as any CapturedRoomAttribute },
                        ChairLegType.allCases.map { $0 as any CapturedRoomAttribute },
                        ChairArmType.allCases.map { $0 as any CapturedRoomAttribute },
                        ChairBackType.allCases.map { $0 as any CapturedRoomAttribute },
                    ])
                default:
                    return []
                }
            }
        }
    }

    /// Options that determine the underlying data format of a scan export.
    ///
    /// Bit values follow OptionSet convention from API-digester member order:
    /// parametric (bit 0), mesh (bit 1), model (bit 2). Apple's exact integers
    /// are unobserved and recorded as an oracle question.
    public struct USDExportOptions: OptionSet, Sendable {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let parametric = USDExportOptions(rawValue: 1 << 0)
        public static let mesh = USDExportOptions(rawValue: 1 << 1)
        public static let model = USDExportOptions(rawValue: 1 << 2)
    }

    public struct AttributesCodableRepresentation: Codable {
        public let attributes: [any CapturedRoomAttribute]

        public init(attributes: [any CapturedRoomAttribute]) {
            self.attributes = attributes
        }

        public init(from decoder: any Decoder) throws {
            let records = try [RoomPlanAttributeRecord](from: decoder)
            self.attributes = records.map(\.attribute)
        }

        public func encode(to encoder: any Encoder) throws {
            let records = attributes.compactMap(RoomPlanAttributeRecord.init)
            try records.encode(to: encoder)
        }
    }

    public struct ModelProvider {
        private var categoryURLs: [Object.Category: URL] = [:]
        private var attributeURLs: [String: URL] = [:]

        public init() {}

        public var modelFileURLs: [URL] {
            var seen = Set<String>()
            var result: [URL] = []
            for url in categoryURLs.values {
                if seen.insert(url.absoluteString).inserted {
                    result.append(url)
                }
            }
            for url in attributeURLs.values {
                if seen.insert(url.absoluteString).inserted {
                    result.append(url)
                }
            }
            return result
        }

        public mutating func setModelFileURL(_ url: URL?, for category: Object.Category) throws {
            if let url {
                try roomPlanRequireExistingFile(url)
                categoryURLs[category] = url
            } else {
                categoryURLs.removeValue(forKey: category)
            }
        }

        public mutating func setModelFileURL(
            _ url: URL?,
            for attributes: [any CapturedRoomAttribute]
        ) throws {
            guard roomPlanAnyCategorySupports(attributes) else {
                throw ModelProvider.Error.attributeCombinationNotSupported
            }
            let key = roomPlanAttributeCombinationKey(attributes)
            if let url {
                try roomPlanRequireExistingFile(url)
                attributeURLs[key] = url
            } else {
                attributeURLs.removeValue(forKey: key)
            }
        }

        public func modelFileURL(for category: Object.Category) throws -> URL? {
            guard let url = categoryURLs[category] else { return nil }
            try roomPlanRequireExistingFile(url)
            return url
        }

        public func modelFileURL(for attributes: [any CapturedRoomAttribute]) throws -> URL? {
            guard roomPlanAnyCategorySupports(attributes) else {
                throw ModelProvider.Error.attributeCombinationNotSupported
            }
            let key = roomPlanAttributeCombinationKey(attributes)
            guard let url = attributeURLs[key] else { return nil }
            try roomPlanRequireExistingFile(url)
            return url
        }

        public func modelFileURL(for object: Object) throws -> URL? {
            if !object.attributes.isEmpty {
                if let url = try modelFileURL(for: object.attributes) {
                    return url
                }
            }
            return try modelFileURL(for: object.category)
        }

        public enum Error: Swift.Error, LocalizedError, Sendable {
            case attributeCombinationNotSupported
            case nonExistingFile(url: URL)

            public var errorDescription: String? {
                switch self {
                case .attributeCombinationNotSupported:
                    return "The framework doesn't support the attributes set in a model-URL query."
                case .nonExistingFile(let url):
                    return "A 3D model doesn't exist at \(url.absoluteString)."
                }
            }
        }
    }

    public func export(
        to url: URL,
        exportOptions: USDExportOptions = .mesh
    ) throws {
        try export(to: url, metadataURL: nil, modelProvider: nil, exportOptions: exportOptions)
    }

    public func export(
        to url: URL,
        metadataURL: URL? = nil,
        modelProvider: ModelProvider? = nil,
        exportOptions: USDExportOptions = .mesh
    ) throws {
        _ = exportOptions
        _ = modelProvider
        try roomPlanValidateExportURL(url)
        if let metadataURL {
            try roomPlanValidateExportURL(metadataURL)
        }
        throw Error.deviceNotSupported
    }
}

extension CapturedRoom.Surface.Category: Codable {
    enum CodingKeys: String, CodingKey {
        case wall, opening, window, door, floor, isOpen
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.wall) {
            self = .wall
        } else if container.contains(.opening) {
            self = .opening
        } else if container.contains(.window) {
            self = .window
        } else if container.contains(.door) {
            let isOpen = try container.decode(Bool.self, forKey: .isOpen)
            self = .door(isOpen: isOpen)
        } else if container.contains(.floor) {
            self = .floor
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Surface.Category"
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .wall:
            try container.encode(true, forKey: .wall)
        case .opening:
            try container.encode(true, forKey: .opening)
        case .window:
            try container.encode(true, forKey: .window)
        case .door(let isOpen):
            try container.encode(true, forKey: .door)
            try container.encode(isOpen, forKey: .isOpen)
        case .floor:
            try container.encode(true, forKey: .floor)
        }
    }
}

extension CapturedRoom.Surface: Codable {
    enum CodingKeys: String, CodingKey {
        case category, confidence, dimensions, identifier, completedEdges
        case polygonCorners, parentIdentifier, curve, story, transform
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(Category.self, forKey: .category)
        confidence = try container.decode(CapturedRoom.Confidence.self, forKey: .confidence)
        let dim = try container.decode([Float].self, forKey: .dimensions)
        guard dim.count == 3 else {
            throw DecodingError.dataCorruptedError(
                forKey: .dimensions, in: container, debugDescription: "dimensions"
            )
        }
        dimensions = simd_float3(dim[0], dim[1], dim[2])
        identifier = try container.decode(UUID.self, forKey: .identifier)
        completedEdges = try container.decode(Set<Edge>.self, forKey: .completedEdges)
        let corners = try container.decode([[Float]].self, forKey: .polygonCorners)
        polygonCorners = try corners.map { values -> simd_float3 in
            guard values.count == 3 else {
                throw DecodingError.dataCorruptedError(
                    forKey: .polygonCorners, in: container, debugDescription: "corner"
                )
            }
            return simd_float3(values[0], values[1], values[2])
        }
        parentIdentifier = try container.decodeIfPresent(UUID.self, forKey: .parentIdentifier)
        curve = try container.decodeIfPresent(Curve.self, forKey: .curve)
        story = try container.decode(Int.self, forKey: .story)
        let scalars = try container.decode([Float].self, forKey: .transform)
        transform = simd_float4x4(scalars: scalars)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(confidence, forKey: .confidence)
        try container.encode([dimensions.x, dimensions.y, dimensions.z], forKey: .dimensions)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(completedEdges, forKey: .completedEdges)
        try container.encode(
            polygonCorners.map { [$0.x, $0.y, $0.z] },
            forKey: .polygonCorners
        )
        try container.encodeIfPresent(parentIdentifier, forKey: .parentIdentifier)
        try container.encodeIfPresent(curve, forKey: .curve)
        try container.encode(story, forKey: .story)
        try container.encode(transform.scalars, forKey: .transform)
    }
}

extension CapturedRoom.Object: Codable {
    enum CodingKeys: String, CodingKey {
        case attributes, confidence, dimensions, identifier
        case parentIdentifier, story, category, transform
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let representation = try container.decode(
            CapturedRoom.AttributesCodableRepresentation.self,
            forKey: .attributes
        )
        attributes = representation.attributes
        confidence = try container.decode(CapturedRoom.Confidence.self, forKey: .confidence)
        let dim = try container.decode([Float].self, forKey: .dimensions)
        guard dim.count == 3 else {
            throw DecodingError.dataCorruptedError(
                forKey: .dimensions, in: container, debugDescription: "dimensions"
            )
        }
        dimensions = simd_float3(dim[0], dim[1], dim[2])
        identifier = try container.decode(UUID.self, forKey: .identifier)
        parentIdentifier = try container.decodeIfPresent(UUID.self, forKey: .parentIdentifier)
        story = try container.decode(Int.self, forKey: .story)
        category = try container.decode(Category.self, forKey: .category)
        let scalars = try container.decode([Float].self, forKey: .transform)
        transform = simd_float4x4(scalars: scalars)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(
            CapturedRoom.AttributesCodableRepresentation(attributes: attributes),
            forKey: .attributes
        )
        try container.encode(confidence, forKey: .confidence)
        try container.encode([dimensions.x, dimensions.y, dimensions.z], forKey: .dimensions)
        try container.encode(identifier, forKey: .identifier)
        try container.encodeIfPresent(parentIdentifier, forKey: .parentIdentifier)
        try container.encode(story, forKey: .story)
        try container.encode(category, forKey: .category)
        try container.encode(transform.scalars, forKey: .transform)
    }
}

/// An opaque object that holds the raw results of a scan.
public struct CapturedRoomData: Codable, Sendable {
    var payload: Data

    init(payload: Data = Data()) {
        self.payload = payload
    }

    enum CodingKeys: String, CodingKey {
        case payload
    }
}

/// A merged multi-room scan result.
public struct CapturedStructure: Sendable {
    public var rooms: [CapturedRoom]
    public var walls: [Surface]
    public var doors: [Surface]
    public var windows: [Surface]
    public var openings: [Surface]
    public var objects: [Object]
    public var floors: [Surface]
    public var sections: [Section]
    public var identifier: UUID
    public var version: Int

    public typealias Surface = CapturedRoom.Surface
    public typealias Object = CapturedRoom.Object
    public typealias USDExportOptions = CapturedRoom.USDExportOptions
    public typealias Section = CapturedRoom.Section
    public typealias ModelProvider = CapturedRoom.ModelProvider
    public typealias Error = CapturedRoom.Error

    public init(
        rooms: [CapturedRoom] = [],
        identifier: UUID = UUID(),
        version: Int = 0
    ) {
        self.rooms = rooms
        self.walls = rooms.flatMap(\.walls)
        self.doors = rooms.flatMap(\.doors)
        self.windows = rooms.flatMap(\.windows)
        self.openings = rooms.flatMap(\.openings)
        self.objects = rooms.flatMap(\.objects)
        self.floors = rooms.flatMap(\.floors)
        self.sections = rooms.flatMap(\.sections)
        self.identifier = identifier
        self.version = version
    }

    public func export(
        to url: URL,
        metadataURL: URL? = nil,
        modelProvider: ModelProvider? = nil,
        exportOptions: USDExportOptions = .mesh
    ) throws {
        _ = rooms
        try CapturedRoom().export(
            to: url,
            metadataURL: metadataURL,
            modelProvider: modelProvider,
            exportOptions: exportOptions
        )
    }
}

extension CapturedStructure: Codable {
    enum CodingKeys: String, CodingKey {
        case rooms, identifier, version
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rooms = try container.decode([CapturedRoom].self, forKey: .rooms)
        let identifier = try container.decode(UUID.self, forKey: .identifier)
        let version = try container.decode(Int.self, forKey: .version)
        self.init(rooms: rooms, identifier: identifier, version: version)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rooms, forKey: .rooms)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(version, forKey: .version)
    }
}

func roomPlanValidateExportURL(_ url: URL) throws {
    let scheme = (url.scheme ?? "").lowercased()
    if scheme != "file" {
        throw CapturedRoom.Error.urlInvalidScheme
    }
    let path = url.path
    if path.isEmpty {
        throw CapturedRoom.Error.urlInvalidFilePath
    }
    if url.pathExtension.isEmpty {
        throw CapturedRoom.Error.urlMissingFileExtension
    }
    let allowed: Set<String> = ["usdz", "usd", "usda", "usdc"]
    if !allowed.contains(url.pathExtension.lowercased()) {
        throw CapturedRoom.Error.urlInvalidFileExtension
    }
}

func roomPlanRequireExistingFile(_ url: URL) throws {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    if !exists || isDirectory.boolValue {
        throw CapturedRoom.ModelProvider.Error.nonExistingFile(url: url)
    }
}

func roomPlanAnyCategorySupports(_ attributes: [any CapturedRoomAttribute]) -> Bool {
    CapturedRoom.Object.Category.allCases.contains { $0.supportsCombination(attributes) }
}

func roomPlanAttributeCombinationKey(_ attributes: [any CapturedRoomAttribute]) -> String {
    attributes
        .map { "\(roomPlanAttributeTypeName($0)):\($0.rawValue)" }
        .sorted()
        .joined(separator: "|")
}

func roomPlanCartesianAttributeCombinations(
    _ groups: [[any CapturedRoomAttribute]]
) -> [[any CapturedRoomAttribute]] {
    var combinations: [[any CapturedRoomAttribute]] = [[]]
    for group in groups {
        var next: [[any CapturedRoomAttribute]] = []
        next.append(contentsOf: combinations)
        for existing in combinations {
            for item in group {
                next.append(existing + [item])
            }
        }
        combinations = next
    }
    return combinations.filter { !$0.isEmpty }
}

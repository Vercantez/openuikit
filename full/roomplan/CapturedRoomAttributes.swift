import Foundation

/// Details about an object in the room that the framework observes during a scan.
public protocol CapturedRoomAttribute: CaseIterable, RawRepresentable, Sendable
where RawValue == String {
    static var parentCategory: CapturedElementCategory? { get }
    var shortIdentifier: String { get }
}

/// The category of the particular object or surface.
public enum CapturedElementCategory: Equatable, Sendable {
    case surface(CapturedRoom.Surface.Category)
    case object(CapturedRoom.Object.Category)
}

extension CapturedElementCategory: Codable {
    private enum CodingKeys: String, CodingKey {
        case surface
        case object
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.surface) {
            self = .surface(try container.decode(CapturedRoom.Surface.Category.self, forKey: .surface))
        } else if container.contains(.object) {
            self = .object(try container.decode(CapturedRoom.Object.Category.self, forKey: .object))
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "CapturedElementCategory"
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .surface(let category):
            try container.encode(category, forKey: .surface)
        case .object(let category):
            try container.encode(category, forKey: .object)
        }
    }
}

// MARK: - Attribute enums (String raw values match case names)

public enum ChairType: String, CapturedRoomAttribute, Codable, Sendable {
    case dining
    case stool
    case swivel
    case unidentified

    public static var parentCategory: CapturedElementCategory? { .object(.chair) }
    public var shortIdentifier: String { rawValue }
}

public enum ChairLegType: String, CapturedRoomAttribute, Codable, Sendable {
    case four
    case star
    case unidentified

    public static var parentCategory: CapturedElementCategory? { .object(.chair) }
    public var shortIdentifier: String { rawValue }
}

public enum ChairArmType: String, CapturedRoomAttribute, Codable, Sendable {
    case existing
    case missing

    public static var parentCategory: CapturedElementCategory? { .object(.chair) }
    public var shortIdentifier: String { rawValue }
}

public enum ChairBackType: String, CapturedRoomAttribute, Codable, Sendable {
    case existing
    case missing

    public static var parentCategory: CapturedElementCategory? { .object(.chair) }
    public var shortIdentifier: String { rawValue }
}

public enum SofaType: String, CapturedRoomAttribute, Codable, Sendable {
    case rectangular
    case lShaped
    case lShapedExtension
    case singleSeat
    case unidentified

    public static var parentCategory: CapturedElementCategory? { .object(.sofa) }
    public var shortIdentifier: String { rawValue }
}

public enum TableType: String, CapturedRoomAttribute, Codable, Sendable {
    case coffee
    case dining
    case unidentified

    public static var parentCategory: CapturedElementCategory? { .object(.table) }
    public var shortIdentifier: String { rawValue }
}

public enum TableShapeType: String, CapturedRoomAttribute, Codable, Sendable {
    case rectangular
    case circularElliptic
    case lShaped
    case unidentified

    public static var parentCategory: CapturedElementCategory? { .object(.table) }
    public var shortIdentifier: String { rawValue }
}

public enum StorageType: String, CapturedRoomAttribute, Codable, Sendable {
    case cabinet
    case shelf

    public static var parentCategory: CapturedElementCategory? { .object(.storage) }
    public var shortIdentifier: String { rawValue }
}

enum RoomPlanAttributeRecord: Codable, Equatable {
    case chairType(ChairType)
    case chairLegType(ChairLegType)
    case chairArmType(ChairArmType)
    case chairBackType(ChairBackType)
    case sofaType(SofaType)
    case tableType(TableType)
    case tableShapeType(TableShapeType)
    case storageType(StorageType)

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    init?(_ attribute: any CapturedRoomAttribute) {
        switch attribute {
        case let value as ChairType:
            self = .chairType(value)
        case let value as ChairLegType:
            self = .chairLegType(value)
        case let value as ChairArmType:
            self = .chairArmType(value)
        case let value as ChairBackType:
            self = .chairBackType(value)
        case let value as SofaType:
            self = .sofaType(value)
        case let value as TableType:
            self = .tableType(value)
        case let value as TableShapeType:
            self = .tableShapeType(value)
        case let value as StorageType:
            self = .storageType(value)
        default:
            return nil
        }
    }

    var attribute: any CapturedRoomAttribute {
        switch self {
        case .chairType(let value): return value
        case .chairLegType(let value): return value
        case .chairArmType(let value): return value
        case .chairBackType(let value): return value
        case .sofaType(let value): return value
        case .tableType(let value): return value
        case .tableShapeType(let value): return value
        case .storageType(let value): return value
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeName = try container.decode(String.self, forKey: .type)
        switch typeName {
        case "ChairType":
            self = .chairType(try container.decode(ChairType.self, forKey: .value))
        case "ChairLegType":
            self = .chairLegType(try container.decode(ChairLegType.self, forKey: .value))
        case "ChairArmType":
            self = .chairArmType(try container.decode(ChairArmType.self, forKey: .value))
        case "ChairBackType":
            self = .chairBackType(try container.decode(ChairBackType.self, forKey: .value))
        case "SofaType":
            self = .sofaType(try container.decode(SofaType.self, forKey: .value))
        case "TableType":
            self = .tableType(try container.decode(TableType.self, forKey: .value))
        case "TableShapeType":
            self = .tableShapeType(try container.decode(TableShapeType.self, forKey: .value))
        case "StorageType":
            self = .storageType(try container.decode(StorageType.self, forKey: .value))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "unknown attribute type"
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .chairType(let value):
            try container.encode("ChairType", forKey: .type)
            try container.encode(value, forKey: .value)
        case .chairLegType(let value):
            try container.encode("ChairLegType", forKey: .type)
            try container.encode(value, forKey: .value)
        case .chairArmType(let value):
            try container.encode("ChairArmType", forKey: .type)
            try container.encode(value, forKey: .value)
        case .chairBackType(let value):
            try container.encode("ChairBackType", forKey: .type)
            try container.encode(value, forKey: .value)
        case .sofaType(let value):
            try container.encode("SofaType", forKey: .type)
            try container.encode(value, forKey: .value)
        case .tableType(let value):
            try container.encode("TableType", forKey: .type)
            try container.encode(value, forKey: .value)
        case .tableShapeType(let value):
            try container.encode("TableShapeType", forKey: .type)
            try container.encode(value, forKey: .value)
        case .storageType(let value):
            try container.encode("StorageType", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

func roomPlanAttributeTypeName(_ attribute: any CapturedRoomAttribute) -> String {
    String(describing: type(of: attribute))
}

func roomPlanAttributeTypeName(_ type: any CapturedRoomAttribute.Type) -> String {
    String(describing: type)
}

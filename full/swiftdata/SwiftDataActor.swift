import Foundation

public protocol VersionedSchema: SendableMetatype {
    static var models: [any PersistentModel.Type] { get }
    static var versionIdentifier: Schema.Version { get }
}

public protocol SchemaMigrationPlan: SendableMetatype {
    static var schemas: [any VersionedSchema.Type] { get }
    static var stages: [MigrationStage] { get }
}

public enum MigrationStage: @unchecked Sendable {
    case lightweight(fromVersion: any VersionedSchema.Type, toVersion: any VersionedSchema.Type)
    case custom(
        fromVersion: any VersionedSchema.Type,
        toVersion: any VersionedSchema.Type,
        willMigrate: ((ModelContext) throws -> Void)?,
        didMigrate: ((ModelContext) throws -> Void)?
    )
}

public protocol ModelExecutor: Executor {
    var modelContext: ModelContext { get }
}

public protocol SerialModelExecutor: ModelExecutor, SerialExecutor {}

public protocol ModelActor: Actor {
    nonisolated var modelContainer: ModelContainer { get }
    nonisolated var modelExecutor: any ModelExecutor { get }
}

public extension ModelActor {
    var modelContext: ModelContext { modelExecutor.modelContext }

    subscript<T>(id: PersistentIdentifier, as type: T.Type) -> T? where T: PersistentModel {
        modelContext.registeredModel(for: id)
    }

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        if let serial = modelExecutor as? any SerialExecutor {
            return serial.asUnownedSerialExecutor()
        }
        fatalError("ModelActor.modelExecutor must be a SerialExecutor")
    }
}

public final class DefaultSerialModelExecutor: SerialModelExecutor, @unchecked Sendable {
    public let modelContext: ModelContext
    private let lock = NSLock()

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let unowned = UnownedJob(job)
        lock.lock()
        unowned.runSynchronously(on: asUnownedSerialExecutor())
        lock.unlock()
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

#if hasFeature(Macros) && !os(Linux)
@attached(member, names: named(modelExecutor), named(modelContainer), named(init))
@attached(extension, conformances: ModelActor)
public macro ModelActor() =
    #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")

@freestanding(declaration)
public macro Index<T>(_ indices: Schema.Index<T>.Types<T>...) =
    #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")
    where T: PersistentModel

@freestanding(declaration)
public macro Index<T>(_ indices: [PartialKeyPath<T>]...) =
    #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")
    where T: PersistentModel

@freestanding(declaration)
public macro Unique<T>(_ constraints: [PartialKeyPath<T>]...) =
    #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")
    where T: PersistentModel

@attached(peer)
public macro Attribute(
    _ options: Schema.Attribute.Option...,
    originalName: String? = nil,
    hashModifier: String? = nil
) = #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")

@attached(peer)
public macro Transient() =
    #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")

@attached(peer)
public macro Relationship(
    _ options: Schema.Relationship.Option...,
    deleteRule: Schema.Relationship.DeleteRule = .nullify,
    minimumModelCount: Int? = 0,
    maximumModelCount: Int? = 0,
    originalName: String? = nil,
    inverse: AnyKeyPath? = nil,
    hashModifier: String? = nil
) = #externalMacro(module: "SwiftDataMacros", type: "PersistentModelMacro")
#endif

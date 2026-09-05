import Foundation

// Additional AppIntents protocols from the sealed public surface.

public protocol ShowInAppSearchResultsIntent: SystemIntent {}

public protocol AppShortcutsContent {}

public protocol AppEntityAnnotatable {}

public protocol AppShortcutOptionsCollectionProtocol {}

public protocol AppShortcutOptionsCollectionSpecification: Sendable {}

public protocol AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { get }
}

extension AppIntentsPackage {
    public static var includedPackages: [any AppIntentsPackage.Type] { [] }
}

public protocol AppIntentsExtension: AppExtension {}

public protocol OpenIntent: SystemIntent {
    associatedtype Value: AppEntity
    var target: Value { get set }
}

extension OpenIntent {
    public static var openAppWhenRun: Bool { true }
}

public protocol DeleteIntent: SystemIntent {}

public protocol AnyIntentValue: Sendable {}

public protocol SearchCriteria: _IntentValue, Hashable, Sendable {}

public protocol SetValueIntent: AppIntent {}

public protocol UndoableIntent: SystemIntent {}

public protocol PlayVideoIntent: SystemIntent {}

public protocol IntentValueQuery: PersistentlyIdentifiable, _SupportsAppDependencies, Sendable {}

public protocol PredictableIntent: AppIntent {}

public protocol LiveActivityIntent: SystemIntent {}

public protocol PauseWorkoutIntent: SystemIntent {}

public protocol StartWorkoutIntent: InstanceDisplayRepresentable, SystemIntent {}

public protocol AudioPlaybackIntent: SystemIntent {}

public protocol AudioStartingIntent: SystemIntent {}

public protocol CameraCaptureIntent: SystemIntent {}

public protocol EntityPropertyQuery: EntityQuery {
    associatedtype ComparatorMappingType = Never
    static var properties: EntityQueryProperties<Entity, ComparatorMappingType> { get }
    static var sortingOptions: EntityQuerySortingOptions<Entity> { get }
    static var findIntentDescription: IntentDescription? { get }
    func entities(
        matching comparators: [ComparatorMappingType],
        mode: EntityQueryComparatorMode,
        sortedBy: [EntityQuerySort<Entity>],
        limit: Int?
    ) async throws -> [Entity]
}

extension EntityPropertyQuery {
    public static var findIntentDescription: IntentDescription? { nil }
    public static var properties: EntityQueryProperties<Entity, ComparatorMappingType> {
        EntityQueryProperties()
    }
    public static var sortingOptions: EntityQuerySortingOptions<Entity> {
        EntityQuerySortingOptions()
    }
    public func entities(
        matching comparators: [ComparatorMappingType],
        mode: EntityQueryComparatorMode,
        sortedBy: [EntityQuerySort<Entity>],
        limit: Int?
    ) async throws -> [Entity] {
        _ = comparators
        _ = mode
        _ = sortedBy
        _ = limit
        return try await suggestedEntities()
    }
    public typealias QueryProperties = EntityQueryProperties<Entity, ComparatorMappingType>
    public typealias ComparatorMode = EntityQueryComparatorMode
    public typealias SortingOptions = EntityQuerySortingOptions<Entity>
    public typealias Sort = EntityQuerySort
}

public protocol ResumeWorkoutIntent: SystemIntent {}

public protocol AudioRecordingIntent: SystemIntent {}

public protocol SetFocusFilterIntent: AppIntent, InstanceDisplayRepresentable {}

public protocol URLRepresentableEnum: AppEnum, CustomURLRepresentationParameterConvertible {}

public protocol RangeCheckingResolver: Resolver {}

public protocol ResolverSpecification: Hashable, Sendable {}

public protocol URLRepresentableEntity: AppEntity, CustomURLRepresentationParameterConvertible {}

public protocol URLRepresentableIntent: AppIntent {}

public protocol ProgressReportingIntent: AppIntent {}

public protocol RangeComparableProperty: _IntentValue {}

public protocol LiveActivityStartingIntent: SystemIntent {}

public protocol ForegroundContinuableIntent: AppIntent {}

public protocol PushToTalkTransmissionIntent: SystemIntent {}

public protocol TargetContentProvidingIntent: AppIntent {}

public protocol IntentPredictionConfiguration {}

public protocol CustomURLRepresentationParameterConvertible {}

public protocol Resolver: Hashable, Sendable {}

public protocol UISceneAppIntent: TargetContentProvidingIntent {}

public protocol AppIntentSceneDelegate: UISceneDelegate {}


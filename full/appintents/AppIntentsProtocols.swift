import Foundation

// Additional AppIntents protocols from the sealed public surface.

public protocol ShowInAppSearchResultsIntent: SystemIntent {
    associatedtype Criteria: SearchCriteria
    var criteria: Criteria { get set }
    static var searchScopes: Criteria.SearchScopes { get }
}

extension ShowInAppSearchResultsIntent {
    public static var openAppWhenRun: Bool { true }
}

extension ShowInAppSearchResultsIntent where Criteria == StringSearchCriteria {
    public static var searchScopes: [StringSearchScope] { [] }
}

extension ShowInAppSearchResultsIntent where Criteria.SearchScopes == Void {
    public static var searchScopes: Void { () }
}

public protocol AppShortcutsContent {
    static var appShortcuts: [AppShortcut] { get }
}

public protocol AppEntityAnnotatable {
    var appEntityIdentifier: EntityIdentifier? { get set }
}

public protocol AppShortcutOptionsCollectionProtocol {
    associatedtype Provider: DynamicOptionsProvider
    var title: LocalizedStringResource { get }
    var systemImageName: String? { get }
    var dynamicOptionsProvider: Provider { get }
}

public protocol AppShortcutOptionsCollectionSpecification<Value>: Sendable, Sequence
    where Element == any AppShortcutOptionsCollectionProtocol
{
    associatedtype Value: _IntentValue
}

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

public protocol DeleteIntent: SystemIntent {
    associatedtype Entity: AppEntity
    var entities: [Entity] { get }
}

public protocol AnyIntentValue: Sendable {}

public protocol SearchCriteria: _IntentValue, Hashable, Sendable {
    associatedtype SearchScopes = Void
}

public protocol SetValueIntent: AppIntent {
    associatedtype ValueType: _IntentValue
    var value: ValueType { get set }
}

public protocol UndoableIntent: SystemIntent {}

public protocol PlayVideoIntent: SystemIntent {
    var term: String { get }
    static var supportedCategories: [VideoCategory] { get }
}

public protocol IntentValueQuery: PersistentlyIdentifiable, _SupportsAppDependencies, Sendable {
    associatedtype Input
    /// Host defaults keep existing conformers compiling; Apple chains these
    /// through `Result.Result.ValueType`, which the host toolchain cannot
    /// express as a default without a concrete anchor.
    associatedtype Result: ResultsCollection = [String]
    associatedtype ResultValue = String
}

public protocol PredictableIntent: AppIntent {
    associatedtype Prediction
    static var predictionConfiguration: Prediction { get }
}

public protocol LiveActivityIntent: SystemIntent {}

public protocol PauseWorkoutIntent: SystemIntent {}

public protocol StartWorkoutIntent: InstanceDisplayRepresentable, SystemIntent {
    associatedtype WorkoutStyle
    var workoutStyle: WorkoutStyle { get }
    static var suggestedWorkouts: [Self] { get }
}

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
        _ = mode
        _ = sortedBy
        var results = try await suggestedEntities()
        if !comparators.isEmpty, let tokens = comparators as? [String] {
            results = results.filter { entity in
                let ident = String(describing: entity.id)
                let title = appIntentsString(entity.displayRepresentation.title)
                switch mode {
                case .or:
                    return tokens.contains { ident.hasPrefix($0) || title.hasPrefix($0) }
                case .and:
                    return tokens.allSatisfy { ident.hasPrefix($0) || title.hasPrefix($0) }
                }
            }
        }
        if let first = sortedBy.first, first.order == .descending {
            results.reverse()
        }
        if let limit {
            results = Array(results.prefix(limit))
        }
        return results
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

public protocol ResolverSpecification: Hashable, Sendable, Sequence where Element == any Resolver {
    associatedtype Output = Never
}

public protocol URLRepresentableEntity: AppEntity, CustomURLRepresentationParameterConvertible {}

public protocol URLRepresentableIntent: AppIntent {}

public protocol ProgressReportingIntent: AppIntent {
    var progress: Progress { get }
}

extension ProgressReportingIntent {
    public var progress: Progress {
        ProgressReportingHost.progress(for: String(describing: Self.self))
    }
}

public protocol RangeComparableProperty: _IntentValue {}

public protocol LiveActivityStartingIntent: SystemIntent {}

public protocol ForegroundContinuableIntent: AppIntent {}

public protocol PushToTalkTransmissionIntent: SystemIntent {}

public protocol TargetContentProvidingIntent: AppIntent {}

public protocol IntentPredictionConfiguration {}

public protocol CustomURLRepresentationParameterConvertible {}

public protocol Resolver: Hashable, Sendable {
    associatedtype Input: _IntentValue
    associatedtype Output: _IntentValue
    typealias Context = IntentParameterContext<Output>
    func resolve(from input: Input, context: IntentParameterContext<Output>) async throws -> Output?
}

public protocol UISceneAppIntent: TargetContentProvidingIntent {}

public protocol AppIntentSceneDelegate: UISceneDelegate {}


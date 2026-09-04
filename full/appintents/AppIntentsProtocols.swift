import Foundation

// Additional AppIntents protocols from the sealed public surface.

public protocol ShowInAppSearchResultsIntent: SystemIntent {}

public protocol AppShortcutsContent {}

public protocol AppEntityAnnotatable {}

public protocol AppShortcutOptionsCollectionProtocol {}

public protocol AppShortcutOptionsCollectionSpecification: Sendable {}

public protocol AppIntentsPackage {}

public protocol AppIntentsExtension: AppExtension {}

public protocol OpenIntent: SystemIntent {}

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

public protocol EntityPropertyQuery: EntityQuery {}

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


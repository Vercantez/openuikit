#if OPENUIKIT_PORTABLE_SWIFTUI
import SwiftUI

private enum _ModelContextEnvironmentKey: EnvironmentKey {
    static let defaultValue: ModelContext = {
        let container = try! ModelContainer(
            modelTypes: [],
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        SwiftDataPortable.installDefaultContainer(container)
        return container.mainContext
    }()
}

public extension EnvironmentValues {
    var modelContext: ModelContext {
        get { self[_ModelContextEnvironmentKey.self] }
        set { self[_ModelContextEnvironmentKey.self] = newValue }
    }
}

extension Query: DynamicProperty {
    public mutating func update() {}
}

public extension View {
    @MainActor
    func modelContainer(_ container: ModelContainer) -> some View {
        SwiftDataPortable.installDefaultContainer(container)
        return environment(\.modelContext, container.mainContext)
    }

    @MainActor
    func modelContainer(
        for modelType: any PersistentModel.Type,
        inMemory: Bool = false,
        isAutosaveEnabled: Bool = true,
        isUndoEnabled: Bool = false,
        onSetup: @escaping (Result<ModelContainer, any Error>) -> Void = { _ in }
    ) -> some View {
        modelContainer(
            for: [modelType],
            inMemory: inMemory,
            isAutosaveEnabled: isAutosaveEnabled,
            isUndoEnabled: isUndoEnabled,
            onSetup: onSetup
        )
    }

    @MainActor
    func modelContainer(
        for modelTypes: [any PersistentModel.Type],
        inMemory: Bool = false,
        isAutosaveEnabled: Bool = true,
        isUndoEnabled: Bool = false,
        onSetup: @escaping (Result<ModelContainer, any Error>) -> Void = { _ in }
    ) -> some View {
        if !inMemory {
            SwiftDataPortable.reportVolatileFallback()
        }
        precondition(!isUndoEnabled, "SwiftData undo integration is unavailable")
        do {
            let container = try ModelContainer(
                modelTypes: modelTypes,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
            container.mainContext.autosaveEnabled = isAutosaveEnabled
            onSetup(.success(container))
            return modelContainer(container)
        } catch {
            onSetup(.failure(error))
            preconditionFailure(String(describing: error))
        }
    }
}
#endif

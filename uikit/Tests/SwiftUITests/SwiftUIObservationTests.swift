// Focused runtime coverage for SwiftUI S2 dynamic state and observation.

import XCTest
import Combine
#if os(Linux)
@preconcurrency import OpenUIKit
#else
import OpenUIKit
#endif
#if os(Linux)
@preconcurrency @testable import SwiftUI
#else
@testable import SwiftUI
#endif

private final class ObservationModel: Combine.ObservableObject {
    @Combine.Published var value: Int

    init(_ value: Int) {
        self.value = value
    }
}

private final class WeakReference<Object: AnyObject> {
    weak var value: Object?

    init(_ value: Object?) {
        self.value = value
    }
}

private struct ObservationFixture: View {
    @ObservedObject var model: ObservationModel
    let capture: @MainActor (Binding<Int>) -> Void

    init(
        model: ObservationModel,
        capture: @escaping @MainActor (Binding<Int>) -> Void = { _ in }
    ) {
        self.model = model
        self.capture = capture
    }

    var body: some View {
        // Read the same observed object repeatedly and expose the exact
        // projected-binding shape used by Focus's $viewModel.activeScreen.
        capture($model.value)
        return HStack {
            Text("value=\(model.value)")
            Text("again=\(model.value)")
        }
    }
}

private struct ReentrantObservationFixture: View {
    @ObservedObject var model: ObservationModel
    let duringBody: @MainActor () -> Void

    var body: some View {
        duringBody()
        return Text("reentrant=\(model.value)")
    }
}

private struct StateFixture: View {
    @State private var count: Int
    let capture: @MainActor (Binding<Int>) -> Void

    init(initialValue: Int, capture: @escaping @MainActor (Binding<Int>) -> Void) {
        _count = State(wrappedValue: initialValue)
        self.capture = capture
    }

    var body: some View {
        capture($count)
        return Text("state=\(count)")
    }
}

private struct AnimatedStateFixture: View {
    @State private var count = 0
    let animation: Animation
    let capture: @MainActor (Binding<Int>) -> Void

    var body: some View {
        capture($count)
        return Text("animated=\(count)")
            .animation(animation, value: count)
    }
}

private enum TestEnvironmentKey: EnvironmentKey {
    static let defaultValue = "default"
}

private extension EnvironmentValues {
    var testValue: String {
        get { self[TestEnvironmentKey.self] }
        set { self[TestEnvironmentKey.self] = newValue }
    }
}

private final class EnvironmentService {
    let identifier: Int

    init(_ identifier: Int) {
        self.identifier = identifier
    }
}

@available(macOS 14.0, *)
@Observable
private final class EnvironmentObservationService {
    var value: Int

    init(_ value: Int) {
        self.value = value
    }
}

@available(macOS 14.0, *)
private struct EnvironmentObservationLeaf: View {
    @Environment(EnvironmentObservationService.self) private var service

    var body: some View {
        Text("environmentObservation=\(service.value)")
    }
}

@available(macOS 14.0, *)
private struct EnvironmentObservationFixture: View {
    let service: EnvironmentObservationService

    var body: some View {
        EnvironmentObservationLeaf()
            .environment(service)
    }
}

private struct EnvironmentLeaf: View {
    @Environment(\.testValue) private var value
    @Environment(EnvironmentService.self) private var service
    let capture: @MainActor (String, EnvironmentService) -> Void

    var body: some View {
        capture(value, service)
        return Text("\(value)=\(service.identifier)")
    }
}

private struct EnvironmentFixture: View {
    let service: EnvironmentService
    let capture: @MainActor (String, EnvironmentService) -> Void

    var body: some View {
        VStack {
            EnvironmentLeaf(capture: capture)
            EnvironmentLeaf(capture: capture)
                .environment(\.testValue, "inner")
        }
        .environment(\.testValue, "outer")
        .environment(service)
    }
}

private struct BuiltInEnvironmentLeaf: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    let capture: @MainActor (Bool, ColorScheme) -> Void

    var body: some View {
        capture(isEnabled, colorScheme)
        return Text("enabled=\(isEnabled),scheme=\(colorScheme)")
    }
}

private struct StateObjectFixture: View {
    @StateObject private var model: ObservationModel
    let capture: @MainActor (ObservationModel, Binding<Int>) -> Void

    init(
        model: ObservationModel,
        capture: @escaping @MainActor (ObservationModel, Binding<Int>) -> Void
    ) {
        _model = StateObject(wrappedValue: model)
        self.capture = capture
    }

    var body: some View {
        capture(model, $model.value)
        return Text("stateObject=\(model.value)")
    }
}

private struct AppStorageFixture: View {
    @AppStorage("shared-test-value") private var first = 1
    @AppStorage("shared-test-value") private var second = 2
    let capture: @MainActor (Binding<Int>, Binding<Int>) -> Void

    init(capture: @escaping @MainActor (Binding<Int>, Binding<Int>) -> Void) {
        self.capture = capture
    }

    var body: some View {
        capture($first, $second)
        return Text("appStorage=\(first)/\(second)")
    }
}

private struct StatefulLeaf: View {
    @State private var value: Int
    let name: String
    let capture: @MainActor (String, Binding<Int>) -> Void

    init(
        name: String,
        initialValue: Int,
        capture: @escaping @MainActor (String, Binding<Int>) -> Void
    ) {
        self.name = name
        _value = State(initialValue: initialValue)
        self.capture = capture
    }

    var body: some View {
        capture(name, $value)
        return Text("\(name)=\(value)")
    }
}

private struct SameTypeConditionalFixture: View {
    let firstBranch: Bool
    let capture: @MainActor (String, Binding<Int>) -> Void

    @ViewBuilder var body: some View {
        if firstBranch {
            StatefulLeaf(name: "first", initialValue: 11, capture: capture)
        } else {
            // Deliberately the exact same concrete type as the first branch.
            StatefulLeaf(name: "second", initialValue: 22, capture: capture)
        }
    }
}

private struct OptionalStackFixture: View {
    let showsOptional: Bool
    let capture: @MainActor (String, Binding<Int>) -> Void

    var body: some View {
        VStack {
            if showsOptional {
                StatefulLeaf(name: "optional", initialValue: 10, capture: capture)
            }
            HStack {
                StatefulLeaf(name: "stable", initialValue: 20, capture: capture)
            }
        }
    }
}

private struct ArrayElement {
    let name: String
    let initialValue: Int
}

private struct ArrayBoundaryFixture: View {
    let leading: [ArrayElement]
    let capture: @MainActor (String, Binding<Int>) -> Void

    var body: some View {
        VStack {
            for element in leading {
                HStack {
                    StatefulLeaf(
                        name: element.name,
                        initialValue: element.initialValue,
                        capture: capture
                    )
                }
            }
            VStack {
                StatefulLeaf(name: "stable", initialValue: 100, capture: capture)
            }
        }
    }
}

private struct DeferredBackgroundFixture: View {
    let capture: @MainActor (String, Binding<Int>) -> Void

    var body: some View {
        HStack {
            Text("left").background(
                StatefulLeaf(name: "leftBackground", initialValue: 1, capture: capture)
            )
            Text("right").background(
                StatefulLeaf(name: "rightBackground", initialValue: 2, capture: capture)
            )
        }
    }
}

private struct OpaqueElementID: Hashable, CustomStringConvertible {
    let rawValue: Int

    // Both IDs intentionally have the same textual representation. Graph
    // identity must use Hashable equality, never reflected/interpolated text.
    var description: String { "same-description" }
}

private struct IdentifiedElement {
    let id: OpaqueElementID
    let initialValue: Int
}

private struct ForEachFixture: View {
    let elements: [IdentifiedElement]
    let capture: @MainActor (String, Binding<Int>) -> Void

    var body: some View {
        VStack {
            ForEach(elements, id: \.id) { element in
                StatefulLeaf(
                    name: "id\(element.id.rawValue)",
                    initialValue: element.initialValue,
                    capture: capture
                )
            }
        }
    }
}

private final class DynamicUpdateRecorder {
    var events: [String] = []
}

private struct InnerDynamicProperty: DynamicProperty {
    @State private var count: Int
    @ObservedObject private var model: ObservationModel
    let recorder: DynamicUpdateRecorder
    private(set) var updatedValue = -1

    init(initialValue: Int, model: ObservationModel, recorder: DynamicUpdateRecorder) {
        _count = State(initialValue: initialValue)
        _model = ObservedObject(initialValue: model)
        self.recorder = recorder
    }

    mutating func update() {
        recorder.events.append("inner")
        updatedValue = count
    }

    var value: Int { count }
    var modelValue: Int { model.value }
    var valueBinding: Binding<Int> { $count }
    var modelBinding: Binding<Int> { $model.value }
}

private struct OuterDynamicProperty: DynamicProperty {
    var inner: InnerDynamicProperty
    let recorder: DynamicUpdateRecorder
    private(set) var updatedValue = -1

    mutating func update() {
        recorder.events.append("outer")
        updatedValue = inner.updatedValue
    }
}

private struct NestedDynamicLeaf: View {
    var property: OuterDynamicProperty
    let capture: @MainActor (Binding<Int>, Binding<Int>) -> Void

    var body: some View {
        capture(property.inner.valueBinding, property.inner.modelBinding)
        return Text(
            "nested=\(property.inner.value)/\(property.inner.modelValue)"
                + "/updated=\(property.updatedValue)"
        )
    }
}

// Oracle-shaped regression for DynamicProperty's value semantics. A Mirror
// existential copy can run update(), but body must evaluate the prepared View
// copy containing that mutation rather than the original value.
private struct UpdatingProperty: DynamicProperty {
    @State private var source = 7
    private(set) var value = -1

    mutating func update() {
        value = source
    }
}

private struct UpdatingPropertyFixture: View {
    var property = UpdatingProperty()
    let capture: @MainActor (Int) -> Void

    var body: some View {
        capture(property.value)
        return Text("updated=\(property.value)")
    }
}

// CustomReflectable must not be able to replace the stored-field mirror and
// silently hide DynamicProperty values from the preparation pass.
private struct CustomMirroredUpdatingProperty: DynamicProperty, CustomReflectable {
    @State private var source = 7
    private(set) var value = -1

    mutating func update() {
        value = source
    }

    var customMirror: Mirror {
        Mirror(self, children: EmptyCollection<(label: String?, value: Any)>())
    }
}

private struct CustomMirroredUpdatingFixture: View, CustomReflectable {
    var property = CustomMirroredUpdatingProperty()
    let capture: @MainActor (Int) -> Void

    nonisolated var customMirror: Mirror {
        Mirror(self, children: EmptyCollection<(label: String?, value: Any)>())
    }

    var body: some View {
        capture(property.value)
        return Text("customUpdated=\(property.value)")
    }
}

private final class AliasedClassUpdatingProperty: DynamicProperty {
    private(set) var updateCount = 0

    func update() {
        updateCount += 1
    }
}

private struct AliasedClassUpdatingFixture: View {
    var first: AliasedClassUpdatingProperty
    var second: AliasedClassUpdatingProperty
    let capture: @MainActor (Int) -> Void

    var body: some View {
        let observed = first.updateCount * 10 + second.updateCount
        capture(observed)
        return Text("aliasUpdated=\(observed)")
    }
}

private struct ReusedStateLeaf: View {
    @State private var value = 1
    let capture: @MainActor (Binding<Int>) -> Void

    var body: some View {
        capture($value)
        return Text("reused=\(value)")
    }
}

private struct ReusedStateFixture: View {
    let leaf: ReusedStateLeaf

    init(capture: @escaping @MainActor (Binding<Int>) -> Void) {
        leaf = ReusedStateLeaf(capture: capture)
    }

    var body: some View {
        HStack {
            leaf
            leaf
        }
    }
}

// DynamicProperty permits reference types too. This also verifies recursive
// State discovery at native class-object offsets on both Swift runtimes.
private final class ClassUpdatingProperty: DynamicProperty {
    @State private var source: Int
    private(set) var value = -1
    let recorder: DynamicUpdateRecorder

    init(source: Int, recorder: DynamicUpdateRecorder) {
        _source = State(initialValue: source)
        self.recorder = recorder
    }

    func update() {
        recorder.events.append("class")
        value = source
    }

    var sourceBinding: Binding<Int> { $source }
}

private struct ClassUpdatingPropertyFixture: View {
    var property: ClassUpdatingProperty
    let capture: @MainActor (Binding<Int>) -> Void

    var body: some View {
        capture(property.sourceBinding)
        return Text("classUpdated=\(property.value)")
    }
}

private final class DynamicPropertyLifetimeToken {}

private struct ReferenceBearingUpdatingProperty: DynamicProperty {
    let token: DynamicPropertyLifetimeToken
    private(set) var value = -1

    mutating func update() {
        value = 42
    }
}

private struct ReferenceBearingUpdatingPropertyFixture: View {
    var property: ReferenceBearingUpdatingProperty

    var body: some View {
        Text("referenceUpdated=\(property.value)")
    }
}

private struct NestedDynamicBranchFixture: View {
    let showsLeaf: Bool
    let model: ObservationModel
    let recorder: DynamicUpdateRecorder
    let capture: @MainActor (Binding<Int>, Binding<Int>) -> Void

    @ViewBuilder var body: some View {
        if showsLeaf {
            NestedDynamicLeaf(
                property: OuterDynamicProperty(
                    inner: InnerDynamicProperty(
                        initialValue: 5,
                        model: model,
                        recorder: recorder
                    ),
                    recorder: recorder
                ),
                capture: capture
            )
        } else {
            Text("absent")
        }
    }
}

private final class NonisolatedStorageBox {
    var value = 1
}

// A declaration-level compatibility probe: none of these functions is actor
// isolated. The old globally-@MainActor wrappers fail to compile this shape.
private func makeNonisolatedBinding(
    storage: NonisolatedStorageBox
) -> Binding<Int> {
    Binding(get: { storage.value }, set: { storage.value = $0 })
}

private func makeNonisolatedState() -> State<Int> {
    State(initialValue: 3)
}

private func makeNonisolatedObservedObject(
    _ model: ObservationModel
) -> ObservedObject<ObservationModel> {
    ObservedObject(initialValue: model)
}

#if !os(Linux)
@MainActor
#endif
final class SwiftUIObservationTests: XCTestCase {
    func testFoundationHiddenSchedulerDefersToOneHostClockTurn() {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        var events: [String] = []
        _OpenInvalidationScheduler.enqueue {
            events.append("first")
            _OpenInvalidationScheduler.enqueue { events.append("nested") }
        }
        _OpenInvalidationScheduler.enqueue { events.append("second") }

        XCTAssertEqual(events, [])
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        XCTAssertEqual(events, ["first", "second"])
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        XCTAssertEqual(events, ["first", "second", "nested"])
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)
    }

    func testHostClockSchedulerCoalescesObservedObjectAndRendersLatestValue() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let model = ObservationModel(0)
        let controller = UIHostingController(rootView: ObservationFixture(model: model))
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 220, height: 44)
        host.layoutIfNeeded()

        model.value = 1
        model.value = 2

        XCTAssertEqual(controller._openGraphRenderCount, 1)
        XCTAssertEqual(controller._openGraphInvalidationCount, 0)
        XCTAssertEqual(texts(in: host), ["value=0", "again=0"])
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)

        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()

        XCTAssertEqual(controller._openGraphRenderCount, 2)
        XCTAssertEqual(controller._openGraphInvalidationCount, 1)
        XCTAssertEqual(controller._openGraphObservationCount, 1)
        XCTAssertEqual(texts(in: host), ["value=2", "again=2"])
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)
    }

    func testHostClockPendingWorkSurvivesRootReplacementWithoutRetainingController() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let oldModel = ObservationModel(0)
        let newModel = ObservationModel(10)
        var controller: UIHostingController<ObservationFixture>? = UIHostingController(
            rootView: ObservationFixture(model: oldModel)
        )
        let host = try XCTUnwrap(controller?.view)
        host.frame = CGRect(x: 0, y: 0, width: 220, height: 44)
        host.layoutIfNeeded()

        oldModel.value = 1
        controller?.rootView = ObservationFixture(model: newModel)
        newModel.value = 11
        oldModel.value = 2

        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
        XCTAssertEqual(controller?._openGraphInvalidationCount, 1)
        XCTAssertEqual(texts(in: host), ["value=11", "again=11"])
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)

        newModel.value = 12
        let weakController = WeakReference(controller)
        controller = nil
        XCTAssertNil(weakController.value)
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)

        newModel.value = 13
        XCTAssertFalse(
            OpenUIKit.Timer._hasScheduledTimers,
            "a model outliving its controller must not enqueue dead-graph work"
        )
    }

    func testHostClockRetiredRootActionCannotConsumeNewGenerationPublication() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let oldModel = ObservationModel(0)
        let newModel = ObservationModel(10)
        let controller = UIHostingController(
            rootView: ObservationFixture(model: oldModel)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 220, height: 44)
        host.layoutIfNeeded()

        // Insert ordinary host work before the old graph action. During this
        // turn it replaces the root (retiring the old action) and publishes
        // from the replacement graph. That publication owns a new timer which
        // is not eligible until the following outer host turn.
        OpenUIKit.Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { timer in
            timer.invalidate()
            controller.rootView = ObservationFixture(model: newModel)
            newModel.value = 11
        }
        oldModel.value = 1

        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
        XCTAssertEqual(
            controller._openGraphInvalidationCount,
            0,
            "a retired old-root callback must not consume the new graph's work token"
        )
        XCTAssertEqual(controller._openGraphRenderCount, 2)
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)

        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
        XCTAssertEqual(controller._openGraphInvalidationCount, 1)
        XCTAssertEqual(controller._openGraphRenderCount, 3)
        XCTAssertEqual(texts(in: host), ["value=11", "again=11"])
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)
    }

    func testHostClockMultipleGraphsCoalesceIndependentlyAtEqualDeadline() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let firstModel = ObservationModel(0)
        let secondModel = ObservationModel(100)
        let first = UIHostingController(rootView: ObservationFixture(model: firstModel))
        let second = UIHostingController(rootView: ObservationFixture(model: secondModel))
        let firstHost = try XCTUnwrap(first.view)
        let secondHost = try XCTUnwrap(second.view)

        firstModel.value = 1
        firstModel.value = 2
        secondModel.value = 101
        secondModel.value = 102

        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        firstHost.layoutIfNeeded()
        secondHost.layoutIfNeeded()
        XCTAssertEqual(first._openGraphInvalidationCount, 1)
        XCTAssertEqual(second._openGraphInvalidationCount, 1)
        XCTAssertEqual(texts(in: firstHost), ["value=2", "again=2"])
        XCTAssertEqual(texts(in: secondHost), ["value=102", "again=102"])
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)
    }

    func testHostClockEqualDeadlineOrderingAndNestedTurnBoundaryAreDeterministic() {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        var events: [Int] = []
        for value in 0..<64 {
            _OpenInvalidationScheduler.enqueue {
                events.append(value)
                if value == 31 {
                    _OpenInvalidationScheduler.enqueue { events.append(64) }
                }
            }
        }

        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        XCTAssertEqual(events, Array(0..<64))
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        XCTAssertEqual(events, Array(0...64))
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)
    }

    func testHostClockSchedulerActionIsNotDuplicatedByReentrantHostStep() {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        var deliveries = 0
        _OpenInvalidationScheduler.enqueue {
            deliveries += 1
            if deliveries == 1 {
                OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
            }
        }

        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        XCTAssertEqual(deliveries, 1, "one queued action must not re-enter itself")
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)
    }

    func testNativeTaskSchedulerActionIsNotDuplicatedByHostStep() async {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = false
        defer { OpenUIKit.Timer._reset() }

        var deliveries = 0
        _OpenInvalidationScheduler.enqueue {
            deliveries += 1
            OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        }

        await Task.yield()
        await Task.yield()
        XCTAssertEqual(deliveries, 1)
    }

    func testHostClockGraphKeepsPublicationDuringReentrantEvaluationForNextTurn() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let model = ObservationModel(0)
        var reenterDuringNextBody = false
        let controller = UIHostingController(
            rootView: ReentrantObservationFixture(model: model) {
                guard reenterDuringNextBody else { return }
                reenterDuringNextBody = false
                model.value = 2
                OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
            }
        )
        let host = try XCTUnwrap(controller.view)
        host.layoutIfNeeded()

        reenterDuringNextBody = true
        model.value = 1
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)

        XCTAssertEqual(
            controller._openGraphInvalidationCount,
            1,
            "a publication during evaluation belongs to the next host turn"
        )
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
        XCTAssertEqual(controller._openGraphInvalidationCount, 2)
        XCTAssertEqual(texts(in: host), ["reentrant=2"])
    }

    func testBindingRoundTripsAndWritableDynamicMember() {
        struct FormValue: Equatable {
            var count: Int
            var title: String
        }

        var storage = FormValue(count: 1, title: "one")
        let binding = SwiftUI.Binding<FormValue>(
            get: { storage },
            set: { storage = $0 }
        )

        XCTAssertEqual(binding.wrappedValue, storage)
        binding.wrappedValue = FormValue(count: 2, title: "two")
        XCTAssertEqual(storage, FormValue(count: 2, title: "two"))

        binding.count.wrappedValue = 7
        XCTAssertEqual(storage, FormValue(count: 7, title: "two"))
        XCTAssertEqual(binding.projectedValue.title.wrappedValue, "two")

        let reprojected = SwiftUI.Binding(projectedValue: binding)
        reprojected.title.wrappedValue = "projected"
        XCTAssertEqual(storage, FormValue(count: 7, title: "projected"))
    }

    func testWrappersRetainSystemCompatibleNonisolatedConstruction() {
        let box = NonisolatedStorageBox()
        let binding = makeNonisolatedBinding(storage: box)
        binding.wrappedValue = 8
        XCTAssertEqual(box.value, 8)

        let state = makeNonisolatedState()
        state.wrappedValue = 9
        XCTAssertEqual(state.projectedValue.wrappedValue, 9)

        let model = ObservationModel(4)
        let observed = makeNonisolatedObservedObject(model)
        XCTAssertTrue(observed.wrappedValue === model)
    }

    func testObservedObjectUsesThePlatformCombineIdentity() {
        let model = ObservationModel(3)

        func acceptsCombineObject<T: Combine.ObservableObject>(_ value: T) {
            _ = value
        }
        func acceptsCombinePublisher(
            _ value: Combine.Published<Int>.Publisher
        ) {
            _ = value
        }

        acceptsCombineObject(model)
        acceptsCombinePublisher(model.$value)
    }

    func testObservedObjectDeliversOneDeferredMainActorInvalidation() async throws {
        let model = ObservationModel(0)
        var projectedBinding: Binding<Int>?
        let controller = UIHostingController(
            rootView: ObservationFixture(model: model) {
                projectedBinding = $0
            }
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 220, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(controller._openGraphRenderCount, 1)
        XCTAssertEqual(controller._openGraphInvalidationCount, 0)
        XCTAssertEqual(controller._openGraphObservationCount, 1)
        XCTAssertEqual(texts(in: host), ["value=0", "again=0"])

        projectedBinding?.wrappedValue = 1
        XCTAssertEqual(model.value, 1, "projected binding must write the model")
        XCTAssertEqual(
            controller._openGraphRenderCount,
            1,
            "ObservableObject delivery is deferred to the next main-actor turn"
        )

        await drainMainActor()
        host.layoutIfNeeded()

        XCTAssertEqual(controller._openGraphRenderCount, 2)
        XCTAssertEqual(controller._openGraphInvalidationCount, 1)
        XCTAssertEqual(controller._openGraphObservationCount, 1)
        XCTAssertEqual(texts(in: host), ["value=1", "again=1"])
    }

    func testStateLocationSurvivesRecomputationAndRootReplacement() async throws {
        var binding: Binding<Int>?
        let controller = UIHostingController(
            rootView: StateFixture(initialValue: 2) { binding = $0 }
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 140, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(controller._openGraphStateCount, 1)
        XCTAssertEqual(texts(in: host), ["state=2"])

        binding?.wrappedValue = 7
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(controller._openGraphInvalidationCount, 1)
        XCTAssertEqual(texts(in: host), ["state=7"])

        controller.rootView = StateFixture(initialValue: 99) { binding = $0 }
        host.layoutIfNeeded()

        XCTAssertEqual(controller._openGraphStateCount, 1)
        XCTAssertEqual(
            texts(in: host),
            ["state=7"],
            "a same-identity root update must reuse retained State storage"
        )
        XCTAssertEqual(binding?.wrappedValue, 7)
    }

    func testSameTypeConditionalBranchesNeverStealState() async throws {
        var bindings: [String: Binding<Int>] = [:]
        let capture: @MainActor (String, Binding<Int>) -> Void = {
            bindings[$0] = $1
        }
        let controller = UIHostingController(
            rootView: SameTypeConditionalFixture(firstBranch: true, capture: capture)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 180, height: 44)
        host.layoutIfNeeded()

        bindings["first"]?.wrappedValue = 91
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["first=91"])

        bindings.removeAll()
        controller.rootView = SameTypeConditionalFixture(
            firstBranch: false,
            capture: capture
        )
        host.layoutIfNeeded()
        XCTAssertEqual(bindings["second"]?.wrappedValue, 22)
        XCTAssertEqual(texts(in: host), ["second=22"])

        bindings["second"]?.wrappedValue = 82
        await drainMainActor()
        bindings.removeAll()
        controller.rootView = SameTypeConditionalFixture(
            firstBranch: true,
            capture: capture
        )
        host.layoutIfNeeded()
        XCTAssertEqual(
            bindings["first"]?.wrappedValue,
            11,
            "state in a branch is destroyed while that branch is absent"
        )
    }

    func testOptionalTupleAndStackScopesProtectLaterSiblingState() async throws {
        var bindings: [String: Binding<Int>] = [:]
        let capture: @MainActor (String, Binding<Int>) -> Void = {
            bindings[$0] = $1
        }
        let controller = UIHostingController(
            rootView: OptionalStackFixture(showsOptional: true, capture: capture)
        )
        let host = try XCTUnwrap(controller.view)

        bindings["stable"]?.wrappedValue = 99
        await drainMainActor()
        XCTAssertEqual(controller._openGraphStateCount, 2)

        bindings.removeAll()
        controller.rootView = OptionalStackFixture(
            showsOptional: false,
            capture: capture
        )
        XCTAssertEqual(controller._openGraphStateCount, 1)
        XCTAssertEqual(
            bindings["stable"]?.wrappedValue,
            99,
            "removing an earlier optional must not shift a nested stack sibling"
        )
        _ = host
    }

    func testBuilderArrayCannotShiftStateAcrossItsStackBoundary() async throws {
        var bindings: [String: Binding<Int>] = [:]
        let capture: @MainActor (String, Binding<Int>) -> Void = {
            bindings[$0] = $1
        }
        let controller = UIHostingController(
            rootView: ArrayBoundaryFixture(
                leading: [
                    ArrayElement(name: "a", initialValue: 10),
                    ArrayElement(name: "b", initialValue: 20),
                ],
                capture: capture
            )
        )
        _ = try XCTUnwrap(controller.view)

        bindings["stable"]?.wrappedValue = 909
        await drainMainActor()
        XCTAssertEqual(controller._openGraphStateCount, 3)

        bindings.removeAll()
        controller.rootView = ArrayBoundaryFixture(
            leading: [ArrayElement(name: "b", initialValue: 20)],
            capture: capture
        )
        XCTAssertEqual(controller._openGraphStateCount, 2)
        XCTAssertEqual(
            bindings["stable"]?.wrappedValue,
            909,
            "a positional array shrinking must not renumber a later stack"
        )
    }

    func testDeferredBackgroundsKeepTheirParentTupleScopes() async throws {
        var bindings: [String: Binding<Int>] = [:]
        let controller = UIHostingController(
            rootView: DeferredBackgroundFixture {
                bindings[$0] = $1
            }
        )
        _ = try XCTUnwrap(controller.view)
        XCTAssertEqual(controller._openGraphStateCount, 2)
        XCTAssertEqual(bindings["leftBackground"]?.wrappedValue, 1)
        XCTAssertEqual(bindings["rightBackground"]?.wrappedValue, 2)

        bindings["rightBackground"]?.wrappedValue = 22
        await drainMainActor()
        XCTAssertEqual(bindings["leftBackground"]?.wrappedValue, 1)
        XCTAssertEqual(bindings["rightBackground"]?.wrappedValue, 22)
    }

    func testForEachStateFollowsTypedIDAcrossReorderAndDiesOnRemoval() async throws {
        let id1 = OpaqueElementID(rawValue: 1)
        let id2 = OpaqueElementID(rawValue: 2)
        let id3 = OpaqueElementID(rawValue: 3)
        var bindings: [String: Binding<Int>] = [:]
        let capture: @MainActor (String, Binding<Int>) -> Void = {
            bindings[$0] = $1
        }
        let controller = UIHostingController(
            rootView: ForEachFixture(
                elements: [
                    IdentifiedElement(id: id1, initialValue: 10),
                    IdentifiedElement(id: id2, initialValue: 20),
                    IdentifiedElement(id: id3, initialValue: 30),
                ],
                capture: capture
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 120)

        bindings["id2"]?.wrappedValue = 200
        await drainMainActor()
        bindings.removeAll()
        controller.rootView = ForEachFixture(
            elements: [
                IdentifiedElement(id: id3, initialValue: 3000),
                IdentifiedElement(id: id2, initialValue: 2000),
                IdentifiedElement(id: id1, initialValue: 1000),
            ],
            capture: capture
        )
        host.layoutIfNeeded()
        XCTAssertEqual(controller._openGraphStateCount, 3)
        XCTAssertEqual(bindings["id1"]?.wrappedValue, 10)
        XCTAssertEqual(bindings["id2"]?.wrappedValue, 200)
        XCTAssertEqual(bindings["id3"]?.wrappedValue, 30)
        XCTAssertEqual(texts(in: host), ["id3=30", "id2=200", "id1=10"])

        let removedBinding = bindings["id2"]
        bindings.removeAll()
        controller.rootView = ForEachFixture(
            elements: [
                IdentifiedElement(id: id3, initialValue: 30),
                IdentifiedElement(id: id1, initialValue: 10),
            ],
            capture: capture
        )
        XCTAssertEqual(controller._openGraphStateCount, 2)
        let invalidationsAfterRemoval = controller._openGraphInvalidationCount
        removedBinding?.wrappedValue = 999
        await drainMainActor()
        XCTAssertEqual(
            controller._openGraphInvalidationCount,
            invalidationsAfterRemoval,
            "a binding retained past element removal must be detached from the graph"
        )

        bindings.removeAll()
        controller.rootView = ForEachFixture(
            elements: [
                IdentifiedElement(id: id2, initialValue: 222),
                IdentifiedElement(id: id3, initialValue: 30),
                IdentifiedElement(id: id1, initialValue: 10),
            ],
            capture: capture
        )
        XCTAssertEqual(controller._openGraphStateCount, 3)
        XCTAssertEqual(
            bindings["id2"]?.wrappedValue,
            222,
            "removing an ID destroys its state before a later reinsertion"
        )
    }

    func testDynamicPropertyUpdateMutationIsVisibleToBodyOnEveryRender() throws {
        var values: [Int] = []
        let capture: @MainActor (Int) -> Void = { values.append($0) }
        let controller = UIHostingController(
            rootView: UpdatingPropertyFixture(capture: capture)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 180, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(values, [7])
        XCTAssertEqual(texts(in: host), ["updated=7"])

        controller.rootView = UpdatingPropertyFixture(capture: capture)
        host.layoutIfNeeded()
        XCTAssertEqual(
            values,
            [7, 7],
            "body must receive the mutated DynamicProperty value on each render"
        )
        XCTAssertEqual(texts(in: host), ["updated=7"])
    }

    func testCustomMirrorCannotHideStoredDynamicPropertyFromPreparation() throws {
        var values: [Int] = []
        let capture: @MainActor (Int) -> Void = { values.append($0) }
        let controller = UIHostingController(
            rootView: CustomMirroredUpdatingFixture(capture: capture)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 220, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(values, [7])
        XCTAssertEqual(texts(in: host), ["customUpdated=7"])

        controller.rootView = CustomMirroredUpdatingFixture(capture: capture)
        host.layoutIfNeeded()
        XCTAssertEqual(
            values,
            [7, 7],
            "runtime stored-field metadata must override an empty customMirror"
        )
        XCTAssertEqual(texts(in: host), ["customUpdated=7"])
    }

    func testAliasedClassDynamicPropertyUpdatesOncePerStructuralField() throws {
        let shared = AliasedClassUpdatingProperty()
        var values: [Int] = []
        let controller = UIHostingController(
            rootView: AliasedClassUpdatingFixture(
                first: shared,
                second: shared,
                capture: { values.append($0) }
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 220, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(shared.updateCount, 2)
        XCTAssertEqual(values, [22])
        XCTAssertEqual(
            texts(in: host),
            ["aliasUpdated=22"],
            "alias detection must be recursion-scoped, not render-wide"
        )

        let replacementShared = AliasedClassUpdatingProperty()
        controller.rootView = AliasedClassUpdatingFixture(
            first: replacementShared,
            second: replacementShared,
            capture: { values.append($0) }
        )
        host.layoutIfNeeded()
        XCTAssertEqual(replacementShared.updateCount, 2)
        XCTAssertEqual(
            values,
            [22, 22],
            "both oracle-shaped renders must observe two structural updates"
        )
    }

    func testReusedStatefulViewValueGetsOneLocationPerStructuralScope() throws {
        var bindings: [Binding<Int>] = []
        let controller = UIHostingController(
            rootView: ReusedStateFixture { bindings.append($0) }
        )
        _ = try XCTUnwrap(controller.view)

        XCTAssertEqual(controller._openGraphStateCount, 2)
        XCTAssertEqual(bindings.count, 2)
        let initialBindings = bindings
        initialBindings[0].wrappedValue = 7
        XCTAssertEqual(
            initialBindings.map(\.wrappedValue),
            [7, 1],
            "copies of one pre-mount State seed must attach independently"
        )
    }

    func testClassDynamicPropertyRecursivelyPreparesStateAndUpdatesBody() async throws {
        let recorder = DynamicUpdateRecorder()
        let property = ClassUpdatingProperty(source: 6, recorder: recorder)
        var binding: Binding<Int>?
        let controller = UIHostingController(
            rootView: ClassUpdatingPropertyFixture(property: property) {
                binding = $0
            }
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(controller._openGraphStateCount, 1)
        XCTAssertEqual(recorder.events, ["class"])
        XCTAssertEqual(texts(in: host), ["classUpdated=6"])

        binding?.wrappedValue = 16
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(controller._openGraphStateCount, 1)
        XCTAssertEqual(recorder.events, ["class", "class"])
        XCTAssertEqual(texts(in: host), ["classUpdated=16"])
    }

    func testDynamicPropertyWriteBackBalancesReferenceStorage() throws {
        weak var weakToken: DynamicPropertyLifetimeToken?
        var controller: UIHostingController<ReferenceBearingUpdatingPropertyFixture>?

        do {
            let token = DynamicPropertyLifetimeToken()
            weakToken = token
            controller = UIHostingController(
                rootView: ReferenceBearingUpdatingPropertyFixture(
                    property: ReferenceBearingUpdatingProperty(token: token)
                )
            )
            let host = try XCTUnwrap(controller?.view)
            host.frame = CGRect(x: 0, y: 0, width: 240, height: 44)
            host.layoutIfNeeded()
            XCTAssertEqual(texts(in: host), ["referenceUpdated=42"])
        }

        XCTAssertNotNil(weakToken)
        controller = nil
        XCTAssertNil(
            weakToken,
            "prepared DynamicProperty copies must balance reference ownership"
        )
    }

    func testNestedDynamicPropertiesPrepareUpdateAndTearDownRecursively() async throws {
        let model = ObservationModel(7)
        let recorder = DynamicUpdateRecorder()
        var stateBinding: Binding<Int>?
        var modelBinding: Binding<Int>?
        let capture: @MainActor (Binding<Int>, Binding<Int>) -> Void = {
            stateBinding = $0
            modelBinding = $1
        }
        let controller = UIHostingController(
            rootView: NestedDynamicBranchFixture(
                showsLeaf: true,
                model: model,
                recorder: recorder,
                capture: capture
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 260, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(recorder.events, ["inner", "outer"])
        XCTAssertEqual(controller._openGraphStateCount, 1)
        XCTAssertEqual(controller._openGraphObservationCount, 1)
        XCTAssertEqual(texts(in: host), ["nested=5/7/updated=5"])

        stateBinding?.wrappedValue = 15
        modelBinding?.wrappedValue = 17
        await drainMainActor()
        XCTAssertEqual(
            recorder.events,
            ["inner", "outer", "inner", "outer"],
            "nested and outer update() each execute exactly once per render"
        )
        XCTAssertEqual(controller._openGraphInvalidationCount, 1)
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["nested=15/17/updated=15"])

        controller.rootView = NestedDynamicBranchFixture(
            showsLeaf: false,
            model: model,
            recorder: recorder,
            capture: capture
        )
        XCTAssertEqual(controller._openGraphStateCount, 0)
        XCTAssertEqual(controller._openGraphObservationCount, 0)
        let invalidationsAfterRemoval = controller._openGraphInvalidationCount
        model.value = 99
        await drainMainActor()
        XCTAssertEqual(controller._openGraphInvalidationCount, invalidationsAfterRemoval)

        stateBinding = nil
        modelBinding = nil
        controller.rootView = NestedDynamicBranchFixture(
            showsLeaf: true,
            model: model,
            recorder: recorder,
            capture: capture
        )
        XCTAssertEqual(controller._openGraphStateCount, 1)
        XCTAssertEqual(controller._openGraphObservationCount, 1)
        XCTAssertEqual(stateBinding?.wrappedValue, 5)
        XCTAssertEqual(modelBinding?.wrappedValue, 99)
    }

    func testRootReplacementCancelsOldObservationAndControllerTearsDown() async throws {
        let oldModel = ObservationModel(1)
        let newModel = ObservationModel(2)
        var controller: UIHostingController<ObservationFixture>? = UIHostingController(
            rootView: ObservationFixture(model: oldModel)
        )
        _ = try XCTUnwrap(controller?.view)
        XCTAssertEqual(controller?._openGraphObservationCount, 1)

        controller?.rootView = ObservationFixture(model: newModel)
        let countAfterReplacement = try XCTUnwrap(controller?._openGraphInvalidationCount)

        oldModel.value = 10
        await drainMainActor()
        XCTAssertEqual(controller?._openGraphInvalidationCount, countAfterReplacement)

        newModel.value = 20
        await drainMainActor()
        XCTAssertEqual(controller?._openGraphInvalidationCount, countAfterReplacement + 1)

        let weakController = WeakReference(controller)
        controller = nil
        await drainMainActor()
        XCTAssertNil(
            weakController.value,
            "subscriptions must not retain the hosting controller"
        )

        // A model which outlives the controller can continue publishing after
        // teardown without touching a dead graph.
        newModel.value = 21
        await drainMainActor()
    }

    func testEnvironmentKeysObjectsAndNestedScopesReachPreparedBodies() throws {
        let service = EnvironmentService(41)
        var captured: [(String, EnvironmentService)] = []
        let controller = UIHostingController(
            rootView: EnvironmentFixture(service: service) {
                captured.append(($0, $1))
            }
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 80)
        host.layoutIfNeeded()

        XCTAssertEqual(captured.map(\.0), ["outer", "inner"])
        XCTAssertTrue(captured.allSatisfy { $0.1 === service })
        XCTAssertEqual(texts(in: host), ["outer=41", "inner=41"])

        let replacement = EnvironmentService(99)
        captured.removeAll()
        controller.rootView = EnvironmentFixture(service: replacement) {
            captured.append(($0, $1))
        }
        host.layoutIfNeeded()
        XCTAssertEqual(captured.map(\.0), ["outer", "inner"])
        XCTAssertTrue(captured.allSatisfy { $0.1 === replacement })
        XCTAssertEqual(texts(in: host), ["outer=99", "inner=99"])
    }

    @available(macOS 14.0, *)
    func testObservableEnvironmentReadsInvalidateCoalesceAndResubscribe() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let service = EnvironmentObservationService(1)
        let controller = UIHostingController(
            rootView: EnvironmentObservationFixture(service: service)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 260, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(texts(in: host), ["environmentObservation=1"])
        XCTAssertEqual(controller._openGraphRenderCount, 1)

        service.value = 2
        service.value = 3
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        XCTAssertEqual(controller._openGraphInvalidationCount, 0)

        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["environmentObservation=3"])
        XCTAssertEqual(controller._openGraphRenderCount, 2)
        XCTAssertEqual(controller._openGraphInvalidationCount, 1)

        // withObservationTracking is one-shot. The rebuilt graph must install
        // a fresh access list so a second mutation still reaches the host.
        service.value = 4
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["environmentObservation=4"])
        XCTAssertEqual(controller._openGraphRenderCount, 3)
        XCTAssertEqual(controller._openGraphInvalidationCount, 2)
    }

    @available(macOS 14.0, *)
    func testRetiredObservableEnvironmentCannotInvalidateReplacementTree() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let retired = EnvironmentObservationService(1)
        let current = EnvironmentObservationService(10)
        let controller = UIHostingController(
            rootView: EnvironmentObservationFixture(service: retired)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 260, height: 44)
        host.layoutIfNeeded()

        controller.rootView = EnvironmentObservationFixture(service: current)
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["environmentObservation=10"])
        XCTAssertEqual(controller._openGraphRenderCount, 2)

        retired.value = 2
        XCTAssertFalse(OpenUIKit.Timer._hasScheduledTimers)
        XCTAssertEqual(controller._openGraphInvalidationCount, 0)

        current.value = 11
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["environmentObservation=11"])
        XCTAssertEqual(controller._openGraphRenderCount, 3)
        XCTAssertEqual(controller._openGraphInvalidationCount, 1)
    }

    func testStateObjectRetainsStableIdentityObservesAndProjectsBindings() async throws {
        let original = ObservationModel(3)
        let replacementSeed = ObservationModel(90)
        var capturedModels: [ObservationModel] = []
        var binding: Binding<Int>?
        let capture: @MainActor (ObservationModel, Binding<Int>) -> Void = {
            capturedModels.append($0)
            binding = $1
        }
        let controller = UIHostingController(
            rootView: StateObjectFixture(model: original, capture: capture)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 44)
        host.layoutIfNeeded()

        XCTAssertTrue(capturedModels.last === original)
        XCTAssertEqual(controller._openGraphObservationCount, 1)
        XCTAssertEqual(texts(in: host), ["stateObject=3"])

        controller.rootView = StateObjectFixture(
            model: replacementSeed,
            capture: capture
        )
        host.layoutIfNeeded()
        XCTAssertTrue(capturedModels.last === original)
        XCTAssertEqual(texts(in: host), ["stateObject=3"])

        binding?.wrappedValue = 7
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertTrue(capturedModels.last === original)
        XCTAssertEqual(texts(in: host), ["stateObject=7"])
        XCTAssertEqual(controller._openGraphObservationCount, 1)
    }

    func testBindableProjectionMutatesTheOriginalReference() {
        let model = ObservationModel(5)
        let bindable = Bindable(wrappedValue: model)
        let value = bindable.projectedValue.value
        value.wrappedValue = 12
        XCTAssertEqual(model.value, 12)
        XCTAssertTrue(bindable.wrappedValue === model)
    }

    func testBuiltInEnvironmentActionsAndDefaultsAreCallable() throws {
        let values = EnvironmentValues()
        XCTAssertEqual(values.colorScheme, .light)
        XCTAssertTrue(values.isEnabled)
        XCTAssertFalse(values.accessibilityReduceMotion)
        XCTAssertEqual(values.displayScale, 1)

        var opened: URL?
        let action = OpenURLAction { url in
            opened = url
            return .handled
        }
        let url = try XCTUnwrap(URL(string: "https://example.invalid/path"))
        if case .handled = action(url) {} else {
            XCTFail("OpenURLAction did not return its handler result")
        }
        XCTAssertEqual(opened, url)

        var dismissed = false
        DismissAction { dismissed = true }()
        XCTAssertTrue(dismissed)
    }

    func testDisabledAndColorSchemeModifiersScopeDynamicEnvironment() throws {
        var captured: [(Bool, ColorScheme)] = []
        let controller = UIHostingController(
            rootView: Group {
                BuiltInEnvironmentLeaf {
                    captured.append(($0, $1))
                }
                .disabled(false)
            }
            .disabled(true)
            .colorScheme(.dark)
        )
        _ = try XCTUnwrap(controller.view)
        XCTAssertEqual(captured.count, 1)
        XCTAssertFalse(captured[0].0)
        XCTAssertEqual(captured[0].1, .dark)
    }

    func testAppStorageSharesAKeyAndSurvivesRootRecomputation() async throws {
        var first: Binding<Int>?
        var second: Binding<Int>?
        let capture: @MainActor (Binding<Int>, Binding<Int>) -> Void = {
            first = $0
            second = $1
        }
        let controller = UIHostingController(
            rootView: AppStorageFixture(capture: capture)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 44)
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["appStorage=1/1"])

        second?.wrappedValue = 8
        await drainMainActor()
        host.layoutIfNeeded()
        XCTAssertEqual(first?.wrappedValue, 8)
        XCTAssertEqual(texts(in: host), ["appStorage=8/8"])

        controller.rootView = AppStorageFixture(capture: capture)
        host.layoutIfNeeded()
        XCTAssertEqual(texts(in: host), ["appStorage=8/8"])
    }

    func testAnimationTransactionsReachTheMountedOpenUIKitGraph() async throws {
        var state: Binding<Int>?
        let explicit = Animation.spring(
            response: 0.4,
            dampingFraction: 0.8
        )
        let controller = UIHostingController(
            rootView: StateFixture(initialValue: 0) { state = $0 }
        )
        _ = try XCTUnwrap(controller.view)

        withAnimation(explicit) {
            state?.wrappedValue = 1
        }
        await drainMainActor()
        XCTAssertEqual(controller._openGraphLastAppliedAnimation, explicit)

        var animatedState: Binding<Int>?
        let implicit = Animation.easeInOut(duration: 0.2)
        let implicitController = UIHostingController(
            rootView: AnimatedStateFixture(animation: implicit) {
                animatedState = $0
            }
        )
        _ = try XCTUnwrap(implicitController.view)
        animatedState?.wrappedValue = 1
        await drainMainActor()
        XCTAssertEqual(
            implicitController._openGraphLastAppliedAnimation,
            implicit
        )
    }

    private func drainMainActor() async {
        // One yield runs the graph's queued invalidation; the second makes the
        // assertion insensitive to executor handoff details on either host.
        await Task.yield()
        await Task.yield()
    }

    private func texts(in root: UIView) -> [String] {
        descendants(of: root)
            .compactMap { $0 as? UILabel }
            .filter { $0.accessibilityIdentifier == "SwiftUI.Text" }
            .compactMap(\.text)
    }

    private func descendants(of root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants(of: $0) }
    }
}

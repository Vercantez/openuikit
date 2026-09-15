import Foundation
import ImagePlayground

// Identity View-overlay batches for the ImagePlayground SwiftUI surface.
// This slug declares no View types of its own, so each modifier is invoked
// on a probe View plus EmptyView. Linux renders EmptyView; no sheet is
// presented, no style or policy is applied, and the completion closures
// are never invoked. These calls pin the no-op identity behavior without
// inventing layout or generative-service success.

private struct ImagePlaygroundOverlayProbeView: View {
    var body: EmptyView { EmptyView() }
}

func testViewOverlayBatch01() {
    let probe = ImagePlaygroundOverlayProbeView()
    _ = probe.imagePlaygroundGenerationStyle(.animation)
    _ = EmptyView().imagePlaygroundGenerationStyle(.sketch, in: [.sketch])
    _ = probe.imagePlaygroundPersonalizationPolicy()
    _ = EmptyView().imagePlaygroundPersonalizationPolicy(.disabled)
    let environment = EnvironmentValues()
    precondition(environment.imagePlaygroundPersonalizationPolicy == .automatic)
    precondition(
        environment.imagePlaygroundAllowedGenerationStyles.map(\.id)
            == ImagePlaygroundStyle.all.map(\.id)
    )
}

func testViewOverlayBatch02() {
    let isPresented = Binding.constant(false)
    let sourceURL = URL(fileURLWithPath: "/tmp/imageplayground-batch02.png")
    var completed: [URL] = []
    var cancelled = false
    _ = ImagePlaygroundOverlayProbeView().imagePlaygroundSheet(
        isPresented: isPresented,
        concepts: [ImagePlaygroundConcept.text("a red bicycle")],
        sourceImage: Image(),
        onCompletion: { completed.append($0) },
        onCancellation: nil
    )
    _ = EmptyView().imagePlaygroundSheet(
        isPresented: isPresented,
        concepts: [],
        sourceImageURL: sourceURL,
        onCompletion: { completed.append($0) },
        onCancellation: { cancelled = true }
    )
    precondition(completed.isEmpty)
    precondition(!cancelled)
    let environment = EnvironmentValues()
    precondition(environment.imagePlaygroundSelectedGenerationStyle == .illustration)
    precondition(environment.supportsImagePlayground == false)
}

func testViewOverlayBatch03() {
    let isPresented = Binding.constant(true)
    let sourceURL = URL(fileURLWithPath: "/tmp/imageplayground-batch03.png")
    var completed: [URL] = []
    _ = ImagePlaygroundOverlayProbeView().imagePlaygroundSheet(
        isPresented: isPresented,
        concept: "a red bicycle",
        sourceImage: Image(),
        onCompletion: { completed.append($0) },
        onCancellation: nil
    )
    _ = EmptyView().imagePlaygroundSheet(
        isPresented: isPresented,
        concept: "sunset over water",
        sourceImageURL: sourceURL,
        onCompletion: { completed.append($0) },
        onCancellation: nil
    )
    precondition(completed.isEmpty)
}

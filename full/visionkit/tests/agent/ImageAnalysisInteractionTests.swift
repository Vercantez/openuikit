@_spi(OpenUIKitHost) import VisionKit
import Foundation

func testInteractionInitialization() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.delegate == nil)
    precondition(interaction.analysis == nil)
    final class Sink: ImageAnalysisInteractionDelegate {}
    let sink = Sink()
    let viaDelegate = ImageAnalysisInteraction(sink)
    precondition(viaDelegate.delegate === sink)
}

func testInteractionContentsRect() {
    final class RectSink: ImageAnalysisInteractionDelegate {
        var rect = CGRect(x: 1, y: 2, width: 3, height: 4)
        func contentsRect(for interaction: ImageAnalysisInteraction) -> CGRect {
            _ = interaction
            return rect
        }
    }
    let empty = ImageAnalysisInteraction()
    precondition(empty.contentsRect == .zero)
    empty.setContentsRectNeedsUpdate()
    precondition(empty.contentsRect == .zero)

    let sink = RectSink()
    let interaction = ImageAnalysisInteraction(sink)
    interaction.setContentsRectNeedsUpdate()
    precondition(interaction.contentsRect == sink.rect)
    sink.rect = CGRect(x: 9, y: 9, width: 1, height: 1)
    precondition(interaction.contentsRect.origin.x == 1)
    interaction.setContentsRectNeedsUpdate()
    precondition(interaction.contentsRect == sink.rect)
}

func testInteractionTextSurface() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.text.isEmpty)
    precondition(interaction.selectedText.isEmpty)
    precondition(interaction.selectedAttributedText.characters.isEmpty)
    precondition(!interaction.hasActiveTextSelection)
    interaction.analysis = ImageAnalysis.hostFixture(transcript: "abc", resultTypes: [.text])
    precondition(interaction.text == "abc")
    let range = interaction.text.startIndex..<interaction.text.endIndex
    interaction.selectedRanges = [range]
    precondition(interaction.hasActiveTextSelection)
    interaction.resetTextSelection()
    precondition(!interaction.hasActiveTextSelection)
    precondition(interaction.selectedRanges.isEmpty)
}

func testInteractionHitTests() {
    let interaction = ImageAnalysisInteraction()
    interaction.analysis = ImageAnalysis.hostFixture(transcript: "abc", resultTypes: [.text])
    let origin = CGPoint.zero
    precondition(!interaction.hasText(at: origin))
    precondition(!interaction.analysisHasText(at: origin))
    precondition(!interaction.hasDataDetector(at: origin))
    precondition(!interaction.hasInteractiveItem(at: origin))
    precondition(!interaction.hasSupplementaryInterface(at: origin))
    let away = CGPoint(x: 50, y: 50)
    precondition(!interaction.hasText(at: away))
}

func testInteractionSupplementaryInterface() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.isSupplementaryInterfaceHidden)
    precondition(!interaction.liveTextButtonVisible)
    precondition(!interaction.allowLongPressForDataDetectorsInTextMode)
    precondition(!interaction.selectableItemsHighlighted)
    interaction.setSupplementaryInterfaceHidden(false, animated: true)
    precondition(interaction.isSupplementaryInterfaceHidden == false)
    interaction.setSupplementaryInterfaceHidden(true, animated: false)
    precondition(interaction.isSupplementaryInterfaceHidden)
    interaction.allowLongPressForDataDetectorsInTextMode = true
    precondition(interaction.allowLongPressForDataDetectorsInTextMode)
    interaction.selectableItemsHighlighted = true
    precondition(interaction.selectableItemsHighlighted)
}

func testInteractionAnalysisProperty() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.analysis == nil)
    let analysis = ImageAnalysis.hostFixture(transcript: "code", resultTypes: [.machineReadableCode])
    interaction.analysis = analysis
    precondition(interaction.analysis === analysis)
    precondition(interaction.text == "code")
    interaction.analysis = nil
    precondition(interaction.analysis == nil)
    precondition(interaction.text.isEmpty)
}

func testInteractionSubjects() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction._hostSubject(at: .zero) == nil)
    precondition(interaction._hostSubjects().isEmpty)
    precondition(interaction.highlightedSubjects.isEmpty)
    let fixture = ImageAnalysisInteraction.Subject.hostFixture(
        bounds: CGRect(x: 1, y: 2, width: 3, height: 4)
    )
    precondition(fixture.bounds.width == 3)
    precondition(fixture.bounds.height == 4)
    let other = ImageAnalysisInteraction.Subject.hostFixture(
        bounds: CGRect(x: 0, y: 0, width: 1, height: 1)
    )
    precondition(fixture != other)
    precondition(fixture == fixture)
    precondition(fixture.hashValue == fixture.hashValue)
    var hasher = Hasher()
    fixture.hash(into: &hasher)
    other.hash(into: &hasher)
    _ = hasher.finalize()
    interaction.highlightedSubjects = [fixture]
    precondition(interaction.highlightedSubjects.count == 1)
    interaction.highlightedSubjects = []
    precondition(interaction.highlightedSubjects.isEmpty)
    let asyncPeek = interaction.subject(at:)
    _ = asyncPeek
}

func testSubjectUnavailable() {
    precondition(
        ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable
            == .imageUnavailable
    )
    _ = ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable.hashValue
    var hasher = Hasher()
    ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable.hash(into: &hasher)
    _ = hasher.finalize()
    let error: Error = ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable
    precondition(!error.localizedDescription.isEmpty)
    precondition(
        error.localizedDescription
            == ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable.localizedDescription
    )
}

func testInteractionDelegate() {
    final class InteractionSink: ImageAnalysisInteractionDelegate {}
    let sink = InteractionSink()
    let interaction = ImageAnalysisInteraction(sink)
    let origin = CGPoint.zero
    precondition(sink.interaction(interaction, shouldBeginAt: origin, for: .automatic) == false)
    sink.interaction(interaction, highlightSelectedItemsDidChange: true)
    sink.interaction(interaction, liveTextButtonDidChangeToVisible: true)
    sink.textSelectionDidChange(interaction)
    precondition(sink.contentsRect(for: interaction) == .zero)
}

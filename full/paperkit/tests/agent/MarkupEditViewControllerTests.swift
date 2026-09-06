import PaperKit
import Foundation

final class PaperKitEditDelegate: MarkupEditViewController.Delegate {
    var shapes: [ShapeConfiguration.Shape] = []
    var contents: [PaperMarkup] = []
    var lines: [(Bool, Bool)] = []
    var textboxes = 0

    func markupEditViewController(
        _ markupEditViewController: MarkupEditViewController,
        insertNewShape type: ShapeConfiguration.Shape
    ) {
        _ = markupEditViewController
        shapes.append(type)
    }

    func markupEditViewController(
        _ markupEditViewController: MarkupEditViewController,
        insertNewContents toInsert: PaperMarkup
    ) {
        _ = markupEditViewController
        contents.append(toInsert)
    }

    func markupEditViewController(
        _ markupEditViewController: MarkupEditViewController,
        insertNewLineWithStartMarker lineStartMarker: Bool,
        endMarker lineEndMarker: Bool
    ) {
        _ = markupEditViewController
        lines.append((lineStartMarker, lineEndMarker))
    }

    func markupEditViewControllerInsertNewTextbox(_ markupEditViewController: MarkupEditViewController) {
        _ = markupEditViewController
        textboxes += 1
    }
}

func testMarkupEditViewControllerInit() {
    let extra = UIMenuElement()
    let controller = MarkupEditViewController(
        supportedFeatureSet: .version1,
        additionalActions: [extra]
    )
    precondition(controller.supportedFeatureSet == FeatureSet.version1)
    controller.viewDidLoad()
}

func testMarkupEditViewControllerDelegateShape() {
    let controller = MarkupEditViewController(supportedFeatureSet: .latest)
    let delegate = PaperKitEditDelegate()
    controller.delegate = delegate
    controller.hostInsertNewShape(.chatBubble)
    precondition(delegate.shapes == [.chatBubble])
    precondition(controller.delegate === delegate)
}

func testMarkupEditViewControllerDelegateContents() {
    let controller = MarkupEditViewController(supportedFeatureSet: .latest)
    let delegate = PaperKitEditDelegate()
    controller.delegate = delegate
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 4, height: 4))
    markup.insertNewShape(
        configuration: ShapeConfiguration(type: .ellipse),
        frame: CGRect(x: 0, y: 0, width: 2, height: 2)
    )
    controller.hostInsertNewContents(markup)
    precondition(delegate.contents.count == 1)
    precondition(delegate.contents[0].featureSet.shapes.contains(.ellipse))
}

func testMarkupEditViewControllerDelegateLine() {
    let controller = MarkupEditViewController(supportedFeatureSet: .latest)
    let delegate = PaperKitEditDelegate()
    controller.delegate = delegate
    controller.hostInsertNewLine(startMarker: true, endMarker: true)
    precondition(delegate.lines.count == 1)
    precondition(delegate.lines[0].0)
    precondition(delegate.lines[0].1)
}

func testMarkupEditViewControllerDelegateTextbox() {
    let controller = MarkupEditViewController(supportedFeatureSet: .latest)
    let delegate = PaperKitEditDelegate()
    controller.delegate = delegate
    controller.hostInsertNewTextbox()
    precondition(delegate.textboxes == 1)
}

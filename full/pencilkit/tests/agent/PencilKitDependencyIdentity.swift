import PencilKit
import Foundation
import UIKit

/// Future clean EC2 probe. Isolated Linux hosts do not compile this file;
/// the sealed gate only checks that the declared modules are imported.
func pencilKitDependencyIdentityProbe() {
    let color = UIColor.black
    let ink = PKInk(.pen, color: color)
    precondition(ink.inkType == .pen)

    let tool = PKInkingTool(.pencil, color: color, width: 5)
    precondition(tool.width == 5)

    let drawing = PKDrawing()
    let rect = CGRect(x: 0, y: 0, width: 32, height: 16)
    let image = drawing.image(from: rect, scale: 1)
    _ = image.size

    let view = PKCanvasView(frame: rect)
    view.drawing = drawing
    let hosted: UIView = view
    _ = hosted.frame

    let window = UIWindow(frame: rect)
    _ = PKToolPicker.shared(for: window)

    let responder = UIResponder()
    _ = responder.pencilKitResponderState

    _ = Foundation.Data()
    _ = Foundation.Date()
}

import PaperKit
import Foundation
import PencilKit
import UIKit

/// Future clean EC2 probe. Isolated Linux hosts do not compile this file;
/// the sealed gate only checks that the declared modules are imported.
func paperKitDependencyIdentityProbe() {
    let markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 32, height: 32))
    let featureSet = FeatureSet.latest
    let controller = PaperMarkupViewController(markup: markup, supportedFeatureSet: featureSet)
    let tool: any PKTool = PKInkingTool(.pen)
    controller.drawingTool = tool
    let drawing = PKDrawing()
    var copy = markup
    copy.append(contentsOf: drawing)
    _ = copy.featureSet.contains(.drawing)

    let view = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
    controller.contentView = view
    _ = UIColor.black
    _ = Foundation.Data()
    _ = Foundation.Date()
}

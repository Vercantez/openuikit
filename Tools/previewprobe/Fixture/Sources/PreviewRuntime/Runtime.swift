@_spi(OpenUIKitPreview) import DeveloperToolsSupport
import PreviewClient
import UIKit

@main
struct PreviewRuntime {
    @MainActor
    static func main() {
        precondition(previewClientCompiled())

        weak var weakView: UIView?
        let viewPreview: DeveloperToolsSupport.Preview
        do {
            let view = UIView()
            weakView = view
            viewPreview = DeveloperToolsSupport.Preview(body: { [view] in view })
        }
        let viewRetained = weakView != nil
        precondition(viewRetained)
        print("preview.viewRetained=\(viewRetained)")
        let viewIdentity = viewPreview._openUIKitBody() as AnyObject === weakView
        precondition(viewIdentity)
        print("preview.viewIdentity=\(viewIdentity)")

        weak var weakController: UIViewController?
        let controllerPreview: DeveloperToolsSupport.Preview
        do {
            let controller = UIViewController()
            weakController = controller
            controllerPreview = DeveloperToolsSupport.Preview(
                body: { [controller] in controller }
            )
        }
        let controllerRetained = weakController != nil
        precondition(controllerRetained)
        print("preview.controllerRetained=\(controllerRetained)")
        let controllerIdentity =
            controllerPreview._openUIKitBody() as AnyObject === weakController
        precondition(controllerIdentity)
        print("preview.controllerIdentity=\(controllerIdentity)")
        print("PREVIEW_RUNTIME_OK")
    }
}

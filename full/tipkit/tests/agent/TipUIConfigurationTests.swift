@_spi(OpenUIKitHost) import TipKit
import Foundation

func testTipUIViewConfiguration() {
    let view = TipUIView(EligibleHostTip())
    precondition(view.tip.id == "eligible-host")
    view.cornerRadius = 8
    view.imageSize = CGSize(width: 12, height: 16)
    view.viewStyle = MiniTipViewStyle()
    precondition(view.cornerRadius == 8)
    precondition(view.imageSize.width == 12)
    precondition(view.imageSize.height == 16)
    let configuration = TipViewStyleConfiguration(tip: view.tip)
    _ = MiniTipViewStyle().makeBody(configuration: configuration)
}

func testTipUICollectionViewCellFrameInit() {
    let cell = TipUICollectionViewCell(
        frame: CGRect(x: 1, y: 2, width: 30, height: 40)
    )
    precondition(cell.frame.width == 30)
    precondition(cell.frame.height == 40)
    cell.cornerRadius = 3
    cell.imageSize = CGSize(width: 5, height: 6)
    cell.viewStyle = MiniTipViewStyle()
    _ = cell.configureTip(EligibleHostTip())
    precondition(cell.tip?.id == "eligible-host")
    precondition(cell.cornerRadius == 3)
    precondition(cell.imageSize.width == 5)
}

func testTipUICollectionViewCellCoderInit() {
    precondition(TipUICollectionViewCell(coder: TipKitHostCoder()) == nil)
}

func testTipUICollectionReusableViewFrameInit() {
    let view = TipUICollectionReusableView(
        frame: CGRect(x: 0, y: 0, width: 10, height: 20)
    )
    precondition(view.frame.height == 20)
    view.cornerRadius = 1
    view.imageSize = CGSize(width: 2, height: 3)
    view.viewStyle = MiniTipViewStyle()
    _ = view.configureTip(OptionsHostTip())
    precondition(view.tip?.id == "options-host")
}

func testTipUICollectionReusableViewCoderInit() {
    precondition(TipUICollectionReusableView(coder: TipKitHostCoder()) == nil)
}

func testTipUIPopoverViewControllerNibInit() {
    let controller = TipUIPopoverViewController(nibName: "TipPopover", bundle: nil)
    precondition(controller.nibName == "TipPopover")
    precondition(controller.bundle == nil)
    controller.imageSize = CGSize(width: 9, height: 9)
    controller.viewStyle = MiniTipViewStyle()
    controller.configure(EligibleHostTip())
    precondition(controller.tip?.id == "eligible-host")
    precondition(controller.imageSize.width == 9)
}

func testTipUIPopoverViewControllerCoderInit() {
    precondition(TipUIPopoverViewController(coder: TipKitHostCoder()) == nil)
}

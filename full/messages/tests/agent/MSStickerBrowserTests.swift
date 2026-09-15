import Foundation
import Messages

/// Isolated-host zero rect spelled with Foundation-only initializers.
/// (`CGRect(x:y:width:height:)` and `.zero` require CoreGraphics on the
/// current SDK, so tests use the Foundation-visible `origin:size:` form.)
func messagesZeroRect() -> CGRect {
    CGRect(
        origin: CGPoint(x: 0, y: 0),
        size: CGSize(width: 0, height: 0)
    )
}

final class MessagesCountingStickerSource: NSObject, MSStickerBrowserViewDataSource {
    var numberCalls = 0
    var stickerCalls = 0
    let stickers: [MSSticker]

    init(stickers: [MSSticker]) {
        self.stickers = stickers
        super.init()
    }

    func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        _ = stickerBrowserView
        numberCalls += 1
        return stickers.count
    }

    func stickerBrowserView(
        _ stickerBrowserView: MSStickerBrowserView,
        stickerAt index: Int
    ) -> MSSticker {
        _ = stickerBrowserView
        stickerCalls += 1
        return stickers[index]
    }
}

func testBrowserDefaultSizeRegular() {
    let view = MSStickerBrowserView(frame: CGRect(origin: CGPoint(x: 1, y: 2), size: CGSize(width: 3, height: 4)))
    precondition(view.stickerSize == .regular)
    precondition(view.frame.origin.x == 1)
    precondition(view.frame.size.width == 3)
    precondition(view.contentOffset.x == 0 && view.contentOffset.y == 0)
}

func testBrowserInitWithSize() {
    let view = MSStickerBrowserView(
        frame: messagesZeroRect(),
        stickerSize: .large
    )
    precondition(view.stickerSize == .large)
}

func testBrowserContentOffset() {
    let view = MSStickerBrowserView(frame: messagesZeroRect())
    view.contentOffset = CGPoint(x: 10, y: 20)
    precondition(view.contentOffset.x == 10)
    precondition(view.contentOffset.y == 20)
}

func testBrowserSetContentOffset() {
    let view = MSStickerBrowserView(frame: messagesZeroRect())
    view.setContentOffset(CGPoint(x: 4, y: 5), animated: true)
    precondition(view.contentOffset.x == 4)
    precondition(view.contentOffset.y == 5)
}

func testBrowserReloadQueriesDataSource() {
    let sticker = messagesMakePNGSticker()
    let source = MessagesCountingStickerSource(stickers: [sticker])
    let view = MSStickerBrowserView(frame: messagesZeroRect(), stickerSize: .small)
    view.dataSource = source
    view.reloadData()
    precondition(source.numberCalls == 1)
    precondition(source.stickerCalls == 1)
    precondition(view.linuxLoadedStickers.count == 1)
    precondition(view.linuxLoadedStickers.first === sticker)
}

func testBrowserReloadWithoutDataSource() {
    let view = MSStickerBrowserView(frame: messagesZeroRect())
    view.reloadData()
    precondition(view.linuxLoadedStickers.isEmpty)
}

func testBrowserViewControllerSize() {
    let controller = MSStickerBrowserViewController(stickerSize: .small)
    precondition(controller.stickerSize == .small)
    precondition(controller.stickerBrowserView.stickerSize == .small)
}

func testBrowserViewControllerHasView() {
    let controller = MSStickerBrowserViewController(stickerSize: .regular)
    precondition(controller.stickerBrowserView.dataSource === controller)
}

func testBrowserViewControllerDefaultStickerCount() {
    let controller = MSStickerBrowserViewController(stickerSize: .regular)
    precondition(controller.numberOfStickers(in: controller.stickerBrowserView) == 0)
    controller.stickerBrowserView.reloadData()
    precondition(controller.stickerBrowserView.linuxLoadedStickers.isEmpty)
}

func testStickerViewStoresSticker() {
    let sticker = messagesMakePNGSticker()
    let view = MSStickerView(
        frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 100)),
        sticker: sticker
    )
    precondition(view.sticker === sticker)
    view.sticker = nil
    precondition(view.sticker == nil)
}

func testStickerViewAnimationState() {
    let view = MSStickerView(frame: messagesZeroRect(), sticker: nil)
    precondition(view.isAnimating() == false)
    view.startAnimating()
    precondition(view.isAnimating() == true)
    view.stopAnimating()
    precondition(view.isAnimating() == false)
}

func testStickerViewAnimationDurationZero() {
    let view = MSStickerView(frame: messagesZeroRect(), sticker: messagesMakePNGSticker())
    precondition(view.animationDuration == 0)
}

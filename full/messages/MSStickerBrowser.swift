import Foundation

/// Data source for `MSStickerBrowserView`.
public protocol MSStickerBrowserViewDataSource: NSObjectProtocol {
    func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int
    func stickerBrowserView(
        _ stickerBrowserView: MSStickerBrowserView,
        stickerAt index: Int
    ) -> MSSticker
}

/// Sticker grid. Isolated host subclasses `NSObject` because `UIView` is
/// UIKit-owned. `contentInset` (`UIEdgeInsets`) is omitted for the same
/// reason.
open class MSStickerBrowserView: NSObject {
    public let stickerSize: MSStickerSize
    public var frame: CGRect
    public var contentOffset: CGPoint
    public weak var dataSource: (any MSStickerBrowserViewDataSource)?

    /// Stickers last returned by `reloadData()`. Empty until reload.
    public private(set) var linuxLoadedStickers: [MSSticker] = []

    public init(frame: CGRect) {
        self.frame = frame
        self.stickerSize = .regular
        self.contentOffset = .zero
        super.init()
    }

    public init(frame: CGRect, stickerSize: MSStickerSize) {
        self.frame = frame
        self.stickerSize = stickerSize
        self.contentOffset = .zero
        super.init()
    }

    open func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        _ = animated
        self.contentOffset = contentOffset
    }

    open func reloadData() {
        guard let dataSource else {
            linuxLoadedStickers = []
            return
        }
        let count = dataSource.numberOfStickers(in: self)
        guard count >= 0 else {
            linuxLoadedStickers = []
            return
        }
        var loaded: [MSSticker] = []
        loaded.reserveCapacity(count)
        if count > 0 {
            for index in 0..<count {
                loaded.append(dataSource.stickerBrowserView(self, stickerAt: index))
            }
        }
        linuxLoadedStickers = loaded
    }
}

/// Standard sticker-browser controller. Isolated host subclasses `NSObject`
/// rather than `UIViewController`. The controller is its browser's default
/// data source and reports zero stickers until subclassed.
open class MSStickerBrowserViewController: NSObject, MSStickerBrowserViewDataSource {
    public let stickerSize: MSStickerSize
    public let stickerBrowserView: MSStickerBrowserView

    public init(stickerSize: MSStickerSize) {
        self.stickerSize = stickerSize
        self.stickerBrowserView = MSStickerBrowserView(
            frame: .zero,
            stickerSize: stickerSize
        )
        super.init()
        stickerBrowserView.dataSource = self
    }

    open func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        _ = stickerBrowserView
        return 0
    }

    open func stickerBrowserView(
        _ stickerBrowserView: MSStickerBrowserView,
        stickerAt index: Int
    ) -> MSSticker {
        _ = stickerBrowserView
        _ = index
        preconditionFailure(
            "MSStickerBrowserViewController.stickerBrowserView(_:stickerAt:) requires a subclass when numberOfStickers is nonzero"
        )
    }
}

/// Sticker renderer. Isolated host subclasses `NSObject`. Animation is a
/// local flag; GIF frame timing is not decoded, so `animationDuration` is
/// always `0`.
open class MSStickerView: NSObject {
    public var frame: CGRect
    public var sticker: MSSticker?
    public var animationDuration: TimeInterval { 0 }

    private var animating = false

    public init(frame: CGRect, sticker: MSSticker?) {
        self.frame = frame
        self.sticker = sticker
        super.init()
    }

    open func startAnimating() {
        animating = true
    }

    open func stopAnimating() {
        animating = false
    }

    open func isAnimating() -> Bool {
        animating
    }
}

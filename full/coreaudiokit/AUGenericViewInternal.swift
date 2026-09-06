import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Swift overlay name for the generic AU parameter view's UIView base.
public typealias AUGenericViewInternalBase = UIView

/// Internal generic Audio Unit parameter collection view. Linux stores
/// `auAudioUnit`, `owningController`, `paramObserverToken`, and
/// `showSingleClumpIndex`. It never schedules a firing `Timer` (the host
/// gate has no run loop) and never renders parameter cells.
open class AUGenericViewInternal: AUGenericViewInternalBase {
    public var auAudioUnit: AUAudioUnit?
    public var owningController: UIViewController?
    public var paramObserverToken: AUParameterObserverToken?
    public var showSingleClumpIndex: Int?

    private var scheduledUpdatesTimerIsActive = false
    private var lastDisplayedItemIndexPath: IndexPath?
    private var lastDisplayedSupplementaryKind: String?
    private var lastDisplayedSupplementaryIndexPath: IndexPath?
    private var lastTraitCollection: UITraitCollection?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        lastTraitCollection = previousTraitCollection
        super.traitCollectionDidChange(previousTraitCollection)
    }

    public override func removeFromSuperview() {
        removeScheduledUpdatesTimer()
        super.removeFromSuperview()
    }

    /// Darwin invalidates the parameter-refresh timer. Linux clears the
    /// host-visible scheduled flag and never fires a callback.
    public func removeScheduledUpdatesTimer() {
        scheduledUpdatesTimerIsActive = false
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplaySupplementaryView view: UICollectionReusableView,
        forElementKind elementKind: String,
        at indexPath: IndexPath
    ) {
        _ = collectionView
        _ = view
        lastDisplayedSupplementaryKind = elementKind
        lastDisplayedSupplementaryIndexPath = indexPath
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay item: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        _ = collectionView
        _ = item
        lastDisplayedItemIndexPath = indexPath
    }

    var hostScheduledUpdatesTimerIsActive: Bool { scheduledUpdatesTimerIsActive }

    func hostArmScheduledUpdatesTimer() {
        scheduledUpdatesTimerIsActive = true
    }

    var hostLastDisplayedItemIndexPath: IndexPath? { lastDisplayedItemIndexPath }

    var hostLastDisplayedSupplementaryKind: String? { lastDisplayedSupplementaryKind }

    var hostLastDisplayedSupplementaryIndexPath: IndexPath? {
        lastDisplayedSupplementaryIndexPath
    }

    var hostLastTraitCollection: UITraitCollection? { lastTraitCollection }
}

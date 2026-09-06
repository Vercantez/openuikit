import Foundation
import CoreAudioKit
@_spi(OpenUIKitHost) import CoreAudioKit

func testAUGenericViewInternalClass() {
    let view = AUGenericViewInternal(frame: .zero)
    let asView: UIView = view
    precondition(asView === view)
    precondition(AUGenericViewInternalBase.self == UIView.self)
    precondition(type(of: view) == AUGenericViewInternal.self)
}

func testAUGenericViewInternalInitFrame() {
    let frame = CGRect(x: 8, y: 16, width: 320, height: 480)
    let view = AUGenericViewInternal(frame: frame)
    precondition(view.frame.origin.x == 8)
    precondition(view.frame.origin.y == 16)
    precondition(view.frame.width == 320)
    precondition(view.frame.height == 480)
    precondition(view.auAudioUnit == nil)
    precondition(view.owningController == nil)
    precondition(view.paramObserverToken == nil)
    precondition(view.showSingleClumpIndex == nil)
}

func testAUGenericViewInternalInitCoder() {
    let encoder = NSKeyedArchiver(requiringSecureCoding: false)
    encoder.finishEncoding()
    let decoder = try! NSKeyedUnarchiver(forReadingFrom: encoder.encodedData)
    decoder.requiresSecureCoding = false
    let view = AUGenericViewInternal(coder: decoder)
    precondition(view != nil)
    precondition(view?.frame == .zero)
    precondition(view?.auAudioUnit == nil)
    precondition(view?.showSingleClumpIndex == nil)
}

func testAUGenericViewInternalRemoveFromSuperview() {
    let parent = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    let view = AUGenericViewInternal(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    parent.addSubview(view)
    precondition(view.superview === parent)
    CoreAudioKitHostControl.armScheduledUpdatesTimer(view)
    precondition(CoreAudioKitHostControl.scheduledUpdatesTimerIsActive(view))
    view.removeFromSuperview()
    precondition(view.superview == nil)
    precondition(CoreAudioKitHostControl.scheduledUpdatesTimerIsActive(view) == false)
}

func testAUGenericViewInternalRemoveScheduledUpdatesTimer() {
    let view = AUGenericViewInternal(frame: .zero)
    precondition(CoreAudioKitHostControl.scheduledUpdatesTimerIsActive(view) == false)
    CoreAudioKitHostControl.armScheduledUpdatesTimer(view)
    precondition(CoreAudioKitHostControl.scheduledUpdatesTimerIsActive(view))
    view.removeScheduledUpdatesTimer()
    precondition(CoreAudioKitHostControl.scheduledUpdatesTimerIsActive(view) == false)
    view.removeScheduledUpdatesTimer()
    precondition(CoreAudioKitHostControl.scheduledUpdatesTimerIsActive(view) == false)
}

func testAUGenericViewInternalTraitCollectionDidChange() {
    let view = AUGenericViewInternal(frame: .zero)
    precondition(CoreAudioKitHostControl.lastTraitCollection(view) == nil)
    let previous = UITraitCollection()
    view.traitCollectionDidChange(previous)
    precondition(CoreAudioKitHostControl.lastTraitCollection(view) === previous)
    view.traitCollectionDidChange(nil)
    precondition(CoreAudioKitHostControl.lastTraitCollection(view) == nil)
}

func testAUGenericViewInternalAuAudioUnit() {
    let view = AUGenericViewInternal(frame: .zero)
    precondition(view.auAudioUnit == nil)
    let unit = AUAudioUnit()
    view.auAudioUnit = unit
    precondition(view.auAudioUnit === unit)
    view.auAudioUnit = nil
    precondition(view.auAudioUnit == nil)
}

func testAUGenericViewInternalOwningController() {
    let view = AUGenericViewInternal(frame: .zero)
    precondition(view.owningController == nil)
    let owner = AUGenericViewController()
    view.owningController = owner
    precondition(view.owningController === owner)
    view.owningController = nil
    precondition(view.owningController == nil)
}

func testAUGenericViewInternalParamObserverToken() {
    let view = AUGenericViewInternal(frame: .zero)
    precondition(view.paramObserverToken == nil)
    let token = UnsafeMutableRawPointer(bitPattern: 0xCA)!
    view.paramObserverToken = token
    precondition(view.paramObserverToken == token)
    view.paramObserverToken = nil
    precondition(view.paramObserverToken == nil)
}

func testAUGenericViewInternalShowSingleClumpIndex() {
    let view = AUGenericViewInternal(frame: .zero)
    precondition(view.showSingleClumpIndex == nil)
    view.showSingleClumpIndex = 0
    precondition(view.showSingleClumpIndex == 0)
    view.showSingleClumpIndex = 3
    precondition(view.showSingleClumpIndex == 3)
    view.showSingleClumpIndex = nil
    precondition(view.showSingleClumpIndex == nil)
}

func testAUGenericViewInternalCollectionViewWillDisplay() {
    let host = AUGenericViewInternal(frame: .zero)
    let collection = UICollectionView(frame: .zero)
    let cell = UICollectionViewCell(frame: .zero)
    let indexPath = IndexPath(indexes: [1, 4])
    precondition(CoreAudioKitHostControl.lastDisplayedItemIndexPath(host) == nil)
    host.collectionView(collection, willDisplay: cell, forItemAt: indexPath)
    precondition(CoreAudioKitHostControl.lastDisplayedItemIndexPath(host) == indexPath)
}

func testAUGenericViewInternalCollectionViewWillDisplaySupplementary() {
    let host = AUGenericViewInternal(frame: .zero)
    let collection = UICollectionView(frame: .zero)
    let supplementary = UICollectionReusableView(frame: .zero)
    let indexPath = IndexPath(indexes: [2, 0])
    host.collectionView(
        collection,
        willDisplaySupplementaryView: supplementary,
        forElementKind: UICollectionView.elementKindSectionHeader,
        at: indexPath
    )
    precondition(
        CoreAudioKitHostControl.lastDisplayedSupplementaryKind(host)
            == UICollectionView.elementKindSectionHeader
    )
    precondition(
        CoreAudioKitHostControl.lastDisplayedSupplementaryIndexPath(host) == indexPath
    )
}

func testAUGenericViewInternalBaseTypealias() {
    precondition(AUGenericViewInternalBase.self == UIView.self)
    let view: AUGenericViewInternalBase = AUGenericViewInternal(frame: .zero)
    precondition(type(of: view) == AUGenericViewInternal.self)
}

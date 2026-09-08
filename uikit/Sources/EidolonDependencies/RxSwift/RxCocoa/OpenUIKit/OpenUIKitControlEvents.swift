// OpenUIKit adapter derived from RxCocoa 4.1.2 UIControl+Rx.swift (MIT,
// Copyright 2015 Krunoslav Zaher; THIRD_PARTY_LICENSES/Eidolon-RxSwift-LICENSE.md).
// The pinned upstream sources stay unchanged.
// RxCocoa 4.1.2 selects NSControl on macOS, including the Apple-toolchain
// guest route. Eidolon 44486ed calls UIButton.rx.tap in three source files.
#if os(macOS) && canImport(OpenUIKit)
import OpenUIKit
import RxSwift

@MainActor
extension Reactive where Base: OpenUIKit.UIControl {
    // MEASURED EidolonTap, iPhone 16 / iOS 26.1, pinned RxCocoa 4.1.2:
    // no initial value; unrelated events 0; touchUpInside 1 per subscriber;
    // disposal removes the event registration; deallocation completes once.
    // fixtures/realapp/eidolon/tap-oracle.json carries all 16 measured cases.
    // The port's closure registration replaces RxCocoa's iOS ControlTarget;
    // the observable, weak ownership and ControlEvent scheduler remain real Rx.
    public func controlEvent(_ controlEvents: OpenUIKit.UIControl.Event) -> ControlEvent<Void> {
        let source: Observable<Void> = Observable.create { [weak control = self.base] observer in
            MainScheduler.ensureExecutingOnScheduler()
            guard let control = control else {
                observer.on(.completed)
                return Disposables.create()
            }
            let token = control.addTarget(for: controlEvents) { _, _ in
                observer.on(.next(()))
            }
            return Disposables.create { [weak control] in
                control?.removeTarget(token)
            }
        }.takeUntil(deallocated)
        return ControlEvent(events: source)
    }
}

@MainActor
extension Reactive where Base: OpenUIKit.UIButton {
    public var tap: ControlEvent<Void> { controlEvent(.touchUpInside) }
}
#endif

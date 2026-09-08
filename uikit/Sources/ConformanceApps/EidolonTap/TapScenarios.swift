import Foundation
import UIKit
import RxSwift
import RxCocoa

// Shared verbatim by the iOS oracle and the port tests. These are explicit
// sendActions calls; this probe does not simulate a finger or network service.
@MainActor
func eidolonTapScenarios() -> [[String: Any]] {
    var rows: [[String: Any]] = []
    weak var bareButton: UIButton?
    autoreleasepool {
        let value = UIButton(type: .custom)
        bareButton = value
    }
    rows.append(["case": "button-without-rx", "released": bareButton == nil])
    weak var weakParent: UIView?
    let child = UIView()
    autoreleasepool {
        let parent = UIView()
        weakParent = parent
        parent.addSubview(child)
    }
    rows.append(["case": "child-does-not-retain-parent", "parentReleased": weakParent == nil,
                 "superviewCleared": child.superview == nil])
    weak var weakChild: UIView?
    let owner = UIView()
    autoreleasepool {
        let value = UIView()
        weakChild = value
        owner.addSubview(value)
    }
    let childRetainedWhileAttached = weakChild != nil
    // Drain UIKit's autoreleased references before inspecting ownership.
    autoreleasepool { weakChild?.removeFromSuperview() }
    rows.append(["case": "parent-retains-child-until-removal",
                 "retainedWhileAttached": childRetainedWhileAttached,
                 "releasedAfterRemoval": weakChild == nil])
    let button = UIButton(type: .custom)
    var first = 0, second = 0, completions = 0, errors = 0
    var onMain = true
    let a = button.rx.tap.subscribe(onNext: {
        first += 1; onMain = onMain && Thread.isMainThread
    }, onError: { _ in errors += 1 }, onCompleted: { completions += 1 })
    let b = button.rx.tap.subscribe(onNext: { second += 1 })
    func record(_ name: String) {
        rows.append(["case": name, "first": first, "second": second,
                     "completed": completions, "errors": errors, "onMain": onMain,
                     "events": Int(button.allControlEvents.rawValue)])
    }
    record("subscribe")
    button.sendActions(for: .touchDown)
    button.sendActions(for: .touchUpOutside)
    button.sendActions(for: .valueChanged)
    record("unrelated-events")
    button.sendActions(for: .touchUpInside)
    record("touch-up-inside")
    button.sendActions(for: [.touchUpInside, .valueChanged])
    record("combined-events")
    button.isEnabled = false
    button.sendActions(for: .touchUpInside)
    record("disabled-explicit-send")
    a.dispose()
    button.sendActions(for: .touchUpInside)
    record("dispose-first")
    a.dispose()
    b.dispose()
    button.sendActions(for: .touchUpInside)
    record("dispose-all")

    let control = UIControl()
    var down = 0
    let d = control.rx.controlEvent(.touchDown).subscribe(onNext: { down += 1 })
    control.sendActions(for: .touchUpInside)
    control.sendActions(for: .touchDown)
    d.dispose()
    control.sendActions(for: .touchDown)
    rows.append(["case": "control-event-filter", "next": down,
                 "events": Int(control.allControlEvents.rawValue)])
    var union = 0
    let multiple = control.rx.controlEvent([.touchDown, .touchUpInside])
        .subscribe(onNext: { union += 1 })
    control.sendActions(for: .touchDown)
    control.sendActions(for: .touchUpInside)
    let individual = union
    control.sendActions(for: [.touchDown, .touchUpInside])
    let combined = union
    multiple.dispose()
    control.sendActions(for: [.touchDown, .touchUpInside])
    rows.append(["case": "control-event-union", "individual": individual,
                 "combined": combined, "disposed": union,
                 "events": Int(control.allControlEvents.rawValue)])

    var taken = 0, takeCompleted = 0
    let take = button.rx.tap.take(1).subscribe(onNext: { taken += 1 },
                                              onCompleted: { takeCompleted += 1 })
    button.sendActions(for: .touchUpInside)
    button.sendActions(for: .touchUpInside)
    rows.append(["case": "dispose-during-delivery", "next": taken,
                 "completed": takeCompleted, "events": Int(button.allControlEvents.rawValue)])
    take.dispose()

    var lifetimeNext = 0, lifetimeCompleted = 0
    weak var weakButton: UIButton?
    var stream: ControlEvent<Void>!
    var subscription: Disposable!
    autoreleasepool {
        let ephemeral = UIButton(type: .custom)
        weakButton = ephemeral
        stream = ephemeral.rx.tap
        subscription = stream.subscribe(onNext: { lifetimeNext += 1 },
                                        onCompleted: { lifetimeCompleted += 1 })
        ephemeral.sendActions(for: .touchUpInside)
    }
    rows.append(["case": "deallocate-subscribed-control", "released": weakButton == nil,
                 "next": lifetimeNext, "completed": lifetimeCompleted])
    var lateNext = 0, lateCompleted = 0
    let late = stream.subscribe(onNext: { lateNext += 1 }, onCompleted: { lateCompleted += 1 })
    rows.append(["case": "subscribe-after-deallocation", "next": lateNext,
                 "completed": lateCompleted])
    late.dispose(); subscription.dispose()

    final class Payload {}
    weak var weakPayload: Payload?
    var retainedSubscription: Disposable!
    autoreleasepool {
        let payload = Payload()
        weakPayload = payload
        retainedSubscription = button.rx.tap.subscribe(onNext: { _ = payload })
    }
    let retainedBeforeDispose = weakPayload != nil
    retainedSubscription.dispose()
    rows.append(["case": "dispose-releases-observer", "retainedBeforeDispose": retainedBeforeDispose,
                 "releasedAfterDispose": weakPayload == nil,
                 "events": Int(button.allControlEvents.rawValue)])
    return rows
}

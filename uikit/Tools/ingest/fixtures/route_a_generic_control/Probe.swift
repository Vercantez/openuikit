import Foundation
import UIKit
import Combine

// Run with the complete upstream Combine+UIControl.swift on both platforms.
// No fixture implements eventHandler or substitutes a publisher/subscription.
private final class LimitedSubscriber<Input>: Subscriber {
    typealias Failure = Never
    var subscription: Subscription?
    var inputs: [Input] = []
    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.max(1))
    }
    func receive(_ input: Input) -> Subscribers.Demand {
        inputs.append(input)
        return .none
    }
    func receive(completion: Subscribers.Completion<Never>) {}
}

@MainActor
func genericControlMeasurement() -> [String: Any] {
    var result: [String: Any] = [:]
    let control = UIControl(frame: .zero)
    var received: [UIControl] = []
    let sink = control.publisher(event: .touchUpInside).sink { received.append($0) }
    control.sendActions(for: .valueChanged)
    result["sink_after_wrong_event"] = received.count
    for _ in 0..<3 { control.sendActions(for: .touchUpInside) }
    result["sink_after_matching_events"] = received.count
    result["sink_identity"] = received.map { $0 === control }
    sink.cancel()
    control.sendActions(for: .touchUpInside)
    result["sink_after_cancel"] = received.count

    // A second Control specialization with a state-bearing sender.
    let toggle = UISwitch(frame: .zero)
    var toggleStates: [Bool] = []
    var toggleIdentity: [Bool] = []
    let toggleSink = UIControlPublisher(control: toggle, event: .valueChanged).sink {
        toggleStates.append($0.isOn)
        toggleIdentity.append($0 === toggle)
    }
    toggle.isOn = true
    toggle.sendActions(for: .valueChanged)
    toggle.isOn = false
    toggle.sendActions(for: .valueChanged)
    toggle.sendActions(for: .touchUpInside)
    toggleSink.cancel()
    toggle.sendActions(for: .valueChanged)
    result["switch_states"] = toggleStates
    result["switch_identity"] = toggleIdentity

    // A different Subscriber specialization; preserve the app's measured
    // behavior even though its request(_:) deliberately ignores demand.
    let button = UIButton(frame: .zero)
    let limited = LimitedSubscriber<UIButton>()
    UIControlPublisher(control: button, event: .touchDown).subscribe(limited)
    button.sendActions(for: .touchUpInside)
    result["limited_after_wrong_event"] = limited.inputs.count
    for _ in 0..<2 { button.sendActions(for: .touchDown) }
    result["limited_after_two_events_requesting_one"] = limited.inputs.count
    result["limited_identity"] = limited.inputs.map { $0 === button }
    limited.subscription?.cancel()
    button.sendActions(for: .touchDown)
    result["limited_after_cancel"] = limited.inputs.count
    withExtendedLifetime((sink, toggleSink, limited)) {}
    return result
}

#if os(iOS)
@main
final class RouteAGenericControlOracle: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let measurement = genericControlMeasurement()
            // Inspect the registered selector separately; the port does not
            // expose this native runtime introspection API.
            let control = UIControl(frame: .zero)
            let subscriber = LimitedSubscriber<UIControl>()
            let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: .touchUpInside)
            // Do not use allTargets: iOS 26.1's Set<AnyHashable> bridge traps
            // casting this pure Swift generic target to NSObject.
            let names = control.actions(forTarget: subscription, forControlEvent: .touchUpInside) ?? []
            withExtendedLifetime(subscription) {}
            let oracle: [String: Any] = ["measurement": measurement,
                                        "registered_selectors": names,
                                        "system_version": UIDevice.current.systemVersion,
                                        "scale": UIScreen.main.scale]
            try JSONSerialization.data(withJSONObject: oracle, options: [.prettyPrinted, .sortedKeys])
                .write(to: documents.appendingPathComponent("oracle.json"))
            exit(0)
        } catch { fatalError("oracle write: \(error)") }
    }
}
#else
@main
struct RouteAGenericControlLinux {
    @MainActor static func main() throws {
        let result = genericControlMeasurement()
        let data = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
#endif

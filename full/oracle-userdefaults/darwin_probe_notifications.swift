// Measure the notification contract separately from value/persistence rules:
// exact name, synchronous delivery, sender identity, and which mutation APIs
// publish even when the resulting value is unchanged.

import Foundation

let suite = "OpenUIKit.NotificationOracle.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
let center = NotificationCenter.default
var events: [(String, AnyObject?)] = []
let token = center.addObserver(
    forName: UserDefaults.didChangeNotification,
    object: nil,
    queue: nil
) { note in
    let object = note.object as AnyObject?
    events.append(("event", object))
    print(
        "event objectNil=\(note.object == nil) " +
            "objectIsDefaults=\(object === defaults) " +
            "name=\(note.name.rawValue)"
    )
}

func step(_ label: String, _ body: () -> Void) {
    let before = events.count
    body()
    print("step \(label) delta=\(events.count - before)")
}

print("constant=\(UserDefaults.didChangeNotification.rawValue)")
step("set-new") { defaults.set(1, forKey: "k") }
step("set-same") { defaults.set(1, forKey: "k") }
step("remove-existing") { defaults.removeObject(forKey: "k") }
step("remove-missing") { defaults.removeObject(forKey: "k") }
step("register") { defaults.register(defaults: ["r": 1]) }
step("add-suite") { defaults.addSuite(named: "x") }
step("remove-suite") { defaults.removeSuite(named: "x") }
step("set-persistent") {
    defaults.setPersistentDomain(["p": 1], forName: suite)
}
step("remove-persistent") {
    defaults.removePersistentDomain(forName: suite)
}
step("set-volatile") {
    defaults.setVolatileDomain(["v": 1], forName: "volatile")
}
step("remove-volatile") {
    defaults.removeVolatileDomain(forName: "volatile")
}
step("synchronize") { _ = defaults.synchronize() }
center.removeObserver(token)
defaults.removePersistentDomain(forName: suite)

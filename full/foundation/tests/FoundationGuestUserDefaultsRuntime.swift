import Foundation
import FoundationGuestServices

struct StoredReminder: Codable, Equatable {
    let id: String
    let title: String
    let created: Date
    let complete: Bool
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(2)
    }
}

guard CommandLine.arguments.count == 3 else { exit(64) }
let mode = CommandLine.arguments[1]
let suite = CommandLine.arguments[2]
let defaults = FoundationGuestServices.UserDefaults(suiteName: suite)!

switch mode {
case "semantics":
    defaults.removePersistentDomain(forName: suite)
    var notificationCount = 0
    let notificationToken = NotificationCenter.default.addObserver(
        forName: FoundationGuestServices.UserDefaults.didChangeNotification,
        object: defaults,
        queue: nil
    ) { notification in
        require(
            (notification.object as AnyObject?) === defaults,
            "did-change notification object identity"
        )
        notificationCount += 1
    }
    defaults.set(1, forKey: "notification")
    defaults.set(1, forKey: "notification")
    defaults.removeObject(forKey: "notification")
    defaults.removeObject(forKey: "notification")
    require(notificationCount == 4, "did-change notification per mutation")
    require(
        FoundationGuestServices.UserDefaults.didChangeNotification.rawValue ==
            "NSUserDefaultsDidChangeNotification",
        "did-change notification name"
    )
    NotificationCenter.default.removeObserver(notificationToken)
    defaults.register(defaults: ["fallback": "registered", "registeredInt": 7])
    require(defaults.object(forKey: "missing") == nil, "absent object")
    require(defaults.integer(forKey: "missing") == 0, "absent integer")
    require(defaults.bool(forKey: "missing") == false, "absent bool")
    defaults.set("set", forKey: "fallback")
    require(defaults.string(forKey: "fallback") == "set", "stored beats registered")
    defaults.removeObject(forKey: "fallback")
    require(defaults.string(forKey: "fallback") == "registered", "remove falls back")
    defaults.set(42, forKey: "integer")
    defaults.set(3.5, forKey: "double")
    defaults.set(true, forKey: "bool")
    defaults.set(["a", "b"], forKey: "strings")
    defaults.set(["nested": [1, 2, 3]], forKey: "dictionary")
    require(defaults.integer(forKey: "integer") == 42, "integer round trip")
    require(defaults.double(forKey: "double") == 3.5, "double round trip")
    require(defaults.bool(forKey: "bool"), "bool round trip")
    require(defaults.stringArray(forKey: "strings") == ["a", "b"], "string array")
    require(defaults.dictionary(forKey: "dictionary") != nil, "dictionary")
    require(defaults.integer(forKey: "registeredInt") == 7, "registration typed getter")
    require(defaults.synchronize(), "synchronize")
    print("USER_DEFAULTS_SEMANTICS_OK")
case "write":
    defaults.removePersistentDomain(forName: suite)
    let payload = [
        StoredReminder(id: "A", title: "Ship the port", created: Date(timeIntervalSince1970: 1_700_000_000), complete: false),
        StoredReminder(id: "B", title: "Cold read", created: Date(timeIntervalSince1970: 1_700_000_123), complete: true),
    ]
    defaults.set(try JSONEncoder().encode(payload), forKey: "reminders")
    require(defaults.synchronize(), "write synchronize")
    print("USER_DEFAULTS_WRITE_OK")
case "read":
    guard let data = defaults.data(forKey: "reminders") else {
        require(false, "cold process data read")
        exit(2)
    }
    let payload = try JSONDecoder().decode([StoredReminder].self, from: data)
    require(payload.count == 2, "cold payload count")
    require(payload[0].title == "Ship the port", "cold payload value")
    require(payload[1].complete, "cold payload bool")
    print("USER_DEFAULTS_COLD_READ_OK")
case "clean":
    defaults.removePersistentDomain(forName: suite)
    require(defaults.synchronize(), "clean synchronize")
    print("USER_DEFAULTS_CLEAN_OK")
default:
    exit(64)
}

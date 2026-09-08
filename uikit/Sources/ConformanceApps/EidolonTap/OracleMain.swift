import UIKit

@UIApplicationMain
final class EidolonTapOracle: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let result: [String: Any] = ["system": UIDevice.current.systemVersion,
                                    "device": UIDevice.current.model,
                                    "rows": eidolonTapScenarios()]
        let data = try! JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("eidolon-tap.json")
        try! data.write(to: url)
        print(String(data: data, encoding: .utf8)!)
        exit(0)
    }
}

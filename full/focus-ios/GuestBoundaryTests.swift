import Foundation
import Dispatch
import Synchronization

@main
struct GuestBoundaryTests {
    static func main() throws {
        let queue = DispatchQueue(label: "focus.boundary")
        let key = DispatchSpecificKey<Int>()
        queue.setSpecific(key: key, value: 42)
        precondition(queue.sync { DispatchQueue.getSpecific(key: key) } == 42)
        let group = DispatchGroup()
        let completed = DispatchSemaphore(value: 0)
        group.enter()
        precondition(group.wait(timeout: .now()) == .timedOut)
        group.notify(queue: queue) { completed.signal() }
        group.leave()
        precondition(completed.wait(timeout: .now() + .seconds(2)) == .success)
        group.enter()
        queue.async { group.leave() }
        precondition(group.wait(timeout: .now() + .seconds(2)) == .success)
        var scalar = 0.0
        NSNumber(value: 2.5).getValue(&scalar)
        precondition(scalar == 2.5)
        precondition(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).count == 1)
        let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let link = "https://mozilla.org"
        precondition(detector.firstMatch(in: link, range: NSRange(location: 0, length: link.utf16.count))?.range.length == link.utf16.count)
        precondition(detector.firstMatch(in: "", range: NSRange(location: 0, length: 0)) == nil)
        let path = NSTemporaryDirectory() + "focus-boundary-plist.plist"
        let original = ["default": ["duckduckgo", "google"], "en-US": ["bing"]]
        try PropertyListEncoder().encode(original).write(to: URL(fileURLWithPath: path))
        let dictionary = NSDictionary(contentsOfFile: path)!
        let restored = dictionary as! [String: [String]]
        precondition(restored == original)
        precondition((original as NSDictionary) as! [String: [String]] == original)
        precondition(CFURLCreateStringByReplacingPercentEscapes(nil, "%F0%9F%A6%8A%20focus", "") == "🦊 focus")
        do {
            _ = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(Data([0]))
            preconditionFailure("Unsupported archive accepted")
        } catch {}
        print("FOCUS_GUEST_BOUNDARY_OK sync=specific group=notify,reuse,timeout plist=bridge percent=utf8 archive=refused")
    }
}

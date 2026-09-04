import Foundation
import WatchConnectivity

/// Import/identity consumer for the staged Foundation module. Confirms
/// WatchConnectivity types share Foundation's NSObject / NSError /
/// property-list identities rather than module-local substitutes.
public enum WatchConnectivityIdentityConsumer {
    @discardableResult
    public static func consume() -> Int {
        let session: WCSession = .default
        let object: NSObject = session
        precondition(object === session)

        let error = WCError(.genericError)
        let bridged = error as NSError
        precondition(bridged.domain == WCErrorDomain)
        precondition(bridged.code == WCError.genericError.rawValue)

        let string: NSString = "ok"
        let number = NSNumber(value: 7)
        let date = NSDate(timeIntervalSince1970: 1)
        let data: NSData = NSData(data: Data([0x03]))
        let array: NSArray = [string, number]
        let dictionary: NSDictionary = [
            "s": string,
            "n": number,
            "d": date,
            "b": data,
            "a": array,
        ]
        do {
            try session.updateApplicationContext(dictionary as! [String: Any])
            fatalError("identity consumer must not fabricate a delivered context")
        } catch let wcError as WCError {
            precondition(wcError.code == .sessionNotSupported)
        } catch {
            fatalError("identity consumer expected WCError")
        }

        let file: WCSessionFileTransfer = session.transferFile(
            URL(fileURLWithPath: "/tmp/watchconnectivity-identity-missing"),
            metadata: nil
        )
        precondition(file.file.fileURL.isFileURL)
        precondition(file.progress.isKind(of: Progress.self))
        let info = session.transferUserInfo(["s": string])
        precondition(info.userInfo["s"] as? NSString == string)
        return 1
    }
}

@main
enum WatchConnectivityIdentityMain {
    static func main() {
        precondition(WatchConnectivityIdentityConsumer.consume() == 1)
        print("WATCHCONNECTIVITY_IDENTITY_OK")
    }
}

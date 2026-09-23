// Eidolon's own compiled view archives through each runtime, with NO app
// classes present. Shared verbatim between the iOS 26.1 simulator probe
// (real UIKit) and the OpenUIKit test, exactly like NibRuntimeScenario.swift.
//
// Why without the app: the unmodified Kiosk target does not build (see
// docs/agent_reports/eidolon-launch-oracle.md — CocoaPods, CardFlight), so
// the only honest oracle for "does the port decode Eidolon's archives the way
// UIKit does" is to load the same archives in both runtimes under the same
// conditions. UIKit's rule for an unknown custom class (`UIClassSwapper`
// falls back to `UIOriginalClassName`, logging "Unknown class ... in
// Interface Builder file") is then part of what is measured, and every outlet
// the archive connects lands on a recorder via `setValue(_:forUndefinedKey:)`
// — the KVC path both runtimes take for a key with no setter.
#if canImport(ObjectiveC)
#if canImport(OpenUIKit)
import OpenUIKit
import Foundation
#else
import UIKit
#endif

/// Records every outlet UIKit's KVC could not find a setter for (the File's
/// Owner stand-in).
final class NibOwnerRecorder: NSObject {
    let identifier = "owner"
    var outlets: [String] = []
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        outlets.append(NibOutletRecorder.describe(identifier, key, value))
    }
}

/// The same, for the external placeholders. A gesture recognizer so that an
/// archive which adds a placeholder to a view's `gestureRecognizers`
/// collection (Auction's long-press-for-admin, measured: a plain NSObject
/// there raises inside `-[UIView setGestureRecognizers:]`) still loads; it
/// has no target and never fires.
final class NibOutletRecorder: UIGestureRecognizer {
    let identifier: String
    var outlets: [String] = []
    init(identifier: String) {
        self.identifier = identifier
        // UIKit's designated initializer, OpenUIKit's too (eidolon-kiosk).
        super.init(target: nil, action: nil)
    }
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        outlets.append(NibOutletRecorder.describe(identifier, key, value))
    }

    static func describe(_ identifier: String, _ key: String, _ value: Any?) -> String {
        let described: String
        if let array = value as? [Any] {
            described = "[" + array.map { String(describing: type(of: $0)) }.joined(separator: ",") + "]"
        } else if let value {
            described = String(describing: type(of: value))
        } else {
            described = "nil"
        }
        return "\(identifier).\(key)=\(described)"
    }
}

@MainActor
enum EidolonNibProbe {
    /// Runs an archive load, returning an exception description instead of
    /// terminating. The iOS probe installs an Objective-C @try/@catch here
    /// (Tools/oracle2/nibruntimeprobe/OUKTry.m); the port never raises.
    static var guardedCall: (() -> Void) -> String? = { body in body(); return nil }

    /// Loads one compiled view archive with recorder owners and dumps the
    /// top-level view after laying it out at its archived size (or at the
    /// kiosk's 1024 x 768 when the archive's root is a full-screen view).
    static func load(name: String, bytes: Data) -> [String: Any] {
        let owner = NibOwnerRecorder()
        var externals: [String: Any] = [:]
        var recorders: [NibOutletRecorder] = []
        for i in 1...8 {
            let recorder = NibOutletRecorder(identifier: "UpstreamPlaceholder-\(i)")
            externals["UpstreamPlaceholder-\(i)"] = recorder
            recorders.append(recorder)
        }
        let nib = UINib(data: bytes, bundle: nil)
        var objects: [Any] = []
        if let exception = guardedCall({
            objects = nib.instantiate(withOwner: owner, options: [.externalObjects: externals])
        }) {
            return ["exception": exception,
                    "outlets": (owner.outlets + recorders.flatMap { $0.outlets }).sorted()]
        }
        var out: [String: Any] = [
            "topLevel": objects.map { NibProbe.name($0) },
            "outlets": (owner.outlets + recorders.flatMap { $0.outlets }).sorted(),
        ]
        if let root = objects.compactMap({ $0 as? UIView }).first {
            if root.frame.size == CGSize(width: 1024, height: 768) {
                root.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
            }
            root.layoutIfNeeded()
            out["root"] = NibProbe.dump(root)
        }
        return out
    }
}
#endif

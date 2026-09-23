// guestbundlemoduleprobe -- SwiftPM's Bundle.module on the guest.
//
// Compiled together with the accessor full/xcodeplan/swiftpm_resource_accessor.py
// generates for package "GuestProbe", target "GuestBundleModuleProbe" (byte-for-byte
// Xcode 26.1's), with GuestProbe_GuestBundleModuleProbe.bundle staged beside the
// executable, the way an app's package bundles sit in Bundle.main.resourceURL.
// run.sh measures the same layout on the iOS 26.1 simulator
// (transcript-ios26.1.txt); Tools/guestprobes/GuestBundleModuleProbe.probe.sh
// runs it on the guest and requires the same lines.
import Foundation

@main
struct GuestBundleModuleProbe {
    static func main() {
        print("guestbundlemoduleprobe v1")
        let bundle = Bundle.module
        print("bundle.module name=\(bundle.bundleURL.lastPathComponent) stable=\(Bundle.module === bundle)")
        print("bundle.module identifier=\(bundle.bundleIdentifier ?? "nil")")
        let parent = bundle.bundleURL.deletingLastPathComponent().standardizedFileURL.path
        let mainResources = Bundle.main.resourceURL?.standardizedFileURL.path ?? "nil"
        print("bundle.module inMainResources=\(parent == mainResources)")
        if let url = bundle.url(forResource: "hello", withExtension: "txt"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            print("resource hello.txt=\(text.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            print("resource hello.txt=nil")
        }
        print("resource missing=\(bundle.url(forResource: "missing", withExtension: "txt") == nil ? "nil" : "found")")
        // ActivityLog's own spelling: NSLocalizedString(_, bundle: .module, comment:).
        print("localized refresh=\(NSLocalizedString("Refresh all", bundle: .module, comment: "Activity kind"))")
        print("localized redirect=\(NSLocalizedString("Feed redirect", bundle: .module, comment: "Activity kind"))")
        print("localized missing=\(NSLocalizedString("Not translated", bundle: .module, comment: ""))")
        print("guestbundlemoduleprobe done")
    }
}

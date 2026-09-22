// NibRuntimeProbe on REAL iOS 26.1: the storyboard/NIB runtime oracle.
//
// Built by scripts/nib_runtime_probe_sim.sh with module name NibRuntimeTests
// from this file plus Tests/NibRuntimeTests/NibRuntimeScenario.swift and
// EidolonNibScenario.swift — the same two scenario files the OpenUIKit test
// target compiles — so the class names in the compiled storyboard resolve on
// both sides. Writes:
//   <Documents>/nibruntime.json   NibProbe.run over NibRuntimeProbe.storyboardc
//   <Documents>/nibruntime2.json  NibProbe.runExtended (stacks, prototype
//                                 cells, tabs, ProbeXibView.nib)
//   <Documents>/eidolonnibs.json  every Eidolon view archive, no app classes
//
// MEASURED while building it: without UIApplicationMain, `sendActions(for:)`
// delivers nothing (UIControl routes through UIApplication.sendAction), so
// the scenario runs from a real application delegate's launch callback.
import UIKit

let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

func write(_ object: Any, _ name: String) {
    let data = try! JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try! data.write(to: URL(fileURLWithPath: docs + "/" + name))
}

final class ProbeAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        write(NibProbe.run(storyboardName: "NibRuntimeProbe"), "nibruntime.json")
        write(NibProbe.runExtended(storyboardName: "NibRuntimeProbe"), "nibruntime2.json")

        EidolonNibProbe.guardedCall = { body in
            // Object addresses differ per run; the class and key do not.
            OUKTry(body).map {
                $0.replacingOccurrences(of: " 0x[0-9a-f]+>", with: ">", options: .regularExpression)
            }
        }

        var eidolon: [String: Any] = [:]
        let root = Bundle.main.bundlePath + "/eidolon"
        let fm = FileManager.default
        for dir in ((try? fm.contentsOfDirectory(atPath: root)) ?? []).sorted() {
            let path = root + "/" + dir
            for file in ((try? fm.contentsOfDirectory(atPath: path)) ?? []).sorted()
            where file.hasSuffix(".nib") && (file.contains("-view-") || dir == "xib") {
                let bytes = try! Data(contentsOf: URL(fileURLWithPath: path + "/" + file))
                eidolon[dir + "/" + file] = EidolonNibProbe.load(name: file, bytes: bytes)
                write(eidolon, "eidolonnibs.json")
            }
        }
        write(eidolon, "eidolonnibs.json")
        exit(0)
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(ProbeAppDelegate.self))

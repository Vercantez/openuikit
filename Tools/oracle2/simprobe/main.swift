// SimProbe: iOS Simulator scroll-physics oracle (M8).
//
// The Mac Catalyst oracle (oracle2 `scroll` mode) can only exercise UIKit's
// POINTER scroll path — its Mac-feel physics (velocity-dependent decay,
// stiff rubber band) are NOT the iOS touch physics OpenUIKit implements,
// and Catalyst UIScrollView refuses to apply touch-pan translation to
// contentOffset at all (verified: the pan recognizes, tracks and reports
// velocity, but the content never moves — Mac behavioral style).
//
// So the authoritative TOUCH measurements come from REAL iOS UIKit in the
// iOS Simulator: this app synthesizes UITouch drags (KIF-style private-API
// delivery, scrollshared.swift), records contentOffset traces, and writes
// golden trace JSONs to its Documents directory.
//
// Build + run end-to-end: scripts/scroll_probe_sim.sh <outdir>
import UIKit

final class SimProbeRunner {
    let host: UIView
    let window: UIWindow
    let scrollView = UIScrollView()
    let recorder = TraceRecorder()
    var driver: TouchExperimentDriver?

    init(host: UIView, window: UIWindow) {
        self.host = host
        self.window = window
    }

    func start() {
        let bounds = host.bounds
        scrollView.frame = bounds
        scrollView.contentInsetAdjustmentBehavior = .never
        let contentHeight = 40_000.0
        scrollView.contentSize = CGSize(width: bounds.width, height: contentHeight)
        scrollView.backgroundColor = .white
        for i in 0..<80 {
            let stripe = UIView(frame: CGRect(x: 0, y: CGFloat(i) * 500, width: bounds.width, height: 250))
            stripe.backgroundColor = UIColor(white: 0.9, alpha: 1)
            scrollView.addSubview(stripe)
        }
        host.addSubview(scrollView)
        recorder.attach(scrollView)
        recorder.recording = true

        let synth = TouchSynth(window: window)
        synth.probeSelectors()

        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        probeLog("simprobe outdir: \(docs)")
        probeLog("viewport: \(bounds.size) scale=\(UIScreen.main.scale) iOS \(UIDevice.current.systemVersion)")
        let source = "simprobe: real iOS UIKit, iOS Simulator \(UIDevice.current.systemVersion), "
            + "synthetic UITouch drags via UIApplication.sendEvent (ideal 8ms timestamp grid)"
        let driver = TouchExperimentDriver(scrollView: scrollView, recorder: recorder,
                                           synth: synth, outdir: docs, source: source)
        self.driver = driver
        driver.run(specs: standardTouchExperiments(viewport: bounds.size,
                                                   contentHeight: contentHeight)) {
            probeLog("PROBE DONE")
            try? (logLines.joined(separator: "\n") + "\n")
                .write(toFile: docs + "/probe.log", atomically: true, encoding: .utf8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
        }
    }
}

class SimAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var runner: SimProbeRunner?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        window = win
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        win.rootViewController = vc
        win.makeKeyAndVisible()
        // Let the first render commit + the app reach steady state before
        // measuring (UIKit skips animations for never-displayed hierarchies).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let r = SimProbeRunner(host: vc.view, window: win)
            self.runner = r
            r.start()
        }
        return true
    }
}

// Watchdog: the probe must terminate even if an experiment hangs.
DispatchQueue.main.asyncAfter(deadline: .now() + 240) {
    FileHandle.standardError.write(Data("simprobe: watchdog timeout\n".utf8))
    exit(3)
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(SimAppDelegate.self))

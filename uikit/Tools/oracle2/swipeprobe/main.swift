// Real iOS 26.1 swipe oracle. Run scripts/swipe_probe_sim.sh <outdir>.
// The touch synthesizer uses the same in-process selectors as scrollshared.swift.
import UIKit
import Darwin

var logLines: [String] = []
func probeLog(_ s: String) {
    logLines.append(s)
    print(s)
    fflush(stdout)
}

let rawMsgSend = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "objc_msgSend")!
typealias MsgSendPointBool = @convention(c) (AnyObject, Selector, CGPoint, Bool) -> Void
typealias MsgSendInt = @convention(c) (AnyObject, Selector, Int) -> Void
typealias MsgSendDouble = @convention(c) (AnyObject, Selector, Double) -> Void
typealias MsgSendBool = @convention(c) (AnyObject, Selector, Bool) -> Void
typealias MsgSendObjBool = @convention(c) (AnyObject, Selector, AnyObject?, Bool) -> Void
typealias MsgSendVoid = @convention(c) (AnyObject, Selector) -> Void
typealias MsgSendRetObj = @convention(c) (AnyObject, Selector) -> Unmanaged<AnyObject>?

func stateName(_ s: UIGestureRecognizer.State) -> String {
    switch s {
    case .possible: return "possible"
    case .began: return "began"
    case .changed: return "changed"
    case .ended: return "ended"
    case .cancelled: return "cancelled"
    case .failed: return "failed"
    @unknown default: return "other"
    }
}
func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

final class TwoTouchSynth {
    let window: UIWindow
    var touches: [NSObject] = []
    init(window: UIWindow) {
        self.window = window
        let cls = NSClassFromString("UITouch") as? NSObject.Type
        touches = [0, 1].compactMap { _ in cls?.init() }
    }
    func touchesEvent() -> NSObject? {
        let app = UIApplication.shared
        let sel = NSSelectorFromString("_touchesEvent")
        guard app.responds(to: sel) else { return nil }
        let f = unsafeBitCast(rawMsgSend, to: MsgSendRetObj.self)
        return f(app, sel)?.takeUnretainedValue() as? NSObject
    }
    func phaseValue(_ p: UITouch.Phase) -> Int {
        switch p {
        case .began: return 0
        case .moved: return 1
        case .stationary: return 2
        case .ended: return 3
        case .cancelled: return 4
        default: return 0
        }
    }
    func send(phases: [UITouch.Phase], points: [CGPoint], timestamp: Double, first: Bool) {
        let setInt = unsafeBitCast(rawMsgSend, to: MsgSendInt.self)
        let setDouble = unsafeBitCast(rawMsgSend, to: MsgSendDouble.self)
        let setObjBool = unsafeBitCast(rawMsgSend, to: MsgSendObjBool.self)
        let call = unsafeBitCast(rawMsgSend, to: MsgSendVoid.self)
        let setObj = unsafeBitCast(rawMsgSend, to: (@convention(c) (AnyObject, Selector, AnyObject?) -> Void).self)
        let setBool = unsafeBitCast(rawMsgSend, to: MsgSendBool.self)
        let setPointBool = unsafeBitCast(rawMsgSend, to: MsgSendPointBool.self)
        guard let ev = touchesEvent() else { return }
        call(ev, NSSelectorFromString("_clearTouches"))
        if ev.responds(to: NSSelectorFromString("_setTimestamp:")) {
            setDouble(ev, NSSelectorFromString("_setTimestamp:"), timestamp)
        }
        for i in 0..<min(phases.count, points.count, touches.count) {
            let t = touches[i]
            let point = points[i]
            if first {
                setObj(t, NSSelectorFromString("setWindow:"), window)
                let view = window.hitTest(point, with: nil) ?? window
                setObj(t, NSSelectorFromString("setView:"), view)
                setInt(t, NSSelectorFromString("setTapCount:"), 1)
                if t.responds(to: NSSelectorFromString("_setIsFirstTouchForView:")) {
                    setBool(t, NSSelectorFromString("_setIsFirstTouchForView:"), true)
                }
                if t.responds(to: NSSelectorFromString("_setSenderID:")) {
                    let f = unsafeBitCast(rawMsgSend, to: (@convention(c) (AnyObject, Selector, UInt64) -> Void).self)
                    f(t, NSSelectorFromString("_setSenderID:"), 0x0ACE_FADE_0000_0002 + UInt64(i))
                }
            }
            setPointBool(t, NSSelectorFromString("_setLocationInWindow:resetPrevious:"), point, first)
            setInt(t, NSSelectorFromString("setPhase:"), phaseValue(phases[i]))
            setDouble(t, NSSelectorFromString("setTimestamp:"), timestamp)
            setObjBool(ev, NSSelectorFromString("_addTouch:forDelayedDelivery:"), t, false)
        }
        UIApplication.shared.sendEvent(ev as! UIEvent)
    }
}

final class SwipeSpy: NSObject {
    var samples: [String] = []
    var step = "begin"
    @objc func handle(_ g: UISwipeGestureRecognizer) {
        samples.append("step=\(step),action=\(stateName(g.state)),n=\(g.numberOfTouches),loc=\(g.location(in: nil))")
    }
}

final class ProbeDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        window = win
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        win.rootViewController = vc
        win.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            probeLog("scale=\(UIScreen.main.scale) size=\(win.bounds.size) version=\(UIDevice.current.systemVersion)")
            let plain = UISwipeGestureRecognizer()
            probeLog("default direction=\(plain.direction.rawValue) touches=\(plain.numberOfTouchesRequired) state=\(stateName(plain.state)) enabled=\(plain.isEnabled) cancels=\(plain.cancelsTouchesInView) delaysBegan=\(plain.delaysTouchesBegan) delaysEnded=\(plain.delaysTouchesEnded) number=\(plain.numberOfTouches) location=\(plain.location(in: nil))")
            probeLog("raw right=\(UISwipeGestureRecognizer.Direction.right.rawValue) left=\(UISwipeGestureRecognizer.Direction.left.rawValue) up=\(UISwipeGestureRecognizer.Direction.up.rawValue) down=\(UISwipeGestureRecognizer.Direction.down.rawValue)")
            for raw: UInt in [0, 1, 2, 3, 4, 8, 15, 16, UInt.max] {
                plain.direction = .init(rawValue: raw)
                probeLog("direction assigned=\(raw) read=\(plain.direction.rawValue)")
            }
            for n in [0, 1, 2, 3, 5, 6, 16, -1] {
                plain.numberOfTouchesRequired = n
                probeLog("touches assigned=\(n) read=\(plain.numberOfTouchesRequired)")
            }
            func run(_ name: String, direction: UISwipeGestureRecognizer.Direction = .right,
                     required: Int = 1, count: Int = 1, multipliers: [CGFloat] = [], moves: [(CGFloat, CGFloat, Double)]) {
                let host = UIView(frame: win.bounds)
                vc.view.addSubview(host)
                let spy = SwipeSpy()
                let g = UISwipeGestureRecognizer(target: spy, action: #selector(SwipeSpy.handle(_:)))
                g.direction = direction
                g.numberOfTouchesRequired = required
                host.addGestureRecognizer(g)
                let synth = TwoTouchSynth(window: win)
                let start = (0..<count).map { CGPoint(x: 120, y: 220 + CGFloat($0) * 80) }
                let base = CACurrentMediaTime()
                synth.send(phases: Array(repeating: .began, count: count), points: start, timestamp: base, first: true)
                var samples = ["begin=\(stateName(g.state))"]
                for (dx, dy, dt) in moves {
                    spy.step = "move(\(dx),\(dy),\(dt))"
                    synth.send(phases: Array(repeating: .moved, count: count),
                               points: start.enumerated().map { index, p in
                                   let factor = index < multipliers.count ? multipliers[index] : 1
                                   return CGPoint(x:p.x + dx * factor, y:p.y + dy * factor)
                               },
                               timestamp: base + dt, first: false)
                    samples.append("move(\(dx),\(dy),\(dt))=\(stateName(g.state))")
                }
                let last = moves.last ?? (0,0,0)
                spy.step = "end"
                synth.send(phases: Array(repeating: .ended, count: count),
                           points: start.map { CGPoint(x: $0.x + last.0, y: $0.y + last.1) },
                           timestamp: base + last.2 + 0.01, first: false)
                samples.append("end=\(stateName(g.state))")
                samples += spy.samples
                probeLog("\(name) " + samples.joined(separator: " | "))
                host.removeFromSuperview()
            }
            for key in ["_maximumDuration", "_minimumPrimaryMovement", "_maximumSecondaryMovement",
                        "_maximumOppositeMovement", "_rateOfMinimumMovementDecay", "_rateOfMaximumMovementDecay"] {
                probeLog("default-private \(key)=\(UISwipeGestureRecognizer().value(forKey: key)!)")
            }
            run("distance-fast", moves: [(2,0,0.01),(5,0,0.02),(10,0,0.03),(20,0,0.04),(30,0,0.05),(40,0,0.06),(50,0,0.07),(60,0,0.08),(80,0,0.09),(120,0,0.1)])
            run("left", direction:.left, moves:[(-100,0,0.1)])
            run("up", direction:.up, moves:[(0,-100,0.1)])
            run("down", direction:.down, moves:[(0,100,0.1)])
            run("wrong-left", moves:[(-100,0,0.1)])
            run("diagonal", moves:[(100,100,0.1)])
            for t in [0.49,0.499,0.5,0.501,0.51,0.6,1.0] { run("duration-\(t)", moves:[(100,0,t)]) }
            // These independently bracket both boundaries; the measurement
            // does not evaluate the implementation's threshold expression.
            for (t,primary,secondary): (Double,CGFloat,CGFloat) in [(0,50,50),(0.1,45.3,45.1),(0.2,40.6,40.2),(0.3,35.9,35.3),(0.4,31.2,30.4),(0.5,26.5,25.5)] {
                for epsilon: CGFloat in [-0.001,0.001] {
                    run("measured-primary-\(t)-\(primary+epsilon)",moves:[(primary+epsilon,0,t)])
                    run("measured-secondary-\(t)-\(secondary+epsilon)",moves:[(100,secondary+epsilon,t)])
                }
            }
            run("two-required",required:2,count:2,moves:[(100,0,0.1)])
            run("two-one-required",required:1,count:2,moves:[(100,0,0.1)])
            run("one-two-required",required:2,count:1,moves:[(100,0,0.1)])
            run("two-both-required",required:2,count:2,multipliers:[1,0],moves:[(100,0,0.1)])
            run("two-unequal-qualified",required:2,count:2,multipliers:[1,0.5],moves:[(100,0,0.1)])
            run("two-opposite",required:2,count:2,multipliers:[1,-1],moves:[(100,0,0.1)])
            run("right-left-union-right",direction:[.right,.left],moves:[(100,0,0.1)])
            run("right-left-union-left",direction:[.right,.left],moves:[(-100,0,0.1)])
            run("right-down-right",direction:[.right,.down],moves:[(100,0,0.1)])
            run("right-down-down",direction:[.right,.down],moves:[(0,100,0.1)])
            run("right-down-diagonal",direction:[.right,.down],moves:[(100,100,0.1)])
            run("all-right",direction:[.right,.left,.up,.down],moves:[(100,0,0.1)])
            run("all-diagonal-zero",direction:[.right,.left,.up,.down],moves:[(50,50,0)])
            run("direction-empty",direction:[],moves:[(100,0,0.1)])
            run("direction-unknown",direction:.init(rawValue:16),moves:[(100,0,0.1)])
            run("reversal",moves:[(-0.1,0,0.01),(100,0,0.1)])
            run("cross-first",moves:[(0,20,0.01),(100,0,0.1)])
            run("retreat-positive",moves:[(20,0,0.01),(10,0,0.02),(100,0,0.1)])
            run("no-move",moves:[])
            run("zero-required",required:0,moves:[(100,0,0.1)])
            let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            try! (logLines.joined(separator: "\n") + "\n")
                .write(toFile: docs + "/swipe.txt", atomically: true, encoding: .utf8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exit(0) }
        }
        return true
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(ProbeDelegate.self))

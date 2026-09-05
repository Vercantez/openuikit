// The port's half of the CONFORMANCE-APP harness (docs/HILLCLIMB.md).
//
//   openhost --app NavFlow --script Sources/ConformanceApps/NavFlow/script.json \
//            --record <outdir> [--scale N]
//
// boots the app through AppMode.swift, which merges ConformanceApps.registry
// into the host app table (UIApplicationMain, a real UIWindow, the app's own
// root controller), replays the script's named actions on a 60 Hz integer
// frame clock (`ConformanceClock`: animationTime = frame / 60) and writes,
// at each capture frame:
//
//   <outdir>/<app>.t<ms>.png          the window rendered at the script scale
//   <outdir>/<app>.t<ms>.layout.json  {"name", "t", "clock", "screen", "views"}
//
// Tools/oracle2/confprobe writes byte-compatible files from REAL UIKit at
// the same 60 Hz frame index (CADisplayLink, not a GCD wall-clock), and
// scripts/conformance_flow.sh compares them pair by pair.
//
// The dump carries ABSOLUTE frames (`abs`, origins accumulated to the
// captured root) as well as parent-relative ones, because the two view trees
// only agree on absolute geometry: real UIKit hangs the app's controllers off
// private containers (UILayoutContainerView, UIViewControllerWrapperView,
// UITransitionView) that the port has no counterpart for, so a path-indexed
// comparison compares two unrelated trees. It also carries presentation-layer
// frames so a capture taken mid-animation says which state it caught — every
// capture in NavFlow's script is at rest, and `pframe == frame` is how that
// is checked rather than assumed.
//
// Like HostCore.swift this file must NOT import Foundation (OpenUIKit's CG
// types would collide with Apple's); the file IO goes through SceneIO.swift.

import OpenUIKit
import ConformanceApps

// MARK: - Script

struct ConformanceStep {
    let t: Double
    let action: String
}

/// Parse `{"events": [{"t": , "action": }...], "captures": [t...], "style"?, "direction"?}`.
func parseConformanceScript(_ script: JSONValue)
    -> (steps: [ConformanceStep], captures: [Double], style: String, direction: String) {
    let steps: [ConformanceStep] = (script["events"]?.arrayValue ?? []).map { e in
        guard let j = e.objectValue, let t = j["t"]?.doubleValue,
              let action = j["action"]?.stringValue else {
            fatalError("bad conformance step (need {t, action})")
        }
        return ConformanceStep(t: t, action: action)
    }
    let captures = (script["captures"]?.arrayValue ?? []).compactMap { $0.doubleValue }
    guard !captures.isEmpty else { fatalError("script needs non-empty \"captures\"") }
    let scriptStyle = script["style"]?.stringValue ?? "light"
    let scriptDirection = script["direction"]?.stringValue ?? "ltr"
    return (steps, captures, scriptStyle, scriptDirection)
}

// MARK: - Layout dump

/// One dump entry per view, DFS order, mirroring
/// Tools/oracle2/confprobe/main.swift's `dumpLayout` key for key.
@MainActor
func dumpConformanceLayout(_ v: UIView, path: String, absOrigin: CGPoint,
                           into out: inout [JSONValue]) {
    let origin = CGPoint(x: absOrigin.x + v.frame.origin.x - v.bounds.origin.x,
                         y: absOrigin.y + v.frame.origin.y - v.bounds.origin.y)
    var entry: [String: JSONValue] = [
        "path": .string(path),
        "class": .string(String(describing: type(of: v))),
        "frame": rectJSON(v.frame),
        "abs": .array([.number(round3(origin.x)), .number(round3(origin.y)),
                       .number(round3(v.frame.width)), .number(round3(v.frame.height))]),
        "bounds": rectJSON(v.bounds),
        "hidden": .bool(v.isHidden),
        "alpha": .number(round3(v.alpha)),
    ]
    let sa = v.safeAreaInsets
    entry["safeAreaInsets"] = .array([.number(round3(sa.top)), .number(round3(sa.left)),
                                      .number(round3(sa.bottom)), .number(round3(sa.right))])
    if v.layer.cornerRadius != 0 {
        entry["cornerRadius"] = .number(round3(v.layer.cornerRadius))
    }
    if v.transform != .identity {
        let t = v.transform
        entry["transform"] = .array([t.a, t.b, t.c, t.d, t.tx, t.ty].map { .number(round3($0)) })
    }
    // No `pframe` here: OpenUIKit's CALayer has no presentation layer (it
    // animates by mutating the model on the host clock). The simulator side
    // dumps one, which is how a capture is checked to be at rest on the side
    // that has a render server.
    if let c = v.backgroundColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if c.getRed(&r, green: &g, blue: &b, alpha: &a) {
            entry["bg"] = .array([round3(r), round3(g), round3(b), round3(a)].map { .number($0) })
        }
    }
    if let l = v as? UILabel {
        if let t = l.text { entry["text"] = .string(t) }
        // `fontSize` is the comparable half: real UIKit's PostScript
        // `fontName` (".SFUI-Regular") has no counterpart in OpenUIKit's
        // struct font, whose identity is (pointSize, weight, design).
        entry["fontSize"] = .number(round3(l.font.pointSize))
        entry["fontName"] = .string(l.font.weight.name)
    }
    if v.effectiveUserInterfaceLayoutDirection == .rightToLeft {
        entry["uiDir"] = .string("rtl")
    }
    if v is UILabel || v is UIButton || v is UISwitch || v is UIImageView
        || v is UITextField || v is UITextView {
        let i = v.intrinsicContentSize
        entry["intrinsic"] = .array([
            .number(i.width == UIView.noIntrinsicMetric ? -1 : round3(i.width)),
            .number(i.height == UIView.noIntrinsicMetric ? -1 : round3(i.height)),
        ])
    }
    if let sw = v as? UISwitch { entry["isOn"] = .bool(sw.isOn) }
    if let tf = v as? UITextField {
        entry["isEditing"] = .bool(tf.isEditing)
    }
    if let tv = v as? UITextView {
        if let t = tv.text { entry["text"] = .string(t) }
        entry["isEditing"] = .bool(tv.isFirstResponder)
    }
    if let sl = v as? UISlider { entry["value"] = .number(round3(CGFloat(sl.value))) }
    if let st = v as? UIStepper { entry["value"] = .number(round3(CGFloat(st.value))) }
    if let sg = v as? UISegmentedControl {
        entry["selectedSegmentIndex"] = .number(Double(sg.selectedSegmentIndex))
    }
    if let sv = v as? UIScrollView {
        entry["contentOffset"] = .array([.number(round3(sv.contentOffset.x)),
                                         .number(round3(sv.contentOffset.y))])
        entry["contentSize"] = .array([.number(round3(sv.contentSize.width)),
                                       .number(round3(sv.contentSize.height))])
        let ci = sv.contentInset, ai = sv.adjustedContentInset
        entry["contentInset"] = .array([.number(round3(ci.top)), .number(round3(ci.left)),
                                        .number(round3(ci.bottom)), .number(round3(ci.right))])
        entry["adjustedContentInset"] = .array([.number(round3(ai.top)), .number(round3(ai.left)),
                                                .number(round3(ai.bottom)), .number(round3(ai.right))])
    }
    out.append(.object(entry))
    for (i, sub) in v.subviews.enumerated() {
        dumpConformanceLayout(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)",
                              absOrigin: origin, into: &out)
    }
}

func rectJSON(_ r: CGRect) -> JSONValue {
    .array([.number(round3(r.origin.x)), .number(round3(r.origin.y)),
            .number(round3(r.width)), .number(round3(r.height))])
}

// MARK: - Scripted replay

/// Replay `steps` and capture at `captures`, on a 60 Hz integer frame clock.
///
/// Script times convert with `ConformanceClock.frameIndex` — the same
/// mapping confprobe's CADisplayLink uses — so a mid-flight capture at
/// +0.15 s is frame 9 after the action (TableEditor t1350 / t2350) and
/// +0.2 s is frame 12 (Modal t600). `animationTime` is `frame / 60`, not
/// an accumulated `t += 1/60` (that addition missed t=2.35 by one frame:
/// fire_n=142 vs ideal 141). The clock is stepped every frame rather than
/// jumped from event to event: OpenUIKit's transitions, sheet presentations
/// and switch springs advance from `UIWindow.tick`, and a jump would
/// collapse a whole transition into a single step. Nothing renders except
/// at capture frames.
@MainActor
func runConformanceScripted(_ scene: HostScene, app: String,
                            steps: [ConformanceStep], captures: [Double],
                            style: String, direction: String, outdir: String) throws -> [String] {
    guard let perform = ConformanceApps.registry[app]?.perform else {
        fatalError("no conformance action table for app \"\(app)\"")
    }
    var nextStep = 0, nextCapture = 0
    let sortedSteps = steps.sorted { $0.t < $1.t }
    let sortedCaptures = captures.sorted()
    var written: [String] = []
    let stepFrames = sortedSteps.map { ConformanceClock.frameIndex(for: $0.t) }
    let captureFrames = sortedCaptures.map { ConformanceClock.frameIndex(for: $0) }
    var endFrame = 0
    for f in stepFrames { if f > endFrame { endFrame = f } }
    for f in captureFrames { if f > endFrame { endFrame = f } }

    UIApplication.shared._hostDidBecomeActive()
    var frame = 0
    while frame <= endFrame {
        let t = ConformanceClock.time(of: frame)
        OpenUIKitRuntime.animationTime = t
        scene.window.tick(timestamp: t)
        // At equal frames a capture runs before an action: Pager t400 is
        // the rest tick (frame 0), then setViewControllers so the private
        // updater's first motion is vsync 1 (pager-clock probe).
        while nextCapture < sortedCaptures.count, captureFrames[nextCapture] <= frame {
            let ct = sortedCaptures[nextCapture]
            written.append(try captureConformance(scene, app: app, t: ct,
                                                  frame: frame, style: style,
                                                  direction: direction,
                                                  outdir: outdir))
            nextCapture += 1
        }
        while nextStep < sortedSteps.count, stepFrames[nextStep] <= frame {
            let step = sortedSteps[nextStep]
            print("action: \(step.action) t=\(fmt3(step.t)) frame=\(frame)")
            perform(step.action)
            scene.window.layoutIfNeeded()
            nextStep += 1
        }
        frame += 1
    }
    return written
}

@MainActor
func captureConformance(_ scene: HostScene, app: String, t: Double,
                        frame: Int, style: String, direction: String,
                        outdir: String) throws -> String {
    scene.window.layoutIfNeeded()
    let bmp = _UIKeyboardChrome.renderCapture(appWindow: scene.window,
                                            scale: scene.scale)
    let suffix = ConformanceClock.captureSuffix(for: t, style: style,
                                               direction: direction)
    let png = "\(app).\(suffix).png"
    try writeBinaryFile(bmp.pngData(), path: "\(outdir)/\(png)")

    var views: [JSONValue] = []
    dumpConformanceLayout(scene.window, path: "", absOrigin: .zero, into: &views)
    let layout = JSONValue.object([
        "name": .string("\(app).\(suffix)"),
        "t": .number(round3(CGFloat(t))),
        "style": .string(style),
        "direction": .string(direction),
        "clock": .object([
            "frame": .number(Double(frame)),
            "hz": .number(Double(ConformanceClock.hz)),
            "scriptT": .number(round3(CGFloat(t))),
        ]),
        "screen": .object(["scale": .number(Double(scene.scale)),
                           "bounds": .array([.number(round3(scene.window.bounds.width)),
                                             .number(round3(scene.window.bounds.height))]),
                           "windowSafeArea": .array([
                               .number(round3(scene.window.safeAreaInsets.top)),
                               .number(round3(scene.window.safeAreaInsets.left)),
                               .number(round3(scene.window.safeAreaInsets.bottom)),
                               .number(round3(scene.window.safeAreaInsets.right))])]),
        "views": .array(views),
    ])
    try writeJSONFile(layout, path: "\(outdir)/\(app).\(suffix).layout.json")
    print("captured \(png) frame=\(frame)")
    return png
}

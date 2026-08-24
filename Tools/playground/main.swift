// OpenUIKit Playground v2 — progress dashboard + live scene lab.
//
// Build & run:  ./scripts/playground.sh   (from the repo root)
//
// - "Run Suite": renders ALL fixture scenes with OpenUIKit and scores them
//   against the real-UIKit goldens; the sidebar becomes a scoreboard.
// - Select a scene: live JSON editor; renders OpenUIKit vs real-UIKit oracle
//   vs diff heatmap. Animation scenes get a frame slider (capture times).
// - "Interactive": launches the SDL2 live host (openhost) on the current
//   scene, once that binary exists (M7).

import AppKit

let repoRoot = FileManager.default.currentDirectoryPath
let scratch = NSTemporaryDirectory() + "openuikit-playground"

func findBinary(_ candidates: [String]) -> String? {
    candidates.map { repoRoot + "/" + $0 }.first { FileManager.default.isExecutableFile(atPath: $0) }
}

@discardableResult
func run(_ launchPath: String, _ args: [String], env: [String: String] = [:]) -> (Int32, String) {
    let p = Process()
    p.launchPath = launchPath
    p.arguments = args
    p.currentDirectoryPath = repoRoot
    var e = ProcessInfo.processInfo.environment
    for (k, v) in env { e[k] = v }
    p.environment = e
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return (127, "\(error)") }
    p.waitUntilExit()
    let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return (p.terminationStatus, out)
}

func pixelData(_ path: String) -> (w: Int, h: Int, bytes: [UInt8])? {
    guard let img = NSImage(contentsOfFile: path),
          let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return nil }
    let w = rep.pixelsWide, h = rep.pixelsHigh
    var out = [UInt8](repeating: 0, count: w * h * 4)
    for y in 0..<h {
        for x in 0..<w {
            let c = rep.colorAt(x: x, y: y) ?? .clear
            let o = (y * w + x) * 4
            out[o] = UInt8(max(0, min(255, c.redComponent * 255)))
            out[o + 1] = UInt8(max(0, min(255, c.greenComponent * 255)))
            out[o + 2] = UInt8(max(0, min(255, c.blueComponent * 255)))
            out[o + 3] = UInt8(max(0, min(255, c.alphaComponent * 255)))
        }
    }
    return (w, h, out)
}

/// compare.py semantics: composite over white, match = per-channel delta <= 6.
func diffImages(_ a: String, _ b: String) -> (score: Double, heatmap: NSImage)? {
    guard let ga = pixelData(a), let gb = pixelData(b), ga.w == gb.w, ga.h == gb.h,
          ga.w > 0 else { return nil }
    let w = ga.w, h = ga.h
    var match = 0
    var heat = [UInt8](repeating: 0, count: w * h * 4)
    func overWhite(_ bytes: [UInt8], _ i: Int, _ c: Int) -> Int {
        let a = Int(bytes[i * 4 + 3])
        return (Int(bytes[i * 4 + c]) * a + 255 * (255 - a)) / 255
    }
    for i in 0..<(w * h) {
        var d = 0
        for c in 0..<3 {
            d = max(d, abs(overWhite(ga.bytes, i, c) - overWhite(gb.bytes, i, c)))
        }
        let o = i * 4
        if d <= 6 {
            match += 1
            heat[o + 1] = 60
        } else {
            heat[o] = UInt8(min(255, d * 4))
        }
        heat[o + 3] = 255
    }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: w * 4, bitsPerPixel: 32)!
    rep.bitmapData!.update(from: heat, count: heat.count)
    let img = NSImage(size: NSSize(width: w, height: h))
    img.addRepresentation(rep)
    return (100.0 * Double(match) / Double(w * h), img)
}

struct SceneRow {
    var name: String
    var status: String? = nil   // PASS / FAIL from suite run
    var score: Double? = nil
    var category: String? = nil
}

final class PlaygroundController: NSObject, NSTableViewDataSource, NSTableViewDelegate,
                                  NSTextViewDelegate {
    var window: NSWindow!
    var sceneList: NSTableView!
    var editor: NSTextView!
    var oursView = NSImageView()
    var goldenView = NSImageView()
    var diffView = NSImageView()
    var status = NSTextField(labelWithString: "")
    var suiteSummary = NSTextField(labelWithString: "suite not run yet")
    var backendPopup = NSPopUpButton()
    var autoRender = NSButton(checkboxWithTitle: "Auto-render", target: nil, action: nil)
    var frameSlider = NSSlider(value: 0, minValue: 0, maxValue: 0, target: nil, action: nil)
    var frameLabel = NSTextField(labelWithString: "")
    var interactiveBtn: NSButton!
    var rows: [SceneRow] = []
    var debounce: Timer?
    var rendering = false
    var pendingRender = false
    var frames: [(time: String, ours: String, golden: String)] = []

    let openrender = findBinary([".build/release/openrender", ".build/debug/openrender"])
    let oracle = findBinary(["Tools/oracle/oracle"])
    let oracle2 = findBinary(["Tools/oracle2/run.sh"])
    var openhost: String? { findBinary([".build/release/openhost", ".build/debug/openhost"]) }

    func setUp() {
        try? FileManager.default.createDirectory(atPath: scratch, withIntermediateDirectories: true)
        reloadSceneList()

        window = NSWindow(contentRect: NSRect(x: 60, y: 60, width: 1520, height: 940),
                          styleMask: [.titled, .closable, .resizable, .miniaturizable],
                          backing: .buffered, defer: false)
        window.title = "OpenUIKit Playground — progress dashboard"
        window.minSize = NSSize(width: 1100, height: 620)

        sceneList = NSTableView()
        let col = NSTableColumn(identifier: .init("scene"))
        col.title = "Scenes"
        sceneList.addTableColumn(col)
        sceneList.dataSource = self
        sceneList.delegate = self
        sceneList.headerView = nil
        sceneList.rowHeight = 22
        let sideScroll = NSScrollView()
        sideScroll.documentView = sceneList
        sideScroll.hasVerticalScroller = true

        let editorScroll = NSScrollView()
        editor = NSTextView()
        editor.isRichText = false
        editor.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.delegate = self
        editor.autoresizingMask = [.width]
        editor.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                height: CGFloat.greatestFiniteMagnitude)
        editor.isVerticallyResizable = true
        editor.textContainer?.widthTracksTextView = true
        editorScroll.documentView = editor
        editorScroll.hasVerticalScroller = true

        for v in [oursView, goldenView, diffView] {
            v.imageScaling = .scaleProportionallyDown
            v.wantsLayer = true
            v.layer?.backgroundColor = NSColor(white: 0.93, alpha: 1).cgColor
        }
        func labeled(_ v: NSView, _ text: String) -> NSStackView {
            let l = NSTextField(labelWithString: text)
            l.font = NSFont.boldSystemFont(ofSize: 11)
            let s = NSStackView(views: [l, v])
            s.orientation = .vertical
            s.alignment = .leading
            s.spacing = 2
            return s
        }
        frameSlider.target = self
        frameSlider.action = #selector(frameChanged)
        frameSlider.isHidden = true
        frameLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let frameRow = NSStackView(views: [frameSlider, frameLabel])
        frameRow.orientation = .horizontal
        let renders = NSStackView(views: [frameRow,
                                          labeled(oursView, "OpenUIKit"),
                                          labeled(goldenView, "Real UIKit (oracle)"),
                                          labeled(diffView, "Diff (red = mismatch)")])
        renders.orientation = .vertical
        renders.distribution = .fill
        renders.spacing = 8
        oursView.heightAnchor.constraint(equalTo: goldenView.heightAnchor).isActive = true
        diffView.heightAnchor.constraint(equalTo: goldenView.heightAnchor).isActive = true

        backendPopup.addItems(withTitles: ["quartz", "swift"])
        autoRender.state = .on
        let suiteBtn = NSButton(title: "Run Suite", target: self, action: #selector(runSuite))
        let renderBtn = NSButton(title: "Render ⌘R", target: self, action: #selector(renderNow))
        renderBtn.keyEquivalent = "r"
        renderBtn.keyEquivalentModifierMask = .command
        let saveBtn = NSButton(title: "Save to fixture", target: self, action: #selector(saveFixture))
        interactiveBtn = NSButton(title: "▶ Interactive", target: self, action: #selector(launchInteractive))
        status.lineBreakMode = .byTruncatingTail
        suiteSummary.font = NSFont.boldSystemFont(ofSize: 12)
        let bar = NSStackView(views: [suiteBtn, suiteSummary,
                                      NSTextField(labelWithString: "Backend:"), backendPopup,
                                      renderBtn, saveBtn, interactiveBtn, autoRender, status])
        bar.orientation = .horizontal
        bar.spacing = 8
        status.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let split = NSSplitView()
        split.isVertical = true
        split.dividerStyle = .thin
        split.addArrangedSubview(sideScroll)
        split.addArrangedSubview(editorScroll)
        split.addArrangedSubview(renders)

        let content = NSStackView(views: [bar, split])
        content.orientation = .vertical
        content.spacing = 6
        content.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async {
            split.setPosition(280, ofDividerAt: 0)
            split.setPosition(800, ofDividerAt: 1)
        }

        updateInteractiveButton()
        if openrender == nil {
            status.stringValue = "⚠️ openrender not found — run: swift build -c release"
        }
        if !rows.isEmpty { sceneList.selectRowIndexes([0], byExtendingSelection: false) }
    }

    func reloadSceneList() {
        let names = ((try? FileManager.default.contentsOfDirectory(atPath: repoRoot + "/fixtures/scenes")) ?? [])
            .filter { $0.hasSuffix(".json") }.map { String($0.dropLast(5)) }.sorted()
        let old = Dictionary(uniqueKeysWithValues: rows.map { ($0.name, $0) })
        rows = names.map { old[$0] ?? SceneRow(name: $0) }
    }

    func updateInteractiveButton() {
        interactiveBtn.isEnabled = openhost != nil
        interactiveBtn.toolTip = openhost == nil
            ? "openhost not built yet (lands with milestone M7)"
            : "Launch the live SDL2 host with this scene — click switches, press buttons"
    }

    // MARK: suite dashboard
    @objc func runSuite() {
        guard let openrender else { return }
        status.stringValue = "running full suite…"
        let backend = backendPopup.titleOfSelectedItem ?? "quartz"
        DispatchQueue.global().async { [weak self] in
            let outdir = scratch + "/suite_out"
            try? FileManager.default.removeItem(atPath: outdir)
            let scenes = ((try? FileManager.default.contentsOfDirectory(atPath: repoRoot + "/fixtures/scenes")) ?? [])
                .filter { $0.hasSuffix(".json") }.sorted().map { repoRoot + "/fixtures/scenes/" + $0 }
            let t0 = Date()
            let (rc, out) = run(openrender, ["render", outdir] + scenes,
                                env: ["OPENUIKIT_BACKEND": backend])
            let reportPath = scratch + "/suite_report.json"
            let (_, _) = run("/usr/bin/python3", ["Tools/compare/compare.py", "--out", outdir,
                                                  "--json", reportPath])
            let ms = Int(Date().timeIntervalSince(t0) * 1000)
            var parsed: [[String: Any]] = []
            if let data = FileManager.default.contents(atPath: reportPath),
               let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] {
                parsed = arr
            }
            DispatchQueue.main.async {
                guard let self else { return }
                if rc != 0 && parsed.isEmpty {
                    self.status.stringValue = "⚠️ suite render failed: " + String(out.suffix(140))
                    return
                }
                var byName: [String: (String, Double?, String?)] = [:]
                for e in parsed {
                    guard let n = e["scene"] as? String else { continue }
                    byName[n] = (e["status"] as? String ?? "?",
                                 e["score"] as? Double,
                                 e["category"] as? String)
                }
                self.reloadSceneList()
                for i in self.rows.indices {
                    if let (st, sc, cat) = byName[self.rows[i].name] {
                        self.rows[i].status = st
                        self.rows[i].score = sc
                        self.rows[i].category = cat
                    }
                }
                let pass = parsed.filter { ($0["status"] as? String) == "PASS" }.count
                self.suiteSummary.stringValue = "✅ \(pass)/\(parsed.count) scenes pass"
                if pass < parsed.count {
                    self.suiteSummary.stringValue = "⚠️ \(pass)/\(parsed.count) scenes pass"
                }
                self.status.stringValue = "suite done in \(ms)ms (\(backend) backend)"
                self.sceneList.reloadData()
                self.updateInteractiveButton()
            }
        }
    }

    // MARK: table
    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }
    func tableView(_ t: NSTableView, viewFor c: NSTableColumn?, row: Int) -> NSView? {
        let r = rows[row]
        var text = r.name
        var color = NSColor.labelColor
        if let st = r.status {
            let dot = st == "PASS" ? "🟢" : "🔴"
            let score = r.score.map { String(format: " %.1f", $0) } ?? ""
            text = "\(dot) \(r.name)\(score)"
            color = st == "PASS" ? .labelColor : .systemRed
        }
        let tf = NSTextField(labelWithString: text)
        tf.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        tf.textColor = color
        tf.lineBreakMode = .byTruncatingTail
        return tf
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = sceneList.selectedRow
        guard row >= 0, row < rows.count else { return }
        let path = repoRoot + "/fixtures/scenes/" + rows[row].name + ".json"
        editor.string = (try? String(contentsOfFile: path, encoding: .utf8)) ?? "{}"
        renderNow()
    }

    // MARK: editing
    func textDidChange(_ notification: Notification) {
        guard autoRender.state == .on else { return }
        debounce?.invalidate()
        debounce = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
            self?.renderNow()
        }
    }

    @objc func saveFixture() {
        let row = sceneList.selectedRow
        guard row >= 0 else { return }
        let path = repoRoot + "/fixtures/scenes/" + rows[row].name + ".json"
        try? editor.string.write(toFile: path, atomically: true, encoding: .utf8)
        status.stringValue = "saved \(rows[row].name).json"
    }

    // MARK: interactive host
    @objc func launchInteractive() {
        guard let openhost, sceneList.selectedRow >= 0 else { return }
        let scenePath = repoRoot + "/fixtures/scenes/" + rows[sceneList.selectedRow].name + ".json"
        let p = Process()
        p.launchPath = openhost
        p.arguments = [scenePath]
        p.currentDirectoryPath = repoRoot
        try? p.run()
        status.stringValue = "launched interactive host — click around in the new window"
    }

    // MARK: rendering
    @objc func frameChanged() {
        showFrame(Int(frameSlider.doubleValue.rounded()))
    }

    func showFrame(_ idx: Int) {
        guard idx >= 0, idx < frames.count else { return }
        let f = frames[idx]
        frameLabel.stringValue = "t=\(f.time)s  (\(idx + 1)/\(frames.count))"
        oursView.image = NSImage(contentsOfFile: f.ours)
        goldenView.image = NSImage(contentsOfFile: f.golden)
        if let (score, heat) = diffImages(f.golden, f.ours) {
            diffView.image = heat
            status.stringValue = String(format: "frame t=%@: pixel match %.2f%%", f.time, score)
        }
    }

    @objc func renderNow() {
        if rendering { pendingRender = true; return }
        guard let openrender, let oracle else { return }
        guard let data = editor.string.data(using: .utf8),
              var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            status.stringValue = "⚠️ invalid JSON"
            return
        }
        json["name"] = "playground"
        let isWindowScene = (json["window"] as? Bool) == true
        guard let sceneData = try? JSONSerialization.data(withJSONObject: json) else { return }
        let scenePath = scratch + "/playground.json"
        try? sceneData.write(to: URL(fileURLWithPath: scenePath))
        let backend = backendPopup.titleOfSelectedItem ?? "quartz"
        rendering = true
        status.stringValue = "rendering…"
        let oracle2 = self.oracle2
        DispatchQueue.global().async { [weak self] in
            let oursDir = scratch + "/ours", goldenDir = scratch + "/golden"
            try? FileManager.default.removeItem(atPath: oursDir)
            try? FileManager.default.removeItem(atPath: goldenDir)
            let t0 = Date()
            let (rc1, out1) = run(openrender, ["render", oursDir, scenePath],
                                  env: ["OPENUIKIT_BACKEND": backend])
            let oracleBin = isWindowScene && oracle2 != nil ? oracle2! : oracle
            let (rc2, out2) = run(oracleBin, ["render", goldenDir, scenePath])
            let ms = Int(Date().timeIntervalSince(t0) * 1000)
            // collect frames: playground.png or playground.t###.png
            let oursFiles = ((try? FileManager.default.contentsOfDirectory(atPath: oursDir)) ?? [])
                .filter { $0.hasPrefix("playground") && $0.hasSuffix(".png") }.sorted()
            var newFrames: [(String, String, String)] = []
            for f in oursFiles {
                let g = goldenDir + "/" + f
                guard FileManager.default.fileExists(atPath: g) else { continue }
                var t = "0"
                if let r = f.range(of: ".t"), let dot = f.range(of: ".png") {
                    let ms = String(f[r.upperBound..<dot.lowerBound])
                    t = String(format: "%.3f", (Double(ms) ?? 0) / 1000)
                }
                newFrames.append((t, oursDir + "/" + f, g))
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.rendering = false
                self.updateInteractiveButton()
                if rc1 != 0 || rc2 != 0 {
                    let err = (rc1 != 0 ? "openrender: " + out1 : "oracle: " + out2)
                    let lastLine = err.split(separator: "\n").last.map(String.init) ?? err
                    self.status.stringValue = "⚠️ " + String(lastLine.prefix(160))
                } else {
                    self.frames = newFrames
                    let animated = newFrames.count > 1
                    self.frameSlider.isHidden = !animated
                    self.frameLabel.isHidden = !animated
                    if animated {
                        self.frameSlider.maxValue = Double(newFrames.count - 1)
                        self.frameSlider.numberOfTickMarks = newFrames.count
                        self.frameSlider.doubleValue = 0
                    }
                    self.showFrame(0)
                    if !animated {
                        self.status.stringValue += String(format: "  (%dms, %@)", ms, backend)
                    }
                }
                if self.pendingRender {
                    self.pendingRender = false
                    self.renderNow()
                }
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let controller = PlaygroundController()
controller.setUp()
app.activate(ignoringOtherApps: true)

let menubar = NSMenu()
let appMenuItem = NSMenuItem()
menubar.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)),
                           keyEquivalent: "q"))
appMenuItem.submenu = appMenu
app.mainMenu = menubar

app.run()

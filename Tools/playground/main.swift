// OpenUIKit Playground — edit a scene, watch OpenUIKit vs REAL UIKit live.
//
// Build & run:  ./scripts/playground.sh   (from the repo root)
//
// Left: fixture scenes. Middle: live JSON editor (docs/SCENE_SPEC.md).
// Right: OpenUIKit render | real-UIKit oracle render | diff heatmap + score.
// Renders by invoking the repo's openrender and oracle binaries.

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

/// compare.py semantics: match = per-channel delta <= 6 (on straight RGBA).
func diffImages(_ a: String, _ b: String) -> (score: Double, heatmap: NSImage)? {
    guard let ga = pixelData(a), let gb = pixelData(b), ga.w == gb.w, ga.h == gb.h,
          ga.w > 0 else { return nil }
    let w = ga.w, h = ga.h
    var match = 0
    var heat = [UInt8](repeating: 0, count: w * h * 4)
    for i in 0..<(w * h) {
        var d = 0
        for c in 0..<4 {
            d = max(d, abs(Int(ga.bytes[i * 4 + c]) - Int(gb.bytes[i * 4 + c])))
        }
        let o = i * 4
        if d <= 6 {
            match += 1
            heat[o + 1] = 60  // dim green where matching
        } else {
            heat[o] = UInt8(min(255, d * 4))  // red = diff magnitude
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

final class PlaygroundController: NSObject, NSTableViewDataSource, NSTableViewDelegate,
                                  NSTextViewDelegate {
    var window: NSWindow!
    var sceneList: NSTableView!
    var editor: NSTextView!
    var oursView = NSImageView()
    var goldenView = NSImageView()
    var diffView = NSImageView()
    var status = NSTextField(labelWithString: "")
    var backendPopup = NSPopUpButton()
    var autoRender = NSButton(checkboxWithTitle: "Auto-render", target: nil, action: nil)
    var scenes: [String] = []
    var debounce: Timer?
    var rendering = false
    var pendingRender = false

    let openrender = findBinary([".build/release/openrender", ".build/debug/openrender",
                                 ".build/arm64-apple-macosx/release/openrender",
                                 ".build/arm64-apple-macosx/debug/openrender"])
    let oracle = findBinary(["Tools/oracle/oracle"])
    let oracle2 = findBinary(["Tools/oracle2/run.sh"])

    func setUp() {
        try? FileManager.default.createDirectory(atPath: scratch, withIntermediateDirectories: true)
        scenes = ((try? FileManager.default.contentsOfDirectory(atPath: repoRoot + "/fixtures/scenes")) ?? [])
            .filter { $0.hasSuffix(".json") }.sorted()

        window = NSWindow(contentRect: NSRect(x: 80, y: 80, width: 1440, height: 900),
                          styleMask: [.titled, .closable, .resizable, .miniaturizable],
                          backing: .buffered, defer: false)
        window.title = "OpenUIKit Playground — vs real UIKit"
        window.minSize = NSSize(width: 1000, height: 600)

        // Sidebar
        sceneList = NSTableView()
        let col = NSTableColumn(identifier: .init("scene"))
        col.title = "Scenes"
        sceneList.addTableColumn(col)
        sceneList.dataSource = self
        sceneList.delegate = self
        sceneList.headerView = nil
        let sideScroll = NSScrollView()
        sideScroll.documentView = sceneList
        sideScroll.hasVerticalScroller = true

        // Editor
        let editorScroll = NSScrollView()
        editor = NSTextView()
        editor.isRichText = false
        editor.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        editor.isAutomaticQuoteSubstitutionEnabled = false
        editor.delegate = self
        editor.autoresizingMask = [.width]
        editor.minSize = NSSize(width: 0, height: 0)
        editor.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                height: CGFloat.greatestFiniteMagnitude)
        editor.isVerticallyResizable = true
        editor.textContainer?.widthTracksTextView = true
        editorScroll.documentView = editor
        editorScroll.hasVerticalScroller = true

        // Render panels
        for (v, title) in [(oursView, "OpenUIKit"), (goldenView, "Real UIKit (oracle)"),
                           (diffView, "Diff (red = mismatch)")] {
            v.imageScaling = .scaleProportionallyDown
            v.wantsLayer = true
            v.layer?.backgroundColor = NSColor(white: 0.93, alpha: 1).cgColor
            v.toolTip = title
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
        let renders = NSStackView(views: [labeled(oursView, "OpenUIKit"),
                                          labeled(goldenView, "Real UIKit (oracle)"),
                                          labeled(diffView, "Diff (red = mismatch)")])
        renders.orientation = .vertical
        renders.distribution = .fillEqually
        renders.spacing = 8

        // Toolbar row
        backendPopup.addItems(withTitles: ["quartz", "swift"])
        autoRender.state = .on
        let renderBtn = NSButton(title: "Render ⌘R", target: self, action: #selector(renderNow))
        renderBtn.keyEquivalent = "r"
        renderBtn.keyEquivalentModifierMask = .command
        let saveBtn = NSButton(title: "Save to fixture", target: self, action: #selector(saveFixture))
        status.lineBreakMode = .byTruncatingTail
        let bar = NSStackView(views: [NSTextField(labelWithString: "Backend:"), backendPopup,
                                      renderBtn, saveBtn, autoRender, status])
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
        split.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content
        NSLayoutConstraint.activate([
            split.heightAnchor.constraint(greaterThanOrEqualToConstant: 500),
        ])
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async {
            split.setPosition(230, ofDividerAt: 0)
            split.setPosition(760, ofDividerAt: 1)
        }

        if openrender == nil {
            status.stringValue = "⚠️ openrender binary not found — run: swift build -c release"
        } else if oracle == nil {
            status.stringValue = "⚠️ oracle not found — run: ./scripts/build_oracle.sh"
        }
        if !scenes.isEmpty {
            sceneList.selectRowIndexes([0], byExtendingSelection: false)
        }
    }

    // MARK: table
    func numberOfRows(in tableView: NSTableView) -> Int { scenes.count }
    func tableView(_ t: NSTableView, viewFor c: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField(labelWithString: scenes[row].replacingOccurrences(of: ".json", with: ""))
        text.font = NSFont.systemFont(ofSize: 12)
        return text
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = sceneList.selectedRow
        guard row >= 0, row < scenes.count else { return }
        let path = repoRoot + "/fixtures/scenes/" + scenes[row]
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
        let path = repoRoot + "/fixtures/scenes/" + scenes[row]
        try? editor.string.write(toFile: path, atomically: true, encoding: .utf8)
        status.stringValue = "saved \(scenes[row])"
    }

    // MARK: rendering
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
            let t0 = Date()
            let (rc1, out1) = run(openrender, ["render", scratch + "/ours", scenePath],
                                  env: ["OPENUIKIT_BACKEND": backend])
            let oracleBin = isWindowScene && oracle2 != nil ? oracle2! : oracle
            let (rc2, out2) = run(oracleBin, ["render", scratch + "/golden", scenePath])
            let ms = Int(Date().timeIntervalSince(t0) * 1000)
            DispatchQueue.main.async {
                guard let self else { return }
                self.rendering = false
                if rc1 != 0 || rc2 != 0 {
                    let err = (rc1 != 0 ? "openrender: " + out1 : "oracle: " + out2)
                    let lastLine = err.split(separator: "\n").last.map(String.init) ?? err
                    self.status.stringValue = "⚠️ " + String(lastLine.prefix(160))
                } else {
                    let ours = scratch + "/ours/playground.png"
                    let golden = scratch + "/golden/playground.png"
                    self.oursView.image = NSImage(contentsOfFile: ours)
                    self.goldenView.image = NSImage(contentsOfFile: golden)
                    if let (score, heat) = diffImages(golden, ours) {
                        self.diffView.image = heat
                        self.status.stringValue = String(format: "pixel match: %.2f%%  (%dms, %@ backend)",
                                                         score, ms, backend)
                    } else {
                        self.status.stringValue = "rendered (\(ms)ms) — diff unavailable"
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

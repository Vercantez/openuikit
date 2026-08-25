// objcparity — the Swift twin of ObjCFacade/ProofApp.m.
//
// Same screen, same numbers, same render call. If the ObjC facade adds or
// loses anything, the two PNGs stop matching. scripts/objc_facade_verify.sh
// runs both inside one Linux container and diffs the bytes.
//
// Imports nothing but OpenUIKit and the C shims, so the Swift half of the
// comparison pulls in exactly what the ObjC half's Swift library pulls in.
// (The original reason for the rule — that Foundation's CoreGraphics types
// would clash with OpenUIKit's — stopped applying at M15, when OpenUIKit's CG
// types BECAME Foundation's; see docs/PORTABILITY.md. The remaining reason is
// parity, which is the one that matters here.)

import CPortableIO
import OpenUIKit
import OpenUIKitC

// MARK: - The same UIView subclass, in Swift

final class CardView: UIView {
    let titleLabel = UILabel()
    let bodyLabel = UILabel()
    var layoutPasses = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = "Card laid out by ObjC"
        titleLabel.textColor = UIColor(red: 0.06, green: 0.07, blue: 0.11, alpha: 1)
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        addSubview(titleLabel)

        bodyLabel.text = "-layoutSubviews positioned these."
        bodyLabel.textColor = UIColor(red: 0.36, green: 0.38, blue: 0.44, alpha: 1)
        bodyLabel.font = .systemFont(ofSize: 13, weight: .regular)
        addSubview(bodyLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutPasses += 1
        let b = bounds
        titleLabel.frame = CGRect(x: 16, y: 14, width: b.width - 32, height: 22)
        bodyLabel.frame = CGRect(x: 16, y: 40, width: b.width - 32, height: 18)
    }

    override func draw(_ rect: CGRect) {
        UIColor(red: 0.20, green: 0.45, blue: 0.85, alpha: 1).setFill()
        if let c = UIGraphicsGetCurrentContext() {
            c.fill(rect: CGRect(x: 16, y: 70, width: rect.width - 32, height: 4),
                   color: UIGraphicsCurrentFillColor())
            c.fill(.roundedRect(CGRect(x: 16, y: 86, width: 120, height: 34),
                                cornerRadius: 8),
                   color: CGColor(red: 0.20, green: 0.45, blue: 0.85, alpha: 0.30))
        }
    }
}

// MARK: - The same target-action target, in Swift
//
// Note the asymmetry the prototype exists to measure: this class must declare
// an ActionTable, because Swift off Darwin has no by-name dispatch
// (docs/OBJC_RUNTIME.md). ProofApp.m's equivalent needs nothing — it writes
// `@selector(buttonTapped:)` and the ObjC runtime does the rest.

final class Screen: SelectorDispatching {
    let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    let status = UILabel()
    let card = CardView(frame: CGRect(x: 16, y: 64, width: 288, height: 150))
    let button = UIButton(type: .system)

    static let actions: ActionTable<Screen> = [
        .action("buttonTapped:", Screen.buttonTapped)
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }

    func build() {
        root.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

        let header = UILabel(frame: CGRect(x: 16, y: 20, width: 288, height: 30))
        header.text = "Objective-C on OpenUIKit"
        header.textColor = UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1)
        header.font = .systemFont(ofSize: 22, weight: .semibold)
        root.addSubview(header)

        card.backgroundColor = UIColor(red: 0.92, green: 0.94, blue: 0.98, alpha: 1)
        card.layer.cornerRadius = 14
        card.clipsToBounds = true
        root.addSubview(card)

        button.frame = CGRect(x: 16, y: 232, width: 180, height: 44)
        button.tag = 7
        button.setTitle("Send action", for: .normal)
        button.setTitleColor(UIColor(red: 0, green: 0.48, blue: 1, alpha: 1), for: .normal)
        button.addTarget(self, action: .named("buttonTapped:"), for: .touchUpInside)
        root.addSubview(button)

        status.frame = CGRect(x: 16, y: 288, width: 288, height: 22)
        status.text = "(no action yet)"
        status.textColor = UIColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1)
        status.font = .systemFont(ofSize: 15, weight: .regular)
        root.addSubview(status)

        let footer = UILabel(frame: CGRect(x: 16, y: 322, width: 288, height: 60))
        footer.numberOfLines = 3
        footer.text = "layoutSubviews and drawRect: are Objective-C overrides, "
            + "called back from the Swift render engine."
        footer.textColor = UIColor(red: 0.45, green: 0.46, blue: 0.50, alpha: 1)
        footer.font = .systemFont(ofSize: 13, weight: .regular)
        root.addSubview(footer)
    }

    func buttonTapped(_ sender: AnyObject) {
        let tag = (sender as? UIView)?.tag ?? -1
        status.text = "action fired, sender tag \(tag)"
    }
}

// MARK: - main

func env(_ name: String) -> String? {
    name.withCString { k in cpio_getenv(k).map { String(cString: $0) } }
}

func logErr(_ s: String) { s.withCString { cpio_log_stderr($0) } }

// Top-level code in `main.swift` is NOT main-actor isolated, but everything
// below it builds, lays out and renders UIKit objects, and those are
// `@MainActor` now -- exactly as they are in real UIKit. The tool is
// single-threaded and this IS the process's main thread, so state that once
// here and let the compiler check the rest. `assumeIsolated` traps if the
// assumption is ever violated. Same crossing, same reason, as openrender and
// openhost -- and as the C ABI's `oukMain` (Sources/OpenUIKitC/Runtime.swift),
// which is what the ObjC half of this comparison goes through.
MainActor.assumeIsolated {
    let args = CommandLine.arguments
    guard args.count >= 2 else {
        logErr("usage: objcparity <out.png> [resource-root] [font-dir]")
        cpio_exit(2)
        fatalError()
    }
    if args.count > 2 { OpenUIKitRuntime.resourceRoot = args[2] }
    if args.count > 3 {
        let base = args[3].hasSuffix("/") ? String(args[3].dropLast()) : args[3]
        for (key, file) in [("system", "SFNS.ttf"), ("mono", "SFNSMono.ttf"),
                            ("italic", "SFNSItalic.ttf")] {
            let path = base + "/" + file
            if ResourceIO.readFile(path) != nil { OpenUIKitRuntime.fontPaths[key] = path }
        }
    }
    OpenUIKitRuntime.renderBackend = (env("OPENUIKIT_BACKEND") == "quartz") ? .quartz : .swift

    let screen = Screen()
    screen.build()
    screen.button.sendActions(for: .touchUpInside)

    // Render through the SAME entry point the ObjC facade uses, so the comparison
    // isolates the bridge and not the PNG writer.
    let ok = args[1].withCString { p in
        openuikit_render_png(Unmanaged.passUnretained(screen.root).toOpaque(), 2.0, p)
    }
    if ok == 0 {
        logErr("render failed")
        cpio_exit(1)
    }
    print("swift: layout passes = \(screen.card.layoutPasses)")
    print("swift: status = \(screen.status.text ?? "")")
    print("swift: wrote \(args[1])")
}

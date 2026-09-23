// SwiftUI rows NetNewsWire needs: the exact iOS system colours behind
// SwiftUI's Color statics (light and dark), `.link`, UIColor(Color), and a
// few defaults. iPhone 16 / iOS 26.1.
import SwiftUI
import UIKit

func rgba(_ c: UIColor) -> String {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    c.getRed(&r, green: &g, blue: &b, alpha: &a)
    func q(_ v: CGFloat) -> String { String(format: "%.4f", Double(v)) }
    return "(\(q(r)),\(q(g)),\(q(b)),\(q(a)))"
}

@MainActor func pixel<V: View>(_ v: V) -> String {
    let r = ImageRenderer(content: v)
    r.scale = 1
    guard let cg = r.cgImage,
          let ctx = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return "nil" }
    ctx.draw(cg, in: CGRect(x: -1, y: -1, width: cg.width, height: cg.height))
    let p = ctx.data!.assumingMemoryBound(to: UInt8.self)
    return "(\(p[0]),\(p[1]),\(p[2]),\(p[3]))"
}

@MainActor func run() {
    let light = UITraitCollection(userInterfaceStyle: .light)
    let dark = UITraitCollection(userInterfaceStyle: .dark)
    let colors: [(String, Color)] = [
        ("red", .red), ("orange", .orange), ("yellow", .yellow), ("green", .green),
        ("mint", .mint), ("teal", .teal), ("cyan", .cyan), ("blue", .blue),
        ("indigo", .indigo), ("purple", .purple), ("pink", .pink), ("brown", .brown),
        ("gray", .gray), ("black", .black), ("white", .white), ("clear", .clear),
        ("primary", .primary), ("secondary", .secondary), ("accentColor", .accentColor),
    ]
    for (name, color) in colors {
        let ui = UIColor(color)
        print("FACT Color.\(name) UIColor(Color) light=\(rgba(ui.resolvedColor(with: light))) dark=\(rgba(ui.resolvedColor(with: dark)))")
        var envL = EnvironmentValues(); envL.colorScheme = .light
        var envD = EnvironmentValues(); envD.colorScheme = .dark
        let rl = color.resolve(in: envL), rd = color.resolve(in: envD)
        print("FACT Color.\(name) resolve light=(\(rl.red),\(rl.green),\(rl.blue),\(rl.opacity)) dark=(\(rd.red),\(rd.green),\(rd.blue),\(rd.opacity))")
    }
    let systems: [(String, UIColor)] = [
        ("systemRed", .systemRed), ("systemOrange", .systemOrange), ("systemYellow", .systemYellow),
        ("systemGreen", .systemGreen), ("systemMint", .systemMint), ("systemTeal", .systemTeal),
        ("systemCyan", .systemCyan), ("systemBlue", .systemBlue), ("systemIndigo", .systemIndigo),
        ("systemPurple", .systemPurple), ("systemPink", .systemPink), ("systemBrown", .systemBrown),
        ("systemGray", .systemGray), ("link", .link), ("label", .label), ("secondaryLabel", .secondaryLabel),
    ]
    for (name, c) in systems {
        print("FACT UIColor.\(name) light=\(rgba(c.resolvedColor(with: light))) dark=\(rgba(c.resolvedColor(with: dark)))")
    }
    var envL = EnvironmentValues(); envL.colorScheme = .light
    var envD = EnvironmentValues(); envD.colorScheme = .dark
    for (label, scheme) in [("light", ColorScheme.light), ("dark", ColorScheme.dark)] {
        print("FACT fill(.link) \(label) pixel=\(pixel(Rectangle().fill(.link).frame(width: 4, height: 4).environment(\.colorScheme, scheme)))")
        print("FACT fill(AnyShapeStyle(.secondary)) \(label) pixel=\(pixel(Rectangle().fill(AnyShapeStyle(.secondary)).frame(width: 4, height: 4).environment(\.colorScheme, scheme)))")
        print("FACT fill(Color.teal) \(label) pixel=\(pixel(Rectangle().fill(Color.teal).frame(width: 4, height: 4).environment(\.colorScheme, scheme)))")
    }
    print("FACT ButtonRole.close describing=\(String(describing: ButtonRole.close)) destructive=\(String(describing: ButtonRole.destructive)) equalCancel=\(ButtonRole.close == .cancel)")
    print("FACT VerticalAlignment firstTextBaseline==center \(VerticalAlignment.firstTextBaseline == .center) lastTextBaseline==firstTextBaseline \(VerticalAlignment.lastTextBaseline == .firstTextBaseline)")
    print("FACT TextSelectability enabled allowsSelection=\(EnabledTextSelectability.allowsSelection) disabled=\(DisabledTextSelectability.allowsSelection)")
    hosted()
}

nonisolated(unsafe) var frames: [String: CGRect] = [:]
struct FrameProbe: View {
    let name: String
    var body: some View {
        Color.clear.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames[name] = $0 }
    }
}

struct Hosted: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Color.red.frame(height: 10).scenePadding(.horizontal).background(FrameProbe(name: "scenePadding(.horizontal) outer"))
                    .overlay(FrameProbe(name: "unused"))
                Color.blue.frame(height: 10).scenePadding(.horizontal).overlay(EmptyView())
                    .background(FrameProbe(name: "scenePadding outer2"))
                Color.green.frame(height: 10).background(FrameProbe(name: "scenePadding inner")).scenePadding(.horizontal)
                Text(verbatim: "Hg").font(.body).background(FrameProbe(name: "body text"))
                Text(verbatim: "Hg").font(.system(.body, design: .monospaced)).background(FrameProbe(name: "mono body text"))
                Text(verbatim: "Hg").font(.system(.body, design: .monospaced).weight(.medium)).background(FrameProbe(name: "mono medium body text"))
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "checkmark.circle").background(FrameProbe(name: "ftb image"))
                    Text(verbatim: "Hg").font(.footnote).background(FrameProbe(name: "ftb footnote"))
                    Text(verbatim: "Hg").font(.title).background(FrameProbe(name: "ftb title"))
                }.background(FrameProbe(name: "ftb hstack"))
                Picker("", selection: .constant(6)) {
                    ForEach([3, 6, 12, 24], id: \.self) { m in Text(verbatim: "\(m) months").tag(m) }
                }.pickerStyle(.segmented).background(FrameProbe(name: "segmented picker"))
                LabeledContent {
                    Text(verbatim: "Value")
                } label: {
                    Text(verbatim: "Label")
                }.font(.caption).background(FrameProbe(name: "labeledContent"))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {}
                }
            }
            .navigationTitle(Text(verbatim: "Title"))
            .navigationSubtitle(Text(verbatim: "Subtitle"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

@MainActor func dumpTree(_ v: UIView, _ depth: Int = 0) {
    let pad = String(repeating: " ", count: depth)
    var extra = ""
    if let l = v as? UILabel { extra = " text=\(l.text ?? "nil") font=\(l.font.pointSize) color=\(rgba(l.textColor))" }
    if let i = v as? UIImageView, let img = i.image { extra = " image=\(img.size) sym=\(String(describing: img).contains("xmark"))" }
    if v.accessibilityLabel != nil { extra += " ax=\(v.accessibilityLabel!)" }
    print("FACT TREE \(pad)\(type(of: v)) \(v.frame)\(extra)")
    for s in v.subviews { dumpTree(s, depth + 1) }
}

@MainActor func hosted() {
    let host = UIHostingController(rootView: Hosted())
    let w = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first!.windows.first!
    w.rootViewController = host
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        for (k, v) in frames.sorted(by: { $0.key < $1.key }) { print("FACT frame \(k) = \(v)") }
        func findNav(_ v: UIView) -> UINavigationBar? {
            if let n = v as? UINavigationBar { return n }
            for s in v.subviews { if let n = findNav(s) { return n } }
            return nil
        }
        if let nav = findNav(w) {
            let item = nav.topItem
            print("FACT navItem title=\(item?.title ?? "nil") subtitle=\(item?.subtitle ?? "nil") right=\(item?.rightBarButtonItems?.map { "title=\($0.title ?? "nil") image=\($0.image.map { "\($0)" } ?? "nil") ax=\($0.accessibilityLabel ?? "nil")" } ?? [])")
            func findSeg(_ v: UIView) -> UISegmentedControl? {
                if let s = v as? UISegmentedControl { return s }
                for c in v.subviews { if let s = findSeg(c) { return s } }
                return nil
            }
            if let seg = findSeg(w) {
                print("FACT segmented UIKit=\(type(of: seg)) frame=\(seg.convert(seg.bounds, to: nil)) count=\(seg.numberOfSegments) selected=\(seg.selectedSegmentIndex) titles=\((0..<seg.numberOfSegments).map { seg.titleForSegment(at: $0) ?? "nil" })")
            } else { print("FACT segmented UIKit=none") }
            dumpTree(nav)
            func axWalk(_ v: UIView) {
                if let l = v.accessibilityLabel, !l.isEmpty { print("FACT navbar ax \(type(of: v)) label=\(l) frame=\(v.convert(v.bounds, to: nil))") }
                for e in (v.accessibilityElements ?? []) { if let o = e as? NSObject { print("FACT navbar axElement \(type(of: o)) label=\(o.accessibilityLabel ?? "nil")") } }
                for s in v.subviews { axWalk(s) }
            }
            axWalk(nav)
        }
        print("DONE")
        exit(0)
    }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = UIViewController()
        w.makeKeyAndVisible()
        window = w
        DispatchQueue.main.async { run() }
        return true
    }
}

// About screen. Owner: demo app (M7.5).
//
// APP_FEEL detail screen #3: static value rows plus a LONG scrollable text
// block (multi-paragraph UILabels) — the screen exists to exercise reading-
// length scrolling on a pushed VC.

import OpenUIKit

public final class AboutViewController: UIViewController, BottomInsetAdjustable {
    let scrollView = UIScrollView()

    public var extraBottomInset: CGFloat = 0

    public init() { super.init() }

    public override func viewDidLoad() {
        if title == nil { title = "About" }
        view.backgroundColor = .systemGroupedBackground

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset.bottom = extraBottomInset
        view.addSubview(scrollView)

        let margin: CGFloat = 16
        let width = view.bounds.width - 2 * margin
        var y: CGFloat = 18

        func valueRow(_ title: String, _ value: String) -> SettingsRow {
            SettingsRow(title: title, accessory: .detail(value))
        }
        let card = GroupCard(rows: [
            valueRow("Name", "OpenUIKit Demo"),
            valueRow("Framework", "OpenUIKit"),
            valueRow("Milestone", "M7.5"),
            valueRow("Backend", "quartz"),
            valueRow("Compositor", "QZLayer"),
            valueRow("Scenes", "56 passing"),
        ])
        card.frame = CGRect(x: margin, y: y, width: width,
                            height: card.bounds.height)
        card.autoresizingMask = [.flexibleWidth]
        scrollView.addSubview(card)
        y = card.frame.maxY + 30

        let header = makeSectionHeader("COLOPHON")
        let hs = header.intrinsicContentSize
        header.frame = CGRect(x: margin + 16, y: y, width: hs.width,
                              height: hs.height)
        scrollView.addSubview(header)
        y = header.frame.maxY + 7

        // Long text block: one card, many paragraphs.
        let paragraphs = [
            "OpenUIKit is a portable reimplementation of UIKit. Every visual "
            + "behavior in this app — text layout, colors, controls, "
            + "animations, scrolling and navigation — is rendered by the "
            + "portable stack and validated pixel-by-pixel against real "
            + "UIKit running under Mac Catalyst.",
            "The scrolling in this very screen uses UIKit's exact physics: "
            + "content tracks the finger 1:1, release velocity is measured "
            + "over the last 100 milliseconds, momentum decays at 0.998 per "
            + "millisecond, and overscroll rubber-bands with Apple's 0.55 "
            + "coefficient before springing back on a critically damped "
            + "spring.",
            "Navigation transitions run the measured iOS curve: 0.35 seconds "
            + "ease-in-out, the incoming screen sliding over an outgoing "
            + "screen that parallaxes to minus thirty percent of its width "
            + "under a dimming scrim, with a soft shadow on the leading "
            + "edge. The back swipe scrubs the same transition "
            + "interactively.",
            "Text is shaped with the platform's variable San Francisco "
            + "fonts through a portable font engine whose metrics, kerning "
            + "and glyph smoothing were captured from — and are continuously "
            + "compared against — the real Core Text rasterizer.",
            "The switch you can toggle on the Display & Brightness screen "
            + "replays the exact hybrid animation a real UISwitch performs: "
            + "a spring-driven track well and a display-link thumb whose "
            + "travel curve was fitted from golden captures to within a "
            + "thousandth of its range.",
            "Rendering goes through quartz, a portable Quartz 2D and Core "
            + "Animation reimplementation, composited by its CALayer engine "
            + "— the same pipeline the golden test suite renders through, "
            + "so what you see here is what the tests measure.",
            "This screen intentionally holds more text than fits, so that "
            + "reading it exercises deceleration into the bottom edge and "
            + "the bounce that follows. Flick hard and watch the scroll "
            + "indicator compress as the content overshoots.",
        ]
        for text in paragraphs {
            let l = UILabel()
            l.text = text
            l.font = .systemFont(ofSize: 15)
            l.textColor = .label
            l.numberOfLines = 0
            let size = l.sizeThatFits(CGSize(width: width - 32, height: 10_000))
            l.frame = CGRect(x: margin + 16, y: y, width: width - 32,
                             height: size.height)
            scrollView.addSubview(l)
            y += size.height + 14
        }
        y += 16

        scrollView.contentSize = CGSize(width: view.bounds.width, height: y)
    }
}

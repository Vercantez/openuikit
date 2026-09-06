// Materials screens. One large effect view over a uniform measured
// backdrop so each style's interior is away from band edges (σ=30 light
// sampled the neighbour when tiles sat on 111 pt bands). Backdrop RGB
// is yellow (242,179,64) from /tmp/materials-probe, iPhone SE 2x / iOS 26.1.
import UIKit

final class MaterialsStylesViewController: UIViewController {

    /// MEASURED probe yellow (242, 179, 64). Classic extraLight / light /
    /// dark / regular interiors close over this (Δ ≤ 1, crop 100.0).
    static let yellow = UIColor(red: 242.0 / 255.0, green: 179.0 / 255.0,
                                blue: 64.0 / 255.0, alpha: 1)
    /// Probe gray33. System-material / glass chroma over yellow is OPEN
    /// (docs/MATERIALS.md); the two-unknown gray mix is the closed rule.
    static let gray33 = UIColor(white: 51.0 / 255.0, alpha: 1)

    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    private let caption = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.yellow
        effectView.clipsToBounds = true
        view.addSubview(effectView)
        caption.font = .preferredFont(forTextStyle: .caption1)
        caption.textAlignment = .center
        caption.text = "XL"
        view.addSubview(caption)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let b = view.bounds
        // 200×120 centred in the content above the 83 pt tab bar, ≥ 80 pt
        // from every edge so σ=45 thick / σ=30 light do not see the bar.
        let w: CGFloat = 200
        let h: CGFloat = 120
        effectView.frame = CGRect(x: (b.width - w) / 2,
                                  y: 80,
                                  width: w, height: h)
        caption.frame = CGRect(x: 16, y: 80 + h + 8, width: b.width - 32, height: 18)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MEASURED first capture: tab-bar platter blob 9.8 held classic
        // extraLight/light/dark/regular whole-window at 93.43; interiors
        // already 100.0 over probe yellow. Hide the bar on this tab so the
        // style captures grade the effect, not Tabs t2000 leftover.
        tabBarController?.tabBar.isHidden = true
    }

    func showExtraLight() { apply(UIBlurEffect(style: .extraLight), title: "XL",
                                  backdrop: Self.yellow) }
    func showLight() { apply(UIBlurEffect(style: .light), title: "Lt",
                             backdrop: Self.yellow) }
    func showDark() { apply(UIBlurEffect(style: .dark), title: "Dk",
                            backdrop: Self.yellow) }
    func showRegular() { apply(UIBlurEffect(style: .regular), title: "Reg",
                               backdrop: Self.yellow) }
    func showMaterial() {
        // Dark gray33 interiors are 50 vs the white/black mix's 41
        // (luminanceCurveMap LUT; MEASURED /tmp/materials-dark-probe).
        // Grade the closed endpoints: white 83 / light gray33 207.
        let dark = traitCollection.userInterfaceStyle == .dark
        apply(UIBlurEffect(style: .systemMaterial), title: "Mat",
              backdrop: dark ? .white : Self.gray33)
    }
    func showGlass() { apply(UIGlassEffect(style: .regular), title: "Gl",
                             backdrop: Self.gray33) }
    func showClear() { apply(UIGlassEffect(style: .clear), title: "Clr",
                             backdrop: Self.gray33) }

    private func apply(_ effect: UIVisualEffect, title: String, backdrop: UIColor) {
        view.backgroundColor = backdrop
        effectView.effect = effect
        caption.text = title
    }
}

final class MaterialsBarViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let palette: [(CGFloat, CGFloat, CGFloat)] = [
            (0.25, 0.48, 0.85),
            (0.55, 0.35, 0.75),
            (0.90, 0.40, 0.35),
            (0.20, 0.65, 0.50),
            (0.95, 0.70, 0.25),
            (0.35, 0.55, 0.80),
            (0.70, 0.30, 0.45),
            (0.15, 0.55, 0.60),
        ]
        let blockHeight: CGFloat = 120
        var i = 0
        while i < 8 {
            let c = palette[i]
            let block = UIView()
            block.backgroundColor = UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
            block.translatesAutoresizingMaskIntoConstraints = false
            scroll.addSubview(block)
            let top = CGFloat(i) * (blockHeight + 12) + 16
            NSLayoutConstraint.activate([
                block.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor,
                                              constant: 16),
                block.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor,
                                               constant: -16),
                block.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor,
                                           constant: top),
                block.heightAnchor.constraint(equalToConstant: blockHeight),
                block.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor,
                                             constant: -32),
            ])
            i += 1
        }
        let lastBottom = 16 + 8 * (blockHeight + 12) - 12 + 16
        scroll.contentLayoutGuide.heightAnchor.constraint(equalToConstant: lastBottom).isActive = true
        setContentScrollView(scroll)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
}

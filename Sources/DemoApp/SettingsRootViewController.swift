// Settings root screen. Owner: demo app (M7.5).
//
// The APP_FEEL root: nav bar "Settings", a UIScrollView of inset-grouped
// cards — profile card up top, toggle rows, disclosure rows (more content
// than fits on screen, so flick/momentum/rubber-band physics are always
// exercised). Disclosure rows push their detail VC with the animated
// transition; the profile card and generic rows push placeholder details.

import OpenUIKit

// MARK: - Profile card

final class ProfileCard: UIControl {
    static let height: CGFloat = 78

    let avatar = UIView()
    let initials = UILabel()
    let nameLabel = UILabel()
    let subtitleLabel = UILabel()
    let chevron = UILabel()

    var onTap: (() -> Void)?

    init(name: String, subtitle: String, monogram: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: 358,
                                 height: ProfileCard.height))
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 10
        clipsToBounds = true

        avatar.backgroundColor = .systemGray
        avatar.layer.cornerRadius = 27
        avatar.isUserInteractionEnabled = false
        addSubview(avatar)

        initials.text = monogram
        initials.font = .systemFont(ofSize: 22)
        initials.textColor = .white
        avatar.addSubview(initials)

        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 20)
        nameLabel.textColor = .label
        addSubview(nameLabel)

        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        addSubview(subtitleLabel)

        chevron.text = "\u{203A}"
        chevron.font = .systemFont(ofSize: 17, weight: .semibold)
        chevron.textColor = .systemGray2
        addSubview(chevron)

        addTarget(for: .touchUpInside) { [weak self] _, _ in self?.onTap?() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        avatar.frame = CGRect(x: 14, y: (h - 54) / 2, width: 54, height: 54)
        let i = initials.intrinsicContentSize
        initials.frame = CGRect(x: (54 - i.width) / 2, y: (54 - i.height) / 2,
                                width: i.width, height: i.height)
        let n = nameLabel.intrinsicContentSize
        let s = subtitleLabel.intrinsicContentSize
        let textX: CGFloat = 14 + 54 + 12
        let block = n.height + 3 + s.height
        nameLabel.frame = CGRect(x: textX, y: (h - block) / 2,
                                 width: n.width, height: n.height)
        subtitleLabel.frame = CGRect(x: textX,
                                     y: nameLabel.frame.maxY + 3,
                                     width: s.width, height: s.height)
        let c = chevron.intrinsicContentSize
        chevron.frame = CGRect(x: bounds.width - 16 - c.width,
                               y: (h - c.height) / 2,
                               width: c.width, height: c.height)
    }

    override func stateDidChange() {
        super.stateDidChange()
        if isHighlighted {
            removeAllAnimations()
            backgroundColor = .systemGray4
        } else {
            UIView.animate(withDuration: SettingsRow.highlightFadeDuration,
                           delay: 0, options: .curveLinear, animations: {
                self.backgroundColor = .secondarySystemGroupedBackground
            })
        }
    }
}

// MARK: - Placeholder detail (rows without a dedicated screen)

final class PlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        view.backgroundColor = .systemGroupedBackground
        let card = UIView(frame: CGRect(x: 16, y: 20,
                                        width: view.bounds.width - 32,
                                        height: 108))
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        card.autoresizingMask = [.flexibleWidth]
        view.addSubview(card)

        let heading = UILabel()
        heading.text = title
        heading.font = .systemFont(ofSize: 20, weight: .semibold)
        heading.frame = CGRect(x: 16, y: 18, width: card.bounds.width - 32,
                               height: 24)
        card.addSubview(heading)

        let body = UILabel()
        body.text = "Nothing to configure here yet.\nSwipe from the left edge or tap Back."
        body.font = .systemFont(ofSize: 15)
        body.textColor = .secondaryLabel
        body.numberOfLines = 0
        body.frame = CGRect(x: 16, y: 50, width: card.bounds.width - 32,
                            height: 44)
        card.addSubview(body)
    }
}

// MARK: - Root

public final class SettingsRootViewController: UIViewController {
    let scrollView = UIScrollView()

    public override init() { super.init() }

    public override func viewDidLoad() {
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        let margin: CGFloat = 16
        let width = view.bounds.width - 2 * margin
        var y: CGFloat = 18

        // Profile card.
        let profile = ProfileCard(name: "Miguel Salinas",
                                  subtitle: "Apple Account, iCloud, and more",
                                  monogram: "MS")
        profile.frame = CGRect(x: margin, y: y, width: width,
                               height: ProfileCard.height)
        profile.autoresizingMask = [.flexibleWidth]
        profile.onTap = { [weak self] in
            self?.push(PlaceholderViewController(), title: "Apple Account")
        }
        scrollView.addSubview(profile)
        y = profile.frame.maxY + 22

        // Grouped sections.
        for group in makeGroups() {
            let card = GroupCard(rows: group)
            card.frame = CGRect(x: margin, y: y, width: width,
                                height: card.bounds.height)
            card.autoresizingMask = [.flexibleWidth]
            scrollView.addSubview(card)
            y = card.frame.maxY + 22
        }

        scrollView.contentSize = CGSize(width: view.bounds.width, height: y)
    }

    func push(_ vc: UIViewController, title: String) {
        vc.title = title
        navigationController?.pushViewController(vc, animated: true)
    }

    func disclosureRow(icon: IconGlyph, color: UIColor, title: String,
                       makeVC: @escaping () -> UIViewController) -> SettingsRow {
        let row = SettingsRow(icon: icon, iconColor: color, title: title,
                              accessory: .chevron)
        row.onTap = { [weak self] _ in self?.push(makeVC(), title: title) }
        return row
    }

    func valueRow(icon: IconGlyph, color: UIColor, title: String,
                  value: String) -> SettingsRow {
        let row = SettingsRow(icon: icon, iconColor: color, title: title,
                              accessory: .value(value))
        row.onTap = { [weak self] _ in
            self?.push(PlaceholderViewController(), title: title)
        }
        return row
    }

    func makeGroups() -> [[SettingsRow]] {
        let airplane = SettingsRow(icon: .airplane, iconColor: .systemOrange,
                                   title: "Airplane Mode",
                                   accessory: .toggle(false))
        return [
            [
                airplane,
                valueRow(icon: .wifi, color: .systemBlue, title: "Wi-Fi",
                         value: "HomeNet"),
                valueRow(icon: .bluetooth, color: .systemBlue,
                         title: "Bluetooth", value: "On"),
                disclosureRow(icon: .cellular, color: .systemGreen,
                              title: "Cellular") { PlaceholderViewController() },
                disclosureRow(icon: .battery, color: .systemGreen,
                              title: "Battery") { PlaceholderViewController() },
            ],
            [
                disclosureRow(icon: .bell, color: .systemRed,
                              title: "Notifications") { PlaceholderViewController() },
                disclosureRow(icon: .speaker, color: .systemPink,
                              title: "Sounds & Haptics") { PlaceholderViewController() },
                disclosureRow(icon: .moon, color: .systemIndigo,
                              title: "Focus") { PlaceholderViewController() },
                disclosureRow(icon: .hourglass, color: .systemIndigo,
                              title: "Screen Time") { PlaceholderViewController() },
            ],
            [
                disclosureRow(icon: .gear, color: .systemGray,
                              title: "General") { PlaceholderViewController() },
                disclosureRow(icon: .toggles, color: .systemGray,
                              title: "Control Center") { PlaceholderViewController() },
                disclosureRow(icon: .sun, color: .systemBlue,
                              title: "Display & Brightness") {
                    DisplayBrightnessViewController()
                },
                disclosureRow(icon: .grid, color: .systemBlue,
                              title: "Home Screen") { PlaceholderViewController() },
                disclosureRow(icon: .person, color: .systemBlue,
                              title: "Accessibility") { PlaceholderViewController() },
                disclosureRow(icon: .shield, color: .systemBlue,
                              title: "Privacy & Security") { PlaceholderViewController() },
            ],
            [
                disclosureRow(icon: .info, color: .systemGray,
                              title: "About") { AboutViewController() },
            ],
        ]
    }
}

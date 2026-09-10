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

    /// Rebind the card's two lines (the profile sheet edits them).
    func setProfile(name: String, subtitle: String) {
        nameLabel.text = name
        nameLabel.setNeedsDisplay()
        subtitleLabel.text = subtitle
        subtitleLabel.setNeedsDisplay()
        setNeedsLayout()
    }

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

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

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

public final class SettingsRootViewController: UIViewController,
                                               BottomInsetAdjustable {
    public let scrollView = UIScrollView()
    var profileCard: ProfileCard!
    var profileName = "Miguel Salinas"
    var profileEmail = "miguel@camelqa.com"

    /// Extra bottom inset for chrome the controller does not own (the
    /// showcase app's floating tab bar). Set before the view loads.
    public var extraBottomInset: CGFloat = 0

    public init() { super.init() }
    public required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.alwaysBounceVertical = true
        scrollView.contentInset.bottom = extraBottomInset
        view.addSubview(scrollView)
        // Drive the navigation bar's large title from this scroll view when
        // the stack asks for large titles (no automatic detection exists —
        // the binding is explicit, like UIKit's setContentScrollView).
        setContentScrollView(scrollView)

        let margin: CGFloat = 16
        let width = view.bounds.width - 2 * margin
        var y: CGFloat = 18

        // Profile card.
        let profile = ProfileCard(name: profileName,
                                  subtitle: "Apple Account, iCloud, and more",
                                  monogram: "MS")
        profileCard = profile
        profile.frame = CGRect(x: margin, y: y, width: width,
                               height: ProfileCard.height)
        profile.autoresizingMask = [.flexibleWidth]
        profile.onTap = { [weak self] in self?.presentProfileEditor() }
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
        (vc as? BottomInsetAdjustable)?.extraBottomInset = extraBottomInset
        navigationController?.pushViewController(vc, animated: true)
    }

    /// The profile card opens the account editor as a pageSheet — the M10
    /// modal presentation, over the whole window (navigation bar and tab bar
    /// included), dimming the base at 20%.
    func presentProfileEditor() {
        let editor = ProfileEditorViewController(name: profileName,
                                                 email: profileEmail)
        editor.onDone = { [weak self] name, email in
            guard let self else { return }
            self.profileName = name
            self.profileEmail = email
            self.profileCard.setProfile(name: name,
                                        subtitle: "Apple Account, iCloud, and more")
        }
        present(editor, animated: true)
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

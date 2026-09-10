// UIButton.Configuration, against the iOS 26.1 oracle.
//
// Every expected number below is a row of
// Tools/oracle2/buttonconfigprobe/ios-26.1-iphone16.json, measured on an
// iPhone 16 / iOS 26.1 (3x, light). The scope is Kickstarter's: the 28
// UIButton.Configuration uses in KDS plus the six in Kickstarter-Framework
// and Library. See docs/agent_reports/uibutton-configuration.md.
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class UIButtonConfigurationTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut = .macOS

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        // The oracle is iOS, not Catalyst; the port's font metrics differ.
        OpenUIKitRuntime.systemFontCut = .iOS
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                      displayScale: 3)
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    // MARK: Helpers

    /// A configured button laid out at the given size (its intrinsic size by
    /// default), the way the probe hosted every one of its measurements.
    private func laidOut(_ configuration: UIButton.Configuration,
                         width: CGFloat? = nil, height: CGFloat? = nil,
                         _ tweak: (UIButton) -> Void = { _ in }) -> UIButton {
        let button = UIButton(configuration: configuration)
        tweak(button)
        let intrinsic = button.intrinsicContentSize
        button.frame = CGRect(x: 0, y: 0,
                              width: width ?? intrinsic.width,
                              height: height ?? intrinsic.height)
        button.layoutIfNeeded()
        return button
    }

    private func rgba(_ color: UIColor?) -> [CGFloat]? {
        guard let resolved = color?.resolvedCGColor(with: UITraitCollection.current)
        else { return nil }
        return [resolved.red, resolved.green, resolved.blue, resolved.alpha]
    }

    private func assertColor(_ color: UIColor?, _ expected: [CGFloat],
                             _ label: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        guard let actual = rgba(color) else {
            return XCTFail("\(label): expected \(expected), got nil", file: file, line: line)
        }
        for i in 0..<4 {
            XCTAssertEqual(actual[i], expected[i], accuracy: 0.002,
                           "\(label) component \(i)", file: file, line: line)
        }
    }

    private static let tint: [CGFloat] = [0, 0.533333, 1, 1]
    private static let white: [CGFloat] = [1, 1, 1, 1]
    private static let black: [CGFloat] = [0, 0, 0, 1]
    /// `tertiaryLabel` in light mode: (60, 60, 67) at alpha 0.298.
    private static let tertiary: [CGFloat] = [0.235294, 0.235294, 0.262745, 0.298039]
    /// The system gray fill (120, 120, 128), at whatever alpha.
    private static func gray(_ alpha: CGFloat) -> [CGFloat] {
        [120.0 / 255, 120.0 / 255, 128.0 / 255, alpha]
    }

    private func configured(_ title: String = "Configure") -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        return configuration
    }

    // MARK: - Factory defaults

    func testEveryFactoryCarriesTheMeasuredDefaults() {
        // Measured `factoryDefaults`: identical across all eight classic
        // factories.
        let factories: [(String, UIButton.Configuration)] = [
            ("plain", .plain()), ("gray", .gray()), ("tinted", .tinted()),
            ("filled", .filled()), ("borderless", .borderless()), ("bordered", .bordered()),
            ("borderedTinted", .borderedTinted()),
            ("borderedProminent", .borderedProminent()),
        ]
        for (name, configuration) in factories {
            XCTAssertEqual(configuration.contentInsets,
                           OpenUIKit.NSDirectionalEdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12),
                           "\(name) contentInsets")
            XCTAssertEqual(configuration.imagePadding, 0, "\(name) imagePadding")
            XCTAssertEqual(configuration.titlePadding, 1, "\(name) titlePadding")
            XCTAssertEqual(configuration.imagePlacement, .leading, "\(name) imagePlacement")
            XCTAssertEqual(configuration.titleAlignment, .automatic, "\(name) titleAlignment")
            XCTAssertEqual(configuration.titleLineBreakMode, .byWordWrapping,
                           "\(name) titleLineBreakMode")
            XCTAssertEqual(configuration.buttonSize, .medium, "\(name) buttonSize")
            XCTAssertNil(configuration.baseForegroundColor, "\(name) baseForegroundColor")
            XCTAssertNil(configuration.baseBackgroundColor, "\(name) baseBackgroundColor")
            XCTAssertFalse(configuration.showsActivityIndicator,
                           "\(name) showsActivityIndicator")
            XCTAssertEqual(configuration.imageReservation, 0, "\(name) imageReservation")
            XCTAssertEqual(configuration.cornerStyle, .dynamic, "\(name) cornerStyle")
            XCTAssertEqual(configuration.background.cornerRadius, 17,
                           "\(name) background.cornerRadius")
            XCTAssertEqual(configuration.background.strokeWidth, 1,
                           "\(name) background.strokeWidth")
        }
    }

    func testAutomaticallyUpdateForSelectionIsFalseOnlyForProminentFactories() {
        // Measured: false for `.filled()`, `.borderedProminent()` and the
        // glass family; true for the other five.
        XCTAssertFalse(UIButton.Configuration.filled().automaticallyUpdateForSelection)
        XCTAssertFalse(UIButton.Configuration.borderedProminent().automaticallyUpdateForSelection)
        XCTAssertFalse(UIButton.Configuration.glass().automaticallyUpdateForSelection)
        XCTAssertTrue(UIButton.Configuration.plain().automaticallyUpdateForSelection)
        XCTAssertTrue(UIButton.Configuration.gray().automaticallyUpdateForSelection)
        XCTAssertTrue(UIButton.Configuration.tinted().automaticallyUpdateForSelection)
        XCTAssertTrue(UIButton.Configuration.borderless().automaticallyUpdateForSelection)
        XCTAssertTrue(UIButton.Configuration.bordered().automaticallyUpdateForSelection)
        XCTAssertTrue(UIButton.Configuration.borderedTinted().automaticallyUpdateForSelection)
    }

    func testGlassFactoryIsCapsuleWithTheSystemRadius() {
        // Measured: the iOS 26 glass family alone starts `.capsule` with
        // background.cornerRadius 5.95.
        let configuration = UIButton.Configuration.glass()
        XCTAssertEqual(configuration.cornerStyle, .capsule)
        XCTAssertEqual(configuration.background.cornerRadius, 5.95)
    }

    // MARK: - Intrinsic size and title frame

    func testEveryFactorySizesConfigureTo99By34333() {
        // Measured `factoryLayout`: every factory gives intrinsic
        // 99 x 34.33333 with the title label at (12, 7, 75, 20.33333).
        let factories: [(String, UIButton.Configuration)] = [
            ("plain", .plain()), ("gray", .gray()), ("tinted", .tinted()),
            ("filled", .filled()), ("borderless", .borderless()), ("bordered", .bordered()),
            ("borderedTinted", .borderedTinted()),
            ("borderedProminent", .borderedProminent()),
        ]
        for (name, factory) in factories {
            var configuration = factory
            configuration.title = "Configure"
            let button = laidOut(configuration)
            XCTAssertEqual(button.intrinsicContentSize.width, 99, accuracy: 0.001,
                           "\(name) width")
            XCTAssertEqual(button.intrinsicContentSize.height, 34.33333, accuracy: 0.001,
                           "\(name) height")
            let title = button.titleLabel?.frame ?? .zero
            XCTAssertEqual(title.origin.x, 12, accuracy: 0.001, "\(name) title x")
            XCTAssertEqual(title.origin.y, 7, accuracy: 0.001, "\(name) title y")
            XCTAssertEqual(title.size.width, 75, accuracy: 0.001, "\(name) title width")
            XCTAssertEqual(title.size.height, 20.33333, accuracy: 0.001, "\(name) title height")
            XCTAssertEqual(button.titleLabel?.font.pointSize, 17, "\(name) title font")
        }
    }

    func testContentInsetsSweepMatchesTheOracle() {
        // Measured `contentInsets`: the box is the title box plus the insets,
        // and the label sits at the inset origin.
        let cases: [(String, OpenUIKit.NSDirectionalEdgeInsets, CGSize, CGPoint)] = [
            ("zero", .zero, CGSize(width: 75, height: 20.33333), CGPoint(x: 0, y: 0)),
            ("kds_plain",
             OpenUIKit.NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
             CGSize(width: 99, height: 44.33333), CGPoint(x: 12, y: 12)),
            ("kds_image",
             OpenUIKit.NSDirectionalEdgeInsets(top: 8.5, leading: 12, bottom: 8.5, trailing: 12),
             CGSize(width: 99, height: 37.33333), CGPoint(x: 12, y: 8.5)),
            ("asym",
             OpenUIKit.NSDirectionalEdgeInsets(top: 3, leading: 20, bottom: 7, trailing: 4),
             CGSize(width: 99, height: 30.33333), CGPoint(x: 20, y: 3)),
        ]
        for (name, insets, expectedSize, expectedOrigin) in cases {
            var configuration = configured()
            configuration.contentInsets = insets
            let button = laidOut(configuration)
            XCTAssertEqual(button.intrinsicContentSize.width, expectedSize.width,
                           accuracy: 0.001, "\(name) width")
            XCTAssertEqual(button.intrinsicContentSize.height, expectedSize.height,
                           accuracy: 0.001, "\(name) height")
            let title = button.titleLabel?.frame ?? .zero
            XCTAssertEqual(title.origin.x, expectedOrigin.x, accuracy: 0.001, "\(name) title x")
            XCTAssertEqual(title.origin.y, expectedOrigin.y, accuracy: 0.001, "\(name) title y")
        }
    }

    func testButtonSizeCarriesItsInsetsAndFont() {
        // Measured `buttonSizes`.
        let cases: [(UIButton.Configuration.Size, OpenUIKit.NSDirectionalEdgeInsets, CGSize, CGFloat)] = [
            (.mini, OpenUIKit.NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10),
             CGSize(width: 87.33333, height: 28), 15),
            (.small, OpenUIKit.NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10),
             CGSize(width: 87.33333, height: 28), 15),
            (.medium, OpenUIKit.NSDirectionalEdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12),
             CGSize(width: 99, height: 34.33333), 17),
            (.large, OpenUIKit.NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20),
             CGSize(width: 115, height: 50.33333), 17),
        ]
        for (size, insets, expected, pointSize) in cases {
            var configuration = UIButton.Configuration.filled()
            configuration.buttonSize = size
            configuration.title = "Configure"
            XCTAssertEqual(configuration.contentInsets, insets, "\(size) insets")
            let button = laidOut(configuration)
            XCTAssertEqual(button.intrinsicContentSize.width, expected.width,
                           accuracy: 0.001, "\(size) width")
            XCTAssertEqual(button.intrinsicContentSize.height, expected.height,
                           accuracy: 0.001, "\(size) height")
            XCTAssertEqual(button.titleLabel?.font.pointSize, pointSize, "\(size) font")
        }
    }

    func testTitleAndSubtitleStackWithTitlePadding() {
        // Measured `titles.titleAndSubtitle`: 99 x 51 =
        // 7 + 20.33333 + 1 + 15.66667 + 7, subtitle 13 pt.
        var configuration = configured()
        configuration.subtitle = "Subtitle"
        let button = laidOut(configuration)
        XCTAssertEqual(button.intrinsicContentSize.width, 99, accuracy: 0.001)
        XCTAssertEqual(button.intrinsicContentSize.height, 51, accuracy: 0.001)
        XCTAssertEqual(button.titleLabel?.frame.origin.y ?? -1, 7, accuracy: 0.001)
    }

    func testCentringUsesAHalfDownPixelRule() {
        // Measured `misc.backgroundStroke`, a 160 x 44 button: the title's
        // centred x is 42.5 pt = 127.5 px at 3x and the oracle reports
        // 42.33333, i.e. pixel 127. Vertically 11.83333 pt = 35.5 px reports
        // as 11.66667. Half-DOWN, where the legacy path rounds half up.
        let button = laidOut(configured(), width: 160, height: 44)
        let title = button.titleLabel?.frame ?? .zero
        XCTAssertEqual(title.origin.x, 42.33333, accuracy: 0.001)
        XCTAssertEqual(title.origin.y, 11.66667, accuracy: 0.001)
    }

    // MARK: - Corner style

    func testCornerStyleResolvesPerTheMeasuredRules() {
        // Measured `cornerStyles`, heights 20 / 28 / 34 / 44 / 60 at width 160.
        let heights: [CGFloat] = [20, 28, 34, 44, 60]
        let expected: [UIButton.Configuration.CornerStyle: [CGFloat]] = [
            // `.fixed` is background.cornerRadius verbatim; assigning any
            // non-dynamic style drops it to the system 5.95.
            .fixed: [5.95, 5.95, 5.95, 5.95, 5.95],
            .small: [2.5, 3.5, 4.25, 5.5, 7.5],
            .medium: [3.5, 4.9, 5.95, 7.7, 10.5],
            .large: [5, 7, 8.5, 11, 15],
            .capsule: [10, 14, 17, 22, 30],
        ]
        for (style, radii) in expected {
            for (height, radius) in zip(heights, radii) {
                var configuration = configured()
                configuration.cornerStyle = style
                let button = laidOut(configuration, width: 160, height: height)
                XCTAssertEqual(button.layer.cornerRadius, radius, accuracy: 0.001,
                               "\(style) at height \(height)")
            }
        }
        // `.dynamic` is min(height / 2, background.cornerRadius) against the
        // factory's 17: 10, 14, 17, 17, 17.
        for (height, radius) in zip(heights, [10, 14, 17, 17, 17] as [CGFloat]) {
            let button = laidOut(configured(), width: 160, height: height)
            XCTAssertEqual(button.layer.cornerRadius, radius, accuracy: 0.001,
                           "dynamic at height \(height)")
        }
    }

    func testProportionalCornerStylesIgnoreAnExplicitRadius() {
        // Measured `cornerStyles.*.explicitRadius6_h44`: with
        // background.cornerRadius set to 6, a 44 pt button still measures
        // 5.5 / 7.7 / 11 under small / medium / large, while `.fixed` takes
        // the 6 and `.dynamic` takes min(22, 6) = 6.
        let cases: [(UIButton.Configuration.CornerStyle, CGFloat)] = [
            (.small, 5.5), (.medium, 7.7), (.large, 11),
            (.capsule, 22), (.fixed, 6), (.dynamic, 6),
        ]
        for (style, radius) in cases {
            var configuration = configured()
            configuration.cornerStyle = style
            configuration.background.cornerRadius = 6
            let button = laidOut(configuration, width: 160, height: 44)
            XCTAssertEqual(button.layer.cornerRadius, radius, accuracy: 0.001, "\(style)")
        }
    }

    func testAssigningANonDynamicCornerStyleResetsTheBackgroundRadius() {
        // Measured: every `cornerStyles` row reads background.cornerRadius
        // back as 5.95 except the `.dynamic` ones, which keep the factory 17.
        var configuration = UIButton.Configuration.filled()
        XCTAssertEqual(configuration.background.cornerRadius, 17)
        configuration.cornerStyle = .dynamic
        XCTAssertEqual(configuration.background.cornerRadius, 17)
        configuration.cornerStyle = .capsule
        XCTAssertEqual(configuration.background.cornerRadius, 5.95)
    }

    // MARK: - Colours per state

    func testFilledColoursPerState() {
        // Measured `statesPerFactory.filled` and `explicitColorsPerState`.
        let normal = laidOut(configured())
        assertColor(normal.backgroundColor, Self.tint, "filled normal fill")
        assertColor(normal.titleLabel?.textColor, Self.white, "filled normal title")

        let highlighted = laidOut(configured()) { $0.isHighlighted = true }
        assertColor(highlighted.backgroundColor, [0, 0.533333, 1, 0.75],
                    "filled highlighted fill")
        assertColor(highlighted.titleLabel?.textColor, [1, 1, 1, 0.75],
                    "filled highlighted title")

        let disabled = laidOut(configured()) { $0.isEnabled = false }
        assertColor(disabled.backgroundColor, Self.gray(0.12), "filled disabled fill")
        assertColor(disabled.titleLabel?.textColor, Self.tertiary, "filled disabled title")

        // `.filled` has automaticallyUpdateForSelection false, so selection
        // changes nothing.
        let selected = laidOut(configured()) { $0.isSelected = true }
        assertColor(selected.backgroundColor, Self.tint, "filled selected fill")
        assertColor(selected.titleLabel?.textColor, Self.white, "filled selected title")
    }

    func testBorderedColoursPerState() {
        // Measured `statesPerFactory.bordered`. The normal title is `.label`
        // — black in light — not tint; the port's own
        // golden/button_configurations_2x draws exactly that.
        func bordered() -> UIButton.Configuration {
            var configuration = UIButton.Configuration.bordered()
            configuration.title = "Configure"
            return configuration
        }
        let normal = laidOut(bordered())
        assertColor(normal.backgroundColor, Self.gray(0.16), "bordered normal fill")
        assertColor(normal.titleLabel?.textColor, Self.black, "bordered normal title")

        // Highlighted is the normal fill at alpha times 0.75: 0.16 -> 0.12.
        let highlighted = laidOut(bordered()) { $0.isHighlighted = true }
        assertColor(highlighted.backgroundColor, Self.gray(0.12), "bordered highlighted fill")
        assertColor(highlighted.titleLabel?.textColor, [0, 0, 0, 0.75],
                    "bordered highlighted title")

        let disabled = laidOut(bordered()) { $0.isEnabled = false }
        assertColor(disabled.backgroundColor, Self.gray(0.12), "bordered disabled fill")
        assertColor(disabled.titleLabel?.textColor, Self.tertiary, "bordered disabled title")

        // Selection moves BOTH the fill and the title to tint.
        let selected = laidOut(bordered()) { $0.isSelected = true }
        assertColor(selected.backgroundColor, [0, 0.533333, 1, 0.18], "bordered selected fill")
        assertColor(selected.titleLabel?.textColor, Self.tint, "bordered selected title")
    }

    func testPlainAndBorderlessHaveNoFillUntilSelected() {
        // Measured `statesPerFactory.plain` / `.borderless`: the fill is clear
        // when normal, highlighted and disabled, and becomes tint at 0.18
        // when selected.
        for factory in [UIButton.Configuration.plain(), .borderless()] {
            var configuration = factory
            configuration.title = "Configure"
            XCTAssertNil(laidOut(configuration).backgroundColor)
            XCTAssertNil(laidOut(configuration) { $0.isEnabled = false }.backgroundColor)
            let selected = laidOut(configuration) { $0.isSelected = true }
            assertColor(selected.backgroundColor, [0, 0.533333, 1, 0.18], "selected fill")
        }
    }

    func testDisabledIgnoresBaseForegroundColor() {
        // Measured `explicitColorsPerState.filled_baseForeground`: normal
        // draws systemGreen, highlighted systemGreen at 0.75, and disabled
        // `tertiaryLabel` — the base colour is dropped entirely. KDS's source
        // comment says the same thing and installs a transformer to work
        // around it.
        var configuration = configured()
        configuration.baseForegroundColor = .systemGreen
        let green = rgba(.systemGreen)!
        assertColor(laidOut(configuration).titleLabel?.textColor, green, "normal")
        assertColor(laidOut(configuration) { $0.isHighlighted = true }.titleLabel?.textColor,
                    [green[0], green[1], green[2], 0.75], "highlighted")
        assertColor(laidOut(configuration) { $0.isEnabled = false }.titleLabel?.textColor,
                    Self.tertiary, "disabled")
    }

    func testBaseBackgroundColorReplacesTheTintInTheDerivedFill() {
        // Measured `explicitColorsPerState.filled_baseBackground`: red at
        // full alpha normal, red at 0.75 highlighted, and the system gray at
        // 0.12 disabled — the disabled substitution ignores it.
        var configuration = configured()
        configuration.baseBackgroundColor = .systemRed
        let red = rgba(.systemRed)!
        assertColor(laidOut(configuration).backgroundColor, red, "normal")
        assertColor(laidOut(configuration) { $0.isHighlighted = true }.backgroundColor,
                    [red[0], red[1], red[2], 0.75], "highlighted")
        assertColor(laidOut(configuration) { $0.isEnabled = false }.backgroundColor,
                    Self.gray(0.12), "disabled")
    }

    func testExplicitBackgroundColorIsDrawnVerbatimInEveryState() {
        // Measured `explicitColorsPerState.filled_explicitBackground`: red in
        // all three states, with no highlight dim and no disabled
        // substitution. This is what KDS's `updateColors(with:)` and
        // AlertBanner's handler depend on — they assign the per-state colour
        // themselves.
        var configuration = configured()
        configuration.background.backgroundColor = .systemRed
        let red = rgba(.systemRed)!
        assertColor(laidOut(configuration).backgroundColor, red, "normal")
        assertColor(laidOut(configuration) { $0.isHighlighted = true }.backgroundColor,
                    red, "highlighted")
        assertColor(laidOut(configuration) { $0.isEnabled = false }.backgroundColor,
                    red, "disabled")
    }

    func testAnExplicitBackgroundGivesEvenAPlainButtonAFill() {
        // Measured `explicitColorsPerState.plain_explicitBackground`.
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Configure"
        configuration.background.backgroundColor = .systemRed
        assertColor(laidOut(configuration).backgroundColor, rgba(.systemRed)!, "plain fill")
        // ... and leaves the foreground at the style's own default.
        assertColor(laidOut(configuration).titleLabel?.textColor, Self.tint, "plain title")
    }

    func testExplicitStrokeDrawsABorderInEveryState() {
        // Measured `explicitColorsPerState.bordered_explicitStroke`: a
        // `_UISystemBackgroundStrokeView` carries borderWidth 2 and the red
        // stroke colour in all three states, and the white fill is untouched.
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "Configure"
        configuration.background.backgroundColor = .white
        configuration.background.strokeColor = .systemRed
        configuration.background.strokeWidth = 2
        // cornerStyle FIRST: assigning a non-dynamic style resets
        // background.cornerRadius to the system 5.95 (measured), which is the
        // order Tools/oracle2/buttonconfigprobe's `misc.backgroundStroke` used.
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = 6
        for tweak in [{ (_: UIButton) in }, { $0.isHighlighted = true }, { $0.isEnabled = false }] {
            let button = laidOut(configuration, width: 160, height: 44, tweak)
            XCTAssertEqual(button.layer.borderWidth, 2)
            assertColor(button.backgroundColor, Self.white, "fill")
            XCTAssertEqual(button.layer.cornerRadius, 6, accuracy: 0.001)
        }
    }

    // MARK: - Transformers

    func testTitleTransformerOverridesFontAndColourInEveryState() {
        // Measured `explicitColorsPerState.filled_baseForeground_transformer`:
        // the transformer's font and colour win when normal, highlighted AND
        // disabled, at FULL alpha each time. This is KDS's exact shape.
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) else { return }
        var configuration = configured()
        configuration.baseForegroundColor = .systemGreen
        configuration.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing[AttributeScopes.OpenUIKitAttributes.FontAttribute.self] =
                    UIFont.systemFont(ofSize: 19, weight: .medium)
                outgoing[AttributeScopes.OpenUIKitAttributes.ForegroundColorAttribute.self] =
                    UIColor.systemGreen
                return outgoing
            }
        let green = rgba(.systemGreen)!
        for (name, tweak) in [("normal", { (_: UIButton) in }),
                              ("highlighted", { $0.isHighlighted = true }),
                              ("disabled", { $0.isEnabled = false })] {
            let button = laidOut(configuration, width: 160, height: 44, tweak)
            assertColor(button.titleLabel?.textColor, green, "\(name) title colour")
            XCTAssertEqual(button.titleLabel?.font.pointSize, 19, "\(name) title font")
        }
    }

    func testTitleTransformerReceivesTheResolvedFontAndBaseColour() {
        // Measured `transformers.callLog`: the incoming container carries
        // exactly the 17 pt body font and the configuration's
        // baseForegroundColor (systemGreen in the probe).
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) else { return }
        final class Box: @unchecked Sendable { var font: UIFont?; var color: UIColor? }
        let box = Box()
        var configuration = configured()
        configuration.baseForegroundColor = .systemGreen
        configuration.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                box.font = incoming[AttributeScopes.OpenUIKitAttributes.FontAttribute.self]
                box.color =
                    incoming[AttributeScopes.OpenUIKitAttributes.ForegroundColorAttribute.self]
                return incoming
            }
        let button = laidOut(configuration)
        XCTAssertEqual(box.font?.pointSize, 17)
        assertColor(box.color, rgba(.systemGreen)!, "incoming colour")
        // A pass-through transformer leaves both alone.
        XCTAssertEqual(button.titleLabel?.font.pointSize, 17)
        assertColor(button.titleLabel?.textColor, rgba(.systemGreen)!, "pass-through")
    }

    func testImageColorTransformerDrivesTheImageTint() {
        // Measured `transformers`: the image view's tint becomes whatever the
        // transformer returns. KDS installs one returning `self.tintColor`.
        var configuration = configured()
        configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in
            .systemOrange
        }
        let button = laidOut(configuration)
        assertColor(button.imageView?.tintColor, rgba(.systemOrange)!, "image tint")
    }

    // MARK: - Update handler

    func testUpdateHandlerFiringMatchesTheOracle() {
        // Measured `updateHandler`. The counts below are that table.
        final class Counter: @unchecked Sendable { var count = 0 }
        let counter = Counter()
        let button = UIButton(configuration: configured())
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
        button.configurationUpdateHandler = { _ in counter.count += 1 }

        func fired(_ body: () -> Void) -> Int {
            let before = counter.count
            body()
            button.layoutIfNeeded()
            return counter.count - before
        }

        XCTAssertEqual(fired {}, 1, "assigning the handler then laying out")
        XCTAssertEqual(fired {}, 0, "a layout with nothing dirty")
        XCTAssertEqual(fired { button.setNeedsUpdateConfiguration() }, 1,
                       "setNeedsUpdateConfiguration")
        XCTAssertEqual(fired {
            button.setNeedsUpdateConfiguration()
            button.setNeedsUpdateConfiguration()
        }, 1, "two setNeedsUpdateConfiguration coalesce")
        XCTAssertEqual(fired { button.isHighlighted = true }, 1, "isHighlighted")
        XCTAssertEqual(fired { button.isEnabled = false }, 1, "isEnabled")
        XCTAssertEqual(fired { button.isSelected = true }, 1, "isSelected")
        XCTAssertEqual(fired { button.tintColor = .systemPink }, 1, "tintColor")
        // Assigning the configuration requests NO update — that is what keeps
        // KDS's handler, which assigns `self.configuration`, from looping.
        XCTAssertEqual(fired {
            var configuration = button.configuration
            configuration?.title = "Changed"
            button.configuration = configuration
        }, 0, "configuration assignment")
        XCTAssertEqual(fired { button.frame = CGRect(x: 0, y: 0, width: 200, height: 44) },
                       0, "frame change")
    }

    func testSetNeedsUpdateConfigurationIsAsynchronous() {
        // Measured `updateHandler.syncCheck/immediate`: 0 calls before the
        // next layout pass.
        final class Counter: @unchecked Sendable { var count = 0 }
        let counter = Counter()
        let button = UIButton(configuration: configured())
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
        button.configurationUpdateHandler = { _ in counter.count += 1 }
        button.layoutIfNeeded()
        let before = counter.count
        button.setNeedsUpdateConfiguration()
        XCTAssertEqual(counter.count, before, "fired before layout")
        button.layoutIfNeeded()
        XCTAssertEqual(counter.count, before + 1, "fired at layout")
    }

    func testHandlerAssigningTheConfigurationDoesNotReenter() {
        // Measured `updateHandlerReentrancy`: the log reads `depth=1` both
        // times, and the assigned colour takes effect. This is KDS's
        // `updateColors(with:)` shape exactly.
        final class Depth: @unchecked Sendable { var current = 0; var max = 0 }
        let depth = Depth()
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "Configure"
        let button = UIButton(configuration: configuration)
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
        button.configurationUpdateHandler = { button in
            depth.current += 1
            depth.max = Swift.max(depth.max, depth.current)
            var updated = button.configuration
            updated?.background.backgroundColor =
                button.state.contains(.highlighted) ? .systemRed : .systemBlue
            button.configuration = updated
            depth.current -= 1
        }
        button.layoutIfNeeded()
        button.isHighlighted = true
        button.layoutIfNeeded()
        XCTAssertEqual(depth.max, 1)
        assertColor(button.backgroundColor, rgba(.systemRed)!, "handler-assigned fill")
    }

    // MARK: - updated(for:)

    func testUpdatedForRewritesOnlyTheBackgroundColour() {
        // Measured `updatedFor`: the ONLY field that changes is
        // background.backgroundColor, and baseForeground/baseBackground come
        // back exactly as assigned.
        var configuration = configured()
        configuration.baseForegroundColor = .systemGreen
        configuration.baseBackgroundColor = .systemBlue
        let button = UIButton(configuration: configuration)
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
        button.layoutIfNeeded()

        let normal = configuration.updated(for: button)
        assertColor(normal.background.backgroundColor, rgba(.systemBlue)!, "normal fill")
        assertColor(normal.baseForegroundColor, rgba(.systemGreen)!, "baseForeground kept")
        assertColor(normal.baseBackgroundColor, rgba(.systemBlue)!, "baseBackground kept")
        XCTAssertEqual(normal.contentInsets, configuration.contentInsets)
        XCTAssertEqual(normal.title, configuration.title)

        button.isEnabled = false
        button.layoutIfNeeded()
        assertColor(configuration.updated(for: button).background.backgroundColor,
                    Self.gray(0.12), "disabled fill")
    }

    // MARK: - Title storage, initialisers, and clearing

    func testTitleAndAttributedTitleShareOneSlot() {
        // Measured `titles.titleAfterAttributed` / `.attributedAfterTitle`:
        // whichever is assigned last wins, and `title` reads the attributed
        // string's characters.
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) else { return }
        var afterAttributed = UIButton.Configuration.plain()
        afterAttributed.attributedTitle = AttributedString("Attributed")
        afterAttributed.title = "Plain"
        XCTAssertEqual(afterAttributed.title, "Plain")
        XCTAssertNil(afterAttributed.attributedTitle)

        var afterTitle = UIButton.Configuration.plain()
        afterTitle.title = "Plain"
        afterTitle.attributedTitle = AttributedString("Attributed")
        XCTAssertEqual(afterTitle.title, "Attributed")
        XCTAssertEqual(afterTitle.attributedTitle.map { String($0.characters) }, "Attributed")
    }

    func testAttributedTitleFontAndColourWin() {
        // Measured `titles.attributedTitle`: a 20 pt bold systemRed
        // attributed title renders in `.SFUI-Bold@20.0` and systemRed, and
        // `configuration.title` reads back "Terms of Use".
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) else { return }
        var configuration = UIButton.Configuration.borderless()
        // Exactly the call PledgeOverTimePaymentScheduleViewController makes.
        configuration.attributedTitle = AttributedString(OpenUIKit.NSAttributedString(
            string: "Terms of Use",
            attributes: [OpenUIKit.NSAttributedString.Key.font:
                            UIFont.systemFont(ofSize: 20, weight: .bold),
                         OpenUIKit.NSAttributedString.Key.foregroundColor:
                            UIColor.systemRed]))
        XCTAssertEqual(configuration.title, "Terms of Use")
        let button = laidOut(configuration)
        XCTAssertEqual(button.titleLabel?.font.pointSize, 20)
        assertColor(button.titleLabel?.textColor, rgba(.systemRed)!, "attributed colour")
    }

    func testInitWithConfigurationAndPrimaryAction() {
        // Measured `misc.primaryAction`: the action's title lands in
        // configuration.title, currentTitle and the label, and the action
        // fires on touchUpInside.
        final class Counter: @unchecked Sendable { var count = 0 }
        let counter = Counter()
        let action = UIAction(title: "Action Title") { _ in counter.count += 1 }
        let button = UIButton(configuration: .plain(), primaryAction: action)
        XCTAssertEqual(button.configuration?.title, "Action Title")
        XCTAssertEqual(button.currentTitle, "Action Title")
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
        button.layoutIfNeeded()
        XCTAssertEqual(button.titleLabel?.text, "Action Title")
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(counter.count, 1)
    }

    func testInitWithConfigurationAppliesItImmediately() {
        // The regression this file was written against: Swift skips a
        // property observer for an assignment made inside an initializer, so
        // `UIButton(configuration:)` used to store a configuration it had
        // never applied — intrinsic 24 x 14, the bare content insets, with an
        // empty label. `button.configuration = c` was correct throughout.
        let button = UIButton(configuration: configured())
        XCTAssertEqual(button.intrinsicContentSize.width, 99, accuracy: 0.001)
        XCTAssertEqual(button.intrinsicContentSize.height, 34.33333, accuracy: 0.001)
        XCTAssertEqual(button.titleLabel?.text, "Configure")
    }

    func testLegacySetTitleUnderAConfiguration() {
        // Measured `misc.legacySetTitleWithConfiguration`: configuration.title
        // stays nil and the legacy title still drives the label, with the
        // configuration's own insets and font.
        let button = UIButton(configuration: .filled())
        button.setTitle("Legacy", for: .normal)
        XCTAssertNil(button.configuration?.title)
        button.frame = CGRect(origin: .zero, size: button.intrinsicContentSize)
        button.layoutIfNeeded()
        XCTAssertEqual(button.titleLabel?.text, "Legacy")
        XCTAssertEqual(button.currentTitle, "Legacy")
        XCTAssertEqual(button.intrinsicContentSize.height, 34.33333, accuracy: 0.001)
    }

    func testClearingAConfigurationReturnsToTheLegacyPath() {
        // Measured `misc.configurationSetToNil`: intrinsic 30 x 30 and a
        // 15 pt font, the port's own legacy floor for an empty button.
        let button = UIButton(configuration: .filled())
        button.configuration?.title = "Configure"
        button.configuration = nil
        XCTAssertEqual(button.intrinsicContentSize.width, 30, accuracy: 0.001)
        XCTAssertEqual(button.intrinsicContentSize.height, 30, accuracy: 0.001)
        XCTAssertEqual(button.titleLabel?.font.pointSize, 15)
        XCTAssertEqual(button.layer.cornerRadius, 0)
    }

    func testAPlainButtonHasNoConfiguration() {
        // Measured `misc`: both are nil.
        XCTAssertNil(UIButton(frame: .zero).configuration)
        XCTAssertNil(UIButton(type: .system).configuration)
    }

    // MARK: - Line break mode and activity indicator

    func testTitleLineBreakModeDrivesTheLabel() {
        // Measured `titles.titleLineBreakMode`: a wrapping mode gives the
        // label numberOfLines 0, a truncating mode 1, and the unbounded
        // intrinsic size is the same for every mode.
        let cases: [(OpenUIKit.NSLineBreakMode, Int)] = [
            (.byWordWrapping, 0), (.byCharWrapping, 0),
            (.byTruncatingTail, 1), (.byTruncatingMiddle, 1),
        ]
        var widths: [CGFloat] = []
        for (mode, lines) in cases {
            var configuration = configured("A rather long button title here")
            configuration.titleLineBreakMode = mode
            let button = UIButton(configuration: configuration)
            XCTAssertEqual(button.titleLabel?.numberOfLines, lines, "\(mode)")
            XCTAssertEqual(button.titleLabel?.lineBreakMode, mode, "\(mode)")
            widths.append(button.intrinsicContentSize.width)
        }
        for width in widths {
            XCTAssertEqual(width, widths[0], accuracy: 0.001,
                           "intrinsic width is mode-independent")
        }
    }

    func testShowsActivityIndicatorWidensTheButtonByTheTitleLineHeight() {
        // Measured `misc.showsActivityIndicator`: 119.33333 x 34.33333 =
        // 12 + 20.33333 + 75 + 12, the spinner a square of the title's line
        // height in the leading slot with the default zero imagePadding.
        var configuration = configured()
        configuration.showsActivityIndicator = true
        let button = laidOut(configuration)
        XCTAssertEqual(button.intrinsicContentSize.width, 119.33333, accuracy: 0.001)
        XCTAssertEqual(button.intrinsicContentSize.height, 34.33333, accuracy: 0.001)
        XCTAssertEqual(button.titleLabel?.frame.origin.x ?? -1, 32.33333, accuracy: 0.001)
    }

    func testImagePaddingAddsToTheBoxOnceForEachPlacement() {
        // Measured `imagePlacement`, title "Go" plus a 22 x 20 image: the
        // padding adds to the box exactly once. The absolute widths differ
        // from the oracle's because UIKit's symbol image VIEW is wider than
        // the image (28 pt for a 22 pt `star.fill`); the deltas do not.
        let image = UIImage(bitmap: Bitmap(width: 22, height: 20))
        for placement in [OpenUIKit.NSDirectionalRectEdge.leading, .trailing, .top, .bottom] {
            var widths: [CGFloat] = []
            var heights: [CGFloat] = []
            for padding in [0, 6, 20] as [CGFloat] {
                var configuration = configured("Go")
                configuration.image = image
                configuration.imagePlacement = placement
                configuration.imagePadding = padding
                let button = laidOut(configuration)
                widths.append(button.intrinsicContentSize.width)
                heights.append(button.intrinsicContentSize.height)
            }
            if placement == .leading || placement == .trailing {
                XCTAssertEqual(widths[1] - widths[0], 6, accuracy: 0.001, "\(placement) +6")
                XCTAssertEqual(widths[2] - widths[0], 20, accuracy: 0.001, "\(placement) +20")
                XCTAssertEqual(heights[0], heights[2], accuracy: 0.001,
                               "\(placement) height unchanged")
            } else {
                XCTAssertEqual(heights[1] - heights[0], 6, accuracy: 0.001, "\(placement) +6")
                XCTAssertEqual(heights[2] - heights[0], 20, accuracy: 0.001, "\(placement) +20")
                XCTAssertEqual(widths[0], widths[2], accuracy: 0.001,
                               "\(placement) width unchanged")
            }
        }
    }

    // MARK: - Kickstarter's own shape, end to end

    func testKDSApplyStyleConfigurationShape() {
        // KDS/Sources/KDS/Buttons/KSRButtonStyleConfiguration.swift, reduced
        // to the members it touches. This is the compile-and-behave check for
        // the 28 uses: `.filled()`, contentInsets, background.cornerRadius,
        // imagePadding, imagePlacement, titleLineBreakMode, titleAlignment,
        // configurationUpdateHandler, titleTextAttributesTransformer,
        // imageColorTransformer, `self.configuration =`,
        // setNeedsUpdateConfiguration(), and background.backgroundColor /
        // strokeColor / strokeWidth / baseForegroundColor per state.
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) else { return }
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Back this project"
        configuration.contentInsets =
            OpenUIKit.NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        configuration.background.cornerRadius = 6
        configuration.imagePadding = 6
        configuration.imagePlacement = .leading
        configuration.titleLineBreakMode = .byWordWrapping
        configuration.titleAlignment = .center
        button.tintColor = .systemGreen
        button.configurationUpdateHandler = { [weak button] _ in
            guard let button else { return }
            var updated = button.configuration
            switch button.state {
            case .disabled:
                updated?.background.backgroundColor = .systemGray
                updated?.baseForegroundColor = .white
            case .highlighted:
                updated?.background.backgroundColor = .systemTeal
                updated?.baseForegroundColor = .white
            default:
                updated?.background.backgroundColor = .systemGreen
                updated?.baseForegroundColor = .white
            }
            updated?.background.strokeColor = .systemBlue
            updated?.background.strokeWidth = 1
            button.configuration = updated
        }
        configuration.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { [weak button] incoming in
                var outgoing = incoming
                outgoing[AttributeScopes.OpenUIKitAttributes.FontAttribute.self] =
                    UIFont.systemFont(ofSize: 15, weight: .bold)
                outgoing[AttributeScopes.OpenUIKitAttributes.ForegroundColorAttribute.self] =
                    button?.configuration?.baseForegroundColor ?? button?.tintColor ?? .white
                return outgoing
            }
        configuration.imageColorTransformer = UIConfigurationColorTransformer { [weak button] _ in
            button?.tintColor ?? .white
        }
        button.configuration = configuration
        button.setNeedsUpdateConfiguration()

        button.frame = CGRect(x: 0, y: 0, width: 300, height: 60)
        button.layoutIfNeeded()
        assertColor(button.backgroundColor, rgba(.systemGreen)!, "normal fill")
        XCTAssertEqual(button.layer.borderWidth, 1)
        XCTAssertEqual(button.layer.cornerRadius, 6, accuracy: 0.001)
        XCTAssertEqual(button.titleLabel?.font.pointSize, 15)
        assertColor(button.titleLabel?.textColor, Self.white, "normal title")

        // The disabled branch: KDS's transformer is exactly what keeps the
        // title white instead of tertiaryLabel.
        button.isEnabled = false
        button.layoutIfNeeded()
        assertColor(button.backgroundColor, rgba(.systemGray)!, "disabled fill")
        assertColor(button.titleLabel?.textColor, Self.white, "disabled title")

        button.isEnabled = true
        button.isHighlighted = true
        button.layoutIfNeeded()
        assertColor(button.backgroundColor, rgba(.systemTeal)!, "highlighted fill")
    }

    func testAlertBannerShape() {
        // Kickstarter-Framework AlertBanner.swift:8 and 56.
        let button = UIButton(configuration: .plain())
        button.configurationUpdateHandler = { button in
            switch button.state {
            case .highlighted, .selected:
                button.configuration?.background.backgroundColor = .systemGray
            default:
                button.configuration?.background.backgroundColor = .clear
            }
        }
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
        button.layoutIfNeeded()
        assertColor(button.backgroundColor, [0, 0, 0, 0], "normal fill is clear")
        button.isHighlighted = true
        button.layoutIfNeeded()
        assertColor(button.backgroundColor, rgba(.systemGray)!, "highlighted fill")
    }

    func testTermsOfUseStyleShape() {
        // Kickstarter-Framework PledgePaymentPlanOptionView.swift:299.
        let button = UIButton(type: .system)
        button.configuration = {
            var configuration = UIButton.Configuration.borderless()
            configuration.contentInsets =
                OpenUIKit.NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            configuration.baseForegroundColor = .systemGreen
            return configuration
        }()
        button.contentHorizontalAlignment = .leading
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        button.layoutIfNeeded()
        XCTAssertNil(button.backgroundColor)
        assertColor(button.titleLabel?.textColor, rgba(.systemGreen)!, "foreground")
    }
}

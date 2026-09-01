import XCTest
import OpenCoreGraphics
import OpenUIKit
@_spi(OpenUIKitPreview) import DeveloperToolsSupport
@testable import SwiftUI

private extension EnvironmentValues {
    @Entry var buttonKitCompatibilityValue: Int = 17
}

private struct EntryReader: View {
    @Environment(\.buttonKitCompatibilityValue) private var value

    var body: some View {
        Text("entry=\(value)")
    }
}

private struct TranslationEffect: GeometryEffect {
    var animatableData: CGFloat

    nonisolated func effectValue(size: CGSize) -> ProjectionTransform {
        _ = size
        return ProjectionTransform(
            OpenCoreGraphics.CGAffineTransform(
                translationX: animatableData,
                y: animatableData / 2
            )
        )
    }
}

private struct FadingModifier: AnimatableModifier {
    var animatableData: Double

    func body(content: Content) -> some View {
        content.opacity(animatableData)
    }
}

private struct ConditionalDisappearFixture: View {
    let isVisible: Bool
    let disappeared: @MainActor () -> Void

    var body: some View {
        if isVisible {
            Text("conditional")
                .onDisappear(perform: disappeared)
        } else {
            Text("removed")
        }
    }
}

final class SwiftUIButtonKitCompatibilityTests: XCTestCase {
    @available(macOS 14.0, *)
    @MainActor
    func testSwiftUIPreviewMetadataRetainsConcreteBodyWithoutHosting() {
        let preview = DeveloperToolsSupport.Preview(body: {
            Text("compile-only-preview")
        })
        XCTAssertTrue(preview._openUIKitBody() is Text)
    }

    func testLocalizedStringKeyInterpolationRendersDevelopmentValue() throws {
        let count = 3
        let key: LocalizedStringKey = "Downloaded \(count) items"
        XCTAssertEqual(key.rawValue, "Downloaded 3 items")

        let root = try hosted(Text(key))
        let label = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.Text"
            } as? UILabel
        )
        XCTAssertEqual(label.text, "Downloaded 3 items")
    }

    @available(macOS 14.0, *)
    func testImageResourcePreservesBundleQualifiedIdentityAndRenders() throws {
        let first = ImageResource(name: "buttonkit-glyph", bundle: .main)
        let second = ImageResource(name: "buttonkit-glyph", bundle: .main)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.name, "buttonkit-glyph")

        let root = try hosted(Image(first))
        XCTAssertNotNil(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.Image.named.buttonkit-glyph"
            }
        )
    }

    func testAnyViewDefersAndRendersConcreteView() throws {
        let erased = AnyView(Text("erased-button-label"))
        let root = try hosted(erased)
        let label = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.Text"
            } as? UILabel
        )
        XCTAssertEqual(label.text, "erased-button-label")
    }

    func testEntryMacroProvidesDefaultAndEnvironmentOverride() throws {
        let defaultRoot = try hosted(EntryReader())
        XCTAssertEqual(text(in: defaultRoot), "entry=17")

        let overriddenRoot = try hosted(
            EntryReader().environment(\.buttonKitCompatibilityValue, 42)
        )
        XCTAssertEqual(text(in: overriddenRoot), "entry=42")
    }

    func testProjectionTransformInvertsAffineTransform() {
        let original = ProjectionTransform(
            OpenCoreGraphics.CGAffineTransform(
                a: 2, b: 0, c: 0, d: 4, tx: 8, ty: 12
            )
        )
        var inverse = original
        XCTAssertTrue(inverse.invert())
        XCTAssertEqual(inverse.m11, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(inverse.m22, 0.25, accuracy: 0.000_001)
        XCTAssertEqual(inverse.m31, -4, accuracy: 0.000_001)
        XCTAssertEqual(inverse.m32, -3, accuracy: 0.000_001)

        var singular = ProjectionTransform()
        singular.m11 = 0
        singular.m22 = 0
        XCTAssertFalse(singular.invert())
    }

    func testGeometryEffectAppliesMeasuredProjectionWithoutChangingLayout() throws {
        let root = try hosted(
            Text("moving")
                .modifier(TranslationEffect(animatableData: 12))
        )
        let host = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.GeometryEffect"
            }
        )
        XCTAssertEqual(host.transform.tx, 12, accuracy: 0.000_001)
        XCTAssertEqual(host.transform.ty, 6, accuracy: 0.000_001)
        XCTAssertNotNil(
            descendants(including: host).first {
                $0.accessibilityIdentifier == "SwiftUI.Text"
            }
        )
    }

    func testAnimatableModifierUsesNormalModifierBodyPipeline() throws {
        let root = try hosted(
            Text("fading").modifier(FadingModifier(animatableData: 0.35))
        )
        let opacity = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.Opacity"
            }
        )
        XCTAssertEqual(opacity.alpha, 0.35, accuracy: 0.000_001)
    }

    func testProminentBorderedButtonAndColorGradientRenderConcreteSurfaces() throws {
        _ = BorderedProminentButtonStyle()
        let gradientStyle: LinearGradient = .linearGradient(
            colors: [.blue, .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let root = try hosted(
            VStack {
                Button("Continue") {}
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)
                gradientStyle
                    .frame(width: 80, height: 24)
            }
        )

        let button = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.Button"
            } as? UIControl
        )
        let border = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.ButtonBorderShape"
            }
        )
        XCTAssertEqual(border.layer.cornerRadius, 8, accuracy: 0.001)
        XCTAssertTrue(border.clipsToBounds)
        let label = try XCTUnwrap(
            descendants(including: button).compactMap { $0 as? UILabel }
                .first { $0.text == "Continue" }
        )
        XCTAssertEqual(label.textColor, .white)
        XCTAssertNotNil(
            descendants(including: button).first {
                $0.accessibilityIdentifier == "SwiftUI.Color"
                    && $0.backgroundColor == .systemBlue
            }
        )

        let gradient = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.LinearGradient"
            } as? UIGradientView
        )
        XCTAssertEqual(gradient.colors.count, 2)
        XCTAssertEqual(gradient.locations ?? [], [0, 1])
        XCTAssertEqual(gradient.startPoint, CGPoint(x: 0, y: 0))
        XCTAssertEqual(gradient.endPoint, CGPoint(x: 1, y: 1))
    }

    func testStringProtocolTextAndSystemLabelPreserveTheirDisplayedValue() throws {
        let storage = "xxLive scoreyy"
        let title = storage.dropFirst(2).dropLast(2)
        let root = try hosted(
            VStack {
                Text(title)
                Label(title, systemImage: "clock")
                    .accessibilityAddTraits(.updatesFrequently)
            }
        )

        let labels = descendants(including: root).compactMap { $0 as? UILabel }
        XCTAssertEqual(labels.filter { $0.text == "Live score" }.count, 2)
        let accessibility = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.AccessibilityTraits"
            }
        )
        XCTAssertTrue(accessibility.accessibilityTraits.contains(.updatesFrequently))
    }

    @MainActor
    func testOnDisappearPairsEachVisibleHostAppearanceExactlyOnce() throws {
        var events: [String] = []
        let controller = UIHostingController(
            rootView: Text("lifecycle")
                .onAppear { events.append("appear") }
                .onDisappear { events.append("disappear") }
        )
        let root = try XCTUnwrap(controller.view)
        root.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        root.layoutIfNeeded()
        XCTAssertEqual(events, [])

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(events, ["appear", "disappear"])

        // A duplicate disappearance without a new visible cycle is inert.
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(events, ["appear", "disappear"])

        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        XCTAssertEqual(events, ["appear", "disappear", "appear", "disappear"])
    }

    @MainActor
    func testOnDisappearFiresWhenVisibleConditionalLeavesRetainedGraph() throws {
        var disappearances = 0
        let action: @MainActor () -> Void = { disappearances += 1 }
        let controller = UIHostingController(
            rootView: ConditionalDisappearFixture(
                isVisible: true,
                disappeared: action
            )
        )
        _ = controller.view
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()

        controller.rootView = ConditionalDisappearFixture(
            isVisible: false,
            disappeared: action
        )
        XCTAssertEqual(disappearances, 1)
        controller.rootView = ConditionalDisappearFixture(
            isVisible: false,
            disappeared: action
        )
        XCTAssertEqual(disappearances, 1)

        controller.rootView = ConditionalDisappearFixture(
            isVisible: true,
            disappeared: action
        )
        controller.view.layoutIfNeeded()
        controller.rootView = ConditionalDisappearFixture(
            isVisible: false,
            disappeared: action
        )
        XCTAssertEqual(disappearances, 2)
    }

    private func hosted<Content: View>(_ content: Content) throws -> UIView {
        let controller = UIHostingController(rootView: content)
        let root = try XCTUnwrap(controller.view)
        root.frame = CGRect(x: 0, y: 0, width: 240, height: 120)
        root.layoutIfNeeded()
        return root
    }

    private func text(in root: UIView) -> String? {
        (descendants(including: root).first {
            $0.accessibilityIdentifier == "SwiftUI.Text"
        } as? UILabel)?.text
    }

    private func descendants(including root: UIView) -> [UIView] {
        [root] + root.subviews.flatMap(descendants(including:))
    }
}

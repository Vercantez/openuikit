import XCTest
import OpenCoreGraphics
import OpenUIKit
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

final class SwiftUIButtonKitCompatibilityTests: XCTestCase {
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

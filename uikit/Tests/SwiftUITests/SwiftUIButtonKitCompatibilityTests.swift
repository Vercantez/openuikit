import XCTest
import OpenCoreGraphics
#if os(Linux)
@preconcurrency import OpenUIKit
#else
import OpenUIKit
#endif
@_spi(OpenUIKitPreview) import DeveloperToolsSupport
#if os(Linux)
@preconcurrency @testable import SwiftUI
#else
@testable import SwiftUI
#endif

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
    #if !os(Linux)
    @MainActor
    #endif
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

    func testDeterminateLinearProgressNormalizesAndRendersNativeBars() throws {
        let root = try hosted(
            VStack {
                ProgressView(value: 2.0, total: 4.0)
                    .progressViewStyle(.linear)
                    .tint(.red)
                    .frame(width: 180, height: 20)
                ProgressView(value: 3.0, total: 2.0)
                    .progressViewStyle(.linear)
                ProgressView(value: 1.0, total: 0.0)
                    .progressViewStyle(.linear)
            }
        )

        let bars = descendants(including: root).compactMap { $0 as? UIProgressView }
        XCTAssertEqual(bars.count, 3)
        XCTAssertEqual(bars[0].progress, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(bars[0].progressTintColor, .red)
        XCTAssertEqual(bars[0].frame.width, 180, accuracy: 0.001)
        XCTAssertEqual(bars[0].frame.height, 4, accuracy: 0.001)
        XCTAssertEqual(bars[0].accessibilityValue, "50%")
        XCTAssertEqual(bars[1].progress, 1, accuracy: 0.000_001)
        XCTAssertEqual(bars[2].progress, 0, accuracy: 0.000_001)
    }

    func testEffectContentCompositingGroupRetainsConcreteRenderBoundary() throws {
        let root = try hosted(
            Text("grouped")
                .onChange(of: 1) { _ in }
                .compositingGroup()
                .opacity(0.5)
        )
        let group = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.CompositingGroup"
            }
        )
        XCTAssertFalse(group.isOpaque)
        XCTAssertNotNil(
            descendants(including: group).first {
                $0.accessibilityIdentifier == "SwiftUI.Text"
            }
        )
        let opacity = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.Opacity"
            }
        )
        XCTAssertEqual(opacity.alpha, 0.5, accuracy: 0.001)
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testTrimmedCircleStrokeRetainsDirectionCapsAndDashPolicy() throws {
        let doubleStart: Double = 0
        let doubleEnd: Double = 0.25
        let solidRoot = try hosted(
            Circle()
                .trim(from: doubleStart, to: doubleEnd)
                .stroke(
                    .red,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round,
                        lineJoin: .bevel,
                        miterLimit: 6
                    )
                )
                .frame(width: 80, height: 80)
        )
        let solidView = try XCTUnwrap(
            descendants(including: solidRoot).first {
                $0.accessibilityIdentifier == "SwiftUI.Circle.trim.stroke"
            }
        )
        XCTAssertEqual(solidView.bounds.size, CGSize(width: 80, height: 80))
        let solid = UIRenderer.render(solidView, scale: 1)

        // Circle fractions start at three o'clock and advance clockwise in
        // UIKit's top-left coordinate space. A quarter therefore paints the
        // right and bottom extrema but not the opposite half.
        XCTAssertGreaterThan(alpha(solid, x: 76, y: 40), 0)
        XCTAssertGreaterThan(alpha(solid, x: 40, y: 76), 0)
        XCTAssertEqual(alpha(solid, x: 3, y: 40), 0)
        XCTAssertEqual(alpha(solid, x: 40, y: 3), 0)

        let dashedRoot = try hosted(
            Circle()
                .trim()
                .stroke(
                    .black,
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .butt,
                        dash: [8, 8],
                        dashPhase: 3
                    )
                )
                .frame(width: 80, height: 80)
        )
        let dashedView = try XCTUnwrap(
            descendants(including: dashedRoot).first {
                $0.accessibilityIdentifier == "SwiftUI.Circle.trim.stroke"
            }
        )
        let dashed = UIRenderer.render(dashedView, scale: 1)
        let solidPixels = stride(from: 3, to: solid.pixels.count, by: 4)
            .filter { solid.pixels[$0] > 0 }.count
        let dashedPixels = stride(from: 3, to: dashed.pixels.count, by: 4)
            .filter { dashed.pixels[$0] > 0 }.count
        XCTAssertGreaterThan(dashedPixels, solidPixels)
        XCTAssertLessThan(dashedPixels, solidPixels * 4)
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testRotationEffectUsesAuthoredAngleAndKeepsAnchorFixed() throws {
        let root = try hosted(
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(.black, style: StrokeStyle(lineWidth: 4))
                .frame(width: 80, height: 60)
                .rotationEffect(.degrees(-90), anchor: .topLeading)
        )
        let host = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.RotationEffect"
            }
        )
        XCTAssertEqual(host.transform.a, 0, accuracy: 0.000_001)
        XCTAssertEqual(host.transform.b, -1, accuracy: 0.000_001)
        XCTAssertEqual(host.transform.c, 1, accuracy: 0.000_001)
        XCTAssertEqual(host.transform.d, 0, accuracy: 0.000_001)

        let localAnchor = CGPoint(
            x: -host.bounds.midX,
            y: -host.bounds.midY
        ).applying(host.transform)
        XCTAssertEqual(
            host.center.x + localAnchor.x,
            root.bounds.minX,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            host.center.y + localAnchor.y,
            root.bounds.minY,
            accuracy: 0.000_001
        )
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testFormatStyleTextAndMonospacedDigitsRenderConcreteValue() throws {
        let value: Double = 0.437
        let text = Text(value, format: .percent.rounded(increment: 1))
            .monospacedDigit()
        let root = try hosted(text)
        let label = try XCTUnwrap(
            descendants(including: root).first {
                $0.accessibilityIdentifier == "SwiftUI.Text"
            } as? UILabel
        )
        XCTAssertEqual(label.text, "44%")
        XCTAssertEqual(label.font.design, UIFont.Design.monospaced)
    }

    #if !os(Linux)
    @MainActor
    #endif
    func testBrightnessAndSaturationFilterCompletedSubtreeOnBothBackends() throws {
        let savedBackend = OpenUIKitRuntime.renderBackend
        let savedCompositor = OpenUIKitRuntime.compositor
        defer {
            OpenUIKitRuntime.renderBackend = savedBackend
            OpenUIKitRuntime.compositor = savedCompositor
        }

        let root = try hosted(
            Color.red
                .frame(width: 40, height: 40)
                .brightness(0.2)
                .saturation(0)
        )
        XCTAssertNotNil(descendants(including: root).first {
            $0.accessibilityIdentifier == "SwiftUI.Brightness"
        })
        XCTAssertNotNil(descendants(including: root).first {
            $0.accessibilityIdentifier == "SwiftUI.Saturation"
        })

        var samples: [[UInt8]] = []
        for backend in [RenderBackend.swift, .quartz] {
            OpenUIKitRuntime.renderBackend = backend
            OpenUIKitRuntime.compositor = .layers
            let bitmap = UIRenderer.render(root, scale: 1)
            let pixel = try XCTUnwrap(
                stride(from: 0, to: bitmap.pixels.count, by: 4)
                    .first { bitmap.pixels[$0 + 3] == 255 }
            )
            let sample = Array(bitmap.pixels[pixel..<(pixel + 4)])
            // Red brightened by 0.2 becomes (1,.2,.2); zero saturation
            // evaluates Rec. 709 luminance and produces a concrete 94 gray.
            XCTAssertEqual(sample, [94, 94, 94, 255])
            samples.append(sample)
        }
        XCTAssertEqual(samples[0], samples[1])
    }

    func testEnvironmentIsConditionallySendable() {
        func requireSendable<T: Sendable>(_: T) {}
        requireSendable(Environment<Bool>(\.isEnabled))
    }

    func testRepeatForeverRetainsBaseTimingAndAutoreversePolicy() {
        let animation = Animation.linear(duration: 1.25)
            .repeatForever(autoreverses: false)
        guard case .repeated(let base, let autoreverses) = animation.storage,
              case .cubic(let x1, let y1, let x2, let y2, let duration) = base
        else {
            return XCTFail("repeatForever must retain its authored base timing")
        }
        XCTAssertFalse(autoreverses)
        XCTAssertEqual(x1, 0)
        XCTAssertEqual(y1, 0)
        XCTAssertEqual(x2, 1)
        XCTAssertEqual(y2, 1)
        XCTAssertEqual(duration, 1.25)
    }

    #if !os(Linux)
    @MainActor
    #endif
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

    #if !os(Linux)
    @MainActor
    #endif
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

    private func alpha(_ bitmap: Bitmap, x: Int, y: Int) -> Int {
        Int(bitmap.pixels[(y * bitmap.width + x) * 4 + 3])
    }
}

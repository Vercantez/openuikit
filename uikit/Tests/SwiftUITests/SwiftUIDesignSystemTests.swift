// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// The API combinations in these fixtures are derived from Mozilla Focus's
// seven BlockzillaPackage/Sources/DesignSystem Swift files at pinned revision
// a2832521c1daa0c23419c73705ae043ed60c9791.  No Focus source is copied here;
// scripts/prove_focus_designsystem_swiftui.sh is the byte-exact source gate.

import XCTest
@testable import SwiftUI
@testable import OpenUIKit

private enum DesignSystemRow: String, CaseIterable {
    case first
    case second
    case third

    var color: UIColor {
        switch self {
        case .first: return .red
        case .second: return .green
        case .third: return .blue
        }
    }
}

private struct DesignSystemRowsFixture: View {
    var body: some View {
        NavigationView {
            Form {
                ForEach(DesignSystemRow.allCases, id: \.self) { row in
                    HStack {
                        Text(row.rawValue)
                        Spacer()
                        Color(row.color)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .navigationTitle("Palette")
        }
    }
}

private struct UIKitImageFixture: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 22, height: 22)
    }
}

private struct UIKitFontFixture: View {
    let font: UIFont

    var body: some View {
        Text("Bridged font")
            .font(Font(font as SwiftUI.CTFont))
    }
}

private struct RoundedOverlayFixture: View {
    var body: some View {
        HStack {
            Color(UIColor.red)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 2)
                )
        }
    }
}

private struct HackersThumbnailSurfaceFixture: View {
    var body: some View {
        Group {
            Image(systemName: "safari")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
        }
        .accessibilityHidden(true)
    }
}

private struct GradientForegroundFixture: View {
    var body: some View {
        Text("gradient style")
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [.red, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

private struct HackersSecureFieldFixture: View {
    @State private var text = "private value"
    @FocusState private var isFocused: Bool

    init(startFocused: Bool) {
        _isFocused = FocusState(wrappedValue: startFocused)
    }

    var body: some View {
        SecureField("Password", text: $text)
            .focused($isFocused)
            .lineLimit(1)
    }
}

private struct PressOpacityStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.35 : 1)
    }
}

private struct HackersControlsFixture: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(.red)
                .scaleEffect(0.6)
            Capsule()
                .fill(.blue)
                .frame(width: 80, height: 24)
            Button("Vote", action: action)
                .buttonStyle(PressOpacityStyle())
        }
        .glassEffect()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Voting controls")
        .accessibilityHint("Double tap to vote")
        .accessibilityValue("Ready")
        .accessibilityAddTraits(.isButton)
    }
}

private struct HackersContextMenuFixture: View {
    let vote: () -> Void
    let share: () -> Void

    var body: some View {
        Text("Post")
            .contextMenu {
                Button(action: vote) {
                    Label("Upvote", systemImage: "arrow.up")
                }
                Divider()
                Button(role: .destructive, action: share) {
                    Label("Remove", systemImage: "trash")
                }
            }
    }
}

private struct GradientStopsFixture: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .red, location: 0),
                .init(color: .green, location: 0.25),
                .init(color: .blue, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private enum AuthenticationField: Hashable {
    case username
    case password
}

private struct AuthenticationSurfaceFixture: View {
    @State private var username = "alice"
    @State private var password = "secret"
    @FocusState private var focusedField: AuthenticationField?
    let didSubmit: () -> Void

    init(didSubmit: @escaping () -> Void) {
        self.didSubmit = didSubmit
        _focusedField = FocusState(wrappedValue: .username)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Text("\(Int(geometry.size.width))x\(Int(geometry.size.height))")
                        TextField("Username", text: $username)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .username)
                            .accessibilityIdentifier("login.username")
                            .onSubmit(didSubmit)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {} label: {
                        Label("Close", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }
}

private struct AuthenticationAlertFixture: View {
    @State private var showAlert = true
    let acknowledged: () -> Void

    var body: some View {
        Text("Login")
            .alert("Login Failed", isPresented: $showAlert) {
                Button("OK", role: .cancel, action: acknowledged)
            } message: {
                Text("Please check your credentials.")
            }
    }
}

private struct CommentsComposerFixture: View {
    let text: Binding<String>
    let didSubmit: @MainActor () -> Void

    var body: some View {
        TextField("Write a comment", text: text, axis: .vertical)
            .lineLimit(2...6)
            .textContentType(.name)
            .autocapitalization(.sentences)
            .disableAutocorrection(true)
            .submitLabel(.send)
            .onSubmit(didSubmit)
    }
}

private struct CommentsScrollFixture: View {
    let captureProxy: @MainActor (ScrollViewProxy) -> Void
    let geometryChanged: @MainActor (CGFloat, CGFloat) -> Void
    let visibilityChanged: @MainActor ([Int]) -> Void
    let refresh: @MainActor @Sendable () async -> Void

    var body: some View {
        ScrollViewReader { proxy in makeContent(proxy) }
    }

    @MainActor
    private func makeContent(_ proxy: ScrollViewProxy) -> some View {
        captureProxy(proxy)
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { index in
                    Text("Comment \(index)")
                        .frame(height: 40)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(
            for: CGFloat.self,
            of: { $0.contentOffset.y },
            action: geometryChanged
        )
        .onScrollTargetVisibilityChange(
            idType: Int.self,
            threshold: 0.5,
            visibilityChanged
        )
        .refreshable(action: refresh)
    }
}

private enum CommentsHeightPreference: PreferenceKey {
    static let defaultValue = 0

    static func reduce(value: inout Int, nextValue: () -> Int) {
        value += nextValue()
    }
}

private struct CommentsPreferenceFixture: View {
    let changed: @MainActor (Int) -> Void

    var body: some View {
        VStack {
            Text("One").preference(key: CommentsHeightPreference.self, value: 2)
            Text("Two").preference(key: CommentsHeightPreference.self, value: 3)
        }
        .onPreferenceChange(CommentsHeightPreference.self, perform: changed)
    }
}

private struct CommentsDragFixture: View {
    let changed: @MainActor (DragGesture.Value) -> Void
    let ended: @MainActor (DragGesture.Value) -> Void

    var body: some View {
        Color.clear
            .frame(width: 100, height: 80)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged(changed)
                    .onEnded(ended)
            )
    }
}

private struct WhatsNewFixtureItem: Identifiable {
    let id: Int
    let title: String
}

private struct WhatsNewSurfaceFixture: View {
    let dismiss: @MainActor () -> Void
    let items = [
        WhatsNewFixtureItem(
            id: 7,
            title: "A deliberately long release note that must wrap onto multiple lines."
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(items) { item in
                        Text(item.title)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 90, height: 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", action: dismiss)
                }
            }
        }
    }
}

private struct FeedSurfaceFixture: View {
    let searchText: Binding<String>
    let selected: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                Menu {
                    Button("Popular", action: selected)
                    Button("Recent") {}
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .menuIndicator(.hidden)

                HStack {
                    ProgressView("Searching...")
                        .tint(nil)
                    Circle()
                        .fill(.white.opacity(0.22))
                        .frame(width: 18, height: 18)
                }

                List {
                    Text("Pinned")
                        .listRowBackground(Color.red)
                        .listRowSeparator(.hidden)
                    Text("Story")
                }
                .listStyle(.sidebar)
            }
            .font(.headline.weight(.semibold))
            .background(.bar)
            .toolbar {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            }
        }
        .searchable(text: searchText, placement: .toolbar, prompt: "Search Hacker News")
        .searchToolbarBehavior(.minimize)
    }
}

@MainActor
final class SwiftUIDesignSystemTests: XCTestCase {
    private var savedResourceRoot = ""
    private var savedBackend: RenderBackend = .swift
    private var savedCompositor: RenderCompositor = .renderPass

    override func setUp() {
        super.setUp()
        savedResourceRoot = OpenUIKitRuntime.resourceRoot
        savedBackend = OpenUIKitRuntime.renderBackend
        savedCompositor = OpenUIKitRuntime.compositor

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        OpenUIKitRuntime.resourceRoot = root
            .appendingPathComponent("Sources/OpenUIKit/Resources").path
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
    }

    override func tearDown() {
        OpenUIKitRuntime.resourceRoot = savedResourceRoot
        OpenUIKitRuntime.renderBackend = savedBackend
        OpenUIKitRuntime.compositor = savedCompositor
        super.tearDown()
    }

    func testFormExpandsForEachInStableRowOrderUnderNavigationTitle() throws {
        let controller = UIHostingController(rootView: DesignSystemRowsFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 184)
        host.layoutIfNeeded()

        let navigation = try XCTUnwrap(descendant(host, identifier: "SwiftUI.NavigationView"))
        let title = try XCTUnwrap(
            descendant(navigation, identifier: "SwiftUI.NavigationTitle") as? UILabel
        )
        let form = try XCTUnwrap(descendant(navigation, identifier: "SwiftUI.Form"))
        let rows = descendants(form).filter {
            $0.accessibilityIdentifier?.hasPrefix("SwiftUI.Form.row.") == true
        }
        let labels = descendants(form).compactMap { $0 as? UILabel }.filter {
            $0.accessibilityIdentifier == "SwiftUI.Text"
        }

        XCTAssertEqual(title.text, "Palette")
        XCTAssertEqual(title.frame.height, 52, accuracy: 0.001)
        XCTAssertEqual(form.frame, CGRect(x: 0, y: 52, width: 240, height: 132))
        XCTAssertEqual(rows.map(\.frame.origin.y), [0, 44, 88])
        XCTAssertEqual(rows.map(\.frame.height), [44, 44, 44])
        XCTAssertEqual(labels.map(\.text), ["first", "second", "third"])

        let first = UIRenderer.render(host, scale: 1)
        let second = UIRenderer.render(host, scale: 1)
        XCTAssertEqual(first.pixels, second.pixels)
        XCTAssertEqual(alpha(first, x: 0, y: 0), 255)
    }

    func testUIKitImageInitializerPreservesPixelsAndResizableFrame() throws {
        let bitmap = Bitmap(width: 2, height: 2)
        bitmap.pixels = [
            255, 0, 0, 255, 0, 255, 0, 255,
            0, 0, 255, 255, 255, 255, 255, 255,
        ]
        let image = UIImage(bitmap: bitmap)
        let controller = UIHostingController(rootView: UIKitImageFixture(image: image))
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        host.layoutIfNeeded()

        let imageView = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Image.uiImage") as? UIImageView
        )
        XCTAssertTrue(imageView.image === image)
        XCTAssertEqual(imageView.frame, CGRect(x: 11, y: 11, width: 22, height: 22))

        let first = UIRenderer.render(host, scale: 1)
        let second = UIRenderer.render(host, scale: 1)
        XCTAssertEqual(first.pixels, second.pixels)
        XCTAssertGreaterThan(alpha(first, x: 21, y: 21), 0)
    }

    func testCTFontBridgePreservesUIKitPointSizeWeightAndDesign() throws {
        let font = UIFont.systemFont(ofSize: 14, weight: .light)
        let controller = UIHostingController(rootView: UIKitFontFixture(font: font))
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 180, height: 44)
        host.layoutIfNeeded()

        let label = try XCTUnwrap(descendant(host, identifier: "SwiftUI.Text") as? UILabel)
        XCTAssertEqual(label.font.pointSize, 14, accuracy: 0.001)
        XCTAssertEqual(label.font.weight, .light)
        XCTAssertEqual(label.font.design, .default)

        let rendered = UIRenderer.render(host, scale: 1)
        let visiblePixels = stride(from: 3, to: rendered.pixels.count, by: 4)
            .filter { rendered.pixels[$0] > 0 }
            .count
        XCTAssertGreaterThan(visiblePixels, 20)
    }

    func testRoundedClipAndStrokeOverlayRenderDeterministically() throws {
        let controller = UIHostingController(rootView: RoundedOverlayFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        host.layoutIfNeeded()

        let clip = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ClipRoundedRectangle")
        )
        let stroke = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.RoundedRectangle.stroke")
        )
        XCTAssertEqual(clip.frame.size, CGSize(width: 44, height: 44))
        XCTAssertEqual(clip.layer.cornerRadius, 12, accuracy: 0.001)
        XCTAssertEqual(stroke.frame.size, CGSize(width: 44, height: 44))
        XCTAssertEqual(stroke.layer.cornerRadius, 12, accuracy: 0.001)
        XCTAssertEqual(stroke.layer.borderWidth, 2, accuracy: 0.001)

        let first = UIRenderer.render(host, scale: 1)
        let second = UIRenderer.render(host, scale: 1)
        XCTAssertEqual(first.pixels, second.pixels)
        XCTAssertEqual(rgba(first, x: 22, y: 30), [255, 0, 0, 255])
        XCTAssertEqual(alpha(first, x: 59, y: 59), 0)
        XCTAssertGreaterThan(alpha(first, x: 1, y: 30), 0)
    }

    func testGroupHierarchicalForegroundAndAccessibilityComposeLikeHackersThumbnail() throws {
        let controller = UIHostingController(rootView: HackersThumbnailSurfaceFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        host.layoutIfNeeded()

        let accessibilityHost = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.AccessibilityHidden")
        )
        let symbol = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Image.systemName.safari")
        )
        XCTAssertTrue(accessibilityHost.accessibilityElementsHidden)
        XCTAssertEqual(symbol.frame.size, CGSize(width: 28, height: 28))
        XCTAssertEqual(
            Font.title2.resolve(weight: nil).pointSize,
            22,
            accuracy: 0.001
        )
    }

    func testStandardTextStylesExposeUIKitMetricsUsedByUntouchedHackers() {
        let styles: [Font] = [
            .largeTitle, .title, .title2, .title3, .headline, .body,
            .callout, .subheadline, .footnote, .caption, .caption2,
        ]
        XCTAssertEqual(
            styles.map { $0.resolve(weight: nil).pointSize },
            [34, 28, 22, 20, 17, 17, 16, 15, 13, 12, 11]
        )
    }

    func testGradientForegroundResolvesDeterministicallyToLeadingStyleColor() throws {
        let controller = UIHostingController(rootView: GradientForegroundFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
        host.layoutIfNeeded()
        let label = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Text") as? UILabel
        )
        XCTAssertEqual(label.textColor, .red)
    }

    func testDecorativeBitmapImageAppliesCGImageOrientationAndScale() throws {
        let bitmap = Bitmap(width: 2, height: 1)
        bitmap.pixels = [
            255, 0, 0, 255,
            0, 0, 255, 255,
        ]
        let image = Image(decorative: bitmap, scale: 2, orientation: .right)
        guard case .uiImage(let oriented) = image.source else {
            return XCTFail("decorative CGImage must produce a UIImage-backed source")
        }
        XCTAssertEqual(oriented.scale, 2)
        XCTAssertEqual(oriented.bitmap.width, 1)
        XCTAssertEqual(oriented.bitmap.height, 2)
        XCTAssertEqual(
            oriented.bitmap.pixels,
            [255, 0, 0, 255, 0, 0, 255, 255]
        )
    }

    func testSecureFieldMountsMaskedAndTakesInitialGraphFocus() throws {
        let controller = UIHostingController(
            rootView: HackersSecureFieldFixture(startFocused: true)
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 60))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let field = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.SecureField") as? UITextField
        )
        XCTAssertTrue(field.isSecureTextEntry)
        XCTAssertEqual(field.text, "private value")
        XCTAssertTrue(field.isFirstResponder)
        XCTAssertEqual(field.textLabel.text, String(repeating: "\u{2022}", count: 13))

        XCTAssertTrue(field.resignFirstResponder())
        XCTAssertFalse(field.isFirstResponder)
    }

    func testHackersControlsRenderRealProgressCapsuleGlassAccessibilityAndPressedStyle() throws {
        var actionCount = 0
        let controller = UIHostingController(
            rootView: HackersControlsFixture { actionCount += 1 }
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 180, height: 140)
        host.layoutIfNeeded()

        let effect = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.GlassEffect") as? UIVisualEffectView
        )
        XCTAssertTrue(effect.effect is UIBlurEffect)
        let progress = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ProgressView") as? UIActivityIndicatorView
        )
        XCTAssertTrue(progress.isAnimating)
        XCTAssertEqual(progress.color, .red)
        let capsule = try XCTUnwrap(descendant(host, identifier: "SwiftUI.Capsule.fill"))
        XCTAssertEqual(capsule.layer.cornerRadius, 12, accuracy: 0.001)
        XCTAssertEqual(capsule.backgroundColor, .blue)

        let button = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Button") as? UIControl
        )
        let opacityHosts = descendants(button).filter {
            $0.accessibilityIdentifier == "SwiftUI.Opacity"
        }
        XCTAssertEqual(opacityHosts.map(\.alpha).sorted(), [0.35, 1])
        button.sendActions(for: .touchUpInside)
        XCTAssertEqual(actionCount, 1)

        let accessibility = try XCTUnwrap(
            descendants(host).first { $0.accessibilityLabel == "Voting controls" }
        )
        XCTAssertEqual(accessibility.accessibilityHint, "Double tap to vote")
        XCTAssertEqual(accessibility.accessibilityValue, "Ready")
        XCTAssertTrue(accessibility.accessibilityTraits.contains(.button))
    }

    func testContextMenuBuildsLabelActionsSectionsAndDispatches() throws {
        var votes = 0
        var removals = 0
        let controller = UIHostingController(
            rootView: HackersContextMenuFixture(
                vote: { votes += 1 },
                share: { removals += 1 }
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
        host.layoutIfNeeded()

        let contextHost = try XCTUnwrap(descendant(host, identifier: "SwiftUI.ContextMenu"))
        let interaction = try XCTUnwrap(contextHost.interactions.first as? UIContextMenuInteraction)
        let configuration = try XCTUnwrap(
            interaction.delegate?.contextMenuInteraction(
                interaction,
                configurationForMenuAtLocation: .zero
            )
        )
        let menu = try XCTUnwrap(configuration.resolvedMenu())
        XCTAssertEqual(menu.children.count, 2)
        let upvote = try XCTUnwrap(menu.children.first as? UIAction)
        XCTAssertEqual(upvote.title, "Upvote")
        upvote.performWithSender(contextHost, target: nil)
        XCTAssertEqual(votes, 1)

        let section = try XCTUnwrap(menu.children.last as? UIMenu)
        let remove = try XCTUnwrap(section.children.first as? UIAction)
        XCTAssertTrue(remove.attributes.contains(.destructive))
        remove.performWithSender(contextHost, target: nil)
        XCTAssertEqual(removals, 1)
    }

    func testGradientStopsCarryExactLocationsIntoOpenUIKitLayer() throws {
        let controller = UIHostingController(rootView: GradientStopsFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 40, height: 100)
        host.layoutIfNeeded()
        let gradient = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.LinearGradient") as? UIGradientView
        )
        XCTAssertEqual(gradient.locations ?? [], [0, 0.25, 1])
        XCTAssertEqual(gradient.startPoint, CGPoint(x: 0.5, y: 0))
        XCTAssertEqual(gradient.endPoint, CGPoint(x: 0.5, y: 1))
    }

    func testAuthenticationInputTraitsGeometryToolbarFocusAndSubmitAreLive() throws {
        var submitCount = 0
        let controller = UIHostingController(
            rootView: AuthenticationSurfaceFixture { submitCount += 1 }
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 360))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let scroll = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.ScrollView") as? UIScrollView
        )
        XCTAssertEqual(scroll.keyboardDismissMode, .interactive)
        let geometryLabel = try XCTUnwrap(
            descendants(controller.view).compactMap { $0 as? UILabel }
                .first { $0.text == "240x296" }
        )
        XCTAssertEqual(
            geometryLabel.text,
            "240x296",
            "the concrete UINavigationController reserves its measured 64pt bar"
        )

        let identifierHost = try XCTUnwrap(
            descendant(controller.view, identifier: "login.username")
        )
        let username = try XCTUnwrap(
            descendants(identifierHost).first { $0 is UITextField } as? UITextField
        )
        XCTAssertEqual(username.textContentType, .username)
        XCTAssertEqual(username.autocapitalizationType, .none)
        XCTAssertEqual(username.autocorrectionType, .no)
        XCTAssertTrue(username.isFirstResponder)
        username.sendActions(for: .primaryActionTriggered)
        XCTAssertEqual(submitCount, 1)

        let password = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.SecureField") as? UITextField
        )
        XCTAssertEqual(password.textContentType, .password)
        XCTAssertTrue(password.isSecureTextEntry)

        let progress = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.ProgressView")
                as? UIActivityIndicatorView
        )
        XCTAssertEqual(progress.frame.size, CGSize(width: 16, height: 16))

        let navigation = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.NavigationStack")
        )
        let closeButton = try XCTUnwrap(
            descendants(navigation).first { $0.accessibilityLabel == "Close" }
        )
        XCTAssertNotNil(
            descendants(closeButton).first {
                $0.accessibilityIdentifier == "SwiftUI.Image.systemName.xmark"
            }
        )
        XCTAssertFalse(
            descendants(closeButton).compactMap { ($0 as? UILabel)?.text }.contains("Close")
        )
    }

    func testAuthenticationAlertPresentsNativeControllerAndDispatchesCancel() throws {
        var acknowledgements = 0
        let controller = UIHostingController(
            rootView: AuthenticationAlertFixture { acknowledgements += 1 }
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 360))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let alert = try XCTUnwrap(controller.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.title, "Login Failed")
        XCTAssertEqual(alert.message, "Please check your credentials.")
        XCTAssertEqual(alert.actions.count, 1)
        XCTAssertEqual(alert.actions[0].title, "OK")
        XCTAssertEqual(alert.actions[0].style, .cancel)
        alert.actions[0]._fire()
        XCTAssertEqual(acknowledgements, 1)
    }

    func testCommentsMultilineComposerUsesUITextViewTraitsBindingAndSubmit() throws {
        var value = "Draft"
        var submitCount = 0
        let binding = Binding<String>(
            get: { value },
            set: { value = $0 }
        )
        let controller = UIHostingController(
            rootView: CommentsComposerFixture(
                text: binding,
                didSubmit: { submitCount += 1 }
            )
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 72))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let editor = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.TextField.Multiline")
                as? UITextView
        )
        XCTAssertEqual(editor.text, "Draft")
        XCTAssertEqual(editor.accessibilityLabel, "Write a comment")
        XCTAssertEqual(editor.textContentType, .name)
        XCTAssertEqual(editor.autocapitalizationType, .sentences)
        XCTAssertEqual(editor.autocorrectionType, .no)
        XCTAssertEqual(editor.returnKeyType, .send)
        XCTAssertEqual(editor.backgroundColor, .clear)
        XCTAssertTrue(editor.becomeFirstResponder())

        editor.insertText("!")
        XCTAssertEqual(value, "Draft!")
        editor.insertText("\n")
        XCTAssertEqual(value, "Draft!", "a configured submit consumes the newline")
        XCTAssertEqual(submitCount, 1)
    }

    func testCommentsScrollReaderTargetsVisibilityGeometryAndRefreshSurface() throws {
        var proxy: ScrollViewProxy?
        var geometryChanges: [(CGFloat, CGFloat)] = []
        var visibility: [Int] = []
        let controller = UIHostingController(
            rootView: CommentsScrollFixture(
                captureProxy: { proxy = $0 },
                geometryChanged: { geometryChanges.append(($0, $1)) },
                visibilityChanged: { visibility = $0 },
                refresh: {}
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 120)
        host.layoutIfNeeded()

        let scroll = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ScrollView") as? UIScrollView
        )
        XCTAssertEqual(scroll.contentSize.height, 400, accuracy: 0.001)
        XCTAssertFalse(scroll.showsVerticalScrollIndicator)
        XCTAssertFalse(scroll.showsHorizontalScrollIndicator)
        XCTAssertNotNil(scroll.refreshControl)
        XCTAssertEqual(visibility, [0, 1, 2])
        var geometry = try XCTUnwrap(geometryChanges.last)
        XCTAssertEqual(geometry.0, 0, accuracy: 0.001)
        XCTAssertEqual(geometry.1, 0, accuracy: 0.001)

        try XCTUnwrap(proxy).scrollTo(9, anchor: .bottom)
        XCTAssertEqual(scroll.contentOffset.y, 280, accuracy: 0.001)
        XCTAssertEqual(visibility, [7, 8, 9])
        geometry = try XCTUnwrap(geometryChanges.last)
        XCTAssertEqual(geometry.0, 0, accuracy: 0.001)
        XCTAssertEqual(geometry.1, 280, accuracy: 0.001)
    }

    func testCommentsPreferencesReduceAcrossSiblings() throws {
        var values: [Int] = []
        let controller = UIHostingController(
            rootView: CommentsPreferenceFixture { values.append($0) }
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 120, height: 80)
        host.layoutIfNeeded()
        XCTAssertEqual(values.last, 5)
    }

    func testCommentsDragGestureReceivesRealWindowTouches() throws {
        var changedValues: [DragGesture.Value] = []
        var endedValues: [DragGesture.Value] = []
        let controller = UIHostingController(
            rootView: CommentsDragFixture(
                changed: { changedValues.append($0) },
                ended: { endedValues.append($0) }
            )
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 120, height: 100))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let host = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.Gesture")
        )
        XCTAssertTrue(host.gestureRecognizers?.first is UIPanGestureRecognizer)
        window.sendTouch(.began, at: CGPoint(x: 30, y: 30), timestamp: 0)
        window.sendTouch(.moved, at: CGPoint(x: 60, y: 45), timestamp: 0.05)
        window.sendTouch(.ended, at: CGPoint(x: 70, y: 50), timestamp: 0.1)

        XCTAssertFalse(changedValues.isEmpty)
        let ended = try XCTUnwrap(endedValues.last)
        XCTAssertEqual(ended.startLocation.x, 30, accuracy: 0.001)
        XCTAssertEqual(ended.startLocation.y, 30, accuracy: 0.001)
        XCTAssertEqual(ended.translation.width, 40, accuracy: 0.001)
        XCTAssertEqual(ended.translation.height, 20, accuracy: 0.001)
    }

    func testWhatsNewIdentifiableRowsFixedHeightAndTopToolbarAreSemantic() throws {
        var dismissCount = 0
        let controller = UIHostingController(
            rootView: WhatsNewSurfaceFixture { dismissCount += 1 }
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 220, height: 180)
        host.layoutIfNeeded()

        let note = try XCTUnwrap(
            descendants(host).compactMap { $0 as? UILabel }
                .first { $0.text?.hasPrefix("A deliberately long") == true }
        )
        XCTAssertGreaterThan(note.frame.height, 20)
        let close = try XCTUnwrap(
            descendants(host).first {
                $0.accessibilityIdentifier == "SwiftUI.Button"
                    && descendants($0).compactMap { ($0 as? UILabel)?.text }.contains("Close")
            } as? UIControl
        )
        close.sendActions(for: .touchUpInside)
        XCTAssertEqual(dismissCount, 1)
    }

    func testFeedSearchMenuListStyleShapeFontProgressAndMaterialAreLive() throws {
        var query = "initial"
        var selectionCount = 0
        let controller = UIHostingController(
            rootView: FeedSurfaceFixture(
                searchText: Binding(
                    get: { query },
                    set: { query = $0 }
                ),
                selected: { selectionCount += 1 }
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 280, height: 360)
        host.layoutIfNeeded()

        let search = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Searchable") as? UISearchBar
        )
        XCTAssertEqual(search.text, "initial")
        XCTAssertEqual(search.placeholder, "Search Hacker News")
        search.searchTextField.text = "linux"
        search.searchTextField.sendActions(for: .editingChanged)
        XCTAssertEqual(query, "linux")

        let menu = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Menu") as? UIButton
        )
        XCTAssertTrue(menu.showsMenuAsPrimaryAction)
        XCTAssertNil(descendant(menu, identifier: "SwiftUI.Menu.indicator"))
        let firstAction = try XCTUnwrap(menu.menu?.children.first as? UIAction)
        XCTAssertEqual(firstAction.title, "Popular")
        firstAction.performWithSender(menu, target: nil)
        XCTAssertEqual(selectionCount, 1)

        let progress = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ProgressView")
                as? UIActivityIndicatorView
        )
        XCTAssertTrue(progress.isAnimating)
        XCTAssertNotNil(
            descendants(host).compactMap { $0 as? UILabel }
                .first { $0.text == "Searching..." }
        )
        XCTAssertEqual(
            Font.headline.weight(.semibold).resolve(weight: nil).weight,
            .semibold
        )

        let list = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.List") as? UIScrollView
        )
        XCTAssertEqual(list.accessibilityValue, "style=sidebar")
        XCTAssertTrue(
            descendants(list).filter {
                $0.accessibilityIdentifier?.hasPrefix("SwiftUI.List.separator") == true
            }.isEmpty,
            "the first row's all-edge hidden preference removes its bottom boundary"
        )
        let rowBackground = try XCTUnwrap(
            descendant(list, identifier: "SwiftUI.ListRowBackground")
        )
        XCTAssertNotNil(descendants(rowBackground).first { $0.backgroundColor == .red })

        let circle = try XCTUnwrap(
            descendants(host).first {
                $0.accessibilityIdentifier == "SwiftUI.Capsule.fill"
                    && $0.frame.size == CGSize(width: 18, height: 18)
            }
        )
        XCTAssertEqual(circle.layer.cornerRadius, 9, accuracy: 0.001)
        XCTAssertNotNil(descendant(host, identifier: "SwiftUI.Material.bar") as? UIVisualEffectView)
    }

    private func descendant(_ root: UIView, identifier: String) -> UIView? {
        descendants(root).first { $0.accessibilityIdentifier == identifier }
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }

    private func alpha(_ bitmap: Bitmap, x: Int, y: Int) -> Int {
        Int(bitmap.pixels[(y * bitmap.width + x) * 4 + 3])
    }

    private func rgba(_ bitmap: Bitmap, x: Int, y: Int) -> [Int] {
        let offset = (y * bitmap.width + x) * 4
        return (0..<4).map { Int(bitmap.pixels[offset + $0]) }
    }
}

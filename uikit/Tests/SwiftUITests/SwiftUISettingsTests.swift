// Runtime coverage for the settings-form surface used by Mozilla Focus's
// exact Blockzilla/InternalSettings sources at a2832521c1daa0c23419c73705ae043ed60c9791.

import XCTest
import Combine
#if os(Linux)
@preconcurrency @testable import OpenUIKit
#else
@testable import OpenUIKit
#endif
#if os(Linux)
@preconcurrency @testable import SwiftUI
#else
@testable import SwiftUI
#endif

private enum SettingsPublisherFailure: Error {
    case stopped
}

private final class SettingsModel: Combine.ObservableObject {
    @Combine.Published var enabled = false
    @Combine.Published var tag = ""
    @Combine.Published var explicitSelection = 10
    var changedTags: [String] = []
    var receivedBranches: [String] = []
    let events = PassthroughSubject<String, SettingsPublisherFailure>()
}

private struct SettingsDestination: View {
    var body: some View { Text(verbatim: "Destination") }
}

private struct SettingsFixture: View {
    @ObservedObject var model: SettingsModel
    @State private var branch = "none"

    var body: some View {
        Form {
            SwiftUI.Section(
                header: Text(verbatim: "Settings"),
                footer: Text(verbatim: "Changes apply immediately")
            ) {
                Toggle(isOn: $model.enabled) {
                    VStack(alignment: .leading) {
                        Text(verbatim: "Enabled")
                        Text(verbatim: "Requires app restart").font(.caption)
                    }
                }
                .disabled(model.tag.isEmpty)

                TextField("Debug View Tag", text: $model.tag)
                    .onChange(of: model.tag) { model.changedTags.append($0) }

                Picker(selection: $branch, label: Text(verbatim: "Active Branch")) {
                    ForEach(["none", "beta"], id: \.self) { branch in
                        if branch == "none" {
                            Text(verbatim: "Not Enrolled")
                        } else {
                            Text(verbatim: branch)
                        }
                    }
                }
                .onReceive(Just(branch)) { model.receivedBranches.append($0) }

                NavigationLink(destination: SettingsDestination()) {
                    Text(verbatim: "Details")
                }
            }
        }
        .navigationBarTitle(Text(verbatim: "Internal Settings"))
    }
}

private struct SettingsAlertItem: Identifiable {
    let id: Int
    let title: String
}

private struct SettingsModernSurfaceFixture: View {
    let slider: Binding<Double>
    let alertItem: Binding<SettingsAlertItem?>
    let toolbarAction: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            List {
                SwiftUI.Section {
                    Slider(value: slider, in: 0 ... 4, step: 1)
                        .tint(.red)
                    Grid(horizontalSpacing: 10, verticalSpacing: 6) {
                        GridRow {
                            Button("A") {}
                                .frame(maxWidth: .infinity, minHeight: 40)
                            Button("B") {}
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                        GridRow {
                            Button("C") {}
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }
                    }
                } footer: {
                    Text("Restores previous purchases")
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Settings"))
            .navigationBarItems(
                trailing: Button("Close", action: toolbarAction)
            )
        }
        .alert(item: alertItem) { item in
            Alert(
                title: Text(item.title),
                message: Text("Legacy item alert"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

private struct SettingsStyleFixture: View {
    let destination: URL

    var body: some View {
        VStack(spacing: 8) {
            Text("Tight label")
                .lineLimit(1)
                .allowsTightening(true)
                .frame(width: 54, height: 24)
                .background(
                    Color.red.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .shadow(color: .blue.opacity(0.5), radius: 4, x: 2, y: 3)
            HStack {
                Image(systemName: "heart").imageScale(.small)
                Image(systemName: "heart").imageScale(.large)
            }
            ProgressView().progressViewStyle(.circular).tint(nil)
            Link("Project", destination: destination)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct SettingsDismissDestination: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(title) { dismiss() }
    }
}

private struct SettingsSheetFixture: View {
    @State private var isPresented = false

    var body: some View {
        Button("Show Sheet") { isPresented = true }
            .sheet(isPresented: $isPresented) {
                SettingsDismissDestination(title: "Dismiss Sheet")
            }
    }
}

private struct SettingsNavigationDestinationFixture: View {
    @State private var isPresented = false

    var body: some View {
        Button("Show Destination") { isPresented = true }
            .navigationDestination(isPresented: $isPresented) {
                SettingsDismissDestination(title: "Dismiss Destination")
                    .navigationTitle("Support")
            }
    }
}

#if !os(Linux)
@MainActor
#endif
final class SwiftUISettingsTests: XCTestCase {
    func testSettingsControlsRoundTripBindingsEffectsAndDisabledState() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let model = SettingsModel()
        let controller = UIHostingController(rootView: SettingsFixture(model: model))
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 360, height: 260)
        host.layoutIfNeeded()

        XCTAssertEqual(controller.title, "Internal Settings")
        XCTAssertEqual(controller._openGraphChangeCount, 1)
        XCTAssertEqual(controller._openGraphSubscriptionCount, 1)
        XCTAssertEqual(model.changedTags, [])
        XCTAssertEqual(model.receivedBranches, ["none"])

        let section = try XCTUnwrap(descendant(host, identifier: "SwiftUI.Section"))
        XCTAssertEqual(
            section.subviews.filter {
                $0.accessibilityIdentifier?.hasPrefix("SwiftUI.Section.row.") == true
            }.count,
            4
        )
        let caption = try XCTUnwrap(
            descendants(host).compactMap { $0 as? UILabel }.first {
                $0.text == "Requires app restart"
            }
        )
        XCTAssertEqual(caption.font.pointSize, 12, accuracy: 0.001)
        XCTAssertTrue(
            descendants(host).compactMap { ($0 as? UILabel)?.text }
                .contains("Changes apply immediately")
        )

        var toggle = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Toggle.switch") as? UISwitch
        )
        XCTAssertFalse(toggle.isEnabled)

        let field = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.TextField") as? UITextField
        )
        field.text = "focus-debug"
        field.sendActions(for: .editingChanged)
        flush(host)

        XCTAssertEqual(model.tag, "focus-debug")
        XCTAssertEqual(model.changedTags, ["focus-debug"])
        toggle = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Toggle.switch") as? UISwitch
        )
        XCTAssertTrue(toggle.isEnabled)

        toggle.setOn(true, animated: false)
        toggle.sendActions(for: .valueChanged)
        flush(host)
        XCTAssertTrue(model.enabled)

        let picker = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Picker") as? UIControl
        )
        picker.sendActions(for: .touchUpInside)
        flush(host)
        XCTAssertEqual(model.receivedBranches.last, "beta")
        XCTAssertTrue(
            descendants(host).compactMap { ($0 as? UILabel)?.text }.contains("beta")
        )
    }

    func testEffectStorageIsRemovedWhenConditionalBranchLeavesGraph() throws {
        struct ConditionalFixture: View {
            let visible: Bool
            let model: SettingsModel

            @ViewBuilder var body: some View {
                if visible {
                    Text(verbatim: model.tag)
                        .onChange(of: model.tag) { _ in }
                        .onReceive(model.events) { model.receivedBranches.append($0) }
                } else {
                    Text(verbatim: "hidden")
                }
            }
        }

        let model = SettingsModel()
        let controller = UIHostingController(
            rootView: ConditionalFixture(visible: true, model: model)
        )
        _ = controller.view
        XCTAssertEqual(controller._openGraphChangeCount, 1)
        XCTAssertEqual(controller._openGraphSubscriptionCount, 1)
        model.events.send("mounted")
        XCTAssertEqual(model.receivedBranches, ["mounted"])

        controller.rootView = ConditionalFixture(visible: false, model: model)
        XCTAssertEqual(controller._openGraphChangeCount, 0)
        XCTAssertEqual(controller._openGraphSubscriptionCount, 0)
        model.events.send("stale")
        XCTAssertEqual(model.receivedBranches, ["mounted"])
    }

    func testPickerPrefersExplicitTagsOverForEachIdentity() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        struct ExplicitTagFixture: View {
            @ObservedObject var model: SettingsModel

            var body: some View {
                Picker("Explicit", selection: $model.explicitSelection) {
                    ForEach([1, 2], id: \.self) { value in
                        Text(verbatim: value == 1 ? "ten" : "twenty")
                            .tag(value * 10)
                    }
                }
            }
        }

        let model = SettingsModel()
        let controller = UIHostingController(rootView: ExplicitTagFixture(model: model))
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 320, height: 60)
        host.layoutIfNeeded()

        XCTAssertTrue(
            descendants(host).compactMap { ($0 as? UILabel)?.text }.contains("ten")
        )
        let picker = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Picker") as? UIControl
        )
        picker.sendActions(for: .touchUpInside)
        flush(host)
        XCTAssertEqual(model.explicitSelection, 20)
        XCTAssertTrue(
            descendants(host).compactMap { ($0 as? UILabel)?.text }.contains("twenty")
        )

        var menuSelection = 1
        let menuController = UIHostingController(
            rootView: Picker(
                selection: Binding(
                    get: { menuSelection },
                    set: { menuSelection = $0 }
                )
            ) {
                Text("One").tag(1)
                Text("Two").tag(2)
            } label: {
                Label("Mode", systemImage: "safari")
            }
            .pickerStyle(.menu)
        )
        let menuHost = try XCTUnwrap(menuController.view)
        menuHost.frame = CGRect(x: 0, y: 0, width: 320, height: 60)
        menuHost.layoutIfNeeded()
        let menuPicker = try XCTUnwrap(
            descendant(menuHost, identifier: "SwiftUI.Picker") as? UIButton
        )
        XCTAssertTrue(menuPicker.showsMenuAsPrimaryAction)
        XCTAssertEqual(menuPicker.menu?.options, [.singleSelection])
        let actions = try XCTUnwrap(menuPicker.menu?.children as? [UIAction])
        XCTAssertEqual(actions.map(\.title), ["One", "Two"])
        XCTAssertEqual(actions.map(\.state), [.on, .off])
        actions[1].performWithSender(menuPicker, target: nil)
        XCTAssertEqual(menuSelection, 2)
    }

    func testSliderGridGroupedSectionToolbarAndLegacyItemAlertAreLive() throws {
        var sliderValue = 1.0
        var item: SettingsAlertItem? = .init(id: 7, title: "Could not restore")
        var toolbarCount = 0
        let controller = UIHostingController(
            rootView: SettingsModernSurfaceFixture(
                slider: Binding(get: { sliderValue }, set: { sliderValue = $0 }),
                alertItem: Binding(get: { item }, set: { item = $0 }),
                toolbarAction: { toolbarCount += 1 }
            )
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 420))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let slider = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.Slider") as? UISlider
        )
        XCTAssertEqual(slider.minimumValue, 0)
        XCTAssertEqual(slider.maximumValue, 4)
        slider.value = 3.4
        slider.sendActions(for: .valueChanged)
        XCTAssertEqual(sliderValue, 3)

        let buttons = descendants(controller.view).compactMap { $0 as? UIControl }
            .filter { $0.accessibilityIdentifier == "SwiftUI.Button" }
        XCTAssertGreaterThanOrEqual(buttons.count, 4)
        // NavigationStack now owns a real UINavigationController, so its
        // toolbar is a sibling of the content controller rather than a fake
        // in-tree bar. Select grid controls semantically instead of relying
        // on cross-controller traversal order.
        let gridButtons = ["A", "B", "C"].compactMap { title in
            buttons.first { button in
                descendants(button).compactMap { ($0 as? UILabel)?.text }
                    .contains(title)
            }
        }
        XCTAssertEqual(gridButtons.count, 3)
        XCTAssertEqual(gridButtons[0].frame.width, gridButtons[1].frame.width, accuracy: 0.001)
        XCTAssertGreaterThan(gridButtons[1].frame.minX, gridButtons[0].frame.minX)
        XCTAssertGreaterThan(gridButtons[2].frame.minY, gridButtons[0].frame.minY)
        XCTAssertEqual(gridButtons[2].frame.minX, gridButtons[0].frame.minX, accuracy: 0.001)

        let list = try XCTUnwrap(
            descendant(controller.view, identifier: "SwiftUI.List") as? UIScrollView
        )
        XCTAssertEqual(list.accessibilityValue, "style=grouped")
        XCTAssertTrue(
            descendants(controller.view).compactMap { ($0 as? UILabel)?.text }
                .contains("Restores previous purchases")
        )

        let close = try XCTUnwrap(
            buttons.first { button in
                descendants(button).compactMap { ($0 as? UILabel)?.text }.contains("Close")
            }
        )
        close.sendActions(for: .touchUpInside)
        XCTAssertEqual(toolbarCount, 1)

        let alert = try XCTUnwrap(controller.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.title, "Could not restore")
        XCTAssertEqual(alert.message, "Legacy item alert")
        XCTAssertEqual(alert.actions.map(\.title), ["OK"])
        alert.actions[0]._fire()
        XCTAssertNil(item)
    }

    func testSettingsStylingLinkImageScaleAndCircularProgressReachOpenUIKit() throws {
        let destination = try XCTUnwrap(URL(string: "https://example.invalid/project"))
        var opened: String?
        let previousHandler = UIApplication.urlOpenHandler
        UIApplication.urlOpenHandler = { url in
            opened = url
            return true
        }
        defer { UIApplication.urlOpenHandler = previousHandler }

        let controller = UIHostingController(
            rootView: SettingsStyleFixture(destination: destination)
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 240)
        host.layoutIfNeeded()

        let label = try XCTUnwrap(
            descendants(host).compactMap { $0 as? UILabel }.first { $0.text == "Tight label" }
        )
        XCTAssertTrue(label.allowsDefaultTighteningForTruncation)
        let rounded = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.RoundedRectangle.fill")
        )
        XCTAssertEqual(rounded.layer.cornerRadius, 12, accuracy: 0.001)
        let shadow = try XCTUnwrap(descendant(host, identifier: "SwiftUI.Shadow"))
        XCTAssertEqual(shadow.layer.shadowRadius, 4, accuracy: 0.001)
        XCTAssertEqual(shadow.layer.shadowOffset, CGSize(width: 2, height: 3))
        XCTAssertEqual(shadow.layer.shadowOpacity, 0.5, accuracy: 0.001)
        XCTAssertEqual(
            try XCTUnwrap(shadow.layer.shadowColor).blue,
            1,
            accuracy: 0.001
        )

        let symbols = descendants(host).filter {
            $0.accessibilityIdentifier == "SwiftUI.Image.systemName.heart"
        }
        XCTAssertEqual(symbols.count, 2)
        XCTAssertLessThan(symbols[0].frame.width, symbols[1].frame.width)
        XCTAssertEqual(symbols[0].frame.width, 13.5, accuracy: 0.001)
        XCTAssertEqual(symbols[1].frame.width, 27, accuracy: 0.001)

        let progress = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ProgressView")
                as? UIActivityIndicatorView
        )
        XCTAssertEqual(progress.accessibilityValue, "style=circular")

        let link = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Link") as? UIControl
        )
        XCTAssertTrue(link.accessibilityTraits.contains(.link))
        link.sendActions(for: .touchUpInside)
        XCTAssertEqual(opened, destination.absoluteString)
    }

    func testSheetAndNavigationDestinationDriveRealControllerState() throws {
        OpenUIKit.Timer._reset()
        _OpenInvalidationScheduler.forceHostClockForTesting = true
        defer {
            _OpenInvalidationScheduler.forceHostClockForTesting = false
            OpenUIKit.Timer._reset()
        }

        let sheetHost = UIHostingController(rootView: SettingsSheetFixture())
        let sheetWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        sheetWindow.rootViewController = sheetHost
        sheetWindow.makeKeyAndVisible()
        sheetHost.view.frame = sheetWindow.bounds
        sheetHost.view.layoutIfNeeded()

        let showSheet = try XCTUnwrap(control(named: "Show Sheet", in: sheetHost.view))
        showSheet.sendActions(for: .touchUpInside)
        flush(sheetHost.view)

        let presented = try XCTUnwrap(sheetHost.presentedViewController)
        presented.view.layoutIfNeeded()
        XCTAssertEqual(presented.modalPresentationStyle, .pageSheet)
        XCTAssertNotNil(
            descendant(presented.view, identifier: "SwiftUI.PresentationContainer")
                ?? (presented.view.accessibilityIdentifier == "SwiftUI.PresentationContainer"
                    ? presented.view : nil)
        )
        let dismissSheet = try XCTUnwrap(control(named: "Dismiss Sheet", in: presented.view))
        dismissSheet.sendActions(for: .touchUpInside)
        flush(sheetHost.view)
        sheetWindow.tick(timestamp: 10)
        XCTAssertNil(sheetHost.presentedViewController)

        let navigationHost = UIHostingController(
            rootView: SettingsNavigationDestinationFixture()
        )
        let navigation = UINavigationController(rootViewController: navigationHost)
        let navigationWindow = UIWindow(
            frame: CGRect(x: 0, y: 0, width: 320, height: 480)
        )
        navigationWindow.rootViewController = navigation
        navigationWindow.makeKeyAndVisible()
        navigation.view.frame = navigationWindow.bounds
        navigation.view.layoutIfNeeded()
        navigationHost.view.layoutIfNeeded()

        let showDestination = try XCTUnwrap(
            control(named: "Show Destination", in: navigationHost.view)
        )
        showDestination.sendActions(for: .touchUpInside)
        flush(navigationHost.view)
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertNil(navigationHost.presentedViewController)
        XCTAssertEqual(navigation.topViewController?.title, "Support")

        let destinationController = try XCTUnwrap(navigation.topViewController)
        destinationController.view.layoutIfNeeded()
        let dismissDestination = try XCTUnwrap(
            control(named: "Dismiss Destination", in: destinationController.view)
        )
        dismissDestination.sendActions(for: .touchUpInside)
        flush(navigationHost.view)
        navigationWindow.tick(timestamp: 10)
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.topViewController === navigationHost)
    }

    private func flush(_ host: UIView) {
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
    }

    private func descendant(_ root: UIView, identifier: String) -> UIView? {
        descendants(root).first { $0.accessibilityIdentifier == identifier }
    }

    private func control(named title: String, in root: UIView) -> UIControl? {
        descendants(root).compactMap { $0 as? UIControl }.first { control in
            descendants(control).compactMap { ($0 as? UILabel)?.text }.contains(title)
        }
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}

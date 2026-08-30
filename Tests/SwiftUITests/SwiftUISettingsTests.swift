// Runtime coverage for the settings-form surface used by Mozilla Focus's
// exact Blockzilla/InternalSettings sources at a2832521c1daa0c23419c73705ae043ed60c9791.

import XCTest
import Combine
import OpenUIKit
@testable import SwiftUI

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

@MainActor
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
    }

    private func flush(_ host: UIView) {
        XCTAssertTrue(OpenUIKit.Timer._hasScheduledTimers)
        OpenUIKit.Timer._step(to: OpenUIKit.Timer.currentTime)
        host.layoutIfNeeded()
    }

    private func descendant(_ root: UIView, identifier: String) -> UIView? {
        descendants(root).first { $0.accessibilityIdentifier == identifier }
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}

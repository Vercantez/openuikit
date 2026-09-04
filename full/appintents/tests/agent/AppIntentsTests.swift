import Foundation
import AppIntents

private struct EchoIntent: AppIntent {
    let value: String
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "echo=\(value)")
    }
}

private struct ShortcutCatalog: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: EchoIntent(value: "one"),
            phrases: ["Echo with \(.applicationName)"],
            shortTitle: "Echo",
            systemImageName: "waveform"
        )
    }
}

func testIntentPerformEcho() {
    final class Box: @unchecked Sendable {
        var text: String?
        var error: Error?
    }
    let box = Box()
    let sem = DispatchSemaphore(value: 0)
    Task {
        do {
            let result = try await EchoIntent(value: "portable").perform()
            box.text = (result as? IntentResultValue)?.dialog?.text
        } catch {
            box.error = error
        }
        sem.signal()
    }
    precondition(sem.wait(timeout: .now() + 5) == .success)
    precondition(box.error == nil)
    precondition(box.text == "echo=portable")
}

func testIntentDialogAndResultFactories() {
    let dialog = IntentDialog("hello")
    precondition(dialog.text == "hello")
    let interpolated: IntentDialog = "echo=\("portable")"
    precondition(interpolated.text == "echo=portable")
    let empty = IntentResultValue.result()
    precondition(empty.dialog == nil)
    let withDialog = IntentResultValue.result(dialog: dialog)
    precondition(withDialog.dialog?.text == "hello")
}

func testAppShortcutPhraseInterpolation() {
    precondition(ShortcutCatalog.appShortcuts.count == 1)
    precondition(
        ShortcutCatalog.appShortcuts[0].phrases[0].template ==
            "Echo with ${applicationName}"
    )
    precondition(AppShortcutPhraseToken.applicationName == .applicationName)
    precondition(!AppIntentsPortable.supportsSystemRegistration)
}

func testIntentParameterStoresValue() {
    let parameter = IntentParameter<String>(title: "Query")
    parameter.wrappedValue = "search"
    precondition(parameter.wrappedValue == "search")
    precondition(parameter.metadata.title == "Query")
    let alias: Parameter<String> = Parameter(title: "Alias")
    alias.wrappedValue = "ok"
    precondition(alias.wrappedValue == "ok")
}

func testInputConnectionAndAuthenticationEnums() {
    precondition(InputConnectionBehavior.connectToPreviousIntentResult != .never)
    precondition(InputConnectionBehavior.default != .never)
    precondition(IntentAuthenticationPolicy.alwaysAllowed != .requiresAuthentication)
    precondition(IntentAuthenticationPolicy.requiresLocalDeviceAuthentication != .alwaysAllowed)
}

func testShortcutTileColorAndIntentModes() {
    precondition(ShortcutTileColor.navy != .red)
    precondition(ShortcutTileColor.tangerine != .lime)
    precondition(IntentModes.background.contains(.background))
    precondition(!IntentModes.background.contains(.foreground))
    let combined: IntentModes = [.background, .foreground]
    precondition(combined.contains(.foreground))
    precondition(IntentModes.ForegroundMode.immediate != .deferred)
}

func testAppIntentErrorFailClosed() {
    let error = AppIntentError.Unrecoverable.unsupportedOnDevice
    precondition(error.description == "unsupportedOnDevice")
    precondition(AppIntentError.PermissionRequired.siri.description == "siri")
    precondition(AppIntentError.UserActionRequired.confirmation.description == "confirmation")
    let location = AppIntentError.PermissionRequired.location(precise: true)
    precondition(location.description == "locationPrecise")
}

func testLocalDonationDoesNotClaimSystemRegistrar() {
    IntentDonationManager.resetLocalDonations()
    let identifier = EchoIntent(value: "donate").donate()
    precondition(identifier.rawValue.contains("EchoIntent"))
    precondition(IntentDonationManager.recordedLocalDonations.count == 1)
    precondition(!AppIntentsPortable.supportsSystemRegistration)
}

func testOpenURLIntentAndFile() {
    let url = URL(fileURLWithPath: "/tmp/openuikit-appintents")
    let intent = OpenURLIntent(url)
    precondition(intent.url == url)
    let data = Data([1, 2, 3])
    let file = IntentFile(data: data, filename: "a.bin", type: .data)
    precondition(file.data == data)
    precondition(file.filename == "a.bin")
    precondition(file.type == .data)
}

func testDisplayRepresentationAndDescription() {
    let image = DisplayRepresentation.Image(systemName: "star", isTemplate: true)
    precondition(image.systemName == "star")
    precondition(image.isTemplate == true)
    let representation = DisplayRepresentation(title: "Site", subtitle: "News")
    precondition(representation.title.key == "Site")
    precondition(representation.subtitle?.key == "News")
    let description = IntentDescription("Adds a feed")
    precondition(description.text == "Adds a feed")
    let typeRep = TypeDisplayRepresentation(name: "Feed")
    precondition(typeRep.name == "Feed")
}

func testSiriTipAndConfirmationFailClosed() {
    precondition(SiriTipViewStyle.automatic == SiriTipViewStyle.automatic)
    precondition(SiriTipViewStyle.dark != .light)
    precondition(ConfirmationActionName.continue.rawValue == "continue")
    precondition(ConfirmationConditions.lowConfidenceSource.contains(.lowConfidenceSource))
    let option = IntentChoiceOption(title: LocalizedStringResource("One"))
    precondition(option.title.key == "One")
}

func testWidgetFamilyAndVideoCategory() {
    precondition(IntentWidgetFamily.systemSmall != .systemLarge)
    precondition(VideoCategory.movies != .tv)
    precondition(StringSearchScope.general != .movies)
}

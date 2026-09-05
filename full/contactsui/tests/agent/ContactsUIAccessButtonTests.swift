@_spi(OpenUIKitHost) import ContactsUI
import Foundation

@MainActor
func testAccessButtonInit() {
    var received: [String]?
    let button = ContactAccessButton(
        queryString: "Anne",
        ignoredEmails: ["skip@example.com"],
        ignoredPhoneNumbers: ["+15555550100"]
    ) { identifiers in
        received = identifiers
    }
    precondition(button.queryString == "Anne")
    precondition(button.ignoredEmails == ["skip@example.com"])
    precondition(button.ignoredPhoneNumbers == ["+15555550100"])
    precondition(received == nil)
    let granted = ContactsUIHostControl.invokeAccessApproval(button)
    precondition(granted.isEmpty)
    precondition(received == [])
    let model = ContactsUIHostControl.accessPickerModel(button)
    precondition(model.queryString == "Anne")
    precondition(model.ignoredEmails == ["skip@example.com"])
    precondition(model.ignoredPhoneNumbers == ["+15555550100"])
    precondition(model.failClosedApprovedIdentifiers().isEmpty)
}

@MainActor
func testAccessButtonBody() {
    let button = ContactAccessButton(queryString: "Ada")
    _ = button.body
    let _: ContactAccessButton.Body = button.body
}

@MainActor
func testContactAccessButtonCaption() {
    let button = ContactAccessButton(queryString: "Ada")
    let captioned = button.contactAccessButtonCaption(.email)
    precondition(captioned.linuxCaption == .email)
    let tags = ContactsUIHostControl.linuxModifierTags(captioned)
    precondition(tags.contains("contactAccessButtonCaption(_:)"))
}

@MainActor
func testContactAccessButtonStyle() {
    let button = ContactAccessButton(queryString: "Ada")
    let styled = button.contactAccessButtonStyle(ContactAccessButton.Style(imageWidth: 30))
    precondition(styled.linuxStyle.imageWidth == 30)
    let tags = ContactsUIHostControl.linuxModifierTags(styled)
    precondition(tags.contains("contactAccessButtonStyle(_:)"))
}

@MainActor
func testContactAccessPickerFailClosed() {
    var presented = true
    var granted: [String]?
    let binding = Binding(
        get: { presented },
        set: { presented = $0 }
    )
    let button = ContactAccessButton(queryString: "Ada")
    let gated = button.contactAccessPicker(isPresented: binding) { ids in
        granted = ids
    }
    precondition(presented == false)
    precondition(granted == [])
    let tags = ContactsUIHostControl.linuxModifierTags(gated)
    precondition(tags.contains("contactAccessPicker(isPresented:completionHandler:)"))
    let model = ContactsUIHostControl.accessPickerModel(button)
    precondition(model.queryString == "Ada")
    precondition(model.failClosedApprovedIdentifiers() == [])
}

@MainActor
func testViewContactAccessPicker() {
    var presented = true
    var granted: [String]?
    let binding = Binding(
        get: { presented },
        set: { presented = $0 }
    )
    var view: some View = EmptyView()
    view = view.contactAccessPicker(
        isPresented: binding,
        completionHandler: { ids in granted = ids }
    )
    _ = view
    precondition(presented == false)
    precondition(granted == [])
}

@MainActor
func testViewContactAccessButtonStyle() {
    var view: some View = EmptyView()
    view = view.contactAccessButtonStyle(ContactAccessButton.Style.automatic)
    _ = view
}

@MainActor
func testViewContactAccessButtonCaption() {
    var view: some View = EmptyView()
    view = view.contactAccessButtonCaption(.phone)
    _ = view
}

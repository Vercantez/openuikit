import ContactsUI
import Foundation

@MainActor
private final class PickerProbe: CNContactPickerDelegate {
    var cancelled = false
    var contacts: [CNContact] = []
    var properties: [CNContactProperty] = []
    var multiContacts: [CNContact] = []
    var multiProperties: [CNContactProperty] = []

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contact: CNContact
    ) {
        contacts.append(contact)
    }

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelectContactProperties contactProperties: [CNContactProperty]
    ) {
        multiProperties.append(contentsOf: contactProperties)
    }

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contactProperty: CNContactProperty
    ) {
        properties.append(contactProperty)
    }

    func contactPicker(
        _ picker: CNContactPickerViewController,
        didSelect contacts: [CNContact]
    ) {
        multiContacts.append(contentsOf: contacts)
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        cancelled = true
    }
}

@MainActor
private final class EditorProbe: CNContactViewControllerDelegate {
    var completed: CNContact?
    var didComplete = false
    var defaultAction = true

    func contactViewController(
        _ viewController: CNContactViewController,
        didCompleteWith contact: CNContact?
    ) {
        completed = contact
        didComplete = true
    }

    func contactViewController(
        _ viewController: CNContactViewController,
        shouldPerformDefaultActionFor property: CNContactProperty
    ) -> Bool {
        defaultAction
    }
}

@MainActor
private func applyModifiers(_ button: ContactAccessButton) -> ContactAccessButton {
    button
        .navigationSplitViewColumnWidth(min: 1, ideal: 2, max: 3)
        .navigationSplitViewColumnWidth(10)
        .brightness(0.25)
        .saturation(0.5)
        .unredacted()
        .colorInvert()
        .onDisappear(perform: nil)
        .refreshable {}
        .scaledToFit()
        .cornerRadius(3, antialiased: true)
        .labelsHidden()
        .onTapGesture(count: 2, perform: {})
        .renameAction {}
        .scaledToFill()
        .geometryGroup()
        .layoutPriority(1)
        .listRowSpacing(2)
        .scrollDisabled(true)
        .gridCellColumns(2)
        .monospacedDigit()
        .safeAreaPadding(8)
        .statusBarHidden(true)
        .allowsHitTesting(false)
        .allowsTightening(true)
        .compositingGroup()
        .luminanceToAlpha()
        .privacySensitive(true)
        .searchCompletion("ada")
        .listSectionSpacing(4)
        .minimumScaleFactor(0.8)
        .previewDisplayName("preview")
        .scrollClipDisabled(true)
        .focusEffectDisabled(true)
        .hoverEffectDisabled(true)
        .navigationBarHidden(true)
        .speechAdjustedPitch(0.1)
        .inspectorColumnWidth(min: 1, ideal: 2, max: 3)
        .inspectorColumnWidth(12)
        .invalidatableContent(true)
        .disableAutocorrection(true)
        .autocorrectionDisabled(true)
        .labelReservedIconWidth(10)
        .labelIconToTitleSpacing(2)
        .onScrollVisibilityChange(threshold: 0.4) { _ in }
        .backgroundExtensionEffect()
        .fileDialogCustomizationID("id")
        .onInteractiveResizeChange { _ in }
        .speechAnnouncementsQueued(true)
        .speechSpellsOutCharacters(true)
        .allowsWindowActivationEvents()
        .allowsWindowActivationEvents(true)
        .interactionActivityTrackingTag("tag")
        .speechAlwaysIncludesPunctuation(true)
        .accessibilityIgnoresInvertColors(true)
        .fileDialogImportsUnresolvedAliases(false)
        .flipsForRightToLeftLayoutDirection(true)
        .accessibilityShowsLargeContentViewer()
        .blur(radius: 1, opaque: false)
        .badge(3)
        .frame()
        .hidden()
        .offset(x: 1, y: 2)
        .zIndex(4)
        .clipped(antialiased: false)
        .kerning(1)
        .onHover { _ in }
        .opacity(0.9)
        .padding(5)
        .contrast(1.1)
        .disabled(true)
        .onAppear(perform: nil)
        .position(x: 1, y: 2)
        .tracking(1)
        .fixedSize(horizontal: true, vertical: false)
        .fixedSize()
        .grayscale(0.2)
        .lineLimit(2)
        .statusBar(hidden: true)
}

@MainActor
private func runContactsUIRuntime() {
    precondition(!ContactsUIPortable.limitedAccessUIAvailable)
    precondition(!ContactsUIPortable.systemContactStoreAvailable)
    precondition(ContactsUIPortable.contactPickerCapability == .hostDriven)
    precondition(ContactsUIPortable.contactViewCapability == .hostDriven)

    let ada = CNMutableContact(
        identifier: "ada",
        givenName: "Ada",
        familyName: "Lovelace"
    )
    precondition(!ada.id.uuidString.isEmpty)
    let adaID = ada.id

    let picker = CNContactPickerViewController()
    let pickerDelegate = PickerProbe()
    picker.delegate = pickerDelegate
    picker.displayedPropertyKeys = ["givenName", "familyName", "emailAddresses"]
    picker.predicateForEnablingContact = NSPredicate { object, _ in
        (object as? CNContact)?.givenName == "Ada"
    }
    picker.predicateForSelectionOfContact = NSPredicate { object, _ in
        (object as? CNContact)?.familyName == "Lovelace"
    }
    picker.predicateForSelectionOfProperty = NSPredicate { object, _ in
        (object as? CNContactProperty)?.key == "emailAddresses"
    }
    precondition(picker.displayedPropertyKeys?.count == 3)
    picker.presentPicker()
    precondition(picker.isPresented)

    let bob = CNContact(identifier: "bob", givenName: "Bob", familyName: "Kane")
    precondition(picker.reportSelection(contact: bob)?.code == .contactDisabledByPredicate)
    precondition(pickerDelegate.contacts.isEmpty)

    picker.predicateForSelectionOfContact = NSPredicate { object, _ in
        (object as? CNContact)?.givenName == "Nope"
    }
    precondition(
        picker.reportSelection(contact: ada)?.code == .contactNotSelectableByPredicate
    )
    picker.predicateForSelectionOfContact = NSPredicate { object, _ in
        (object as? CNContact)?.familyName == "Lovelace"
    }
    precondition(picker.reportSelection(contact: ada) == nil)
    precondition(pickerDelegate.contacts.map(\.identifier) == ["ada"])
    precondition(!picker.isPresented)

    picker.presentPicker()
    precondition(picker.reportCancel())
    precondition(pickerDelegate.cancelled)
    precondition(!picker.isPresented)

    picker.presentPicker()
    precondition(picker.reportSelection(contacts: [ada]) == nil)
    precondition(pickerDelegate.multiContacts.count == 1)

    let email = CNContactProperty(
        contact: ada,
        key: "emailAddresses",
        value: "ada@example.com",
        identifier: "e1",
        label: "work"
    )
    let phone = CNContactProperty(contact: ada, key: "phoneNumbers", value: "1")
    picker.presentPicker()
    precondition(
        picker.reportSelection(contactProperty: phone)?.code == .propertyNotSelectableByPredicate
    )
    precondition(picker.reportSelection(contactProperty: email) == nil)
    precondition(pickerDelegate.properties.map(\.key) == ["emailAddresses"])
    picker.presentPicker()
    precondition(picker.reportSelection(contactProperties: [email]) == nil)
    precondition(pickerDelegate.multiProperties.count == 1)

    let existing = CNContactViewController(for: ada)
    precondition(existing.mode == .existing)
    precondition(existing.allowsEditing)
    precondition(existing.allowsActions)
    precondition(existing.contact.identifier == "ada")
    let aliased = CNContactViewController(forContact: ada)
    precondition(aliased.contact.identifier == "ada")

    let unknown = CNContactViewController(forUnknownContact: ada)
    precondition(unknown.mode == .unknown)
    precondition(!unknown.allowsEditing)
    precondition(unknown.allowsActions)

    let created = CNContactViewController(forNewContact: nil)
    precondition(created.mode == .new)
    precondition(created.allowsEditing)
    precondition(!created.allowsActions)

    created.alternateName = "New person"
    created.message = "Add this caller"
    created.shouldShowLinkedContacts = true
    created.displayedPropertyKeys = ["givenName"]
    created.contactStore = CNContactStore()
    created.parentGroup = CNGroup(identifier: "g1", name: "Friends")
    created.parentContainer = CNContainer(identifier: "c1", name: "Local")
    created.highlightProperty(withKey: "givenName", identifier: nil)
    precondition(created.highlightedPropertyKey == "givenName")
    precondition(created.alternateName == "New person")
    precondition(created.message == "Add this caller")
    precondition(created.shouldShowLinkedContacts)
    precondition(created.parentGroup?.name == "Friends")
    precondition(created.parentContainer?.name == "Local")
    precondition(created.contactStore != nil)

    let keys = CNContactViewController.descriptorForRequiredKeys()
    let descriptor = keys as! CNContactKeyDescriptor
    precondition(descriptor.keys.contains("givenName"))
    _ = descriptor.copy() as Any

    let editorDelegate = EditorProbe()
    editorDelegate.defaultAction = false
    existing.delegate = editorDelegate
    precondition(!existing.shouldPerformDefaultAction(for: email))
    existing.reportCompletion(contact: ada)
    precondition(editorDelegate.didComplete)
    precondition(editorDelegate.completed?.identifier == "ada")
    created.reportCompletion(contact: nil)

    let icon = UIApplicationShortcutIcon(contact: ada)
    precondition(icon.contactIdentifier == "ada")
    precondition(ada.id == adaID)

    var granted: [String] = ["sentinel"]
    var button = ContactAccessButton(
        queryString: "Ada",
        ignoredEmails: ["skip@example.com"],
        ignoredPhoneNumbers: ["555"],
        approvalCallback: { granted = $0 }
    )
    precondition(button.queryString == "Ada")
    precondition(button.ignoredEmails == ["skip@example.com"])
    precondition(button.ignoredPhoneNumbers == ["555"])
    precondition(button.caption == .defaultText)
    precondition(button.style == .automatic)
    precondition(button.body.reason.contains("unavailable"))
    let _: ContactAccessButton.Body = button.body

    let style = ContactAccessButton.Style(
        imageTrailingEdgePadding: 4,
        imageWidth: 20,
        imageColor: Color(rawValue: "accent")
    )
    button = button
        .contactAccessButtonStyle(style)
        .contactAccessButtonCaption(.email)
        .contactAccessPicker(isPresented: true) { _ in }
    precondition(button.style.imageWidth == 20)
    precondition(button.style.imageTrailingEdgePadding == 4)
    precondition(button.style.imageColor?.rawValue == "accent")
    precondition(button.caption == .email)
    precondition(
        button.recordedModifiers.contains(.contactAccessPickerPresented(true))
    )
    button.reportApproval()
    precondition(granted.isEmpty)
    button.reportApproval(newlyGrantedIdentifiers: ["host-id"])
    precondition(granted == ["host-id"])

    precondition(ContactAccessButton.Caption(rawValue: "phone") == .phone)
    precondition(ContactAccessButton.Caption.phone.rawValue == "phone")
    precondition(ContactAccessButton.Caption.email != .defaultText)
    var hasher = Hasher()
    ContactAccessButton.Caption.email.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ContactAccessButton.Caption.defaultText.hashValue

    button = applyModifiers(button)
    precondition(button.recordedModifiers.contains(.brightness(0.25)))
    precondition(button.recordedModifiers.contains(.disabled(true)))
    precondition(button.recordedModifiers.contains(.hidden))
    precondition(button.recordedModifiers.contains(.fixedSizeBoth))
    precondition(button.recordedModifiers.contains(.allowsWindowActivationEventsNil))
}

MainActor.assumeIsolated {
    runContactsUIRuntime()
}
print("CONTACTSUI_AGENT_RUNTIME_OK")

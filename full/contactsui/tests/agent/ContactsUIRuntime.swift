@_spi(OpenUIKitHost) import ContactsUI
import Foundation

func runContactsUIRuntime() {
    precondition(!ContactsUIPortable.limitedAccessUIAvailable)
    precondition(!ContactsUIPortable.systemContactStoreAvailable)
    precondition(ContactsUIPortable.contactPickerCapability == .hostDriven)
    precondition(ContactsUIPortable.contactViewCapability == .hostDriven)

    let unavailable = ContactsUIPortableError(.limitedAccessUIUnavailable)
    precondition(unavailable.code == .limitedAccessUIUnavailable)
    precondition(unavailable.description.contains("unavailable"))

    let store = ContactsUIPortableError(.systemContactStoreUnavailable)
    precondition(store.code == .systemContactStoreUnavailable)
    precondition(store != unavailable)

    let disabled = ContactsUIPortableError(.contactDisabledByPredicate)
    let notSelectable = ContactsUIPortableError(.contactNotSelectableByPredicate)
    let propertyRejected = ContactsUIPortableError(.propertyNotSelectableByPredicate)
    precondition(disabled.code.rawValue == 1)
    precondition(notSelectable.code.rawValue == 2)
    precondition(propertyRejected.code.rawValue == 3)
}

runContactsUIRuntime()
print("CONTACTSUI_AGENT_RUNTIME_OK")

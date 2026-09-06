import Foundation
import ContactProvider

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then ContactProvider with that `-I` / `-L`.
// The host gate does not compile this file.

func contactProviderDependencyIdentityProbe() {
    let marker = Data("contact-provider".utf8)
    precondition(type(of: marker) == Data.self)
    precondition(!String(reflecting: type(of: marker)).hasPrefix("ContactProvider."))

    let page = ContactItemPage(generationMarker: marker, offset: 3)
    precondition(page.generationMarker == marker)
    precondition(page.offset == 3)

    let anchor = ContactItemSyncAnchor(generationMarker: marker, offset: 7)
    precondition(anchor.generationMarker == marker)
    precondition(anchor.offset == 7)

    let identifier = ContactItem.Identifier("foundation-data")
    precondition(identifier.value == "foundation-data")

    let encoded = try! JSONEncoder().encode(page)
    let decoded = try! JSONDecoder().decode(ContactItemPage.self, from: encoded)
    precondition(decoded.generationMarker == marker)
}

#if CONTACTPROVIDER_IDENTITY_MAIN
contactProviderDependencyIdentityProbe()
print("CONTACTPROVIDER_DEPENDENCY_IDENTITY_OK")
#endif
